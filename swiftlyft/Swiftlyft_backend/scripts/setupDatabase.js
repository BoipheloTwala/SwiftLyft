const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

// Import models
const User = require('../models/User');

class DatabaseSetup {
  constructor() {
    this.connection = null;
  }

  // Connect to MongoDB
  async connect() {
    try {
      const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_users';
      
      this.connection = await mongoose.connect(mongoUri, {
        useNewUrlParser: true,
        useUnifiedTopology: true,
      });

      console.log('✅ Connected to MongoDB');
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
      console.log('🔍 Creating database indexes...');

      // Users collection indexes
      await User.collection.createIndex({ "email": 1 }, { unique: true });
      console.log('✅ Created email index');

      await User.collection.createIndex({ "referralCode": 1 }, { unique: true, sparse: true });
      console.log('✅ Created referralCode index');

      await User.collection.createIndex({ "refreshTokens.token": 1 });
      console.log('✅ Created refreshTokens index');

      await User.collection.createIndex({ "resetPasswordToken": 1 });
      console.log('✅ Created resetPasswordToken index');

      await User.collection.createIndex({ "emailVerificationToken": 1 });
      console.log('✅ Created emailVerificationToken index');

      await User.collection.createIndex({ "phoneVerificationCode": 1 });
      console.log('✅ Created phoneVerificationCode index');

      // Compound indexes for common queries
      await User.collection.createIndex({ "loyaltyTier": 1, "loyaltyPoints": -1 });
      console.log('✅ Created loyalty compound index');

      await User.collection.createIndex({ "isActive": 1, "createdAt": -1 });
      console.log('✅ Created active users compound index');

      await User.collection.createIndex({ "corporateAccount.status": 1 });
      console.log('✅ Created corporate status index');

      await User.collection.createIndex({ "bulkBookings.status": 1, "bulkBookings.createdAt": -1 });
      console.log('✅ Created bulk bookings compound index');

      // Text index for search functionality
      await User.collection.createIndex({ 
        "name": "text", 
        "email": "text", 
        "corporateAccount.companyName": "text" 
      });
      console.log('✅ Created text search index');

      console.log('🎉 All indexes created successfully!');
    } catch (error) {
      console.error('❌ Error creating indexes:', error);
      throw error;
    }
  }

  // Validate database schema
  async validateSchema() {
    try {
      console.log('🔍 Validating database schema...');

      // Test user creation with validation
      const testUser = new User({
        email: 'test@example.com',
        password: 'TestPassword123',
        name: 'Test User',
        phoneNumber: '+27123456789',
        loyaltyTier: 'Bronze',
        loyaltyPoints: 0,
        totalTrips: 0,
        totalSpent: 0,
        savedAddresses: [{
          label: 'Test Address',
          address: '123 Test Street',
          coordinates: {
            latitude: -33.9249,
            longitude: 18.4241
          },
          isDefault: true
        }],
        earnedRewards: [],
        availableRewards: [],
        referrals: [],
        bulkBookings: [],
        isEmailVerified: false,
        isPhoneVerified: false,
        isActive: true,
        refreshTokens: [],
        lastLoginAt: new Date(),
        loginCount: 0,
        notificationSettings: {
          push: true,
          email: true,
          sms: false,
          bookingUpdates: true,
          promotionalOffers: true,
          paymentReminders: true,
          driverMessages: true
        }
      });

      // Validate the document
      await testUser.validate();
      console.log('✅ User schema validation passed');

      // Test virtual fields
      console.log('🔍 Testing virtual fields...');
      console.log(`Points to next tier: ${testUser.pointsToNextTier}`);
      console.log(`Tier progress: ${testUser.tierProgress}`);
      console.log(`Tier discount: ${testUser.tierDiscount}`);
      console.log(`Is corporate user: ${testUser.isCorporateUser}`);

      console.log('🎉 Schema validation completed successfully!');
    } catch (error) {
      console.error('❌ Schema validation failed:', error);
      throw error;
    }
  }

