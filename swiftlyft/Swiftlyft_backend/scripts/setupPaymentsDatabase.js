const mongoose = require('mongoose');
require('dotenv').config();

const { PaymentMethod, Payment } = require('../models/Payment');

class PaymentsDatabaseSetup {
  constructor() {
    this.connection = null;
  }

  async connect() {
    try {
      const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_payments';
      this.connection = await mongoose.connect(mongoUri, {
        useNewUrlParser: true,
        useUnifiedTopology: true,
      });
      console.log('✅ Connected to MongoDB for Payments');
      console.log(`📊 Database: ${mongoose.connection.name}`);
      return this.connection;
    } catch (error) {
      console.error('❌ MongoDB connection error:', error);
      throw error;
    }
  }

  async createIndexes() {
    try {
      console.log('🔍 Creating Payments database indexes...');

      // PaymentMethod indexes (from schema + helpful)
      await PaymentMethod.collection.createIndex({ userId: 1 });
      console.log('✅ PaymentMethod userId index');
      await PaymentMethod.collection.createIndex({ userId: 1, isDefault: 1 });
      console.log('✅ PaymentMethod userId + isDefault index');
      await PaymentMethod.collection.createIndex({ externalId: 1 });
      console.log('✅ PaymentMethod externalId index');
      await PaymentMethod.collection.createIndex({ provider: 1, type: 1 });
      console.log('✅ PaymentMethod provider + type index');
      await PaymentMethod.collection.createIndex({ createdAt: -1 });
      console.log('✅ PaymentMethod createdAt index');
      await PaymentMethod.collection.createIndex({ isActive: 1, createdAt: -1 });
      console.log('✅ PaymentMethod isActive + createdAt index');

      // Payment indexes (from schema + helpful)
      await Payment.collection.createIndex({ userId: 1 });
      console.log('✅ Payment userId index');
      await Payment.collection.createIndex({ bookingId: 1 });
      console.log('✅ Payment bookingId index');
      await Payment.collection.createIndex({ status: 1 });
      console.log('✅ Payment status index');
      await Payment.collection.createIndex({ externalTransactionId: 1 });
      console.log('✅ Payment externalTransactionId index');
      await Payment.collection.createIndex({ createdAt: -1 });
      console.log('✅ Payment createdAt index');
      await Payment.collection.createIndex({ transactionType: 1, createdAt: -1 });
      console.log('✅ Payment transactionType + createdAt index');
      await Payment.collection.createIndex({ processedAt: -1 });
      console.log('✅ Payment processedAt index');
      await Payment.collection.createIndex({ 'refunds.status': 1, 'refunds.createdAt': -1 });
      console.log('✅ Payment refunds.status + refunds.createdAt index');

      // Compound for common queries
      await Payment.collection.createIndex({ userId: 1, status: 1, createdAt: -1 });
      console.log('✅ Payment userId + status + createdAt compound index');

      console.log('🎉 All Payments indexes created successfully!');
    } catch (error) {
      console.error('❌ Error creating Payments indexes:', error);
      throw error;
    }
  }

  async validateSchema() {
    try {
      console.log('🔍 Validating Payments schema...');

      // Validate PaymentMethod document
      const pm = new PaymentMethod({
        userId: new mongoose.Types.ObjectId(),
        type: 'credit_card',
        provider: 'visa',
        lastFourDigits: '4242',
        expiryMonth: 12,
        expiryYear: new Date().getFullYear() + 2,
        cardholderName: 'Test User',
        isDefault: true,
        isActive: true,
        encryptedData: 'encrypted_blob',
      });
      await pm.validate();

      // Validate Payment document
      const pay = new Payment({
        userId: pm.userId,
        bookingId: new mongoose.Types.ObjectId(),
        paymentMethodId: new mongoose.Types.ObjectId(),
        amount: 500.0,
        currency: 'ZAR',
        status: 'pending',
        transactionType: 'payment',
        processingFee: 15.0,
        netAmount: 485.0,
        description: 'Test payment',
        metadata: { test: true }
      });
      await pay.validate();

      // Exercise instance methods
      pm.maskCardNumber();
      pm.isExpired();

      if (!pay.canRefund()) {
        // Simulate completion then refund
        pay.status = 'completed';
      }
      const refundable = pay.getRefundableAmount();
      if (refundable > 0) {
        await pay.addRefund({ amount: Math.min(50, refundable), reason: 'Test refund' });
      }

      console.log('✅ Payments schema validation passed');
    } catch (error) {
      console.error('❌ Payments schema validation failed:', error);
      throw error;
    }
  }

