const express = require('express');
const router = express.Router();
const Booking = require('../models/Booking');
const User = require('../models/User');
const Driver = require('../models/Driver');
const Quote = require('../models/Quote');
const { authenticateToken } = require('../middleware/auth');

// Helper function to populate driver information
const populateDriverInfo = async (booking) => {
  if (booking.driverId) {
    const driver = await Driver.findById(booking.driverId).populate('userId', 'name phoneNumber');
    if (driver) {
      booking.driverName = driver.userId?.name || '';
      booking.driverPhone = driver.userId?.phoneNumber || '';
      booking.driverPhotoUrl = driver.documents?.profilePhoto || '';
    }
  }
  return booking;
};

// Helper function to format booking response for frontend
const formatBookingResponse = (booking) => {
  const toLatLng = (loc) => {
    if (!loc || !loc.coordinates) return null;
    return {
      latitude: loc.coordinates.latitude,
      longitude: loc.coordinates.longitude
    };
  };

  return {
    id: booking._id,
    bookingId: booking.bookingId,
    userId: booking.userId?.toString?.() || booking.userId,
    vehicleId: booking.vehicleId?.toString?.() || booking.vehicleId,
    vehicleName: booking.vehicleName,
    driverId: booking.driverId?.toString?.() || booking.driverId || '',
    driverName: booking.driverName || '',
    driverPhone: booking.driverPhone || '',
    driverPhotoUrl: booking.driverPhotoUrl || '',
    pickupAddress: booking.pickupAddress,
    dropoffAddress: booking.dropoffAddress,
    pickupLocation: toLatLng(booking.pickupLocation),
    dropoffLocation: toLatLng(booking.dropoffLocation),
    pickupTime: booking.pickupTime,
    actualPickupTime: booking.actualPickupTime,
    actualDropoffTime: booking.actualDropoffTime,
    passengerCount: booking.passengerCount,
    basePrice: booking.pricing?.baseFare || 0,
    finalPrice: booking.pricing?.total || 0,
    specialNotes: booking.specialNotes,
    closeProtectionOfficer: booking.closeProtectionOfficer,
    status: booking.status,
    paymentStatus: booking.paymentStatus,
    paymentMethodId: booking.paymentMethodId,
    createdAt: booking.createdAt,
    updatedAt: booking.updatedAt,
    rating: booking.rating,
    review: booking.review,
    routeInfo: booking.routeInfo
  };
};

// Helper function to validate booking data
const validateBookingData = (req, res, next) => {
  const {
    pickupLocation,
    dropoffLocation,
    pickupAddress,
    dropoffAddress,
    vehicleId,
    vehicleName,
    vehicleType,
    serviceType,
    passengerCount,
    scheduledDate,
    pickupTime,
    pricing
  } = req.body;

  // Check pickup location (either structured or address)
  if (!pickupLocation && !pickupAddress) {
    return res.status(400).json({
      success: false,
      message: 'Pickup location or address is required'
    });
  }

  if (pickupLocation && (!pickupLocation.address || !pickupLocation.coordinates)) {
    return res.status(400).json({
      success: false,
      message: 'Pickup location must include address and coordinates'
    });
  }

  // Check dropoff location (either structured or address)
  if (!dropoffLocation && !dropoffAddress) {
    return res.status(400).json({
      success: false,
      message: 'Dropoff location or address is required'
    });
  }

  if (dropoffLocation && (!dropoffLocation.address || !dropoffLocation.coordinates)) {
    return res.status(400).json({
      success: false,
      message: 'Dropoff location must include address and coordinates'
    });
  }

  if (!vehicleId || !vehicleName || !vehicleType || !serviceType || !passengerCount || (!scheduledDate && !pickupTime)) {
    return res.status(400).json({
      success: false,
      message: 'Missing required fields: vehicleId, vehicleName, vehicleType, serviceType, passengerCount, scheduledDate/pickupTime'
    });
  }

  // Check pricing
  if (!pricing || !pricing.total) {
    return res.status(400).json({
      success: false,
      message: 'Pricing information is required'
    });
  }

  if (pricing.total <= 0) {
    return res.status(400).json({
      success: false,
      message: 'Total price must be greater than 0'
    });
  }

  next();
};

// Helper function to check if user can access booking
const checkBookingAccess = async (req, res, next) => {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    // Check if user owns the booking or is admin
    if (booking.userId.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You can only access your own bookings.'
      });
    }

    req.booking = booking;
    next();
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error checking booking access',
      error: error.message
    });
  }
};

