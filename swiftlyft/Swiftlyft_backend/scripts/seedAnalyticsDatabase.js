const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const {
  UserAnalytics,
  BookingAnalytics,
  RevenueAnalytics,
  DriverAnalytics
} = require('../models/Analytics');

class AnalyticsDatabaseSeeder {
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

      console.log('✅ Connected to MongoDB for Analytics seeding');
      return this.connection;
    } catch (error) {
      console.error('❌ MongoDB connection error:', error);
      throw error;
    }
  }

  // Clear existing data
  async clearData() {
    try {
      console.log('🧹 Clearing existing Analytics data...');
      
      const collections = [
        { name: 'UserAnalytics', model: UserAnalytics },
        { name: 'BookingAnalytics', model: BookingAnalytics },
        { name: 'RevenueAnalytics', model: RevenueAnalytics },
        { name: 'DriverAnalytics', model: DriverAnalytics }
      ];

      for (const collection of collections) {
        const count = await collection.model.countDocuments();
        if (count > 0) {
          await collection.model.deleteMany({});
          console.log(`✅ Cleared ${count} ${collection.name} documents`);
        } else {
          console.log(`ℹ️ No ${collection.name} documents to clear`);
        }
      }
    } catch (error) {
      console.error('❌ Error clearing Analytics data:', error);
      throw error;
    }
  }

  // Generate random data
  generateRandomData() {
    const eventTypes = [
      'app_open', 'app_close', 'booking_started', 'booking_completed',
      'payment_attempt', 'payment_success', 'payment_failed', 'quote_requested',
      'quote_accepted', 'profile_updated', 'location_search', 'driver_rated',
      'support_contacted', 'promotion_viewed', 'loyalty_used'
    ];

    const platforms = ['ios', 'android', 'web'];
    const cities = ['Cape Town', 'Johannesburg', 'Durban', 'Pretoria', 'Port Elizabeth'];
    const vehicleTypes = ['sedan', 'suv', 'luxury', 'van', 'truck', 'motorcycle'];
    const serviceTypes = ['standard', 'premium', 'corporate', 'airport', 'security'];
    const paymentMethods = ['card', 'cash', 'wallet', 'corporate'];
    const regions = ['Cape Town', 'Johannesburg', 'Durban', 'Pretoria', 'Port Elizabeth'];

    const randomEventType = eventTypes[Math.floor(Math.random() * eventTypes.length)];
    const randomPlatform = platforms[Math.floor(Math.random() * platforms.length)];
    const randomCity = cities[Math.floor(Math.random() * cities.length)];
    const randomVehicle = vehicleTypes[Math.floor(Math.random() * vehicleTypes.length)];
    const randomService = serviceTypes[Math.floor(Math.random() * serviceTypes.length)];
    const randomPayment = paymentMethods[Math.floor(Math.random() * paymentMethods.length)];
    const randomRegion = regions[Math.floor(Math.random() * regions.length)];

    return {
      eventType: randomEventType,
      platform: randomPlatform,
      city: randomCity,
      vehicle: randomVehicle,
      service: randomService,
      payment: randomPayment,
      region: randomRegion
    };
  }

  // Generate realistic event data based on event type
  generateEventData(eventType) {
    const eventDataTemplates = {
      'app_open': {
        screen: 'home',
        source: ['push_notification', 'direct', 'deep_link'][Math.floor(Math.random() * 3)]
      },
      'app_close': {
        session_duration: Math.floor(Math.random() * 3600) + 60, // 1 min to 1 hour
        screens_viewed: Math.floor(Math.random() * 10) + 1
      },
      'booking_started': {
        pickupLocation: `${Math.floor(Math.random() * 999) + 1} Street, Cape Town`,
        dropoffLocation: `${Math.floor(Math.random() * 999) + 1} Avenue, Cape Town`,
        estimatedPrice: Math.floor(Math.random() * 300) + 50,
        vehicleType: ['sedan', 'suv', 'luxury'][Math.floor(Math.random() * 3)]
      },
      'booking_completed': {
        actualPrice: Math.floor(Math.random() * 300) + 50,
        duration: Math.floor(Math.random() * 120) + 15, // 15 min to 2 hours
        distance: Math.floor(Math.random() * 50) + 5 // 5-55 km
      },
      'payment_attempt': {
        amount: Math.floor(Math.random() * 300) + 50,
        paymentMethod: ['card', 'cash', 'wallet'][Math.floor(Math.random() * 3)]
      },
      'payment_success': {
        amount: Math.floor(Math.random() * 300) + 50,
        paymentMethod: ['card', 'cash', 'wallet'][Math.floor(Math.random() * 3)],
        transactionId: `txn_${Math.random().toString(36).substr(2, 9)}`
      },
      'payment_failed': {
        amount: Math.floor(Math.random() * 300) + 50,
        paymentMethod: ['card', 'cash', 'wallet'][Math.floor(Math.random() * 3)],
        reason: ['insufficient_funds', 'card_declined', 'network_error'][Math.floor(Math.random() * 3)]
      },
      'quote_requested': {
        pickupLocation: `${Math.floor(Math.random() * 999) + 1} Street, Cape Town`,
        dropoffLocation: `${Math.floor(Math.random() * 999) + 1} Avenue, Cape Town`,
        vehicleType: ['sedan', 'suv', 'luxury'][Math.floor(Math.random() * 3)]
      },
      'quote_accepted': {
        price: Math.floor(Math.random() * 300) + 50,
        vehicleType: ['sedan', 'suv', 'luxury'][Math.floor(Math.random() * 3)]
      },
      'profile_updated': {
        fields: ['name', 'phone', 'address', 'payment_method'][Math.floor(Math.random() * 4)]
      },
      'location_search': {
        query: `${Math.floor(Math.random() * 999) + 1} Street, Cape Town`,
        results_count: Math.floor(Math.random() * 20) + 1
      },
      'driver_rated': {
        rating: Math.floor(Math.random() * 5) + 1,
        comment: Math.random() > 0.5 ? 'Great service!' : null
      },
      'support_contacted': {
        issue_type: ['booking', 'payment', 'account', 'technical'][Math.floor(Math.random() * 4)],
        priority: ['low', 'medium', 'high'][Math.floor(Math.random() * 3)]
      },
      'promotion_viewed': {
        promotion_id: `promo_${Math.random().toString(36).substr(2, 9)}`,
        discount_percentage: Math.floor(Math.random() * 50) + 5
      },
      'loyalty_used': {
        reward_type: ['discount', 'free_ride', 'upgrade'][Math.floor(Math.random() * 3)],
        points_used: Math.floor(Math.random() * 1000) + 100
      }
    };

    return eventDataTemplates[eventType] || {};
  }

  // Generate realistic location data
  generateLocationData() {
    const cities = [
      { name: 'Cape Town', lat: -33.9249, lng: 18.4241 },
      { name: 'Johannesburg', lat: -26.2041, lng: 28.0473 },
      { name: 'Durban', lat: -29.8587, lng: 31.0218 },
      { name: 'Pretoria', lat: -25.7479, lng: 28.2293 },
      { name: 'Port Elizabeth', lat: -33.9608, lng: 25.6022 }
    ];

    const randomCity = cities[Math.floor(Math.random() * cities.length)];
    const latVariation = (Math.random() - 0.5) * 0.1; // ±0.05 degrees
    const lngVariation = (Math.random() - 0.5) * 0.1;

    return {
      latitude: randomCity.lat + latVariation,
      longitude: randomCity.lng + lngVariation,
      address: `${Math.floor(Math.random() * 999) + 1} ${randomCity.name} Street, ${randomCity.name}, South Africa`
    };
  }

  // Generate device info
  generateDeviceInfo() {
    const devices = [
      { platform: 'ios', version: '15.0', deviceId: 'iPhone_13_Pro' },
      { platform: 'ios', version: '14.8', deviceId: 'iPhone_12' },
      { platform: 'android', version: '12.0', deviceId: 'Samsung_Galaxy_S21' },
      { platform: 'android', version: '11.0', deviceId: 'Google_Pixel_6' },
      { platform: 'web', version: '2.0.0', deviceId: 'Chrome_Browser' },
      { platform: 'web', version: '2.0.0', deviceId: 'Safari_Browser' }
    ];

    return devices[Math.floor(Math.random() * devices.length)];
  }

  // Create UserAnalytics events
  async createUserAnalyticsEvents(count = 1000) {
    try {
      console.log(`📊 Creating ${count} UserAnalytics events...`);
      
      const events = [];
      const userIds = Array.from({ length: 50 }, () => new mongoose.Types.ObjectId());
      const sessionIds = Array.from({ length: 100 }, (_, i) => `session_${i + 1}`);
      
      for (let i = 0; i < count; i++) {
        const randomData = this.generateRandomData();
        const userId = userIds[Math.floor(Math.random() * userIds.length)];
        const sessionId = sessionIds[Math.floor(Math.random() * sessionIds.length)];
        const timestamp = new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000); // Last 30 days
        
        events.push({
          userId: userId,
          eventType: randomData.eventType,
          eventData: this.generateEventData(randomData.eventType),
          sessionId: sessionId,
          deviceInfo: this.generateDeviceInfo(),
          location: this.generateLocationData(),
          timestamp: timestamp
        });
      }

      // Insert in batches to avoid memory issues
      const batchSize = 100;
      for (let i = 0; i < events.length; i += batchSize) {
        const batch = events.slice(i, i + batchSize);
        await UserAnalytics.insertMany(batch);
        console.log(`✅ Created UserAnalytics batch ${Math.floor(i / batchSize) + 1}: ${batch.length} events`);
      }

      return events.length;
    } catch (error) {
      console.error('❌ Error creating UserAnalytics events:', error);
      throw error;
    }
  }

  // Create BookingAnalytics data
  async createBookingAnalyticsData(days = 90) {
    try {
      console.log(`📊 Creating ${days} days of BookingAnalytics data...`);
      
      const analytics = [];
      
      for (let i = 0; i < days; i++) {
        const date = new Date(Date.now() - i * 24 * 60 * 60 * 1000);
        const totalBookings = Math.floor(Math.random() * 200) + 50;
        const completedBookings = Math.floor(totalBookings * (0.85 + Math.random() * 0.1));
        const cancelledBookings = totalBookings - completedBookings;
        const averageBookingValue = 100 + Math.random() * 200;
        const totalRevenue = completedBookings * averageBookingValue;
        
        // Generate vehicle type breakdown
        const vehicleBreakdown = {
          sedan: Math.floor(totalBookings * (0.3 + Math.random() * 0.2)),
          suv: Math.floor(totalBookings * (0.25 + Math.random() * 0.15)),
          luxury: Math.floor(totalBookings * (0.15 + Math.random() * 0.1)),
          van: Math.floor(totalBookings * (0.1 + Math.random() * 0.1)),
          truck: Math.floor(totalBookings * (0.05 + Math.random() * 0.05)),
          motorcycle: Math.floor(totalBookings * (0.02 + Math.random() * 0.03))
        };

        // Generate service type breakdown
        const serviceBreakdown = {
          standard: Math.floor(totalBookings * (0.6 + Math.random() * 0.2)),
          premium: Math.floor(totalBookings * (0.15 + Math.random() * 0.1)),
          corporate: Math.floor(totalBookings * (0.1 + Math.random() * 0.1)),
          airport: Math.floor(totalBookings * (0.05 + Math.random() * 0.05)),
          security: Math.floor(totalBookings * (0.02 + Math.random() * 0.03))
        };

        // Generate peak hours
        const peakHours = Array.from({ length: 24 }, (_, hour) => ({
          hour: hour,
          bookingCount: hour >= 6 && hour <= 22 ? Math.floor(Math.random() * 20) + 5 : Math.floor(Math.random() * 5)
        }));

        // Generate popular routes
        const routes = [
          { pickup: 'Cape Town CBD', dropoff: 'Airport', bookingCount: Math.floor(totalBookings * 0.15) },
          { pickup: 'Sea Point', dropoff: 'Cape Town CBD', bookingCount: Math.floor(totalBookings * 0.12) },
          { pickup: 'Camps Bay', dropoff: 'Cape Town CBD', bookingCount: Math.floor(totalBookings * 0.1) },
          { pickup: 'Table View', dropoff: 'Cape Town CBD', bookingCount: Math.floor(totalBookings * 0.08) }
        ];

        analytics.push({
          date: date,
          totalBookings: totalBookings,
          completedBookings: completedBookings,
          cancelledBookings: cancelledBookings,
          averageBookingValue: Math.round(averageBookingValue * 100) / 100,
          totalRevenue: Math.round(totalRevenue * 100) / 100,
          bookingsByVehicleType: vehicleBreakdown,
          bookingsByServiceType: serviceBreakdown,
          peakHours: peakHours,
          popularRoutes: routes
        });
      }

      await BookingAnalytics.insertMany(analytics);
      console.log(`✅ Created ${analytics.length} BookingAnalytics records`);
      
      return analytics.length;
    } catch (error) {
      console.error('❌ Error creating BookingAnalytics data:', error);
      throw error;
    }
  }

  // Create RevenueAnalytics data
  async createRevenueAnalyticsData(days = 90) {
    try {
      console.log(`📊 Creating ${days} days of RevenueAnalytics data...`);
      
      const analytics = [];
      
      for (let i = 0; i < days; i++) {
        const date = new Date(Date.now() - i * 24 * 60 * 60 * 1000);
        const totalRevenue = 5000 + Math.random() * 15000;
        const bookingRevenue = totalRevenue * (0.8 + Math.random() * 0.1);
        const corporateRevenue = totalRevenue * (0.1 + Math.random() * 0.1);
        const otherRevenue = totalRevenue * (0.02 + Math.random() * 0.03);
        const refunds = totalRevenue * (0.01 + Math.random() * 0.03);
        const commissions = totalRevenue * (0.04 + Math.random() * 0.02);
        const driverPayouts = bookingRevenue * (0.65 + Math.random() * 0.1);
        const platformFees = totalRevenue * (0.02 + Math.random() * 0.02);

        // Generate payment method breakdown
        const paymentBreakdown = {
          card: totalRevenue * (0.5 + Math.random() * 0.2),
          cash: totalRevenue * (0.2 + Math.random() * 0.1),
          wallet: totalRevenue * (0.15 + Math.random() * 0.1),
          corporate: totalRevenue * (0.05 + Math.random() * 0.05)
        };

        // Generate regional breakdown
        const regions = [
          { region: 'Cape Town', amount: totalRevenue * (0.4 + Math.random() * 0.2) },
          { region: 'Johannesburg', amount: totalRevenue * (0.25 + Math.random() * 0.15) },
          { region: 'Durban', amount: totalRevenue * (0.15 + Math.random() * 0.1) },
          { region: 'Pretoria', amount: totalRevenue * (0.1 + Math.random() * 0.1) },
          { region: 'Port Elizabeth', amount: totalRevenue * (0.05 + Math.random() * 0.05) }
        ];

        analytics.push({
          date: date,
          totalRevenue: Math.round(totalRevenue * 100) / 100,
          bookingRevenue: Math.round(bookingRevenue * 100) / 100,
          corporateRevenue: Math.round(corporateRevenue * 100) / 100,
          otherRevenue: Math.round(otherRevenue * 100) / 100,
          refunds: Math.round(refunds * 100) / 100,
          commissions: Math.round(commissions * 100) / 100,
          driverPayouts: Math.round(driverPayouts * 100) / 100,
          platformFees: Math.round(platformFees * 100) / 100,
          paymentMethods: paymentBreakdown,
          revenueByRegion: regions
        });
      }

      await RevenueAnalytics.insertMany(analytics);
      console.log(`✅ Created ${analytics.length} RevenueAnalytics records`);
      
      return analytics.length;
    } catch (error) {
      console.error('❌ Error creating RevenueAnalytics data:', error);
      throw error;
    }
  }

  // Create DriverAnalytics data
  async createDriverAnalyticsData(driverCount = 100) {
    try {
      console.log(`📊 Creating DriverAnalytics data for ${driverCount} drivers...`);
      
      const analytics = [];
      const driverIds = Array.from({ length: driverCount }, () => new mongoose.Types.ObjectId());
      
      for (const driverId of driverIds) {
        // Generate data for the last 30 days
        for (let i = 0; i < 30; i++) {
          const date = new Date(Date.now() - i * 24 * 60 * 60 * 1000);
          const totalRides = Math.floor(Math.random() * 20) + 5;
          const completedRides = Math.floor(totalRides * (0.8 + Math.random() * 0.15));
          const cancelledRides = totalRides - completedRides;
          const totalEarnings = completedRides * (80 + Math.random() * 120);
          const averageRating = 3.5 + Math.random() * 1.5;
          const onlineHours = 4 + Math.random() * 8;
          const acceptanceRate = 70 + Math.random() * 25;
          const averageResponseTime = 1 + Math.random() * 5;

          analytics.push({
            driverId: driverId,
            date: date,
            totalRides: totalRides,
            completedRides: completedRides,
            cancelledRides: cancelledRides,
            totalEarnings: Math.round(totalEarnings * 100) / 100,
            averageRating: Math.round(averageRating * 10) / 10,
            onlineHours: Math.round(onlineHours * 10) / 10,
            acceptanceRate: Math.round(acceptanceRate * 10) / 10,
            averageResponseTime: Math.round(averageResponseTime * 10) / 10,
            customerComplaints: Math.floor(Math.random() * 3),
            performance: {
              onTimePickup: Math.round((80 + Math.random() * 15) * 10) / 10,
              customerSatisfaction: Math.round((75 + Math.random() * 20) * 10) / 10,
              completionRate: Math.round((80 + Math.random() * 15) * 10) / 10
            }
          });
        }
      }

      // Insert in batches
      const batchSize = 500;
      for (let i = 0; i < analytics.length; i += batchSize) {
        const batch = analytics.slice(i, i + batchSize);
        await DriverAnalytics.insertMany(batch);
        console.log(`✅ Created DriverAnalytics batch ${Math.floor(i / batchSize) + 1}: ${batch.length} records`);
      }

      console.log(`✅ Created DriverAnalytics data for ${driverCount} drivers`);
      return analytics.length;
    } catch (error) {
      console.error('❌ Error creating DriverAnalytics data:', error);
      throw error;
    }
  }

  // Print summary statistics
  async printSummary() {
    try {
      console.log('\n📊 Analytics Database Summary:');
      
      const userAnalyticsCount = await UserAnalytics.countDocuments();
      const bookingAnalyticsCount = await BookingAnalytics.countDocuments();
      const revenueAnalyticsCount = await RevenueAnalytics.countDocuments();
      const driverAnalyticsCount = await DriverAnalytics.countDocuments();
      
      console.log(`📈 UserAnalytics events: ${userAnalyticsCount}`);
      console.log(`📅 BookingAnalytics records: ${bookingAnalyticsCount}`);
      console.log(`💰 RevenueAnalytics records: ${revenueAnalyticsCount}`);
      console.log(`🚗 DriverAnalytics records: ${driverAnalyticsCount}`);

      // Event type breakdown
      const eventTypeStats = await UserAnalytics.aggregate([
        { $group: { _id: '$eventType', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]);

      console.log('\n📊 Event Type Breakdown:');
      eventTypeStats.forEach(stat => {
        console.log(`  ${stat._id}: ${stat.count}`);
      });

      // Revenue summary
      const revenueSummary = await RevenueAnalytics.aggregate([
        { $group: { _id: null, totalRevenue: { $sum: '$totalRevenue' } } }
      ]);

      console.log('\n💰 Total Revenue:');
      console.log(`  R${(revenueSummary[0]?.totalRevenue || 0).toLocaleString()}`);

      // Driver performance summary
      const driverSummary = await DriverAnalytics.aggregate([
        { $group: { _id: null, avgRating: { $avg: '$averageRating' }, totalEarnings: { $sum: '$totalEarnings' } } }
      ]);

      console.log('\n🚗 Driver Performance Summary:');
      console.log(`  Average Rating: ${Math.round((driverSummary[0]?.avgRating || 0) * 10) / 10}`);
      console.log(`  Total Driver Earnings: R${(driverSummary[0]?.totalEarnings || 0).toLocaleString()}`);

    } catch (error) {
      console.error('❌ Error printing Analytics summary:', error);
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

  // Full seeding process
  async run(options = {}) {
    const {
      clearData = false,
      userEvents = 1000,
      bookingDays = 90,
      revenueDays = 90,
      driverCount = 100
    } = options;

    try {
      console.log('🚀 Starting Analytics database seeding...');

      // Connect to database
      await this.connect();

      // Clear existing data if requested
      if (clearData) {
        await this.clearData();
      }

      // Create Analytics data
      await this.createUserAnalyticsEvents(userEvents);
      await this.createBookingAnalyticsData(bookingDays);
      await this.createRevenueAnalyticsData(revenueDays);
      await this.createDriverAnalyticsData(driverCount);

      // Print summary
      await this.printSummary();

      console.log('🎉 Analytics database seeding completed successfully!');
    } catch (error) {
      console.error('❌ Analytics database seeding failed:', error);
      throw error;
    }
  }
}

// CLI interface
if (require.main === module) {
  const args = process.argv.slice(2);
  const options = {};

  // Parse command line arguments
  if (args.includes('--clear')) {
    options.clearData = true;
  }
  
  const userEventsArg = args.find(arg => arg.startsWith('--user-events='));
  if (userEventsArg) {
    options.userEvents = parseInt(userEventsArg.split('=')[1]) || 1000;
  }

  const bookingDaysArg = args.find(arg => arg.startsWith('--booking-days='));
  if (bookingDaysArg) {
    options.bookingDays = parseInt(bookingDaysArg.split('=')[1]) || 90;
  }

  const revenueDaysArg = args.find(arg => arg.startsWith('--revenue-days='));
  if (revenueDaysArg) {
    options.revenueDays = parseInt(revenueDaysArg.split('=')[1]) || 90;
  }

  const driverCountArg = args.find(arg => arg.startsWith('--driver-count='));
  if (driverCountArg) {
    options.driverCount = parseInt(driverCountArg.split('=')[1]) || 100;
  }

  const seeder = new AnalyticsDatabaseSeeder();
  
  seeder.run(options)
    .then(() => {
      console.log('✅ Analytics seeding completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Analytics seeding failed:', error);
      process.exit(1);
    });
}

module.exports = AnalyticsDatabaseSeeder;
