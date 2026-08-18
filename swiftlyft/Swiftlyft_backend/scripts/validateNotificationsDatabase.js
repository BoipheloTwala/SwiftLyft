const mongoose = require('mongoose');
const Notification = require('../models/Notification');
require('dotenv').config();

class NotificationsDatabaseValidator {
  constructor() {
    this.connection = null;
    this.errors = [];
    this.warnings = [];
  }

  async connect() {
    try {
      const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_notifications';
      this.connection = await mongoose.connect(mongoUri, {
        useNewUrlParser: true,
        useUnifiedTopology: true,
      });
      console.log('✅ Connected to MongoDB for Notifications validation');
      console.log(`📊 Database: ${mongoose.connection.name}`);
      return this.connection;
    } catch (error) {
      console.error('❌ MongoDB connection error:', error);
      throw error;
    }
  }

  addError(message, details = null) { this.errors.push({ message, details, timestamp: new Date() }); }
  addWarning(message, details = null) { this.warnings.push({ message, details, timestamp: new Date() }); }

  async validateConnection() {
    try {
      console.log('🔍 Validating Notifications database connection...');
      await this.connection.connection.db.admin().ping();
      console.log('✅ Notifications database connection is healthy');
      return true;
    } catch (error) {
      this.addError('Database connection failed', error.message);
      return false;
    }
  }

  async validateCollection() {
    try {
      console.log('🔍 Validating Notifications collection...');
      const collections = await this.connection.connection.db.listCollections().toArray();
      const col = collections.find(c => c.name === 'notifications');
      if (!col) { this.addError('Notifications collection does not exist'); return false; }
      console.log('✅ Notifications collection exists');
      const stats = await this.connection.connection.db.collection('notifications').stats();
      console.log(`📊 Collection size: ${(stats.size / 1024 / 1024).toFixed(2)} MB`);
      console.log(`📊 Document count: ${stats.count}`);
      return true;
    } catch (error) {
      this.addError('Collection validation failed', error.message);
      return false;
    }
  }

  async validateIndexes() {
    try {
      console.log('🔍 Validating Notifications indexes...');
      const indexes = await Notification.collection.getIndexes();
      const existing = Object.keys(indexes);
      const required = [
        'userId_1_createdAt_-1',
        'type_1_createdAt_-1',
        'scheduledFor_1',
        'expiresAt_1',
        'priority_1_createdAt_-1',
        'status.inApp.read_1_createdAt_-1',
        'status.push.sent_1_createdAt_-1',
        'status.email.sent_1_createdAt_-1',
        'status.sms.sent_1_createdAt_-1',
        'channels_1_createdAt_-1'
      ];
      for (const idx of required) {
        if (!existing.includes(idx)) this.addError(`Required index missing: ${idx}`); else console.log(`✅ Index exists: ${idx}`);
      }
      console.log(`📊 Total indexes: ${existing.length}`);
      return this.errors.length === 0;
    } catch (error) {
      this.addError('Index validation failed', error.message);
      return false;
    }
  }

  async validateDocuments() {
    try {
      console.log('🔍 Validating Notifications documents...');
      const total = await Notification.countDocuments();
      if (total === 0) { this.addWarning('No notifications found'); return true; }
      console.log(`📊 Total notifications: ${total}`);

      const missingUser = await Notification.countDocuments({ userId: { $exists: false } });
      if (missingUser > 0) this.addError(`${missingUser} notifications missing userId`);

      const missingType = await Notification.countDocuments({ type: { $exists: false } });
      if (missingType > 0) this.addError(`${missingType} notifications missing type`);

      const missingTitle = await Notification.countDocuments({ title: { $exists: false } });
      if (missingTitle > 0) this.addError(`${missingTitle} notifications missing title`);

      const missingMessage = await Notification.countDocuments({ message: { $exists: false } });
      if (missingMessage > 0) this.addError(`${missingMessage} notifications missing message`);

      const invalidTypes = await Notification.countDocuments({
        type: { $nin: ['booking_confirmed','driver_assigned','driver_arrived','trip_started','trip_completed','payment_received','payment_failed','quote_ready','driver_cancelled','system_update','promotion','loyalty_points','support_response','reminder'] }
      });
      if (invalidTypes > 0) this.addError(`${invalidTypes} notifications have invalid type`);

      const invalidPriorities = await Notification.countDocuments({ priority: { $nin: ['low','normal','high','urgent'] } });
      if (invalidPriorities > 0) this.addError(`${invalidPriorities} notifications have invalid priority`);

      const invalidChannels = await Notification.countDocuments({ channels: { $elemMatch: { $nin: ['push','email','sms','in_app'] } } });
      if (invalidChannels > 0) this.addError(`${invalidChannels} notifications have invalid channel values`);

      const expiredButUnread = await Notification.countDocuments({ expiresAt: { $lt: new Date() }, 'status.inApp.read': false });
      if (expiredButUnread > 0) this.addWarning(`${expiredButUnread} expired notifications are still unread`);

      return this.errors.length === 0;
    } catch (error) {
      this.addError('Document validation failed', error.message);
      return false;
    }
  }

