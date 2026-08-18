const mongoose = require('mongoose');

// Subdocument schemas
const locationSchema = new mongoose.Schema({
  address: { type: String, required: true },
  coordinates: {
    latitude: { type: Number, required: true },
    longitude: { type: Number, required: true }
  },
  city: { type: String, required: true },
  province: { type: String, required: true },
  postalCode: String
}, { _id: false });

const pricingSchema = new mongoose.Schema({
  baseFare: { type: Number, required: true },
  perKmRate: { type: Number, required: true },
  perMinuteRate: { type: Number, required: true },
  minimumFare: { type: Number, required: true },
  surgeMultiplier: { type: Number, default: 1.0 },
  currency: { type: String, default: 'ZAR' }
}, { _id: false });

const featuresSchema = new mongoose.Schema({
  airConditioning: { type: Boolean, default: true },
  wifi: { type: Boolean, default: false },
  leatherSeats: { type: Boolean, default: false },
  tintedWindows: { type: Boolean, default: false },
  usbCharging: { type: Boolean, default: true },
  bluetooth: { type: Boolean, default: true },
  gps: { type: Boolean, default: true },
  childSeat: { type: Boolean, default: false },
  wheelchairAccessible: { type: Boolean, default: false },
  petFriendly: { type: Boolean, default: false }
}, { _id: false });

const maintenanceSchema = new mongoose.Schema({
  lastServiceDate: Date,
  nextServiceDate: Date,
  mileage: { type: Number, default: 0 },
  serviceHistory: [{
    date: Date,
    type: String,
    description: String,
    cost: Number,
    mileage: Number
  }],
  insuranceExpiry: Date,
  registrationExpiry: Date
}, { _id: false });

// Main Vehicle schema
const vehicleSchema = new mongoose.Schema({
  // Frontend-compatible fields
  vehicleId: {
    type: String,
    unique: true,
    required: true
  },
  driverId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Driver',
    required: [true, 'Driver ID is required']
  },
  
  // Frontend-compatible basic information
  name: {
    type: String,
    required: [true, 'Vehicle name is required']
  },
  description: {
    type: String,
    required: [true, 'Vehicle description is required']
  },
  imageUrl: {
    type: String,
    default: ''
  },
  imageGallery: [String], // Array of image URLs
  
  // Original backend fields (kept for internal use)
  make: {
    type: String,
    required: [true, 'Vehicle make is required']
  },
  model: {
    type: String,
    required: [true, 'Vehicle model is required']
  },
  year: {
    type: Number,
    required: [true, 'Vehicle year is required'],
    min: 1990,
    max: new Date().getFullYear() + 1
  },
  color: {
    type: String,
    required: [true, 'Vehicle color is required']
  },
  licensePlate: {
    type: String,
    required: [true, 'License plate is required'],
    unique: true,
    uppercase: true
  },
  vin: {
    type: String,
    unique: true,
    sparse: true
  },
  
  // Vehicle categorization
  category: {
    type: String,
    required: [true, 'Vehicle category is required'],
    enum: ['sedan', 'suv', 'luxury', 'van', 'truck', 'motorcycle', 'electric', 'hybrid']
  },
  subcategory: {
    type: String,
    enum: ['economy', 'comfort', 'premium', 'business', 'executive', 'family', 'cargo']
  },
  
  // Capacity and specifications - Frontend compatible
  passengerCapacity: {
    type: Number,
    required: [true, 'Passenger capacity is required'],
    min: 1,
    max: 20
  },
  luggageCapacity: {
    type: Number,
    default: 0,
    min: 0
  },
  engineType: {
    type: String,
    enum: ['petrol', 'diesel', 'electric', 'hybrid', 'lpg'],
    default: 'petrol'
  },
  transmission: {
    type: String,
    enum: ['manual', 'automatic', 'cvt'],
    default: 'automatic'
  },
  fuelEfficiency: {
    type: Number, // km per liter
    min: 0
  },
  
  // Location and availability
  currentLocation: {
    type: locationSchema,
    required: true
  },
  serviceArea: [locationSchema], // Areas where vehicle operates
  
  // Availability and status - Frontend compatible
  status: {
    type: String,
    enum: ['available', 'busy', 'offline', 'maintenance', 'out_of_service'],
    default: 'offline'
  },
  availability: {
    isAvailable: { type: Boolean, default: false },
    availableFrom: Date,
    availableUntil: Date,
    workingHours: {
      start: String, // HH:MM format
      end: String    // HH:MM format
    },
    operatingDays: [{
      type: String,
      enum: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
    }]
  },
  
  // Pricing - Frontend compatible
  pricing: {
    type: pricingSchema,
    required: true
  },
  
  // Features and amenities - Frontend compatible
  features: [String], // Array of feature strings for frontend
  featuresDetails: {
    type: featuresSchema,
    default: {}
  },
  
  // Images and media - Frontend compatible
  images: {
    exterior: [String], // URLs to exterior photos
    interior: [String], // URLs to interior photos
    documents: [String] // URLs to registration, insurance docs
  },
  
  // Frontend-specific fields
  badges: [String], // Array of badge strings like ['Top Choice', 'Popular']
  specifications: {
    type: Map,
    of: String,
    default: {}
  },
  
  // Maintenance and compliance
  maintenance: {
    type: maintenanceSchema,
    default: {}
  },
  
  // Performance metrics
  performance: {
    rating: { type: Number, default: 5.0, min: 0, max: 5 },
    totalTrips: { type: Number, default: 0 },
    totalDistance: { type: Number, default: 0 }, // in km
    totalEarnings: { type: Number, default: 0 },
    averageRating: { type: Number, default: 5.0, min: 0, max: 5 },
    reliabilityScore: { type: Number, default: 100, min: 0, max: 100 }
  },
  
  // Safety and compliance
  safety: {
    hasAirbags: { type: Boolean, default: true },
    hasAbs: { type: Boolean, default: true },
    hasEbd: { type: Boolean, default: true },
    safetyRating: { type: String, enum: ['1', '2', '3', '4', '5'] },
    lastInspection: Date,
    nextInspection: Date
  },
  
  // Insurance and registration
  insurance: {
    provider: String,
    policyNumber: String,
    expiryDate: Date,
    coverageAmount: Number
  },
  registration: {
    registrationNumber: String,
    expiryDate: Date,
    province: String
  },
  
  // Special capabilities
  specialCapabilities: [{
    type: String,
    enum: ['wheelchair_access', 'child_seat', 'pet_transport', 'luggage_assistance', 'airport_pickup', 'corporate_service']
  }],
  
  // Current booking information
  currentBookingId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Booking',
    default: null
  },
  
  // Metadata
  isActive: { type: Boolean, default: true },
  isVerified: { type: Boolean, default: false },
  verificationDate: Date,
  notes: String,
  
  // Timestamps
  lastLocationUpdate: { type: Date, default: Date.now },
  lastStatusUpdate: { type: Date, default: Date.now }
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
vehicleSchema.index({ vehicleId: 1 });
vehicleSchema.index({ driverId: 1 });
vehicleSchema.index({ 'currentLocation.coordinates': '2dsphere' });
vehicleSchema.index({ status: 1 });
vehicleSchema.index({ category: 1 });
vehicleSchema.index({ 'availability.isAvailable': 1 });
vehicleSchema.index({ licensePlate: 1 });
vehicleSchema.index({ vin: 1 });

