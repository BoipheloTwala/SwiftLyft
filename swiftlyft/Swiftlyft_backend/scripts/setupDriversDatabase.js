const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Driver = require('../models/Driver');

class DriversDatabaseSetup {
  constructor() {
    this.connection = null;
  }

  // Connect to MongoDB
  async connect() {
    try {
      const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_drivers';
      
      this.connection = await mongoose.connect(mongoUri, {
        useNewUrlParser: true,
        useUnifiedTopology: true,
      });

      console.log('✅ Connected to MongoDB for Drivers');
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
      console.log('🔍 Creating Drivers database indexes...');

      // Core identifier indexes
      await Driver.collection.createIndex({ "driverId": 1 }, { unique: true });
      console.log('✅ Created driverId index');

      await Driver.collection.createIndex({ "licenseNumber": 1 }, { unique: true });
      console.log('✅ Created licenseNumber index');

      await Driver.collection.createIndex({ "vehicleInfo.licensePlate": 1 }, { unique: true });
      console.log('✅ Created licensePlate index');

      // User relationship index
      await Driver.collection.createIndex({ "userId": 1 });
      console.log('✅ Created userId index');

      // Geographic index for location-based queries
      await Driver.collection.createIndex({ "currentLocation.coordinates": "2dsphere" });
      console.log('✅ Created currentLocation 2dsphere index');

      // Availability and status indexes
      await Driver.collection.createIndex({ "availability.status": 1 });
      console.log('✅ Created availability.status index');

      await Driver.collection.createIndex({ "status": 1 });
      console.log('✅ Created status index');

      // Vehicle type and performance indexes
      await Driver.collection.createIndex({ "vehicleInfo.vehicleType": 1 });
      console.log('✅ Created vehicleType index');

      await Driver.collection.createIndex({ "performance.rating": 1 });
      console.log('✅ Created performance.rating index');

      // Current booking index
      await Driver.collection.createIndex({ "currentBookingId": 1 });
      console.log('✅ Created currentBookingId index');

      // Verification status indexes
      await Driver.collection.createIndex({ "verificationStatus.backgroundCheck": 1 });
      console.log('✅ Created backgroundCheck index');

      await Driver.collection.createIndex({ "verificationStatus.documentsVerified": 1 });
      console.log('✅ Created documentsVerified index');

      await Driver.collection.createIndex({ "verificationStatus.vehicleInspected": 1 });
      console.log('✅ Created vehicleInspected index');

      // Time-based indexes
      await Driver.collection.createIndex({ "createdAt": -1 });
      console.log('✅ Created createdAt index');

      await Driver.collection.createIndex({ "updatedAt": -1 });
      console.log('✅ Created updatedAt index');

      // License expiry index for monitoring
      await Driver.collection.createIndex({ "licenseExpiry": 1 });
      console.log('✅ Created licenseExpiry index');

      // Compound indexes for complex queries
      await Driver.collection.createIndex({ 
        "availability.status": 1, 
        "status": 1, 
        "currentLocation.coordinates": "2dsphere" 
      });
      console.log('✅ Created availability + status + location compound index');

      await Driver.collection.createIndex({ 
        "status": 1, 
        "vehicleInfo.vehicleType": 1, 
        "performance.rating": 1 
      });
      console.log('✅ Created status + vehicleType + rating compound index');

      await Driver.collection.createIndex({ 
        "verificationStatus.backgroundCheck": 1, 
        "verificationStatus.documentsVerified": 1, 
        "verificationStatus.vehicleInspected": 1 
      });
      console.log('✅ Created verification status compound index');

      // Performance and earnings indexes
      await Driver.collection.createIndex({ "performance.totalEarnings": -1 });
      console.log('✅ Created totalEarnings index');

      await Driver.collection.createIndex({ "performance.totalRides": -1 });
      console.log('✅ Created totalRides index');

      await Driver.collection.createIndex({ "performance.completedRides": -1 });
      console.log('✅ Created completedRides index');

      // Working hours index
      await Driver.collection.createIndex({ "availability.workingHours.start": 1 });
      console.log('✅ Created workingHours.start index');

      await Driver.collection.createIndex({ "availability.workingHours.end": 1 });
      console.log('✅ Created workingHours.end index');

      // Text search index for driver information
      await Driver.collection.createIndex({ 
        "vehicleInfo.make": "text", 
        "vehicleInfo.model": "text", 
        "vehicleInfo.color": "text" 
      });
      console.log('✅ Created text search index');

      console.log('🎉 All Drivers indexes created successfully!');
    } catch (error) {
      console.error('❌ Error creating Drivers indexes:', error);
      throw error;
    }
  }

