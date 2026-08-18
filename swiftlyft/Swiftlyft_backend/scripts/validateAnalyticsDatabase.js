const mongoose = require('mongoose');
const {
  UserAnalytics,
  BookingAnalytics,
  RevenueAnalytics,
  DriverAnalytics
} = require('../models/Analytics');
require('dotenv').config();

class AnalyticsDatabaseValidator {
  constructor() {
    this.connection = null;
    this.errors = [];
    this.warnings = [];
  }

  // Connect to MongoDB
  async connect() {
    try {
      const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_analytics';
      
      this.connection = await mongoose.connect(mongoUri, {
        useNewUrlParser: true,
        useUnifiedTopology: true,
      });

      console.log('✅ Connected to MongoDB for Analytics validation');
      console.log(`📊 Database: ${mongoose.connection.name}`);
      return this.connection;
    } catch (error) {
      console.error('❌ MongoDB connection error:', error);
      throw error;
    }
  }

  // Add error to validation results
  addError(message, details = null) {
    this.errors.push({ message, details, timestamp: new Date() });
  }

  // Add warning to validation results
  addWarning(message, details = null) {
    this.warnings.push({ message, details, timestamp: new Date() });
  }

  // Validate database connection
  async validateConnection() {
    try {
      console.log('🔍 Validating Analytics database connection...');
      
      if (!this.connection) {
        this.addError('No database connection established');
        return false;
      }

      // Test basic operations
      await this.connection.connection.db.admin().ping();
      console.log('✅ Analytics database connection is healthy');
      return true;
    } catch (error) {
      this.addError('Database connection failed', error.message);
      return false;
    }
  }

  // Validate collections exist and have proper structure
  async validateCollections() {
    try {
      console.log('🔍 Validating Analytics collections...');
      
      const collections = await this.connection.connection.db.listCollections().toArray();
      const requiredCollections = ['useranalytics', 'bookinganalytics', 'revenueanalytics', 'driveranalytics'];
      
      for (const collectionName of requiredCollections) {
        const collection = collections.find(col => col.name === collectionName);
        
        if (!collection) {
          this.addError(`Analytics collection does not exist: ${collectionName}`);
        } else {
          console.log(`✅ Collection exists: ${collectionName}`);
          
          // Check collection stats
          const stats = await this.connection.connection.db.collection(collectionName).stats();
          console.log(`📊 ${collectionName} size: ${(stats.size / 1024 / 1024).toFixed(2)} MB, documents: ${stats.count}`);
        }
      }
      
      return this.errors.length === 0;
    } catch (error) {
      this.addError('Collection validation failed', error.message);
      return false;
    }
  }

  // Validate indexes
  async validateIndexes() {
    try {
      console.log('🔍 Validating Analytics database indexes...');
      
      const collections = [
        { name: 'UserAnalytics', model: UserAnalytics },
        { name: 'BookingAnalytics', model: BookingAnalytics },
        { name: 'RevenueAnalytics', model: RevenueAnalytics },
        { name: 'DriverAnalytics', model: DriverAnalytics }
      ];

      const requiredIndexes = {
        UserAnalytics: [
          'userId_1_timestamp_-1',
          'eventType_1_timestamp_-1',
          'sessionId_1',
          'timestamp_-1'
        ],
        BookingAnalytics: [
          'date_1',
          'totalBookings_-1',
          'totalRevenue_-1'
        ],
        RevenueAnalytics: [
          'date_1',
          'totalRevenue_-1'
        ],
        DriverAnalytics: [
          'driverId_1_date_1',
          'averageRating_-1',
          'totalEarnings_-1'
        ]
      };

      for (const collection of collections) {
        const indexes = await collection.model.collection.getIndexes();
        const existingIndexNames = typeof indexes === 'object' ? Object.keys(indexes) : [];
        const required = requiredIndexes[collection.name] || [];
        
        console.log(`📋 ${collection.name} indexes:`, existingIndexNames.length);
        
        for (const requiredIndex of required) {
          if (!existingIndexNames.includes(requiredIndex)) {
            this.addError(`Required index missing in ${collection.name}: ${requiredIndex}`);
          } else {
            console.log(`✅ Index exists in ${collection.name}: ${requiredIndex}`);
          }
        }
      }

      console.log('✅ Analytics indexes validation completed');
      return this.errors.length === 0;
    } catch (error) {
      this.addError('Index validation failed', error.message);
      return false;
    }
  }

