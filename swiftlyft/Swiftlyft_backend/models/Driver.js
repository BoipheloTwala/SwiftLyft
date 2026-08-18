const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const driverSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'User ID is required']
  },
  driverId: {
    type: String,
    unique: true,
    required: true
  },
  licenseNumber: {
    type: String,
    required: [true, 'License number is required'],
    unique: true
  },
  licenseExpiry: {
    type: Date,
    required: [true, 'License expiry date is required']
  },
  vehicleInfo: {
    make: { type: String, required: true },
    model: { type: String, required: true },
    year: { type: Number, required: true },
    color: { type: String, required: true },
    licensePlate: { type: String, required: true, unique: true },
    vehicleType: {
      type: String,
      required: true,
      enum: ['sedan', 'suv', 'luxury', 'van', 'truck', 'motorcycle']
    },
    passengerCapacity: { type: Number, required: true, min: 1, max: 20 },
    hasAC: { type: Boolean, default: true },
    features: [String] // e.g., ['wifi', 'leather_seats', 'tinted_windows']
  },
  documents: {
    licensePhoto: { type: String, required: true },
    vehicleRegistration: { type: String, required: true },
    vehicleInsurance: { type: String, required: true },
    profilePhoto: String
  },
  bankDetails: {
    accountHolder: { type: String, required: true },
    accountNumber: { type: String, required: true },
    bankName: { type: String, required: true },
    branchCode: { type: String, required: true }
  },
  currentLocation: {
    coordinates: {
      latitude: { type: Number, required: true },
      longitude: { type: Number, required: true }
    },
    address: String,
    lastUpdated: { type: Date, default: Date.now }
  },
  availability: {
    status: {
      type: String,
      enum: ['online', 'offline', 'busy', 'maintenance'],
      default: 'offline'
    },
    availableUntil: Date,
    workingHours: {
      start: String, // HH:MM format
      end: String    // HH:MM format
    }
  },
  performance: {
    rating: { type: Number, default: 5.0, min: 0, max: 5 },
    totalRides: { type: Number, default: 0 },
    completedRides: { type: Number, default: 0 },
    cancelledRides: { type: Number, default: 0 },
    totalEarnings: { type: Number, default: 0 },
    averageResponseTime: { type: Number, default: 0 }, // in minutes
    onTimePickup: { type: Number, default: 100 }, // percentage
    customerSatisfaction: { type: Number, default: 100 } // percentage
  },
  currentBookingId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Booking'
  },
  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected', 'suspended', 'active'],
    default: 'pending'
  },
  verificationStatus: {
    backgroundCheck: { type: Boolean, default: false },
    documentsVerified: { type: Boolean, default: false },
    vehicleInspected: { type: Boolean, default: false }
  },
  emergencyContact: {
    name: { type: String, required: true },
    phone: { type: String, required: true },
    relationship: String
  }
}, {
  timestamps: true,
  toJSON: {
    transform: function(doc, ret) {
      ret.id = ret._id;
      delete ret._id;
      delete ret.__v;
      // Don't include sensitive banking info
      delete ret.bankDetails;
      return ret;
    }
  }
});

// Indexes for performance
driverSchema.index({ driverId: 1 });
driverSchema.index({ 'currentLocation.coordinates': '2dsphere' });
driverSchema.index({ 'availability.status': 1 });
driverSchema.index({ status: 1 });
driverSchema.index({ userId: 1 });

// Virtual for driver's full name (from associated User)
driverSchema.virtual('fullName').get(async function() {
  const User = mongoose.model('User');
  const user = await User.findById(this.userId).select('name');
  return user ? user.name : 'Unknown Driver';
});

// Virtual for driver availability check
driverSchema.virtual('isAvailable').get(function() {
  return this.availability.status === 'online' &&
         this.status === 'active' &&
         !this.currentBookingId;
});

// Instance methods
driverSchema.methods.updateLocation = function(latitude, longitude, address = null) {
  this.currentLocation.coordinates = { latitude, longitude };
  if (address) this.currentLocation.address = address;
  this.currentLocation.lastUpdated = new Date();
  return this.save();
};

driverSchema.methods.updateAvailability = function(status, availableUntil = null) {
  this.availability.status = status;
  if (availableUntil) this.availability.availableUntil = availableUntil;
  return this.save();
};

driverSchema.methods.updatePerformance = function(rideData) {
  const { rating, earnings, completed, cancelled } = rideData;

  if (rating) {
    // Calculate new average rating
    const totalRating = this.performance.rating * this.performance.totalRides;
    this.performance.totalRides += 1;
    this.performance.rating = (totalRating + rating) / this.performance.totalRides;
  }

  if (completed) this.performance.completedRides += 1;
  if (cancelled) this.performance.cancelledRides += 1;
  if (earnings) this.performance.totalEarnings += earnings;

  return this.save();
};

// Static methods
driverSchema.statics.findAvailableDrivers = function(latitude, longitude, maxDistance = 5000) {
  return this.find({
    'currentLocation.coordinates': {
      $near: {
        $geometry: {
          type: 'Point',
          coordinates: [longitude, latitude]
        },
        $maxDistance: maxDistance // meters
      }
    },
    'availability.status': 'online',
    status: 'active',
    currentBookingId: { $exists: false }
  }).populate('userId', 'name phoneNumber');
};

driverSchema.statics.findByDriverId = function(driverId) {
  return this.findOne({ driverId });
};

module.exports = mongoose.model('Driver', driverSchema);
