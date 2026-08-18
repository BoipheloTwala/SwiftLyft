const mongoose = require('mongoose');
const Vehicle = require('../models/Vehicle');
require('dotenv').config();

class VehiclesDatabaseValidator {
  constructor(){ this.connection=null; this.errors=[]; this.warnings=[]; }
  async connect(){
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_vehicles';
    this.connection = await mongoose.connect(mongoUri, { useNewUrlParser:true, useUnifiedTopology:true });
    console.log('✅ Connected to MongoDB for Vehicles validation');
      console.log(`📊 Database: ${mongoose.connection.name}`);
  }
  addError(m,d=null){ this.errors.push({ message:m, details:d, timestamp:new Date() }); }
  addWarning(m,d=null){ this.warnings.push({ message:m, details:d, timestamp:new Date() }); }

  async validateConnection(){
    console.log('🔍 Validating DB connection...');
    await this.connection.connection.db.admin().ping();
    console.log('✅ DB connection healthy');
  }
  async validateCollection(){
    console.log('🔍 Validating collection exists...');
    const cols = await this.connection.connection.db.listCollections().toArray();
    const names = cols.map(c=>c.name);
    if (!names.includes('vehicles')) this.addError('vehicles collection missing'); else console.log('✅ vehicles exists');
  }
  async validateIndexes(){
    console.log('🔍 Validating indexes...');
    const idx = Object.keys(await Vehicle.collection.getIndexes());
    const required = ['vehicleId_1','driverId_1','status_1','category_1','licensePlate_1','vin_1'];
    required.forEach(r=>{ if (!idx.includes(r)) this.addError(`Missing index: ${r}`); else console.log(`✅ Index: ${r}`); });
  }
  async validateDocuments(){
    console.log('🔍 Validating documents...');
    const invalidCategory = await Vehicle.countDocuments({ category: { $nin: ['sedan','suv','luxury','van','truck','motorcycle','electric','hybrid'] } });
    if (invalidCategory>0) this.addError(`${invalidCategory} vehicles have invalid category`);

    const invalidStatus = await Vehicle.countDocuments({ status: { $nin: ['available','busy','offline','maintenance','out_of_service'] } });
    if (invalidStatus>0) this.addWarning(`${invalidStatus} vehicles have out-of-range status`);
  }
  async validateMethods(){
    console.log('🔍 Validating model methods & virtuals...');
    const vehicle = await Vehicle.findOne();
    if (vehicle){
      vehicle.fullName; vehicle.displayName; vehicle.isCurrentlyAvailable; vehicle.age;
      await vehicle.updateStatus('available');
      await vehicle.updateAvailability(true);
    }
  }
  async validatePerformance(){
    console.log('🔍 Validating query performance...');
    const t = Date.now(); await Vehicle.find({ status: 'available' }).limit(50); const d = Date.now()-t;
    if (d>500) this.addWarning(`Available vehicles query slow: ${d}ms`);
    console.log(`📊 availableQuery=${d}ms`);
  }
  report(){
    console.log('\n📋 VEHICLES VALIDATION REPORT');
    console.log('='.repeat(50));
    if (this.errors.length===0) console.log('✅ All Vehicles validations passed!');
    else { console.log(`❌ ${this.errors.length} errors:`); this.errors.forEach((e,i)=>console.log(`  ${i+1}. ${e.message}`)); }
    if (this.warnings.length) { console.log(`\n⚠️ ${this.warnings.length} warnings:`); this.warnings.forEach((w,i)=>console.log(`  ${i+1}. ${w.message}`)); }
    console.log(`\n📊 Summary: Errors=${this.errors.length} Warnings=${this.warnings.length} Status=${this.errors.length===0?'PASS':'FAIL'}`);
    return { passed: this.errors.length===0, errors:this.errors, warnings:this.warnings };
  }
  async runAll(){
    try{
      console.log('🚀 Starting comprehensive Vehicles validation...');
      await this.connect();
      await this.validateConnection();
      await this.validateCollection();
      await this.validateIndexes();
      await this.validateDocuments();
      await this.validateMethods();
      await this.validatePerformance();
      return this.report();
    }catch(e){
      this.addError('Validation failed', e.message);
      return this.report();
    }
  }
}

if (require.main === module){
  new VehiclesDatabaseValidator().runAll()
    .then(r=>{ console.log(`\n🏁 Vehicles validation ${r.passed?'SUCCESS':'FAILURE'}`); process.exit(r.passed?0:1); })
    .catch(e=>{ console.error('❌ Vehicles validation failed:', e); process.exit(1); });
}

module.exports = VehiclesDatabaseValidator;
