const express = require('express');
const mongoose = require('mongoose');
const User = require('../models/User');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Utility: normalize Mongoose documents to plain JSON with id fields
function asPlain(doc) {
  if (!doc) return doc;
  if (typeof doc.toJSON === 'function') return doc.toJSON();
  if (typeof doc.toObject === 'function') return doc.toObject({ virtuals: true });
  return doc;
}

function normalizeIdFields(value) {
  if (!value) return value;
  if (Array.isArray(value)) return value.map(normalizeIdFields);
  if (typeof value === 'object') {
    const out = {};
    for (const key of Object.keys(value)) {
      if (key === '_id') out.id = value._id;
      else out[key] = normalizeIdFields(value[key]);
    }
    return out;
  }
  return value;
}

// All user routes require authentication
router.use(authenticateToken);

/**
 * @swagger
 * /api/users/profile:
 *   get:
 *     summary: Get current user profile
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User profile retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         user:
 *                           $ref: '#/components/schemas/User'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *     description: |
 *       Response notes:
 *       - All nested documents expose `id` instead of `_id`.
 *       - `savedAddresses` is a flattened string array in the top-level user JSON.
 */
router.get('/profile', async (req, res, next) => {
  try {
    // User is already attached to req by authenticateToken middleware
    const user = asPlain(req.user);
    res.json({
      success: true,
      data: {
        user
      }
    });
  } catch (error) {
    next(error);
  }
});

// Proxy to get user's quotes: align with tests expecting /api/users/:userId/quotes
router.get('/:userId/quotes', async (req, res, next) => {
  try {
    const quotesRouter = require('./quotes');
    // Delegate by changing url to match router.get('/user/:userId')
    req.url = `/user/${req.params.userId}${req.url.split(`/quotes`)[1] || ''}`;
    return quotesRouter.handle(req, res, next);
  } catch (error) {
    next(error);
  }
});

// Proxy notifications routes: align with tests expecting /api/users/:userId/notifications
router.get('/:userId/notifications', async (req, res, next) => {
  try {
    const notificationsRouter = require('./notifications');
    req.url = `/user/${req.params.userId}${req.url.split(`/notifications`)[1] || ''}`;
    return notificationsRouter.handle(req, res, next);
  } catch (error) {
    next(error);
  }
});

router.put('/:userId/notifications/:notificationId/read', async (req, res, next) => {
  try {
    const notificationsRouter = require('./notifications');
    req.url = `/user/${req.params.userId}/${req.params.notificationId}/read`;
    return notificationsRouter.handle(req, res, next);
  } catch (error) {
    next(error);
  }
});

// Proxy notification settings routes: align with tests expecting /api/users/:userId/notification-settings
router.get('/:userId/notification-settings', async (req, res, next) => {
  try {
    const notificationsRouter = require('./notifications');
    req.url = `/user/${req.params.userId}/settings`;
    return notificationsRouter.handle(req, res, next);
  } catch (error) {
    next(error);
  }
});

router.put('/:userId/notification-settings', async (req, res, next) => {
  try {
    const notificationsRouter = require('./notifications');
    req.url = `/user/${req.params.userId}/settings`;
    return notificationsRouter.handle(req, res, next);
  } catch (error) {
    next(error);
  }
});

// Proxy FCM token routes: align with tests expecting /api/users/:userId/fcm-token
router.post('/:userId/fcm-token', async (req, res, next) => {
  try {
    const notificationsRouter = require('./notifications');
    req.url = `/user/${req.params.userId}/fcm-token`;
    return notificationsRouter.handle(req, res, next);
  } catch (error) {
    next(error);
  }
});

// Proxy support tickets: align with tests expecting /api/users/:userId/support-tickets
router.get('/:userId/support-tickets', async (req, res, next) => {
  try {
    const supportRouter = require('./support');
    req.url = `/user/${req.params.userId}/tickets${req.url.split(`/support-tickets`)[1] || ''}`;
    return supportRouter.handle(req, res, next);
  } catch (error) {
    next(error);
  }
});

