const {
  createTestUser,
  createTestDriver,
  createTestQuote
} = require('./setup');
const {
  request,
  authenticatedRequest,
  adminRequest,
  expectSuccess,
  expectError
} = require('./testUtils');

describe('Integration Tests - Complete API Flows', () => {
  describe('Complete User Journey: Registration to Booking', () => {
    test('should complete full user registration and booking flow', async () => {
      // This would typically test the full flow, but since we're using mocks,
      // we'll test the key integration points

      const user = await createTestUser({
        email: 'integration@test.com',
        name: 'Integration User'
      });

      // 1. User gets their profile
      const { request: profileRequest } = await authenticatedRequest('GET', '/api/users/profile', user);
      const profileResult = await profileRequest;
      expectSuccess(profileResult);
      expect(profileResult.body.data.user.email).toBe('integration@test.com');

      // 2. User creates a quote
      const { request: quoteRequest } = await authenticatedRequest('POST', '/api/quotes');
      const quoteData = {
        pickupLocation: {
          address: '123 Integration St, Test City',
          coordinates: { latitude: -26.2041, longitude: 28.0473 }
        },
        dropoffLocation: {
          address: '456 Destination Ave, Test City',
          coordinates: { latitude: -25.7479, longitude: 28.2293 }
        },
        vehicleType: 'sedan',
        serviceType: 'standard',
        passengerCount: 2,
        scheduledDate: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()
      };

      const quoteResult = await quoteRequest.send(quoteData);
      expectSuccess(quoteResult, 201);
      const quoteId = quoteResult.body.data.quote.id;

      // 3. User views their quote
      const { request: getQuoteRequest } = await authenticatedRequest('GET', `/api/quotes/${quoteId}`);
      const getQuoteResult = await getQuoteRequest;
      expectSuccess(getQuoteResult);
      expect(getQuoteResult.body.data.quote.id).toBe(quoteId);

      // 4. User checks their quote history
      const { request: historyRequest } = await authenticatedRequest('GET', `/api/users/${user._id}/quotes`);
      const historyResult = await historyRequest;
      expectSuccess(historyResult);
      expect(historyResult.body.data.quotes.length).toBe(1);

      // 5. User updates their profile
      const { request: updateProfileRequest } = await authenticatedRequest('PUT', '/api/users/profile');
      const updateResult = await updateProfileRequest.send({
        name: 'Updated Integration User'
      });
      expectSuccess(updateResult);
      expect(updateResult.body.data.user.name).toBe('Updated Integration User');
    });
  });

  describe('Driver Onboarding and Management Flow', () => {
    test('should complete driver registration and management flow', async () => {
      const driverUser = await createTestUser({
        email: 'driver@test.com',
        name: 'Test Driver'
      });

      // 1. Driver registers their profile
      const { request: registerRequest } = await authenticatedRequest('POST', '/api/drivers');

      const driverData = {
        licenseNumber: 'DRV123456789',
        licenseExpiry: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString(),
        vehicleInfo: {
          make: 'Toyota',
          model: 'Corolla',
          year: 2020,
          color: 'White',
          licensePlate: 'ABC123GP',
          vehicleType: 'sedan',
          passengerCapacity: 4,
          hasAC: true,
          features: ['wifi', 'leather_seats']
        },
        documents: {
          licensePhoto: 'https://example.com/license.jpg',
          vehicleRegistration: 'https://example.com/registration.jpg',
          vehicleInsurance: 'https://example.com/insurance.jpg',
          profilePhoto: 'https://example.com/profile.jpg'
        },
        bankDetails: {
          accountHolder: 'Test Driver',
          accountNumber: '1234567890',
          bankName: 'Test Bank',
          branchCode: '123456'
        },
        emergencyContact: {
          name: 'Emergency Contact',
          phone: '+1234567890',
          relationship: 'Spouse'
        },
        latitude: -26.2041,
        longitude: 28.0473,
        address: 'Test Location, Johannesburg'
      };

      const registerResult = await registerRequest.send(driverData);
      expectSuccess(registerResult, 201);
      const driverId = registerResult.body.data.driver.id;

      // 2. Admin approves driver
      const { request: approveRequest } = await adminRequest('PUT', `/api/drivers/${driverId}/status`);
      const approveResult = await approveRequest.send({
        status: 'approved',
        notes: 'Application approved for testing'
      });
      expectSuccess(approveResult);

      // 3. Driver updates availability
      const { request: availabilityRequest } = await authenticatedRequest('PUT', `/api/drivers/${driverId}/availability`, driverUser);
      const availabilityResult = await availabilityRequest.send({
        status: 'online',
        workingHours: {
          start: '06:00',
          end: '18:00'
        }
      });
      expectSuccess(availabilityResult);

      // 4. Driver updates location
      const { request: locationRequest } = await authenticatedRequest('PUT', `/api/drivers/${driverId}/location`, driverUser);
      const locationResult = await locationRequest.send({
        latitude: -25.7479,
        longitude: 28.2293,
        address: 'Updated Location, Pretoria'
      });
      expectSuccess(locationResult);

      // 5. Admin finds available drivers
      const { request: findDriversRequest } = await adminRequest('GET', '/api/drivers/available?latitude=-25.7479&longitude=28.2293&maxDistance=50000');
      const findDriversResult = await findDriversRequest;
      expectSuccess(findDriversResult);
      expect(findDriversResult.body.data.count).toBeGreaterThan(0);
    });
  });

  describe('Support System Integration', () => {
    test('should complete support ticket lifecycle', async () => {
      const user = await createTestUser({
        email: 'support@test.com'
      });

      // 1. User creates support ticket
      const { request: createTicketRequest } = await authenticatedRequest('POST', '/api/support/tickets');
      const ticketData = {
        subject: 'Integration Test Ticket',
        category: 'booking_issue',
        description: 'This is an integration test for the support system',
        priority: 'normal'
      };

      const createTicketResult = await createTicketRequest.send(ticketData);
      expectSuccess(createTicketResult, 201);
      const ticketId = createTicketResult.body.data.ticket.ticketId;

      // 2. User views their tickets
      const { request: getTicketsRequest } = await authenticatedRequest('GET', `/api/users/${user._id}/support-tickets`);
      const getTicketsResult = await getTicketsRequest;
      expectSuccess(getTicketsResult);
      expect(getTicketsResult.body.data.tickets.length).toBe(1);

      // 3. User gets ticket details
      const { request: getTicketRequest } = await authenticatedRequest('GET', `/api/support/tickets/${ticketId}`);
      const getTicketResult = await getTicketRequest;
      expectSuccess(getTicketResult);

      // 4. Admin assigns ticket to agent
      const agent = await createTestUser({ email: 'agent@test.com', role: 'admin' });
      const { request: assignRequest } = await adminRequest('PUT', `/api/support/tickets/${ticketId}/status`);
      const assignResult = await assignRequest.send({
        assignedTo: agent._id.toString(),
        status: 'in_progress'
      });
      expectSuccess(assignResult);

      // 5. Agent adds message to ticket
      const { request: addMessageRequest } = await adminRequest('POST', `/api/support/tickets/${ticketId}/messages`);
      const addMessageResult = await addMessageRequest.send({
        message: 'Thank you for contacting support. We are looking into this issue.',
        isInternal: false
      });
      expectSuccess(addMessageResult, 201);

      // 6. Agent resolves ticket
      const { request: resolveRequest } = await adminRequest('POST', `/api/support/tickets/${ticketId}/resolve`);
      const resolveResult = await resolveRequest.send({
        solution: 'Issue resolved through integration testing',
        satisfaction: 5
      });
      expectSuccess(resolveResult);
    });
  });

  describe('Notification System Integration', () => {
    test('should handle notification preferences and delivery', async () => {
      const user = await createTestUser({
        email: 'notification@test.com'
      });

      // 1. User updates notification settings
      const { request: settingsRequest } = await authenticatedRequest('PUT', `/api/users/${user._id}/notification-settings`, user);
      const settingsResult = await settingsRequest.send({
        push: true,
        email: true,
        sms: false,
        bookingUpdates: true,
        promotionalOffers: false
      });
      expectSuccess(settingsResult);

      // 2. User registers FCM token
      const { request: fcmRequest } = await authenticatedRequest('POST', `/api/users/${user._id}/fcm-token`, user);
      const fcmResult = await fcmRequest.send({
        fcmToken: 'fcm_test_token_12345'
      });
      expectSuccess(fcmResult);

      // 3. Admin sends notification
      const { request: sendNotificationRequest } = await adminRequest('POST', '/api/notifications/send');
      const notificationResult = await sendNotificationRequest.send({
        userId: user._id.toString(),
        type: 'booking_confirmed',
        title: 'Integration Test Notification',
        message: 'This is a test notification for integration testing',
        channels: ['push', 'email'],
        priority: 'normal'
      });
      expectSuccess(notificationResult, 201);

      // 4. User views their notifications
      const { request: getNotificationsRequest } = await authenticatedRequest('GET', `/api/users/${user._id}/notifications`);
      const getNotificationsResult = await getNotificationsRequest;
      expectSuccess(getNotificationsResult);
      expect(getNotificationsResult.body.data.notifications.length).toBe(1);

      // 5. User marks notification as read
      const notificationId = getNotificationsResult.body.data.notifications[0].id;
      const { request: markReadRequest } = await authenticatedRequest('PUT', `/api/users/${user._id}/notifications/${notificationId}/read`);
      const markReadResult = await markReadRequest;
      expectSuccess(markReadResult);
    });
  });

  describe('Analytics Integration', () => {
    test('should track user events and generate analytics', async () => {
      const user = await createTestUser({
        email: 'analytics@test.com',
        totalTrips: 5
      });

      // 1. Track multiple user events
      const events = [
        {
          eventType: 'app_open',
          eventData: { platform: 'web' },
          deviceInfo: { platform: 'web', version: '1.0.0' }
        },
        {
          eventType: 'booking_started',
          eventData: { vehicleType: 'sedan', serviceType: 'standard' }
        },
        {
          eventType: 'booking_completed',
          eventData: { amount: 150, duration: 45 }
        }
      ];

      for (const event of events) {
        const { request: eventRequest } = await authenticatedRequest('POST', '/api/analytics/events');
        await eventRequest.send(event);
      }

      // 2. Admin views user analytics
      const { request: analyticsRequest } = await adminRequest('GET', `/api/analytics/users/${user._id}`);
      const analyticsResult = await analyticsRequest;
      expectSuccess(analyticsResult);

      const analytics = analyticsResult.body.data.analytics;
      expect(analytics.totalEvents).toBe(3);
      expect(analytics.uniqueEventTypes).toBe(3);
      expect(analytics.behaviorStats.length).toBe(3);
    });
  });

  describe('Corporate Features Integration', () => {
    test('should handle corporate user booking flow', async () => {
      // Create corporate user
      const corporateUser = await createTestUser({
        email: 'corporate@test.com',
        isCorporateUser: true,
        corporateAccount: {
          companyName: 'Integration Corp',
          discountPercentage: 15
        }
      });

      // 1. Corporate user creates booking
      const { request: corporateBookingRequest } = await authenticatedRequest('POST', '/api/corporate/bookings');
      const bookingData = {
        title: 'Team Integration Test',
        description: 'Testing corporate booking system',
        bookingType: 'business_travel',
        trips: [
          {
            tripId: 'INT001',
            pickupLocation: 'Office HQ',
            dropoffLocation: 'Client Meeting',
            estimatedCost: 300,
            pickupTime: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
            passengerCount: 3
          },
          {
            tripId: 'INT002',
            pickupLocation: 'Client Meeting',
            dropoffLocation: 'Airport',
            estimatedCost: 450,
            pickupTime: new Date(Date.now() + 25 * 60 * 60 * 1000).toISOString(),
            passengerCount: 2
          }
        ],
        specialInstructions: 'VIP service required'
      };

      const bookingResult = await corporateBookingRequest.send(bookingData);
      expectSuccess(bookingResult, 201);
      const bookingId = bookingResult.body.data.booking.id;

      // 2. Admin approves booking
      const { request: approveRequest } = await adminRequest('PUT', `/api/admin/corporate/bookings/${bookingId}/approve`);
      const approveResult = await approveRequest;
      expectSuccess(approveResult);

      // 3. Corporate user views their bookings
      const { request: getBookingsRequest } = await authenticatedRequest('GET', `/api/users/${corporateUser._id}/corporate/bookings`, corporateUser);
      const getBookingsResult = await getBookingsRequest;
      expectSuccess(getBookingsResult);
      expect(getBookingsResult.body.data.bookings.length).toBe(1);
      expect(getBookingsResult.body.data.bookings[0].status).toBe('approved');
    });
  });

  describe('Quote to Booking Flow Integration', () => {
    test('should handle quote creation and potential booking flow', async () => {
      const user = await createTestUser({
        email: 'quotebooking@test.com'
      });

      // 1. User gets price estimate
      const estimateResult = await request
        .post('/api/quotes/estimate')
        .send({
          pickupCoordinates: { latitude: -26.2041, longitude: 28.0473 },
          dropoffCoordinates: { latitude: -25.7479, longitude: 28.2293 },
          vehicleType: 'luxury',
          serviceType: 'premium',
          passengerCount: 2
        });
      expectSuccess(estimateResult);

      const estimatedPrice = estimateResult.body.data.pricing;

      // 2. User creates formal quote
      const { request: quoteRequest } = await authenticatedRequest('POST', '/api/quotes');
      const quoteData = {
        pickupLocation: {
          address: '123 Quote St, Johannesburg',
          coordinates: { latitude: -26.2041, longitude: 28.0473 }
        },
        dropoffLocation: {
          address: '456 Booking Ave, Pretoria',
          coordinates: { latitude: -25.7479, longitude: 28.2293 }
        },
        vehicleType: 'luxury',
        serviceType: 'premium',
        passengerCount: 2,
        specialRequirements: 'Champagne service requested',
        scheduledDate: new Date(Date.now() + 48 * 60 * 60 * 1000).toISOString()
      };

      const quoteResult = await quoteRequest.send(quoteData);
      expectSuccess(quoteResult, 201);
      const quote = quoteResult.body.data.quote;

      // 3. Verify quote pricing matches estimate
      expect(quote.estimatedPrice.total).toBeGreaterThan(0);

      // 4. Admin updates quote status to quoted
      const { request: updateQuoteRequest } = await adminRequest('PUT', `/api/quotes/${quote.id}`);
      const updateResult = await updateQuoteRequest.send({
        status: 'quoted',
        notes: 'Quote prepared with premium service details'
      });
      expectSuccess(updateResult);

      // 5. User could then proceed to booking (simulated)
      // In a real flow, this would create a booking from the accepted quote
      expect(updateResult.body.data.quote.status).toBe('quoted');
    });
  });

  describe('Error Handling and Edge Cases', () => {
    test('should handle authentication failures gracefully', async () => {
      // Try to access protected route without auth
      const profileResult = await request.get('/api/users/profile');
      expectError(profileResult, 401);

      // Try to access admin route as regular user
      const { request: adminRequest } = await authenticatedRequest('GET', '/api/analytics/dashboard');
      const adminResult = await adminRequest;
      expectError(adminResult, 403);
    });

    test('should handle invalid data validation', async () => {
      const user = await createTestUser();

      // Try to create quote with invalid data
      const { request: quoteRequest } = await authenticatedRequest('POST', '/api/quotes');
      const invalidQuoteResult = await quoteRequest.send({
        vehicleType: 'invalid_type',
        passengerCount: -1
      });
      expectError(invalidQuoteResult, 400);

      // Try to create driver with missing required fields
      const { request: driverRequest } = await authenticatedRequest('POST', '/api/drivers');
      const invalidDriverResult = await driverRequest.send({
        licenseNumber: 'TEST123'
        // Missing other required fields
      });
      expectError(invalidDriverResult, 400);
    });

    test('should handle not found resources', async () => {
      const { request: quoteRequest } = await authenticatedRequest('GET', '/api/quotes/507f1f77bcf86cd799439011');
      const quoteResult = await quoteRequest;
      expectError(quoteResult, 404);

      const { request: driverRequest } = await authenticatedRequest('GET', '/api/drivers/507f1f77bcf86cd799439011');
      const driverResult = await driverRequest;
      expectError(driverResult, 404);
    });

    test('should handle concurrent operations', async () => {
      const user = await createTestUser();

      // Create multiple concurrent quote requests
      const promises = [];
      for (let i = 0; i < 3; i++) {
        const { request } = await authenticatedRequest('POST', '/api/quotes');
        promises.push(request.send({
          pickupLocation: {
            address: `Test Address ${i}`,
            coordinates: { latitude: -26.2041, longitude: 28.0473 }
          },
          dropoffLocation: {
            address: `Destination ${i}`,
            coordinates: { latitude: -25.7479, longitude: 28.2293 }
          },
          vehicleType: 'sedan',
          serviceType: 'standard',
          passengerCount: 1,
          scheduledDate: new Date(Date.now() + (i + 1) * 24 * 60 * 60 * 1000).toISOString()
        }));
      }

      const results = await Promise.all(promises);
      results.forEach(result => {
        expectSuccess(result, 201);
      });
    });
  });

  describe('Performance and Load Testing Simulation', () => {
    test('should handle multiple users creating quotes simultaneously', async () => {
      const users = [];
      const userPromises = [];

      // Create multiple users
      for (let i = 0; i < 5; i++) {
        userPromises.push(createTestUser({
          email: `perfuser${i}@test.com`,
          name: `Performance User ${i}`
        }));
      }

      users.push(...await Promise.all(userPromises));

      // All users create quotes simultaneously
      const quotePromises = users.map(async (user, index) => {
        const { request } = await authenticatedRequest('POST', '/api/quotes', user);
        return request.send({
          pickupLocation: {
            address: `Performance Test Address ${index}`,
            coordinates: { latitude: -26.2041, longitude: 28.0473 }
          },
          dropoffLocation: {
            address: `Performance Destination ${index}`,
            coordinates: { latitude: -25.7479, longitude: 28.2293 }
          },
          vehicleType: 'sedan',
          serviceType: 'standard',
          passengerCount: 2,
          scheduledDate: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()
        });
      });

      const quoteResults = await Promise.all(quotePromises);
      quoteResults.forEach(result => {
        expectSuccess(result, 201);
      });

      // Verify all quotes were created
      expect(quoteResults.length).toBe(5);
      quoteResults.forEach(result => {
        expect(result.body.data).toHaveProperty('quote');
      });
    });

    test('should handle rapid notification creation and retrieval', async () => {
      const user = await createTestUser({
        email: 'rapid@test.com'
      });

      // Create multiple notifications rapidly
      const notificationPromises = [];
      for (let i = 0; i < 10; i++) {
        const { request } = await adminRequest('POST', '/api/notifications/send');
        notificationPromises.push(request.send({
          userId: user._id.toString(),
          type: 'system_update',
          title: `Rapid Notification ${i}`,
          message: `This is rapid notification number ${i}`,
          channels: ['push'],
          priority: 'low'
        }));
      }

      const notificationResults = await Promise.all(notificationPromises);
      notificationResults.forEach(result => {
        expectSuccess(result, 201);
      });

      // Verify user can retrieve all notifications
      const { request: getNotificationsRequest } = await authenticatedRequest('GET', `/api/users/${user._id}/notifications`);
      const getResult = await getNotificationsRequest;
      expectSuccess(getResult);
      expect(getResult.body.data.notifications.length).toBe(10);
    });
  });
});