  async validateMethods() {
    try {
      console.log('🔍 Validating Notifications instance/static methods...');
      const one = await Notification.findOne();
      if (one) {
        await one.updateDeliveryStatus('push', true);
        await one.markAsRead();
      }
      const unread = await Notification.findUnread(one ? one.userId : new mongoose.Types.ObjectId());
      if (!Array.isArray(unread)) this.addError('findUnread did not return an array');
      console.log('✅ Methods validation completed');
      return true;
    } catch (error) {
      this.addError('Methods validation failed', error.message);
      return false;
    }
  }

  async validateAPICompatibility() {
    try {
      console.log('🔍 Validating Notifications API compatibility...');
      const n = await Notification.findOne();
      if (!n) { this.addWarning('No documents to validate API shape'); return true; }
      const obj = n.toJSON();
      const required = ['id','userId','type','title','message','channels','priority','status'];
      for (const f of required) if (!(f in obj)) this.addError(`Missing field in API response: ${f}`);
      if ('__v' in obj) this.addError('Version key should not be exposed');
      return this.errors.length === 0;
    } catch (error) {
      this.addError('API compatibility validation failed', error.message);
      return false;
    }
  }

  async validatePerformance() {
    try {
      console.log('🔍 Validating Notifications performance...');
      const t1 = Date.now(); await Notification.find({ 'status.inApp.read': false }).limit(50); const dt1 = Date.now() - t1;
      const t2s = Date.now(); await Notification.find({ type: 'booking_confirmed' }).limit(50); const dt2 = Date.now() - t2s;
      const t3s = Date.now(); await Notification.find({ scheduledFor: { $gt: new Date() } }).limit(50); const dt3 = Date.now() - t3s;
      const warn = (name, val, thr) => { if (val > thr) this.addWarning(`${name} query slow: ${val}ms (thr ${thr}ms)`); };
      warn('Unread', dt1, 300); warn('Type', dt2, 200); warn('Scheduled', dt3, 200);
      console.log(`📊 Query times: unread=${dt1}ms type=${dt2}ms scheduled=${dt3}ms`);
      return true;
    } catch (error) {
      this.addError('Performance validation failed', error.message);
      return false;
    }
  }

  report() {
    console.log('\n📋 NOTIFICATIONS VALIDATION REPORT');
    console.log('='.repeat(50));
    if (this.errors.length === 0) console.log('✅ All Notifications validations passed!');
    else {
      console.log(`❌ ${this.errors.length} errors:`);
      this.errors.forEach((e,i)=>{ console.log(`  ${i+1}. ${e.message}`); if (e.details) console.log(`     Details: ${e.details}`); });
    }
    if (this.warnings.length > 0) {
      console.log(`\n⚠️ ${this.warnings.length} warnings:`);
      this.warnings.forEach((w,i)=>{ console.log(`  ${i+1}. ${w.message}`); if (w.details) console.log(`     Details: ${w.details}`); });
    }
    console.log(`\n📊 Summary: Errors=${this.errors.length} Warnings=${this.warnings.length} Status=${this.errors.length===0?'PASS':'FAIL'}`);
    return { errors: this.errors, warnings: this.warnings, passed: this.errors.length===0 };
  }

  async runAll() {
    try {
      console.log('🚀 Starting comprehensive Notifications validation...');
      await this.connect();
      await this.validateConnection();
      await this.validateCollection();
      await this.validateIndexes();
      await this.validateDocuments();
      await this.validateMethods();
      await this.validateAPICompatibility();
      await this.validatePerformance();
      return this.report();
    } catch (error) {
      this.addError('Validation process failed', error.message);
      return this.report();
    }
  }
}

if (require.main === module) {
  const validator = new NotificationsDatabaseValidator();
  validator.runAll()
    .then((r)=>{ console.log(`\n🏁 Notifications validation ${r.passed?'SUCCESS':'FAILURE'}`); process.exit(r.passed?0:1); })
    .catch((e)=>{ console.error('❌ Notifications validation failed:', e); process.exit(1); });
}

module.exports = NotificationsDatabaseValidator;
