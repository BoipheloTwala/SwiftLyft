const mongoose = require('mongoose');

// Enhanced subdocument schemas for comprehensive trip management

// Location schema with enhanced tracking
const locationSchema = new mongoose.Schema({
  address: { type: String, required: true },
  coordinates: {
    latitude: { type: Number, required: true },
    longitude: { type: Number, required: true }
  },
  city: { type: String, required: true },
  province: { type: String, required: true },
  postalCode: String,
  instructions: String,
  contactPhone: String,
  landmark: String, // Nearby landmark for easier identification
  buildingName: String, // Specific building name
  floor: String, // Floor number for pickup
  unit: String // Unit/apartment number
}, { _id: false });

// Enhanced pricing schema with dynamic calculations
const pricingSchema = new mongoose.Schema({
  baseFare: { type: Number, required: true },
  distanceFare: { type: Number, required: true },
  timeFare: { type: Number, required: true },
  serviceFee: { type: Number, default: 0 },
  taxes: { type: Number, required: true },
  discount: { type: Number, default: 0 },
  loyaltyDiscount: { type: Number, default: 0 },
  surgeMultiplier: { type: Number, default: 1.0 },
  waitingFee: { type: Number, default: 0 },
  cancellationFee: { type: Number, default: 0 },
  total: { type: Number, required: true },
  currency: { type: String, default: 'ZAR' },
  breakdown: {
    baseFare: Number,
    distanceFare: Number,
    timeFare: Number,
    serviceFee: Number,
    taxes: Number,
    discount: Number,
    loyaltyDiscount: Number,
    surgeMultiplier: Number,
    waitingFee: Number,
    cancellationFee: Number
  }
}, { _id: false });

// Enhanced trip details with real-time tracking
const tripDetailsSchema = new mongoose.Schema({
  // Estimated vs Actual
  estimatedDistance: { type: Number, required: true }, // in kilometers
  estimatedDuration: { type: Number, required: true }, // in minutes
  actualDistance: Number, // actual distance traveled
  actualDuration: Number, // actual trip duration
  
  // Route tracking
  route: [{
    latitude: Number,
    longitude: Number,
    timestamp: Date,
    speed: Number, // km/h
    heading: Number, // degrees
    accuracy: Number // GPS accuracy in meters
  }],
  
  // Timing
  startTime: Date,
  endTime: Date,
  waitingTime: Number, // minutes driver waited
  
  // Traffic and conditions
  trafficConditions: {
    type: String,
    enum: ['light', 'moderate', 'heavy', 'severe'],
    default: 'moderate'
  },
  weatherConditions: {
    type: String,
    enum: ['clear', 'rainy', 'stormy', 'foggy', 'snowy'],
    default: 'clear'
  },
  
  // Route optimization
  routeOptimized: { type: Boolean, default: false },
  alternativeRoutes: [{
    distance: Number,
    duration: Number,
    reason: String // why this route was not chosen
  }],
  
  // Safety metrics
  maxSpeed: Number, // maximum speed reached during trip
  averageSpeed: Number, // average speed during trip
  harshBraking: Number, // count of harsh braking events
  harshAcceleration: Number, // count of harsh acceleration events
  
  // Fuel and efficiency
  fuelConsumed: Number, // liters
  carbonFootprint: Number, // kg CO2
  efficiency: Number // km per liter
}, { _id: false });

// Enhanced rating schema with detailed feedback
const ratingSchema = new mongoose.Schema({
  rating: { 
    type: Number, 
    required: true, 
    min: 1, 
    max: 5 
  },
  review: { 
    type: String, 
    maxlength: [500, 'Review cannot exceed 500 characters'] 
  },
  categories: {
    cleanliness: { type: Number, min: 1, max: 5 },
    punctuality: { type: Number, min: 1, max: 5 },
    friendliness: { type: Number, min: 1, max: 5 },
    driving: { type: Number, min: 1, max: 5 },
    vehicleCondition: { type: Number, min: 1, max: 5 },
    communication: { type: Number, min: 1, max: 5 }
  },
  tags: [String], // e.g., ['excellent', 'professional', 'safe', 'clean']
  submittedAt: { type: Date, default: Date.now },
  isAnonymous: { type: Boolean, default: false }
}, { _id: false });

