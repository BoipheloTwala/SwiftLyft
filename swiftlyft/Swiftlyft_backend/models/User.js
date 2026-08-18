const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

// Subdocument schemas
const loyaltyRewardSchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: { type: String, required: true },
  type: { 
    type: String, 
    required: true,
    enum: ['discount', 'free_ride', 'upgrade', 'priority']
  },
  pointsCost: { type: Number, required: true },
  discountPercentage: { type: Number, default: 0 },
  isActive: { type: Boolean, default: true },
  expiresAt: Date,
  redeemedAt: Date
}, { _id: true });

const referralSchema = new mongoose.Schema({
  referredUserId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  referredUserEmail: String,
  referredUserName: String,
  status: { 
    type: String, 
    enum: ['pending', 'completed', 'cancelled'], 
    default: 'pending' 
  },
  earnings: { type: Number, default: 0 },
  createdAt: { type: Date, default: Date.now },
  completedAt: Date
}, { _id: true });

const corporateAccountSchema = new mongoose.Schema({
  companyName: { type: String, required: true },
  companyEmail: { type: String, required: true },
  contactPerson: { type: String, required: true },
  contactPhone: { type: String, required: true },
  discountPercentage: { type: Number, default: 0 },
  monthlyBudget: { type: Number, default: 0 },
  usedBudget: { type: Number, default: 0 },
  status: { 
    type: String, 
    enum: ['active', 'suspended', 'pending'], 
    default: 'active' 
  },
  createdAt: { type: Date, default: Date.now },
  expiresAt: Date,
  authorizedUsers: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }]
}, { _id: false });

const bulkBookingItemSchema = new mongoose.Schema({
  vehicleId: { type: mongoose.Schema.Types.ObjectId, required: true },
  vehicleName: { type: String, required: true },
  quantity: { type: Number, required: true, min: 1 },
  unitPrice: { type: Number, required: true, min: 0 },
  pickupLocation: { type: String, required: true },
  dropoffLocation: { type: String, required: true },
  pickupTime: { type: Date, required: true },
  passengerCount: { type: Number, required: true, min: 1 }
}, { _id: true });

const bulkBookingSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: { type: String, required: true },
  items: [bulkBookingItemSchema],
  status: { 
    type: String, 
    enum: ['draft', 'pending', 'confirmed', 'completed', 'cancelled'], 
    default: 'draft' 
  },
  totalAmount: { type: Number, default: 0 },
  discountAmount: { type: Number, default: 0 },
  createdAt: { type: Date, default: Date.now },
  scheduledDate: Date,
  specialNotes: String
}, { _id: true });

