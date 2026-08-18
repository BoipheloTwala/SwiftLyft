const express = require('express');
const rateLimit = require('express-rate-limit');
const User = require('../models/User');
const { generateTokenPair, verifyRefreshToken } = require('../utils/jwt');
const { authenticateToken } = require('../middleware/auth');
const { sendEmailVerification, sendPhoneVerificationEmail, sendPasswordResetEmail } = require('../utils/email');

const router = express.Router();

// Rate limiting for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // limit each IP to 5 requests per windowMs
  message: {
    success: false,
    message: 'Too many authentication attempts, please try again later'
  },
  standardHeaders: true,
  legacyHeaders: false
});

// Validation helpers
const { sendResponse, errorResponses } = require('../middleware/validation');

const validateEmail = (email) => {
  const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
  return emailRegex.test(email);
};

const validatePassword = (password) => {
  // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
  const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$/;
  return passwordRegex.test(password);
};

/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     summary: Register a new user
 *     tags: [Authentication]
 *     security: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *                 example: user@example.com
 *               password:
 *                 type: string
 *                 minLength: 8
 *                 example: Password123
 *               name:
 *                 type: string
 *                 example: John Doe
 *               phoneNumber:
 *                 type: string
 *                 example: +27123456789
 *     responses:
 *       201:
 *         description: User registered successfully
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
 *                         tokens:
 *                           type: object
 *                           properties:
 *                             accessToken:
 *                               type: string
 *                             refreshToken:
 *                               type: string
 *                         emailSent:
 *                           type: boolean
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       429:
 *         description: Too many registration attempts
 */
router.post('/register', authLimiter, async (req, res, next) => {
  try {
    const { email, password, name, phoneNumber, phone, referralCode } = req.body;
    
    // Handle both phoneNumber and phone field names
    const userPhone = phoneNumber || phone;

    // Validation
    if (!email || !password) {
      return errorResponses.badRequest(res, 'Email and password are required');
    }

    if (!validateEmail(email)) {
      return errorResponses.badRequest(res, 'Please provide a valid email address');
    }

    if (!validatePassword(password)) {
      return errorResponses.badRequest(res, 'Password must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, and one number');
    }

    // Check if user already exists
    const existingUser = await User.findByEmail(email);
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'An account with this email already exists'
      });
    }

    // Process referral code if provided
    let referrer = null;
    if (referralCode) {
      referrer = await User.findByReferralCode(referralCode);
      if (!referrer) {
        return res.status(400).json({
          success: false,
          message: 'Invalid referral code'
        });
      }
      // Prevent self-referral
      if (referrer.email === email.toLowerCase()) {
        return res.status(400).json({
          success: false,
          message: 'You cannot use your own referral code'
        });
      }
    }

    // Extract corporate registration fields
    const { isCorporate, companyName, companyEmail, contactPerson, monthlyBudget } = req.body;

    // Create user
    const user = new User({
      email,
      password,
      name: name?.trim(),
      phoneNumber: userPhone?.trim(),
      referredBy: referrer?._id
    });

    // If corporate registration, add corporate account
    if (isCorporate) {
      user.corporateAccount = {
        companyName: companyName || name,
        companyEmail: companyEmail || email,
        contactPerson: contactPerson || name,
        contactPhone: userPhone || '',
        discountPercentage: 10, // Default 10% discount for new corporate accounts
        monthlyBudget: monthlyBudget || 50000, // Use provided budget or default to R50,000
        usedBudget: 0,
        status: 'active', // Start active for assignment demo purposes
        authorizedUsers: []
        // Note: createdAt is handled by schema default
      };
    }

    // Generate email verification token
    const crypto = require('crypto');
    const verificationToken = crypto.randomBytes(32).toString('hex');
    const verificationTokenHash = crypto.createHash('sha256').update(verificationToken).digest('hex');

    user.emailVerificationToken = verificationTokenHash;
    user.emailVerificationExpires = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

    // Initial save (may fail on rare referralCode collision)
    try {
      await user.save();
    } catch (err) {
      // Handle duplicate referralCode collision: regenerate and retry once
      if (err && err.code === 11000 && err.keyValue && err.keyValue.referralCode) {
        const crypto = require('crypto');
        const buildCode = () => `REF${crypto.randomBytes(3).toString('hex')}`.toUpperCase();
        let newCode = buildCode();
        for (let i = 0; i < 5; i += 1) {
          const exists = await User.findOne({ referralCode: newCode }).select('_id');
          if (!exists) break;
          newCode = buildCode();
        }
        user.referralCode = newCode;
        await user.save();
      } else {
        throw err;
      }
    }

    // Award referral bonuses immediately upon registration
    if (referrer) {
      // Reward the new user (referred user)
      const newUserBonus = 250;
      user.addLoyaltyPoints(newUserBonus, 'Referral signup bonus');
      await user.save();

      // Reward the referrer
      const referrerBonus = 500; // Base bonus for referring someone
      referrer.addLoyaltyPoints(referrerBonus, 'Referral bonus: New signup');
      
      // Add referral to referrer's list (status: pending until first booking)
      referrer.referrals.push({
        referredUserId: user._id,
        referredUserEmail: user.email,
        referredUserName: user.name,
        status: 'pending',
        earnings: referrerBonus,
        createdAt: new Date()
      });
      
      await referrer.save();
    }

    // Send verification email (non-blocking)
    const verificationUrl = `${req.protocol}://${req.get('host')}/api/auth/verify-email/${verificationToken}`;
    
    // Don't await email sending to prevent timeouts
    sendEmailVerification(user.email, verificationUrl)
      .then(emailResult => {
        if (!emailResult.success) {
          console.error('Failed to send verification email:', emailResult.error);
        }
      })
      .catch(error => {
        console.error('Email sending error:', error);
      });

    // Generate tokens
    const tokens = generateTokenPair(user._id);
    
    // Add refresh token to user
    user.addRefreshToken(tokens.refreshToken);
    await user.save();

    // Update login tracking
    user.lastLoginAt = new Date();
    user.loginCount += 1;
    await user.save();

    res.status(201).json({
      success: true,
      message: 'Account created successfully. Please check your email for verification.',
      data: {
        user: user.toJSON(),
        tokens,
        emailSent: true // Email sending is now asynchronous
      }
    });

  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/auth/login:
 *   post:
 *     summary: Login user
 *     tags: [Authentication]
 *     security: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *                 example: user@example.com
 *               password:
 *                 type: string
 *                 example: Password123
 *     responses:
 *       200:
 *         description: Login successful
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
 *                         tokens:
 *                           type: object
 *                           properties:
 *                             accessToken:
 *                               type: string
 *                             refreshToken:
 *                               type: string
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         description: Invalid credentials
 *       429:
 *         description: Too many login attempts
 */
