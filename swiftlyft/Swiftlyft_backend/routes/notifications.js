const express = require('express');
const rateLimit = require('express-rate-limit');
const Notification = require('../models/Notification');
const User = require('../models/User');
const { authenticateToken, requireAdmin } = require('../middleware/auth');
const { sendEmail } = require('../utils/email');

const router = express.Router();

// Rate limiting
const notificationLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 50,
  message: {
    success: false,
    message: 'Too many notification requests, please try again later'
  }
});

// Mock FCM service - in production, use Firebase Admin SDK
const sendPushNotification = async (fcmToken, title, message, data = {}) => {
  try {
    // Mock implementation - in production, use Firebase
    console.log(`📱 Push notification sent to ${fcmToken}: ${title} - ${message}`);

    return {
      success: true,
      messageId: `mock_${Date.now()}`
    };
  } catch (error) {
    console.error('Push notification error:', error);
    return {
      success: false,
      error: error.message
    };
  }
};

// Mock SMS service - in production, integrate with SMS provider
const sendSMS = async (phoneNumber, message) => {
  try {
    // Mock implementation - in production, use SMS service like Twilio
    console.log(`📱 SMS sent to ${phoneNumber}: ${message}`);

    return {
      success: true,
      messageId: process.env.NODE_ENV === 'test' ? 'sms-test-id' : `sms_${Date.now()}`
    };
  } catch (error) {
    console.error('SMS error:', error);
    return {
      success: false,
      error: error.message
    };
  }
};

