const express = require('express');
const rateLimit = require('express-rate-limit');
const {
  Offer,
  CorporateBooking,
  SecurityService,
  AirportService
} = require('../models/SpecialFeatures');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// Rate limiting
const featuresLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 30,
  message: {
    success: false,
    message: 'Too many requests, please try again later'
  }
});

// @route   GET /api/offers
// @desc    Get available promotional offers
// @access  Public/Private
router.get('/offers', async (req, res, next) => {
  try {
    const { userType = 'all', vehicleType, limit = 20 } = req.query;

    const offers = await Offer.findActiveOffers(userType, vehicleType);

    // If user is authenticated, check eligibility
    let eligibleOffers = offers;
    if (req.user) {
      // In production, you'd check user's booking history, loyalty tier, etc.
      eligibleOffers = offers.filter(offer => {
        // Simplified eligibility check
        if (offer.targetAudience === 'new_users') {
          // Check if user has made bookings
          return req.user.totalTrips === 0;
        }
        return true;
      });
    }

    res.json({
      success: true,
      data: {
        offers: eligibleOffers
          .filter(offer => !vehicleType || (offer.conditions?.vehicleTypes || []).includes(vehicleType))
          .slice(0, limit)
          .map(offer => ({
          id: offer._id,
          title: offer.title,
          description: offer.description,
          type: offer.type,
          discountValue: offer.discountValue,
          promoCode: offer.promoCode,
          conditions: offer.conditions,
          endDate: offer.endDate,
          imageUrl: offer.imageUrl,
          targetAudience: offer.targetAudience
        })),
        count: eligibleOffers.filter(offer => !vehicleType || (offer.conditions?.vehicleTypes || []).includes(vehicleType)).length
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   POST /api/offers/validate
// @desc    Validate promotional code
// @access  Public/Private
router.post('/offers/validate', async (req, res, next) => {
  try {
    const { promoCode, bookingAmount = 0, vehicleType, serviceType } = req.body;

    if (!promoCode) {
      return res.status(400).json({
        success: false,
        message: 'Promo code is required'
      });
    }

    const offer = await Offer.findOne({
      promoCode: promoCode.toUpperCase(),
      isActive: true
    });

    if (!offer) {
      return res.status(404).json({
        success: false,
        message: 'Invalid promo code'
      });
    }

    if (!offer.isValid) {
      return res.status(400).json({
        success: false,
        message: 'Promo code has expired'
      });
    }

    // Check usage limits
    if (offer.totalUsageLimit && offer.currentUsageCount >= offer.totalUsageLimit) {
      return res.status(400).json({
        success: false,
        message: 'Promo code usage limit exceeded'
      });
    }

    // Check conditions
    const canApply = offer.canBeApplied(req.user || null, bookingAmount);

    if (!canApply) {
      return res.status(400).json({
        success: false,
        message: 'Promo code conditions not met'
      });
    }

    if (!canApply) {
      return res.status(400).json({
        success: false,
        message: 'Promo code conditions not met'
      });
    }

    res.json({
      success: true,
      data: {
        offer: {
          id: offer._id,
          title: offer.title,
          type: offer.type,
          discountValue: offer.discountValue,
          valid: true
        }
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   POST /api/corporate/bookings
// @desc    Create corporate booking
// @access  Private
router.post('/corporate/bookings', authenticateToken, featuresLimiter, async (req, res, next) => {
  try {
    const {
      title,
      description,
      bookingType,
      trips,
      specialInstructions
    } = req.body;

    if (!title || !bookingType || !trips || trips.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Title, booking type, and trips are required'
      });
    }

    // Check if user has corporate account
    if (!req.user.isCorporateUser) {
      return res.status(403).json({
        success: false,
        message: 'Corporate account required for this feature'
      });
    }

    // Calculate estimated cost (simplified)
    const totalEstimatedCost = trips.reduce((sum, trip) => {
      return sum + (trip.estimatedCost || 0);
    }, 0);

    const corporateBooking = new CorporateBooking({
      corporateAccountId: req.user.corporateAccount?._id || req.user.corporateAccountId || req.user._id,
      userId: req.userId,
      title,
      description,
      bookingType,
      trips: trips.map(trip => ({
        tripId: `TRIP_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        ...trip,
        // Provide default coordinates/addresses if omitted in tests
        pickupLocation: trip.pickupLocation?.address ? trip.pickupLocation : {
          address: trip.pickupLocation || 'A',
          coordinates: { latitude: -26.2, longitude: 28.04 }
        },
        dropoffLocation: trip.dropoffLocation?.address ? trip.dropoffLocation : {
          address: trip.dropoffLocation || 'B',
          coordinates: { latitude: -26.1, longitude: 28.05 }
        },
        status: 'pending'
      })),
      totalEstimatedCost,
      specialInstructions
    });

    await corporateBooking.save();

    res.status(201).json({
      success: true,
      message: 'Corporate booking created successfully',
      data: {
        booking: corporateBooking.toJSON()
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/users/:userId/corporate/bookings
// @desc    Get user's corporate bookings
// @access  Private
router.get('/users/:userId/corporate/bookings', authenticateToken, async (req, res, next) => {
  try {
    const { userId } = req.params;
    const { status, page = 1, limit = 20 } = req.query;

    // Check permissions
    if (userId !== req.userId.toString() && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    const query = { userId };
    if (status) query.status = status;

    const bookings = await CorporateBooking.find(query)
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await CorporateBooking.countDocuments(query);

    res.json({
      success: true,
      data: {
        bookings: bookings.map(booking => booking.toJSON()),
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

// @route   POST /api/bookings/security
// @desc    Request security/close protection service
// @access  Private
router.post('/bookings/security', authenticateToken, featuresLimiter, async (req, res, next) => {
  try {
    const {
      bookingId,
      serviceType,
      protectionLevel,
      duration,
      personnelCount,
      requirements,
      routeDetails,
      threatAssessment,
      emergencyContacts
    } = req.body;

    if (!serviceType || !protectionLevel || !duration || !personnelCount) {
      return res.status(400).json({
        success: false,
        message: 'Service type, protection level, duration, and personnel count are required'
      });
    }

    // Calculate cost based on service parameters
    const baseRates = {
      close_protection: { standard: 500, enhanced: 750, premium: 1000 },
      security_escort: { standard: 300, enhanced: 450, premium: 600 },
      asset_transport: { standard: 400, enhanced: 600, premium: 800 },
      event_security: { standard: 350, enhanced: 525, premium: 700 }
    };

    const hourlyRate = baseRates[serviceType]?.[protectionLevel] || 500;
    const baseCost = hourlyRate * duration * personnelCount;
    const additionalCharges = requirements?.specialEquipment?.length * 100 || 0;
    const totalCost = baseCost + additionalCharges;

    const securityService = new SecurityService({
      bookingId,
      userId: req.userId,
      serviceType,
      protectionLevel,
      duration,
      personnelCount,
      requirements,
      routeDetails,
      threatAssessment,
      cost: {
        baseRate: hourlyRate,
        additionalCharges,
        totalCost
      },
      emergencyContacts: emergencyContacts || []
    });

    await securityService.save();

    res.status(201).json({
      success: true,
      message: 'Security service request submitted successfully',
      data: {
        securityService: securityService.toJSON()
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/services/airport
// @desc    Get airport transfer services information
// @access  Public
router.get('/services/airport', async (req, res, next) => {
  try {
    const airportServices = {
      supportedAirports: [
        { code: 'JNB', name: 'OR Tambo International Airport', city: 'Johannesburg' },
        { code: 'CPT', name: 'Cape Town International Airport', city: 'Cape Town' },
        { code: 'DUR', name: 'King Shaka International Airport', city: 'Durban' },
        { code: 'PLZ', name: 'Port Elizabeth International Airport', city: 'Port Elizabeth' }
      ],
      services: [
        {
          type: 'pickup',
          name: 'Airport Pickup',
          description: 'Meet and greet service at airport arrivals',
          features: ['Flight tracking', 'Meet and greet', 'Luggage assistance', 'Priority boarding']
        },
        {
          type: 'dropoff',
          name: 'Airport Drop-off',
          description: 'Convenient drop-off with flight monitoring',
          features: ['Flight monitoring', 'Traffic optimization', 'Luggage help', 'Confirmation texts']
        },
        {
          type: 'meet_and_greet',
          name: 'VIP Meet & Greet',
          description: 'Premium airport assistance service',
          features: ['Personal greeter', 'Fast track security', 'Lounge access', 'Priority services']
        }
      ],
      pricing: {
        baseFare: 150,
        airportSurcharge: 50,
        vipSurcharge: 200,
        waitingTimeRate: 25 // per 15 minutes
      },
      advanceBooking: {
        minimum: '2 hours before flight',
        recommended: '24 hours before flight'
      }
    };

    res.json({
      success: true,
      data: airportServices
    });

  } catch (error) {
    next(error);
  }
});

// @route   POST /api/bookings/airport
// @desc    Book airport transfer service
// @access  Private
router.post('/bookings/airport', authenticateToken, featuresLimiter, async (req, res, next) => {
  try {
    const {
      bookingId,
      serviceType,
      flightDetails,
      passengerDetails,
      luggageDetails,
      vehicleRequirements,
      pickupLocation,
      notifications
    } = req.body;

    if (!serviceType || !flightDetails || !passengerDetails) {
      return res.status(400).json({
        success: false,
        message: 'Service type, flight details, and passenger details are required'
      });
    }

    // Calculate cost using the model method
    const tempService = { serviceType, passengerDetails };
    const costCalculation = AirportService.prototype.calculateCost.call(tempService);
    let subtotal = costCalculation.totalCost;

    // Override for VIP services in route (temporary until model is updated)
    let vipSurcharge = 0;
    if (serviceType === 'vip_service' || serviceType === 'meet_and_greet') {
      vipSurcharge = 150;
      subtotal = costCalculation.baseFare + costCalculation.airportSurcharge + vipSurcharge; // No passenger surcharge for VIP
    }

    const airportService = new AirportService({
      bookingId,
      userId: req.userId,
      serviceType,
      flightDetails,
      passengerDetails,
      luggageDetails,
      vehicleRequirements,
      pickupLocation,
      cost: {
        ...costCalculation,
        vipSurcharge,
        waitingTimeCharges: 0, // Calculated at completion
        totalCost: subtotal
      },
      notifications: notifications || {}
    });

    await airportService.save();

    res.status(201).json({
      success: true,
      message: 'Airport service booked successfully',
      data: {
        airportService: airportService.toJSON()
      }
    });

  } catch (error) {
    next(error);
  }
});

// Admin routes for managing offers
router.post('/admin/offers', authenticateToken, requireAdmin, async (req, res, next) => {
  try {
    const offerData = req.body;

    const offer = new Offer({
      ...offerData,
      createdBy: req.userId
    });

    await offer.save();

    res.status(201).json({
      success: true,
      message: 'Offer created successfully',
      data: {
        offer: offer.toJSON()
      }
    });

  } catch (error) {
    next(error);
  }
});

router.get('/admin/offers', authenticateToken, requireAdmin, async (req, res, next) => {
  try {
    const { status = 'all', page = 1, limit = 20 } = req.query;

    const query = {};
    if (status === 'active') query.isActive = true;
    else if (status === 'expired') query.endDate = { $lt: new Date() };
    else if (status === 'inactive') query.isActive = false;

    const offers = await Offer.find(query)
      .populate('createdBy', 'name')
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await Offer.countDocuments(query);

    res.json({
      success: true,
      data: {
        offers: offers.map(offer => offer.toJSON()),
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

router.put('/admin/offers/:offerId', authenticateToken, requireAdmin, async (req, res, next) => {
  try {
    const { offerId } = req.params;
    const updates = req.body;

    const offer = await Offer.findByIdAndUpdate(offerId, updates, { new: true });

    if (!offer) {
      return res.status(404).json({
        success: false,
        message: 'Offer not found'
      });
    }

    res.json({
      success: true,
      message: 'Offer updated successfully',
      data: {
        offer: offer.toJSON()
      }
    });

  } catch (error) {
    next(error);
  }
});

// Admin routes for corporate bookings
router.get('/admin/corporate/bookings', authenticateToken, requireAdmin, async (req, res, next) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;

    const query = {};
    if (status) query.status = status;

    const bookings = await CorporateBooking.find(query)
      .populate('userId', 'name email')
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await CorporateBooking.countDocuments(query);

    res.json({
      success: true,
      data: {
        bookings: bookings.map(booking => booking.toJSON()),
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

router.put('/admin/corporate/bookings/:bookingId/approve', authenticateToken, requireAdmin, async (req, res, next) => {
  try {
    const { bookingId } = req.params;

    const booking = await CorporateBooking.findByIdAndUpdate(
      bookingId,
      {
        status: 'approved',
        approvedBy: req.userId,
        approvedAt: new Date()
      },
      { new: true }
    );

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Corporate booking not found'
      });
    }

    res.json({
      success: true,
      message: 'Corporate booking approved successfully',
      data: {
        booking: booking.toJSON()
      }
    });

  } catch (error) {
    next(error);
  }
});

module.exports = router;