  // Validate database schema
  async validateSchema() {
    try {
      console.log('🔍 Validating Drivers database schema...');

      // Test Driver creation with validation
      const testDriver = new Driver({
        userId: new mongoose.Types.ObjectId(),
        driverId: 'DRV-' + Date.now().toString(36).slice(-4).toUpperCase(),
        licenseNumber: 'LIC' + Date.now().toString().slice(-8),
        licenseExpiry: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // 1 year from now
        vehicleInfo: {
          make: 'Toyota',
          model: 'Camry',
          year: 2022,
          color: 'White',
          licensePlate: 'ABC' + Date.now().toString().slice(-3),
          vehicleType: 'sedan',
          passengerCapacity: 4,
          hasAC: true,
          features: ['wifi', 'leather_seats', 'tinted_windows']
        },
        documents: {
          licensePhoto: 'https://example.com/license.jpg',
          vehicleRegistration: 'https://example.com/registration.pdf',
          vehicleInsurance: 'https://example.com/insurance.pdf',
          profilePhoto: 'https://example.com/profile.jpg'
        },
        bankDetails: {
          accountHolder: 'John Driver',
          accountNumber: '1234567890',
          bankName: 'Standard Bank',
          branchCode: '051001'
        },
        currentLocation: {
          coordinates: {
            latitude: -33.9249,
            longitude: 18.4241
          },
          address: 'Cape Town, South Africa',
          lastUpdated: new Date()
        },
        availability: {
          status: 'online',
          availableUntil: new Date(Date.now() + 8 * 60 * 60 * 1000), // 8 hours from now
          workingHours: {
            start: '06:00',
            end: '22:00'
          }
        },
        performance: {
          rating: 4.8,
          totalRides: 150,
          completedRides: 145,
          cancelledRides: 5,
          totalEarnings: 25000.00,
          averageResponseTime: 3.5,
          onTimePickup: 95,
          customerSatisfaction: 98
        },
        currentBookingId: null,
        status: 'active',
        verificationStatus: {
          backgroundCheck: true,
          documentsVerified: true,
          vehicleInspected: true
        },
        emergencyContact: {
          name: 'Jane Driver',
          phone: '+27123456789',
          relationship: 'spouse'
        }
      });

      // Validate the document
      await testDriver.validate();
      console.log('✅ Driver schema validation passed');

      // Test virtual fields
      console.log('🔍 Testing virtual fields...');
      console.log(`Is available: ${testDriver.isAvailable}`);

      // Test instance methods
      console.log('🔍 Testing instance methods...');
      
      // Test location update
      await testDriver.updateLocation(-33.9250, 18.4242, 'Updated Location');
      console.log(`✅ Location update method works: ${testDriver.currentLocation.coordinates.latitude}, ${testDriver.currentLocation.coordinates.longitude}`);

      // Test availability update
      await testDriver.updateAvailability('busy', new Date(Date.now() + 2 * 60 * 60 * 1000));
      console.log(`✅ Availability update method works: ${testDriver.availability.status}`);

      // Test performance update
      await testDriver.updatePerformance({
        rating: 5.0,
        earnings: 150.00,
        completed: true
      });
      console.log(`✅ Performance update method works: rating=${testDriver.performance.rating}, earnings=${testDriver.performance.totalEarnings}`);

      console.log('🎉 Drivers schema validation completed successfully!');
    } catch (error) {
      console.error('❌ Drivers schema validation failed:', error);
      throw error;
    }
  }