// Enhanced status history with detailed tracking
const statusHistorySchema = new mongoose.Schema({
  status: { 
    type: String, 
    required: true,
    enum: ['pending', 'confirmed', 'driverAssigned', 'driverEnRoute', 'driverArrived', 'inProgress', 'completed', 'cancelled', 'expired', 'disputed']
  },
  timestamp: { type: Date, default: Date.now },
  notes: String,
  updatedBy: { 
    type: String,
    enum: ['user', 'driver', 'system', 'admin', 'support']
  },
  location: {
    latitude: Number,
    longitude: Number,
    address: String
  },
  estimatedTimeToNext: Number, // minutes to next status
  reason: String, // reason for status change
  metadata: {
    type: Map,
    of: mongoose.Schema.Types.Mixed
  }
}, { _id: false });

// Emergency and safety schema
const emergencySchema = new mongoose.Schema({
  emergencyContact: {
    name: String,
    phone: String,
    relationship: String
  },
  safetyCheckCompleted: { type: Boolean, default: false },
  safetyCheckTimestamp: Date,
  safetyNotes: String,
  incidentReport: {
    hasIncident: { type: Boolean, default: false },
    incidentType: String,
    description: String,
    reportedAt: Date,
    reportedBy: String,
    severity: {
      type: String,
      enum: ['low', 'medium', 'high', 'critical'],
      default: 'low'
    }
  }
}, { _id: false });

// Notification tracking schema
const notificationSchema = new mongoose.Schema({
  type: { 
    type: String, 
    required: true,
    enum: ['booking_confirmed', 'driver_assigned', 'driver_en_route', 'driver_arrived', 'trip_started', 'trip_completed', 'payment_confirmed', 'booking_cancelled', 'delay_notification', 'route_update']
  },
  sentAt: { type: Date, default: Date.now },
  status: { type: String, enum: ['sent', 'failed', 'delivered', 'read'], default: 'sent' },
  recipient: {
    type: String,
    enum: ['user', 'driver', 'admin'],
    required: true
  },
  method: {
    type: String,
    enum: ['push', 'sms', 'email', 'in_app'],
    required: true
  },
  content: String,
  metadata: {
    type: Map,
    of: mongoose.Schema.Types.Mixed
  }
}, { _id: false });

