const mongoose = require('mongoose');
const { PaymentMethod, Payment } = require('../models/Payment');

/**
 * Database Migration Script for Payment Processing
 * This script handles database migrations, data cleanup, and schema updates
 */

class PaymentDatabaseMigration {
  constructor() {
    this.connection = null;
    this.migrationVersion = '1.0.0';
  }

  /**
   * Connect to MongoDB
   */
  async connect() {
    try {
      this.connection = await mongoose.connect(process.env.MONGODB_URI, {
        useNewUrlParser: true,
        useUnifiedTopology: true,
      });
      console.log('✅ Connected to MongoDB for migration');
      return this.connection;
    } catch (error) {
      console.error('❌ MongoDB connection error:', error);
      throw error;
    }
  }

  /**
   * Create migration tracking collection
   */
  async createMigrationCollection() {
    try {
      const migrationSchema = new mongoose.Schema({
        version: { type: String, required: true },
        name: { type: String, required: true },
        description: String,
        executedAt: { type: Date, default: Date.now },
        status: { type: String, enum: ['pending', 'running', 'completed', 'failed'], default: 'pending' },
        error: String,
        duration: Number, // in milliseconds
        recordsAffected: Number
      });

      const Migration = mongoose.model('Migration', migrationSchema);
      return Migration;
    } catch (error) {
      console.error('❌ Error creating migration collection:', error);
      throw error;
    }
  }

  /**
   * Record migration execution
   */
  async recordMigration(migration, status, error = null, duration = 0, recordsAffected = 0) {
    try {
      const Migration = await this.createMigrationCollection();
      
      await Migration.findOneAndUpdate(
        { version: migration.version, name: migration.name },
        {
          version: migration.version,
          name: migration.name,
          description: migration.description,
          status: status,
          error: error,
          duration: duration,
          recordsAffected: recordsAffected,
          executedAt: new Date()
        },
        { upsert: true, new: true }
      );
    } catch (error) {
      console.error('❌ Error recording migration:', error);
    }
  }

  /**
   * Migration 1: Create initial payment collections and indexes
   */
  async migration_001_initial_setup() {
    const migration = {
      version: '1.0.0',
      name: 'initial_payment_setup',
      description: 'Create initial payment collections and indexes'
    };

    const startTime = Date.now();
    
    try {
      console.log('🔄 Running migration: Initial Payment Setup');
      
      // Create PaymentMethods collection with validation
      await mongoose.connection.db.createCollection('paymentmethods', {
        validator: {
          $jsonSchema: {
            bsonType: 'object',
            required: ['userId', 'type', 'provider'],
            properties: {
              userId: { bsonType: 'objectId' },
              type: { enum: ['credit_card', 'debit_card', 'bank_transfer', 'digital_wallet', 'cash'] },
              provider: { enum: ['visa', 'mastercard', 'amex', 'paypal', 'apple_pay', 'google_pay', 'eft', 'cash'] },
              lastFourDigits: { pattern: '^\\d{4}$' },
              expiryMonth: { bsonType: 'int', minimum: 1, maximum: 12 },
              expiryYear: { bsonType: 'int', minimum: new Date().getFullYear() },
              isDefault: { bsonType: 'bool' },
              isActive: { bsonType: 'bool' }
            }
          }
        }
      });

      // Create Payments collection with validation
      await mongoose.connection.db.createCollection('payments', {
        validator: {
          $jsonSchema: {
            bsonType: 'object',
            required: ['userId', 'bookingId', 'paymentMethodId', 'amount', 'currency', 'status', 'transactionType'],
            properties: {
              userId: { bsonType: 'objectId' },
              bookingId: { bsonType: 'objectId' },
              paymentMethodId: { bsonType: 'objectId' },
              amount: { bsonType: 'double', minimum: 0.01 },
              currency: { enum: ['ZAR', 'USD', 'EUR', 'GBP'] },
              status: { enum: ['pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded', 'partially_refunded'] },
              transactionType: { enum: ['payment', 'refund', 'partial_refund'] },
              processingFee: { bsonType: 'double', minimum: 0 },
              netAmount: { bsonType: 'double', minimum: 0 },
              totalRefunded: { bsonType: 'double', minimum: 0 }
            }
          }
        }
      });

      // Create indexes
      const paymentMethodsCollection = mongoose.connection.db.collection('paymentmethods');
      const paymentsCollection = mongoose.connection.db.collection('payments');

      // PaymentMethods indexes
      await paymentMethodsCollection.createIndex({ userId: 1, isDefault: 1 });
      await paymentMethodsCollection.createIndex({ externalId: 1 });
      await paymentMethodsCollection.createIndex({ userId: 1 });
      await paymentMethodsCollection.createIndex({ userId: 1, isActive: 1 });
      await paymentMethodsCollection.createIndex({ expiryYear: 1, expiryMonth: 1 });

      // Payments indexes
      await paymentsCollection.createIndex({ userId: 1, createdAt: -1 });
      await paymentsCollection.createIndex({ bookingId: 1 });
      await paymentsCollection.createIndex({ status: 1 });
      await paymentsCollection.createIndex({ externalTransactionId: 1 });
      await paymentsCollection.createIndex({ paymentMethodId: 1, status: 1 });
      await paymentsCollection.createIndex({ createdAt: -1 });
      await paymentsCollection.createIndex({ userId: 1, status: 1, totalRefunded: 1 });
      await paymentsCollection.createIndex({ currency: 1, createdAt: -1 });
      await paymentsCollection.createIndex({ amount: 1 });

      const duration = Date.now() - startTime;
      await this.recordMigration(migration, 'completed', null, duration, 0);
      
      console.log('✅ Migration completed: Initial Payment Setup');
      return true;
    } catch (error) {
      const duration = Date.now() - startTime;
      await this.recordMigration(migration, 'failed', error.message, duration, 0);
      console.error('❌ Migration failed:', error);
      throw error;
    }
  }

