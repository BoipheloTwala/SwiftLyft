const mongoose = require('mongoose');

// Trip-specific subdocument schemas

// Real-time location tracking
const locationTrackingSchema = new mongoose.Schema({
  latitude: { type: Number, required: true },
  longitude: { type: Number, required: true },
  timestamp: { type: Date, default: Date.now },
  speed: { type: Number, default: 0 }, // km/h
  heading: { type: Number, default: 0 }, // degrees
  accuracy: { type: Number, default: 0 }, // GPS accuracy in meters
  altitude: Number, // meters above sea level
  address: String, // Reverse geocoded address
  isStopped: { type: Boolean, default: false },
  stopDuration: Number // seconds stopped at this location
}, { _id: false });

// Trip events and milestones
const tripEventSchema = new mongoose.Schema({
  eventType: {
    type: String,
    required: true,
    enum: ['pickup_started', 'pickup_completed', 'trip_started', 'waypoint_reached', 'trip_paused', 'trip_resumed', 'trip_completed', 'emergency_stop', 'route_deviation', 'speed_violation', 'harsh_braking', 'harsh_acceleration']
  },
  timestamp: { type: Date, default: Date.now },
  location: {
    latitude: Number,
    longitude: Number,
    address: String
  },
  description: String,
  metadata: {
    type: Map,
    of: mongoose.Schema.Types.Mixed
  },
  severity: {
    type: String,
    enum: ['low', 'medium', 'high', 'critical'],
    default: 'low'
  }
}, { _id: false });

// Safety metrics tracking
const safetyMetricsSchema = new mongoose.Schema({
  maxSpeed: { type: Number, default: 0 }, // km/h
  averageSpeed: { type: Number, default: 0 }, // km/h
  harshBrakingCount: { type: Number, default: 0 },
  harshAccelerationCount: { type: Number, default: 0 },
  suddenLaneChangeCount: { type: Number, default: 0 },
  phoneUsageCount: { type: Number, default: 0 },
  seatbeltViolations: { type: Number, default: 0 },
  speedViolations: [{
    speed: Number,
    limit: Number,
    location: {
      latitude: Number,
      longitude: Number
    },
    timestamp: Date
  }],
  safetyScore: { type: Number, min: 0, max: 100, default: 100 }
}, { _id: false });

// Environmental impact tracking
const environmentalMetricsSchema = new mongoose.Schema({
  fuelConsumed: { type: Number, default: 0 }, // liters
  carbonFootprint: { type: Number, default: 0 }, // kg CO2
  efficiency: { type: Number, default: 0 }, // km per liter
  emissionsByPhase: {
    pickup: Number,
    trip: Number,
    dropoff: Number
  },
  ecoFriendlyScore: { type: Number, min: 0, max: 100, default: 100 }
}, { _id: false });

// Trip performance metrics
const performanceMetricsSchema = new mongoose.Schema({
  onTimePickup: { type: Boolean, default: false },
  pickupDelay: Number, // minutes late
  tripDuration: Number, // minutes
  estimatedDuration: Number, // minutes
  durationAccuracy: Number, // percentage accuracy
  routeEfficiency: Number, // percentage of optimal route
  customerSatisfaction: Number, // 1-5 rating
  driverPerformance: Number, // 1-5 rating
  overallScore: { type: Number, min: 0, max: 100, default: 100 }
}, { _id: false });

// Communication log
const communicationLogSchema = new mongoose.Schema({
  timestamp: { type: Date, default: Date.now },
  type: {
    type: String,
    enum: ['call', 'sms', 'push_notification', 'in_app_message', 'email'],
    required: true
  },
  direction: {
    type: String,
    enum: ['driver_to_customer', 'customer_to_driver', 'system_to_customer', 'system_to_driver'],
    required: true
  },
  content: String,
  status: {
    type: String,
    enum: ['sent', 'delivered', 'read', 'failed'],
    default: 'sent'
  },
  metadata: {
    type: Map,
    of: mongoose.Schema.Types.Mixed
  }
}, { _id: false });

