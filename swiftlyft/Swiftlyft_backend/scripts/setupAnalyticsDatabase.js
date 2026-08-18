const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const {
  UserAnalytics,
  BookingAnalytics,
  RevenueAnalytics,
  DriverAnalytics
} = require('../models/Analytics');

class AnalyticsDatabaseSetup {
  constructor() {
    this.connection = null;
  }

  // Connect to MongoDB
  async connect() {
    try {
      const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_analytics';
      
      this.connection = await mongoose.connect(mongoUri, {
        useNewUrlParser: true,
        useUnifiedTopology: true,
      });

      console.log('✅ Connected to MongoDB for Analytics');
      console.log(`📊 Database: ${mongoose.connection.name}`);
      return this.connection;
    } catch (error) {
      console.error('❌ MongoDB connection error:', error);
      throw error;
    }
  }

  // Create indexes for optimal performance
  async createIndexes() {
    try {
      console.log('🔍 Creating Analytics database indexes...');

      // UserAnalytics collection indexes
      await UserAnalytics.collection.createIndex({ "userId": 1, "timestamp": -1 });
      console.log('✅ Created userAnalytics userId + timestamp index');

      await UserAnalytics.collection.createIndex({ "eventType": 1, "timestamp": -1 });
      console.log('✅ Created userAnalytics eventType + timestamp index');

      await UserAnalytics.collection.createIndex({ "sessionId": 1 });
      console.log('✅ Created userAnalytics sessionId index');

      await UserAnalytics.collection.createIndex({ "timestamp": -1 });
      console.log('✅ Created userAnalytics timestamp index');

      // BookingAnalytics collection indexes
      await BookingAnalytics.collection.createIndex({ "date": 1 }, { unique: true });
      console.log('✅ Created bookingAnalytics date index');

      await BookingAnalytics.collection.createIndex({ "totalBookings": -1 });
      console.log('✅ Created bookingAnalytics totalBookings index');

      await BookingAnalytics.collection.createIndex({ "totalRevenue": -1 });
      console.log('✅ Created bookingAnalytics totalRevenue index');

      // RevenueAnalytics collection indexes
      await RevenueAnalytics.collection.createIndex({ "date": 1 }, { unique: true });
      console.log('✅ Created revenueAnalytics date index');

      await RevenueAnalytics.collection.createIndex({ "totalRevenue": -1 });
      console.log('✅ Created revenueAnalytics totalRevenue index');

      // DriverAnalytics collection indexes
      await DriverAnalytics.collection.createIndex({ "driverId": 1, "date": 1 });
      console.log('✅ Created driverAnalytics driverId + date index');

      await DriverAnalytics.collection.createIndex({ "averageRating": -1 });
      console.log('✅ Created driverAnalytics averageRating index');

      await DriverAnalytics.collection.createIndex({ "totalEarnings": -1 });
      console.log('✅ Created driverAnalytics totalEarnings index');

      // Compound indexes for analytics queries
      await UserAnalytics.collection.createIndex({ 
        "userId": 1, 
        "eventType": 1, 
        "timestamp": -1 
      });
      console.log('✅ Created userAnalytics compound query index');

      await BookingAnalytics.collection.createIndex({ 
        "date": 1, 
        "totalBookings": -1 
      });
      console.log('✅ Created bookingAnalytics compound index');

      console.log('🎉 All Analytics indexes created successfully!');
    } catch (error) {
      console.error('❌ Error creating Analytics indexes:', error);
      throw error;
    }
  }

