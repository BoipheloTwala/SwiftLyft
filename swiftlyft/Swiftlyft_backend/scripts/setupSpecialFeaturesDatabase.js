const mongoose = require('mongoose');
require('dotenv').config();

const {
  Offer,
  CorporateBooking,
  SecurityService,
  AirportService
} = require('../models/SpecialFeatures');

class SpecialFeaturesDatabaseSetup {
  constructor() {
    this.connection = null;
  }

  async connect() {
    try {
      const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_special_features';
      this.connection = await mongoose.connect(mongoUri, {
        useNewUrlParser: true,
        useUnifiedTopology: true,
      });
      console.log('✅ Connected to MongoDB for SpecialFeatures');
      console.log(`📊 Database: ${mongoose.connection.name}`);
      return this.connection;
    } catch (error) {
      console.error('❌ MongoDB connection error:', error);
      throw error;
    }
  }

  async safeCreateIndex(collection, key, options = {}) {
    try {
      await collection.createIndex(key, { background: true, ...options });
    } catch (error) {
      // 85: IndexOptionsConflict, 86: IndexKeySpecsConflict
      if (error && (error.code === 85 || error.code === 86)) {
        console.log(`ℹ️  Index already exists or conflicting options, skipping: ${JSON.stringify(key)}`);
      } else {
        throw error;
      }
    }
  }

  async createIndexes() {
    try {
      console.log('🔍 Creating SpecialFeatures database indexes...');

      // Offer indexes (some defined in model; ensure presence without overriding)
      await this.safeCreateIndex(Offer.collection, { promoCode: 1 });
      await this.safeCreateIndex(Offer.collection, { type: 1, isActive: 1 });
      await this.safeCreateIndex(Offer.collection, { startDate: 1, endDate: 1 });
      await this.safeCreateIndex(Offer.collection, { targetAudience: 1, isActive: 1 });
      console.log('✅ Offer indexes ensured');

      // CorporateBooking indexes
      await this.safeCreateIndex(CorporateBooking.collection, { corporateAccountId: 1, createdAt: -1 });
      await this.safeCreateIndex(CorporateBooking.collection, { userId: 1, status: 1 });
      await this.safeCreateIndex(CorporateBooking.collection, { status: 1, createdAt: -1 });
      console.log('✅ CorporateBooking indexes ensured');

      // SecurityService indexes
      await this.safeCreateIndex(SecurityService.collection, { bookingId: 1 });
      await this.safeCreateIndex(SecurityService.collection, { status: 1 });
      await this.safeCreateIndex(SecurityService.collection, { serviceType: 1, protectionLevel: 1 });
      console.log('✅ SecurityService indexes ensured');

      // AirportService indexes
      await this.safeCreateIndex(AirportService.collection, { bookingId: 1 });
      await this.safeCreateIndex(AirportService.collection, { 'flightDetails.scheduledTime': 1 });
      await this.safeCreateIndex(AirportService.collection, { serviceType: 1, status: 1 });
      console.log('✅ AirportService indexes ensured');

      console.log('🎉 All SpecialFeatures indexes created successfully!');
    } catch (error) {
      console.error('❌ Error creating SpecialFeatures indexes:', error);
      throw error;
    }
  }

