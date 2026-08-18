const {
  UserAnalytics,
  BookingAnalytics,
  RevenueAnalytics,
  DriverAnalytics
} = require('../models/Analytics');
const {
  createTestUser,
  createTestDriver
} = require('./setup');
const {
  request,
  authenticatedRequest,
  adminRequest,
  expectSuccess,
  expectError
} = require('./testUtils');

describe('Analytics & Reporting APIs (API 9)', () => {
  describe('GET /api/analytics/users/:userId - User Analytics', () => {
    test('should get user analytics for admin', async () => {
      const user = await createTestUser({
        totalTrips: 15,
        totalSpent: 2250,
        loyaltyTier: 'Silver',
        loyaltyPoints: 1250
      });

      // Create some user analytics events
      await UserAnalytics.create([
        {
          userId: user._id,
          eventType: 'app_open',
          deviceInfo: { platform: 'ios' },
          timestamp: new Date()
        },
        {
          userId: user._id,
          eventType: 'booking_started',
          timestamp: new Date()
        },
        {
          userId: user._id,
          eventType: 'booking_completed',
          timestamp: new Date()
        }
      ]);

      const { request } = await adminRequest('GET', `/api/analytics/users/${user._id}`);

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data).toHaveProperty('user');
      expect(result.data).toHaveProperty('analytics');

      const userData = result.data.user;
      expect(userData.id).toBe(user._id.toString());
      expect(userData.totalTrips).toBe(15);
      expect(userData.loyaltyTier).toBe('Silver');

      const analytics = result.data.analytics;
      expect(analytics).toHaveProperty('totalEvents');
      expect(analytics).toHaveProperty('uniqueEventTypes');
      expect(analytics).toHaveProperty('avgEventsPerDay');
      expect(analytics).toHaveProperty('behaviorStats');
      expect(analytics).toHaveProperty('recentEvents');

      expect(analytics.totalEvents).toBe(3);
      expect(analytics.uniqueEventTypes).toBe(3);
    });

    test('should filter analytics by date range', async () => {
      const user = await createTestUser();

      const pastDate = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000); // 7 days ago
      const recentDate = new Date();

      await UserAnalytics.create([
        {
          userId: user._id,
          eventType: 'app_open',
          timestamp: pastDate
        },
        {
          userId: user._id,
          eventType: 'booking_started',
          timestamp: recentDate
        }
      ]);

      const { request } = await adminRequest('GET', `/api/analytics/users/${user._id}?startDate=${recentDate.toISOString().split('T')[0]}`);

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data.analytics.totalEvents).toBe(1);
    });

    test('should fail for non-admin user', async () => {
      const user = await createTestUser();

      const { request } = await authenticatedRequest('GET', `/api/analytics/users/${user._id}`);

      const response = await request;
      expectError(response, 403);
    });

    test('should return 404 for non-existent user', async () => {
      const { request } = await adminRequest('GET', '/api/analytics/users/507f1f77bcf86cd799439011');

      const response = await request;
      expectError(response, 404);
    });
  });

  describe('GET /api/analytics/bookings - Booking Analytics', () => {
    test('should get booking analytics summary', async () => {
      // Create booking analytics data
      await BookingAnalytics.create([
        {
          date: new Date(),
          totalBookings: 25,
          completedBookings: 22,
          cancelledBookings: 3,
          totalRevenue: 3750,
          averageBookingValue: 150,
          bookingsByVehicleType: {
            sedan: 15,
            suv: 8,
            luxury: 2
          },
          peakHours: [
            { hour: 8, bookingCount: 5 },
            { hour: 17, bookingCount: 7 },
            { hour: 12, bookingCount: 3 }
          ]
        }
      ]);

      const { request } = await adminRequest('GET', '/api/analytics/bookings');

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data).toHaveProperty('summary');
      expect(result.data).toHaveProperty('trends');
      expect(result.data).toHaveProperty('vehicleTypeBreakdown');
      expect(result.data).toHaveProperty('peakHours');
      expect(result.data).toHaveProperty('dateRange');

      const summary = result.data.summary;
      expect(summary.totalBookings).toBe(25);
      expect(summary.completedBookings).toBe(22);
      expect(summary.cancelledBookings).toBe(3);
      expect(summary.totalRevenue).toBe(3750);
    });

    test('should filter by date range', async () => {
      const today = new Date();
      const yesterday = new Date(today);
      yesterday.setDate(yesterday.getDate() - 1);

      await BookingAnalytics.create([
        {
          date: yesterday,
          totalBookings: 20,
          completedBookings: 18,
          totalRevenue: 2700
        },
        {
          date: today,
          totalBookings: 25,
          completedBookings: 22,
          totalRevenue: 3750
        }
      ]);

      const { request } = await adminRequest('GET', `/api/analytics/bookings?startDate=${today.toISOString().split('T')[0]}`);

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data.trends.length).toBe(1);
      expect(result.data.trends[0].totalBookings).toBe(25);
    });

    test('should calculate vehicle type breakdown correctly', async () => {
      await BookingAnalytics.create({
        date: new Date(),
        totalBookings: 10,
        bookingsByVehicleType: {
          sedan: 6,
          suv: 3,
          luxury: 1
        }
      });

      const { request } = await adminRequest('GET', '/api/analytics/bookings');

      const response = await request;
      const result = expectSuccess(response);

      const breakdown = result.data.vehicleTypeBreakdown;
      expect(breakdown.sedanBookings).toBe(6);
      expect(breakdown.suvBookings).toBe(3);
      expect(breakdown.luxuryBookings).toBe(1);
    });

    test('should identify peak hours correctly', async () => {
      await BookingAnalytics.create({
        date: new Date(),
        peakHours: [
          { hour: 8, bookingCount: 2 },
          { hour: 12, bookingCount: 5 },
          { hour: 17, bookingCount: 8 },
          { hour: 20, bookingCount: 3 }
        ]
      });

      const { request } = await adminRequest('GET', '/api/analytics/bookings');

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data.peakHours.length).toBeGreaterThan(0);
      // Should be sorted by booking count descending
      expect(result.data.peakHours[0].hour).toBe(17);
      expect(result.data.peakHours[0].avgBookings).toBe(8);
    });
  });

  describe('GET /api/analytics/revenue - Revenue Analytics', () => {
    test('should get revenue analytics summary', async () => {
      await RevenueAnalytics.create([
        {
          date: new Date(),
          totalRevenue: 5000,
          bookingRevenue: 4500,
          corporateRevenue: 500,
          refunds: 200,
          commissions: 300,
          driverPayouts: 2000,
          platformFees: 400,
          paymentMethods: {
            card: 3000,
            cash: 1500,
            wallet: 300,
            corporate: 200
          }
        }
      ]);

      const { request } = await adminRequest('GET', '/api/analytics/revenue');

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data).toHaveProperty('summary');
      expect(result.data).toHaveProperty('trends');
      expect(result.data).toHaveProperty('paymentMethods');
      expect(result.data).toHaveProperty('dateRange');

      const summary = result.data.summary;
      expect(summary.totalRevenue).toBe(5000);
      expect(summary.netRevenue).toBe(2100); // total - (refunds + commissions + driverPayouts + platformFees)
    });

    test('should calculate net revenue correctly', async () => {
      await RevenueAnalytics.create({
        date: new Date(),
        totalRevenue: 1000,
        refunds: 100,
        commissions: 100,
        driverPayouts: 400,
        platformFees: 100
      });

      const { request } = await adminRequest('GET', '/api/analytics/revenue');

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data.summary.netRevenue).toBe(300); // 1000 - (100 + 100 + 400 + 100)
    });

    test('should aggregate payment methods correctly', async () => {
      await RevenueAnalytics.create([
        {
          date: new Date(),
          paymentMethods: {
            card: 1000,
            cash: 500,
            wallet: 200
          }
        },
        {
          date: new Date(Date.now() - 24 * 60 * 60 * 1000), // Yesterday
          paymentMethods: {
            card: 800,
            cash: 300,
            corporate: 400
          }
        }
      ]);

      const { request } = await adminRequest('GET', '/api/analytics/revenue');

      const response = await request;
      const result = expectSuccess(response);

      const paymentMethods = result.data.paymentMethods;
      expect(paymentMethods.cardRevenue).toBe(1800);
      expect(paymentMethods.cashRevenue).toBe(800);
      expect(paymentMethods.walletRevenue).toBe(200);
      expect(paymentMethods.corporateRevenue).toBe(400);
    });
  });

  describe('GET /api/analytics/drivers - Driver Analytics', () => {
    test('should get driver performance analytics', async () => {
      // Create test drivers with analytics
      const user1 = await createTestUser({ email: 'driver1@test.com' });
      const user2 = await createTestUser({ email: 'driver2@test.com' });
      const driver1 = await createTestDriver(user1._id);
      const driver2 = await createTestDriver(user2._id);

      await DriverAnalytics.create([
        {
          driverId: driver1._id,
          date: new Date(),
          totalRides: 15,
          completedRides: 14,
          totalEarnings: 2250,
          averageRating: 4.8,
          acceptanceRate: 95,
          onlineHours: 8,
          performance: {
            onTimePickup: 90,
            customerSatisfaction: 95
          }
        },
        {
          driverId: driver2._id,
          date: new Date(),
          totalRides: 20,
          completedRides: 18,
          totalEarnings: 3000,
          averageRating: 4.9,
          acceptanceRate: 98,
          onlineHours: 10,
          performance: {
            onTimePickup: 95,
            customerSatisfaction: 98
          }
        }
      ]);

      const { request } = await adminRequest('GET', '/api/analytics/drivers');

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data).toHaveProperty('overallStats');
      expect(result.data).toHaveProperty('topPerformers');

      const overallStats = result.data.overallStats;
      expect(overallStats.totalDrivers).toBe(2);
      expect(overallStats.totalRides).toBe(35);
      expect(overallStats.totalEarnings).toBe(5250);

      expect(result.data.topPerformers.length).toBeGreaterThan(0);
      expect(result.data.topPerformers[0]).toHaveProperty('totalRides');
      expect(result.data.topPerformers[0]).toHaveProperty('averageRating');
    });

    test('should limit top performers results', async () => {
      // Create multiple drivers
      for (let i = 0; i < 5; i++) {
        const user = await createTestUser({ email: `driver${i}@test.com` });
        const driver = await createTestDriver(user._id);
        await DriverAnalytics.create({
          driverId: driver._id,
          date: new Date(),
          totalRides: 10 + i,
          averageRating: 4.0 + (i * 0.1),
          totalEarnings: 1500 + (i * 100)
        });
      }

      const { request } = await adminRequest('GET', '/api/analytics/drivers?limit=3');

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data.topPerformers.length).toBe(3);
      // Should be sorted by totalRides descending
      expect(result.data.topPerformers[0].totalRides).toBeGreaterThanOrEqual(result.data.topPerformers[1].totalRides);
    });
  });

  describe('POST /api/analytics/events - Track User Events', () => {
    test('should track user analytics events', async () => {
      const user = await createTestUser();

      const { request } = await authenticatedRequest('POST', '/api/analytics/events');

      const eventData = {
        eventType: 'booking_started',
        eventData: {
          vehicleType: 'sedan',
          serviceType: 'standard',
          estimatedPrice: 150
        },
        sessionId: 'session_123',
        deviceInfo: {
          platform: 'web',
          version: '1.0.0'
        },
        location: {
          latitude: -26.2041,
          longitude: 28.0473
        }
      };

      const response = await request.send(eventData);
      expectSuccess(response, 201);

      // Verify event was created
      const events = await UserAnalytics.find({ userId: user._id });
      expect(events.length).toBe(1);

      const event = events[0];
      expect(event.eventType).toBe('booking_started');
      expect(event.eventData.vehicleType).toBe('sedan');
      expect(event.deviceInfo.platform).toBe('web');
      expect(event.userId.toString()).toBe(user._id.toString());
    });

    test('should validate event types', async () => {
      const { request } = await authenticatedRequest('POST', '/api/analytics/events');

      const response = await request.send({
        eventType: 'invalid_event_type',
        eventData: {}
      });

      expectError(response, 400);
    });

    test('should require event type', async () => {
      const { request } = await authenticatedRequest('POST', '/api/analytics/events');

      const response = await request.send({
        eventData: { some: 'data' }
      });

      expectError(response, 400);
    });

    test('should accept valid event types', async () => {
      const user = await createTestUser();

      const { request } = await authenticatedRequest('POST', '/api/analytics/events');

      const validEventTypes = [
        'app_open', 'booking_completed', 'payment_success',
        'profile_updated', 'support_contacted', 'loyalty_used'
      ];

      for (const eventType of validEventTypes) {
        const response = await request.send({
          eventType,
          eventData: {}
        });

        expectSuccess(response, 201);
      }
    });

    test('should work without authentication for public events', async () => {
      // This endpoint uses optionalAuth, so it accepts unauthenticated requests
      const response = await request
        .post('/api/analytics/events')
        .send({
          eventType: 'app_open',
          eventData: {}
        });

      // Endpoint accepts unauthenticated requests (optionalAuth middleware)
      expectSuccess(response, 201);
    });
  });

  describe('GET /api/analytics/dashboard - Dashboard Overview', () => {
    test('should get dashboard metrics', async () => {
      // Create test data
      await createTestUser({ totalTrips: 5, totalSpent: 750 });
      await createTestUser({ totalTrips: 3, totalSpent: 450 });
      await createTestUser({ totalTrips: 8, totalSpent: 1200 });

      // Create active users (logged in recently)
      const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
      await createTestUser({
        lastLoginAt: new Date(),
        totalTrips: 2,
        totalSpent: 300
      });

      // Create booking analytics
      await BookingAnalytics.create({
        date: new Date(),
        totalBookings: 45,
        totalRevenue: 6750
      });

      const fifteenDaysAgo = new Date(Date.now() - 15 * 24 * 60 * 60 * 1000);
      await BookingAnalytics.create({
        date: fifteenDaysAgo,
        totalBookings: 30,
        totalRevenue: 4500
      });

      // Create active drivers
      const activeDriverUser = await createTestUser({ email: 'active_driver@test.com' });
      const inactiveDriverUser = await createTestUser({ email: 'inactive_driver@test.com' });
      await createTestDriver(activeDriverUser._id, { status: 'active' });
      await createTestDriver(inactiveDriverUser._id, { status: 'pending' });

      const { request } = await adminRequest('GET', '/api/analytics/dashboard');

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data).toHaveProperty('overview');
      expect(result.data).toHaveProperty('recentActivity');

      const overview = result.data.overview;
      expect(overview).toHaveProperty('totalUsers');
      expect(overview).toHaveProperty('activeUsers');
      expect(overview).toHaveProperty('totalBookings');
      expect(overview).toHaveProperty('totalRevenue');
      expect(overview).toHaveProperty('activeDrivers');

      expect(overview.totalUsers).toBeGreaterThan(0);
      expect(overview.activeUsers).toBeGreaterThan(0);
      expect(overview.totalBookings).toBe(75); // 45 + 30
      expect(overview.totalRevenue).toBe(11250); // 6750 + 4500
      expect(overview.activeDrivers).toBe(1);
    });

    test('should fail for non-admin user', async () => {
      const { request } = await authenticatedRequest('GET', '/api/analytics/dashboard');

      const response = await request;
      expectError(response, 403);
    });
  });

  describe('Analytics Model Static Methods', () => {
    test('should get bookings summary correctly', async () => {
      const startDate = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
      const endDate = new Date();

      await BookingAnalytics.create([
        {
          date: startDate,
          totalBookings: 10,
          completedBookings: 9,
          cancelledBookings: 1,
          totalRevenue: 1350,
          averageBookingValue: 135
        },
        {
          date: endDate,
          totalBookings: 15,
          completedBookings: 14,
          cancelledBookings: 1,
          totalRevenue: 2100,
          averageBookingValue: 140
        }
      ]);

      const summary = await BookingAnalytics.getBookingsSummary(startDate, endDate);

      expect(summary.length).toBe(1);
      expect(summary[0].totalBookings).toBe(25);
      expect(summary[0].completedBookings).toBe(23);
      expect(summary[0].cancelledBookings).toBe(2);
      expect(summary[0].totalRevenue).toBe(3450);
    });

    test('should get revenue summary correctly', async () => {
      const startDate = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
      const endDate = new Date();

      await RevenueAnalytics.create([
        {
          date: startDate,
          totalRevenue: 2000,
          refunds: 100,
          commissions: 200,
          driverPayouts: 800,
          platformFees: 150
        },
        {
          date: endDate,
          totalRevenue: 3000,
          refunds: 150,
          commissions: 300,
          driverPayouts: 1200,
          platformFees: 200
        }
      ]);

      const summary = await RevenueAnalytics.getRevenueSummary(startDate, endDate);

      expect(summary.length).toBe(1);
      expect(summary[0].totalRevenue).toBe(5000);
      expect(summary[0].netRevenue).toBe(1900); // 5000 - (250 + 500 + 2000 + 350) = 5000 - 3100 = 1900
    });

    test('should get top performers correctly', async () => {
      const user1 = await createTestUser({ email: 'driver1@test.com' });
      const user2 = await createTestUser({ email: 'driver2@test.com' });
      const driver1 = await createTestDriver(user1._id);
      const driver2 = await createTestDriver(user2._id);

      await DriverAnalytics.create([
        {
          driverId: driver1._id,
          totalRides: 20,
          averageRating: 4.8,
          totalEarnings: 3000
        },
        {
          driverId: driver2._id,
          totalRides: 15,
          averageRating: 4.9,
          totalEarnings: 2250
        }
      ]);

      const topPerformers = await DriverAnalytics.getTopPerformers(5);

      expect(topPerformers.length).toBe(2);
      expect(topPerformers[0].totalRides).toBe(20);
      expect(topPerformers[1].totalRides).toBe(15);
    });
  });
});
