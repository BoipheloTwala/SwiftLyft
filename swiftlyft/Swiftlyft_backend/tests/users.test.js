const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../server');
const User = require('../models/User');
const { generateAccessToken } = require('../utils/jwt');

describe('User Management & Profile APIs', () => {
  let testUser;
  let authToken;
  let adminUser;
  let adminToken;

  beforeAll(async () => {
    // Create test user
    testUser = new User({
      email: 'testuser@example.com',
      password: 'password123',
      name: 'Test User',
      phoneNumber: '+1234567890',
      loyaltyPoints: 1500,
      loyaltyTier: 'Silver',
      totalTrips: 25,
      totalSpent: 2500,
      earnedRewards: [{
        name: 'Free Ride',
        description: 'One free ride up to $50',
        type: 'free_ride',
        pointsCost: 1000,
        isActive: true
      }],
      availableRewards: [{
        name: '10% Discount',
        description: '10% off your next ride',
        type: 'discount',
        pointsCost: 500,
        discountPercentage: 10,
        isActive: true
      }],
      referrals: [{
        referredUserEmail: 'referred@example.com',
        referredUserName: 'Referred User',
        status: 'completed',
        earnings: 50,
        completedAt: new Date()
      }],
      corporateAccount: {
        companyName: 'Test Corp',
        companyEmail: 'corp@test.com',
        contactPerson: 'John Doe',
        contactPhone: '+1234567890',
        discountPercentage: 15,
        monthlyBudget: 10000,
        usedBudget: 2500,
        status: 'active'
      },
      bulkBookings: [{
        title: 'Corporate Event',
        description: 'Transportation for company event',
        items: [{
          vehicleId: new mongoose.Types.ObjectId(),
          vehicleName: 'Luxury Sedan',
          quantity: 5,
          unitPrice: 100,
          pickupLocation: 'Office',
          dropoffLocation: 'Venue',
          pickupTime: new Date(),
          passengerCount: 4
        }],
        status: 'confirmed',
        totalAmount: 500,
        discountAmount: 75
      }]
    });
    await testUser.save();

    // Create admin user
    adminUser = new User({
      email: 'admin@example.com',
      password: 'password123',
      name: 'Admin User',
      role: 'admin'
    });
    await adminUser.save();

    // Login to get tokens
    const userLogin = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'testuser@example.com',
        password: 'password123'
      });
    authToken = userLogin.body.data.tokens.accessToken;

    const adminLogin = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'admin@example.com',
        password: 'password123'
      });
    adminToken = adminLogin.body.data.tokens.accessToken;
  });

  beforeEach(async () => {
    // Recreate test user (since setup.js clears all collections)
    testUser = new User({
      email: 'testuser@example.com',
      password: 'password123',
      name: 'Test User',
      phoneNumber: '+1234567890',
      loyaltyPoints: 1500,
      loyaltyTier: 'Silver',
      totalTrips: 25,
      totalSpent: 2500,
      earnedRewards: [{
        name: 'Free Ride',
        description: 'One free ride up to $50',
        type: 'free_ride',
        pointsCost: 1000,
        isActive: true
      }],
      availableRewards: [{
        name: '10% Discount',
        description: '10% off your next ride',
        type: 'discount',
        pointsCost: 500,
        discountPercentage: 10,
        isActive: true
      }],
      referrals: [{
        referredUserEmail: 'referred@example.com',
        referredUserName: 'Referred User',
        status: 'completed',
        earnings: 50,
        completedAt: new Date()
      }],
      corporateAccount: {
        companyName: 'Test Corp',
        companyEmail: 'corp@test.com',
        contactPerson: 'John Doe',
        contactPhone: '+1234567890',
        discountPercentage: 15,
        monthlyBudget: 10000,
        usedBudget: 2500,
        status: 'active'
      },
      bulkBookings: [{
        title: 'Corporate Event',
        description: 'Transportation for company event',
        items: [{
          vehicleId: new mongoose.Types.ObjectId(),
          vehicleName: 'Luxury Sedan',
          quantity: 5,
          unitPrice: 100,
          passengerCount: 4,
          pickupLocation: 'Office',
          dropoffLocation: 'Venue',
          pickupTime: new Date(),
          dropoffTime: new Date(Date.now() + 2 * 60 * 60 * 1000),
          status: 'confirmed'
        }],
        totalAmount: 500,
        discountAmount: 75,
        status: 'confirmed',
        createdAt: new Date()
      }]
    });
    await testUser.save();

    // Recreate admin user
    adminUser = new User({
      email: 'admin@example.com',
      password: 'password123',
      name: 'Admin User',
      phoneNumber: '+1234567891',
      role: 'admin'
    });
    await adminUser.save();

    // Generate auth tokens directly to avoid rate limiting
    authToken = generateAccessToken(testUser._id.toString());
    adminToken = generateAccessToken(adminUser._id.toString());
  });

  afterAll(async () => {
    await User.deleteMany({ email: { $in: ['testuser@example.com', 'admin@example.com'] } });
    if (mongoose.connection.readyState === 1) {
      await mongoose.connection.close();
    }
  });

  describe('GET /api/users/:id', () => {
    it('should get user profile by ID', async () => {
      const response = await request(app)
        .get(`/api/users/${testUser._id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.user).toHaveProperty('id', testUser._id.toString());
      expect(response.body.data.user).toHaveProperty('email', 'testuser@example.com');
      expect(response.body.data.user).toHaveProperty('name', 'Test User');
      expect(response.body.data.user).not.toHaveProperty('password');
    });

    it('should return 403 when accessing another user\'s profile', async () => {
      const otherUser = new User({
        email: 'other@example.com',
        password: 'password123',
        name: 'Other User'
      });
      await otherUser.save();

      await request(app)
        .get(`/api/users/${otherUser._id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(403);

      await User.findByIdAndDelete(otherUser._id);
    });

    it('should allow admin to access any user profile', async () => {
      const response = await request(app)
        .get(`/api/users/${testUser._id}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.user).toHaveProperty('id', testUser._id.toString());
    });

    it('should return 400 for invalid user ID format', async () => {
      await request(app)
        .get('/api/users/invalid-id')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(400);
    });

    it('should return 404 for non-existent user', async () => {
      const fakeId = new mongoose.Types.ObjectId();
      await request(app)
        .get(`/api/users/${fakeId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);
    });
  });

  describe('PUT /api/users/:id', () => {
    it('should update user information', async () => {
      const response = await request(app)
        .put(`/api/users/${testUser._id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Updated Name',
          phoneNumber: '+9876543210',
          profileImageUrl: 'https://example.com/image.jpg'
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.user.name).toBe('Updated Name');
      expect(response.body.data.user.phoneNumber).toBe('+9876543210');
      expect(response.body.data.user.profileImageUrl).toBe('https://example.com/image.jpg');
    });

    it('should return 400 for invalid phone number', async () => {
      await request(app)
        .put(`/api/users/${testUser._id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          phoneNumber: 'invalid-phone'
        })
        .expect(400);
    });

    it('should return 400 for invalid image URL', async () => {
      await request(app)
        .put(`/api/users/${testUser._id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          profileImageUrl: 'not-a-url'
        })
        .expect(400);
    });

    it('should return 403 when updating another user\'s profile', async () => {
      const otherUser = new User({
        email: 'other2@example.com',
        password: 'password123',
        name: 'Other User'
      });
      await otherUser.save();

      await request(app)
        .put(`/api/users/${otherUser._id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Hacked Name'
        })
        .expect(403);

      await User.findByIdAndDelete(otherUser._id);
    });
  });

  describe('GET /api/users/:id/loyalty', () => {
    it('should get loyalty program data', async () => {
      const response = await request(app)
        .get(`/api/users/${testUser._id}/loyalty`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('loyaltyTier', 'Silver');
      expect(response.body.data).toHaveProperty('loyaltyPoints', 1500);
      expect(response.body.data).toHaveProperty('pointsToNextTier');
      expect(response.body.data).toHaveProperty('tierProgress');
      expect(response.body.data).toHaveProperty('tierDiscount');
      expect(response.body.data).toHaveProperty('earnedRewards');
      expect(response.body.data).toHaveProperty('availableRewards');
      expect(response.body.data).toHaveProperty('totalTrips', 25);
      expect(response.body.data).toHaveProperty('totalSpent', 2500);
    });

    it('should return 403 when accessing another user\'s loyalty data', async () => {
      const otherUser = new User({
        email: 'other3@example.com',
        password: 'password123',
        name: 'Other User'
      });
      await otherUser.save();

      await request(app)
        .get(`/api/users/${otherUser._id}/loyalty`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(403);

      await User.findByIdAndDelete(otherUser._id);
    });
  });

  describe('GET /api/users/:id/rewards', () => {
    it('should get available and earned rewards', async () => {
      const response = await request(app)
        .get(`/api/users/${testUser._id}/rewards`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('earnedRewards');
      expect(response.body.data).toHaveProperty('availableRewards');
      expect(response.body.data).toHaveProperty('loyaltyPoints', 1500);
      expect(response.body.data).toHaveProperty('loyaltyTier', 'Silver');
      expect(response.body.data).toHaveProperty('totalEarnedRewards');
      expect(response.body.data).toHaveProperty('totalAvailableRewards');
      
      expect(response.body.data.earnedRewards).toHaveLength(1);
      expect(response.body.data.availableRewards).toHaveLength(1);
    });

    it('should filter only active rewards', async () => {
      // Add an inactive reward
      testUser.earnedRewards.push({
        name: 'Inactive Reward',
        description: 'This reward is inactive',
        type: 'discount',
        pointsCost: 200,
        isActive: false
      });
      await testUser.save();

      const response = await request(app)
        .get(`/api/users/${testUser._id}/rewards`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data.earnedRewards).toHaveLength(1); // Only active rewards
    });
  });

  describe('GET /api/users/:id/referrals', () => {
    it('should get referral tracking data', async () => {
      const response = await request(app)
        .get(`/api/users/${testUser._id}/referrals`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('referralCode');
      expect(response.body.data).toHaveProperty('referrals');
      expect(response.body.data).toHaveProperty('stats');
      
      expect(response.body.data.stats).toHaveProperty('totalReferrals', 1);
      expect(response.body.data.stats).toHaveProperty('successfulReferrals', 1);
      expect(response.body.data.stats).toHaveProperty('pendingReferrals', 0);
      expect(response.body.data.stats).toHaveProperty('cancelledReferrals', 0);
      expect(response.body.data.stats).toHaveProperty('totalEarnings', 50);
    });
  });

  describe('GET /api/users/:id/corporate', () => {
    it('should get corporate account details', async () => {
      const response = await request(app)
        .get(`/api/users/${testUser._id}/corporate`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('corporateAccount');
      expect(response.body.data).toHaveProperty('isCorporateUser', true);
      
      expect(response.body.data.corporateAccount).toHaveProperty('companyName', 'Test Corp');
      expect(response.body.data.corporateAccount).toHaveProperty('companyEmail', 'corp@test.com');
      expect(response.body.data.corporateAccount).toHaveProperty('discountPercentage', 15);
      expect(response.body.data.corporateAccount).toHaveProperty('monthlyBudget', 10000);
      expect(response.body.data.corporateAccount).toHaveProperty('usedBudget', 2500);
    });

    it('should return 404 for user without corporate account', async () => {
      const regularUser = new User({
        email: 'regular@example.com',
        password: 'password123',
        name: 'Regular User'
      });
      await regularUser.save();

      const regularUserToken = generateAccessToken(regularUser._id.toString());

      await request(app)
        .get(`/api/users/${regularUser._id}/corporate`)
        .set('Authorization', `Bearer ${regularUserToken}`)
        .expect(404);

      await User.findByIdAndDelete(regularUser._id);
    });
  });

  describe('GET /api/users/:id/bulk-bookings', () => {
    it('should get corporate bulk bookings', async () => {
      const response = await request(app)
        .get(`/api/users/${testUser._id}/bulk-bookings`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('bulkBookings');
      expect(response.body.data).toHaveProperty('pagination');
      expect(response.body.data).toHaveProperty('summary');
      
      expect(response.body.data.bulkBookings).toHaveLength(1);
      expect(response.body.data.pagination).toHaveProperty('currentPage', 1);
      expect(response.body.data.pagination).toHaveProperty('totalPages', 1);
      expect(response.body.data.pagination).toHaveProperty('totalBookings', 1);
      
      expect(response.body.data.summary).toHaveProperty('totalAmount', 500);
      expect(response.body.data.summary).toHaveProperty('totalDiscount', 75);
      expect(response.body.data.summary.statusCounts).toHaveProperty('confirmed', 1);
    });

    it('should filter bulk bookings by status', async () => {
      const response = await request(app)
        .get(`/api/users/${testUser._id}/bulk-bookings?status=confirmed`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data.bulkBookings).toHaveLength(1);
      expect(response.body.data.bulkBookings[0].status).toBe('confirmed');
    });

    it('should support pagination', async () => {
      const response = await request(app)
        .get(`/api/users/${testUser._id}/bulk-bookings?limit=5&page=1`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data.pagination).toHaveProperty('currentPage', 1);
      expect(response.body.data.pagination).toHaveProperty('totalPages', 1);
    });

    it('should return 404 for user without corporate account', async () => {
      const regularUser = new User({
        email: 'regular2@example.com',
        password: 'password123',
        name: 'Regular User'
      });
      await regularUser.save();

      const regularUserToken = generateAccessToken(regularUser._id.toString());

      await request(app)
        .get(`/api/users/${regularUser._id}/bulk-bookings`)
        .set('Authorization', `Bearer ${regularUserToken}`)
        .expect(404);

      await User.findByIdAndDelete(regularUser._id);
    });
  });

  describe('Authentication and Authorization', () => {
    it('should require authentication for all endpoints', async () => {
      await request(app)
        .get(`/api/users/${testUser._id}`)
        .expect(401);
    });

    it('should allow admin access to all user data', async () => {
      const response = await request(app)
        .get(`/api/users/${testUser._id}/loyalty`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
    });
  });
});