/**
 * @swagger
 * /api/bookings:
 *   post:
 *     summary: Create a new booking
 *     tags: [Bookings]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - pickupLocation
 *               - dropoffLocation
 *               - vehicleId
 *               - vehicleName
 *               - vehicleType
 *               - serviceType
 *               - passengerCount
 *               - scheduledDate
 *               - basePrice
 *               - finalPrice
 *             properties:
 *               pickupLocation:
 *                 type: object
 *                 properties:
 *                   address:
 *                     type: string
 *                   coordinates:
 *                     type: object
 *                     properties:
 *                       lat:
 *                         type: number
 *                       lng:
 *                         type: number
 *               dropoffLocation:
 *                 type: object
 *                 properties:
 *                   address:
 *                     type: string
 *                   coordinates:
 *                     type: object
 *                     properties:
 *                       lat:
 *                         type: number
 *                       lng:
 *                         type: number
 *               vehicleId:
 *                 type: string
 *               vehicleName:
 *                 type: string
 *               vehicleType:
 *                 type: string
 *                 enum: [sedan, suv, van, luxury]
 *               serviceType:
 *                 type: string
 *               passengerCount:
 *                 type: number
 *               scheduledDate:
 *                 type: string
 *                 format: date-time
 *               basePrice:
 *                 type: number
 *               finalPrice:
 *                 type: number
 *               specialNotes:
 *                 type: string
 *               closeProtectionOfficer:
 *                 type: boolean
 *     responses:
 *       201:
 *         description: Booking created successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/Booking'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
router.post('/', authenticateToken, validateBookingData, async (req, res) => {
  try {
    const {
      pickupLocation,
      dropoffLocation,
      pickupAddress,
      dropoffAddress,
      waypoints,
      vehicleId,
      vehicleName,
      vehicleType,
      serviceType,
      passengerCount,
      luggageCount,
      pickupTime,
      scheduledDate,
      isFlexibleTime,
      flexibleWindow,
      basePrice,
      finalPrice,
      pricing,
      specialNotes,
      closeProtectionOfficer,
      customerNotes,
      paymentMethod,
      emergencyContact,
      quoteId
    } = req.body;

    // Validate scheduled date is in the future
    const scheduledDateTime = new Date(scheduledDate || pickupTime);
    if (scheduledDateTime <= new Date()) {
      return res.status(400).json({
        success: false,
        message: 'Scheduled date must be in the future'
      });
    }

    // Generate booking ID
    const timestamp = Date.now().toString(36).slice(-4);
    const random = Math.random().toString(36).substring(2, 6);
    const bookingId = `BK${timestamp}${random}`.toUpperCase();

    // Create booking data
    const bookingData = {
      bookingId,
      userId: req.user.id,
      vehicleId: vehicleId || '',
      vehicleName: vehicleName || '',
      pickupAddress: pickupAddress || pickupLocation?.address || '',
      dropoffAddress: dropoffAddress || dropoffLocation?.address || '',
      pickupLocation,
      dropoffLocation,
      waypoints: waypoints || [],
      vehicleType,
      serviceType,
      passengerCount,
      luggageCount: luggageCount || 0,
      pickupTime: scheduledDateTime,
      scheduledDate: scheduledDateTime,
      isFlexibleTime: isFlexibleTime || false,
      flexibleWindow: flexibleWindow || 15,
      basePrice: basePrice || pricing?.baseFare || 0,
      finalPrice: finalPrice || pricing?.total || 0,
      pricing,
      specialNotes: specialNotes || '',
      closeProtectionOfficer: closeProtectionOfficer || false,
      customerNotes: customerNotes || '',
      paymentMethod: paymentMethod || 'card',
      emergencyContact: emergencyContact || null,
      quoteId: quoteId || null
    };

    // Create the booking
    const booking = new Booking(bookingData);
    await booking.save();

    // Populate driver information if driver is assigned
    await populateDriverInfo(booking);

    // If quoteId provided, update quote status
    if (quoteId) {
      await Quote.findByIdAndUpdate(quoteId, { status: 'accepted' });
    }

    res.status(201).json({
      success: true,
      message: 'Booking created successfully',
      data: formatBookingResponse(booking)
    });

  } catch (error) {
    console.error('Error creating booking:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating booking',
      error: error.message
    });
  }
});

// GET /api/bookings/{id} - Retrieve specific booking details
router.get('/:id', authenticateToken, checkBookingAccess, async (req, res) => {
  try {
    // Populate driver information
    await populateDriverInfo(req.booking);

    res.json({
      success: true,
      data: formatBookingResponse(req.booking)
    });

  } catch (error) {
    console.error('Error retrieving booking:', error);
    res.status(500).json({
      success: false,
      message: 'Error retrieving booking',
      error: error.message
    });
  }
});

// PUT /api/bookings/{id} - Update booking status, driver assignment
router.put('/:id', authenticateToken, checkBookingAccess, async (req, res) => {
  try {
    const {
      status,
      driverId,
      specialNotes,
      customerNotes,
      paymentMethod,
      emergencyContact,
      closeProtectionOfficer
    } = req.body;

    const allowedUpdates = {};
    
    // Only allow certain fields to be updated
    if (specialNotes !== undefined) allowedUpdates.specialNotes = specialNotes;
    if (customerNotes !== undefined) allowedUpdates.customerNotes = customerNotes;
    if (paymentMethod !== undefined) allowedUpdates.paymentMethod = paymentMethod;
    if (emergencyContact !== undefined) allowedUpdates.emergencyContact = emergencyContact;
    if (closeProtectionOfficer !== undefined) allowedUpdates.closeProtectionOfficer = closeProtectionOfficer;

    // Update booking
    Object.assign(req.booking, allowedUpdates);
    await req.booking.save();

    // If status is being updated, use the updateStatus method
    if (status && status !== req.booking.status) {
      await req.booking.updateStatus(status, 'user');
    }

    // If driver is being assigned
    if (driverId && driverId !== req.booking.driverId?.toString()) {
      await req.booking.assignDriver(driverId);
    }

    // Populate driver information
    await populateDriverInfo(req.booking);

    res.json({
      success: true,
      message: 'Booking updated successfully',
      data: formatBookingResponse(req.booking)
    });

  } catch (error) {
    console.error('Error updating booking:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating booking',
      error: error.message
    });
  }
});

// DELETE /api/bookings/{id} - Cancel existing booking
router.delete('/:id', authenticateToken, checkBookingAccess, async (req, res) => {
  try {
    const { reason } = req.body;

    // Check if booking can be cancelled
    const cancellableStatuses = ['pending', 'confirmed', 'driverAssigned'];
    if (!cancellableStatuses.includes(req.booking.status)) {
      return res.status(400).json({
        success: false,
        message: `Booking cannot be cancelled. Current status: ${req.booking.status}`
      });
    }

    // Calculate cancellation fee based on timing
    const now = new Date();
    const scheduledTime = new Date(req.booking.scheduledDate);
    const timeDifference = scheduledTime - now;
    const hoursUntilTrip = timeDifference / (1000 * 60 * 60);

    let cancellationFee = 0;
    if (hoursUntilTrip < 2) {
      cancellationFee = req.booking.pricing.total * 0.5; // 50% fee if less than 2 hours
    } else if (hoursUntilTrip < 24) {
      cancellationFee = req.booking.pricing.total * 0.25; // 25% fee if less than 24 hours
    }

    // Cancel the booking
    await req.booking.cancelBooking('user', reason || 'Cancelled by user', cancellationFee);

    // If driver was assigned, update driver status
    if (req.booking.driverId) {
      await Driver.findByIdAndUpdate(req.booking.driverId, {
        $unset: { currentBookingId: 1 },
        'availability.status': 'online'
      });
    }

    res.json({
      success: true,
      message: 'Booking cancelled successfully',
      data: {
        bookingId: req.booking.bookingId,
        cancellationFee,
        cancelledAt: req.booking.cancelledAt
      }
    });

  } catch (error) {
    console.error('Error cancelling booking:', error);
    res.status(500).json({
      success: false,
      message: 'Error cancelling booking',
      error: error.message
    });
  }
});

// GET /api/users/{userId}/bookings - List user's booking history
router.get('/user/:userId', authenticateToken, async (req, res) => {
  try {
    const { userId } = req.params;
    const { status, limit = 20, page = 1 } = req.query;

    // Check if user can access these bookings
    if (userId !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You can only access your own bookings.'
      });
    }

    const options = { limit: parseInt(limit), page: parseInt(page) };
    if (status) options.status = status;

    const bookings = await Booking.findUserBookings(userId, options);

    // Format bookings for frontend
    const formattedBookings = await Promise.all(
      bookings.map(async (booking) => {
        await populateDriverInfo(booking);
        return formatBookingResponse(booking);
      })
    );

    res.json({
      success: true,
      data: formattedBookings,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: formattedBookings.length
      }
    });

  } catch (error) {
    console.error('Error retrieving user bookings:', error);
    res.status(500).json({
      success: false,
      message: 'Error retrieving user bookings',
      error: error.message
    });
  }
});

// GET /api/users/{userId}/bookings/active - Current active trips
router.get('/user/:userId/active', authenticateToken, async (req, res) => {
  try {
    const { userId } = req.params;

    // Check if user can access these bookings
    if (userId !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You can only access your own bookings.'
      });
    }

    const activeBookings = await Booking.findUserBookings(userId, { active: true });

    // Format bookings for frontend
    const formattedBookings = await Promise.all(
      activeBookings.map(async (booking) => {
        await populateDriverInfo(booking);
        return formatBookingResponse(booking);
      })
    );

    res.json({
      success: true,
      data: formattedBookings
    });

  } catch (error) {
    console.error('Error retrieving active bookings:', error);
    res.status(500).json({
      success: false,
      message: 'Error retrieving active bookings',
      error: error.message
    });
  }
});

// POST /api/bookings/{id}/assign-driver - Assign available driver
router.post('/:id/assign-driver', authenticateToken, async (req, res) => {
  try {
    const { driverId } = req.body;

    if (!driverId) {
      return res.status(400).json({
        success: false,
        message: 'Driver ID is required'
      });
    }

    const booking = await Booking.findById(req.params.id);
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    // Check if booking can have driver assigned
    if (booking.status !== 'confirmed' && booking.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: `Cannot assign driver. Current status: ${booking.status}`
      });
    }

    // Check if driver exists and is available
    const driver = await Driver.findById(driverId);
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found'
      });
    }

    if (driver.status !== 'active') {
      return res.status(400).json({
        success: false,
        message: 'Driver is not active'
      });
    }

    if (driver.currentBookingId) {
      return res.status(400).json({
        success: false,
        message: 'Driver is already assigned to another booking'
      });
    }

    // Assign driver to booking
    await booking.assignDriver(driverId);

    // Update driver's current booking
    await Driver.findByIdAndUpdate(driverId, {
      currentBookingId: booking._id,
      'availability.status': 'busy'
    });

    // Populate driver information
    await populateDriverInfo(booking);

    res.json({
      success: true,
      message: 'Driver assigned successfully',
      data: formatBookingResponse(booking)
    });

  } catch (error) {
    console.error('Error assigning driver:', error);
    res.status(500).json({
      success: false,
      message: 'Error assigning driver',
      error: error.message
    });
  }
});

// PUT /api/bookings/{id}/status - Update booking status
router.put('/:id/status', authenticateToken, async (req, res) => {
  try {
    const { status, notes } = req.body;

    if (!status) {
      return res.status(400).json({
        success: false,
        message: 'Status is required'
      });
    }

    const booking = await Booking.findById(req.params.id);
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    // Determine who is updating the status
    let updatedBy = 'system';
    if (req.user.role === 'admin') {
      updatedBy = 'admin';
    } else if (booking.driverId && booking.driverId.toString() === req.user.id) {
      updatedBy = 'driver';
    } else if (booking.userId.toString() === req.user.id) {
      updatedBy = 'user';
    }

    // Update status
    await booking.updateStatus(status, updatedBy, notes);

    // Handle driver status updates
    if (booking.driverId) {
      const driver = await Driver.findById(booking.driverId);
      if (driver) {
        switch (status) {
          case 'completed':
            await Driver.findByIdAndUpdate(booking.driverId, {
              $unset: { currentBookingId: 1 },
              'availability.status': 'online'
            });
            break;
          case 'cancelled':
            await Driver.findByIdAndUpdate(booking.driverId, {
              $unset: { currentBookingId: 1 },
              'availability.status': 'online'
            });
            break;
        }
      }
    }

    // Handle referral rewards when booking is completed
    if (status === 'completed') {
      const user = await User.findById(booking.userId);
      
      // Increment total trips counter for the user
      if (user) {
        user.totalTrips += 1;
        await user.save();
      }
      
      if (user && user.referredBy) {
        // Get the referrer
        const referrer = await User.findById(user.referredBy);
        if (referrer) {
          // Check if this is the user's first completed booking
          const userCompletedBookings = await Booking.countDocuments({
            userId: user._id,
            status: 'completed'
          });

          if (userCompletedBookings === 1) {
            // First completed booking - give referrer extra bonus points
            const additionalReferrerPoints = Math.round(booking.pricing.total * 0.1); // 10% of booking cost as points
            const referrerBonusPoints = 500; // Additional bonus on first booking completion
            const totalExtraPoints = additionalReferrerPoints + referrerBonusPoints;

            // Reward the referrer with extra points (they already got 500 on signup)
            referrer.addLoyaltyPoints(totalExtraPoints, 'Referral bonus: First booking completed');
            
            // Update the pending referral to completed status
            const pendingReferral = referrer.referrals.find(r => 
              r.referredUserId.toString() === user._id.toString() && r.status === 'pending'
            );
            if (pendingReferral) {
              pendingReferral.status = 'completed';
              pendingReferral.earnings = 500 + totalExtraPoints; // Total points: 500 (signup) + extra (booking)
              pendingReferral.completedAt = new Date();
            }
            
            await referrer.save();
          }
        }
      }
    }

    // Populate driver information
    await populateDriverInfo(booking);

    res.json({
      success: true,
      message: 'Booking status updated successfully',
      data: formatBookingResponse(booking)
    });

  } catch (error) {
    console.error('Error updating booking status:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating booking status',
      error: error.message
    });
  }
});

// POST /api/bookings/{id}/rating - Submit trip rating and review
router.post('/:id/rating', authenticateToken, async (req, res) => {
  try {
    const { rating, review, categories } = req.body;

    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({
        success: false,
        message: 'Rating must be between 1 and 5'
      });
    }

    const booking = await Booking.findById(req.params.id);
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    // Check if user can rate this booking
    if (booking.userId.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'You can only rate your own bookings'
      });
    }

    // Check if booking is completed
    if (booking.status !== 'completed') {
      return res.status(400).json({
        success: false,
        message: 'You can only rate completed trips'
      });
    }

    // Check if already rated
    if (booking.rating) {
      return res.status(400).json({
        success: false,
        message: 'This booking has already been rated'
      });
    }

    // Add rating
    await booking.addRating(rating, review);

    // Update driver's performance metrics
    if (booking.driverId) {
      const driver = await Driver.findById(booking.driverId);
      if (driver) {
        await driver.updatePerformance({
          rating: rating,
          completed: true
        });
      }
    }

    // Update user's loyalty points
    const user = await User.findById(req.user.id);
    if (user) {
      const pointsEarned = Math.round(booking.pricing.total * 0.1); // 10% of trip cost as points
      user.addLoyaltyPoints(pointsEarned, 'Trip completed and rated');
      await user.save();
    }

    // Populate driver information
    await populateDriverInfo(booking);

    res.json({
      success: true,
      message: 'Rating submitted successfully',
      data: formatBookingResponse(booking)
    });

  } catch (error) {
    console.error('Error submitting rating:', error);
    res.status(500).json({
      success: false,
      message: 'Error submitting rating',
      error: error.message
    });
  }
});

// Additional utility endpoints

// GET /api/bookings/stats - Get booking statistics (admin only)
router.get('/stats', authenticateToken, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Admin role required.'
      });
    }

    const stats = await Booking.getBookingStats();
    const totalBookings = await Booking.countDocuments();
    const activeBookings = await Booking.countDocuments({
      status: { $in: ['confirmed', 'driverAssigned', 'driverEnRoute', 'driverArrived', 'inProgress'] }
    });

    res.json({
      success: true,
      data: {
        totalBookings,
        activeBookings,
        statusBreakdown: stats
      }
    });

  } catch (error) {
    console.error('Error retrieving booking stats:', error);
    res.status(500).json({
      success: false,
      message: 'Error retrieving booking stats',
      error: error.message
    });
  }
});

// GET /api/bookings/active - Get all active bookings (admin only)
router.get('/admin/active', authenticateToken, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Admin role required.'
      });
    }

    const activeBookings = await Booking.findActiveBookings();

    // Format bookings for frontend
    const formattedBookings = await Promise.all(
      activeBookings.map(async (booking) => {
        await populateDriverInfo(booking);
        return formatBookingResponse(booking);
      })
    );

    res.json({
      success: true,
      data: formattedBookings
    });

  } catch (error) {
    console.error('Error retrieving active bookings:', error);
    res.status(500).json({
      success: false,
      message: 'Error retrieving active bookings',
      error: error.message
    });
  }
});

module.exports = router;