// Main Trip schema
const tripSchema = new mongoose.Schema({
  // Core identifiers
  tripId: {
    type: String,
    unique: true,
    required: true
  },
  bookingId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Booking',
    required: true
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  driverId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Driver',
    required: true
  },
  vehicleId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Vehicle',
    required: true
  },
  
  // Trip status
  status: {
    type: String,
    enum: ['active', 'completed', 'cancelled', 'disputed'],
    default: 'active'
  },
  
  // Trip timing
  startTime: {
    type: Date,
    required: true
  },
  endTime: Date,
  duration: Number, // total duration in minutes
  
  // Location tracking
  currentLocation: {
    latitude: Number,
    longitude: Number,
    address: String,
    lastUpdated: Date
  },
  locationHistory: [locationTrackingSchema],
  
  // Trip events
  events: [tripEventSchema],
  
  // Route information
  route: {
    polyline: String, // Encoded polyline for the route
    waypoints: [{
      latitude: Number,
      longitude: Number,
      address: String,
      reachedAt: Date,
      order: Number
    }],
    totalDistance: Number, // kilometers
    totalDuration: Number, // minutes
    trafficConditions: {
      type: String,
      enum: ['light', 'moderate', 'heavy', 'severe'],
      default: 'moderate'
    },
    weatherConditions: {
      type: String,
      enum: ['clear', 'rainy', 'stormy', 'foggy', 'snowy'],
      default: 'clear'
    }
  },
  
  // Metrics and analytics
  safetyMetrics: {
    type: safetyMetricsSchema,
    default: {}
  },
  environmentalMetrics: {
    type: environmentalMetricsSchema,
    default: {}
  },
  performanceMetrics: {
    type: performanceMetricsSchema,
    default: {}
  },
  
  // Communication
  communicationLog: [communicationLogSchema],
  
  // Trip-specific data
  passengerCount: {
    type: Number,
    required: true,
    min: 1,
    max: 20
  },
  luggageCount: {
    type: Number,
    default: 0,
    min: 0
  },
  
  // Special requirements
  specialRequirements: {
    wheelchairAccess: { type: Boolean, default: false },
    childSeat: { type: Boolean, default: false },
    petTransport: { type: Boolean, default: false },
    closeProtection: { type: Boolean, default: false },
    medicalTransport: { type: Boolean, default: false }
  },
  
  // Trip notes and feedback
  driverNotes: String,
  customerNotes: String,
  internalNotes: String,
  
  // Quality assurance
  qualityCheck: {
    completed: { type: Boolean, default: false },
    checkedAt: Date,
    checkedBy: String,
    score: Number,
    issues: [String],
    recommendations: [String]
  },
  
  // Dispute and resolution
  dispute: {
    hasDispute: { type: Boolean, default: false },
    disputeType: String,
    description: String,
    reportedAt: Date,
    reportedBy: String,
    resolvedAt: Date,
    resolvedBy: String,
    resolution: String,
    status: {
      type: String,
      enum: ['open', 'investigating', 'resolved', 'closed'],
      default: 'open'
    }
  },
  
  // Metadata
  deviceInfo: {
    driverDevice: {
      platform: String,
      version: String,
      model: String
    },
    customerDevice: {
      platform: String,
      version: String,
      model: String
    }
  },
  
  // Analytics
  analytics: {
    tripSource: String,
    referralCode: String,
    campaignId: String,
    utmData: {
      source: String,
      medium: String,
      campaign: String
    }
  }
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
tripSchema.index({ tripId: 1 });
tripSchema.index({ bookingId: 1 });
tripSchema.index({ userId: 1, createdAt: -1 });
tripSchema.index({ driverId: 1, createdAt: -1 });
tripSchema.index({ vehicleId: 1 });
tripSchema.index({ status: 1 });
tripSchema.index({ startTime: -1 });
tripSchema.index({ 'currentLocation': '2dsphere' });
tripSchema.index({ 'locationHistory.coordinates': '2dsphere' });

// Virtual fields
tripSchema.virtual('isActive').get(function() {
  return this.status === 'active';
});

tripSchema.virtual('isCompleted').get(function() {
  return this.status === 'completed';
});

tripSchema.virtual('tripDuration').get(function() {
  if (this.startTime && this.endTime) {
    return Math.round((this.endTime - this.startTime) / 1000 / 60); // minutes
  }
  return null;
});

tripSchema.virtual('averageSpeed').get(function() {
  if (this.route.totalDistance && this.tripDuration) {
    return (this.route.totalDistance / (this.tripDuration / 60)).toFixed(2); // km/h
  }
  return 0;
});

// Pre-save middleware
tripSchema.pre('save', function(next) {
  if (this.isNew && !this.tripId) {
    const timestamp = Date.now().toString(36).slice(-4);
    const random = Math.random().toString(36).substring(2, 6);
    this.tripId = `TR${timestamp}${random}`.toUpperCase();
  }
  
  // Calculate duration if trip is completed
  if (this.isModified('status') && this.status === 'completed' && this.startTime && !this.endTime) {
    this.endTime = new Date();
    this.duration = Math.round((this.endTime - this.startTime) / 1000 / 60);
  }
  
  next();
});

// Instance methods
tripSchema.methods.updateLocation = function(latitude, longitude, speed = 0, heading = 0, accuracy = 0) {
  this.currentLocation = {
    latitude,
    longitude,
    lastUpdated: new Date()
  };
  
  this.locationHistory.push({
    latitude,
    longitude,
    timestamp: new Date(),
    speed,
    heading,
    accuracy
  });
  
  return this.save();
};

tripSchema.methods.addEvent = function(eventType, description = '', location = null, metadata = {}) {
  this.events.push({
    eventType,
    description,
    location,
    metadata,
    timestamp: new Date()
  });
  
  return this.save();
};