  // Validate database schema
  async validateSchema() {
    try {
      console.log('🔍 Validating Analytics database schema...');

      // Test UserAnalytics creation with validation
      const testUserAnalytics = new UserAnalytics({
        userId: new mongoose.Types.ObjectId(),
        eventType: 'app_open',
        eventData: {
          screen: 'home',
          action: 'login'
        },
        sessionId: 'test_session_123',
        deviceInfo: {
          platform: 'web',
          version: '1.0.0',
          deviceId: 'test_device_123'
        },
        location: {
          latitude: -33.9249,
          longitude: 18.4241,
          address: 'Cape Town, South Africa'
        }
      });

      await testUserAnalytics.validate();
      console.log('✅ UserAnalytics schema validation passed');

      // Test BookingAnalytics creation
      const testBookingAnalytics = new BookingAnalytics({
        date: new Date(),
        totalBookings: 50,
        completedBookings: 45,
        cancelledBookings: 5,
        averageBookingValue: 150.75,
        totalRevenue: 7537.50,
        bookingsByVehicleType: {
          sedan: 20,
          suv: 15,
          luxury: 10,
          van: 3,
          truck: 2,
          motorcycle: 0
        },
        bookingsByServiceType: {
          standard: 35,
          premium: 10,
          corporate: 3,
          airport: 2,
          security: 0
        },
        peakHours: [
          { hour: 8, bookingCount: 15 },
          { hour: 17, bookingCount: 12 },
          { hour: 20, bookingCount: 8 }
        ],
        popularRoutes: [
          { pickup: 'Cape Town CBD', dropoff: 'Airport', bookingCount: 10 },
          { pickup: 'Sea Point', dropoff: 'Cape Town CBD', bookingCount: 8 }
        ]
      });

      await testBookingAnalytics.validate();
      console.log('✅ BookingAnalytics schema validation passed');

      // Test RevenueAnalytics creation
      const testRevenueAnalytics = new RevenueAnalytics({
        date: new Date(),
        totalRevenue: 10000.00,
        bookingRevenue: 8500.00,
        corporateRevenue: 1200.00,
        otherRevenue: 300.00,
        refunds: 150.00,
        commissions: 500.00,
        driverPayouts: 7000.00,
        platformFees: 300.00,
        paymentMethods: {
          card: 6000.00,
          cash: 2000.00,
          wallet: 1500.00,
          corporate: 500.00
        },
        revenueByRegion: [
          { region: 'Cape Town', amount: 6000.00 },
          { region: 'Johannesburg', amount: 3000.00 },
          { region: 'Durban', amount: 1000.00 }
        ]
      });

      await testRevenueAnalytics.validate();
      console.log('✅ RevenueAnalytics schema validation passed');

      // Test DriverAnalytics creation
      const testDriverAnalytics = new DriverAnalytics({
        driverId: new mongoose.Types.ObjectId(),
        date: new Date(),
        totalRides: 25,
        completedRides: 23,
        cancelledRides: 2,
        totalEarnings: 1250.00,
        averageRating: 4.7,
        onlineHours: 8.5,
        acceptanceRate: 92.0,
        averageResponseTime: 2.3,
        customerComplaints: 0,
        performance: {
          onTimePickup: 95.0,
          customerSatisfaction: 96.0,
          completionRate: 92.0
        }
      });

      await testDriverAnalytics.validate();
      console.log('✅ DriverAnalytics schema validation passed');

      console.log('🎉 Analytics schema validation completed successfully!');
    } catch (error) {
      console.error('❌ Analytics schema validation failed:', error);
      throw error;
    }
  }

