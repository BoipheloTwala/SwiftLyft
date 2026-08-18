const Notification = require('../models/Notification');
const {
  createTestUser,
  createMockRequest,
  createMockResponse,
  createMockNext
} = require('./setup');
const {
  authenticatedRequest,
  adminRequest,
  expectSuccess,
  expectError,
  validateNotificationResponse
} = require('./testUtils');

// Mock the email and SMS/push side-effects only (not the router)
jest.mock('../utils/email', () => ({
  sendEmail: jest.fn().mockResolvedValue({ success: true, messageId: 'test-id' })
}));

describe('Notification & Communication APIs (API 8)', () => {
  describe('POST /api/notifications/send - Send Notifications (Admin)', () => {
    test('should send notification successfully', async () => {
      const user = await createTestUser();

      const { request } = await adminRequest('POST', '/api/notifications/send');

      const notificationData = {
        userId: user._id.toString(),
        type: 'booking_confirmed',
        title: 'Booking Confirmed',
        message: 'Your booking has been confirmed',
        channels: ['push', 'email'],
        priority: 'normal',
        data: {
          bookingId: 'booking123',
          amount: 150
        }
      };

      const response = await request.send(notificationData);
      const result = expectSuccess(response, 201);

      expect(result.data).toHaveProperty('notification');
      expect(result.data).toHaveProperty('deliveryResults');

      validateNotificationResponse(result.data.notification);
      expect(result.data.notification.userId).toBe(user._id.toString());
      expect(result.data.notification.type).toBe('booking_confirmed');
      expect(result.data.notification.title).toBe('Booking Confirmed');
      expect(result.data.notification.channels).toEqual(['push', 'email']);
    });

    test('should schedule notification for future delivery', async () => {
      const user = await createTestUser();

      const { request } = await adminRequest('POST', '/api/notifications/send');

      const futureDate = new Date(Date.now() + 60 * 60 * 1000); // 1 hour from now

      const response = await request.send({
        userId: user._id.toString(),
        type: 'reminder',
        title: 'Upcoming Trip',
        message: 'Your trip starts in 1 hour',
        channels: ['push'],
        scheduledFor: futureDate.toISOString()
      });

      const result = expectSuccess(response, 201);
      expect(result.data.deliveryResults).toBeNull(); // No immediate delivery for scheduled notifications
      expect(result.data.notification.scheduledFor).toBeDefined();
    });

    test('should fail with missing required fields', async () => {
      const { request } = await adminRequest('POST', '/api/notifications/send');

      const response = await request.send({
        type: 'booking_confirmed'
        // Missing userId, title, message
      });

      expectError(response, 400);
    });

    test('should fail for non-admin user', async () => {
      const user = await createTestUser();

      const { request } = await authenticatedRequest('POST', '/api/notifications/send');

      const response = await request.send({
        userId: user._id.toString(),
        type: 'booking_confirmed',
        title: 'Test',
        message: 'Test message'
      });

      expectError(response, 403);
    });

    test('should handle different notification types', async () => {
      const user = await createTestUser();

      const { request } = await adminRequest('POST', '/api/notifications/send');

      const notificationTypes = [
        'booking_confirmed',
        'driver_assigned',
        'trip_completed',
        'payment_received',
        'system_update'
      ];

      for (const type of notificationTypes) {
        const response = await request.send({
          userId: user._id.toString(),
          type,
          title: `Test ${type}`,
          message: `Test message for ${type}`,
          channels: ['push']
        });

        expectSuccess(response, 201);
      }
    });
  });

  describe('GET /api/notifications/user/:userId - Get User Notifications', () => {
    test('should get user notifications list', async () => {
      const user = await createTestUser();

      // Create some notifications
      await Notification.create({
        userId: user._id,
        type: 'booking_confirmed',
        title: 'Booking Confirmed',
        message: 'Your booking is confirmed',
        channels: ['push']
      });

      await Notification.create({
        userId: user._id,
        type: 'payment_received',
        title: 'Payment Received',
        message: 'Payment has been processed',
        channels: ['push', 'email']
      });

      const { request } = await authenticatedRequest('GET', `/api/notifications/user/${user._id}`);

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data).toHaveProperty('notifications');
      expect(result.data).toHaveProperty('pagination');
      expect(result.data).toHaveProperty('unreadCount');
      expect(Array.isArray(result.data.notifications)).toBe(true);
      expect(result.data.notifications.length).toBe(2);

      result.data.notifications.forEach(validateNotificationResponse);
    });

    test('should filter unread notifications only', async () => {
      const user = await createTestUser();

      // Create read and unread notifications
      await Notification.create({
        userId: user._id,
        type: 'booking_confirmed',
        title: 'Booking Confirmed',
        message: 'Your booking is confirmed',
        channels: ['push'],
        status: {
          inApp: { read: true, readAt: new Date() }
        }
      });

      await Notification.create({
        userId: user._id,
        type: 'payment_received',
        title: 'Payment Received',
        message: 'Payment processed',
        channels: ['push']
        // unread by default
      });

      const { request } = await authenticatedRequest('GET', `/api/notifications/user/${user._id}?unreadOnly=true`);

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data.notifications.length).toBe(1);
      expect(result.data.notifications[0].type).toBe('payment_received');
      expect(result.data.unreadCount).toBe(1);
    });

    test('should implement pagination', async () => {
      const user = await createTestUser();

      // Create multiple notifications
      for (let i = 0; i < 5; i++) {
        await Notification.create({
          userId: user._id,
          type: 'system_update',
          title: `Update ${i}`,
          message: `System update ${i}`,
          channels: ['push']
        });
      }

      const { request } = await authenticatedRequest('GET', `/api/notifications/user/${user._id}?limit=2&page=2`);

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data.notifications.length).toBe(2);
      expect(result.data.pagination.page).toBe(2);
      expect(result.data.pagination.limit).toBe(2);
      expect(result.data.pagination.total).toBe(5);
    });

    test('should exclude expired notifications', async () => {
      const user = await createTestUser();

      // Create expired notification
      await Notification.create({
        userId: user._id,
        type: 'promotion',
        title: 'Expired Promo',
        message: 'This offer has expired',
        channels: ['push'],
        expiresAt: new Date(Date.now() - 24 * 60 * 60 * 1000) // Expired yesterday
      });

      // Create valid notification
      await Notification.create({
        userId: user._id,
        type: 'booking_confirmed',
        title: 'Valid Notification',
        message: 'This is still valid',
        channels: ['push'],
        expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000) // Expires tomorrow
      });

      const { request } = await authenticatedRequest('GET', `/api/notifications/user/${user._id}`);

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data.notifications.length).toBe(1);
      expect(result.data.notifications[0].title).toBe('Valid Notification');
    });

    test('should fail for non-owner user', async () => {
      const user1 = await createTestUser({ email: 'user1@test.com' });
      const user2 = await createTestUser({ email: 'user2@test.com' });

      const { request } = await authenticatedRequest('GET', `/api/notifications/user/${user1._id}`, user2);

      const response = await request;
      expectError(response, 403);
    });
  });

  describe('PUT /api/notifications/user/:userId/:notificationId/read - Mark as Read', () => {
    test('should mark notification as read', async () => {
      const user = await createTestUser();

      const notification = await Notification.create({
        userId: user._id,
        type: 'booking_confirmed',
        title: 'Booking Confirmed',
        message: 'Your booking is confirmed',
        channels: ['push']
      });

      const { request } = await authenticatedRequest('PUT', `/api/notifications/user/${user._id}/${notification._id}/read`);

      const response = await request;
      expectSuccess(response);

      // Verify notification is marked as read
      const updatedNotification = await Notification.findById(notification._id);
      expect(updatedNotification.status.inApp.read).toBe(true);
      expect(updatedNotification.status.inApp.readAt).toBeDefined();
    });

    test('should fail for non-existent notification', async () => {
      const user = await createTestUser();

      const { request } = await authenticatedRequest('PUT', `/api/notifications/user/${user._id}/507f1f77bcf86cd799439011/read`);

      const response = await request;
      expectError(response, 404);
    });

    test('should fail for wrong user', async () => {
      const user1 = await createTestUser({ email: 'user1@test.com' });
      const user2 = await createTestUser({ email: 'user2@test.com' });

      const notification = await Notification.create({
        userId: user1._id,
        type: 'booking_confirmed',
        title: 'Booking Confirmed',
        message: 'Your booking is confirmed',
        channels: ['push']
      });

      const { request } = await authenticatedRequest('PUT', `/api/notifications/user/${user1._id}/${notification._id}/read`, user2);

      const response = await request;
      expectError(response, 403);
    });
  });

  describe('POST /api/notifications/user/:userId/mark-all-read - Mark All as Read', () => {
    test('should mark all user notifications as read', async () => {
      const user = await createTestUser();

      // Create multiple unread notifications
      await Notification.create({
        userId: user._id,
        type: 'booking_confirmed',
        title: 'Booking 1',
        message: 'Booking confirmed',
        channels: ['push']
      });

      await Notification.create({
        userId: user._id,
        type: 'payment_received',
        title: 'Payment 1',
        message: 'Payment received',
        channels: ['push']
      });

      const { request } = await authenticatedRequest('POST', `/api/notifications/user/${user._id}/mark-all-read`);

      const response = await request;
      const result = expectSuccess(response);

      expect(result.message).toContain('2 notifications marked as read');

      // Verify all notifications are marked as read
      const notifications = await Notification.find({ userId: user._id });
      notifications.forEach(notification => {
        expect(notification.status.inApp.read).toBe(true);
        expect(notification.status.inApp.readAt).toBeDefined();
      });
    });

    test('should only mark unread notifications', async () => {
      const user = await createTestUser();

      // Create one read and one unread notification
      await Notification.create({
        userId: user._id,
        type: 'booking_confirmed',
        title: 'Already Read',
        message: 'Already read',
        channels: ['push'],
        status: {
          inApp: { read: true, readAt: new Date(Date.now() - 60 * 60 * 1000) }
        }
      });

      await Notification.create({
        userId: user._id,
        type: 'payment_received',
        title: 'Unread',
        message: 'Not read yet',
        channels: ['push']
      });

      const { request } = await authenticatedRequest('POST', `/api/notifications/user/${user._id}/mark-all-read`);

      const response = await request;
      const result = expectSuccess(response);

      expect(result.message).toContain('1 notifications marked as read');
    });

    test('should fail for wrong user', async () => {
      const user1 = await createTestUser({ email: 'user1@test.com' });
      const user2 = await createTestUser({ email: 'user2@test.com' });

      const { request } = await authenticatedRequest('POST', `/api/notifications/user/${user1._id}/mark-all-read`, user2);

      const response = await request;
      expectError(response, 403);
    });
  });

  describe('GET /api/users/:userId/notification-settings - Get Notification Settings', () => {
    test('should get user notification settings', async () => {
      const user = await createTestUser();

      const { request } = await authenticatedRequest('GET', `/api/notifications/user/${user._id}/settings`);

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data).toHaveProperty('notificationSettings');
      const settings = result.data.notificationSettings;

      expect(settings).toHaveProperty('push');
      expect(settings).toHaveProperty('email');
      expect(settings).toHaveProperty('sms');
      expect(settings).toHaveProperty('bookingUpdates');
      expect(settings).toHaveProperty('promotionalOffers');
      expect(settings).toHaveProperty('paymentReminders');
      expect(settings).toHaveProperty('driverMessages');
    });

    test('should allow admin to get any user settings', async () => {
      const user = await createTestUser();

      const { request } = await adminRequest('GET', `/api/notifications/user/${user._id}/settings`);

      const response = await request;
      expectSuccess(response);
    });

    test('should fail for non-owner non-admin user', async () => {
      const user1 = await createTestUser({ email: 'user1@test.com' });
      const user2 = await createTestUser({ email: 'user2@test.com' });

      const { request } = await authenticatedRequest('GET', `/api/notifications/user/${user1._id}/settings`, user2);

      const response = await request;
      expectError(response, 403);
    });
  });

  describe('PUT /api/users/:userId/notification-settings - Update Notification Settings', () => {
    test('should update user notification settings', async () => {
      const user = await createTestUser();

      const { request } = await authenticatedRequest('PUT', `/api/notifications/user/${user._id}/settings`);

      const newSettings = {
        push: false,
        email: true,
        sms: true,
        bookingUpdates: false,
        promotionalOffers: false,
        paymentReminders: true,
        driverMessages: true
      };

      const response = await request.send(newSettings);
      const result = expectSuccess(response);

      expect(result.data.notificationSettings.push).toBe(false);
      expect(result.data.notificationSettings.email).toBe(true);
      expect(result.data.notificationSettings.sms).toBe(true);
      expect(result.data.notificationSettings.bookingUpdates).toBe(false);
    });

    test('should only update valid settings', async () => {
      const user = await createTestUser();

      const { request } = await authenticatedRequest('PUT', `/api/notifications/user/${user._id}/settings`);

      const response = await request.send({
        push: false,
        invalidSetting: true, // Should be ignored
        anotherInvalid: 'value'
      });

      const result = expectSuccess(response);
      expect(result.data.notificationSettings.push).toBe(false);
      expect(result.data.notificationSettings).not.toHaveProperty('invalidSetting');
      expect(result.data.notificationSettings).not.toHaveProperty('anotherInvalid');
    });

    test('should fail for non-owner user', async () => {
      const user1 = await createTestUser({ email: 'user1@test.com' });
      const user2 = await createTestUser({ email: 'user2@test.com' });

      const { request } = await authenticatedRequest('PUT', `/api/notifications/user/${user1._id}/settings`, user2);

      const response = await request.send({ push: false });
      expectError(response, 403);
    });
  });

  describe('POST /api/notifications/user/:userId/fcm-token - Register FCM Token', () => {
    test('should register FCM token successfully', async () => {
      const user = await createTestUser();

      const { request } = await authenticatedRequest('POST', `/api/notifications/user/${user._id}/fcm-token`);

      const fcmToken = 'fcm_token_123456789';

      const response = await request.send({ fcmToken });
      expectSuccess(response);

      // Verify token is saved
      const updatedUser = await require('../models/User').findById(user._id);
      expect(updatedUser.fcmToken).toBe(fcmToken);
    });

    test('should fail without FCM token', async () => {
      const user = await createTestUser();

      const { request } = await authenticatedRequest('POST', `/api/notifications/user/${user._id}/fcm-token`);

      const response = await request.send({});
      expectError(response, 400);
    });

    test('should fail for wrong user', async () => {
      const user1 = await createTestUser({ email: 'user1@test.com' });
      const user2 = await createTestUser({ email: 'user2@test.com' });

      const { request } = await authenticatedRequest('POST', `/api/notifications/user/${user1._id}/fcm-token`, user2);

      const response = await request.send({ fcmToken: 'token123' });
      expectError(response, 403);
    });
  });

  describe('POST /api/notifications/sms - Send SMS (Admin)', () => {
    test('should send SMS successfully', async () => {
      const { request } = await adminRequest('POST', '/api/notifications/sms');

      const response = await request.send({
        phoneNumber: '+1234567890',
        message: 'Test SMS message'
      });

      const result = expectSuccess(response);
      expect(result.data.success).toBe(true);
      expect(result.data.messageId).toBe('sms-test-id');
    });

    test('should fail without required fields', async () => {
      const { request } = await adminRequest('POST', '/api/notifications/sms');

      const response = await request.send({ message: 'Test message' });
      expectError(response, 400);
    });

    test('should fail for non-admin user', async () => {
      const { request } = await authenticatedRequest('POST', '/api/notifications/sms');

      const response = await request.send({
        phoneNumber: '+1234567890',
        message: 'Test message'
      });

      expectError(response, 403);
    });
  });

  describe('DELETE /api/notifications/user/:userId/:notificationId - Delete Notification', () => {
    test('should delete user notification', async () => {
      const user = await createTestUser();

      const notification = await Notification.create({
        userId: user._id,
        type: 'booking_confirmed',
        title: 'Booking Confirmed',
        message: 'Your booking is confirmed',
        channels: ['push']
      });

      const { request } = await authenticatedRequest('DELETE', `/api/notifications/user/${user._id}/${notification._id}`);

      const response = await request;
      expectSuccess(response);

      // Verify notification is deleted
      const deletedNotification = await Notification.findById(notification._id);
      expect(deletedNotification).toBeNull();
    });

    test('should allow admin to delete any notification', async () => {
      const user = await createTestUser();

      const notification = await Notification.create({
        userId: user._id,
        type: 'booking_confirmed',
        title: 'Booking Confirmed',
        message: 'Your booking is confirmed',
        channels: ['push']
      });

      const { request } = await adminRequest('DELETE', `/api/notifications/user/${user._id}/${notification._id}`);

      const response = await request;
      expectSuccess(response);
    });

    test('should fail for non-owner non-admin user', async () => {
      const user1 = await createTestUser({ email: 'user1@test.com' });
      const user2 = await createTestUser({ email: 'user2@test.com' });

      const notification = await Notification.create({
        userId: user1._id,
        type: 'booking_confirmed',
        title: 'Booking Confirmed',
        message: 'Your booking is confirmed',
        channels: ['push']
      });

      const { request } = await authenticatedRequest('DELETE', `/api/notifications/user/${user1._id}/${notification._id}`, user2);

      const response = await request;
      expectError(response, 403);
    });
  });

  describe('Notification Model Methods', () => {
    test('should mark notification as read', async () => {
      const user = await createTestUser();

      const notification = await Notification.create({
        userId: user._id,
        type: 'booking_confirmed',
        title: 'Test',
        message: 'Test message',
        channels: ['push']
      });

      expect(notification.isRead).toBe(false);

      await notification.markAsRead();

      expect(notification.status.inApp.read).toBe(true);
      expect(notification.status.inApp.readAt).toBeDefined();
      expect(notification.isRead).toBe(true);
    });

    test('should update delivery status', async () => {
      const user = await createTestUser();

      const notification = await Notification.create({
        userId: user._id,
        type: 'booking_confirmed',
        title: 'Test',
        message: 'Test message',
        channels: ['push', 'email']
      });

      await notification.updateDeliveryStatus('push', true);
      await notification.updateDeliveryStatus('email', false, 'Email service error');

      expect(notification.status.push.sent).toBe(true);
      expect(notification.status.push.sentAt).toBeDefined();
      expect(notification.status.email.sent).toBe(false);
      expect(notification.status.email.error).toBe('Email service error');
    });

    test('should calculate delivery status correctly', async () => {
      const user = await createTestUser();

      const notification = await Notification.create({
        userId: user._id,
        type: 'booking_confirmed',
        title: 'Test',
        message: 'Test message',
        channels: ['push', 'email']
      });

      expect(notification.isDelivered).toBe(false);

      await notification.updateDeliveryStatus('push', true);
      expect(notification.isDelivered).toBe(false); // Email not sent yet

      await notification.updateDeliveryStatus('email', true);
      expect(notification.isDelivered).toBe(true);
    });

    test('should find unread notifications', async () => {
      const user = await createTestUser();

      await Notification.create({
        userId: user._id,
        type: 'booking_confirmed',
        title: 'Read',
        message: 'Read message',
        channels: ['push'],
        status: { inApp: { read: true } }
      });

      await Notification.create({
        userId: user._id,
        type: 'payment_received',
        title: 'Unread',
        message: 'Unread message',
        channels: ['push']
      });

      const unreadNotifications = await Notification.findUnread(user._id);
      expect(unreadNotifications.length).toBe(1);
      expect(unreadNotifications[0].title).toBe('Unread');
    });

    test('should find notifications by type', async () => {
      const user = await createTestUser();

      await Notification.create({
        userId: user._id,
        type: 'booking_confirmed',
        title: 'Booking 1',
        message: 'Booking confirmed',
        channels: ['push']
      });

      await Notification.create({
        userId: user._id,
        type: 'payment_received',
        title: 'Payment 1',
        message: 'Payment received',
        channels: ['push']
      });

      await Notification.create({
        userId: user._id,
        type: 'booking_confirmed',
        title: 'Booking 2',
        message: 'Another booking',
        channels: ['push']
      });

      const bookingNotifications = await Notification.findByType(user._id, 'booking_confirmed');
      expect(bookingNotifications.length).toBe(2);
      bookingNotifications.forEach(notification => {
        expect(notification.type).toBe('booking_confirmed');
      });
    });
  });
});