// Main User schema
const userSchema = new mongoose.Schema({
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    trim: true,
    match: [/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/, 'Please enter a valid email']
  },
  password: {
    type: String,
    required: [true, 'Password is required'],
    minlength: [8, 'Password must be at least 8 characters long'],
    select: false // Don't include password in queries by default
  },
  name: {
    type: String,
    trim: true,
    maxlength: [50, 'Name cannot exceed 50 characters']
  },
  role: {
    type: String,
    enum: ['user', 'admin'],
    default: 'user'
  },
  phoneNumber: {
    type: String,
    trim: true,
    match: [/^\+?[1-9]\d{1,14}$/, 'Please enter a valid phone number'],
    validate: {
      validator: function(v) {
        return !v || /^\+?[1-9]\d{1,14}$/.test(v);
      },
      message: 'Please enter a valid phone number'
    }
  },
  profileImageUrl: String,
  
  // Loyalty program fields
  loyaltyTier: {
    type: String,
    enum: ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond'],
    default: 'Bronze'
  },
  loyaltyPoints: { type: Number, default: 0, min: 0 },
  totalTrips: { type: Number, default: 0, min: 0 },
  totalSpent: { type: Number, default: 0, min: 0 },
  
  // User preferences
  savedAddresses: [{
    label: String, // e.g., "Home", "Work"
    address: String,
    coordinates: {
      latitude: { 
        type: Number,
        min: -90,
        max: 90,
        validate: {
          validator: function(v) {
            return v >= -90 && v <= 90;
          },
          message: 'Latitude must be between -90 and 90 degrees'
        }
      },
      longitude: { 
        type: Number,
        min: -180,
        max: 180,
        validate: {
          validator: function(v) {
            return v >= -180 && v <= 180;
          },
          message: 'Longitude must be between -180 and 180 degrees'
        }
      }
    },
    isDefault: { type: Boolean, default: false }
  }],
  
  paymentMethods: [{ type: mongoose.Schema.Types.ObjectId, ref: 'PaymentMethod' }],
  
  // Loyalty rewards
  earnedRewards: [loyaltyRewardSchema],
  availableRewards: [loyaltyRewardSchema],
  
  // Referral system
  referralCode: { 
    type: String, 
    unique: true,
    sparse: true // Allow null values to be non-unique
  },
  referredBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  referrals: [referralSchema],
  
  // Corporate account
  corporateAccount: corporateAccountSchema,
  bulkBookings: { type: [bulkBookingSchema], default: [] },
  
  // Account status
  isEmailVerified: { type: Boolean, default: false },
  isPhoneVerified: { type: Boolean, default: false },
  isActive: { type: Boolean, default: true },
  
  // Security
  refreshTokens: [{
    token: String,
    createdAt: { type: Date, default: Date.now },
    expiresAt: Date
  }],
  
  // Login tracking
  lastLoginAt: Date,
  lastLoginIP: String,
  loginCount: { type: Number, default: 0 },
  
  // Password reset
  resetPasswordToken: String,
  resetPasswordExpires: Date,
  
  // Email verification
  emailVerificationToken: String,
  emailVerificationExpires: Date,
  
  // Phone verification (via email)
  phoneVerificationCode: String,
  phoneVerificationExpires: Date,
  phoneVerificationAttempts: { type: Number, default: 0 },
  pendingPhoneNumber: String,

  // Notification settings
  notificationSettings: {
    push: { type: Boolean, default: true },
    email: { type: Boolean, default: true },
    sms: { type: Boolean, default: false },
    bookingUpdates: { type: Boolean, default: true },
    promotionalOffers: { type: Boolean, default: true },
    paymentReminders: { type: Boolean, default: true },
    driverMessages: { type: Boolean, default: true }
  },

  // FCM token for push notifications
  fcmToken: String
}, {
  timestamps: true, // Adds createdAt and updatedAt
  toJSON: {
    virtuals: true, // Include virtual fields in JSON output
    transform: function(doc, ret) {
      // Helper to recursively convert _id -> id on plain objects/arrays
      const normalizeIds = (value) => {
        if (!value) return value;
        if (value instanceof Date) return value; // Preserve Date objects
        if (Array.isArray(value)) {
          return value.map(normalizeIds);
        }
        if (typeof value === 'object') {
          const out = {};
          for (const key of Object.keys(value)) {
            if (key === '_id') {
              out.id = value._id;
            } else {
              out[key] = normalizeIds(value[key]);
            }
          }
          return out;
        }
        return value;
      };

      // Root id normalization and redactions
      ret.id = ret._id;
      delete ret._id;
      delete ret.__v;
      delete ret.password;
      delete ret.refreshTokens;
      delete ret.resetPasswordToken;
      delete ret.resetPasswordExpires;
      delete ret.emailVerificationToken;
      delete ret.emailVerificationExpires;
      delete ret.phoneVerificationCode;
      delete ret.phoneVerificationExpires;
      delete ret.phoneVerificationAttempts;
      delete ret.pendingPhoneNumber;

      // Keep savedAddresses as complex objects for frontend compatibility
      // The frontend now expects SavedAddress objects with id, label, address, coordinates, isDefault
      if (Array.isArray(ret.savedAddresses)) {
        ret.savedAddresses = ret.savedAddresses.map(addr => ({
          id: addr._id || addr.id,
          label: addr.label || '',
          address: addr.address || '',
          coordinates: addr.coordinates || null,
          isDefault: addr.isDefault || false
        }));
      }

      // Normalize subdocuments to expose `id` instead of `_id`
      if (Array.isArray(ret.earnedRewards)) ret.earnedRewards = normalizeIds(ret.earnedRewards);
      if (Array.isArray(ret.availableRewards)) ret.availableRewards = normalizeIds(ret.availableRewards);
      if (Array.isArray(ret.referrals)) ret.referrals = normalizeIds(ret.referrals);
      if (Array.isArray(ret.bulkBookings)) ret.bulkBookings = normalizeIds(ret.bulkBookings);

      // Corporate account: ensure an id exists even though schema disables _id
      if (ret.corporateAccount) {
        ret.corporateAccount = normalizeIds(ret.corporateAccount);
        if (!ret.corporateAccount.id) {
          // Synthesize a stable id based on user id
          ret.corporateAccount.id = `${ret.id}:corporate`;
        }
      }

      return ret;
    }
  }
});

// Indexes for performance
userSchema.index({ email: 1 });
userSchema.index({ referralCode: 1 });
userSchema.index({ 'refreshTokens.token': 1 });
userSchema.index({ resetPasswordToken: 1 });
userSchema.index({ emailVerificationToken: 1 });

// Virtual fields
userSchema.virtual('pointsToNextTier').get(function() {
  const tierPoints = {
    'Bronze': 1000,
    'Silver': 2500,
    'Gold': 5000,
    'Platinum': 10000,
    'Diamond': Infinity
  };
  const tier = this.loyaltyTier || 'Bronze';
  const nextTierPoints = tierPoints[tier];
  if (nextTierPoints === undefined) return 0;
  return Math.max(0, nextTierPoints - (this.loyaltyPoints || 0));
});

