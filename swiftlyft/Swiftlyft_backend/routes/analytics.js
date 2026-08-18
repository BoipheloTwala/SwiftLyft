const express = require('express');
const rateLimit = require('express-rate-limit');
const {
  UserAnalytics,
  BookingAnalytics,
  RevenueAnalytics,
  DriverAnalytics
} = require('../models/Analytics');
const User = require('../models/User');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// Helpers to normalize shapes similar to users routes
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

// Rate limiting
const analyticsLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: {
    success: false,
    message: 'Too many analytics requests, please try again later'
  }
});

// @route   GET /api/analytics/users/:userId
// @desc    Get user analytics and behavior data
// @access  Private/Admin
/**
 * @swagger
 * /api/analytics/users/{userId}:
 *   get:
 *     summary: Get user analytics and behavior data
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: startDate
 *         schema:
 *           type: string
 *           format: date-time
 *       - in: query
 *         name: endDate
 *         schema:
 *           type: string
 *           format: date-time
 *     responses:
 *       200:
 *         description: Analytics for the specified user
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
 *                           type: object
 *                           properties:
 *                             id: { type: string }
 *                             name: { type: string }
 *                             email: { type: string }
 *                             memberSince: { type: string, format: date-time }
 *                             loyaltyTier: { type: string }
 *                             totalTrips: { type: integer }
 *                             totalSpent: { type: number }
 *                         analytics:
 *                           type: object
 *                           properties:
 *                             totalEvents: { type: integer }
 *                             uniqueEventTypes: { type: integer }
 *                             avgEventsPerDay: { type: number }
 *                             behaviorStats:
 *                               type: array
 *                               items:
 *                                 type: object
 *                                 properties:
 *                                   eventType: { type: string }
 *                                   count: { type: integer }
 *                                   lastEvent: { type: string, format: date-time }
 *                             recentEvents:
 *                               type: array
 *                               items:
 *                                 type: object
 *                                 properties:
 *                                   eventType: { type: string }
 *                                   timestamp: { type: string, format: date-time }
 *                                   deviceInfo: { type: object }
 *                                   location: { type: object }
 */
