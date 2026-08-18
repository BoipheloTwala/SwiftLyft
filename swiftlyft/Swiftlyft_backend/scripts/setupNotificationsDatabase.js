const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Notification = require('../models/Notification');

class NotificationsDatabaseSetup {
  constructor() {
    this.connection = null;
  }

  async connect() {
    try {
      const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_notifications';
      this.connection = await mongoose.connect(mongoUri, {
        useNewUrlParser: true,
        useUnifiedTopology: true,
      });
      console.log('✅ Connected to MongoDB for Notifications');
      console.log(`📊 Database: ${mongoose.connection.name}`);
      return this.connection;
    } catch (error) {
      console.error('❌ MongoDB connection error:', error);
      throw error;
    }
  }

  async createIndexes() {
    try {
      console.log('🔍 Creating Notifications database indexes...');

      // From schema
      await Notification.collection.createIndex({ userId: 1, createdAt: -1 });
      console.log('✅ Created userId + createdAt index');

      await Notification.collection.createIndex({ type: 1, createdAt: -1 });
      console.log('✅ Created type + createdAt index');

      await Notification.collection.createIndex({ scheduledFor: 1 });
      console.log('✅ Created scheduledFor index');

      await Notification.collection.createIndex({ expiresAt: 1 });
      console.log('✅ Created expiresAt index');

      // Useful additional indexes
      await Notification.collection.createIndex({ priority: 1, createdAt: -1 });
      console.log('✅ Created priority + createdAt index');

      await Notification.collection.createIndex({ 'status.inApp.read': 1, createdAt: -1 });
      console.log('✅ Created inApp.read + createdAt index');

      await Notification.collection.createIndex({ 'status.push.sent': 1, createdAt: -1 });
      console.log('✅ Created push.sent + createdAt index');

      await Notification.collection.createIndex({ 'status.email.sent': 1, createdAt: -1 });
      console.log('✅ Created email.sent + createdAt index');

      await Notification.collection.createIndex({ 'status.sms.sent': 1, createdAt: -1 });
      console.log('✅ Created sms.sent + createdAt index');

      await Notification.collection.createIndex({ channels: 1, createdAt: -1 });
      console.log('✅ Created channels + createdAt index');

      console.log('🎉 All Notifications indexes created successfully!');
    } catch (error) {
      console.error('❌ Error creating Notifications indexes:', error);
      throw error;
    }
  }

  async validateSchema() {
    try {
      console.log('🔍 Validating Notifications schema...');

      const testNotification = new Notification({
        userId: new mongoose.Types.ObjectId(),
        type: 'booking_confirmed',
        title: 'Booking Confirmed',
        message: 'Your booking ABC123 is confirmed.',
        data: { bookingId: 'ABC123', amount: 250.5 },
        channels: ['push', 'email'],
        priority: 'normal',
        status: {
          push: { sent: true, sentAt: new Date() },
          email: { sent: false },
          sms: { sent: false },
          inApp: { read: false }
        },
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
      });

      await testNotification.validate();
      console.log('✅ Notification schema validation passed');

      // Instance methods
      await testNotification.updateDeliveryStatus('email', true);
      await testNotification.markAsRead();
      console.log(`✅ Instance methods work: read=${testNotification.status.inApp.read}`);

      console.log('🎉 Notifications schema validation completed successfully!');
    } catch (error) {
      console.error('❌ Notifications schema validation failed:', error);
      throw error;
    }
  }

