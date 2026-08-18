const mongoose = require('mongoose');

// User Analytics Event schema
const userAnalyticsSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: false
  },
  eventType: {
    type: String,
    required: true,
    enum: [
      'app_open',
      'app_close',
      'booking_started',
      'booking_completed',
      'payment_attempt',
      'payment_success',
      'payment_failed',
      'quote_requested',
      'quote_accepted',
      'profile_updated',
      'location_search',
      'driver_rated',
      'support_contacted',
      'promotion_viewed',
      'loyalty_used',
      // Added for mobile client analytics
      'user_sign_in',
      'user_sign_in_failed',
      'user_sign_out',
      'password_reset_requested'
    ]
  },
  eventData: {
    type: mongoose.Schema.Types.Mixed
  },
  sessionId: String,
  deviceInfo: {
    platform: String, // 'ios', 'android', 'web'
    version: String,
    deviceId: String
  },
  location: {
    latitude: Number,
    longitude: Number,
    address: String
  },
  timestamp: {
    type: Date,
    default: Date.now
  }
});

// Booking Analytics schema
const bookingAnalyticsSchema = new mongoose.Schema({
  date: {
    type: Date,
    required: true
  },
  totalBookings: {
    type: Number,
    default: 0
  },
  completedBookings: {
    type: Number,
    default: 0
  },
  cancelledBookings: {
    type: Number,
    default: 0
  },
  averageBookingValue: {
    type: Number,
    default: 0
  },
  totalRevenue: {
    type: Number,
    default: 0
  },
  bookingsByVehicleType: {
    sedan: { type: Number, default: 0 },
    suv: { type: Number, default: 0 },
    luxury: { type: Number, default: 0 },
    van: { type: Number, default: 0 },
    truck: { type: Number, default: 0 },
    motorcycle: { type: Number, default: 0 }
  },
  bookingsByServiceType: {
    standard: { type: Number, default: 0 },
    premium: { type: Number, default: 0 },
    corporate: { type: Number, default: 0 },
    airport: { type: Number, default: 0 },
    security: { type: Number, default: 0 }
  },
  peakHours: [{
    hour: Number,
    bookingCount: Number
  }],
  popularRoutes: [{
    pickup: String,
    dropoff: String,
    bookingCount: Number
  }]
});

// Revenue Analytics schema
const revenueAnalyticsSchema = new mongoose.Schema({
  date: {
    type: Date,
    required: true
  },
  totalRevenue: {
    type: Number,
    default: 0
  },
  bookingRevenue: {
    type: Number,
    default: 0
  },
  corporateRevenue: {
    type: Number,
    default: 0
  },
  otherRevenue: {
    type: Number,
    default: 0
  },
  refunds: {
    type: Number,
    default: 0
  },
  commissions: {
    type: Number,
    default: 0
  },
  driverPayouts: {
    type: Number,
    default: 0
  },
  platformFees: {
    type: Number,
    default: 0
  },
  paymentMethods: {
    card: { type: Number, default: 0 },
    cash: { type: Number, default: 0 },
    wallet: { type: Number, default: 0 },
    corporate: { type: Number, default: 0 }
  },
  revenueByRegion: [{
    region: String,
    amount: Number
  }]
});

// Driver Analytics schema
const driverAnalyticsSchema = new mongoose.Schema({
  driverId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Driver',
    required: true
  },
  date: {
    type: Date,
    required: true,
    default: Date.now
  },
  totalRides: {
    type: Number,
    default: 0
  },
  completedRides: {
    type: Number,
    default: 0
  },
  cancelledRides: {
    type: Number,
    default: 0
  },
  totalEarnings: {
    type: Number,
    default: 0
  },
  averageRating: {
    type: Number,
    default: 0
  },
  onlineHours: {
    type: Number,
    default: 0
  },
  acceptanceRate: {
    type: Number,
    default: 0
  },
  averageResponseTime: {
    type: Number,
    default: 0
  },
  customerComplaints: {
    type: Number,
    default: 0
  },
  performance: {
    onTimePickup: { type: Number, default: 0 }, // percentage
    customerSatisfaction: { type: Number, default: 0 }, // percentage
    completionRate: { type: Number, default: 0 } // percentage
  }
});

// Indexes
userAnalyticsSchema.index({ userId: 1, timestamp: -1 });
userAnalyticsSchema.index({ eventType: 1, timestamp: -1 });
userAnalyticsSchema.index({ sessionId: 1 });

bookingAnalyticsSchema.index({ date: 1 }, { unique: true });
revenueAnalyticsSchema.index({ date: 1 }, { unique: true });
driverAnalyticsSchema.index({ driverId: 1, date: 1 });

// Static methods for aggregations
bookingAnalyticsSchema.statics.getBookingsSummary = function(startDate, endDate) {
  return this.aggregate([
    {
      $match: {
        date: { $gte: startDate, $lte: endDate }
      }
    },
    {
      $group: {
        _id: null,
        totalBookings: { $sum: '$totalBookings' },
        completedBookings: { $sum: '$completedBookings' },
        cancelledBookings: { $sum: '$cancelledBookings' },
        totalRevenue: { $sum: '$totalRevenue' },
        averageBookingValue: { $avg: '$averageBookingValue' }
      }
    }
  ]);
};

revenueAnalyticsSchema.statics.getRevenueSummary = function(startDate, endDate) {
  return this.aggregate([
    {
      $match: {
        date: { $gte: startDate, $lte: endDate }
      }
    },
    {
      $group: {
        _id: null,
        totalRevenue: { $sum: '$totalRevenue' },
        totalRefunds: { $sum: '$refunds' },
        totalCommissions: { $sum: '$commissions' },
        totalDriverPayouts: { $sum: '$driverPayouts' },
        totalPlatformFees: { $sum: '$platformFees' }
      }
    },
    {
      $project: {
        _id: 0,
        totalRevenue: 1,
        refunds: '$totalRefunds',
        commissions: '$totalCommissions',
        netRevenue: {
          $subtract: [
            '$totalRevenue',
            { $add: ['$totalRefunds', '$totalCommissions', '$totalDriverPayouts', '$totalPlatformFees'] }
          ]
        }
      }
    }
  ]);
};

driverAnalyticsSchema.statics.getTopPerformers = function(limit = 10) {
  return this.aggregate([
    {
      $group: {
        _id: '$driverId',
        totalRides: { $sum: '$totalRides' },
        averageRating: { $avg: '$averageRating' },
        totalEarnings: { $sum: '$totalEarnings' },
        acceptanceRate: { $avg: '$acceptanceRate' }
      }
    },
    {
      $sort: { totalRides: -1, averageRating: -1 }
    },
    {
      $limit: limit
    },
    {
      $lookup: {
        from: 'drivers',
        localField: '_id',
        foreignField: '_id',
        as: 'driver'
      }
    },
    {
      $unwind: '$driver'
    }
  ]);
};

// Models
const UserAnalytics = mongoose.model('UserAnalytics', userAnalyticsSchema);
const BookingAnalytics = mongoose.model('BookingAnalytics', bookingAnalyticsSchema);
const RevenueAnalytics = mongoose.model('RevenueAnalytics', revenueAnalyticsSchema);
const DriverAnalytics = mongoose.model('DriverAnalytics', driverAnalyticsSchema);

module.exports = {
  UserAnalytics,
  BookingAnalytics,
  RevenueAnalytics,
  DriverAnalytics
};
