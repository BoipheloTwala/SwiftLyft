const mongoose = require('mongoose');
require('dotenv').config();

const Quote = require('../models/Quote');

class QuotesDatabaseSetup {
  constructor() {
    this.connection = null;
  }

  async connect() {
    try {
      const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_quotes';
      this.connection = await mongoose.connect(mongoUri, {
        useNewUrlParser: true,
        useUnifiedTopology: true,
      });
      console.log('✅ Connected to MongoDB for Quotes');
      console.log(`📊 Database: ${mongoose.connection.name}`);
      return this.connection;
    } catch (error) {
      console.error('❌ MongoDB connection error:', error);
      throw error;
    }
  }

  async createIndexes() {
    try {
      console.log('🔍 Creating Quotes database indexes...');

      // From schema
      await Quote.collection.createIndex({ userId: 1, createdAt: -1 });
      console.log('✅ Created userId + createdAt index');

      await Quote.collection.createIndex({ status: 1, validUntil: 1 });
      console.log('✅ Created status + validUntil index');

      await Quote.collection.createIndex({ scheduledDate: 1 });
      console.log('✅ Created scheduledDate index');

      // Helpful additional indexes
      await Quote.collection.createIndex({ vehicleType: 1, serviceType: 1 });
      console.log('✅ Created vehicleType + serviceType index');

      await Quote.collection.createIndex({ 'pickupLocation.address': 1 });
      await Quote.collection.createIndex({ 'dropoffLocation.address': 1 });
      console.log('✅ Created pickup/dropoff address indexes');

      await Quote.collection.createIndex({ 'estimatedPrice.total': -1 });
      console.log('✅ Created estimatedPrice.total index');

      console.log('🎉 All Quotes indexes created successfully!');
    } catch (error) {
      console.error('❌ Error creating Quotes indexes:', error);
      throw error;
    }
  }

  async validateSchema() {
    try {
      console.log('🔍 Validating Quotes schema...');

      const now = new Date();
      const testQuote = new Quote({
        userId: new mongoose.Types.ObjectId(),
        pickupLocation: { address: 'Cape Town CBD', coordinates: { latitude: -33.9249, longitude: 18.4241 } },
        dropoffLocation: { address: 'Sea Point', coordinates: { latitude: -33.909, longitude: 18.3903 } },
        vehicleType: 'sedan',
        serviceType: 'standard',
        passengerCount: 2,
        luggageCount: 1,
        specialRequirements: 'Window seat',
        scheduledDate: new Date(now.getTime() + 2 * 60 * 60 * 1000),
        isFlexibleTime: false,
        estimatedDistance: 12.5,
        estimatedDuration: 35,
        estimatedPrice: {
          baseFare: 25,
          distanceFare: 18.75,
          timeFare: 23.33,
          serviceFee: 2.5,
          taxes: 10,
          total: 79.58
        },
        status: 'pending',
        validUntil: new Date(now.getTime() + 24 * 60 * 60 * 1000)
      });

      await testQuote.validate();
      testQuote.canAccept();
      testQuote.isExpired;

      console.log('✅ Quotes schema validation passed');
    } catch (error) {
      console.error('❌ Quotes schema validation failed:', error);
      throw error;
    }
  }

