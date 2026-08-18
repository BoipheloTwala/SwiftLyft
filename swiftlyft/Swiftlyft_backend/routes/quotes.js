const express = require('express');
const rateLimit = require('express-rate-limit');
const Quote = require('../models/Quote');
const { authenticateToken, requireAdmin } = require('../middleware/auth');
const { sendEmailVerification } = require('../utils/email');

const router = express.Router();

// Helpers to normalize quote shape for Flutter frontend
function asPlain(doc) {
  if (!doc) return doc;
  if (typeof doc.toJSON === 'function') return doc.toJSON();
  if (typeof doc.toObject === 'function') return doc.toObject({ virtuals: true });
  return doc;
}

function mapQuoteForFrontend(q) {
  const quote = asPlain(q) || {};
  
  // Handle estimatedPrice - it might be flattened to just a number or be a full object
  let estimatedPrice;
  if (typeof quote.estimatedPrice === 'number') {
    estimatedPrice = { total: quote.estimatedPrice };
  } else if (quote.estimatedPrice && typeof quote.estimatedPrice === 'object') {
    estimatedPrice = quote.estimatedPrice;
  } else {
    estimatedPrice = { total: 0 };
  }
  
  return {
    id: quote.id || quote._id,
    userId: quote.userId,
    pickupLocation: quote.pickupLocation?.address || '',
    dropoffLocation: quote.dropoffLocation?.address || '',
    vehicleType: quote.vehicleType,
    serviceType: quote.serviceType,
    dateTime: quote.scheduledDate,
    passengerCount: quote.passengerCount,
    specialNotes: quote.specialRequirements || undefined,
    closeProtectionOfficer: false, // field not tracked in quotes; default to false
    estimatedPrice: estimatedPrice,
    status: quote.status,
    createdAt: quote.createdAt,
    validUntil: quote.validUntil
  };
}

// Rate limiting for quote endpoints
const quoteLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: process.env.NODE_ENV === 'test' ? 100 : 10, // Higher limit for tests
  message: {
    success: false,
    message: 'Too many quote requests, please try again later'
  },
  standardHeaders: true,
  legacyHeaders: false
});

// Validation helpers
const validateQuoteData = (data) => {
  const errors = [];

  if (!data.pickupLocation?.coordinates?.latitude || !data.pickupLocation?.coordinates?.longitude) {
    errors.push('Pickup location coordinates are required');
  }

  if (!data.dropoffLocation?.coordinates?.latitude || !data.dropoffLocation?.coordinates?.longitude) {
    errors.push('Dropoff location coordinates are required');
  }

  if (!data.vehicleType || !['sedan', 'suv', 'luxury', 'van', 'truck', 'motorcycle'].includes(data.vehicleType)) {
    errors.push('Valid vehicle type is required');
  }

  if (!data.serviceType || !['standard', 'premium', 'corporate', 'airport', 'security'].includes(data.serviceType)) {
    errors.push('Valid service type is required');
  }

  if (!data.passengerCount || data.passengerCount < 1) {
    errors.push('Passenger count must be at least 1');
  }

  if (!data.scheduledDate || new Date(data.scheduledDate) <= new Date()) {
    errors.push('Scheduled date must be in the future');
  }

  return errors;
};