  /**
   * Migration 2: Add data integrity constraints
   */
  async migration_002_data_integrity() {
    const migration = {
      version: '1.0.1',
      name: 'data_integrity_constraints',
      description: 'Add data integrity constraints and cleanup invalid data'
    };

    const startTime = Date.now();
    let recordsAffected = 0;

    try {
      console.log('🔄 Running migration: Data Integrity Constraints');

      // Clean up invalid payment methods
      const invalidPaymentMethods = await PaymentMethod.deleteMany({
        $or: [
          { lastFourDigits: { $not: { $regex: /^\d{4}$/ } } },
          { expiryMonth: { $lt: 1, $gt: 12 } },
          { expiryYear: { $lt: new Date().getFullYear() } }
        ]
      });
      recordsAffected += invalidPaymentMethods.deletedCount;

      // Clean up invalid payments
      const invalidPayments = await Payment.deleteMany({
        $or: [
          { amount: { $lt: 0.01 } },
          { netAmount: { $lt: 0 } },
          { totalRefunded: { $lt: 0 } }
        ]
      });
      recordsAffected += invalidPayments.deletedCount;

      // Fix payment method default constraints
      const users = await PaymentMethod.distinct('userId');
      for (const userId of users) {
        const userPaymentMethods = await PaymentMethod.find({ userId });
        const defaultMethods = userPaymentMethods.filter(pm => pm.isDefault);
        
        if (defaultMethods.length > 1) {
          // Keep only the first default method
          const keepDefault = defaultMethods[0];
          await PaymentMethod.updateMany(
            { userId, _id: { $ne: keepDefault._id }, isDefault: true },
            { isDefault: false }
          );
          recordsAffected += defaultMethods.length - 1;
        }
      }

      // Fix payment net amount calculations
      const paymentsWithWrongNetAmount = await Payment.find({
        $expr: { $ne: ['$netAmount', { $subtract: ['$amount', '$processingFee'] }] }
      });

      for (const payment of paymentsWithWrongNetAmount) {
        payment.netAmount = payment.amount - payment.processingFee;
        await payment.save();
        recordsAffected++;
      }

      const duration = Date.now() - startTime;
      await this.recordMigration(migration, 'completed', null, duration, recordsAffected);
      
      console.log('✅ Migration completed: Data Integrity Constraints');
      return true;
    } catch (error) {
      const duration = Date.now() - startTime;
      await this.recordMigration(migration, 'failed', error.message, duration, recordsAffected);
      console.error('❌ Migration failed:', error);
      throw error;
    }
  }

