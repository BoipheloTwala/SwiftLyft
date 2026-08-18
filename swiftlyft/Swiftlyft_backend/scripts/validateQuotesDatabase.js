const mongoose = require('mongoose');
const Quote = require('../models/Quote');
require('dotenv').config();

class QuotesDatabaseValidator {
  constructor(){ this.connection=null; this.errors=[]; this.warnings=[]; }
  async connect(){
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_quotes';
    this.connection = await mongoose.connect(mongoUri, { useNewUrlParser:true, useUnifiedTopology:true });
    console.log('✅ Connected to MongoDB for Quotes validation');
      console.log(`📊 Database: ${mongoose.connection.name}`);
  }
  addError(m,d=null){ this.errors.push({ message:m, details:d, timestamp:new Date() }); }
  addWarning(m,d=null){ this.warnings.push({ message:m, details:d, timestamp:new Date() }); }

  async validateConnection(){
    console.log('🔍 Validating Quotes DB connection...');
    await this.connection.connection.db.admin().ping();
    console.log('✅ Quotes DB connection healthy');
  }

  async validateCollection(){
    console.log('🔍 Validating Quotes collection...');
    const cols = await this.connection.connection.db.listCollections().toArray();
    if (!cols.find(c=>c.name==='quotes')) this.addError('quotes collection missing');
    else console.log('✅ quotes collection exists');
  }

  async validateIndexes(){
    console.log('🔍 Validating indexes...');
    const idx = Object.keys(await Quote.collection.getIndexes());
    const required = [
      'userId_1_createdAt_-1',
      'status_1_validUntil_1',
      'scheduledDate_1',
      'vehicleType_1_serviceType_1',
      'pickupLocation.address_1',
      'dropoffLocation.address_1',
      'estimatedPrice.total_-1'
    ];
    for (const r of required){ if (!idx.includes(r)) this.addError(`Missing index: ${r}`); else console.log(`✅ Index exists: ${r}`); }
  }

  async validateDocuments(){
    console.log('🔍 Validating documents...');
    const total = await Quote.countDocuments();
    if (total===0) { this.addWarning('No quote documents found'); return; }

    const missingUser = await Quote.countDocuments({ userId: { $exists: false } });
    if (missingUser>0) this.addError(`${missingUser} quotes missing userId`);

    const invalidVehicle = await Quote.countDocuments({ vehicleType: { $nin: ['sedan','suv','luxury','van','truck','motorcycle'] } });
    if (invalidVehicle>0) this.addError(`${invalidVehicle} quotes have invalid vehicleType`);

    const invalidService = await Quote.countDocuments({ serviceType: { $nin: ['standard','premium','corporate','airport','security'] } });
    if (invalidService>0) this.addError(`${invalidService} quotes have invalid serviceType`);

    const invalidPax = await Quote.countDocuments({ $or: [ { passengerCount: { $lt: 1 } }, { passengerCount: { $gt: 20 } } ] });
    if (invalidPax>0) this.addError(`${invalidPax} quotes have invalid passengerCount`);

    const pastSchedule = await Quote.countDocuments({ scheduledDate: { $lte: new Date() } });
    if (pastSchedule>0) this.addWarning(`${pastSchedule} quotes have scheduledDate in the past`);
  }

  async validateMethods(){
    console.log('🔍 Validating virtuals/methods...');
    const q = await Quote.findOne();
    if (q){ q.isExpired; q.canAccept(); }
  }

  async validatePerformance(){
    console.log('🔍 Validating performance...');
    const t1 = Date.now(); await Quote.find({ userId: { $exists: true } }).sort({ createdAt: -1 }).limit(50); const dt1 = Date.now()-t1;
    const t2 = Date.now(); await Quote.find({ status: 'quoted' }).limit(50); const dt2 = Date.now()-t2;
    if (dt1>400) this.addWarning(`Recent quotes query slow: ${dt1}ms`);
    if (dt2>400) this.addWarning(`Quoted quotes query slow: ${dt2}ms`);
    console.log(`📊 Query times: recent=${dt1}ms quoted=${dt2}ms`);
  }

  report(){
    console.log('\n📋 QUOTES VALIDATION REPORT');
    console.log('='.repeat(50));
    if (this.errors.length===0) console.log('✅ All Quotes validations passed!');
    else { console.log(`❌ ${this.errors.length} errors:`); this.errors.forEach((e,i)=>console.log(`  ${i+1}. ${e.message}`)); }
    if (this.warnings.length) { console.log(`\n⚠️ ${this.warnings.length} warnings:`); this.warnings.forEach((w,i)=>console.log(`  ${i+1}. ${w.message}`)); }
    console.log(`\n📊 Summary: Errors=${this.errors.length} Warnings=${this.warnings.length} Status=${this.errors.length===0?'PASS':'FAIL'}`);
    return { errors:this.errors, warnings:this.warnings, passed:this.errors.length===0 };
  }

  async runAll(){
    try{
      console.log('🚀 Starting comprehensive Quotes validation...');
      await this.connect();
      await this.validateConnection();
      await this.validateCollection();
      await this.validateIndexes();
      await this.validateDocuments();
      await this.validateMethods();
      await this.validatePerformance();
      return this.report();
    } catch (e){
      this.addError('Validation failed', e.message);
      return this.report();
    }
  }
}

if (require.main === module){
  const v = new QuotesDatabaseValidator();
  v.runAll().then(r=>{ console.log(`\n🏁 Quotes validation ${r.passed?'SUCCESS':'FAILURE'}`); process.exit(r.passed?0:1); }).catch(e=>{ console.error('❌ Quotes validation failed:', e); process.exit(1); });
}

module.exports = QuotesDatabaseValidator;