  // Validate documents
  async validateDocuments() {
    try {
      console.log('🔍 Validating Analytics documents...');
      
      const collections = [
        { name: 'UserAnalytics', model: UserAnalytics },
        { name: 'BookingAnalytics', model: BookingAnalytics },
        { name: 'RevenueAnalytics', model: RevenueAnalytics },
        { name: 'DriverAnalytics', model: DriverAnalytics }
      ];

      for (const collection of collections) {
        const totalDocs = await collection.model.countDocuments();
        if (totalDocs === 0) {
          this.addWarning(`No documents found in ${collection.name}`);
          continue;
        }

        console.log(`📊 ${collection.name} documents: ${totalDocs}`);

        // Validate required fields for each collection
        if (collection.name === 'UserAnalytics') {
          const docsWithoutUserId = await collection.model.countDocuments({ userId: { $exists: false } });
          if (docsWithoutUserId > 0) {
            this.addError(`${docsWithoutUserId} UserAnalytics documents missing userId field`);
          }

          const docsWithoutEventType = await collection.model.countDocuments({ eventType: { $exists: false } });
          if (docsWithoutEventType > 0) {
            this.addError(`${docsWithoutEventType} UserAnalytics documents missing eventType field`);
          }

          // Validate event types
          const invalidEventTypes = await collection.model.countDocuments({
            eventType: { 
              $nin: [
                'app_open', 'app_close', 'booking_started', 'booking_completed',
                'payment_attempt', 'payment_success', 'payment_failed', 'quote_requested',
                'quote_accepted', 'profile_updated', 'location_search', 'driver_rated',
                'support_contacted', 'promotion_viewed', 'loyalty_used'
              ]
            }
          });
          if (invalidEventTypes > 0) {
            this.addError(`${invalidEventTypes} UserAnalytics documents have invalid eventType`);
          }
        }

        if (collection.name === 'BookingAnalytics') {
          const docsWithoutDate = await collection.model.countDocuments({ date: { $exists: false } });
          if (docsWithoutDate > 0) {
            this.addError(`${docsWithoutDate} BookingAnalytics documents missing date field`);
          }

          const docsWithNegativeBookings = await collection.model.countDocuments({ totalBookings: { $lt: 0 } });
          if (docsWithNegativeBookings > 0) {
            this.addError(`${docsWithNegativeBookings} BookingAnalytics documents have negative totalBookings`);
          }
        }

        if (collection.name === 'RevenueAnalytics') {
          const docsWithoutDate = await collection.model.countDocuments({ date: { $exists: false } });
          if (docsWithoutDate > 0) {
            this.addError(`${docsWithoutDate} RevenueAnalytics documents missing date field`);
          }

          const docsWithNegativeRevenue = await collection.model.countDocuments({ totalRevenue: { $lt: 0 } });
          if (docsWithNegativeRevenue > 0) {
            this.addError(`${docsWithNegativeRevenue} RevenueAnalytics documents have negative totalRevenue`);
          }
        }

        if (collection.name === 'DriverAnalytics') {
          const docsWithoutDriverId = await collection.model.countDocuments({ driverId: { $exists: false } });
          if (docsWithoutDriverId > 0) {
            this.addError(`${docsWithoutDriverId} DriverAnalytics documents missing driverId field`);
          }

          const docsWithInvalidRating = await collection.model.countDocuments({
            $or: [
              { averageRating: { $lt: 0 } },
              { averageRating: { $gt: 5 } }
            ]
          });
          if (docsWithInvalidRating > 0) {
            this.addError(`${docsWithInvalidRating} DriverAnalytics documents have invalid averageRating (must be 0-5)`);
          }
        }
      }

      console.log('✅ Analytics document validation completed');
      return this.errors.length === 0;
    } catch (error) {
      this.addError('Document validation failed', error.message);
      return false;
    }
  }