  async createSampleData() {
    try {
      console.log('🌱 Creating Notifications sample data...');
      const existing = await Notification.countDocuments();
      if (existing > 0) {
        console.log('⚠️ Notifications already exist, skipping sample data');
        return;
      }

      const types = [
        'booking_confirmed','driver_assigned','driver_arrived','trip_started','trip_completed',
        'payment_received','payment_failed','quote_ready','driver_cancelled','system_update',
        'promotion','loyalty_points','support_response','reminder'
      ];
      const priorities = ['low','normal','high','urgent'];
      const channelsList = [['push'], ['email'], ['sms'], ['in_app'], ['push','email'], ['push','sms'], ['push','email','sms']];

      const docs = [];
      for (let i = 0; i < 15; i++) {
        const type = types[i % types.length];
        const channels = channelsList[i % channelsList.length];
        const priority = priorities[i % priorities.length];
        const scheduled = i % 5 === 0 ? new Date(Date.now() + (i + 1) * 60 * 60 * 1000) : null;
        const expires = i % 6 === 0 ? new Date(Date.now() + (i + 3) * 24 * 60 * 60 * 1000) : null;

        docs.push({
          userId: new mongoose.Types.ObjectId(),
          type,
          title: `${type.replace('_',' ')} ${i + 1}`,
          message: `This is a ${type} notification #${i + 1}.`,
          data: { index: i },
          channels,
          priority,
          status: {
            push: { sent: channels.includes('push') && i % 2 === 0, sentAt: channels.includes('push') && i % 2 === 0 ? new Date() : undefined },
            email: { sent: channels.includes('email') && i % 3 === 0, sentAt: channels.includes('email') && i % 3 === 0 ? new Date() : undefined },
            sms: { sent: channels.includes('sms') && i % 4 === 0, sentAt: channels.includes('sms') && i % 4 === 0 ? new Date() : undefined },
            inApp: { read: i % 3 === 0, readAt: i % 3 === 0 ? new Date() : undefined }
          },
          scheduledFor: scheduled,
          expiresAt: expires,
          createdAt: new Date(Date.now() - i * 3600 * 1000),
          updatedAt: new Date(Date.now() - i * 3600 * 1000),
        });
      }

      await Notification.insertMany(docs);
      console.log('🎉 Notifications sample data created successfully!');
    } catch (error) {
      console.error('❌ Error creating Notifications sample data:', error);
      throw error;
    }
  }

  async healthCheck() {
    try {
      console.log('🏥 Running Notifications health check...');
      if (!this.connection) throw new Error('No database connection');

      const stats = await this.connection.connection.db.stats();
      console.log(`📊 Database size: ${(stats.dataSize / 1024 / 1024).toFixed(2)} MB`);
      console.log(`📊 Collections: ${stats.collections}`);
      console.log(`📊 Documents: ${stats.objects || 0}`);

      const total = await Notification.countDocuments();
      const unread = await Notification.countDocuments({ 'status.inApp.read': false });
      const scheduled = await Notification.countDocuments({ scheduledFor: { $gt: new Date() } });
      const expired = await Notification.countDocuments({ expiresAt: { $lt: new Date() } });

      console.log(`📊 Total notifications: ${total}`);
      console.log(`📊 Unread: ${unread}`);
      console.log(`📊 Scheduled (future): ${scheduled}`);
      console.log(`📊 Expired: ${expired}`);

      const indexes = await Notification.collection.getIndexes();
      console.log(`🔍 Indexes: ${Object.keys(indexes).length}`);

      const typeStats = await Notification.aggregate([
        { $group: { _id: '$type', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]);
      console.log('\n🔔 Type Distribution:');
      typeStats.forEach(s => console.log(`  ${s._id}: ${s.count}`));

      const priorityStats = await Notification.aggregate([
        { $group: { _id: '$priority', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]);
      console.log('\n⚡ Priority Distribution:');
      priorityStats.forEach(s => console.log(`  ${s._id}: ${s.count}`));

      console.log('🎉 Notifications health check completed successfully!');
      return true;
    } catch (error) {
      console.error('❌ Notifications health check failed:', error);
      return false;
    }
  }

  async setup(options = {}) {
    const { createIndexes = true, validateSchema = true, createSampleData = false, runHealthCheck = true } = options;
    try {
      console.log('🚀 Starting Notifications database setup...');
      await this.connect();
      if (createIndexes) await this.createIndexes();
      if (validateSchema) await this.validateSchema();
      if (createSampleData) await this.createSampleData();
      if (runHealthCheck) await this.healthCheck();
      console.log('🎉 Notifications database setup completed successfully!');
    } catch (error) {
      console.error('❌ Notifications database setup failed:', error);
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

  const setup = new NotificationsDatabaseSetup();
  setup.setup(options)
    .then(() => { console.log('✅ Notifications setup completed successfully'); process.exit(0); })
    .catch((err) => { console.error('❌ Notifications setup failed:', err); process.exit(1); });
}

module.exports = NotificationsDatabaseSetup;
