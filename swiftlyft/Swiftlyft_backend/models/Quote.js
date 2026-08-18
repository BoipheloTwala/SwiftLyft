const mongoose = require('mongoose');

const quoteSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'User ID is required']
  },
  pickupLocation: {
    address: { type: String, required: true },
    coordinates: {
      latitude: { type: Number, required: true },
      longitude: { type: Number, required: true }
    }
  },
  dropoffLocation: {
    address: { type: String, required: true },
    coordinates: {
      latitude: { type: Number, required: true },
      longitude: { type: Number, required: true }
    }
  },
  vehicleType: {
    type: String,
    required: true,
    enum: ['sedan', 'suv', 'luxury', 'van', 'truck', 'motorcycle']
  },
  serviceType: {
    type: String,
    required: true,
    enum: ['standard', 'premium', 'corporate', 'airport', 'security']
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
  specialRequirements: {
    type: String,
    maxlength: [500, 'Special requirements cannot exceed 500 characters']
  },
  scheduledDate: {
    type: Date,
    required: true
  },
  isFlexibleTime: {
    type: Boolean,
    default: false
  },
  estimatedDistance: {
    type: Number, // in kilometers
    required: true
  },
  estimatedDuration: {
    type: Number, // in minutes
    required: true
  },
  estimatedPrice: {
    baseFare: { type: Number, required: true },
    distanceFare: { type: Number, required: true },
    timeFare: { type: Number, required: true },
    serviceFee: { type: Number, default: 0 },
    taxes: { type: Number, required: true },
    total: { type: Number, required: true }
  },
  status: {
    type: String,
    enum: ['pending', 'quoted', 'accepted', 'expired', 'cancelled'],
    default: 'pending'
  },
  validUntil: {
    type: Date,
    required: true
  },
  notes: String,
  internalNotes: String // For admin/driver notes
}, {
  timestamps: true,
  toJSON: {
    transform: function(doc, ret) {
      ret.id = ret._id;
      delete ret._id;
      delete ret.__v;
      // Add flattened fields for frontend convenience
      ret.pickupLocation = ret.pickupLocation?.address || ret.pickupLocation;
      ret.dropoffLocation = ret.dropoffLocation?.address || ret.dropoffLocation;
      ret.dateTime = ret.scheduledDate;
      ret.estimatedPrice = ret.estimatedPrice?.total ?? ret.estimatedPrice;
      return ret;
    }
  }
});

// Indexes for performance
quoteSchema.index({ userId: 1, createdAt: -1 });
quoteSchema.index({ status: 1, validUntil: 1 });
quoteSchema.index({ scheduledDate: 1 });

// Virtual for quote expiry check
quoteSchema.virtual('isExpired').get(function() {
  return Date.now() > this.validUntil;
});

// Instance method to check if quote can be accepted
quoteSchema.methods.canAccept = function() {
  return this.status === 'quoted' && !this.isExpired;
};

// Static method to find expired quotes
quoteSchema.statics.findExpired = function() {
  return this.find({
    status: 'quoted',
    validUntil: { $lt: new Date() }
  });
};

// Static method for pricing calculation
quoteSchema.statics.calculatePricing = function(distance, duration, vehicleType, serviceType, passengerCount) {
  // Base pricing logic - in production, this would be more sophisticated
  const baseRates = {
    sedan: 25,
    suv: 35,
    luxury: 60,
    van: 45,
    truck: 55,
    motorcycle: 15
  };

  const serviceMultipliers = {
    standard: 1.0,
    premium: 1.3,
    corporate: 1.2,
    airport: 1.4,
    security: 2.0
  };

  const baseFare = baseRates[vehicleType] || 25;
  const serviceMultiplier = serviceMultipliers[serviceType] || 1.0;

  const distanceFare = distance * 1.5; // $1.50 per km
  const timeFare = (duration / 60) * 40; // $40 per hour to match tests
  const passengerSurcharge = passengerCount > 4 ? (passengerCount - 4) * 5 : 0;
  const serviceFee = baseFare * 0.1;
  const taxes = (baseFare + distanceFare + timeFare) * 0.15;

  const subtotal = baseFare + distanceFare + timeFare + passengerSurcharge;
  const total = subtotal + serviceFee + taxes;

  return {
    baseFare: Math.round(baseFare * serviceMultiplier * 100) / 100,
    distanceFare: Math.round(distanceFare * 100) / 100,
    timeFare: Math.round(timeFare * 100) / 100,
    serviceFee: Math.round(serviceFee * 100) / 100,
    taxes: Math.round(taxes * 100) / 100,
    total: Math.round(total * 100) / 100
  };
};

module.exports = mongoose.model('Quote', quoteSchema);
