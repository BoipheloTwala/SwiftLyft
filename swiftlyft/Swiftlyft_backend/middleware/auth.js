const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Verify JWT token
const authenticateToken = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Access token required'
      });
    }

    // Verify token
    if (!process.env.JWT_SECRET) {
      return res.status(500).json({
        success: false,
        message: 'Server configuration error'
      });
    }
    
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Get user from database
    const user = await User.findById(decoded.userId).select('-password -refreshTokens');
    
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid token - user not found'
      });
    }

    if (!user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Account is deactivated'
      });
    }

    // Add user to request object
    req.user = user;
    req.userId = user._id;
    
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        message: 'Invalid token'
      });
    }
    
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Token expired'
      });
    }

    console.error('Auth middleware error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Optional authentication (doesn't fail if no token)
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    const token = authHeader && authHeader.split(' ')[1];

    if (token && process.env.JWT_SECRET) {
      try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const user = await User.findById(decoded.userId).select('-password -refreshTokens');
      
        if (user && user.isActive) {
          req.user = user;
          req.userId = user._id;
        }
      } catch (error) {
        // Ignore token errors in optional auth
      }
    }
    
    next();
  } catch (error) {
    // Ignore errors in optional auth
    next();
  }
};

// Admin only middleware
const requireAdmin = async (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    // Check if user has admin role (you'll need to add role field to User schema)
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Admin access required'
      });
    }

    next();
  } catch (error) {
    console.error('Admin middleware error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Corporate user middleware
const requireCorporateUser = async (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    if (!req.user.isCorporateUser) {
      return res.status(403).json({
        success: false,
        message: 'Corporate account required'
      });
    }

    next();
  } catch (error) {
    console.error('Corporate user middleware error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

module.exports = {
  authenticateToken,
  optionalAuth,
  requireAdmin,
  requireCorporateUser
};