router.get('/users/:userId', authenticateToken, requireAdmin, async (req, res, next) => {
  try {
    const { userId } = req.params;
    const { startDate, endDate } = req.query;

    const userDoc = await User.findById(userId);
    if (!userDoc) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    const user = asPlain(userDoc);

    // Date range filter
    const range = {};
    if (startDate) range.$gte = new Date(startDate);
    if (endDate) range.$lte = new Date(endDate);
    const matchEventRange = Object.keys(range).length > 0 ? { timestamp: range } : {};

    // Get user analytics
    const userAnalytics = await UserAnalytics.find({
      userId,
      ...matchEventRange
    }).sort({ timestamp: -1 }).limit(100);

    // Aggregate user behavior
    const behaviorStats = await UserAnalytics.aggregate([
      {
        $match: {
          userId: user.id || user._id,
          ...matchEventRange
        }
      },
      {
        $group: {
          _id: '$eventType',
          count: { $sum: 1 },
          lastEvent: { $max: '$timestamp' }
        }
      },
      {
        $sort: { count: -1 }
      }
    ]);

    // Calculate user engagement metrics
    const totalEvents = behaviorStats.reduce((sum, stat) => sum + stat.count, 0);
    const uniqueEventTypes = behaviorStats.length;
    const avgEventsPerDay = totalEvents / 30; // Rough 30-day average

    res.json({
      success: true,
      data: {
        user: {
          id: user.id || user._id,
          name: user.name,
          email: user.email,
          memberSince: user.createdAt,
          loyaltyTier: user.loyaltyTier,
          totalTrips: user.totalTrips,
          totalSpent: user.totalSpent
        },
        analytics: {
          totalEvents,
          uniqueEventTypes,
          avgEventsPerDay,
          behaviorStats: behaviorStats.map(s => ({ eventType: s._id, count: s.count, lastEvent: s.lastEvent })),
          recentEvents: userAnalytics.slice(0, 10).map(event => ({
            eventType: event.eventType,
            timestamp: event.timestamp,
            deviceInfo: event.deviceInfo,
            location: event.location
          }))
        }
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/analytics/bookings
// @desc    Get booking performance metrics
// @access  Private/Admin
/**
 * @swagger
 * /api/analytics/bookings:
 *   get:
 *     summary: Get booking performance metrics
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: startDate
 *         schema: { type: string, format: date-time }
 *       - in: query
 *         name: endDate
 *         schema: { type: string, format: date-time }
 *     responses:
 *       200:
 *         description: Booking metrics summary, trends and breakdowns
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
 *                         summary:
 *                           type: object
 *                           properties:
 *                             totalBookings: { type: integer }
 *                             completedBookings: { type: integer }
 *                             cancelledBookings: { type: integer }
 *                             totalRevenue: { type: number }
 *                             averageBookingValue: { type: number }
 *                         trends:
 *                           type: array
 *                           items:
 *                             type: object
 *                             properties:
 *                               date: { type: string, format: date-time }
 *                               totalBookings: { type: integer }
 *                               completedBookings: { type: integer }
 *                               revenue: { type: number }
 *                         vehicleTypeBreakdown: { type: object }
 *                         peakHours:
 *                           type: array
 *                           items:
 *                             type: object
 *                             properties:
 *                               hour: { type: integer }
 *                               avgBookings: { type: number }
 *                         dateRange:
 *                           type: object
 *                           properties:
 *                             start: { type: string }
 *                             end: { type: string }
 */
router.get('/bookings', authenticateToken, requireAdmin, async (req, res, next) => {
  try {
    const { startDate, endDate } = req.query;

    const bRange = {};
    if (startDate) bRange.$gte = new Date(startDate);
    if (endDate) bRange.$lte = new Date(endDate);
    const matchFilter = Object.keys(bRange).length > 0 ? { date: bRange } : {};

    // Get booking summary
    const bookingSummary = await BookingAnalytics.getBookingsSummary(
      startDate ? new Date(startDate) : new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
      endDate ? new Date(endDate) : new Date()
    );

    // Get recent booking trends
    const recentTrends = await BookingAnalytics.find(matchFilter)
      .sort({ date: -1 })
      .limit(30);

    // Aggregate by vehicle type
    const vehicleTypeStats = await BookingAnalytics.aggregate([
      { $match: matchFilter },
      {
        $group: {
          _id: null,
          sedanBookings: { $sum: '$bookingsByVehicleType.sedan' },
          suvBookings: { $sum: '$bookingsByVehicleType.suv' },
          luxuryBookings: { $sum: '$bookingsByVehicleType.luxury' },
          vanBookings: { $sum: '$bookingsByVehicleType.van' },
          truckBookings: { $sum: '$bookingsByVehicleType.truck' },
          motorcycleBookings: { $sum: '$bookingsByVehicleType.motorcycle' }
        }
      }
    ]);

    // Peak hours analysis
    const peakHours = await BookingAnalytics.aggregate([
      { $match: matchFilter },
      { $unwind: '$peakHours' },
      {
        $group: {
          _id: '$peakHours.hour',
          avgBookings: { $avg: '$peakHours.bookingCount' }
        }
      },
      { $sort: { avgBookings: -1 } },
      { $limit: 5 }
    ]);

    res.json({
      success: true,
      data: {
        summary: bookingSummary[0] || {
          totalBookings: 0,
          completedBookings: 0,
          cancelledBookings: 0,
          totalRevenue: 0,
          averageBookingValue: 0
        },
        trends: recentTrends.map(trend => ({
          date: trend.date,
          totalBookings: trend.totalBookings,
          completedBookings: trend.completedBookings,
          revenue: trend.totalRevenue
        })),
        vehicleTypeBreakdown: vehicleTypeStats[0] || {},
        peakHours: peakHours.map(p => ({ hour: p._id, avgBookings: p.avgBookings })),
        dateRange: {
          start: startDate || new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
          end: endDate || new Date().toISOString().split('T')[0]
        }
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/analytics/revenue
// @desc    Get revenue and financial reporting
// @access  Private/Admin
/**
 * @swagger
 * /api/analytics/revenue:
 *   get:
 *     summary: Get revenue and financial reporting
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: startDate
 *         schema: { type: string, format: date-time }
 *       - in: query
 *         name: endDate
 *         schema: { type: string, format: date-time }
 *     responses:
 *       200:
 *         description: Revenue summary, trends, and payment method breakdowns
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
 *                         summary: { type: object }
 *                         trends:
 *                           type: array
 *                           items:
 *                             type: object
 *                             properties:
 *                               date: { type: string, format: date-time }
 *                               totalRevenue: { type: number }
 *                               netRevenue: { type: number }
 *                               refunds: { type: number }
 *                               commissions: { type: number }
 *                         paymentMethods:
 *                           type: object
 *                           properties:
 *                             cardRevenue: { type: number }
 *                             cashRevenue: { type: number }
 *                             walletRevenue: { type: number }
 *                             corporateRevenue: { type: number }
 *                         dateRange:
 *                           type: object
 *                           properties:
 *                             start: { type: string }
 *                             end: { type: string }
 */
router.get('/revenue', authenticateToken, requireAdmin, async (req, res, next) => {
  try {
    const { startDate, endDate } = req.query;

    // Get revenue summary
    const revenueSummary = await RevenueAnalytics.getRevenueSummary(
      startDate ? new Date(startDate) : new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
      endDate ? new Date(endDate) : new Date()
    );

    // Get revenue trends
    const dateFilter = {};
    if (startDate) dateFilter.$gte = new Date(startDate);
    if (endDate) dateFilter.$lte = new Date(endDate);

    const matchFilter = Object.keys(dateFilter).length > 0 ? { date: dateFilter } : {};

    const revenueTrends = await RevenueAnalytics.find(matchFilter)
      .sort({ date: -1 })
      .limit(30);

    // Payment method breakdown
    const paymentMethodStats = await RevenueAnalytics.aggregate([
      { $match: matchFilter },
      {
        $group: {
          _id: null,
          cardRevenue: { $sum: '$paymentMethods.card' },
          cashRevenue: { $sum: '$paymentMethods.cash' },
          walletRevenue: { $sum: '$paymentMethods.wallet' },
          corporateRevenue: { $sum: '$paymentMethods.corporate' }
        }
      }
    ]);

    res.json({
      success: true,
      data: {
        summary: revenueSummary[0] || {
          totalRevenue: 0,
          netRevenue: 0,
          refunds: 0,
          commissions: 0
        },
        trends: revenueTrends.map(trend => ({
          date: trend.date,
          totalRevenue: trend.totalRevenue,
          netRevenue: trend.totalRevenue - trend.refunds - trend.commissions - trend.driverPayouts - trend.platformFees,
          refunds: trend.refunds,
          commissions: trend.commissions
        })),
        paymentMethods: paymentMethodStats[0] || { cardRevenue: 0, cashRevenue: 0, walletRevenue: 0, corporateRevenue: 0 },
        dateRange: {
          start: startDate || new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
          end: endDate || new Date().toISOString().split('T')[0]
        }
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/analytics/drivers
// @desc    Get driver performance metrics
// @access  Private/Admin
/**
 * @swagger
 * /api/analytics/drivers:
 *   get:
 *     summary: Get driver performance metrics
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema: { type: integer }
 *       - in: query
 *         name: sortBy
 *         schema: { type: string }
 *     responses:
 *       200:
 *         description: Overall driver stats and top performers
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
 *                         overallStats: { type: object }
 *                         topPerformers:
 *                           type: array
 *                           items:
 *                             type: object
 *                             properties:
 *                               driverId: { type: string }
 *                               id: { type: string }
 *                               name: { type: string }
 *                               totalRides: { type: integer }
 *                               averageRating: { type: number }
 *                               totalEarnings: { type: number }
 *                               acceptanceRate: { type: number }
 */
router.get('/drivers', authenticateToken, requireAdmin, async (req, res, next) => {
  try {
    const { limit = 20, sortBy = 'totalRides' } = req.query;

    // Get top performers
    const topPerformers = await DriverAnalytics.getTopPerformers(parseInt(limit));

    // Get overall driver statistics
    const overallStats = await DriverAnalytics.aggregate([
      {
        $group: {
          _id: null,
          driverIds: { $addToSet: '$driverId' },
          avgRating: { $avg: '$averageRating' },
          totalRides: { $sum: '$totalRides' },
          totalEarnings: { $sum: '$totalEarnings' },
          avgAcceptanceRate: { $avg: '$acceptanceRate' },
          avgResponseTime: { $avg: '$averageResponseTime' }
        }
      },
      {
        $project: {
          totalDrivers: { $size: '$driverIds' },
          avgRating: { $round: ['$avgRating', 2] },
          totalRides: 1,
          totalEarnings: { $round: ['$totalEarnings', 2] },
          avgAcceptanceRate: { $round: ['$avgAcceptanceRate', 2] },
          avgResponseTime: { $round: ['$avgResponseTime', 2] }
        }
      }
    ]);

    res.json({
      success: true,
      data: {
        overallStats: overallStats[0] || {},
        topPerformers: topPerformers.map(driver => ({
          driverId: driver._id,
          id: driver._id, // normalized id for frontend ease
          name: 'Driver Name', // placeholder; populate if needed
          totalRides: driver.totalRides,
          averageRating: Math.round(driver.averageRating * 10) / 10,
          totalEarnings: Math.round(driver.totalEarnings * 100) / 100,
          acceptanceRate: Math.round(driver.acceptanceRate * 100) / 100
        }))
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   POST /api/analytics/events
// @desc    Track user interactions and events
// @access  Private
/**
 * @swagger
 * /api/analytics/events:
 *   post:
 *     summary: Track user interactions and events
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [eventType]
 *             properties:
 *               eventType: { type: string }
 *               eventData: { type: object }
 *               sessionId: { type: string }
 *               deviceInfo: { type: object }
 *               location: { type: object }
 *     responses:
 *       201:
 *         description: Analytics event recorded
 */
router.post('/events', require('../middleware/auth').optionalAuth, analyticsLimiter, async (req, res, next) => {
  try {
    const {
      eventType,
      eventData = {},
      sessionId,
      deviceInfo = {},
      location
    } = req.body;

    if (!eventType) {
      return res.status(400).json({
        success: false,
        message: 'Event type is required'
      });
    }

    // Validate event type
    const validEventTypes = [
      'app_open', 'app_close', 'booking_started', 'booking_completed',
      'payment_attempt', 'payment_success', 'payment_failed', 'quote_requested',
      'quote_accepted', 'profile_updated', 'location_search', 'driver_rated',
      'support_contacted', 'promotion_viewed', 'loyalty_used',
      // Added to support mobile app analytics
      'user_sign_in', 'user_sign_in_failed', 'user_sign_out', 'password_reset_requested'
    ];

    if (!validEventTypes.includes(eventType)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid event type'
      });
    }

    // Create analytics event
    const analyticsEvent = new UserAnalytics({
      userId: req.userId,
      eventType,
      eventData,
      sessionId,
      deviceInfo: {
        platform: deviceInfo.platform || 'web',
        version: deviceInfo.version,
        deviceId: deviceInfo.deviceId
      },
      location,
      timestamp: new Date()
    });

    await analyticsEvent.save();

    res.status(201).json({
      success: true,
      message: 'Analytics event recorded'
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/analytics/dashboard
// @desc    Get dashboard overview metrics
// @access  Private/Admin
/**
 * @swagger
 * /api/analytics/dashboard:
 *   get:
 *     summary: Get dashboard overview metrics
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Overview metrics including users, bookings, revenue and drivers
 */
router.get('/dashboard', authenticateToken, requireAdmin, async (req, res, next) => {
  try {
    const today = new Date();
    const thirtyDaysAgo = new Date(today.getTime() - 30 * 24 * 60 * 60 * 1000);

    // Get key metrics
    const [
      userCount,
      activeUsers,
      totalBookings,
      totalRevenue,
      driverCount
    ] = await Promise.all([
      User.countDocuments(),
      User.countDocuments({ lastLoginAt: { $gte: thirtyDaysAgo } }),
      BookingAnalytics.aggregate([
        { $match: { date: { $gte: thirtyDaysAgo } } },
        { $group: { _id: null, total: { $sum: '$totalBookings' } } }
      ]),
      BookingAnalytics.aggregate([
        { $match: { date: { $gte: thirtyDaysAgo } } },
        { $group: { _id: null, total: { $sum: '$totalRevenue' } } }
      ]),
      require('../models/Driver').countDocuments({ status: 'active' })
    ]);

    res.json({
      success: true,
      data: {
        overview: {
          totalUsers: userCount,
          activeUsers,
          totalBookings: totalBookings[0]?.total || 0,
          totalRevenue: totalRevenue[0]?.total || 0,
          activeDrivers: driverCount
        },
        recentActivity: {
          period: '30 days',
          userGrowth: Math.round((activeUsers / userCount) * 100),
          avgBookingsPerDay: Math.round((totalBookings[0]?.total || 0) / 30),
          avgRevenuePerDay: Math.round((totalRevenue[0]?.total || 0) / 30)
        }
      }
    });

  } catch (error) {
    next(error);
  }
});

module.exports = router;