  async createSampleData() {
    try {
      console.log('🌱 Creating Payments sample data...');
      const existingPayments = await Payment.countDocuments();
      if (existingPayments > 0) {
        console.log('⚠️ Payments already exist, skipping sample data');
        return;
      }

      // Create some payment methods and payments
      const userId = new mongoose.Types.ObjectId();
      const methods = [
        new PaymentMethod({
          userId,
          type: 'credit_card', provider: 'visa', lastFourDigits: '4242',
          expiryMonth: 12, expiryYear: new Date().getFullYear() + 2,
          cardholderName: 'John Card', isDefault: true, encryptedData: 'enc1'
        }),
        new PaymentMethod({
          userId,
          type: 'digital_wallet', provider: 'apple_pay',
          isDefault: false, isActive: true, encryptedData: 'enc2'
        }),
      ];

      await PaymentMethod.insertMany(methods);

      const payments = [];
      for (let i = 0; i < 10; i++) {
        const amount = 100 + i * 25;
        const processingFee = Math.round((amount * 0.029 + 2.50) * 100) / 100;
        const netAmount = amount - processingFee;
        const status = i % 5 === 0 ? 'failed' : (i % 4 === 0 ? 'processing' : 'completed');
        const p = new Payment({
          userId,
          bookingId: new mongoose.Types.ObjectId(),
          paymentMethodId: methods[i % methods.length]._id,
          amount,
          currency: 'ZAR',
          status,
          transactionType: 'payment',
          processingFee,
          netAmount,
          description: `Payment #${i + 1}`,
          metadata: { idx: i },
          createdAt: new Date(Date.now() - i * 3600 * 1000),
          updatedAt: new Date(Date.now() - i * 3600 * 1000)
        });

        // Add a refund occasionally
        if (status === 'completed' && i % 3 === 0) {
          p.refunds.push({ amount: Math.min(30, amount / 2), reason: 'Customer request' });
        }
        payments.push(p);
      }

      await Payment.insertMany(payments);
      console.log('🎉 Payments sample data created successfully!');
    } catch (error) {
      console.error('❌ Error creating Payments sample data:', error);
      throw error;
    }
  }

  async healthCheck() {
    try {
      console.log('🏥 Running Payments health check...');
      const stats = await this.connection.connection.db.stats();
      console.log(`📊 Database size: ${(stats.dataSize / 1024 / 1024).toFixed(2)} MB`);
      console.log(`📊 Collections: ${stats.collections}`);
      console.log(`📊 Documents: ${stats.objects || 0}`);

      const methodCount = await PaymentMethod.countDocuments();
      const activeMethods = await PaymentMethod.countDocuments({ isActive: true });
      const defaultMethods = await PaymentMethod.countDocuments({ isDefault: true });

      const paymentCount = await Payment.countDocuments();
      const completed = await Payment.countDocuments({ status: 'completed' });
      const failed = await Payment.countDocuments({ status: 'failed' });
      const processing = await Payment.countDocuments({ status: 'processing' });
      const refunded = await Payment.countDocuments({ status: { $in: ['refunded', 'partially_refunded'] } });

      console.log(`📊 PaymentMethods: total=${methodCount} active=${activeMethods} default=${defaultMethods}`);
      console.log(`📊 Payments: total=${paymentCount} completed=${completed} failed=${failed} processing=${processing} refunded=${refunded}`);

      const revenueStats = await Payment.aggregate([
        { $match: { status: 'completed' } },
        { $group: { _id: null, gross: { $sum: '$amount' }, fees: { $sum: '$processingFee' }, net: { $sum: '$netAmount' } } }
      ]);
      if (revenueStats.length) {
        const r = revenueStats[0];
        console.log(`💰 Revenue: gross=R${r.gross.toFixed(2)} fees=R${r.fees.toFixed(2)} net=R${r.net.toFixed(2)}`);
      }

      const indexesPM = await PaymentMethod.collection.getIndexes();
      const indexesP = await Payment.collection.getIndexes();
      console.log(`🔍 Indexes PaymentMethod: ${Object.keys(indexesPM).length}`);
      console.log(`🔍 Indexes Payment: ${Object.keys(indexesP).length}`);

      console.log('🎉 Payments health check completed successfully!');
      return true;
    } catch (error) {
      console.error('❌ Payments health check failed:', error);
      return false;
    }
  }

  async setup(options = {}) {
    const { createIndexes = true, validateSchema = true, createSampleData = false, runHealthCheck = true } = options;
    try {
      console.log('🚀 Starting Payments database setup...');
      await this.connect();
      if (createIndexes) await this.createIndexes();
      if (validateSchema) await this.validateSchema();
      if (createSampleData) await this.createSampleData();
      if (runHealthCheck) await this.healthCheck();
      console.log('🎉 Payments database setup completed successfully!');
    } catch (error) {
      console.error('❌ Payments database setup failed:', error);
      throw error;
    }
  }
}

if (require.main === module) {
  const args = process.argv.slice(2);
  const options = {};
  if (args.includes('--sample-data')) options.createSampleData = true;
  if (args.includes('--no-indexes')) options.createIndexes = false;
  if (args.includes('--no-validation')) options.validateSchema = false;
  if (args.includes('--no-health-check')) options.runHealthCheck = false;

  const setup = new PaymentsDatabaseSetup();
  setup.setup(options)
    .then(() => { console.log('✅ Payments setup completed successfully'); process.exit(0); })
    .catch((err) => { console.error('❌ Payments setup failed:', err); process.exit(1); });
}

module.exports = PaymentsDatabaseSetup;