// Virtual for vehicle's full name
vehicleSchema.virtual('fullName').get(function() {
  return `${this.year} ${this.make} ${this.model}`;
});

// Virtual for frontend-compatible name (if not set, use fullName)
vehicleSchema.virtual('displayName').get(function() {
  return this.name || this.fullName;
});

// Virtual for vehicle availability check
vehicleSchema.virtual('isCurrentlyAvailable').get(function() {
  const now = new Date();
  return this.status === 'available' &&
         this.availability.isAvailable &&
         this.isActive &&
         !this.currentBookingId &&
         (!this.availability.availableFrom || now >= this.availability.availableFrom) &&
         (!this.availability.availableUntil || now <= this.availability.availableUntil);
});

// Virtual for basePrice (derived from pricing.baseFare)
vehicleSchema.virtual('basePrice').get(function() {
  return this.pricing?.baseFare || 0;
});

// Virtual for vehicle age
vehicleSchema.virtual('age').get(function() {
  return new Date().getFullYear() - this.year;
});

// Pre-save middleware to generate vehicle ID
vehicleSchema.pre('save', function(next) {
  if (this.isNew && !this.vehicleId) {
    const timestamp = Date.now().toString(36).slice(-4);
    const random = Math.random().toString(36).substring(2, 6);
    this.vehicleId = `VH${timestamp}${random}`.toUpperCase();
  }
  
  // Auto-generate name if not provided
  if (!this.name) {
    this.name = `${this.year} ${this.make} ${this.model}`;
  }
  
  next();
});

// Instance methods
vehicleSchema.methods.updateLocation = function(latitude, longitude, address = null, city = null, province = null) {
  this.currentLocation.coordinates = { latitude, longitude };
  if (address) this.currentLocation.address = address;
  if (city) this.currentLocation.city = city;
  if (province) this.currentLocation.province = province;
  this.lastLocationUpdate = new Date();
  return this.save();
};

vehicleSchema.methods.updateStatus = function(status) {
  this.status = status;
  this.availability.isAvailable = status === 'available';
  this.lastStatusUpdate = new Date();
  return this.save();
};

vehicleSchema.methods.updateAvailability = function(isAvailable, availableFrom = null, availableUntil = null) {
  this.availability.isAvailable = isAvailable;
  if (availableFrom) this.availability.availableFrom = availableFrom;
  if (availableUntil) this.availability.availableUntil = availableUntil;
  this.status = isAvailable ? 'available' : 'offline';
  this.lastStatusUpdate = new Date();
  return this.save();
};