const calculatePricing = (distance, duration, vehicleType, serviceType, passengerCount) => {
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

// @route   POST /api/quotes
// @desc    Create new quote request
// @access  Private
router.post('/', authenticateToken, quoteLimiter, async (req, res, next) => {
  try {
    const {
      pickupLocation,
      dropoffLocation,
      pickupAddress,
      dropoffAddress,
      vehicleType,
      serviceType,
      passengerCount,
      luggageCount,
      specialRequirements,
      scheduledDate,
      dateTime
    } = req.body;

    // Validate input
    const incoming = { ...req.body };
    // Allow string addresses as alternative input for frontend
    if (pickupAddress && !incoming.pickupLocation) {
      incoming.pickupLocation = { address: pickupAddress };
    }
    if (dropoffAddress && !incoming.dropoffLocation) {
      incoming.dropoffLocation = { address: dropoffAddress };
    }
    if (dateTime && !incoming.scheduledDate) {
      incoming.scheduledDate = dateTime;
    }
    const validationErrors = validateQuoteData(incoming);
    if (validationErrors.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validationErrors
      });
    }

    // Calculate route details (simplified - in production use Google Maps API)
    const distance = Math.random() * 50 + 5; // Mock distance calculation
    const duration = distance * 2 + Math.random() * 20; // Mock duration

    // Calculate pricing
    const estimatedPrice = calculatePricing(distance, duration, vehicleType, serviceType, passengerCount);

    // Create quote
    const quote = new Quote({
      userId: req.userId,
      pickupLocation: incoming.pickupLocation || pickupLocation,
      dropoffLocation: incoming.dropoffLocation || dropoffLocation,
      vehicleType,
      serviceType,
      passengerCount,
      luggageCount: luggageCount || 0,
      specialRequirements,
      scheduledDate: new Date(incoming.scheduledDate || scheduledDate),
      estimatedDistance: Math.round(distance * 100) / 100,
      estimatedDuration: Math.round(duration),
      estimatedPrice,
      validUntil: new Date(Date.now() + 24 * 60 * 60 * 1000) // 24 hours
    });

    await quote.save();

    res.status(201).json({
      success: true,
      message: 'Quote request created successfully',
      data: {
        quote: mapQuoteForFrontend(quote)
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/quotes/:id
// @desc    Get quote details
// @access  Private
router.get('/:id', authenticateToken, async (req, res, next) => {
  try {
    const { id } = req.params;

    const quote = await Quote.findById(id);

    if (!quote) {
      return res.status(404).json({
        success: false,
        message: 'Quote not found'
      });
    }

    // Check if user owns this quote or is admin
    if (quote.userId.toString() !== req.userId.toString() && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    res.json({
      success: true,
      data: {
        quote: mapQuoteForFrontend(quote)
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   PUT /api/quotes/:id
// @desc    Update quote status
// @access  Private/Admin
router.put('/:id', authenticateToken, async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status, notes, internalNotes } = req.body;

    const quote = await Quote.findById(id);

    if (!quote) {
      return res.status(404).json({
        success: false,
        message: 'Quote not found'
      });
    }

    // Check permissions
    if (quote.userId.toString() !== req.userId.toString() && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Users can only update to 'cancelled', admins can update status
    if (quote.userId.toString() === req.userId.toString() && status !== 'cancelled') {
      return res.status(403).json({
        success: false,
        message: 'Users can only cancel quotes'
      });
    }

    // Validate status transition
    const validStatuses = ['pending', 'quoted', 'accepted', 'expired', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid status'
      });
    }

    // Update quote
    quote.status = status;
    if (notes) quote.notes = notes;
    if (internalNotes && req.user.role === 'admin') {
      quote.internalNotes = internalNotes;
    }

    await quote.save();

    res.json({
      success: true,
      message: 'Quote updated successfully',
      data: {
        quote: quote.toJSON()
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/users/:userId/quotes
// @desc    Get user's quote history
// @access  Private
router.get('/user/:userId', authenticateToken, async (req, res, next) => {
  try {
    const { userId } = req.params;
    const { status, page = 1, limit = 20 } = req.query;

    // Check permissions
    if (userId.toString() !== req.userId.toString() && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    const query = { userId };
    if (status) query.status = status;

    const quotes = await Quote.find(query)
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await Quote.countDocuments(query);

    res.json({
      success: true,
      data: {
        quotes: quotes.map(q => mapQuoteForFrontend(q)),
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   POST /api/quotes/estimate
// @desc    Calculate pricing estimate
// @access  Public
router.post('/estimate', async (req, res, next) => {
  try {
    const {
      pickupCoordinates,
      dropoffCoordinates,
      vehicleType,
      serviceType,
      passengerCount = 1
    } = req.body;

    if (!pickupCoordinates?.latitude || !pickupCoordinates?.longitude ||
        !dropoffCoordinates?.latitude || !dropoffCoordinates?.longitude) {
      return res.status(400).json({
        success: false,
        message: 'Pickup and dropoff coordinates are required'
      });
    }

    if (!vehicleType || !serviceType) {
      return res.status(400).json({
        success: false,
        message: 'Vehicle type and service type are required'
      });
    }

    // Mock distance calculation - in production, use Google Maps Distance Matrix API
    const distance = Math.random() * 50 + 5;
    const duration = distance * 2 + Math.random() * 20;

    const estimatedPrice = calculatePricing(distance, duration, vehicleType, serviceType, passengerCount);

    res.json({
      success: true,
      data: {
        distance: Math.round(distance * 100) / 100,
        duration: Math.round(duration),
        pricing: estimatedPrice,
        currency: 'ZAR',
        validFor: '24 hours'
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   DELETE /api/quotes/:id
// @desc    Delete quote (admin only)
// @access  Private/Admin
router.delete('/:id', authenticateToken, requireAdmin, async (req, res, next) => {
  try {
    const { id } = req.params;

    const quote = await Quote.findByIdAndDelete(id);

    if (!quote) {
      return res.status(404).json({
        success: false,
        message: 'Quote not found'
      });
    }

    res.json({
      success: true,
      message: 'Quote deleted successfully'
    });

  } catch (error) {
    next(error);
  }
});

module.exports = router;