  // Create sample data for testing
  async createSampleData() {
    try {
      console.log('🌱 Creating sample data...');

      // Check if sample data already exists
      const existingUsers = await User.countDocuments();
      if (existingUsers > 0) {
        console.log('⚠️ Sample data already exists, skipping...');
        return;
      }

      // Create sample users
      const sampleUsers = [
        {
          email: 'john.doe@example.com',
          password: 'Password123',
          name: 'John Doe',
          phoneNumber: '+27123456789',
          loyaltyTier: 'Silver',
          loyaltyPoints: 1500,
          totalTrips: 25,
          totalSpent: 2500,
          savedAddresses: [
            {
              label: 'Home',
              address: '123 Main Street, Cape Town, South Africa',
              coordinates: {
                latitude: -33.9249,
                longitude: 18.4241
              },
              isDefault: true
            },
            {
              label: 'Work',
              address: '456 Business District, Cape Town, South Africa',
              coordinates: {
                latitude: -33.9250,
                longitude: 18.4242
              },
              isDefault: false
            }
          ],
          earnedRewards: [
            {
              name: 'Free Ride',
              description: 'One free ride up to R50',
              type: 'free_ride',
              pointsCost: 1000,
              discountPercentage: 0,
              isActive: true,
              expiresAt: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000) // 1 year from now
            }
          ],
          availableRewards: [
            {
              name: '10% Discount',
              description: '10% off your next ride',
              type: 'discount',
              pointsCost: 500,
              discountPercentage: 10,
              isActive: true,
              expiresAt: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000)
            }
          ],
          referrals: [
            {
              referredUserEmail: 'jane.smith@example.com',
              referredUserName: 'Jane Smith',
              status: 'completed',
              earnings: 50,
              createdAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), // 30 days ago
              completedAt: new Date(Date.now() - 25 * 24 * 60 * 60 * 1000) // 25 days ago
            }
          ],
          corporateAccount: {
            companyName: 'Tech Solutions Ltd',
            companyEmail: 'admin@techsolutions.co.za',
            contactPerson: 'John Doe',
            contactPhone: '+27123456789',
            discountPercentage: 15,
            monthlyBudget: 10000,
            usedBudget: 2500,
            status: 'active',
            createdAt: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000), // 90 days ago
            expiresAt: new Date(Date.now() + 275 * 24 * 60 * 60 * 1000), // 275 days from now
            authorizedUsers: []
          },
          bulkBookings: [
            {
              title: 'Corporate Event Transportation',
              description: 'Transportation for company annual meeting',
              items: [
                {
                  vehicleId: new mongoose.Types.ObjectId(),
                  vehicleName: 'Luxury Sedan',
                  quantity: 5,
                  unitPrice: 100,
                  pickupLocation: 'Company Office',
                  dropoffLocation: 'Convention Center',
                  pickupTime: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days from now
                  passengerCount: 4
                }
              ],
              status: 'confirmed',
              totalAmount: 500,
              discountAmount: 75,
              createdAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000), // 10 days ago
              scheduledDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
              specialNotes: 'Please arrive 15 minutes early'
            }
          ],
          isEmailVerified: true,
          isPhoneVerified: true,
          isActive: true,
          refreshTokens: [],
          lastLoginAt: new Date(Date.now() - 2 * 60 * 60 * 1000), // 2 hours ago
          lastLoginIP: '192.168.1.100',
          loginCount: 45,
          notificationSettings: {
            push: true,
            email: true,
            sms: false,
            bookingUpdates: true,
            promotionalOffers: true,
            paymentReminders: true,
            driverMessages: true
          },
          fcmToken: 'sample_fcm_token_12345'
        },
        {
          email: 'jane.smith@example.com',
          password: 'Password123',
          name: 'Jane Smith',
          phoneNumber: '+27987654321',
          loyaltyTier: 'Gold',
          loyaltyPoints: 3500,
          totalTrips: 50,
          totalSpent: 5000,
          savedAddresses: [
            {
              label: 'Home',
              address: '789 Oak Avenue, Johannesburg, South Africa',
              coordinates: {
                latitude: -26.2041,
                longitude: 28.0473
              },
              isDefault: true
            }
          ],
          earnedRewards: [
            {
              name: 'Priority Booking',
              description: 'Priority booking for next 5 rides',
              type: 'priority',
              pointsCost: 2000,
              discountPercentage: 0,
              isActive: true,
              expiresAt: new Date(Date.now() + 180 * 24 * 60 * 60 * 1000) // 6 months from now
            }
          ],
          availableRewards: [],
          referrals: [],
          bulkBookings: [],
          isEmailVerified: true,
          isPhoneVerified: false,
          isActive: true,
          refreshTokens: [],
          lastLoginAt: new Date(Date.now() - 24 * 60 * 60 * 1000), // 1 day ago
          lastLoginIP: '192.168.1.101',
          loginCount: 23,
          notificationSettings: {
            push: true,
            email: true,
            sms: true,
            bookingUpdates: true,
            promotionalOffers: false,
            paymentReminders: true,
            driverMessages: true
          }
        },
        {
          email: 'admin@swiftlyft.co.za',
          password: 'AdminPassword123',
          name: 'Admin User',
          phoneNumber: '+27111222333',
          role: 'admin',
          loyaltyTier: 'Diamond',
          loyaltyPoints: 15000,
          totalTrips: 100,
          totalSpent: 10000,
          savedAddresses: [],
          earnedRewards: [],
          availableRewards: [],
          referrals: [],
          bulkBookings: [],
          isEmailVerified: true,
          isPhoneVerified: true,
          isActive: true,
          refreshTokens: [],
          lastLoginAt: new Date(Date.now() - 30 * 60 * 1000), // 30 minutes ago
          lastLoginIP: '192.168.1.1',
          loginCount: 156,
          notificationSettings: {
            push: true,
            email: true,
            sms: true,
            bookingUpdates: true,
            promotionalOffers: true,
            paymentReminders: true,
            driverMessages: true
          }
        }
      ];

      // Create users
      for (const userData of sampleUsers) {
        const user = new User(userData);
        await user.save();
        console.log(`✅ Created user: ${user.email}`);
      }

      console.log('🎉 Sample data created successfully!');
    } catch (error) {
      console.error('❌ Error creating sample data:', error);
      throw error;
    }
  }

  // Run database health check
  async healthCheck() {
    try {
      console.log('🏥 Running database health check...');

      // Check connection
      if (!this.connection) {
        throw new Error('No database connection');
      }

      // Check database stats
      const stats = await this.connection.connection.db.stats();
      console.log(`📊 Database size: ${(stats.dataSize / 1024 / 1024).toFixed(2)} MB`);
      console.log(`📊 Collections: ${stats.collections}`);
      console.log(`📊 Documents: ${stats.objects || 0}`);

      // Check user collection stats
      const userCount = await User.countDocuments();
      const activeUsers = await User.countDocuments({ isActive: true });
      const corporateUsers = await User.countDocuments({ 'corporateAccount': { $exists: true } });
      const verifiedUsers = await User.countDocuments({ isEmailVerified: true });

      console.log(`👥 Total users: ${userCount}`);
      console.log(`✅ Active users: ${activeUsers}`);
      console.log(`🏢 Corporate users: ${corporateUsers}`);
      console.log(`📧 Verified users: ${verifiedUsers}`);

      // Check indexes
      const indexes = await User.collection.getIndexes();
      console.log(`🔍 Indexes: ${indexes.length}`);

      console.log('🎉 Database health check completed successfully!');
      return true;
    } catch (error) {
      console.error('❌ Database health check failed:', error);
      return false;
    }
  }

  // Close database connection
  async close() {
    try {
      if (this.connection) {
        await mongoose.connection.close();
        console.log('✅ Database connection closed');
      }
    } catch (error) {
      console.error('❌ Error closing database connection:', error);
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
      console.log('🚀 Starting database setup...');

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

      console.log('🎉 Database setup completed successfully!');
    } catch (error) {
      console.error('❌ Database setup failed:', error);
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

  const dbSetup = new DatabaseSetup();
  
  dbSetup.setup(options)
    .then(() => {
      console.log('✅ Setup completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Setup failed:', error);
      process.exit(1);
    });
}

module.exports = DatabaseSetup;