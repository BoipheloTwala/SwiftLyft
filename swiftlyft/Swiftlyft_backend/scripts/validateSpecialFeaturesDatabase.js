const mongoose = require('mongoose');
const {
  Offer,
  CorporateBooking,
  SecurityService,
  AirportService
} = require('../models/SpecialFeatures');
require('dotenv').config();

class SpecialFeaturesDatabaseValidator {
  constructor() {
    this.connection = null;
    this.errors = [];
    this.warnings = [];
  }

  async connect() {
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_special_features';
    this.connection = await mongoose.connect(mongoUri, { useNewUrlParser: true, useUnifiedTopology: true });
    console.log('✅ Connected to MongoDB for SpecialFeatures validation');
      console.log(`📊 Database: ${mongoose.connection.name}`);
  }

  addError(m, d=null){ this.errors.push({ message:m, details:d, timestamp:new Date() }); }
  addWarning(m, d=null){ this.warnings.push({ message:m, details:d, timestamp:new Date() }); }

  async validateConnection(){
    console.log('🔍 Validating SpecialFeatures DB connection...');
    await this.connection.connection.db.admin().ping();
    console.log('✅ SpecialFeatures DB connection healthy');
  }

  async validateCollections(){
    console.log('🔍 Validating collections exist...');
    const cols = await this.connection.connection.db.listCollections().toArray();
    const names = cols.map(c=>c.name);
    ['offers','corporatebookings','securityservices','airportservices'].forEach(n=>{
      if (!names.includes(n)) this.addError(`${n} collection missing`); else console.log(`✅ ${n} exists`);
    });
  }

  async validateIndexes(){
    console.log('🔍 Validating indexes...');
    const idxOffer = Object.keys(await Offer.collection.getIndexes());
    const idxCorp = Object.keys(await CorporateBooking.collection.getIndexes());
    const idxSec = Object.keys(await SecurityService.collection.getIndexes());
    const idxAir = Object.keys(await AirportService.collection.getIndexes());

    const requiredOffer = ['promoCode_1','type_1_isActive_1','startDate_1_endDate_1'];
    const requiredCorp = ['corporateAccountId_1_createdAt_-1','userId_1_status_1'];
    const requiredSec = ['bookingId_1','status_1'];
    const requiredAir = ['bookingId_1','flightDetails.scheduledTime_1'];

    requiredOffer.forEach(r=>{ if (!idxOffer.includes(r)) this.addError(`Offer missing index: ${r}`); else console.log(`✅ Offer index: ${r}`); });
    requiredCorp.forEach(r=>{ if (!idxCorp.includes(r)) this.addError(`CorporateBooking missing index: ${r}`); else console.log(`✅ Corporate index: ${r}`); });
    requiredSec.forEach(r=>{ if (!idxSec.includes(r)) this.addError(`SecurityService missing index: ${r}`); else console.log(`✅ Security index: ${r}`); });
    requiredAir.forEach(r=>{ if (!idxAir.includes(r)) this.addError(`AirportService missing index: ${r}`); else console.log(`✅ Airport index: ${r}`); });
  }

  async validateDocuments(){
    console.log('🔍 Validating documents...');
    const offerInvalid = await Offer.countDocuments({ type: { $nin: ['discount','discount_percentage','discount_fixed','free_ride','loyalty_bonus','first_ride'] } });
    if (offerInvalid>0) this.addError(`${offerInvalid} offers have invalid type`);

    const corpInvalid = await CorporateBooking.countDocuments({ bookingType: { $nin: ['business','business_travel','event_transport','single_trip','bulk_trips','recurring','shuttle_service'] } });
    if (corpInvalid>0) this.addError(`${corpInvalid} corporate bookings have invalid bookingType`);

    const secInvalidType = await SecurityService.countDocuments({ serviceType: { $nin: ['close_protection','security_escort','asset_transport','event_security'] } });
    if (secInvalidType>0) this.addError(`${secInvalidType} security services have invalid serviceType`);

    const secInvalidLevel = await SecurityService.countDocuments({ protectionLevel: { $nin: ['standard','enhanced','premium'] } });
    if (secInvalidLevel>0) this.addError(`${secInvalidLevel} security services have invalid protectionLevel`);

    const airInvalid = await AirportService.countDocuments({ serviceType: { $nin: ['pickup','dropoff','meet_and_greet','vip_service','group_transport'] } });
    if (airInvalid>0) this.addError(`${airInvalid} airport services have invalid serviceType`);
  }

  async validateMethods(){
    console.log('🔍 Validating model methods...');
    const offer = await Offer.findOne(); if (offer) offer.isValid;
    const corp = await CorporateBooking.findOne(); if (corp){ corp.completionPercentage; corp.calculateTotalCost(); corp.getDiscountedTotal(); }
    const sec = await SecurityService.findOne(); if (sec) sec.calculateCost();
    const air = await AirportService.findOne(); if (air) AirportService.prototype.calculateCost.call(air);
  }

  async validatePerformance(){
    console.log('🔍 Validating performance...');
    const t1 = Date.now(); await Offer.find({ isActive: true }).limit(50); const dt1 = Date.now()-t1;
    const t2 = Date.now(); await CorporateBooking.find({}).sort({ createdAt:-1 }).limit(50); const dt2 = Date.now()-t2;
    const t3 = Date.now(); await SecurityService.find({ status: { $exists: true } }).limit(50); const dt3 = Date.now()-t3;
    const t4 = Date.now(); await AirportService.find({}).limit(50); const dt4 = Date.now()-t4;
    [ ['Offers',dt1], ['Corporate',dt2], ['Security',dt3], ['Airport',dt4] ].forEach(([n,d])=>{
      if (d>500) this.addWarning(`${n} query slow: ${d}ms`);
    });
    console.log(`📊 Times: offers=${dt1}ms corporate=${dt2}ms security=${dt3}ms airport=${dt4}ms`);
  }

  report(){
    console.log('\n📋 SPECIAL FEATURES VALIDATION REPORT');
    console.log('='.repeat(50));
    if (this.errors.length===0) console.log('✅ All SpecialFeatures validations passed!');
    else { console.log(`❌ ${this.errors.length} errors:`); this.errors.forEach((e,i)=>console.log(`  ${i+1}. ${e.message}`)); }
    if (this.warnings.length) { console.log(`\n⚠️ ${this.warnings.length} warnings:`); this.warnings.forEach((w,i)=>console.log(`  ${i+1}. ${w.message}`)); }
    console.log(`\n📊 Summary: Errors=${this.errors.length} Warnings=${this.warnings.length} Status=${this.errors.length===0?'PASS':'FAIL'}`);
    return { errors:this.errors, warnings:this.warnings, passed:this.errors.length===0 };
  }

  async runAll(){
    try {
      console.log('🚀 Starting comprehensive SpecialFeatures validation...');
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

if (require.main === module){
  const v = new SpecialFeaturesDatabaseValidator();
  v.runAll().then(r=>{ console.log(`\n🏁 SpecialFeatures validation ${r.passed?'SUCCESS':'FAILURE'}`); process.exit(r.passed?0:1); }).catch(e=>{ console.error('❌ SpecialFeatures validation failed:', e); process.exit(1); });
}

module.exports = SpecialFeaturesDatabaseValidator;
