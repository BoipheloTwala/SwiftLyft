const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'User ID is required']
  },
  type: {
    type: String,
    required: true,
    enum: [
      'booking_confirmed',
      'driver_assigned',
      'driver_arrived',
      'trip_started',
      'trip_completed',
      'payment_received',
      'payment_failed',
      'quote_ready',
      'driver_cancelled',
      'system_update',
      'promotion',
      'loyalty_points',
      'support_response',
      'reminder'
    ]
  },
  title: {
    type: String,
    required: true,
    maxlength: [100, 'Title cannot exceed 100 characters']
  },
  message: {
    type: String,
    required: true,
    maxlength: [500, 'Message cannot exceed 500 characters']
  },
  data: {
    type: mongoose.Schema.Types.Mixed // Additional data like bookingId, amount, etc.
  },
  channels: [{
    type: String,
    enum: ['push', 'email', 'sms', 'in_app'],
    default: ['push']
  }],
  priority: {
    type: String,
    enum: ['low', 'normal', 'high', 'urgent'],
    default: 'normal'
  },
  status: {
    push: {
      sent: { type: Boolean, default: false },
      sentAt: Date,
      error: String
    },
    email: {
      sent: { type: Boolean, default: false },
      sentAt: Date,
      error: String
    },
    sms: {
      sent: { type: Boolean, default: false },
      sentAt: Date,
      error: String
    },
    inApp: {
      read: { type: Boolean, default: false },
      readAt: Date
    }
  },
  expiresAt: Date,
  scheduledFor: Date // For scheduled notifications
}, {
  timestamps: true,
  toJSON: {
    transform: function(doc, ret) {
      ret.id = ret._id;
      delete ret._id;
      delete ret.__v;
      return ret;
    }
  }
});

// Indexes for performance
notificationSchema.index({ userId: 1, createdAt: -1 });
notificationSchema.index({ type: 1, createdAt: -1 });
notificationSchema.index({ scheduledFor: 1 });
notificationSchema.index({ expiresAt: 1 });

// Virtual for read status
notificationSchema.virtual('isRead').get(function() {
  return this.status.inApp.read;
});

// Virtual for delivery status
notificationSchema.virtual('isDelivered').get(function() {
  const channels = this.channels;
  return channels.every(channel => {
    switch(channel) {
      case 'push': return this.status.push.sent;
      case 'email': return this.status.email.sent;
      case 'sms': return this.status.sms.sent;
      case 'in_app': return true; // In-app is always "delivered"
      default: return false;
    }
  });
});

// Instance methods
notificationSchema.methods.markAsRead = function() {
  this.status.inApp.read = true;
  this.status.inApp.readAt = new Date();
  return this.save();
};

notificationSchema.methods.updateDeliveryStatus = function(channel, success, error = null) {
  if (!this.status[channel]) return;

  if (success) {
    this.status[channel].sent = true;
    this.status[channel].sentAt = new Date();
    this.status[channel].error = undefined;
  } else {
    this.status[channel].error = error;
  }

  return this.save();
};

// Static methods
notificationSchema.statics.findUnread = function(userId) {
  return this.find({
    userId,
    'status.inApp.read': false,
    $or: [
      { expiresAt: { $exists: false } },
      { expiresAt: { $gt: new Date() } }
    ]
  }).sort({ createdAt: -1 });
};

notificationSchema.statics.findByType = function(userId, type, limit = 50) {
  return this.find({ userId, type })
    .sort({ createdAt: -1 })
    .limit(limit);
};

notificationSchema.statics.markAllAsRead = function(userId) {
  return this.updateMany(
    { userId, 'status.inApp.read': false },
    {
      'status.inApp.read': true,
      'status.inApp.readAt': new Date()
    }
  );
};

notificationSchema.statics.getUserSettings = async function(userId) {
  const User = mongoose.model('User');
  const user = await User.findById(userId).select('notificationSettings');
  return user ? user.notificationSettings : null;
};

// Clean up expired notifications
notificationSchema.statics.cleanupExpired = function() {
  return this.deleteMany({
    expiresAt: { $lt: new Date() }
  });
};

module.exports = mongoose.model('Notification', notificationSchema);
