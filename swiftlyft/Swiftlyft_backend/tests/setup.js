const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const User = require('../models/User');
const Quote = require('../models/Quote');
const Driver = require('../models/Driver');
const { SupportTicket, FAQ } = require('../models/Support');
const Notification = require('../models/Notification');
const { UserAnalytics, BookingAnalytics, RevenueAnalytics, DriverAnalytics } = require('../models/Analytics');
const { Offer, CorporateBooking, SecurityService, AirportService } = require('../models/SpecialFeatures');

let mongoServer;

// Setup in-memory MongoDB server
beforeAll(async () => {
  try {
    mongoServer = await MongoMemoryServer.create();
    const mongoUri = mongoServer.getUri();

    // Close any existing connections
    await mongoose.disconnect();

    // Connect to the in-memory database
    // Set test environment variables
    process.env.JWT_SECRET = 'test-secret';
    process.env.JWT_REFRESH_SECRET = 'test-refresh-secret';
    
    await mongoose.connect(mongoUri, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
  } catch (error) {
    console.error('Error setting up test database:', error);
    throw error;
  }
});

// Cleanup after all tests
afterAll(async () => {
  try {
    await mongoose.disconnect();
    if (mongoServer) {
      await mongoServer.stop();
    }
  } catch (error) {
    console.error('Error cleaning up test database:', error);
  }
});

// Clear all collections before each test
beforeEach(async () => {
  try {
    const collections = mongoose.connection.collections;
    for (const key in collections) {
      await collections[key].deleteMany({});
    }
  } catch (error) {
    console.error('Error clearing collections:', error);
  }
});

// Test data factories
const createTestUser = async (overrides = {}) => {
  const userData = {
    email: `test${Date.now()}@example.com`,
    password: 'testpass123',
    name: 'Test User',
    phoneNumber: '+1234567890',
    ...overrides
  };

  // Handle corporate user creation
  if (userData.isCorporateUser) {
    userData.corporateAccount = {
      companyName: userData.corporateAccount?.companyName || 'Test Company',
      companyEmail: userData.corporateAccount?.companyEmail || `corporate${Date.now()}@test.com`,
      contactPerson: userData.corporateAccount?.contactPerson || 'Test Contact',
      contactPhone: userData.corporateAccount?.contactPhone || '+1234567891',
      discountPercentage: userData.corporateAccount?.discountPercentage || 10,
      ...userData.corporateAccount
    };
  }

  const user = new User(userData);
  await user.save();
  return user;
};

const createTestDriver = async (userId, overrides = {}) => {
  if (!userId) {
    throw new Error('userId is required for createTestDriver');
  }
  const driverData = {
    userId,
    driverId: `DRV-${Date.now()}`,
    licenseNumber: `LIC${Date.now()}`,
    licenseExpiry: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // 1 year from now
    vehicleInfo: {
      make: 'Toyota',
      model: 'Corolla',
      year: 2020,
      color: 'White',
      licensePlate: `ABC${Date.now().toString().slice(-3)}`,
      vehicleType: 'sedan',
      passengerCapacity: 4,
      hasAC: true
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
    currentLocation: {
      coordinates: {
        latitude: -26.2041,
        longitude: 28.0473
      },
      address: 'Test Location'
    },
    emergencyContact: {
      name: 'Emergency Contact',
      phone: '+1234567891',
      relationship: 'Spouse'
    },
    ...overrides
  };

  const driver = new Driver(driverData);
  await driver.save();
  return driver;
};

const createTestQuote = async (userId, overrides = {}) => {
  const quoteData = {
    userId,
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
    scheduledDate: new Date(Date.now() + 24 * 60 * 60 * 1000), // Tomorrow
    estimatedDistance: 50,
    estimatedDuration: 60,
    estimatedPrice: {
      baseFare: 25,
      distanceFare: 75,
      timeFare: 40,
      serviceFee: 5,
      taxes: 20,
      total: 165
    },
    validUntil: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 hours from now
    ...overrides
  };

  const quote = new Quote(quoteData);
  await quote.save();
  return quote;
};

const createTestSupportTicket = async (userId, overrides = {}) => {
  const ticketData = {
    ticketId: `TKT-${Date.now()}`,
    userId,
    subject: 'Test Support Ticket',
    category: 'booking_issue',
    description: 'This is a test support ticket description',
    priority: 'normal',
    ...overrides
  };

  const ticket = new SupportTicket(ticketData);
  await ticket.save();
  return ticket;
};

const createTestOffer = async (overrides = {}) => {
  const offerData = {
    title: 'Test Offer',
    description: 'Test offer description',
    type: 'discount',
    discountValue: 20,
    promoCode: `TEST${Date.now()}`,
    targetAudience: 'all',
    conditions: 'Valid for standard bookings',
    startDate: new Date(),
    endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days from now
    isActive: true,
    ...overrides
  };

  const offer = new Offer(offerData);
  await offer.save();
  return offer;
};

// Mock request/response objects
const createMockRequest = (body = {}, params = {}, query = {}, user = null) => ({
  body,
  params,
  query,
  user,
  userId: user?._id,
  headers: {
    authorization: 'Bearer test-token'
  },
  ip: '127.0.0.1'
});

const createMockResponse = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  res.send = jest.fn().mockReturnValue(res);
  return res;
};

const createMockNext = () => jest.fn();

// JWT token generation for tests
const generateTestToken = (userId = '507f1f77bcf86cd799439011') => {
  const jwt = require('jsonwebtoken');
  return jwt.sign(
    { userId, type: 'access' },
    process.env.JWT_SECRET || 'test-secret',
    { expiresIn: '24h' }
  );
};

// Export all utilities
module.exports = {
  createTestUser,
  createTestDriver,
  createTestQuote,
  createTestSupportTicket,
  createTestOffer,
  createMockRequest,
  createMockResponse,
  createMockNext,
  generateTestToken
};
