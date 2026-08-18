const mongoose = require('mongoose');
const Notification = require('../models/Notification');
require('dotenv').config();

class NotificationsDatabaseSeeder {
  constructor() { this.connection = null; }

  async connect() {
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_notifications';
    this.connection = await mongoose.connect(mongoUri, { useNewUrlParser: true, useUnifiedTopology: true });
    console.log('✅ Connected to MongoDB for Notifications seeding');
      console.log(`📊 Database: ${mongoose.connection.name}`);
    return this.connection;
  }

  generateNotification(i) {
    const types = [
      'booking_confirmed','driver_assigned','driver_arrived','trip_started','trip_completed',
      'payment_received','payment_failed','quote_ready','driver_cancelled','system_update',
      'promotion','loyalty_points','support_response','reminder'
    ];
    const priorities = ['low','normal','high','urgent'];
    const channelsList = [['push'], ['email'], ['sms'], ['in_app'], ['push','email'], ['push','sms'], ['push','email','sms']];
    const type = types[i % types.length];
    const channels = channelsList[i % channelsList.length];
    const priority = priorities[i % priorities.length];
    const scheduled = i % 5 === 0 ? new Date(Date.now() + (i + 1) * 60 * 60 * 1000) : null;
    const expires = i % 6 === 0 ? new Date(Date.now() + (i + 3) * 24 * 60 * 60 * 1000) : null;

    return {
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
    };
  }

  async seed({ num = 25, clearExisting = false } = {}) {
    try {
      console.log(`🌱 Seeding Notifications database with ${num} notifications...`);
      if (clearExisting) {
        console.log('🗑️ Clearing existing Notifications...');
        await Notification.deleteMany({});
        console.log('✅ Cleared');
      }

      const existing = await Notification.countDocuments();
      if (existing > 0 && !clearExisting) {
        console.log(`⚠️ ${existing} notifications already exist; use --clear-existing to replace`);
        return;
      }

      const batchSize = 50;
      const docs = [];
      for (let i = 0; i < num; i++) docs.push(this.generateNotification(i));
      for (let i = 0; i < docs.length; i += batchSize) {
        await Notification.insertMany(docs.slice(i, i + batchSize));
        console.log(`✅ Inserted ${Math.min(batchSize, docs.length - i)} notifications`);
      }

      const total = await Notification.countDocuments();
      console.log(`🎉 Seeding complete. Total notifications: ${total}`);
    } catch (error) {
      console.error('❌ Notifications seeding failed:', error);
      throw error;
    }
  }
}

if (require.main === module) {
  const args = process.argv.slice(2);
  const opts = {};
  const idx = args.indexOf('--num'); if (idx !== -1) opts.num = parseInt(args[idx + 1]);
  if (args.includes('--clear-existing')) opts.clearExisting = true;
  const seeder = new NotificationsDatabaseSeeder();
  seeder.connect()
    .then(() => seeder.seed(opts))
    .then(() => { console.log('✅ Notifications seeding completed successfully'); process.exit(0); })
    .catch((e) => { console.error('❌ Notifications seeding failed:', e); process.exit(1); });
}

module.exports = NotificationsDatabaseSeeder;
