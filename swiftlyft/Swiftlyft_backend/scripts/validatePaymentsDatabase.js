const mongoose = require('mongoose');
const { PaymentMethod, Payment } = require('../models/Payment');
require('dotenv').config();

class PaymentsDatabaseValidator {
  constructor() {
    this.connection = null;
    this.errors = [];
    this.warnings = [];
  }

  async connect() {
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_payments';
    this.connection = await mongoose.connect(mongoUri, { useNewUrlParser: true, useUnifiedTopology: true });
    console.log('✅ Connected to MongoDB for Payments validation');
      console.log(`📊 Database: ${mongoose.connection.name}`);
  }

  addError(m, d=null){ this.errors.push({ message:m, details:d, timestamp:new Date() }); }
  addWarning(m, d=null){ this.warnings.push({ message:m, details:d, timestamp:new Date() }); }

  async validateConnection(){
    console.log('🔍 Validating Payments DB connection...');
    await this.connection.connection.db.admin().ping();
    console.log('✅ Payments DB connection healthy');
  }

  async validateCollections(){
    console.log('🔍 Validating Payments collections exist...');
    const cols = await this.connection.connection.db.listCollections().toArray();
    const names = cols.map(c=>c.name);
    if (!names.includes('paymentmethods')) this.addError('paymentmethods collection missing');
    if (!names.includes('payments')) this.addError('payments collection missing');
    console.log('✅ Collections checked');
  }

  async validateIndexes(){
    console.log('🔍 Validating indexes...');
    const idxPM = Object.keys(await PaymentMethod.collection.getIndexes());
    const idxP = Object.keys(await Payment.collection.getIndexes());

    const requiredPM = ['userId_1','userId_1_isDefault_1','externalId_1','provider_1_type_1','createdAt_-1','isActive_1_createdAt_-1'];
    const requiredP = ['userId_1','bookingId_1','status_1','externalTransactionId_1','createdAt_-1','transactionType_1_createdAt_-1','processedAt_-1','refunds.status_1_refunds.createdAt_-1','userId_1_status_1_createdAt_-1'];

    for (const r of requiredPM) if (!idxPM.includes(r)) this.addError(`PaymentMethod missing index: ${r}`); else console.log(`✅ PM index: ${r}`);
    for (const r of requiredP) if (!idxP.includes(r)) this.addError(`Payment missing index: ${r}`); else console.log(`✅ P index: ${r}`);
  }

  async validateDocuments(){
    console.log('🔍 Validating documents...');
    const pmCount = await PaymentMethod.countDocuments();
    const pCount = await Payment.countDocuments();
    if (pmCount === 0) this.addWarning('No PaymentMethod documents found');
    if (pCount === 0) this.addWarning('No Payment documents found');

    const invalidPMTypes = await PaymentMethod.countDocuments({ type: { $nin: ['credit_card','debit_card','bank_transfer','digital_wallet','cash'] } });
    if (invalidPMTypes > 0) this.addError(`${invalidPMTypes} PaymentMethods have invalid type`);

    const invalidProviders = await PaymentMethod.countDocuments({ provider: { $nin: ['visa','mastercard','amex','paypal','apple_pay','google_pay','eft','cash'] } });
    if (invalidProviders > 0) this.addError(`${invalidProviders} PaymentMethods have invalid provider`);

    const invalidPStatuses = await Payment.countDocuments({ status: { $nin: ['pending','processing','completed','failed','cancelled','refunded','partially_refunded'] } });
    if (invalidPStatuses > 0) this.addError(`${invalidPStatuses} Payments have invalid status`);

    const invalidPTypes = await Payment.countDocuments({ transactionType: { $nin: ['payment','refund','partial_refund'] } });
    if (invalidPTypes > 0) this.addError(`${invalidPTypes} Payments have invalid transactionType`);

    const negativeAmounts = await Payment.countDocuments({ $or: [{ amount: { $lte: 0 } }, { processingFee: { $lt: 0 } }, { netAmount: { $lt: 0 } }] });
    if (negativeAmounts > 0) this.addError(`${negativeAmounts} Payments have invalid numeric amounts`);

    const overRefunded = await Payment.countDocuments({ $expr: { $gt: ['$totalRefunded', '$amount'] } });
    if (overRefunded > 0) this.addError(`${overRefunded} Payments have totalRefunded greater than amount`);
  }

  async validateMethods(){
    console.log('🔍 Validating instance/static methods...');
    const pm = await PaymentMethod.findOne();
    if (pm) { pm.maskCardNumber(); pm.isExpired(); }
    const p = await Payment.findOne();
    if (p) { p.canRefund(); p.getRefundableAmount(); }
    console.log('✅ Methods validated');
  }

  async validatePerformance(){
    console.log('🔍 Validating performance...');
    const t1 = Date.now(); await Payment.find({ status: 'completed' }).limit(50); const dt1 = Date.now() - t1;
    const t2 = Date.now(); await Payment.find({ userId: { $exists: true } }).sort({ createdAt: -1 }).limit(50); const dt2 = Date.now() - t2;
    if (dt1 > 400) this.addWarning(`Completed payments query slow: ${dt1}ms`);
    if (dt2 > 400) this.addWarning(`Recent payments query slow: ${dt2}ms`);
    console.log(`📊 Query times: completed=${dt1}ms recent=${dt2}ms`);
  }

  report(){
    console.log('\n📋 PAYMENTS VALIDATION REPORT');
    console.log('='.repeat(50));
    if (this.errors.length === 0) console.log('✅ All Payments validations passed!');
    else { console.log(`❌ ${this.errors.length} errors:`); this.errors.forEach((e,i)=>console.log(`  ${i+1}. ${e.message}`)); }
    if (this.warnings.length) { console.log(`\n⚠️ ${this.warnings.length} warnings:`); this.warnings.forEach((w,i)=>console.log(`  ${i+1}. ${w.message}`)); }
    console.log(`\n📊 Summary: Errors=${this.errors.length} Warnings=${this.warnings.length} Status=${this.errors.length===0?'PASS':'FAIL'}`);
    return { errors:this.errors, warnings:this.warnings, passed:this.errors.length===0 };
  }

  async runAll(){
    try {
      console.log('🚀 Starting comprehensive Payments validation...');
      await this.connect();
      await this.validateConnection();
      await this.validateCollections();
      await this.validateIndexes();
      await this.validateDocuments();
      await this.validateMethods();
      await this.validatePerformance();
      return this.report();
    } catch (e) {
      this.addError('Validation failed', e.message);
      return this.report();
    }
  }
}

if (require.main === module) {
  const v = new PaymentsDatabaseValidator();
  v.runAll().then(r=>{ console.log(`\n🏁 Payments validation ${r.passed?'SUCCESS':'FAILURE'}`); process.exit(r.passed?0:1); }).catch(e=>{ console.error('❌ Payments validation failed:', e); process.exit(1); });
}

module.exports = PaymentsDatabaseValidator;