  async validateSchema() {
    try {
      console.log('🔍 Validating SpecialFeatures schemas...');

      // Offer
      const offer = new Offer({
        title: 'Welcome Discount',
        description: 'Get R50 off your first ride',
        type: 'discount_fixed',
        discountValue: 50,
        conditions: { minBookingAmount: 100, vehicleTypes: ['sedan','suv'] },
        minBookingAmount: 100,
        maxDiscountAmount: 50,
        promoCode: 'WELCOME50',
        isActive: true,
        startDate: new Date(Date.now() - 86400000),
        endDate: new Date(Date.now() + 7*86400000),
        targetAudience: 'new_users'
      });
      await offer.validate();
      offer.isValid;

      // CorporateBooking
      const corp = new CorporateBooking({
        corporateAccountId: new mongoose.Types.ObjectId(),
        userId: new mongoose.Types.ObjectId(),
        title: 'Annual Summit Transport',
        bookingType: 'event_transport',
        trips: [{
          tripId: 'TRIP1',
          pickupLocation: { address: 'Venue A', coordinates: { latitude: -26.2, longitude: 28.04 } },
          dropoffLocation: { address: 'Venue B', coordinates: { latitude: -26.1, longitude: 28.05 } },
          scheduledDate: new Date(Date.now() + 2*3600000),
          passengerCount: 4,
          status: 'pending',
          actualCost: 500
        }],
        totalEstimatedCost: 1500,
        discountApplied: 100
      });
      await corp.validate();
      corp.completionPercentage;
      corp.calculateTotalCost();
      corp.getDiscountedTotal();

      // SecurityService
      const sec = new SecurityService({
        bookingId: new mongoose.Types.ObjectId(),
        userId: new mongoose.Types.ObjectId(),
        serviceType: 'close_protection',
        protectionLevel: 'standard',
        duration: 4,
        personnelCount: 2,
        requirements: { armed: true },
        routeDetails: { pickupLocation: { address: 'HQ' } }
      });
      await sec.validate();
      sec.calculateCost();

      // AirportService
      const air = new AirportService({
        bookingId: new mongoose.Types.ObjectId(),
        userId: new mongoose.Types.ObjectId(),
        serviceType: 'pickup',
        flightDetails: { airline: 'SAA', flightNumber: 'SA123', scheduledTime: new Date(Date.now()+3*3600000) },
        passengerDetails: { count: 2 },
        luggageDetails: { checkedBags: 1 },
        pickupLocation: { terminal: 'A' }
      });
      await air.validate();
      AirportService.prototype.calculateCost.call(air);

      console.log('✅ SpecialFeatures schema validation passed');
    } catch (error) {
      console.error('❌ SpecialFeatures schema validation failed:', error);
      throw error;
    }
  }

  async createSampleData() {
    try {
      console.log('🌱 Creating SpecialFeatures sample data...');

      const offerCount = await Offer.countDocuments();
      if (offerCount === 0) {
        await Offer.insertMany([
          {
            title: 'Winter Promo', description: '10% off rides', type: 'discount_percentage',
            discountValue: 10, conditions: { minBookingAmount: 50, vehicleTypes: ['sedan','suv'] },
            minBookingAmount: 50, promoCode: 'WINTER10', isActive: true,
            startDate: new Date(Date.now()-86400000), endDate: new Date(Date.now()+14*86400000), targetAudience: 'all'
          },
          {
            title: 'First Ride Free', description: 'Free first ride up to R100', type: 'first_ride',
            discountValue: 100, conditions: { minBookingAmount: 0 }, promoCode: 'FREERIDE', isActive: true,
            startDate: new Date(Date.now()-86400000), endDate: new Date(Date.now()+30*86400000), targetAudience: 'new_users'
          }
        ]);
        console.log('✅ Seeded offers');
      } else {
        console.log('ℹ️ Offers already exist, skipping');
      }

      const corpCount = await CorporateBooking.countDocuments();
      if (corpCount === 0) {
        const corp = new CorporateBooking({
          corporateAccountId: new mongoose.Types.ObjectId(),
          userId: new mongoose.Types.ObjectId(),
          title: 'Monthly Shuttle',
          bookingType: 'shuttle_service',
          trips: [
            { tripId: 'S1', pickupLocation: { address: 'Office' }, dropoffLocation: { address: 'Airport' }, scheduledDate: new Date(Date.now()+3600000), passengerCount: 6, status: 'pending', actualCost: 300 },
            { tripId: 'S2', pickupLocation: { address: 'Airport' }, dropoffLocation: { address: 'Office' }, scheduledDate: new Date(Date.now()+3*3600000), passengerCount: 6, status: 'pending', actualCost: 300 }
          ],
          totalEstimatedCost: 700,
          discountApplied: 50
        });
        await corp.save();
        console.log('✅ Seeded corporate booking');
      } else {
        console.log('ℹ️ Corporate bookings already exist, skipping');
      }

      const secCount = await SecurityService.countDocuments();
      if (secCount === 0) {
        await SecurityService.create({
          bookingId: new mongoose.Types.ObjectId(),
          userId: new mongoose.Types.ObjectId(),
          serviceType: 'security_escort', protectionLevel: 'enhanced', duration: 6, personnelCount: 3
        });
        console.log('✅ Seeded security service');
      }

      const airCount = await AirportService.countDocuments();
      if (airCount === 0) {
        await AirportService.create({
          bookingId: new mongoose.Types.ObjectId(),
          userId: new mongoose.Types.ObjectId(),
          serviceType: 'dropoff',
          flightDetails: { airline: 'BA', flightNumber: 'BA45', scheduledTime: new Date(Date.now()+5*3600000) },
          passengerDetails: { count: 3 }
        });
        console.log('✅ Seeded airport service');
      }

      console.log('🎉 SpecialFeatures sample data created successfully!');
    } catch (error) {
      console.error('❌ Error creating SpecialFeatures sample data:', error);
      throw error;
    }
  }