// @route   PUT /api/users/profile
// @desc    Update user profile
// @access  Private
router.put('/profile', async (req, res, next) => {
  try {
    const { name, phoneNumber } = req.body;
    
    const updateData = {};
    
    if (name !== undefined) {
      updateData.name = name?.trim();
    }
    
    if (phoneNumber !== undefined) {
      // Validate phone number format
      const phoneRegex = /^\+?[1-9]\d{1,14}$/;
      if (phoneNumber && !phoneRegex.test(phoneNumber)) {
        return res.status(400).json({
          success: false,
          message: 'Please provide a valid phone number'
        });
      }
      updateData.phoneNumber = phoneNumber?.trim();
    }

    const user = await User.findByIdAndUpdate(
      req.userId,
      updateData,
      { new: true, runValidators: true }
    ).select('-password -refreshTokens');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        user: user.toJSON()
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   POST /api/users/upload-avatar
// @desc    Upload profile picture
// @access  Private
router.post('/upload-avatar', async (req, res, next) => {
  try {
    const { profileImageUrl } = req.body;

    if (!profileImageUrl) {
      return res.status(400).json({
        success: false,
        message: 'Profile image URL is required'
      });
    }

    // Basic URL validation
    const urlRegex = /^https?:\/\/.+\.(jpg|jpeg|png|gif)$/i;
    if (!urlRegex.test(profileImageUrl)) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a valid image URL'
      });
    }

    const user = await User.findByIdAndUpdate(
      req.userId,
      { profileImageUrl },
      { new: true, runValidators: true }
    ).select('-password -refreshTokens');

    res.json({
      success: true,
      message: 'Profile picture updated successfully',
      data: {
        user: user.toJSON()
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/users/addresses
// @desc    Get user's saved addresses
// @access  Private
router.get('/addresses', async (req, res, next) => {
  try {
    const user = await User.findById(req.userId).select('savedAddresses');
    const fullAddresses = user?.savedAddresses?.map(a => normalizeIdFields(asPlain(a))) || [];
    const addressStrings = fullAddresses
      .filter(a => a && typeof a.address === 'string')
      .map(a => a.address);
    
    res.json({
      success: true,
      data: {
        addresses: fullAddresses,
        addressStrings
      }
    });

  } catch (error) {
    next(error);
  }
});
/**
 * @swagger
 * /api/users/addresses:
 *   get:
 *     summary: Get user's saved addresses
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Returns full address objects and a string-only list
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         addresses:
 *                           type: array
 *                           description: Full address objects with id
 *                           items:
 *                             type: object
 *                             properties:
 *                               id:
 *                                 type: string
 *                               label:
 *                                 type: string
 *                               address:
 *                                 type: string
 *                               coordinates:
 *                                 type: object
 *                                 properties:
 *                                   latitude:
 *                                     type: number
 *                                   longitude:
 *                                     type: number
 *                               isDefault:
 *                                 type: boolean
 *                         addressStrings:
 *                           type: array
 *                           description: Flattened list of address strings for UI models
 *                           items:
 *                             type: string
 */

// @route   POST /api/users/addresses
// @desc    Add new saved address
// @access  Private
router.post('/addresses', async (req, res, next) => {
  try {
    const { label, address, coordinates, isDefault } = req.body;

    if (!label || !address) {
      return res.status(400).json({
        success: false,
        message: 'Label and address are required'
      });
    }

    if (coordinates && (!coordinates.latitude || !coordinates.longitude)) {
      return res.status(400).json({
        success: false,
        message: 'Both latitude and longitude are required for coordinates'
      });
    }

    const user = await User.findById(req.userId);

    // If this is set as default, remove default from other addresses
    if (isDefault) {
      user.savedAddresses.forEach(addr => {
        addr.isDefault = false;
      });
    }

    // Add new address
    user.savedAddresses.push({
      label: label.trim(),
      address: address.trim(),
      coordinates,
      isDefault: isDefault || false
    });

    await user.save();

    res.status(201).json({
      success: true,
      message: 'Address added successfully',
      data: {
        addresses: user.savedAddresses.map(a => normalizeIdFields(asPlain(a)))
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   PUT /api/users/addresses/:addressId
// @desc    Update saved address
// @access  Private
router.put('/addresses/:addressId', async (req, res, next) => {
  try {
    const { addressId } = req.params;
    const { label, address, coordinates, isDefault } = req.body;

    const user = await User.findById(req.userId);
    
    const addressIndex = user.savedAddresses.findIndex(
      addr => addr._id.toString() === addressId
    );

    if (addressIndex === -1) {
      return res.status(404).json({
        success: false,
        message: 'Address not found'
      });
    }

    // If this is set as default, remove default from other addresses
    if (isDefault) {
      user.savedAddresses.forEach((addr, index) => {
        if (index !== addressIndex) {
          addr.isDefault = false;
        }
      });
    }

    // Update address
    if (label) user.savedAddresses[addressIndex].label = label.trim();
    if (address) user.savedAddresses[addressIndex].address = address.trim();
    if (coordinates) user.savedAddresses[addressIndex].coordinates = coordinates;
    if (isDefault !== undefined) user.savedAddresses[addressIndex].isDefault = isDefault;

    await user.save();

    res.json({
      success: true,
      message: 'Address updated successfully',
      data: {
        addresses: user.savedAddresses.map(a => normalizeIdFields(asPlain(a)))
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   DELETE /api/users/addresses/:addressId
// @desc    Delete saved address
// @access  Private
router.delete('/addresses/:addressId', async (req, res, next) => {
  try {
    const { addressId } = req.params;

    const user = await User.findById(req.userId);
    
    const addressExists = user.savedAddresses.some(
      addr => addr._id.toString() === addressId
    );

    if (!addressExists) {
      return res.status(404).json({
        success: false,
        message: 'Address not found'
      });
    }

    // Remove address
    user.savedAddresses = user.savedAddresses.filter(
      addr => addr._id.toString() !== addressId
    );

    await user.save();

    res.json({
      success: true,
      message: 'Address deleted successfully',
      data: {
        addresses: user.savedAddresses.map(a => normalizeIdFields(asPlain(a)))
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/users/loyalty
// @desc    Get user loyalty information
// @access  Private
router.get('/loyalty', async (req, res, next) => {
  try {
    const user = asPlain(req.user);
    
    res.json({
      success: true,
      data: {
        loyaltyTier: user.loyaltyTier,
        loyaltyPoints: user.loyaltyPoints,
        pointsToNextTier: user.pointsToNextTier,
        tierProgress: user.tierProgress,
        tierDiscount: user.tierDiscount,
        earnedRewards: user.earnedRewards,
        availableRewards: user.availableRewards,
        totalTrips: user.totalTrips,
        totalSpent: user.totalSpent
      }
    });

  } catch (error) {
    next(error);
  }
});
/**
 * @swagger
 * /api/users/loyalty:
 *   get:
 *     summary: Get loyalty info for current user
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Loyalty data with normalized reward ids
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         loyaltyTier:
 *                           type: string
 *                         loyaltyPoints:
 *                           type: integer
 *                         earnedRewards:
 *                           type: array
 *                           items:
 *                             $ref: '#/components/schemas/LoyaltyReward'
 *                         availableRewards:
 *                           type: array
 *                           items:
 *                             $ref: '#/components/schemas/LoyaltyReward'
 */

// @route   GET /api/users/referral
// @desc    Get user referral information
// @access  Private
router.get('/referral', async (req, res, next) => {
  try {
    const user = asPlain(req.user);
    
    // Calculate referral stats
    const referralEarnings = user.referrals.reduce((sum, ref) => sum + ref.earnings, 0);
    const successfulReferrals = user.referrals.filter(ref => ref.status === 'completed').length;
    const pendingReferrals = user.referrals.filter(ref => ref.status === 'pending').length;

    res.json({
      success: true,
      data: {
        referralCode: user.referralCode,
        referrals: user.referrals,
        stats: {
          totalReferrals: user.referrals.length,
          successfulReferrals,
          pendingReferrals,
          totalEarnings: referralEarnings
        }
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/users/corporate
// @desc    Get corporate account information
// @access  Private
router.get('/corporate', async (req, res, next) => {
  try {
    const user = asPlain(req.user);
    
    if (!user.isCorporateUser) {
      return res.status(404).json({
        success: false,
        message: 'No corporate account found'
      });
    }

    res.json({
      success: true,
      data: {
        corporateAccount: user.corporateAccount,
        bulkBookings: user.bulkBookings
      }
    });

  } catch (error) {
    next(error);
  }
});
/**
 * @swagger
 * /api/users/corporate:
 *   get:
 *     summary: Get corporate account and bulk bookings for current user
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Corporate account includes an `id`; bulk bookings and items include `id`
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         corporateAccount:
 *                           $ref: '#/components/schemas/CorporateAccount'
 *                         bulkBookings:
 *                           type: array
 *                           items:
 *                             $ref: '#/components/schemas/BulkBooking'
 */

// @route   DELETE /api/users/account
// @desc    Delete user account (soft delete by default, hard delete optional)
// @access  Private
router.delete('/account', async (req, res, next) => {
  try {
    const { password, permanent = false } = req.body;

    if (!password) {
      return res.status(400).json({
        success: false,
        message: 'Password is required to delete account'
      });
    }

    // Get user with password
    const user = await User.findById(req.userId).select('+password');
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    // Verify password
    const isPasswordValid = await user.comparePassword(password);
    
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Incorrect password. Account deletion cancelled.'
      });
    }

    // Store user info for response
    const userEmail = user.email;
    const userName = user.name;

    if (permanent === true) {
      // HARD DELETE: Permanently remove user from database
      // WARNING: This is irreversible!
      
      // Log the deletion for audit purposes
      console.log(`⚠️  PERMANENT ACCOUNT DELETION: User ${userName} (${userEmail}, ID: ${user._id}) requested permanent account deletion`);
      
      // Delete the user document
      await User.findByIdAndDelete(req.userId);

      return res.json({
        success: true,
        message: 'Account has been permanently deleted. All your data has been removed.',
        deletionType: 'permanent'
      });
    } else {
      // SOFT DELETE: Deactivate account (recommended)
      // This allows for account recovery and maintains data integrity
      
      // Clear sensitive data and deactivate
      user.isActive = false;
      user.refreshTokens = []; // Invalidate all sessions
      user.fcmToken = null; // Remove push notification token
      
      // Optionally anonymize some data
      // user.email = `deleted_${user._id}@deleted.com`;
      // user.phoneNumber = null;
      
      await user.save();

      console.log(`✓ ACCOUNT DEACTIVATION: User ${userName} (${userEmail}, ID: ${user._id}) deactivated their account`);

      return res.json({
        success: true,
        message: 'Account has been deactivated successfully. You can contact support to reactivate it within 30 days.',
        deletionType: 'deactivation',
        recoveryPeriod: '30 days'
      });
    }

  } catch (error) {
    console.error('Account deletion error:', error);
    next(error);
  }
});

// @route   GET /api/users/stats
// @desc    Get user statistics
// @access  Private
router.get('/stats', async (req, res, next) => {
  try {
    const user = asPlain(req.user);
    
    res.json({
      success: true,
      data: {
        totalTrips: user.totalTrips,
        totalSpent: user.totalSpent,
        loyaltyPoints: user.loyaltyPoints,
        loyaltyTier: user.loyaltyTier,
        memberSince: user.createdAt,
        lastLogin: user.lastLoginAt,
        loginCount: user.loginCount,
        isEmailVerified: user.isEmailVerified,
        isPhoneVerified: user.isPhoneVerified
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/users/:id
// @desc    Get user profile by ID
// @access  Private
router.get('/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    
    // Validate ObjectId format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid user ID format'
      });
    }

    const user = await User.findById(id).select('-password -refreshTokens');
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Check if user is requesting their own profile or if they're an admin
    if (req.userId.toString() !== id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You can only view your own profile.'
      });
    }

    res.json({
      success: true,
      data: {
        user: user.toJSON()
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   PUT /api/users/:id
// @desc    Update user information by ID
// @access  Private
router.put('/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, phoneNumber, profileImageUrl } = req.body;
    
    // Validate ObjectId format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid user ID format'
      });
    }

    // Check if user is updating their own profile or if they're an admin
    if (req.userId.toString() !== id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You can only update your own profile.'
      });
    }

    const updateData = {};
    
    if (name !== undefined) {
      updateData.name = name?.trim();
    }
    
    if (phoneNumber !== undefined) {
      // Validate phone number format
      const phoneRegex = /^\+?[1-9]\d{1,14}$/;
      if (phoneNumber && !phoneRegex.test(phoneNumber)) {
        return res.status(400).json({
          success: false,
          message: 'Please provide a valid phone number'
        });
      }
      updateData.phoneNumber = phoneNumber?.trim();
    }

    if (profileImageUrl !== undefined) {
      // Basic URL validation
      const urlRegex = /^https?:\/\/.+\.(jpg|jpeg|png|gif)$/i;
      if (profileImageUrl && !urlRegex.test(profileImageUrl)) {
        return res.status(400).json({
          success: false,
          message: 'Please provide a valid image URL'
        });
      }
      updateData.profileImageUrl = profileImageUrl;
    }

    const user = await User.findByIdAndUpdate(
      id,
      updateData,
      { new: true, runValidators: true }
    ).select('-password -refreshTokens');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        user: user.toJSON()
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/users/:id/loyalty
// @desc    Get loyalty program data for user
// @access  Private
router.get('/:id/loyalty', async (req, res, next) => {
  try {
    const { id } = req.params;
    
    // Validate ObjectId format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid user ID format'
      });
    }

    // Check if user is requesting their own loyalty data or if they're an admin
    if (req.userId.toString() !== id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You can only view your own loyalty data.'
      });
    }

    const user = await User.findById(id).select('loyaltyTier loyaltyPoints totalTrips totalSpent earnedRewards availableRewards');
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    const plain = asPlain(user);
    res.json({
      success: true,
      data: {
        loyaltyTier: plain.loyaltyTier,
        loyaltyPoints: plain.loyaltyPoints,
        pointsToNextTier: user.pointsToNextTier,
        tierProgress: user.tierProgress,
        tierDiscount: user.tierDiscount,
        earnedRewards: plain.earnedRewards,
        availableRewards: plain.availableRewards,
        totalTrips: plain.totalTrips,
        totalSpent: plain.totalSpent
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/users/:id/rewards
// @desc    Get available and earned rewards for user
// @access  Private
router.get('/:id/rewards', async (req, res, next) => {
  try {
    const { id } = req.params;
    
    // Validate ObjectId format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid user ID format'
      });
    }

    // Check if user is requesting their own rewards or if they're an admin
    if (req.userId.toString() !== id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You can only view your own rewards.'
      });
    }

    const user = await User.findById(id).select('earnedRewards availableRewards loyaltyPoints loyaltyTier');
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const plain = asPlain(user);
    // Filter active rewards
    const activeEarnedRewards = plain.earnedRewards.filter(reward => reward.isActive);
    const activeAvailableRewards = plain.availableRewards.filter(reward => reward.isActive);
    
    res.json({
      success: true,
      data: {
        earnedRewards: activeEarnedRewards,
        availableRewards: activeAvailableRewards,
        loyaltyPoints: plain.loyaltyPoints,
        loyaltyTier: plain.loyaltyTier,
        totalEarnedRewards: activeEarnedRewards.length,
        totalAvailableRewards: activeAvailableRewards.length
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/users/:id/referrals
// @desc    Get referral tracking data for user
// @access  Private
router.get('/:id/referrals', async (req, res, next) => {
  try {
    const { id } = req.params;
    
    // Validate ObjectId format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid user ID format'
      });
    }

    // Check if user is requesting their own referrals or if they're an admin
    if (req.userId.toString() !== id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You can only view your own referrals.'
      });
    }

    const user = await User.findById(id).select('referralCode referrals referredBy');
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    const plain = asPlain(user);
    // Calculate referral stats
    const referralEarnings = plain.referrals.reduce((sum, ref) => sum + ref.earnings, 0);
    const successfulReferrals = plain.referrals.filter(ref => ref.status === 'completed').length;
    const pendingReferrals = plain.referrals.filter(ref => ref.status === 'pending').length;
    const cancelledReferrals = plain.referrals.filter(ref => ref.status === 'cancelled').length;

    res.json({
      success: true,
      data: {
        referralCode: plain.referralCode,
        referredBy: plain.referredBy,
        referrals: plain.referrals,
        stats: {
          totalReferrals: plain.referrals.length,
          successfulReferrals,
          pendingReferrals,
          cancelledReferrals,
          totalEarnings: referralEarnings
        }
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/users/:id/corporate
// @desc    Get corporate account details for user
// @access  Private
router.get('/:id/corporate', async (req, res, next) => {
  try {
    const { id } = req.params;
    
    // Validate ObjectId format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid user ID format'
      });
    }

    // Check if user is requesting their own corporate data or if they're an admin
    if (req.userId.toString() !== id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You can only view your own corporate account.'
      });
    }

    const user = await User.findById(id).select('corporateAccount');
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    const plain = asPlain(user);
    if (!plain.corporateAccount) {
      return res.status(404).json({
        success: false,
        message: 'No corporate account found for this user'
      });
    }

    res.json({
      success: true,
      data: {
        corporateAccount: plain.corporateAccount,
        isCorporateUser: true
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/users/:id/bulk-bookings
// @desc    Get corporate bulk bookings for user
// @access  Private
router.get('/:id/bulk-bookings', async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status, limit = 10, page = 1 } = req.query;
    
    // Validate ObjectId format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid user ID format'
      });
    }

    // Check if user is requesting their own bulk bookings or if they're an admin
    if (req.userId.toString() !== id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You can only view your own bulk bookings.'
      });
    }

    const user = await User.findById(id).select('bulkBookings corporateAccount');
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    const plain = asPlain(user);
    if (!plain.corporateAccount) {
      return res.status(404).json({
        success: false,
        message: 'No corporate account found for this user'
      });
    }

    // Ensure bulkBookings is always an array - multiple safety checks
    let bulkBookings = [];
    if (plain && plain.bulkBookings) {
      if (Array.isArray(plain.bulkBookings)) {
        bulkBookings = plain.bulkBookings;
      } else {
        console.warn('bulkBookings exists but is not an array:', typeof plain.bulkBookings);
      }
    }
    
    // Filter by status if provided
    if (status && Array.isArray(bulkBookings)) {
      bulkBookings = bulkBookings.filter(booking => booking && booking.status === status);
    }
    
    // Sort by creation date (newest first)
    if (Array.isArray(bulkBookings) && bulkBookings.length > 0) {
      bulkBookings.sort((a, b) => {
        const dateA = a && a.createdAt ? new Date(a.createdAt) : new Date(0);
        const dateB = b && b.createdAt ? new Date(b.createdAt) : new Date(0);
        return dateB - dateA;
      });
    }
    
    // Pagination
    const startIndex = (page - 1) * limit;
    const endIndex = startIndex + parseInt(limit);
    const paginatedBookings = Array.isArray(bulkBookings) ? bulkBookings.slice(startIndex, endIndex) : [];
    
    // Calculate totals
    const totalAmount = Array.isArray(bulkBookings) ? bulkBookings.reduce((sum, booking) => sum + ((booking && booking.totalAmount) || 0), 0) : 0;
    const totalDiscount = Array.isArray(bulkBookings) ? bulkBookings.reduce((sum, booking) => sum + ((booking && booking.discountAmount) || 0), 0) : 0;

    res.json({
      success: true,
      data: {
        bulkBookings: paginatedBookings,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(bulkBookings.length / limit),
          totalBookings: bulkBookings.length,
          hasNextPage: endIndex < bulkBookings.length,
          hasPrevPage: page > 1
        },
        summary: {
          totalAmount,
          totalDiscount,
          totalBookings: bulkBookings.length,
          statusCounts: {
            draft: bulkBookings.filter(b => b.status === 'draft').length,
            pending: bulkBookings.filter(b => b.status === 'pending').length,
            confirmed: bulkBookings.filter(b => b.status === 'confirmed').length,
            completed: bulkBookings.filter(b => b.status === 'completed').length,
            cancelled: bulkBookings.filter(b => b.status === 'cancelled').length
          }
        }
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/users/:id/bulk-bookings/:bookingId
// @desc    Get a single bulk booking by ID
// @access  Private
router.get('/:id/bulk-bookings/:bookingId', async (req, res, next) => {
  try {
    const { id, bookingId } = req.params;
    
    // Validate ObjectId formats
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid user ID format'
      });
    }

    if (!mongoose.Types.ObjectId.isValid(bookingId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid booking ID format'
      });
    }

    // Check authorization
    if (req.userId.toString() !== id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You can only view your own bulk bookings.'
      });
    }

    const user = await User.findById(id).select('bulkBookings corporateAccount');
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const plain = asPlain(user);
    if (!plain.corporateAccount) {
      return res.status(404).json({
        success: false,
        message: 'No corporate account found for this user'
      });
    }

    // Find the specific booking
    const booking = plain.bulkBookings.find(b => b.id === bookingId || b._id?.toString() === bookingId);
    
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Bulk booking not found'
      });
    }

    res.json({
      success: true,
      data: {
        booking
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   POST /api/users/:id/bulk-bookings
// @desc    Create a new bulk booking (corporate users only)
// @access  Private
router.post('/:id/bulk-bookings', async (req, res, next) => {
  try {
    const { id } = req.params;
    const { title, description, items, scheduledDate, specialNotes } = req.body;
    
    // Validate ObjectId format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid user ID format'
      });
    }

    // Check authorization
    if (req.userId.toString() !== id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You can only create bookings for your own account.'
      });
    }

    // Validate required fields
    if (!title || !description || !items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Title, description, and at least one item are required'
      });
    }

    // Validate each item
    for (const item of items) {
      if (!item.vehicleName || !item.quantity || !item.unitPrice || 
          !item.pickupLocation || !item.dropoffLocation || 
          !item.pickupTime || !item.passengerCount) {
        return res.status(400).json({
          success: false,
          message: 'Each item must have vehicleName, quantity, unitPrice, pickupLocation, dropoffLocation, pickupTime, and passengerCount'
        });
      }

      if (item.quantity < 1) {
        return res.status(400).json({
          success: false,
          message: 'Quantity must be at least 1'
        });
      }

      if (item.unitPrice < 0) {
        return res.status(400).json({
          success: false,
          message: 'Unit price cannot be negative'
        });
      }

      if (item.passengerCount < 1) {
        return res.status(400).json({
          success: false,
          message: 'Passenger count must be at least 1'
        });
      }
    }

    const user = await User.findById(id);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    if (!user.corporateAccount) {
      return res.status(403).json({
        success: false,
        message: 'Corporate account required to create bulk bookings'
      });
    }

    // Calculate total amount
    const totalAmount = items.reduce((sum, item) => {
      return sum + (item.quantity * item.unitPrice);
    }, 0);

    // Apply corporate discount
    const discountPercentage = user.corporateAccount.discountPercentage || 0;
    const discountAmount = totalAmount * (discountPercentage / 100);
    const finalAmount = totalAmount - discountAmount;

    // Check budget if applicable
    if (user.corporateAccount.monthlyBudget > 0) {
      const remainingBudget = user.corporateAccount.monthlyBudget - user.corporateAccount.usedBudget;
      if (finalAmount > remainingBudget) {
        return res.status(400).json({
          success: false,
          message: `Insufficient budget. Required: R${finalAmount.toFixed(2)}, Available: R${remainingBudget.toFixed(2)}`
        });
      }
    }

    // Create booking items with generated vehicle IDs (in real app, these would be actual vehicle IDs)
    const bookingItems = items.map(item => ({
      vehicleId: item.vehicleId || new mongoose.Types.ObjectId(), // Use provided or generate new
      vehicleName: item.vehicleName.trim(),
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      pickupLocation: item.pickupLocation.trim(),
      dropoffLocation: item.dropoffLocation.trim(),
      pickupTime: new Date(item.pickupTime),
      passengerCount: item.passengerCount
    }));

    // Create new bulk booking
    const newBooking = {
      title: title.trim(),
      description: description.trim(),
      items: bookingItems,
      status: 'draft',
      totalAmount,
      discountAmount,
      scheduledDate: scheduledDate ? new Date(scheduledDate) : undefined,
      specialNotes: specialNotes?.trim() || undefined
    };

    user.bulkBookings.push(newBooking);
    await user.save();

    // Get the newly created booking (it will have an _id now)
    const createdBooking = user.bulkBookings[user.bulkBookings.length - 1];
    const plain = asPlain(createdBooking);

    res.status(201).json({
      success: true,
      message: 'Bulk booking created successfully',
      data: {
        booking: plain
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   PUT /api/users/:id/bulk-bookings/:bookingId
// @desc    Update an existing bulk booking
// @access  Private
router.put('/:id/bulk-bookings/:bookingId', async (req, res, next) => {
  try {
    const { id, bookingId } = req.params;
    const { title, description, items, scheduledDate, specialNotes, status } = req.body;
    
    // Validate ObjectId formats
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid user ID format'
      });
    }

    if (!mongoose.Types.ObjectId.isValid(bookingId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid booking ID format'
      });
    }

    // Check authorization
    if (req.userId.toString() !== id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You can only update your own bookings.'
      });
    }

    const user = await User.findById(id);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    if (!user.corporateAccount) {
      return res.status(403).json({
        success: false,
        message: 'Corporate account required'
      });
    }

    // Find the booking
    const bookingIndex = user.bulkBookings.findIndex(
      b => b._id.toString() === bookingId
    );

    if (bookingIndex === -1) {
      return res.status(404).json({
        success: false,
        message: 'Bulk booking not found'
      });
    }

    const booking = user.bulkBookings[bookingIndex];

    // Check if booking can be updated
    if (booking.status === 'completed' || booking.status === 'cancelled') {
      return res.status(400).json({
        success: false,
        message: `Cannot update ${booking.status} bookings`
      });
    }

    // Update fields
    if (title !== undefined) {
      booking.title = title.trim();
    }

    if (description !== undefined) {
      booking.description = description.trim();
    }

    if (scheduledDate !== undefined) {
      booking.scheduledDate = scheduledDate ? new Date(scheduledDate) : undefined;
    }

    if (specialNotes !== undefined) {
      booking.specialNotes = specialNotes?.trim() || undefined;
    }

    if (status !== undefined) {
      const validStatuses = ['draft', 'pending', 'confirmed', 'completed', 'cancelled'];
      if (!validStatuses.includes(status)) {
        return res.status(400).json({
          success: false,
          message: `Invalid status. Must be one of: ${validStatuses.join(', ')}`
        });
      }
      booking.status = status;
    }

    // Update items if provided
    if (items && Array.isArray(items)) {
      if (items.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'At least one item is required'
        });
      }

      // Validate items
      for (const item of items) {
        if (!item.vehicleName || !item.quantity || !item.unitPrice || 
            !item.pickupLocation || !item.dropoffLocation || 
            !item.pickupTime || !item.passengerCount) {
          return res.status(400).json({
            success: false,
            message: 'Each item must have all required fields'
          });
        }
      }

      // Recalculate total amount
      const totalAmount = items.reduce((sum, item) => {
        return sum + (item.quantity * item.unitPrice);
      }, 0);

      const discountPercentage = user.corporateAccount.discountPercentage || 0;
      const discountAmount = totalAmount * (discountPercentage / 100);

      booking.items = items.map(item => ({
        vehicleId: item.vehicleId || new mongoose.Types.ObjectId(),
        vehicleName: item.vehicleName.trim(),
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        pickupLocation: item.pickupLocation.trim(),
        dropoffLocation: item.dropoffLocation.trim(),
        pickupTime: new Date(item.pickupTime),
        passengerCount: item.passengerCount
      }));

      booking.totalAmount = totalAmount;
      booking.discountAmount = discountAmount;
    }

    await user.save();

    const plain = asPlain(booking);

    res.json({
      success: true,
      message: 'Bulk booking updated successfully',
      data: {
        booking: plain
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   PATCH /api/users/:id/bulk-bookings/:bookingId/cancel
// @desc    Cancel a bulk booking
// @access  Private
router.patch('/:id/bulk-bookings/:bookingId/cancel', async (req, res, next) => {
  try {
    const { id, bookingId } = req.params;
    
    // Validate ObjectId formats
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid user ID format'
      });
    }

    if (!mongoose.Types.ObjectId.isValid(bookingId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid booking ID format'
      });
    }

    // Check authorization
    if (req.userId.toString() !== id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You can only cancel your own bookings.'
      });
    }

    const user = await User.findById(id);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    if (!user.corporateAccount) {
      return res.status(403).json({
        success: false,
        message: 'Corporate account required'
      });
    }

    // Find the booking
    const booking = user.bulkBookings.find(
      b => b._id.toString() === bookingId
    );

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Bulk booking not found'
      });
    }

    // Check if booking can be cancelled
    if (booking.status === 'completed') {
      return res.status(400).json({
        success: false,
        message: 'Cannot cancel completed bookings'
      });
    }

    if (booking.status === 'cancelled') {
      return res.status(400).json({
        success: false,
        message: 'Booking is already cancelled'
      });
    }

    // Restore budget if booking was confirmed and payment was made
    if (booking.status === 'confirmed' && user.corporateAccount.usedBudget > 0) {
      const finalAmount = booking.totalAmount - booking.discountAmount;
      user.corporateAccount.usedBudget = Math.max(0, user.corporateAccount.usedBudget - finalAmount);
    }

    // Update booking status
    booking.status = 'cancelled';
    
    // Mark the bulkBookings array as modified to ensure Mongoose saves the nested change
    user.markModified('bulkBookings');
    
    await user.save();

    const plain = asPlain(booking);

    res.json({
      success: true,
      message: 'Bulk booking cancelled successfully',
      data: {
        booking: plain
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   DELETE /api/users/:id/bulk-bookings/:bookingId
// @desc    Delete a bulk booking (allows deletion of draft, pending, and cancelled bookings)
// @access  Private
router.delete('/:id/bulk-bookings/:bookingId', async (req, res, next) => {
  try {
    const { id, bookingId } = req.params;
    
    // Validate ObjectId formats
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid user ID format'
      });
    }

    if (!mongoose.Types.ObjectId.isValid(bookingId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid booking ID format'
      });
    }

    // Check authorization
    if (req.userId.toString() !== id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You can only delete your own bookings.'
      });
    }

    const user = await User.findById(id);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    if (!user.corporateAccount) {
      return res.status(403).json({
        success: false,
        message: 'Corporate account required'
      });
    }

    // Find the booking
    const bookingIndex = user.bulkBookings.findIndex(
      b => b._id.toString() === bookingId
    );

    if (bookingIndex === -1) {
      return res.status(404).json({
        success: false,
        message: 'Bulk booking not found'
      });
    }

    const booking = user.bulkBookings[bookingIndex];

    // Prevent deletion of confirmed and completed bookings
    // Allow deletion of: draft, pending, and cancelled
    if (booking.status === 'confirmed' || booking.status === 'completed') {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete ${booking.status} bookings. Please contact support.'
      });
    }

    // Restore budget if booking was confirmed and payment was made (shouldn't happen due to check above, but safety check)
    if (booking.status === 'confirmed' && user.corporateAccount.usedBudget > 0) {
      const finalAmount = booking.totalAmount - booking.discountAmount;
      user.corporateAccount.usedBudget = Math.max(0, user.corporateAccount.usedBudget - finalAmount);
    }

    // Remove the booking
    user.bulkBookings.splice(bookingIndex, 1);
    user.markModified('bulkBookings');
    await user.save();

    res.json({
      success: true,
      message: 'Bulk booking deleted successfully'
    });

  } catch (error) {
    next(error);
  }
});

module.exports = router;