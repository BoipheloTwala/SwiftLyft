// Test utilities and helpers
const supertest = require('supertest');
const User = require('../models/User');
const express = require('express');

// Create a separate app instance for testing
const app = express();

// Import routes directly
const authRoutes = require('../routes/auth');
const userRoutes = require('../routes/users');
const quoteRoutes = require('../routes/quotes');
const driverRoutes = require('../routes/drivers');
const notificationRoutes = require('../routes/notifications');
const analyticsRoutes = require('../routes/analytics');
const supportRoutes = require('../routes/support');
const specialFeaturesRoutes = require('../routes/special-features');

// Import middleware
const { authenticateToken, requireAdmin } = require('../middleware/auth');
const errorHandler = require('../middleware/errorHandler');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

// Security middleware
app.use(helmet());
app.use(cors({
  origin: ['http://localhost:3000', 'http://localhost:8080'],
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: {
    error: 'Too many requests from this IP, please try again later.'
  }
});
app.use('/api/', limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/quotes', quoteRoutes);
app.use('/api/drivers', driverRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/support', supportRoutes);
app.use('/api', specialFeaturesRoutes);

// Health check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'SwiftLyft API is running!',
    version: '1.0.0',
    endpoints: {
      health: '/api/health',
      auth: '/api/auth',
      users: '/api/users',
      quotes: '/api/quotes',
      drivers: '/api/drivers',
      notifications: '/api/notifications',
      analytics: '/api/analytics',
      support: '/api/support',
      offers: '/api/offers',
      corporate: '/api/corporate',
      services: '/api/services'
    },
    documentation: 'Visit /api/health for server status'
  });
});

// Error handling middleware (must be last)
app.use(errorHandler);

// Handle 404
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'API endpoint not found'
  });
});

const request = supertest(app);
const { createTestUser, generateTestToken } = require('./setup');

// Helper to create authenticated request
const authenticatedRequest = async (method, url, userOverrides = {}) => {
  // Allow passing an existing user to avoid duplicate email collisions
  let user = userOverrides && userOverrides._id ? userOverrides : null;

  // If no user provided, try to infer from URL patterns
  if (!user) {
    // If URL targets a specific userId, authenticate as that user
    const userMatch = url.match(/\/api\/(?:users|notifications\/user)\/([0-9a-fA-F]{24})/);
    if (userMatch) {
      const targetUserId = userMatch[1];
      user = await User.findById(targetUserId);
      if (!user) {
        user = await createTestUser({ _id: targetUserId, email: `user_${targetUserId}@test.com` });
      }
    }

    // If URL targets a notification, authenticate as notification owner
    const notificationMatch = url.match(/\/api\/notifications\/user\/([0-9a-fA-F]{24})\/([^/]+)/);
    if (!user && notificationMatch) {
      const targetUserId = notificationMatch[1];
      user = await User.findById(targetUserId);
      if (!user) {
        user = await createTestUser({ _id: targetUserId, email: `user_${targetUserId}@test.com` });
      }
    }

    // If URL targets a support ticket, authenticate as ticket owner
    const ticketMatch = url.match(/\/api\/support\/tickets\/([^/]+)/);
    if (!user && ticketMatch) {
      try {
        const { SupportTicket } = require('../models/Support');
        const t = await SupportTicket.findOne({ ticketId: ticketMatch[1] });
        if (t) {
          user = await User.findById(t.userId) || await createTestUser({ _id: t.userId, email: `user_${t.userId}@test.com` });
        }
      } catch {}
    }

    // If URL targets a quote, authenticate as quote owner
    const quoteMatch = url.match(/\/api\/quotes\/([0-9a-fA-F]{24})/);
    if (!user && quoteMatch) {
      try {
        const { Quote } = require('../models/Quote');
        const q = await Quote.findById(quoteMatch[1]);
        if (q) {
          user = await User.findById(q.userId) || await createTestUser({ _id: q.userId, email: `user_${q.userId}@test.com` });
        }
      } catch {}
    }

    // If URL targets a driver, authenticate as driver owner
    const driverMatch = url.match(/\/api\/drivers\/([0-9a-fA-F]{24})/);
    if (!user && driverMatch) {
      try {
        const { Driver } = require('../models/Driver');
        const d = await Driver.findById(driverMatch[1]);
        if (d) {
          user = await User.findById(d.userId) || await createTestUser({ _id: d.userId, email: `user_${d.userId}@test.com` });
        }
      } catch {}
    }
  }
  if (!user) {
    user = await User.findOne().sort({ createdAt: -1 });
  }
  if (!user) {
    user = await createTestUser(userOverrides);
  }
  const token = generateTestToken(user._id);

  const result = {
    request: request[method.toLowerCase()](url)
      .set('Authorization', `Bearer ${token}`),
    user,
    token
  };
  return result;
};

// Helper to create admin request (mock admin user)
const adminRequest = async (method, url) => {
  const adminUser = await createTestUser({
    email: `admin${Date.now()}@swiftlyft.co.za`,
    role: 'admin'
  });
  const token = generateTestToken(adminUser._id);

  return {
    request: request[method.toLowerCase()](url)
      .set('Authorization', `Bearer ${token}`),
    user: adminUser,
    token
  };
};

// Helper to expect successful response
const expectSuccess = (response, statusCode = 200) => {
  expect(response.status).toBe(statusCode);
  expect(response.body.success).toBe(true);
  return response.body;
};