  // Create sample data for testing
  async createSampleData() {
    try {
      console.log('🌱 Creating Drivers sample data...');

      // Check if sample data already exists
      const existingDrivers = await Driver.countDocuments();
      if (existingDrivers > 0) {
        console.log('⚠️ Drivers sample data already exists, skipping...');
        return;
      }

      // Create sample drivers
      const sampleDrivers = [
        {
          userId: new mongoose.Types.ObjectId(),
          driverId: 'DRV-' + Date.now().toString(36).slice(-4).toUpperCase(),
          licenseNumber: 'LIC' + Date.now().toString().slice(-8),
          licenseExpiry: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
          vehicleInfo: {
            make: 'Toyota',
            model: 'Camry',
            year: 2022,
            color: 'White',
            licensePlate: 'CA' + Math.floor(Math.random() * 9000 + 1000),
            vehicleType: 'sedan',
            passengerCapacity: 4,
            hasAC: true,
            features: ['wifi', 'leather_seats', 'tinted_windows']
          },
          documents: {
            licensePhoto: 'https://example.com/license1.jpg',
            vehicleRegistration: 'https://example.com/registration1.pdf',
            vehicleInsurance: 'https://example.com/insurance1.pdf',
            profilePhoto: 'https://example.com/profile1.jpg'
          },
          bankDetails: {
            accountHolder: 'John Driver',
            accountNumber: '1234567890',
            bankName: 'Standard Bank',
            branchCode: '051001'
          },
          currentLocation: {
            coordinates: {
              latitude: -33.9249,
              longitude: 18.4241
            },
            address: 'Cape Town, South Africa',
            lastUpdated: new Date()
          },
          availability: {
            status: 'online',
            availableUntil: new Date(Date.now() + 8 * 60 * 60 * 1000),
            workingHours: {
              start: '06:00',
              end: '22:00'
            }
          },
          performance: {
            rating: 4.8,
            totalRides: 150,
            completedRides: 145,
            cancelledRides: 5,
            totalEarnings: 25000.00,
            averageResponseTime: 3.5,
            onTimePickup: 95,
            customerSatisfaction: 98
          },
          currentBookingId: null,
          status: 'active',
          verificationStatus: {
            backgroundCheck: true,
            documentsVerified: true,
            vehicleInspected: true
          },
          emergencyContact: {
            name: 'Jane Driver',
            phone: '+27123456789',
            relationship: 'spouse'
          }
        },
        {
          userId: new mongoose.Types.ObjectId(),
          driverId: 'DRV-' + (Date.now() + 1).toString(36).slice(-4).toUpperCase(),
          licenseNumber: 'LIC' + (Date.now() + 1).toString().slice(-8),
          licenseExpiry: new Date(Date.now() + 300 * 24 * 60 * 60 * 1000),
          vehicleInfo: {
            make: 'BMW',
            model: 'X5',
            year: 2023,
            color: 'Black',
            licensePlate: 'GP' + Math.floor(Math.random() * 9000 + 1000),
            vehicleType: 'suv',
            passengerCapacity: 7,
            hasAC: true,
            features: ['wifi', 'leather_seats', 'tinted_windows', 'premium_sound']
          },
          documents: {
            licensePhoto: 'https://example.com/license2.jpg',
            vehicleRegistration: 'https://example.com/registration2.pdf',
            vehicleInsurance: 'https://example.com/insurance2.pdf',
            profilePhoto: 'https://example.com/profile2.jpg'
          },
          bankDetails: {
            accountHolder: 'Mike Johnson',
            accountNumber: '2345678901',
            bankName: 'FNB',
            branchCode: '250655'
          },
          currentLocation: {
            coordinates: {
              latitude: -26.2041,
              longitude: 28.0473
            },
            address: 'Johannesburg, South Africa',
            lastUpdated: new Date()
          },
          availability: {
            status: 'online',
            availableUntil: new Date(Date.now() + 6 * 60 * 60 * 1000),
            workingHours: {
              start: '07:00',
              end: '23:00'
            }
          },
          performance: {
            rating: 4.9,
            totalRides: 200,
            completedRides: 195,
            cancelledRides: 5,
            totalEarnings: 35000.00,
            averageResponseTime: 2.8,
            onTimePickup: 98,
            customerSatisfaction: 99
          },
          currentBookingId: null,
          status: 'active',
          verificationStatus: {
            backgroundCheck: true,
            documentsVerified: true,
            vehicleInspected: true
          },
          emergencyContact: {
            name: 'Sarah Johnson',
            phone: '+27987654321',
            relationship: 'sister'
          }
        },
        {
          userId: new mongoose.Types.ObjectId(),
          driverId: 'DRV-' + (Date.now() + 2).toString(36).slice(-4).toUpperCase(),
          licenseNumber: 'LIC' + (Date.now() + 2).toString().slice(-8),
          licenseExpiry: new Date(Date.now() + 200 * 24 * 60 * 60 * 1000),
          vehicleInfo: {
            make: 'Mercedes-Benz',
            model: 'E-Class',
            year: 2021,
            color: 'Silver',
            licensePlate: 'KZN' + Math.floor(Math.random() * 9000 + 1000),
            vehicleType: 'luxury',
            passengerCapacity: 4,
            hasAC: true,
            features: ['wifi', 'leather_seats', 'tinted_windows', 'premium_sound', 'massage_seats']
          },
          documents: {
            licensePhoto: 'https://example.com/license3.jpg',
            vehicleRegistration: 'https://example.com/registration3.pdf',
            vehicleInsurance: 'https://example.com/insurance3.pdf',
            profilePhoto: 'https://example.com/profile3.jpg'
          },
          bankDetails: {
            accountHolder: 'David Brown',
            accountNumber: '3456789012',
            bankName: 'Absa',
            branchCode: '632005'
          },
          currentLocation: {
            coordinates: {
              latitude: -29.8587,
              longitude: 31.0218
            },
            address: 'Durban, South Africa',
            lastUpdated: new Date()
          },
          availability: {
            status: 'offline',
            availableUntil: null,
            workingHours: {
              start: '08:00',
              end: '20:00'
            }
          },
          performance: {
            rating: 4.7,
            totalRides: 120,
            completedRides: 115,
            cancelledRides: 5,
            totalEarnings: 22000.00,
            averageResponseTime: 4.2,
            onTimePickup: 92,
            customerSatisfaction: 96
          },
          currentBookingId: null,
          status: 'approved',
          verificationStatus: {
            backgroundCheck: true,
            documentsVerified: true,
            vehicleInspected: false
          },
          emergencyContact: {
            name: 'Lisa Brown',
            phone: '+27345678901',
            relationship: 'wife'
          }
        },
        {
          userId: new mongoose.Types.ObjectId(),
          driverId: 'DRV-' + (Date.now() + 3).toString(36).slice(-4).toUpperCase(),
          licenseNumber: 'LIC' + (Date.now() + 3).toString().slice(-8),
          licenseExpiry: new Date(Date.now() + 180 * 24 * 60 * 60 * 1000),
          vehicleInfo: {
            make: 'Ford',
            model: 'Transit',
            year: 2020,
            color: 'Blue',
            licensePlate: 'WC' + Math.floor(Math.random() * 9000 + 1000),
            vehicleType: 'van',
            passengerCapacity: 12,
            hasAC: true,
            features: ['wifi', 'air_conditioning', 'comfortable_seats']
          },
          documents: {
            licensePhoto: 'https://example.com/license4.jpg',
            vehicleRegistration: 'https://example.com/registration4.pdf',
            vehicleInsurance: 'https://example.com/insurance4.pdf',
            profilePhoto: 'https://example.com/profile4.jpg'
          },
          bankDetails: {
            accountHolder: 'Robert Wilson',
            accountNumber: '4567890123',
            bankName: 'Nedbank',
            branchCode: '198765'
          },
          currentLocation: {
            coordinates: {
              latitude: -33.9249,
              longitude: 18.4241
            },
            address: 'Cape Town, South Africa',
            lastUpdated: new Date()
          },
          availability: {
            status: 'maintenance',
            availableUntil: new Date(Date.now() + 24 * 60 * 60 * 1000),
            workingHours: {
              start: '05:00',
              end: '21:00'
            }
          },
          performance: {
            rating: 4.5,
            totalRides: 80,
            completedRides: 75,
            cancelledRides: 5,
            totalEarnings: 15000.00,
            averageResponseTime: 5.0,
            onTimePickup: 88,
            customerSatisfaction: 94
          },
          currentBookingId: null,
          status: 'active',
          verificationStatus: {
            backgroundCheck: true,
            documentsVerified: false,
            vehicleInspected: true
          },
          emergencyContact: {
            name: 'Mary Wilson',
            phone: '+27456789012',
            relationship: 'mother'
          }
        },
        {
          userId: new mongoose.Types.ObjectId(),
          driverId: 'DRV-' + (Date.now() + 4).toString(36).slice(-4).toUpperCase(),
          licenseNumber: 'LIC' + (Date.now() + 4).toString().slice(-8),
          licenseExpiry: new Date(Date.now() + 150 * 24 * 60 * 60 * 1000),
          vehicleInfo: {
            make: 'Honda',
            model: 'Civic',
            year: 2023,
            color: 'Red',
            licensePlate: 'FS' + Math.floor(Math.random() * 9000 + 1000),
            vehicleType: 'sedan',
            passengerCapacity: 4,
            hasAC: true,
            features: ['wifi', 'leather_seats', 'tinted_windows', 'premium_sound']
          },
          documents: {
            licensePhoto: 'https://example.com/license5.jpg',
            vehicleRegistration: 'https://example.com/registration5.pdf',
            vehicleInsurance: 'https://example.com/insurance5.pdf',
            profilePhoto: 'https://example.com/profile5.jpg'
          },
          bankDetails: {
            accountHolder: 'James Taylor',
            accountNumber: '5678901234',
            bankName: 'Capitec',
            branchCode: '470010'
          },
          currentLocation: {
            coordinates: {
              latitude: -26.2041,
              longitude: 28.0473
            },
            address: 'Johannesburg, South Africa',
            lastUpdated: new Date()
          },
          availability: {
            status: 'busy',
            availableUntil: new Date(Date.now() + 2 * 60 * 60 * 1000),
            workingHours: {
              start: '06:30',
              end: '22:30'
            }
          },
          performance: {
            rating: 4.6,
            totalRides: 100,
            completedRides: 95,
            cancelledRides: 5,
            totalEarnings: 18000.00,
            averageResponseTime: 3.8,
            onTimePickup: 90,
            customerSatisfaction: 95
          },
          currentBookingId: new mongoose.Types.ObjectId(),
          status: 'active',
          verificationStatus: {
            backgroundCheck: false,
            documentsVerified: true,
            vehicleInspected: true
          },
          emergencyContact: {
            name: 'Emma Taylor',
            phone: '+27567890123',
            relationship: 'girlfriend'
          }
        }
      ];

      // Create drivers
      for (const driverData of sampleDrivers) {
        const driver = new Driver(driverData);
        await driver.save();
        console.log(`✅ Created driver: ${driver.driverId}`);
      }

      console.log('🎉 Drivers sample data created successfully!');
    } catch (error) {
      console.error('❌ Error creating Drivers sample data:', error);
      throw error;
    }
  }

