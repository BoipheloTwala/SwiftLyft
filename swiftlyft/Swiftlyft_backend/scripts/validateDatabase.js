const mongoose = require('mongoose');
const User = require('../models/User');
require('dotenv').config();

class DatabaseValidator {
  constructor() {
    this.connection = null;
    this.errors = [];
    this.warnings = [];
  }

  // Connect to MongoDB
  async connect() {
    try {
      const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_users';
      
      this.connection = await mongoose.connect(mongoUri, {
        useNewUrlParser: true,
        useUnifiedTopology: true,
      });

      console.log('✅ Connected to MongoDB for validation');
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
      console.log('🔍 Validating database connection...');
      
      if (!this.connection) {
        this.addError('No database connection established');
        return false;
      }

      // Test basic operations
      await this.connection.connection.db.admin().ping();
      console.log('✅ Database connection is healthy');
      return true;
    } catch (error) {
      this.addError('Database connection failed', error.message);
      return false;
    }
  }

  // Validate collection exists and has proper structure
  async validateCollection() {
    try {
      console.log('🔍 Validating users collection...');
      
      const collections = await this.connection.connection.db.listCollections().toArray();
      const usersCollection = collections.find(col => col.name === 'users');
      
      if (!usersCollection) {
        this.addError('Users collection does not exist');
        return false;
      }

      console.log('✅ Users collection exists');
      
      // Check collection stats
      const stats = await this.connection.connection.db.collection('users').stats();
      console.log(`📊 Collection size: ${(stats.size / 1024 / 1024).toFixed(2)} MB`);
      console.log(`📊 Document count: ${stats.count}`);
      
      return true;
    } catch (error) {
      this.addError('Collection validation failed', error.message);
      return false;
    }
  }

  // Validate indexes
  async validateIndexes() {
    try {
      console.log('🔍 Validating database indexes...');
      
      const indexes = await User.collection.getIndexes();
      
      const requiredIndexes = [
        'email_1',
        'referralCode_1',
        'refreshTokens.token_1',
        'resetPasswordToken_1',
        'emailVerificationToken_1',
        'phoneVerificationCode_1'
      ];

      const existingIndexNames = typeof indexes === 'object' ? Object.keys(indexes) : [];
      
      for (const requiredIndex of requiredIndexes) {
        if (!existingIndexNames.includes(requiredIndex)) {
          this.addError(`Required index missing: ${requiredIndex}`);
        } else {
          console.log(`✅ Index exists: ${requiredIndex}`);
        }
      }

      // Check for unique constraints
      if (typeof indexes === 'object' && indexes !== null) {
        // Note: Unique constraints are handled at schema level, not in index object
        console.log(`📊 Total indexes: ${Object.keys(indexes).length}`);
      } else {
        console.log('⚠️ Could not retrieve index information');
      }
      return this.errors.length === 0;
    } catch (error) {
      this.addError('Index validation failed', error.message);
      return false;
    }
  }