// Main enhanced Booking schema
const bookingSchema = new mongoose.Schema({
  // Core identifiers
  bookingId: {
    type: String,
    unique: true,
    required: true
  },
  tripId: {
    type: String,
    unique: true,
    sparse: true // Allow null for pending bookings
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'User ID is required']
  },
  driverId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Driver',
    default: null
  },
  vehicleId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Vehicle',
    default: null
  },
  quoteId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Quote',
    default: null
  },
  
  // Frontend-compatible fields
  vehicleName: {
    type: String,
    required: true
  },
  driverName: {
    type: String,
    default: ''
  },
  driverPhone: {
    type: String,
    default: ''
  },
  driverPhotoUrl: {
    type: String,
    default: ''
  },
  
  // Enhanced location details
  pickupAddress: {
    type: String,
    required: true
  },
  dropoffAddress: {
    type: String,
    required: true
  },
  pickupLocation: {
    type: locationSchema,
    required: true
  },
  dropoffLocation: {
    type: locationSchema,
    required: true
  },
  waypoints: [locationSchema], // Optional intermediate stops
  
  // Vehicle and service details
  vehicleType: {
    type: String,
    required: true,
    enum: ['sedan', 'suv', 'luxury', 'van', 'truck', 'motorcycle', 'electric', 'hybrid']
  },
  serviceType: {
    type: String,
    required: true,
    enum: ['standard', 'premium', 'corporate', 'airport', 'security', 'medical', 'event']
  },
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
  
  // Enhanced scheduling
  pickupTime: {
    type: Date,
    required: true
  },
  actualPickupTime: {
    type: Date,
    default: null
  },
  actualDropoffTime: {
    type: Date,
    default: null
  },
  scheduledDate: {
    type: Date,
    required: true
  },
  isFlexibleTime: {
    type: Boolean,
    default: false
  },
  flexibleWindow: {
    type: Number,
    default: 15 // minutes
  },
  
  // Enhanced pricing
  pricing: {
    type: pricingSchema,
    required: true
  },
  
  // Trip execution details
  tripDetails: {
    type: tripDetailsSchema,
    default: null
  },
  
  // Status and tracking
  status: {
    type: String,
    enum: ['pending', 'confirmed', 'driverAssigned', 'driverEnRoute', 'driverArrived', 'inProgress', 'completed', 'cancelled', 'expired', 'disputed'],
    default: 'pending'
  },
  statusHistory: [statusHistorySchema],
  
  // Enhanced driver assignment tracking
  assignedAt: Date,
  driverAcceptedAt: Date,
  driverArrivedAt: Date,
  tripStartedAt: Date,
  tripCompletedAt: Date,
  
  // Special requirements and notes
  specialNotes: {
    type: String,
    maxlength: [500, 'Special notes cannot exceed 500 characters']
  },
  closeProtectionOfficer: {
    type: Boolean,
    default: false
  },
  internalNotes: String, // For driver/admin notes
  customerNotes: String, // Customer notes visible to driver
  
  // Enhanced payment tracking
  paymentMethod: {
    type: String,
    enum: ['cash', 'card', 'wallet', 'corporate', 'crypto'],
    default: 'card'
  },
  paymentStatus: {
    type: String,
    enum: ['pending', 'paid', 'failed', 'refunded', 'partially_refunded', 'disputed'],
    default: 'pending'
  },
  paymentMethodId: String,
  paymentId: String, // External payment system ID
  paidAt: Date,
  refundedAt: Date,
  refundAmount: Number,
  refundReason: String,
  
  // Enhanced rating and feedback
  rating: {
    type: Number,
    min: 1,
    max: 5,
    default: null
  },
  review: {
    type: String,
    maxlength: [500, 'Review cannot exceed 500 characters'],
    default: null
  },
  driverRating: {
    type: ratingSchema,
    default: null
  },
  userRating: {
    type: ratingSchema,
    default: null
  },
  
  // Enhanced cancellation tracking
  cancelledAt: Date,
  cancelledBy: {
    type: String,
    enum: ['user', 'driver', 'system', 'admin', 'support']
  },
  cancellationReason: String,
  cancellationFee: { type: Number, default: 0 },
  cancellationPolicy: String, // Which policy was applied
  
  // Corporate booking details
  isCorporateBooking: { type: Boolean, default: false },
  corporateAccountId: String,
  corporateApprovalRequired: { type: Boolean, default: false },
  corporateApprovedAt: Date,
  corporateApprovedBy: String,
  
  // Emergency and safety
  emergency: {
    type: emergencySchema,
    default: {}
  },
  
  // Enhanced notifications
  notificationsSent: [notificationSchema],
  
  // Additional tracking fields
  routeInfo: {
    type: Map,
    of: mongoose.Schema.Types.Mixed,
    default: null
  },
  
  // Metadata
  source: {
    type: String,
    enum: ['app', 'web', 'api', 'admin', 'phone'],
    default: 'app'
  },
  deviceInfo: {
    platform: String,
    version: String,
    userAgent: String,
    ipAddress: String
  },
  
  // Analytics and reporting
  analytics: {
    bookingSource: String, // How user found the service
    referralCode: String,
    campaignId: String,
    utmSource: String,
    utmMedium: String,
    utmCampaign: String
  },
  
  // Compliance and legal
  termsAccepted: { type: Boolean, default: false },
  termsAcceptedAt: Date,
  privacyPolicyAccepted: { type: Boolean, default: false },
  privacyPolicyAcceptedAt: Date,
  
  // Quality assurance
  qualityCheck: {
    completed: { type: Boolean, default: false },
    checkedAt: Date,
    checkedBy: String,
    score: Number,
    notes: String
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

// Indexes for performance and queries
bookingSchema.index({ bookingId: 1 });
bookingSchema.index({ tripId: 1 });
bookingSchema.index({ userId: 1, createdAt: -1 });
bookingSchema.index({ driverId: 1, createdAt: -1 });
bookingSchema.index({ vehicleId: 1 });
bookingSchema.index({ status: 1, scheduledDate: 1 });
bookingSchema.index({ 'pickupLocation.coordinates': '2dsphere' });
bookingSchema.index({ 'dropoffLocation.coordinates': '2dsphere' });
bookingSchema.index({ scheduledDate: 1 });
bookingSchema.index({ paymentStatus: 1 });
bookingSchema.index({ isCorporateBooking: 1 });
bookingSchema.index({ createdAt: -1 });
bookingSchema.index({ updatedAt: -1 });

// Virtual fields
bookingSchema.virtual('basePrice').get(function() {
  return this.pricing?.baseFare || 0;
});

bookingSchema.virtual('finalPrice').get(function() {
  return this.pricing?.total || 0;
});

bookingSchema.virtual('bookingDuration').get(function() {
  if (this.tripDetails && this.tripDetails.startTime && this.tripDetails.endTime) {
    return Math.round((this.tripDetails.endTime - this.tripDetails.startTime) / 1000 / 60); // minutes
  }
  return null;
});

bookingSchema.virtual('isActive').get(function() {
  const activeStatuses = ['confirmed', 'driverAssigned', 'driverEnRoute', 'driverArrived', 'inProgress'];
  return activeStatuses.includes(this.status);
});

bookingSchema.virtual('isCompleted').get(function() {
  return this.status === 'completed';
});

bookingSchema.virtual('isCancelled').get(function() {
  return this.status === 'cancelled';
});

bookingSchema.virtual('isDisputed').get(function() {
  return this.status === 'disputed';
});

// Pre-save middleware
bookingSchema.pre('save', function(next) {
  if (this.isNew && !this.bookingId) {
    const timestamp = Date.now().toString(36).slice(-4);
    const random = Math.random().toString(36).substring(2, 6);
    this.bookingId = `BK${timestamp}${random}`.toUpperCase();
  }
  
  // Generate trip ID when trip starts
  if (this.isModified('status') && this.status === 'inProgress' && !this.tripId) {
    const timestamp = Date.now().toString(36).slice(-4);
    const random = Math.random().toString(36).substring(2, 6);
    this.tripId = `TR${timestamp}${random}`.toUpperCase();
  }
  
  next();
});

// Pre-save middleware to track status changes
bookingSchema.pre('save', function(next) {
  if (this.isModified('status') && !this.isNew) {
    this.statusHistory.push({
      status: this.status,
      timestamp: new Date(),
      updatedBy: 'system'
    });
  }
  next();
});

// Status transition validation
const validTransitions = {
  'pending': ['confirmed', 'cancelled', 'expired'],
  'confirmed': ['driverAssigned', 'cancelled', 'expired'],
  'driverAssigned': ['driverEnRoute', 'cancelled', 'expired'],
  'driverEnRoute': ['driverArrived', 'cancelled', 'expired'],
  'driverArrived': ['inProgress', 'cancelled', 'expired'],
  'inProgress': ['completed', 'cancelled', 'disputed'],
  'completed': ['disputed'],
  'cancelled': [],
  'expired': [],
  'disputed': ['completed', 'cancelled']
};

// Instance methods
bookingSchema.methods.updateStatus = function(newStatus, updatedBy = 'system', notes = '', location = null) {
  const oldStatus = this.status;
  
  // Validate status transition
  if (!validTransitions[oldStatus] || !validTransitions[oldStatus].includes(newStatus)) {
    throw new Error(`Invalid status transition from ${oldStatus} to ${newStatus}`);
  }
  
  this.status = newStatus;
  
  this.statusHistory.push({
    status: newStatus,
    timestamp: new Date(),
    updatedBy,
    notes,
    location
  });
  
  // Set specific timestamps based on status
  switch (newStatus) {
    case 'driverAssigned':
      this.assignedAt = new Date();
      break;
    case 'driverEnRoute':
      this.driverAcceptedAt = new Date();
      break;
    case 'driverArrived':
      this.driverArrivedAt = new Date();
      break;
    case 'inProgress':
      this.tripStartedAt = new Date();
      if (this.tripDetails) {
        this.tripDetails.startTime = new Date();
      }
      break;
    case 'completed':
      this.tripCompletedAt = new Date();
      if (this.tripDetails) {
        this.tripDetails.endTime = new Date();
      }
      break;
    case 'cancelled':
      this.cancelledAt = new Date();
      this.cancelledBy = updatedBy;
      break;
  }
  
  return this.save();
};

bookingSchema.methods.assignDriver = function(driverId) {
  this.driverId = driverId;
  return this.updateStatus('driverAssigned', 'system', 'Driver assigned to booking');
};

bookingSchema.methods.cancelBooking = function(cancelledBy, reason = '', fee = 0) {
  this.cancelledBy = cancelledBy;
  this.cancellationReason = reason;
  this.cancellationFee = fee;
  return this.updateStatus('cancelled', cancelledBy, reason);
};

bookingSchema.methods.addRating = function(rating, review = '', categories = {}) {
  this.rating = rating;
  this.review = review;
  this.driverRating = {
    rating,
    review,
    categories,
    submittedAt: new Date()
  };
  return this.save();
};

bookingSchema.methods.updateTripDetails = function(distance, duration, route = [], trafficConditions = 'moderate') {
  if (!this.tripDetails) {
    this.tripDetails = {};
  }
  
  this.tripDetails.actualDistance = distance;
  this.tripDetails.actualDuration = duration;
  this.tripDetails.route = route;
  this.tripDetails.trafficConditions = trafficConditions;
  
  return this.save();
};

bookingSchema.methods.addNotification = function(type, recipient, method, content = '') {
  this.notificationsSent.push({
    type,
    recipient,
    method,
    content,
    sentAt: new Date()
  });
  return this.save();
};

// Static methods
bookingSchema.statics.findByBookingId = function(bookingId) {
  return this.findOne({ bookingId });
};

bookingSchema.statics.findByTripId = function(tripId) {
  return this.findOne({ tripId });
};

bookingSchema.statics.findUserBookings = function(userId, options = {}) {
  const query = { userId };
  
  if (options.status) {
    query.status = options.status;
  }
  
  if (options.active) {
    query.status = { $in: ['confirmed', 'driverAssigned', 'driverEnRoute', 'driverArrived', 'inProgress'] };
  }
  
  if (options.completed) {
    query.status = 'completed';
  }
  
  return this.find(query)
    .populate('driverId', 'driverId vehicleInfo performance')
    .populate('vehicleId', 'vehicleId make model year')
    .populate('userId', 'name email phoneNumber')
    .sort({ createdAt: -1 })
    .limit(options.limit || 50);
};

bookingSchema.statics.findDriverBookings = function(driverId, options = {}) {
  const query = { driverId };
  
  if (options.status) {
    query.status = options.status;
  }
  
  return this.find(query)
    .populate('userId', 'name email phoneNumber')
    .populate('vehicleId', 'vehicleId make model year')
    .sort({ createdAt: -1 })
    .limit(options.limit || 50);
};

bookingSchema.statics.findActiveBookings = function() {
  return this.find({
    status: { $in: ['confirmed', 'driverAssigned', 'driverEnRoute', 'driverArrived', 'inProgress'] }
  })
  .populate('userId', 'name email phoneNumber')
  .populate('driverId', 'driverId vehicleInfo')
  .populate('vehicleId', 'vehicleId make model year')
  .sort({ scheduledDate: 1 });
};

bookingSchema.statics.findNearbyBookings = function(latitude, longitude, maxDistance = 5000) {
  return this.find({
    'pickupLocation.coordinates': {
      $near: {
        $geometry: {
          type: 'Point',
          coordinates: [longitude, latitude]
        },
        $maxDistance: maxDistance // meters
      }
    },
    status: { $in: ['pending', 'confirmed'] }
  })
  .populate('userId', 'name phoneNumber')
  .sort({ scheduledDate: 1 });
};

bookingSchema.statics.getBookingStats = function(userId = null, driverId = null, dateRange = null) {
  const match = {};
  if (userId) match.userId = userId;
  if (driverId) match.driverId = driverId;
  if (dateRange) {
    match.createdAt = {
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
        totalRevenue: { $sum: '$pricing.total' },
        averageRating: { $avg: '$rating' }
      }
    }
  ]);
};

bookingSchema.statics.getRevenueStats = function(dateRange = null) {
  const match = { status: 'completed' };
  if (dateRange) {
    match.createdAt = {
      $gte: dateRange.start,
      $lte: dateRange.end
    };
  }
  
  return this.aggregate([
    { $match: match },
    {
      $group: {
        _id: null,
        totalRevenue: { $sum: '$pricing.total' },
        totalBookings: { $sum: 1 },
        averageBookingValue: { $avg: '$pricing.total' },
        totalDistance: { $sum: '$tripDetails.actualDistance' },
        totalDuration: { $sum: '$tripDetails.actualDuration' }
      }
    }
  ]);
};

module.exports = mongoose.model('Booking', bookingSchema);