  async createSampleData() {
    try {
      console.log('🌱 Creating Quotes sample data...');
      const existing = await Quote.countDocuments();
      if (existing > 0) {
        console.log('⚠️ Quotes already exist, skipping sample');
        return;
      }

      const users = [new mongoose.Types.ObjectId(), new mongoose.Types.ObjectId()];
      const vehicleTypes = ['sedan', 'suv', 'luxury', 'van'];
      const serviceTypes = ['standard', 'premium', 'corporate', 'airport'];

      const docs = [];
      for (let i = 0; i < 10; i++) {
        const dist = Math.round((5 + Math.random() * 40) * 100) / 100;
        const dur = Math.round(dist * (1.8 + Math.random() * 0.6));
        const vt = vehicleTypes[i % vehicleTypes.length];
        const st = serviceTypes[i % serviceTypes.length];
        const pax = 1 + (i % 4);

        // Use Quote static to compute price (ensure basic compatibility with model expectations)
        const price = Quote.calculatePricing(dist, dur, vt, st, pax);

        const pickup = { address: `Pickup ${i+1}`, coordinates: { latitude: -33.92 + Math.random()*0.1, longitude: 18.42 + Math.random()*0.1 } };
        const dropoff = { address: `Dropoff ${i+1}`, coordinates: { latitude: -33.95 + Math.random()*0.1, longitude: 18.37 + Math.random()*0.1 } };

        docs.push({
          userId: users[i % users.length],
          pickupLocation: pickup,
          dropoffLocation: dropoff,
          vehicleType: vt,
          serviceType: st,
          passengerCount: pax,
          luggageCount: i % 3,
          scheduledDate: new Date(Date.now() + (i+2) * 60 * 60 * 1000),
          isFlexibleTime: i % 2 === 0,
          estimatedDistance: dist,
          estimatedDuration: dur,
          estimatedPrice: price,
          status: i % 5 === 0 ? 'quoted' : 'pending',
          validUntil: new Date(Date.now() + 24 * 60 * 60 * 1000),
          createdAt: new Date(Date.now() - i * 3600 * 1000),
          updatedAt: new Date(Date.now() - i * 3600 * 1000)
        });
      }

      await Quote.insertMany(docs);
      console.log('🎉 Quotes sample data created successfully!');
    } catch (error) {
      console.error('❌ Error creating Quotes sample data:', error);
      throw error;
    }
  }

  async healthCheck() {
    try {
      console.log('🏥 Running Quotes health check...');
      const stats = await this.connection.connection.db.stats();
      console.log(`📊 Database size: ${(stats.dataSize / 1024 / 1024).toFixed(2)} MB`);
      console.log(`📊 Collections: ${stats.collections}`);

      const total = await Quote.countDocuments();
      const quoted = await Quote.countDocuments({ status: 'quoted' });
      const pending = await Quote.countDocuments({ status: 'pending' });
      const expired = await Quote.countDocuments({ status: 'quoted', validUntil: { $lt: new Date() } });

      console.log(`📊 Quotes: total=${total} quoted=${quoted} pending=${pending} expired=${expired}`);

      const typeStats = await Quote.aggregate([
        { $group: { _id: '$vehicleType', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]);
      console.log('\n🚗 VehicleType Distribution:');
      typeStats.forEach(s => console.log(`  ${s._id}: ${s.count}`));

      const svcStats = await Quote.aggregate([
        { $group: { _id: '$serviceType', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]);
      console.log('\n🧰 ServiceType Distribution:');
      svcStats.forEach(s => console.log(`  ${s._id}: ${s.count}`));

      const idx = await Quote.collection.getIndexes();
      console.log(`\n🔍 Indexes: ${Object.keys(idx).length}`);

      console.log('🎉 Quotes health check completed successfully!');
    } catch (error) {
      console.error('❌ Quotes health check failed:', error);
      throw error;
    }
  }

  async setup(options = {}) {
    const { createIndexes = true, validateSchema = true, createSampleData = false, runHealthCheck = true } = options;
    try {
      console.log('🚀 Starting Quotes database setup...');
      await this.connect();
      if (createIndexes) await this.createIndexes();
      if (validateSchema) await this.validateSchema();
      if (createSampleData) await this.createSampleData();
      if (runHealthCheck) await this.healthCheck();
      console.log('🎉 Quotes database setup completed successfully!');
    } catch (error) {
      console.error('❌ Quotes database setup failed:', error);
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

  const setup = new QuotesDatabaseSetup();
  setup.setup(options)
    .then(() => { console.log('✅ Quotes setup completed successfully'); process.exit(0); })
    .catch((err) => { console.error('❌ Quotes setup failed:', err); process.exit(1); });
}

module.exports = QuotesDatabaseSetup;
