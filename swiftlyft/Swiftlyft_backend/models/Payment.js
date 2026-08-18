const mongoose = require('mongoose');

// Payment method schema
const paymentMethodSchema = new mongoose.Schema({
  userId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  type: {
    type: String,
    required: true,
    enum: ['credit_card', 'debit_card', 'bank_transfer', 'digital_wallet', 'cash']
  },
  provider: {
    type: String,
    required: true,
    enum: ['visa', 'mastercard', 'amex', 'paypal', 'apple_pay', 'google_pay', 'eft', 'cash']
  },
  lastFourDigits: {
    type: String,
    required: function() {
      return this.type !== 'cash';
    },
    match: [/^\d{4}$/, 'Last four digits must be exactly 4 digits']
  },
  expiryMonth: {
    type: Number,
    min: 1,
    max: 12,
    required: function() {
      return ['credit_card', 'debit_card'].includes(this.type);
    }
  },
  expiryYear: {
    type: Number,
    min: new Date().getFullYear(),
    required: function() {
      return ['credit_card', 'debit_card'].includes(this.type);
    }
  },
  cardholderName: {
    type: String,
    required: function() {
      return ['credit_card', 'debit_card'].includes(this.type);
    },
    trim: true
  },
  isDefault: {
    type: Boolean,
    default: false
  },
  isActive: {
    type: Boolean,
    default: true
  },
  // Encrypted sensitive data (in real implementation, use proper encryption)
  encryptedData: {
    type: String,
    required: function() {
      return this.type !== 'cash';
    }
  },
  // External payment processor IDs
  externalId: String, // Stripe, PayPal, etc. payment method ID
  fingerprint: String, // For fraud detection
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true,
  toJSON: {
    transform: function(doc, ret) {
      ret.id = ret._id;
      delete ret._id;
      delete ret.__v;
      delete ret.encryptedData; // Never expose encrypted data
      return ret;
    }
  }
});

// Payment transaction schema
const paymentSchema = new mongoose.Schema({
  userId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  bookingId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Booking',
    required: true
  },
  paymentMethodId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'PaymentMethod',
    required: true
  },
  amount: {
    type: Number,
    required: true,
    min: 0.01
  },
  currency: {
    type: String,
    required: true,
    default: 'ZAR',
    enum: ['ZAR', 'USD', 'EUR', 'GBP']
  },
  status: {
    type: String,
    required: true,
    enum: ['pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded', 'partially_refunded'],
    default: 'pending'
  },
  transactionType: {
    type: String,
    required: true,
    enum: ['payment', 'refund', 'partial_refund']
  },
  // External payment processor data
  externalTransactionId: String, // Stripe, PayPal, etc. transaction ID
  externalPaymentIntentId: String, // For Stripe Payment Intents
  processorResponse: {
    code: String,
    message: String,
    rawResponse: mongoose.Schema.Types.Mixed
  },
  // Payment processing details
  processingFee: {
    type: Number,
    default: 0,
    min: 0
  },
  netAmount: {
    type: Number,
    required: true,
    min: 0
  },
  // Refund information
  refunds: [{
    amount: { type: Number, required: true, min: 0.01 },
    reason: { type: String, required: true },
    status: { 
      type: String, 
      enum: ['pending', 'processing', 'completed', 'failed'],
      default: 'pending'
    },
    externalRefundId: String,
    processedAt: Date,
    createdAt: { type: Date, default: Date.now }
  }],
  totalRefunded: {
    type: Number,
    default: 0,
    min: 0
  },
  // Metadata
  description: String,
  metadata: mongoose.Schema.Types.Mixed,
  // Timestamps
  processedAt: Date,
  failedAt: Date,
  cancelledAt: Date,
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
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
paymentMethodSchema.index({ userId: 1 });
paymentMethodSchema.index({ userId: 1, isDefault: 1 });
paymentMethodSchema.index({ externalId: 1 });

paymentSchema.index({ userId: 1 });
paymentSchema.index({ bookingId: 1 });
paymentSchema.index({ status: 1 });
paymentSchema.index({ externalTransactionId: 1 });
paymentSchema.index({ createdAt: -1 });

// Pre-save middleware for payment methods
paymentMethodSchema.pre('save', async function(next) {
  // Ensure only one default payment method per user
  if (this.isDefault && this.isModified('isDefault')) {
    await this.constructor.updateMany(
      { userId: this.userId, _id: { $ne: this._id } },
      { isDefault: false }
    );
  }
  
  // Update updatedAt
  this.updatedAt = new Date();
  next();
});

// Pre-save middleware for payments
paymentSchema.pre('save', function(next) {
  // Calculate net amount
  this.netAmount = this.amount - this.processingFee;
  
  // Update total refunded
  this.totalRefunded = this.refunds.reduce((total, refund) => {
    return total + (refund.status === 'completed' ? refund.amount : 0);
  }, 0);
  
  // Update status based on refunds
  if (this.totalRefunded > 0) {
    if (this.totalRefunded >= this.amount) {
      this.status = 'refunded';
    } else {
      this.status = 'partially_refunded';
    }
  }
  
  this.updatedAt = new Date();
  next();
});

// Instance methods for PaymentMethod
paymentMethodSchema.methods.maskCardNumber = function() {
  if (this.type === 'cash') return 'Cash';
  return `**** **** **** ${this.lastFourDigits}`;
};

paymentMethodSchema.methods.isExpired = function() {
  if (!this.expiryMonth || !this.expiryYear) return false;
  
  const now = new Date();
  const currentYear = now.getFullYear();
  const currentMonth = now.getMonth() + 1;
  
  return this.expiryYear < currentYear || 
         (this.expiryYear === currentYear && this.expiryMonth < currentMonth);
};

// Instance methods for Payment
paymentSchema.methods.canRefund = function() {
  return this.status === 'completed' && this.totalRefunded < this.amount;
};

paymentSchema.methods.getRefundableAmount = function() {
  return this.status === 'completed' ? this.amount - this.totalRefunded : 0;
};

paymentSchema.methods.addRefund = function(refundData) {
  if (!this.canRefund()) {
    throw new Error('Payment cannot be refunded');
  }
  
  const refundableAmount = this.getRefundableAmount();
  if (refundData.amount > refundableAmount) {
    throw new Error(`Refund amount cannot exceed ${refundableAmount}`);
  }
  
  this.refunds.push(refundData);
  return this.save();
};

// Static methods
paymentSchema.statics.findByUser = function(userId, options = {}) {
  const query = { userId };
  
  if (options.status) {
    query.status = options.status;
  }
  
  if (options.dateFrom || options.dateTo) {
    query.createdAt = {};
    if (options.dateFrom) query.createdAt.$gte = new Date(options.dateFrom);
    if (options.dateTo) query.createdAt.$lte = new Date(options.dateTo);
  }
  
  return this.find(query)
    .populate('bookingId', 'pickupLocation dropoffLocation scheduledTime')
    .populate('paymentMethodId', 'type provider lastFourDigits')
    .sort({ createdAt: -1 })
    .limit(options.limit || 50);
};

paymentSchema.statics.getPaymentStats = function(userId) {
  return this.aggregate([
    { $match: { userId: mongoose.Types.ObjectId(userId) } },
    {
      $group: {
        _id: '$status',
        count: { $sum: 1 },
        totalAmount: { $sum: '$amount' }
      }
    }
  ]);
};

// Create models
const PaymentMethod = mongoose.model('PaymentMethod', paymentMethodSchema);
const Payment = mongoose.model('Payment', paymentSchema);

module.exports = { PaymentMethod, Payment };