tripSchema.methods.updateSafetyMetrics = function(metrics) {
  if (!this.safetyMetrics) {
    this.safetyMetrics = {};
  }
  
  Object.assign(this.safetyMetrics, metrics);
  
  // Calculate safety score
  let score = 100;
  if (this.safetyMetrics.harshBrakingCount > 0) score -= this.safetyMetrics.harshBrakingCount * 5;
  if (this.safetyMetrics.harshAccelerationCount > 0) score -= this.safetyMetrics.harshAccelerationCount * 5;
  if (this.safetyMetrics.speedViolations.length > 0) score -= this.safetyMetrics.speedViolations.length * 10;
  
  this.safetyMetrics.safetyScore = Math.max(0, score);
  
  return this.save();
};

tripSchema.methods.updateEnvironmentalMetrics = function(metrics) {
  if (!this.environmentalMetrics) {
    this.environmentalMetrics = {};
  }
  
  Object.assign(this.environmentalMetrics, metrics);
  
  // Calculate eco-friendly score
  let score = 100;
  if (this.environmentalMetrics.fuelConsumed > 0) {
    const efficiency = this.environmentalMetrics.efficiency;
    if (efficiency < 10) score -= 20;
    else if (efficiency < 15) score -= 10;
  }
  
  this.environmentalMetrics.ecoFriendlyScore = Math.max(0, score);
  
  return this.save();
};

tripSchema.methods.addCommunication = function(type, direction, content, metadata = {}) {
  this.communicationLog.push({
    type,
    direction,
    content,
    metadata,
    timestamp: new Date()
  });
  
  return this.save();
};

tripSchema.methods.completeTrip = function() {
  this.status = 'completed';
  this.endTime = new Date();
  this.duration = Math.round((this.endTime - this.startTime) / 1000 / 60);
  
  this.addEvent('trip_completed', 'Trip completed successfully');
  
  return this.save();
};

tripSchema.methods.cancelTrip = function(reason = '') {
  this.status = 'cancelled';
  this.endTime = new Date();
  
  this.addEvent('trip_cancelled', reason);
  
  return this.save();
};

// Static methods
tripSchema.statics.findByTripId = function(tripId) {
  return this.findOne({ tripId });
};

tripSchema.statics.findByBookingId = function(bookingId) {
  return this.findOne({ bookingId });
};

tripSchema.statics.findActiveTrips = function() {
  return this.find({ status: 'active' })
    .populate('userId', 'name phoneNumber')
    .populate('driverId', 'driverId name phoneNumber')
    .populate('vehicleId', 'vehicleId make model year')
    .sort({ startTime: -1 });
};

tripSchema.statics.findDriverTrips = function(driverId, options = {}) {
  const query = { driverId };
  
  if (options.status) {
    query.status = options.status;
  }
  
  if (options.dateRange) {
    query.startTime = {
      $gte: options.dateRange.start,
      $lte: options.dateRange.end
    };
  }
  
  return this.find(query)
    .populate('userId', 'name phoneNumber')
    .populate('vehicleId', 'vehicleId make model year')
    .sort({ startTime: -1 })
    .limit(options.limit || 50);
};

tripSchema.statics.findUserTrips = function(userId, options = {}) {
  const query = { userId };
  
  if (options.status) {
    query.status = options.status;
  }
  
  if (options.dateRange) {
    query.startTime = {
      $gte: options.dateRange.start,
      $lte: options.dateRange.end
    };
  }
  
  return this.find(query)
    .populate('driverId', 'driverId name phoneNumber')
    .populate('vehicleId', 'vehicleId make model year')
    .sort({ startTime: -1 })
    .limit(options.limit || 50);
};

tripSchema.statics.getTripStats = function(driverId = null, userId = null, dateRange = null) {
  const match = {};
  if (driverId) match.driverId = driverId;
  if (userId) match.userId = userId;
  if (dateRange) {
    match.startTime = {
      $gte: dateRange.start,
      $lte: dateRange.end
    };
  }
  
  return this.aggregate([
    { $match: match },
    {
      $group: {
        _id: '$status',
        count: { $sum: 1 },
        totalDistance: { $sum: '$route.totalDistance' },
        totalDuration: { $sum: '$duration' },
        averageSafetyScore: { $avg: '$safetyMetrics.safetyScore' },
        averageEcoScore: { $avg: '$environmentalMetrics.ecoFriendlyScore' }
      }
    }
  ]);
};

tripSchema.statics.getPerformanceAnalytics = function(dateRange = null) {
  const match = { status: 'completed' };
  if (dateRange) {
    match.startTime = {
      $gte: dateRange.start,
      $lte: dateRange.end
    };
  }
  
  return this.aggregate([
    { $match: match },
    {
      $group: {
        _id: null,
        totalTrips: { $sum: 1 },
        totalDistance: { $sum: '$route.totalDistance' },
        totalDuration: { $sum: '$duration' },
        averageSafetyScore: { $avg: '$safetyMetrics.safetyScore' },
        averageEcoScore: { $avg: '$environmentalMetrics.ecoFriendlyScore' },
        averagePerformanceScore: { $avg: '$performanceMetrics.overallScore' },
        onTimePickups: {
          $sum: {
            $cond: ['$performanceMetrics.onTimePickup', 1, 0]
          }
        }
      }
    }
  ]);
};

module.exports = mongoose.model('Trip', tripSchema);
