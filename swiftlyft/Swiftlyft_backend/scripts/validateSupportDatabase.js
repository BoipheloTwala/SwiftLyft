const mongoose = require('mongoose');
require('dotenv').config();
const { SupportTicket, SupportMessage, FAQ } = require('../models/Support');

class SupportDatabaseValidator {
  constructor(){ this.connection=null; this.errors=[]; this.warnings=[]; }

  async connect(){
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_support';
    this.connection = await mongoose.connect(mongoUri, { useNewUrlParser:true, useUnifiedTopology:true });
    console.log('✅ Connected to MongoDB for Support validation');
      console.log(`📊 Database: ${mongoose.connection.name}`);
  }

  addError(m,d=null){ this.errors.push({ message:m, details:d, timestamp:new Date() }); }
  addWarning(m,d=null){ this.warnings.push({ message:m, details:d, timestamp:new Date() }); }

  async validateConnection(){
    console.log('🔍 Validating DB connection...');
    await this.connection.connection.db.admin().ping();
    console.log('✅ DB connection healthy');
  }

  async validateCollections(){
    console.log('🔍 Validating collections exist...');
    const cols = await this.connection.connection.db.listCollections().toArray();
    const names = cols.map(c=>c.name);
    ;['supporttickets','supportmessages','faqs'].forEach(n=>{
      if (!names.includes(n)) this.addError(`${n} collection missing`); else console.log(`✅ ${n} exists`);
    });
  }

  async validateIndexes(){
    console.log('🔍 Validating indexes...');
    const idxT = Object.keys(await SupportTicket.collection.getIndexes());
    const idxM = Object.keys(await SupportMessage.collection.getIndexes());
    const idxF = Object.keys(await FAQ.collection.getIndexes());

    const reqT = ['ticketId_1','userId_1_createdAt_-1','status_1_priority_1','category_1'];
    const reqM = ['ticketId_1_createdAt_1'];
    const reqF = ['category_1_isActive_1','tags_1'];

    reqT.forEach(r=>{ if (!idxT.includes(r)) this.addError(`SupportTicket missing index: ${r}`); else console.log(`✅ SupportTicket index: ${r}`); });
    reqM.forEach(r=>{ if (!idxM.includes(r)) this.addError(`SupportMessage missing index: ${r}`); else console.log(`✅ SupportMessage index: ${r}`); });
    reqF.forEach(r=>{ if (!idxF.includes(r)) this.addError(`FAQ missing index: ${r}`); else console.log(`✅ FAQ index: ${r}`); });
  }

  async validateDocuments(){
    console.log('🔍 Validating documents...');
    const badCats = await SupportTicket.countDocuments({ category: { $nin: ['booking_issue','payment_problem','driver_issue','app_technical','account_issue','billing_inquiry','safety_concern','feature_request','general_inquiry','corporate_support'] } });
    if (badCats>0) this.addError(`${badCats} support tickets have invalid category`);

    const badStatus = await SupportTicket.countDocuments({ status: { $nin: ['open','in_progress','waiting_for_user','resolved','closed'] } });
    if (badStatus>0) this.addWarning(`${badStatus} support tickets have invalid status`);

    const badSender = await SupportMessage.countDocuments({ senderType: { $nin: ['user','agent','system'] } });
    if (badSender>0) this.addError(`${badSender} messages have invalid senderType`);

    const badFAQ = await FAQ.countDocuments({ category: { $nin: ['general','getting_started','booking','payment','driver','account','safety','corporate','technical'] } });
    if (badFAQ>0) this.addError(`${badFAQ} FAQs have invalid category`);
  }

  async validateMethods(){
    console.log('🔍 Validating methods & virtuals...');
    const t = await SupportTicket.findOne();
    if (t){ t.isResolved; t.responseTime; }
    const f = await FAQ.findOne();
    if (f){ await FAQ.searchFAQs('book'); }
  }

  async validatePerformance(){
    console.log('🔍 Validating performance...');
    const t1=Date.now(); await SupportTicket.find({}).sort({ createdAt:-1 }).limit(50); const d1=Date.now()-t1;
    const t2=Date.now(); await SupportMessage.find({}).limit(50); const d2=Date.now()-t2;
    const t3=Date.now(); await FAQ.find({ isActive:true }).limit(50); const d3=Date.now()-t3;
    ;[['Tickets',d1],['Messages',d2],['FAQs',d3]].forEach(([n,d])=>{ if (d>500) this.addWarning(`${n} query slow: ${d}ms`); });
    console.log(`📊 timings: tickets=${d1}ms messages=${d2}ms faqs=${d3}ms`);
  }

  report(){
    console.log('\n📋 SUPPORT VALIDATION REPORT');
    console.log('='.repeat(50));
    if (this.errors.length===0) console.log('✅ All Support validations passed!');
    else { console.log(`❌ ${this.errors.length} errors:`); this.errors.forEach((e,i)=>console.log(`  ${i+1}. ${e.message}`)); }
    if (this.warnings.length) { console.log(`\n⚠️ ${this.warnings.length} warnings:`); this.warnings.forEach((w,i)=>console.log(`  ${i+1}. ${w.message}`)); }
    console.log(`\n📊 Summary: Errors=${this.errors.length} Warnings=${this.warnings.length} Status=${this.errors.length===0?'PASS':'FAIL'}`);
    return { passed:this.errors.length===0, errors:this.errors, warnings:this.warnings };
  }

  async runAll(){
    try{
      console.log('🚀 Starting comprehensive Support validation...');
      await this.connect();
      await this.validateConnection();
      await this.validateCollections();
      await this.validateIndexes();
      await this.validateDocuments();
      await this.validateMethods();
      await this.validatePerformance();
      return this.report();
    }catch(e){ this.addError('Validation failed', e.message); return this.report(); }
  }
}

if (require.main === module){
  new SupportDatabaseValidator().runAll()
    .then(r=>{ console.log(`\n🏁 Support validation ${r.passed?'SUCCESS':'FAILURE'}`); process.exit(r.passed?0:1); })
    .catch(e=>{ console.error('❌ Support validation failed:', e); process.exit(1); });
}

module.exports = SupportDatabaseValidator;