router.post('/login', authLimiter, async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // Validation
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required'
      });
    }

    // Find user and include password for comparison
    const user = await User.findByEmail(email).select('+password');
    
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    // Check if account is active
    if (!user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Account has been deactivated'
      });
    }

    // Verify password
    const isPasswordValid = await user.comparePassword(password);
    
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    // Generate tokens
    const tokens = generateTokenPair(user._id);
    
    // Add refresh token to user
    user.addRefreshToken(tokens.refreshToken);

    // Update login tracking
    user.lastLoginAt = new Date();
    user.lastLoginIP = req.ip;
    user.loginCount += 1;
    
    await user.save();

    // Remove password from response
    user.password = undefined;

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        user: user.toJSON(),
        tokens
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   POST /api/auth/refresh-token
// @desc    Refresh access token
// @access  Public
router.post('/refresh-token', async (req, res, next) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(401).json({
        success: false,
        message: 'Refresh token is required'
      });
    }

    // Verify refresh token
    const decoded = verifyRefreshToken(refreshToken);
    
    // Find user and check if refresh token exists
    const user = await User.findById(decoded.userId);
    
    if (!user || !user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Invalid refresh token'
      });
    }

    // Check if refresh token exists in user's tokens
    const tokenExists = user.refreshTokens.some(rt => rt.token === refreshToken);
    
    if (!tokenExists) {
      return res.status(401).json({
        success: false,
        message: 'Invalid refresh token'
      });
    }

    // Generate new token pair
    const tokens = generateTokenPair(user._id);
    
    // Replace old refresh token with new one
    user.removeRefreshToken(refreshToken);
    user.addRefreshToken(tokens.refreshToken);
    
    await user.save();

    res.json({
      success: true,
      message: 'Token refreshed successfully',
      data: {
        tokens
      }
    });

  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Refresh token expired'
      });
    }
    next(error);
  }
});