  /**
   * Migration 3: Add performance optimizations
   */
  async migration_003_performance_optimization() {
    const migration = {
      version: '1.0.2',
      name: 'performance_optimization',
      description: 'Add performance optimizations and additional indexes'
    };

    const startTime = Date.now();

    try {
      console.log('🔄 Running migration: Performance Optimization');

      const paymentsCollection = mongoose.connection.db.collection('payments');
      const paymentMethodsCollection = mongoose.connection.db.collection('paymentmethods');

      // Add compound indexes for common query patterns
      await paymentsCollection.createIndex({ status: 1, createdAt: -1 });
      await paymentsCollection.createIndex({ userId: 1, status: 1, createdAt: -1 });
      await paymentsCollection.createIndex({ currency: 1, status: 1 });
      await paymentsCollection.createIndex({ amount: 1, status: 1 });

      // Add text indexes for search functionality
      await paymentsCollection.createIndex({ description: 'text' });
      await paymentMethodsCollection.createIndex({ cardholderName: 'text' });

      // Add partial indexes for active records
      await paymentMethodsCollection.createIndex(
        { userId: 1, createdAt: -1 },
        { partialFilterExpression: { isActive: true } }
      );

      await paymentsCollection.createIndex(
        { userId: 1, createdAt: -1 },
        { partialFilterExpression: { status: { $in: ['completed', 'pending'] } } }
      );

      const duration = Date.now() - startTime;
      await this.recordMigration(migration, 'completed', null, duration, 0);
      
      console.log('✅ Migration completed: Performance Optimization');
      return true;
    } catch (error) {
      const duration = Date.now() - startTime;
      await this.recordMigration(migration, 'failed', error.message, duration, 0);
      console.error('❌ Migration failed:', error);
      throw error;
    }
  }

  /**
   * Get migration history
   */
  async getMigrationHistory() {
    try {
      const Migration = await this.createMigrationCollection();
      const migrations = await Migration.find().sort({ executedAt: -1 });
      return migrations;
    } catch (error) {
      console.error('❌ Error getting migration history:', error);
      throw error;
    }
  }

  /**
   * Run all pending migrations
   */
  async runMigrations() {
    try {
      console.log('🚀 Starting Payment Database Migrations...');
      
      await this.connect();
      
      // Run migrations in order
      await this.migration_001_initial_setup();
      await this.migration_002_data_integrity();
      await this.migration_003_performance_optimization();
      
      console.log('✅ All migrations completed successfully!');
      
      // Show migration history
      const history = await this.getMigrationHistory();
      console.log('📋 Migration History:');
      history.forEach(migration => {
        console.log(`  ${migration.version} - ${migration.name}: ${migration.status}`);
      });
      
    } catch (error) {
      console.error('❌ Migration process failed:', error);
      throw error;
    }
  }

  /**
   * Rollback last migration (if needed)
   */
  async rollbackLastMigration() {
    try {
      console.log('🔄 Rolling back last migration...');
      
      const Migration = await this.createMigrationCollection();
      const lastMigration = await Migration.findOne().sort({ executedAt: -1 });
      
      if (!lastMigration) {
        console.log('ℹ️ No migrations to rollback');
        return;
      }
      
      // Mark migration as rolled back
      await Migration.updateOne(
        { _id: lastMigration._id },
        { 
          status: 'rolled_back',
          rolledBackAt: new Date()
        }
      );
      
      console.log(`✅ Rolled back migration: ${lastMigration.name}`);
    } catch (error) {
      console.error('❌ Rollback failed:', error);
      throw error;
    }
  }

  /**
   * Close database connection
   */
  async close() {
    try {
      await mongoose.connection.close();
      console.log('✅ Database connection closed');
    } catch (error) {
      console.error('❌ Error closing database connection:', error);
      throw error;
    }
  }
}

// Export the migration class
module.exports = PaymentDatabaseMigration;

// If this script is run directly, execute the migrations
if (require.main === module) {
  const migration = new PaymentDatabaseMigration();
  
  migration.runMigrations()
    .then(() => {
      console.log('🎉 Migrations completed successfully!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('💥 Migrations failed:', error);
      process.exit(1);
    });
}