  // Create sample data for testing
  async createSampleData() {
    try {
      console.log('🌱 Creating Analytics sample data...');

      // Check if sample data already exists
      const existingUserAnalytics = await UserAnalytics.countDocuments();
      if (existingUserAnalytics > 0) {
        console.log('⚠️ Analytics sample data already exists, skipping...');
        return;
      }

      // Create sample UserAnalytics events
      const sampleUserEvents = [
        {
          userId: new mongoose.Types.ObjectId(),
          eventType: 'app_open',
          eventData: { screen: 'home', source: 'push_notification' },
          sessionId: 'session_001',
          deviceInfo: {
            platform: 'ios',
            version: '1.2.3',
            deviceId: 'iPhone_12_Pro'
          },
          location: {
            latitude: -33.9249,
            longitude: 18.4241,
            address: 'Cape Town, South Africa'
          },
          timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000) // 2 hours ago
        },
        {
          userId: new mongoose.Types.ObjectId(),
          eventType: 'booking_started',
          eventData: { 
            pickupLocation: 'Cape Town CBD',
            dropoffLocation: 'Airport',
            estimatedPrice: 250.00
          },
          sessionId: 'session_002',
          deviceInfo: {
            platform: 'android',
            version: '1.2.1',
            deviceId: 'Samsung_Galaxy_S21'
          },
          location: {
            latitude: -33.9250,
            longitude: 18.4242,
            address: 'Cape Town CBD, South Africa'
          },
          timestamp: new Date(Date.now() - 1 * 60 * 60 * 1000) // 1 hour ago
        },
        {
          userId: new mongoose.Types.ObjectId(),
          eventType: 'payment_success',
          eventData: { 
            amount: 180.50,
            paymentMethod: 'card',
            transactionId: 'txn_12345'
          },
          sessionId: 'session_003',
          deviceInfo: {
            platform: 'web',
            version: '2.0.0',
            deviceId: 'Chrome_Browser'
          },
          timestamp: new Date(Date.now() - 30 * 60 * 1000) // 30 minutes ago
        }
      ];

      for (const eventData of sampleUserEvents) {
        const event = new UserAnalytics(eventData);
        await event.save();
        console.log(`✅ Created UserAnalytics event: ${eventData.eventType}`);
      }

      // Create sample BookingAnalytics data for the last 30 days
      for (let i = 0; i < 30; i++) {
        const date = new Date(Date.now() - i * 24 * 60 * 60 * 1000);
        const totalBookings = Math.floor(Math.random() * 100) + 20;
        const completedBookings = Math.floor(totalBookings * (0.85 + Math.random() * 0.1));
        const cancelledBookings = totalBookings - completedBookings;
        const averageBookingValue = 120 + Math.random() * 80;
        const totalRevenue = completedBookings * averageBookingValue;

        const bookingData = new BookingAnalytics({
          date: date,
          totalBookings: totalBookings,
          completedBookings: completedBookings,
          cancelledBookings: cancelledBookings,
          averageBookingValue: Math.round(averageBookingValue * 100) / 100,
          totalRevenue: Math.round(totalRevenue * 100) / 100,
          bookingsByVehicleType: {
            sedan: Math.floor(totalBookings * 0.4),
            suv: Math.floor(totalBookings * 0.3),
            luxury: Math.floor(totalBookings * 0.15),
            van: Math.floor(totalBookings * 0.1),
            truck: Math.floor(totalBookings * 0.05),
            motorcycle: 0
          },
          bookingsByServiceType: {
            standard: Math.floor(totalBookings * 0.7),
            premium: Math.floor(totalBookings * 0.2),
            corporate: Math.floor(totalBookings * 0.08),
            airport: Math.floor(totalBookings * 0.02),
            security: 0
          },
          peakHours: [
            { hour: 8, bookingCount: Math.floor(totalBookings * 0.15) },
            { hour: 17, bookingCount: Math.floor(totalBookings * 0.12) },
            { hour: 20, bookingCount: Math.floor(totalBookings * 0.08) }
          ],
          popularRoutes: [
            { pickup: 'Cape Town CBD', dropoff: 'Airport', bookingCount: Math.floor(totalBookings * 0.2) },
            { pickup: 'Sea Point', dropoff: 'Cape Town CBD', bookingCount: Math.floor(totalBookings * 0.15) }
          ]
        });

        await bookingData.save();
      }
      console.log('✅ Created 30 days of BookingAnalytics data');

      // Create sample RevenueAnalytics data for the last 30 days
      for (let i = 0; i < 30; i++) {
        const date = new Date(Date.now() - i * 24 * 60 * 60 * 1000);
        const totalRevenue = 5000 + Math.random() * 10000;
        const bookingRevenue = totalRevenue * 0.85;
        const corporateRevenue = totalRevenue * 0.12;
        const otherRevenue = totalRevenue * 0.03;
        const refunds = totalRevenue * (0.02 + Math.random() * 0.03);
        const commissions = totalRevenue * 0.05;
        const driverPayouts = bookingRevenue * 0.7;
        const platformFees = totalRevenue * 0.03;

        const revenueData = new RevenueAnalytics({
          date: date,
          totalRevenue: Math.round(totalRevenue * 100) / 100,
          bookingRevenue: Math.round(bookingRevenue * 100) / 100,
          corporateRevenue: Math.round(corporateRevenue * 100) / 100,
          otherRevenue: Math.round(otherRevenue * 100) / 100,
          refunds: Math.round(refunds * 100) / 100,
          commissions: Math.round(commissions * 100) / 100,
          driverPayouts: Math.round(driverPayouts * 100) / 100,
          platformFees: Math.round(platformFees * 100) / 100,
          paymentMethods: {
            card: totalRevenue * 0.6,
            cash: totalRevenue * 0.2,
            wallet: totalRevenue * 0.15,
            corporate: totalRevenue * 0.05
          },
          revenueByRegion: [
            { region: 'Cape Town', amount: totalRevenue * 0.6 },
            { region: 'Johannesburg', amount: totalRevenue * 0.3 },
            { region: 'Durban', amount: totalRevenue * 0.1 }
          ]
        });

        await revenueData.save();
      }
      console.log('✅ Created 30 days of RevenueAnalytics data');

      // Create sample DriverAnalytics data
      for (let i = 0; i < 20; i++) {
        const driverId = new mongoose.Types.ObjectId();
        const date = new Date(Date.now() - Math.floor(Math.random() * 30) * 24 * 60 * 60 * 1000);
        const totalRides = Math.floor(Math.random() * 50) + 10;
        const completedRides = Math.floor(totalRides * (0.85 + Math.random() * 0.1));
        const cancelledRides = totalRides - completedRides;
        const totalEarnings = completedRides * (100 + Math.random() * 100);
        const averageRating = 4.0 + Math.random() * 1.0;

        const driverData = new DriverAnalytics({
          driverId: driverId,
          date: date,
          totalRides: totalRides,
          completedRides: completedRides,
          cancelledRides: cancelledRides,
          totalEarnings: Math.round(totalEarnings * 100) / 100,
          averageRating: Math.round(averageRating * 10) / 10,
          onlineHours: 6 + Math.random() * 6,
          acceptanceRate: 80 + Math.random() * 20,
          averageResponseTime: 1 + Math.random() * 4,
          customerComplaints: Math.floor(Math.random() * 3),
          performance: {
            onTimePickup: 85 + Math.random() * 15,
            customerSatisfaction: 80 + Math.random() * 20,
            completionRate: 85 + Math.random() * 15
          }
        });

        await driverData.save();
      }
      console.log('✅ Created DriverAnalytics data for 20 drivers');

      console.log('🎉 Analytics sample data created successfully!');
    } catch (error) {
      console.error('❌ Error creating Analytics sample data:', error);
      throw error;
    }
  }

  // Run database health check
  async healthCheck() {
    try {
      console.log('🏥 Running Analytics database health check...');

      // Check connection
      if (!this.connection) {
        throw new Error('No database connection');
      }

      // Check database stats
      const stats = await this.connection.connection.db.stats();
      console.log(`📊 Database size: ${(stats.dataSize / 1024 / 1024).toFixed(2)} MB`);
      console.log(`📊 Collections: ${stats.collections}`);
      console.log(`📊 Documents: ${stats.objects || 0}`);

      // Check Analytics collection stats
      const userAnalyticsCount = await UserAnalytics.countDocuments();
      const bookingAnalyticsCount = await BookingAnalytics.countDocuments();
      const revenueAnalyticsCount = await RevenueAnalytics.countDocuments();
      const driverAnalyticsCount = await DriverAnalytics.countDocuments();

      console.log(`📊 UserAnalytics events: ${userAnalyticsCount}`);
      console.log(`📊 BookingAnalytics records: ${bookingAnalyticsCount}`);
      console.log(`📊 RevenueAnalytics records: ${revenueAnalyticsCount}`);
      console.log(`📊 DriverAnalytics records: ${driverAnalyticsCount}`);

      // Check indexes
      const userAnalyticsIndexes = await UserAnalytics.collection.getIndexes();
      const bookingAnalyticsIndexes = await BookingAnalytics.collection.getIndexes();
      const revenueAnalyticsIndexes = await RevenueAnalytics.collection.getIndexes();
      const driverAnalyticsIndexes = await DriverAnalytics.collection.getIndexes();

      console.log(`🔍 UserAnalytics indexes: ${Object.keys(userAnalyticsIndexes).length}`);
      console.log(`🔍 BookingAnalytics indexes: ${Object.keys(bookingAnalyticsIndexes).length}`);
      console.log(`🔍 RevenueAnalytics indexes: ${Object.keys(revenueAnalyticsIndexes).length}`);
      console.log(`🔍 DriverAnalytics indexes: ${Object.keys(driverAnalyticsIndexes).length}`);

      console.log('🎉 Analytics volume health check completed successfully!');
      return true;
    } catch (error) {
      console.error('❌ Analytics database health check failed:', error);
      return false;
    }
  }

  // Close database connection
  async close() {
    try {
      if (this.connection) {
        await mongoose.connection.close();
        console.log('✅ Analytics database connection closed');
      }
    } catch (error) {
      console.error('❌ Error closing Analytics database connection:', error);
    }
  }

  // Full database setup
  async setup(options = {}) {
    const {
      createIndexes = true,
      validateSchema = true,
      createSampleData = false,
      runHealthCheck = true
    } = options;

    try {
      console.log('🚀 Starting Analytics database setup...');

      // Connect to database
      await this.connect();

      // Create indexes
      if (createIndexes) {
        await this.createIndexes();
      }

      // Validate schema
      if (validateSchema) {
        await this.validateSchema();
      }

      // Create sample data
      if (createSampleData) {
        await this.createSampleData();
      }

      // Run health check
      if (runHealthCheck) {
        await this.healthCheck();
      }

      console.log('🎉 Analytics database setup completed successfully!');
    } catch (error) {
      console.error('❌ Analytics database setup failed:', error);
      throw error;
    }
  }
}

// CLI interface
if (require.main === module) {
  const args = process.argv.slice(2);
  const options = {};

  // Parse command line arguments
  if (args.includes('--sample-data')) {
    options.createSampleData = true;
  }
  if (args.includes('--no-indexes')) {
    options.createIndexes = false;
  }
  if (args.includes('--no-validation')) {
    options.validateSchema = false;
  }
  if (args.includes('--no-health-check')) {
    options.runHealthCheck = false;
  }

  const analyticsSetup = new AnalyticsDatabaseSetup();
  
  analyticsSetup.setup(options)
    .then(() => {
      console.log('✅ Analytics setup completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Analytics setup failed:', error);
      process.exit(1);
    });
}

module.exports = AnalyticsDatabaseSetup;