// @route   POST /api/notifications/send
// @desc    Send notification (admin only)
// @access  Private/Admin
router.post('/send', authenticateToken, requireAdmin, notificationLimiter, async (req, res, next) => {
  try {
    const {
      userId,
      type,
      title,
      message,
      channels = ['push'],
      priority = 'normal',
      data = {},
      scheduledFor
    } = req.body;

    if (!userId || !type || !title || !message) {
      return res.status(400).json({
        success: false,
        message: 'User ID, type, title, and message are required'
      });
    }

    // Get user notification settings
    const user = await User.findById(userId).select('notificationSettings fcmToken email phoneNumber');
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Create notification record
    const notification = new Notification({
      userId,
      type,
      title,
      message,
      data,
      channels,
      priority,
      scheduledFor: scheduledFor ? new Date(scheduledFor) : null
    });

    // Send immediate notifications (skip if scheduled)
    let deliveryResults = null;
    if (!scheduledFor) {
      deliveryResults = {};

      // Send push notification
      if (channels.includes('push') && user.notificationSettings.push && user.fcmToken) {
        const pushResult = await sendPushNotification(user.fcmToken, title, message, data);
        deliveryResults.push = pushResult;
        await notification.updateDeliveryStatus('push', pushResult.success, pushResult.error);
      }

      // Send email
      if (channels.includes('email') && user.notificationSettings.email && user.email) {
        const emailResult = await sendEmail(user.email, title, message);
        deliveryResults.email = emailResult;
        await notification.updateDeliveryStatus('email', emailResult.success, emailResult.error);
      }

      // Send SMS
      if (channels.includes('sms') && user.notificationSettings.sms && user.phoneNumber) {
        const smsResult = await sendSMS(user.phoneNumber, message);
        deliveryResults.sms = smsResult;
        await notification.updateDeliveryStatus('sms', smsResult.success, smsResult.error);
      }
    }

    await notification.save();

    res.status(201).json({
      success: true,
      message: scheduledFor ? 'Notification scheduled successfully' : 'Notification sent successfully',
      data: {
        notification: notification.toJSON(),
        deliveryResults
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/users/:userId/notifications
// @desc    Get user's notifications
// @access  Private
router.get('/user/:userId', authenticateToken, async (req, res, next) => {
  try {
    const { userId } = req.params;
    const { page = 1, limit = 20, unreadOnly = false } = req.query;

    // Check permissions
    if (userId !== req.userId.toString() && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    const query = { userId };
    if (unreadOnly === 'true') {
      query['status.inApp.read'] = false;
    }

    // Exclude expired notifications
    query.$or = [
      { expiresAt: { $exists: false } },
      { expiresAt: { $gt: new Date() } }
    ];

    const notifications = await Notification.find(query)
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await Notification.countDocuments(query);

    res.json({
      success: true,
      data: {
        notifications: notifications.map(n => n.toJSON()),
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / limit)
        },
        unreadCount: await Notification.countDocuments({
          userId,
          'status.inApp.read': false,
          $or: [
            { expiresAt: { $exists: false } },
            { expiresAt: { $gt: new Date() } }
          ]
        })
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   PUT /api/users/:userId/notifications/:notificationId/read
// @desc    Mark notification as read
// @access  Private
router.put('/user/:userId/:notificationId/read', authenticateToken, async (req, res, next) => {
  try {
    const { userId, notificationId } = req.params;

    // Check permissions
    if (userId !== req.userId.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    const notification = await Notification.findOne({
      _id: notificationId,
      userId
    });

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    await notification.markAsRead();

    res.json({
      success: true,
      message: 'Notification marked as read'
    });

  } catch (error) {
    next(error);
  }
});

// @route   POST /api/users/:userId/notifications/mark-all-read
// @desc    Mark all notifications as read
// @access  Private
router.post('/user/:userId/mark-all-read', authenticateToken, async (req, res, next) => {
  try {
    const { userId } = req.params;

    // Check permissions
    if (userId !== req.userId.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    const result = await Notification.updateMany(
      {
        userId,
        'status.inApp.read': false,
        $or: [
          { expiresAt: { $exists: false } },
          { expiresAt: { $gt: new Date() } }
        ]
      },
      {
        'status.inApp.read': true,
        'status.inApp.readAt': new Date()
      }
    );

    res.json({
      success: true,
      message: `${result.modifiedCount} notifications marked as read`
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/users/:userId/notification-settings
// @desc    Get user notification settings
// @access  Private
router.get('/user/:userId/settings', authenticateToken, async (req, res, next) => {
  try {
    const { userId } = req.params;

    // Check permissions
    if (userId !== req.userId.toString() && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    const user = await User.findById(userId).select('notificationSettings');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      data: {
        notificationSettings: user.notificationSettings
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   PUT /api/users/:userId/notification-settings
// @desc    Update user notification settings
// @access  Private
router.put('/user/:userId/settings', authenticateToken, async (req, res, next) => {
  try {
    const { userId } = req.params;
    const settings = req.body;

    // Check permissions
    if (userId !== req.userId.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Validate settings
    const validSettings = [
      'push', 'email', 'sms', 'bookingUpdates',
      'promotionalOffers', 'paymentReminders', 'driverMessages'
    ];

    const updateData = {};
    Object.keys(settings).forEach(key => {
      if (validSettings.includes(key)) {
        updateData[`notificationSettings.${key}`] = settings[key];
      }
    });

    const user = await User.findByIdAndUpdate(
      userId,
      updateData,
      { new: true, select: 'notificationSettings' }
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      message: 'Notification settings updated successfully',
      data: {
        notificationSettings: user.notificationSettings
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   POST /api/users/:userId/fcm-token
// @desc    Register FCM token for push notifications
// @access  Private
router.post('/user/:userId/fcm-token', authenticateToken, async (req, res, next) => {
  try {
    const { userId } = req.params;
    const { fcmToken } = req.body;

    // Check permissions
    if (userId !== req.userId.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    if (!fcmToken) {
      return res.status(400).json({
        success: false,
        message: 'FCM token is required'
      });
    }

    await User.findByIdAndUpdate(userId, { fcmToken });

    res.json({
      success: true,
      message: 'FCM token registered successfully'
    });

  } catch (error) {
    next(error);
  }
});

// @route   POST /api/notifications/sms
// @desc    Send SMS notification (admin only)
// @access  Private/Admin
router.post('/sms', authenticateToken, requireAdmin, notificationLimiter, async (req, res, next) => {
  try {
    const { phoneNumber, message } = req.body;

    if (!phoneNumber || !message) {
      return res.status(400).json({
        success: false,
        message: 'Phone number and message are required'
      });
    }

    const smsResult = await sendSMS(phoneNumber, message);

    res.json({
      success: smsResult.success,
      message: smsResult.success ? 'SMS sent successfully' : 'Failed to send SMS',
      data: smsResult
    });

  } catch (error) {
    next(error);
  }
});

// @route   DELETE /api/users/:userId/notifications/:notificationId
// @desc    Delete notification
// @access  Private
router.delete('/user/:userId/:notificationId', authenticateToken, async (req, res, next) => {
  try {
    const { userId, notificationId } = req.params;

    // Check permissions
    if (userId !== req.userId.toString() && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    const notification = await Notification.findOneAndDelete({
      _id: notificationId,
      userId
    });

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    res.json({
      success: true,
      message: 'Notification deleted successfully'
    });

  } catch (error) {
    next(error);
  }
});

module.exports = router;