// @route   POST /api/auth/logout
// @desc    Logout user
// @access  Private
router.post('/logout', authenticateToken, async (req, res, next) => {
  try {
    const { refreshToken } = req.body;

    // Get user with refresh tokens (middleware excludes them)
    const user = await User.findById(req.userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    if (refreshToken) {
      // Remove specific refresh token
      user.removeRefreshToken(refreshToken);
    } else {
      // Remove all refresh tokens (logout from all devices)
      user.refreshTokens = [];
    }

    await user.save();

    res.json({
      success: true,
      message: 'Logged out successfully'
    });

  } catch (error) {
    next(error);
  }
});

// @route   POST /api/auth/logout-all
// @desc    Logout from all devices
// @access  Private
router.post('/logout-all', authenticateToken, async (req, res, next) => {
  try {
    // Get user with refresh tokens (middleware excludes them)
    const user = await User.findById(req.userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Clear all refresh tokens
    user.refreshTokens = [];
    await user.save();

    res.json({
      success: true,
      message: 'Logged out from all devices successfully'
    });

  } catch (error) {
    next(error);
  }
});

// @route   POST /api/auth/forgot-password
// @desc    Send password reset email
// @access  Public
router.post('/forgot-password', authLimiter, async (req, res, next) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email is required'
      });
    }

    const user = await User.findByEmail(email);
    
    if (!user) {
      // Don't reveal if user exists or not
      return res.json({
        success: true,
        message: 'If an account with this email exists, a password reset link has been sent'
      });
    }

    // Generate reset token
    const crypto = require('crypto');
    const resetToken = crypto.randomBytes(32).toString('hex');
    const resetTokenHash = crypto.createHash('sha256').update(resetToken).digest('hex');

    // Set reset token and expiration (10 minutes)
    user.resetPasswordToken = resetTokenHash;
    user.resetPasswordExpires = new Date(Date.now() + 10 * 60 * 1000);
    
    await user.save();

    // Send password reset email
    const resetUrl = `${req.protocol}://${req.get('host')}/api/auth/reset-password/${resetToken}`;
    const emailResult = await sendPasswordResetEmail(user.email, resetUrl);

    if (!emailResult.success) {
      console.error('Failed to send password reset email:', emailResult.error);
    }

    res.json({
      success: true,
      message: 'If an account with this email exists, a password reset link has been sent'
    });

  } catch (error) {
    next(error);
  }
});

// @route   POST /api/auth/reset-password/:token
// @desc    Reset password
// @access  Public
router.post('/reset-password/:token', async (req, res, next) => {
  try {
    const { password } = req.body;
    const { token } = req.params;

    if (!password) {
      return res.status(400).json({
        success: false,
        message: 'Password is required'
      });
    }

    if (!validatePassword(password)) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, and one number'
      });
    }

    // Hash the token to compare with stored version
    const crypto = require('crypto');
    const resetTokenHash = crypto.createHash('sha256').update(token).digest('hex');

    // Find user with valid reset token
    const user = await User.findOne({
      resetPasswordToken: resetTokenHash,
      resetPasswordExpires: { $gt: Date.now() }
    });

    if (!user) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or expired reset token'
      });
    }

    // Set new password
    user.password = password;
    user.resetPasswordToken = undefined;
    user.resetPasswordExpires = undefined;
    
    // Clear all refresh tokens (logout from all devices)
    user.refreshTokens = [];

    await user.save();

    res.json({
      success: true,
      message: 'Password reset successful'
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/auth/me
// @desc    Get current user
// @access  Private
router.get('/me', authenticateToken, async (req, res) => {
  res.json({
    success: true,
    data: {
      user: req.user.toJSON()
    }
  });
});

// @route   POST /api/auth/change-password
// @desc    Change password
// @access  Private
router.post('/change-password', authenticateToken, async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Current password and new password are required'
      });
    }

    if (!validatePassword(newPassword)) {
      return res.status(400).json({
        success: false,
        message: 'New password must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, and one number'
      });
    }

    // Get user with password
    const user = await User.findById(req.userId).select('+password');
    
    // Verify current password
    const isCurrentPasswordValid = await user.comparePassword(currentPassword);
    
    if (!isCurrentPasswordValid) {
      return res.status(400).json({
        success: false,
        message: 'Current password is incorrect'
      });
    }

    // Set new password
    user.password = newPassword;
    
    // Clear all refresh tokens except current session
    // You might want to keep current session active
    user.refreshTokens = [];

    await user.save();

    res.json({
      success: true,
      message: 'Password changed successfully'
    });

  } catch (error) {
    next(error);
  }
});

// Email verification function (shared between GET and POST)
const verifyEmailToken = async (token) => {
  if (!token) {
    return {
      success: false,
      message: 'Verification token is required'
    };
  }

  // Hash the token to compare with stored version
  const crypto = require('crypto');
  const verificationTokenHash = crypto.createHash('sha256').update(token).digest('hex');

  // Find user with valid verification token
  const user = await User.findOne({
    emailVerificationToken: verificationTokenHash,
    emailVerificationExpires: { $gt: Date.now() }
  });

  if (!user) {
    return {
      success: false,
      message: 'Invalid or expired verification token'
    };
  }

  // Mark email as verified
  user.isEmailVerified = true;
  user.emailVerificationToken = undefined;
  user.emailVerificationExpires = undefined;
  
  await user.save();

  return {
    success: true,
    message: 'Email verified successfully',
    user: user.toJSON()
  };
};