  // Validate data consistency
  async validateDataConsistency() {
    try {
      console.log('🔍 Validating Analytics data consistency...');
      
      // Check BookingAnalytics vs RevenueAnalytics consistency
      const bookingRevenue = await BookingAnalytics.aggregate([
        { $group: { _id: null, totalRevenue: { $sum: '$totalRevenue' } } }
      ]);
      
      const revenueTotal = await RevenueAnalytics.aggregate([
        { $group: { _id: null, totalRevenue: { $sum: '$totalRevenue' } } }
      ]);

      const bookingTotal = bookingRevenue[0]?.totalRevenue || 0;
      const revenueTotalValue = revenueTotal[0]?.totalRevenue || 0;

      if (Math.abs(bookingTotal - revenueTotalValue) > bookingTotal * 0.1) { // 10% tolerance
        this.addWarning(`Revenue mismatch: BookingAnalytics (${bookingTotal}) vs RevenueAnalytics (${revenueTotalValue})`);
      }

      // Check for duplicate dates in daily analytics
      const duplicateBookingDates = await BookingAnalytics.aggregate([
        { $group: { _id: '$date', count: { $sum: 1 } } },
        { $match: { count: { $gt: 1 } } }
      ]);

      if (duplicateBookingDates.length > 0) {
        this.addError(`${duplicateBookingDates.length} duplicate dates found in BookingAnalytics`);
      }

      const duplicateRevenueDates = await RevenueAnalytics.aggregate([
        { $group: { _id: '$date', count: { $sum: 1 } } },
        { $match: { count: { $gt: 1 } } }
      ]);

      if (duplicateRevenueDates.length > 0) {
        this.addError(`${duplicateRevenueDates.length} duplicate dates found in RevenueAnalytics`);
      }

      console.log('✅ Analytics data consistency validation completed');
      return true;
    } catch (error) {
      this.addError('Data consistency validation failed', error.message);
      return false;
    }
  }

  // Validate static methods
  async validateStaticMethods() {
    try {
      console.log('🔍 Validating Analytics static methods...');
      
      // Test BookingAnalytics.getBookingsSummary
      const startDate = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
      const endDate = new Date();
      
      const bookingSummary = await BookingAnalytics.getBookingsSummary(startDate, endDate);
      if (!Array.isArray(bookingSummary)) {
        this.addError('BookingAnalytics.getBookingsSummary did not return an array');
      }

      // Test RevenueAnalytics.getRevenueSummary
      const revenueSummary = await RevenueAnalytics.getRevenueSummary(startDate, endDate);
      if (!Array.isArray(revenueSummary)) {
        this.addError('RevenueAnalytics.getRevenueSummary did not return an array');
      }

      // Test DriverAnalytics.getTopPerformers
      const topPerformers = await DriverAnalytics.getTopPerformers(5);
      if (!Array.isArray(topPerformers)) {
        this.addError('DriverAnalytics.getTopPerformers did not return an array');
      }

      console.log('✅ Analytics static methods validation completed');
      return true;
    } catch (error) {
      this.addError('Static methods validation failed', error.message);
      return false;
    }
  }

  // Validate API endpoint compatibility
  async validateAPICompatibility() {
    try {
      console.log('🔍 Validating Analytics API endpoint compatibility...');
      
      // Test UserAnalytics data structure for API
      const userAnalytics = await UserAnalytics.find({}).limit(5);
      let apiErrors = 0;

      for (const event of userAnalytics) {
        try {
          const eventData = event.toJSON();
          
          // Check required fields for API responses
          const requiredFields = ['_id', 'userId', 'eventType', 'timestamp'];
          for (const field of requiredFields) {
            if (!(field in eventData)) {
              apiErrors++;
              this.addError(`Missing required field '${field}' in UserAnalytics API response`);
            }
          }

          // Validate event type
          const validEventTypes = [
            'app_open', 'app_close', 'booking_started', 'booking_completed',
            'payment_attempt', 'payment_success', 'payment_failed', 'quote_requested',
            'quote_accepted', 'profile_updated', 'location_search', 'driver_rated',
            'support_contacted', 'promotion_viewed', 'loyalty_used'
          ];

          if (!validEventTypes.includes(eventData.eventType)) {
            apiErrors++;
            this.addError(`Invalid eventType '${eventData.eventType}' in UserAnalytics`);
          }

        } catch (error) {
          apiErrors++;
          this.addError(`API compatibility error for UserAnalytics event`, error.message);
        }
      }

      if (apiErrors === 0) {
        console.log('✅ Analytics API compatibility validation passed');
      } else {
        this.addError(`${apiErrors} Analytics API compatibility errors`);
      }

      return apiErrors === 0;
    } catch (error) {
      this.addError('API compatibility validation failed', error.message);
      return false;
    }
  }