// Helper to expect error response
const expectError = (response, statusCode = 400) => {
  expect(response.status).toBe(statusCode);
  expect(response.body.success).toBe(false);
  expect(response.body.message).toBeDefined();
  return response.body;
};

// Helper to validate quote structure
const validateQuoteResponse = (quote) => {
  expect(quote).toHaveProperty('id');
  expect(quote).toHaveProperty('userId');
  expect(quote).toHaveProperty('pickupLocation');
  expect(quote).toHaveProperty('dropoffLocation');
  expect(quote).toHaveProperty('vehicleType');
  expect(quote).toHaveProperty('serviceType');
  expect(quote).toHaveProperty('passengerCount');
  expect(quote).toHaveProperty('estimatedPrice');
  expect(quote).toHaveProperty('status');
  expect(quote).toHaveProperty('validUntil');
};

// Helper to validate driver structure
const validateDriverResponse = (driver) => {
  expect(driver).toHaveProperty('id');
  expect(driver).toHaveProperty('driverId');
  expect(driver).toHaveProperty('licenseNumber');
  expect(driver).toHaveProperty('vehicleInfo');
  expect(driver).toHaveProperty('currentLocation');
  expect(driver).toHaveProperty('availability');
  expect(driver).toHaveProperty('performance');
  expect(driver).toHaveProperty('status');
};

// Helper to validate notification structure
const validateNotificationResponse = (notification) => {
  expect(notification).toHaveProperty('id');
  expect(notification).toHaveProperty('userId');
  expect(notification).toHaveProperty('type');
  expect(notification).toHaveProperty('title');
  expect(notification).toHaveProperty('message');
  expect(notification).toHaveProperty('channels');
  expect(notification).toHaveProperty('priority');
  expect(notification).toHaveProperty('status');
};

// Helper to validate support ticket structure
const validateSupportTicketResponse = (ticket) => {
  expect(ticket).toHaveProperty('id');
  expect(ticket).toHaveProperty('ticketId');
  expect(ticket).toHaveProperty('userId');
  expect(ticket).toHaveProperty('subject');
  expect(ticket).toHaveProperty('category');
  expect(ticket).toHaveProperty('description');
  expect(ticket).toHaveProperty('status');
  expect(ticket).toHaveProperty('priority');
};

// Helper to validate offer structure
const validateOfferResponse = (offer) => {
  expect(offer).toHaveProperty('id');
  expect(offer).toHaveProperty('title');
  expect(offer).toHaveProperty('description');
  expect(offer).toHaveProperty('type');
  expect(offer).toHaveProperty('discountValue');
  expect(offer).toHaveProperty('promoCode');
  expect(offer).toHaveProperty('conditions');
  expect(offer).toHaveProperty('endDate');
};

// Common test data
const testQuoteData = {
  pickupLocation: {
    address: '123 Main St, Johannesburg',
    coordinates: { latitude: -26.2041, longitude: 28.0473 }
  },
  dropoffLocation: {
    address: '456 Oak Ave, Pretoria',
    coordinates: { latitude: -25.7479, longitude: 28.2293 }
  },
  vehicleType: 'sedan',
  serviceType: 'standard',
  passengerCount: 2,
  luggageCount: 1,
  specialRequirements: 'Test requirements',
  scheduledDate: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()
};

const testDriverData = {
  licenseNumber: 'TEST123456',
  licenseExpiry: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString(),
  vehicleInfo: {
    make: 'Toyota',
    model: 'Corolla',
    year: 2020,
    color: 'White',
    licensePlate: 'ABC123',
    vehicleType: 'sedan',
    passengerCapacity: 4,
    hasAC: true,
    features: ['wifi', 'leather_seats']
  },
  documents: {
    licensePhoto: 'https://example.com/license.jpg',
    vehicleRegistration: 'https://example.com/registration.jpg',
    vehicleInsurance: 'https://example.com/insurance.jpg',
    profilePhoto: 'https://example.com/profile.jpg'
  },
  bankDetails: {
    accountHolder: 'Test Driver',
    accountNumber: '1234567890',
    bankName: 'Test Bank',
    branchCode: '123456'
  },
  emergencyContact: {
    name: 'Emergency Contact',
    phone: '+1234567891',
    relationship: 'Spouse'
  },
  latitude: -26.2041,
  longitude: 28.0473,
  address: 'Test Location'
};

const testSupportTicketData = {
  subject: 'Test Support Ticket',
  category: 'booking_issue',
  description: 'This is a test support ticket description',
  priority: 'normal',
  relatedBookingId: '507f1f77bcf86cd799439011'
};

const testOfferData = {
  title: 'Test Offer',
  description: 'Test offer description',
  type: 'discount_percentage',
  discountValue: 20,
  promoCode: 'TEST20',
  targetAudience: 'all',
  conditions: 'Valid for standard bookings',
  startDate: new Date().toISOString(),
  endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
  isActive: true
};

module.exports = {
  request,
  authenticatedRequest,
  adminRequest,
  expectSuccess,
  expectError,
  validateQuoteResponse,
  validateDriverResponse,
  validateNotificationResponse,
  validateSupportTicketResponse,
  validateOfferResponse,
  testQuoteData,
  testDriverData,
  testSupportTicketData,
  testOfferData
};