// @route   GET /api/auth/verify-email/:token
// @desc    Verify email address (for email links)
// @access  Public
router.get('/verify-email/:token', async (req, res, next) => {
  try {
    const { token } = req.params;
    const result = await verifyEmailToken(token);

    if (result.success) {
      // Return a nice HTML page for successful verification
      const htmlResponse = `
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Email Verified - SwiftLyft</title>
          <style>
            body {
              font-family: Arial, sans-serif;
              max-width: 600px;
              margin: 50px auto;
              padding: 20px;
              text-align: center;
              background-color: #f8f9fa;
            }
            .container {
              background: white;
              padding: 40px;
              border-radius: 10px;
              box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            }
            .success-icon {
              font-size: 64px;
              color: #28a745;
              margin-bottom: 20px;
            }
            h1 {
              color: #007bff;
              margin-bottom: 10px;
            }
            .message {
              color: #666;
              font-size: 18px;
              margin-bottom: 30px;
            }
            .next-steps {
              background: #e3f2fd;
              padding: 20px;
              border-radius: 8px;
              border-left: 4px solid #007bff;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="success-icon">✅</div>
            <h1>🚗 SwiftLyft</h1>
            <h2>Email Verified Successfully!</h2>
            <p class="message">
              Your email address has been verified. You can now access all SwiftLyft features.
            </p>
            <div class="next-steps">
              <h3>What's Next?</h3>
              <p>You can now return to the SwiftLyft app and enjoy:</p>
              <ul style="text-align: left; display: inline-block;">
                <li>Book rides instantly</li>
                <li>Earn loyalty points</li>
                <li>Save favorite addresses</li>
                <li>Access exclusive rewards</li>
              </ul>
            </div>
          </div>
        </body>
        </html>
      `;
      
      res.send(htmlResponse);
    } else {
      // Return error HTML page
      const errorHtml = `
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Verification Failed - SwiftLyft</title>
          <style>
            body {
              font-family: Arial, sans-serif;
              max-width: 600px;
              margin: 50px auto;
              padding: 20px;
              text-align: center;
              background-color: #f8f9fa;
            }
            .container {
              background: white;
              padding: 40px;
              border-radius: 10px;
              box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            }
            .error-icon {
              font-size: 64px;
              color: #dc3545;
              margin-bottom: 20px;
            }
            h1 {
              color: #007bff;
              margin-bottom: 10px;
            }
            .message {
              color: #666;
              font-size: 18px;
              margin-bottom: 30px;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="error-icon">❌</div>
            <h1>🚗 SwiftLyft</h1>
            <h2>Verification Failed</h2>
            <p class="message">${result.message}</p>
            <p>Please try requesting a new verification email or contact support.</p>
          </div>
        </body>
        </html>
      `;
      
      res.status(400).send(errorHtml);
    }

  } catch (error) {
    next(error);
  }
});

// @route   POST /api/auth/verify-email/:token
// @desc    Verify email address (for API calls)
// @access  Public
router.post('/verify-email/:token', async (req, res, next) => {
  try {
    const { token } = req.params;
    const result = await verifyEmailToken(token);

    if (result.success) {
      res.json({
        success: true,
        message: result.message,
        data: {
          user: result.user
        }
      });
    } else {
      res.status(400).json({
        success: false,
        message: result.message
      });
    }

  } catch (error) {
    next(error);
  }
});

// @route   POST /api/auth/resend-verification
// @desc    Resend email verification
// @access  Public
router.post('/resend-verification', authLimiter, async (req, res, next) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email is required'
      });
    }

    if (!validateEmail(email)) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a valid email address'
      });
    }

    const user = await User.findByEmail(email);
    
    if (!user) {
      // Don't reveal if user exists or not
      return res.json({
        success: true,
        message: 'If an account with this email exists and is unverified, a verification email has been sent'
      });
    }

    if (user.isEmailVerified) {
      return res.json({
        success: true,
        message: 'Email is already verified'
      });
    }

    // Generate verification token
    const crypto = require('crypto');
    const verificationToken = crypto.randomBytes(32).toString('hex');
    const verificationTokenHash = crypto.createHash('sha256').update(verificationToken).digest('hex');

    // Set verification token and expiration (24 hours)
    user.emailVerificationToken = verificationTokenHash;
    user.emailVerificationExpires = new Date(Date.now() + 24 * 60 * 60 * 1000);
    
    await user.save();

    // Send verification email
    const verificationUrl = `${req.protocol}://${req.get('host')}/api/auth/verify-email/${verificationToken}`;
    const emailResult = await sendEmailVerification(user.email, verificationUrl);

    if (!emailResult.success) {
      console.error('Failed to send verification email:', emailResult.error);
    }

    res.json({
      success: true,
      message: 'If an account with this email exists and is unverified, a verification email has been sent'
    });

  } catch (error) {
    next(error);
  }
});