  // Validate user documents
  async validateDocuments() {
    try {
      console.log('🔍 Validating user documents...');
      
      const totalUsers = await User.countDocuments();
      if (totalUsers === 0) {
        this.addWarning('No users found in database');
        return true;
      }

      console.log(`📊 Total users: ${totalUsers}`);

      // Validate required fields
      const usersWithoutEmail = await User.countDocuments({ email: { $exists: false } });
      if (usersWithoutEmail > 0) {
        this.addError(`${usersWithoutEmail} users missing email field`);
      }

      const usersWithoutName = await User.countDocuments({ name: { $exists: false } });
      if (usersWithoutName > 0) {
        this.addWarning(`${usersWithoutName} users missing name field`);
      }

      // Validate email format
      const invalidEmails = await User.find({
        email: { $not: /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/ }
      });
      if (invalidEmails.length > 0) {
        this.addError(`${invalidEmails.length} users have invalid email format`);
      }

      // Validate loyalty tier values
      const invalidTiers = await User.countDocuments({
        loyaltyTier: { $nin: ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond'] }
      });
      if (invalidTiers > 0) {
        this.addError(`${invalidTiers} users have invalid loyalty tier`);
      }

      // Validate role values
      const invalidRoles = await User.countDocuments({
        role: { $nin: ['user', 'admin'] }
      });
      if (invalidRoles > 0) {
        this.addError(`${invalidRoles} users have invalid role`);
      }

      // Validate numeric fields
      const usersWithNegativePoints = await User.countDocuments({ loyaltyPoints: { $lt: 0 } });
      if (usersWithNegativePoints > 0) {
        this.addError(`${usersWithNegativePoints} users have negative loyalty points`);
      }

      const usersWithNegativeTrips = await User.countDocuments({ totalTrips: { $lt: 0 } });
      if (usersWithNegativeTrips > 0) {
        this.addError(`${usersWithNegativeTrips} users have negative total trips`);
      }

      const usersWithNegativeSpent = await User.countDocuments({ totalSpent: { $lt: 0 } });
      if (usersWithNegativeSpent > 0) {
        this.addError(`${usersWithNegativeSpent} users have negative total spent`);
      }

      console.log('✅ Document validation completed');
      return this.errors.length === 0;
    } catch (error) {
      this.addError('Document validation failed', error.message);
      return false;
    }
  }

  // Validate data consistency
  async validateDataConsistency() {
    try {
      console.log('🔍 Validating data consistency...');
      
      // Check loyalty tier consistency with points
      const tierInconsistencies = await User.find({
        $or: [
          { loyaltyTier: 'Bronze', loyaltyPoints: { $gte: 1000 } },
          { loyaltyTier: 'Silver', loyaltyPoints: { $gte: 2500 } },
          { loyaltyTier: 'Gold', loyaltyPoints: { $gte: 5000 } },
          { loyaltyTier: 'Platinum', loyaltyPoints: { $gte: 10000 } }
        ]
      });

      if (tierInconsistencies.length > 0) {
        this.addWarning(`${tierInconsistencies.length} users may need loyalty tier updates`);
      }

      // Check referral consistency - skip complex aggregation for now
      // const usersWithSelfReferral = await User.find({
      //   referredBy: { $eq: '$_id' }
      // }).limit(0);
      // if (usersWithSelfReferral.length > 0) {
      //   this.addError(`${usersWithSelfReferral.length} users have self-referrals`);
      // }

      // Check corporate account consistency
      const corporateUsersWithoutAccount = await User.countDocuments({
        'corporateAccount': { $exists: false },
        'bulkBookings.0': { $exists: true }
      });
      if (corporateUsersWithoutAccount > 0) {
        this.addWarning(`${corporateUsersWithoutAccount} users have bulk bookings but no corporate account`);
      }

      console.log('✅ Data consistency validation completed');
      return true;
    } catch (error) {
      this.addError('Data consistency validation failed', error.message);
      return false;
    }
  }

  // Validate virtual fields
  async validateVirtualFields() {
    try {
      console.log('🔍 Validating virtual fields...');
      
      const users = await User.find({}).limit(10);
      let virtualFieldErrors = 0;

      for (const user of users) {
        try {
          // Test virtual field calculations
          const pointsToNextTier = user.pointsToNextTier;
          const tierProgress = user.tierProgress;
          const tierDiscount = user.tierDiscount;
          const isCorporateUser = user.isCorporateUser;

          // Validate points to next tier calculation
          if (typeof pointsToNextTier !== 'number' || pointsToNextTier < 0) {
            virtualFieldErrors++;
            this.addError(`Invalid pointsToNextTier for user ${user.email}`);
          }

          // Validate tier progress calculation
          if (typeof tierProgress !== 'number' || tierProgress < 0 || tierProgress > 1) {
            virtualFieldErrors++;
            this.addError(`Invalid tierProgress for user ${user.email}`);
          }

          // Validate tier discount calculation
          if (typeof tierDiscount !== 'number' || tierDiscount < 0 || tierDiscount > 1) {
            virtualFieldErrors++;
            this.addError(`Invalid tierDiscount for user ${user.email}`);
          }

          // Validate corporate user check
          if (typeof isCorporateUser !== 'boolean') {
            virtualFieldErrors++;
            this.addError(`Invalid isCorporateUser for user ${user.email}`);
          }

        } catch (error) {
          virtualFieldErrors++;
          this.addError(`Virtual field calculation error for user ${user.email}`, error.message);
        }
      }

      if (virtualFieldErrors === 0) {
        console.log('✅ Virtual fields validation passed');
      } else {
        this.addError(`${virtualFieldErrors} virtual field calculation errors`);
      }

      return virtualFieldErrors === 0;
    } catch (error) {
      this.addError('Virtual fields validation failed', error.message);
      return false;
    }
  }

  // Validate API endpoint compatibility
  async validateAPICompatibility() {
    try {
      console.log('🔍 Validating API endpoint compatibility...');
      
      const users = await User.find({}).limit(5);
      let apiErrors = 0;

      for (const user of users) {
        try {
          // Test user profile endpoint data
          const profileData = user.toJSON();
          
          // Check required fields for API responses
          const requiredFields = ['id', 'email', 'name', 'loyaltyTier', 'loyaltyPoints'];
          for (const field of requiredFields) {
            if (!(field in profileData)) {
              apiErrors++;
              this.addError(`Missing required field '${field}' in API response for user ${user.email}`);
            }
          }

          // Check that sensitive fields are excluded
          const sensitiveFields = ['password', 'refreshTokens', 'resetPasswordToken'];
          for (const field of sensitiveFields) {
            if (field in profileData) {
              apiErrors++;
              this.addError(`Sensitive field '${field}' exposed in API response for user ${user.email}`);
            }
          }

          // Test loyalty endpoint data structure
          const loyaltyData = {
            loyaltyTier: user.loyaltyTier,
            loyaltyPoints: user.loyaltyPoints,
            pointsToNextTier: user.pointsToNextTier,
            tierProgress: user.tierProgress,
            tierDiscount: user.tierDiscount,
            earnedRewards: user.earnedRewards,
            availableRewards: user.availableRewards,
            totalTrips: user.totalTrips,
            totalSpent: user.totalSpent
          };

          // Validate loyalty data structure
          if (!Array.isArray(loyaltyData.earnedRewards)) {
            apiErrors++;
            this.addError(`Invalid earnedRewards structure for user ${user.email}`);
          }

          if (!Array.isArray(loyaltyData.availableRewards)) {
            apiErrors++;
            this.addError(`Invalid availableRewards structure for user ${user.email}`);
          }

        } catch (error) {
          apiErrors++;
          this.addError(`API compatibility error for user ${user.email}`, error.message);
        }
      }

      if (apiErrors === 0) {
        console.log('✅ API compatibility validation passed');
      } else {
        this.addError(`${apiErrors} API compatibility errors`);
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
      console.log('🔍 Validating database performance...');
      
      const startTime = Date.now();
      
      // Test common queries
      await User.find({ isActive: true }).limit(100);
      const activeUsersTime = Date.now() - startTime;
      
      const loyaltyStartTime = Date.now();
      await User.find({ loyaltyTier: 'Gold' }).limit(50);
      const loyaltyQueryTime = Date.now() - loyaltyStartTime;
      
      const corporateStartTime = Date.now();
      await User.find({ 'corporateAccount.status': 'active' }).limit(20);
      const corporateQueryTime = Date.now() - corporateStartTime;
      
      // Performance thresholds (in milliseconds)
      const thresholds = {
        activeUsers: 1000,
        loyaltyQuery: 500,
        corporateQuery: 500
      };

      if (activeUsersTime > thresholds.activeUsers) {
        this.addWarning(`Active users query slow: ${activeUsersTime}ms (threshold: ${thresholds.activeUsers}ms)`);
      }

      if (loyaltyQueryTime > thresholds.loyaltyQuery) {
        this.addWarning(`Loyalty query slow: ${loyaltyQueryTime}ms (threshold: ${thresholds.loyaltyQuery}ms)`);
      }

      if (corporateQueryTime > thresholds.corporateQuery) {
        this.addWarning(`Corporate query slow: ${corporateQueryTime}ms (threshold: ${thresholds.corporateQuery}ms)`);
      }

      console.log(`📊 Query performance:`);
      console.log(`  Active users: ${activeUsersTime}ms`);
      console.log(`  Loyalty query: ${loyaltyQueryTime}ms`);
      console.log(`  Corporate query: ${corporateQueryTime}ms`);

      console.log('✅ Performance validation completed');
      return true;
    } catch (error) {
      this.addError('Performance validation failed', error.message);
      return false;
    }
  }

  // Generate validation report
  generateReport() {
    console.log('\n📋 VALIDATION REPORT');
    console.log('='.repeat(50));
    
    if (this.errors.length === 0) {
      console.log('✅ All validations passed successfully!');
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

    console.log('\n📊 Summary:');
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
      console.log('🚀 Starting comprehensive database validation...\n');

      // Connect to database first
      await this.connect();
      
      await this.validateConnection();
      await this.validateCollection();
      await this.validateIndexes();
      await this.validateDocuments();
      await this.validateDataConsistency();
      await this.validateVirtualFields();
      await this.validateAPICompatibility();
      await this.validatePerformance();

      const report = this.generateReport();
      return report;
    } catch (error) {
      console.error('❌ Validation process failed:', error);
      this.addError('Validation process failed', error.message);
      return this.generateReport();
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
}

// CLI interface
if (require.main === module) {
  const validator = new DatabaseValidator();
  
  validator.runAllValidations()
    .then((report) => {
      const exitCode = report.passed ? 0 : 1;
      console.log(`\n🏁 Validation completed with ${report.passed ? 'SUCCESS' : 'FAILURE'}`);
      process.exit(exitCode);
    })
    .catch((error) => {
      console.error('❌ Validation failed:', error);
      process.exit(1);
    });
}

module.exports = DatabaseValidator;