  // Performance testing
  async validatePerformance() {
    try {
      console.log('🔍 Validating Analytics database performance...');
      
      const startTime = Date.now();
      
      // Test common analytics queries
      await UserAnalytics.find({ eventType: 'app_open' }).limit(100);
      const userQueryTime = Date.now() - startTime;
      
      const bookingStartTime = Date.now();
      await BookingAnalytics.find({}).sort({ date: -1 }).limit(50);
      const bookingQueryTime = Date.now() - bookingStartTime;
      
      const revenueStartTime = Date.now();
      await RevenueAnalytics.find({}).sort({ date: -1 }).limit(30);
      const revenueQueryTime = Date.now() - revenueStartTime;
      
      const driverStartTime = Date.now();
      await DriverAnalytics.find({}).sort({ averageRating: -1 }).limit(20);
      const driverQueryTime = Date.now() - driverStartTime;
      
      // Performance thresholds (in milliseconds)
      const thresholds = {
        userQuery: 500,
        bookingQuery: 300,
        revenueQuery: 300,
        driverQuery: 300
      };

      if (userQueryTime > thresholds.userQuery) {
        this.addWarning(`UserAnalytics query slow: ${userQueryTime}ms (threshold: ${thresholds.userQuery}ms)`);
      }

      if (bookingQueryTime > thresholds.bookingQuery) {
        this.addWarning(`BookingAnalytics query slow: ${bookingQueryTime}ms (threshold: ${thresholds.bookingQuery}ms)`);
      }

      if (revenueQueryTime > thresholds.revenueQuery) {
        this.addWarning(`RevenueAnalytics query slow: ${revenueQueryTime}ms (threshold: ${thresholds.revenueQuery}ms)`);
      }

      if (driverQueryTime > thresholds.driverQuery) {
        this.addWarning(`DriverAnalytics query slow: ${driverQueryTime}ms (threshold: ${thresholds.driverQuery}ms)`);
      }

      console.log(`📊 Analytics query performance:`);
      console.log(`  UserAnalytics: ${userQueryTime}ms`);
      console.log(`  BookingAnalytics: ${bookingQueryTime}ms`);
      console.log(`  RevenueAnalytics: ${revenueQueryTime}ms`);
      console.log(`  DriverAnalytics: ${driverQueryTime}ms`);

      console.log('✅ Analytics performance validation completed');
      return true;
    } catch (error) {
      this.addError('Performance validation failed', error.message);
      return false;
    }
  }

  // Generate validation report
  generateReport() {
    console.log('\n📋 ANALYTICS VALIDATION REPORT');
    console.log('='.repeat(50));
    
    if (this.errors.length === 0) {
      console.log('✅ All Analytics validations passed successfully!');
    } else {
      console.log(`❌ ${this.errors.length} errors found:`);
      this.errors.forEach((error, index) => {
        console.log(`  ${index + 1}. ${error.message}`);
        if (error.details) {
          console.log(`     Details: ${error.details}`);
        }
      });
    }

    if (this.warnings.length > 0) {
      console.log(`\n⚠️ ${this.warnings.length} warnings:`);
      this.warnings.forEach((warning, index) => {
        console.log(`  ${index + 1}. ${warning.message}`);
        if (warning.details) {
          console.log(`     Details: ${warning.details}`);
        }
      });
    }

    console.log('\n📊 Analytics Summary:');
    console.log(`  Errors: ${this.errors.length}`);
    console.log(`  Warnings: ${this.warnings.length}`);
    console.log(`  Status: ${this.errors.length === 0 ? 'PASS' : 'FAIL'}`);

    return {
      errors: this.errors,
      warnings: this.warnings,
      passed: this.errors.length === 0
    };
  }

  // Run all validations
  async runAllValidations() {
    try {
      console.log('🚀 Starting comprehensive Analytics database validation...\n');

      // Connect to database first
      await this.connect();
      
      await this.validateConnection();
      await this.validateCollections();
      await this.validateIndexes();
      await this.validateDocuments();
      await this.validateDataConsistency();
      await this.validateStaticMethods();
      await this.validateAPICompatibility();
      await this.validatePerformance();

      const report = this.generateReport();
      return report;
    } catch (error) {
      console.error('❌ Analytics validation process failed:', error);
      this.addError('Validation process failed', error.message);
      return this.generateReport();
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
}

// CLI interface
if (require.main === module) {
  const validator = new AnalyticsDatabaseValidator();
  
  validator.runAllValidations()
    .then((report) => {
      const exitCode = report.passed ? 0 : 1;
      console.log(`\n🏁 Analytics validation completed with ${report.passed ? 'SUCCESS' : 'FAILURE'}`);
      process.exit(exitCode);
    })
    .catch((error) => {
      console.error('❌ Analytics validation failed:', error);
      process.exit(1);
    });
}

module.exports = AnalyticsDatabaseValidator;