// @route   POST /api/auth/send-phone-verification
// @desc    Send phone verification code via EMAIL
// @access  Private
router.post('/send-phone-verification', authenticateToken, authLimiter, async (req, res, next) => {
  try {
    const { phoneNumber } = req.body;

    if (!phoneNumber) {
      return res.status(400).json({
        success: false,
        message: 'Phone number is required'
      });
    }

    // Validate phone number format
    const phoneRegex = /^\+?[1-9]\d{1,14}$/;
    if (!phoneRegex.test(phoneNumber)) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a valid phone number'
      });
    }

    // Generate verification code
    const crypto = require('crypto');
    const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
    const codeHash = crypto.createHash('sha256').update(`${req.userId}-${phoneNumber}-${verificationCode}`).digest('hex');

    // Get user
    const user = await User.findById(req.userId);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Store verification data in user document
    user.phoneVerificationCode = codeHash;
    user.phoneVerificationExpires = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes
    user.phoneVerificationAttempts = 0;
    user.pendingPhoneNumber = phoneNumber;
    
    await user.save();

    // Send verification code via email
    const emailResult = await sendPhoneVerificationEmail(user.email, phoneNumber, verificationCode);
    
    if (!emailResult.success) {
      return res.status(500).json({
        success: false,
        message: 'Failed to send verification code'
      });
    }

    res.json({
      success: true,
      message: 'Verification code sent to your email address',
      data: {
        sentTo: user.email,
        expiresIn: '15 minutes'
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   POST /api/auth/verify-phone
// @desc    Verify phone number with email-sent code
// @access  Private
router.post('/verify-phone', authenticateToken, async (req, res, next) => {
  try {
    const { verificationCode } = req.body;

    if (!verificationCode) {
      return res.status(400).json({
        success: false,
        message: 'Verification code is required'
      });
    }

    // Get user
    const user = await User.findById(req.userId);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Check if verification data exists
    if (!user.phoneVerificationCode || !user.pendingPhoneNumber) {
      return res.status(400).json({
        success: false,
        message: 'No verification code found. Please request a new code.'
      });
    }

    // Check if code expired
    if (Date.now() > user.phoneVerificationExpires) {
      // Clean up expired data
      user.phoneVerificationCode = undefined;
      user.phoneVerificationExpires = undefined;
      user.phoneVerificationAttempts = undefined;
      user.pendingPhoneNumber = undefined;
      await user.save();
      
      return res.status(400).json({
        success: false,
        message: 'Verification code has expired'
      });
    }

    // Check attempts (prevent brute force)
    if (user.phoneVerificationAttempts >= 3) {
      // Clean up after too many attempts
      user.phoneVerificationCode = undefined;
      user.phoneVerificationExpires = undefined;
      user.phoneVerificationAttempts = undefined;
      user.pendingPhoneNumber = undefined;
      await user.save();
      
      return res.status(400).json({
        success: false,
        message: 'Too many failed attempts. Please request a new code.'
      });
    }

    // Verify code
    const crypto = require('crypto');
    const codeHash = crypto.createHash('sha256').update(`${req.userId}-${user.pendingPhoneNumber}-${verificationCode}`).digest('hex');
    
    if (user.phoneVerificationCode !== codeHash) {
      user.phoneVerificationAttempts = (user.phoneVerificationAttempts || 0) + 1;
      await user.save();
      
      return res.status(400).json({
        success: false,
        message: 'Invalid verification code'
      });
    }

    // Code is valid - update user
    user.phoneNumber = user.pendingPhoneNumber;
    user.isPhoneVerified = true;
    
    // Clean up verification data
    user.phoneVerificationCode = undefined;
    user.phoneVerificationExpires = undefined;
    user.phoneVerificationAttempts = undefined;
    user.pendingPhoneNumber = undefined;
    
    await user.save();

    res.json({
      success: true,
      message: 'Phone number verified successfully',
      data: {
        user: user.toJSON()
      }
    });

  } catch (error) {
    next(error);
  }
});

module.exports = router;