userSchema.virtual('tierProgress').get(function() {
  const tierRanges = {
    'Bronze': [0, 1000],
    'Silver': [1000, 2500],
    'Gold': [2500, 5000],
    'Platinum': [5000, 10000],
    'Diamond': [10000, Infinity]
  };
  const tier = this.loyaltyTier || 'Bronze';
  const range = tierRanges[tier];
  if (!range || !Array.isArray(range)) return 0;
  const [min, max] = range;
  const points = this.loyaltyPoints || 0;
  return max === Infinity ? 1.0 : Math.min(1.0, (points - min) / (max - min));
});

userSchema.virtual('tierDiscount').get(function() {
  const discounts = {
    'Bronze': 0.0,
    'Silver': 0.05,
    'Gold': 0.10,
    'Platinum': 0.15,
    'Diamond': 0.20
  };
  const tier = this.loyaltyTier || 'Bronze';
  return discounts[tier] || 0.0;
});

userSchema.virtual('isCorporateUser').get(function() {
  return this.corporateAccount != null;
});

// Pre-save middleware
userSchema.pre('save', async function(next) {
  // Only hash password if it was modified
  if (!this.isModified('password')) return next();
  
  try {
    const saltRounds = parseInt(process.env.BCRYPT_SALT_ROUNDS) || 12;
    this.password = await bcrypt.hash(this.password, saltRounds);
    next();
  } catch (error) {
    next(error);
  }
});

// Generate referral code if not exists
userSchema.pre('save', async function(next) {
  try {
    if (!this.referralCode && this.isNew) {
      // Generate a unique referral code using pure random bytes
      const crypto = require('crypto');
      let code;
      let attempts = 0;
      const maxAttempts = 10;
      
      console.log('🎯 Generating referral code for new user:', this.email);
      
      // Keep generating until we find a unique code
      while (attempts < maxAttempts) {
        // Generate 8 random bytes = 16 hex characters
        code = `REF${crypto.randomBytes(8).toString('hex').toUpperCase()}`;
        
        console.log(`  Attempt ${attempts + 1}: Generated code ${code}`);
        
        // Check if this code already exists
        const exists = await mongoose.models.User.findOne({ referralCode: code }).select('_id');
        if (!exists) {
          console.log(`  ✅ Code ${code} is unique!`);
          break; // Found a unique code
        }
        
        console.log(`  ❌ Code ${code} already exists, retrying...`);
        attempts++;
      }
      
      this.referralCode = code;
      console.log(`🎉 Final referral code assigned: ${code}`);
    } else if (this.referralCode) {
      console.log('ℹ️ User already has referral code:', this.referralCode);
    }
    next();
  } catch (err) {
    console.error('❌ Error generating referral code:', err);
    next(err);
  }
});

// Instance methods
userSchema.methods.comparePassword = async function(candidatePassword) {
  if (!this.password) {
    throw new Error('User password not found');
  }
  return bcrypt.compare(candidatePassword, this.password);
};

userSchema.methods.generateRefreshToken = function() {
  const crypto = require('crypto');
  return crypto.randomBytes(40).toString('hex');
};

userSchema.methods.addRefreshToken = function(token) {
  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + 7); // 7 days
  
  this.refreshTokens.push({
    token,
    expiresAt
  });
  
  // Keep only the last 5 refresh tokens
  if (this.refreshTokens.length > 5) {
    this.refreshTokens = this.refreshTokens.slice(-5);
  }
};

userSchema.methods.removeRefreshToken = function(token) {
  if (!this.refreshTokens) {
    this.refreshTokens = [];
    return;
  }
  this.refreshTokens = this.refreshTokens.filter(rt => rt.token !== token);
};

userSchema.methods.updateLoyaltyTier = function() {
  const points = this.loyaltyPoints;
  let newTier = 'Bronze';
  
  if (points >= 10000) newTier = 'Diamond';
  else if (points >= 5000) newTier = 'Platinum';
  else if (points >= 2500) newTier = 'Gold';
  else if (points >= 1000) newTier = 'Silver';
  
  const oldTier = this.loyaltyTier;
  this.loyaltyTier = newTier;
  
  return oldTier !== newTier; // Return true if tier changed
};

userSchema.methods.addLoyaltyPoints = function(points, reason = 'Booking completed') {
  this.loyaltyPoints += points;
  const tierChanged = this.updateLoyaltyTier();
  
  // You could add a loyalty transaction log here
  
  return { tierChanged, newTier: this.loyaltyTier };
};

// Static methods
userSchema.statics.findByEmail = function(email) {
  return this.findOne({ email: email.toLowerCase() });
};

userSchema.statics.findByReferralCode = function(code) {
  return this.findOne({ referralCode: code });
};

module.exports = mongoose.model('User', userSchema);