  // Run database health check
  async healthCheck() {
    try {
      console.log('🏥 Running Drivers database health check...');

      // Check connection
      if (!this.connection) {
        throw new Error('No database connection');
      }

      // Check database stats
      const stats = await this.connection.connection.db.stats();
      console.log(`📊 Database size: ${(stats.dataSize / 1024 / 1024).toFixed(2)} MB`);
      console.log(`📊 Collections: ${stats.collections}`);
      console.log(`📊 Documents: ${stats.objects || 0}`);

      // Check Drivers collection stats
      const driverCount = await Driver.countDocuments();
      const activeDrivers = await Driver.countDocuments({ status: 'active' });
      const onlineDrivers = await Driver.countDocuments({ 'availability.status': 'online' });
      const approvedDrivers = await Driver.countDocuments({ status: 'approved' });
      const pendingDrivers = await Driver.countDocuments({ status: 'pending' });

      console.log(`📊 Total drivers: ${driverCount}`);
      console.log(`📊 Active drivers: ${activeDrivers}`);
      console.log(`📊 Online drivers: ${onlineDrivers}`);
      console.log(`📊 Approved drivers: ${approvedDrivers}`);
      console.log(`📊 Pending drivers: ${pendingDrivers}`);

      // Check indexes
      const indexes = await Driver.collection.getIndexes();
      console.log(`🔍 Indexes: ${Object.keys(indexes).length}`);

      // Check vehicle type distribution
      const vehicleTypeStats = await Driver.aggregate([
        { $group: { _id: '$vehicleInfo.vehicleType', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]);

      console.log('\n🚗 Vehicle--- Type Distribution:');
      vehicleTypeStats.forEach(stat => {
        console.log(`  ${stat._id}: ${stat.count}`);
      });

      // Check status distribution
      const statusStats = await Driver.aggregate([
        { $group: { _id: '$status', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]);

      console.log('\n📊 Status Distribution:');
      statusStats.forEach(stat => {
        console.log(`  ${stat._id}: ${stat.count}`);
      });

      // Check availability distribution
      const availabilityStats = await Driver.aggregate([
        { $group: { _id: '$availability.status', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]);

      console.log('\n🟢 Availability Distribution:');
      availabilityStats.forEach(stat => {
        console.log(`  ${stat._id}: ${stat.count}`);
      });

      // Check average rating
      const ratingStats = await Driver.aggregate([
        { $group: { _id: null, avgRating: { $avg: '$performance.rating' }, totalDrivers: { $sum: 1 } } }
      ]);

      if (ratingStats.length > 0) {
        console.log(`\n⭐ Average Rating: ${ratingStats[0].avgRating.toFixed(2)} (${ratingStats[0].totalDrivers} drivers)`);
      }

      // Check total earnings
      const earningsStats = await Driver.aggregate([
        { $group: { _id: null, totalEarnings: { $sum: '$performance.totalEarnings' } } }
      ]);

      if (earningsStats.length > 0) {
        console.log(`\n💰 Total Earnings: R${earningsStats[0].totalEarnings.toLocaleString()}`);
      }

      // Check verification status
      const verificationStats = await Driver.aggregate([
        { $group: { _id: null, backgroundCheck: { $sum: { $cond: ['$verificationStatus.backgroundCheck', 1, 0] } }, documentsVerified: { $sum: { $cond: ['$verificationStatus.documentsVerified', 1, 0] } }, vehicleInspected: { $sum: { $cond: ['$verificationStatus.vehicleInspected', 1, 0] } } } }
      ]);

      if (verificationStats.length > 0) {
        console.log('\n✅ Verification Status:');
        console.log(`  Background Check: ${verificationStats[0].backgroundCheck}/${driverCount}`);
        console.log(`  Documents Verified: ${verificationStats[0].documentsVerified}/${driverCount}`);
        console.log(`  Vehicle Inspected: ${verificationStats[0].vehicleInspected}/${driverCount}`);
      }

      console.log('🎉 Drivers health check completed successfully!');
      return true;
    } catch (error) {
      console.error('❌ Drivers database health check failed:', error);
      return false;
    }
  }

  // Close database connection
  async close() {
    try {
      if (this.connection) {
        await mongoose.connection.close();
        console.log('✅ Drivers database connection closed');
      }
    } catch (error) {
      console.error('❌ Error closing Drivers database connection:', error);
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
      console.log('🚀 Starting Drivers database setup...');

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

      console.log('🎉 Drivers database setup completed successfully!');
    } catch (error) {
      console.error('❌ Drivers database setup failed:', error);
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

  const driversSetup = new DriversDatabaseSetup();
  
  driversSetup.setup(options)
    .then(() => {
      console.log('✅ Drivers setup completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Drivers setup failed:', error);
      process.exit(1);
    });
}

module.exports = DriversDatabaseSetup;