vehicleSchema.methods.assignBooking = function(bookingId) {
  this.currentBookingId = bookingId;
  this.status = 'busy';
  this.availability.isAvailable = false;
  this.lastStatusUpdate = new Date();
  return this.save();
};

vehicleSchema.methods.completeBooking = function() {
  this.currentBookingId = null;
  this.status = 'available';
  this.availability.isAvailable = true;
  this.lastStatusUpdate = new Date();
  return this.save();
};

vehicleSchema.methods.updatePerformance = function(tripData) {
  const { rating, distance, earnings } = tripData;

  if (rating) {
    const totalRating = this.performance.averageRating * this.performance.totalTrips;
    this.performance.totalTrips += 1;
    this.performance.averageRating = (totalRating + rating) / this.performance.totalTrips;
  }

  if (distance) this.performance.totalDistance += distance;
  if (earnings) this.performance.totalEarnings += earnings;

  return this.save();
};

vehicleSchema.methods.addServiceRecord = function(serviceData) {
  if (!this.maintenance.serviceHistory) {
    this.maintenance.serviceHistory = [];
  }
  
  this.maintenance.serviceHistory.push({
    date: new Date(),
    ...serviceData
  });
  
  return this.save();
};

// Static methods
vehicleSchema.statics.findAvailableVehicles = function(latitude, longitude, options = {}) {
  const query = {
    'currentLocation.coordinates': {
      $near: {
        $geometry: {
          type: 'Point',
          coordinates: [longitude, latitude]
        },
        $maxDistance: options.maxDistance || 10000 // meters
      }
    },
    status: 'available',
    'availability.isAvailable': true,
    isActive: true,
    currentBookingId: null
  };

  if (options.category) {
    query.category = options.category;
  }

  if (options.passengerCount) {
    query.passengerCapacity = { $gte: options.passengerCount };
  }

  if (options.features) {
    // Support both array of strings and object-based features
    const featureQueries = options.features.map(feature => ({
      $or: [
        { features: feature },
        { [`featuresDetails.${feature}`]: true }
      ]
    }));
    query.$and = featureQueries;
  }

  return this.find(query)
    .populate('driverId', 'driverId performance rating')
    .sort({ 'performance.rating': -1 })
    .limit(options.limit || 50);
};

vehicleSchema.statics.findByVehicleId = function(vehicleId) {
  return this.findOne({ vehicleId });
};

vehicleSchema.statics.findByDriverId = function(driverId) {
  return this.find({ driverId });
};

vehicleSchema.statics.getVehicleCategories = function() {
  return this.distinct('category');
};

vehicleSchema.statics.searchVehicles = function(searchCriteria) {
  const query = {
    isActive: true
  };

  if (searchCriteria.location) {
    const { latitude, longitude, maxDistance = 10000 } = searchCriteria.location;
    query['currentLocation.coordinates'] = {
      $near: {
        $geometry: {
          type: 'Point',
          coordinates: [longitude, latitude]
        },
        $maxDistance: maxDistance
      }
    };
  }

  if (searchCriteria.category) {
    query.category = searchCriteria.category;
  }

  if (searchCriteria.passengerCount) {
    query.passengerCapacity = { $gte: searchCriteria.passengerCount };
  }

  if (searchCriteria.features) {
    // Support both array of strings and object-based features
    const featureQueries = searchCriteria.features.map(feature => ({
      $or: [
        { features: feature },
        { [`featuresDetails.${feature}`]: true }
      ]
    }));
    query.$and = featureQueries;
  }

  if (searchCriteria.priceRange) {
    query['pricing.baseFare'] = {
      $gte: searchCriteria.priceRange.min || 0,
      $lte: searchCriteria.priceRange.max || Infinity
    };
  }

  if (searchCriteria.make) {
    query.make = new RegExp(searchCriteria.make, 'i');
  }

  if (searchCriteria.model) {
    query.model = new RegExp(searchCriteria.model, 'i');
  }

  return this.find(query)
    .populate('driverId', 'driverId performance rating')
    .sort({ 'performance.rating': -1 })
    .limit(searchCriteria.limit || 50);
};

vehicleSchema.statics.getVehicleStats = function() {
  return this.aggregate([
    {
      $group: {
        _id: '$category',
        count: { $sum: 1 },
        available: {
          $sum: {
            $cond: [
              { $and: [
                { $eq: ['$status', 'available'] },
                { $eq: ['$availability.isAvailable', true] },
                { $eq: ['$isActive', true] }
              ]},
              1,
              0
            ]
          }
        },
        averageRating: { $avg: '$performance.averageRating' },
        totalEarnings: { $sum: '$performance.totalEarnings' }
      }
    }
  ]);
};

module.exports = mongoose.model('Vehicle', vehicleSchema);