  async healthCheck() {
    try {
      console.log('🏥 Running SpecialFeatures health check...');
      const stats = await this.connection.connection.db.stats();
      console.log(`📊 Database size: ${(stats.dataSize / 1024 / 1024).toFixed(2)} MB`);
      console.log(`📊 Collections: ${stats.collections}`);

      const counts = await Promise.all([
        Offer.countDocuments(),
        CorporateBooking.countDocuments(),
        SecurityService.countDocuments(),
        AirportService.countDocuments()
      ]);
      console.log(`📊 Counts -> Offers=${counts[0]} CorporateBookings=${counts[1]} SecurityServices=${counts[2]} AirportServices=${counts[3]}`);

      const activeOffers = await Offer.countDocuments({ isActive: true });
      console.log(`📊 Active offers: ${activeOffers}`);

      const corpStatus = await CorporateBooking.aggregate([{ $group: { _id: '$status', count: { $sum: 1 } } }]);
      console.log('📊 CorporateBooking status:');
      corpStatus.forEach(s => console.log(`  ${s._id}: ${s.count}`));

      const secTypes = await SecurityService.aggregate([{ $group: { _id: '$serviceType', count: { $sum: 1 } } }]);
      console.log('📊 SecurityService types:');
      secTypes.forEach(s => console.log(`  ${s._id}: ${s.count}`));

      const airTypes = await AirportService.aggregate([{ $group: { _id: '$serviceType', count: { $sum: 1 } } }]);
      console.log('📊 AirportService types:');
      airTypes.forEach(s => console.log(`  ${s._id}: ${s.count}`));

      console.log('🎉 SpecialFeatures health check completed successfully!');
    } catch (error) {
      console.error('❌ SpecialFeatures health check failed:', error);
      throw error;
    }
  }

  async setup(options = {}) {
    const { createIndexes = true, validateSchema = true, createSampleData = false, runHealthCheck = true } = options;
    try {
      console.log('🚀 Starting SpecialFeatures database setup...');
      await this.connect();
      if (createIndexes) await this.createIndexes();
      if (validateSchema) await this.validateSchema();
      if (createSampleData) await this.createSampleData();
      if (runHealthCheck) await this.healthCheck();
      console.log('🎉 SpecialFeatures database setup completed successfully!');
    } catch (error) {
      console.error('❌ SpecialFeatures database setup failed:', error);
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

  const setup = new SpecialFeaturesDatabaseSetup();
  setup.setup(options)
    .then(() => { console.log('✅ SpecialFeatures setup completed successfully'); process.exit(0); })
    .catch((err) => { console.error('❌ SpecialFeatures setup failed:', err); process.exit(1); });
}

module.exports = SpecialFeaturesDatabaseSetup;
