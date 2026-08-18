const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const User = require('../models/User');
const Booking = require('../models/Booking');
const Driver = require('../models/Driver');
const Vehicle = require('../models/Vehicle');
const Quote = require('../models/Quote');

class IndexManager {
  constructor() {
    this.connection = null;
  }

  async connect() {
    try {
      const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft-auth';
      
      this.connection = await mongoose.connect(mongoUri, {
        useNewUrlParser: true,
        useUnifiedTopology: true,
      });

      console.log('✅ Connected to MongoDB for index creation');
      return this.connection;
    } catch (error) {
      console.error('❌ MongoDB connection error:', error);
      throw error;
    }
  }

  async createUserIndexes() {
    console.log('🔍 Creating User collection indexes...');
    
    try {
      // Email index (already exists but ensure it's unique)
      await User.collection.createIndex({ "email": 1 }, { unique: true });
      console.log('✅ Created email index');

      // Referral code index
      await User.collection.createIndex({ "referralCode": 1 }, { unique: true, sparse: true });
      console.log('✅ Created referralCode index');

      // Refresh tokens index
      await User.collection.createIndex({ "refreshTokens.token": 1 });
      console.log('✅ Created refreshTokens index');

      // Password reset token index
      await User.collection.createIndex({ "resetPasswordToken": 1 });
      console.log('✅ Created resetPasswordToken index');

      // Email verification token index
      await User.collection.createIndex({ "emailVerificationToken": 1 });
      console.log('✅ Created emailVerificationToken index');

      // Phone verification code index
      await User.collection.createIndex({ "phoneVerificationCode": 1 });
      console.log('✅ Created phoneVerificationCode index');

      // Role and active status compound index
      await User.collection.createIndex({ "role": 1, "isActive": 1 });
      console.log('✅ Created role+isActive compound index');

      // Loyalty tier index
      await User.collection.createIndex({ "loyaltyTier": 1 });
      console.log('✅ Created loyaltyTier index');

      // Created at index for sorting
      await User.collection.createIndex({ "createdAt": -1 });
      console.log('✅ Created createdAt index');

    } catch (error) {
      console.error('❌ Error creating User indexes:', error);
      throw error;
    }
  }

  async createBookingIndexes() {
    console.log('🔍 Creating Booking collection indexes...');
    
    try {
      // Booking ID index
      await Booking.collection.createIndex({ "bookingId": 1 }, { unique: true });
      console.log('✅ Created bookingId index');

      // Trip ID index
      await Booking.collection.createIndex({ "tripId": 1 }, { unique: true, sparse: true });
      console.log('✅ Created tripId index');

      // User bookings compound index
      await Booking.collection.createIndex({ "userId": 1, "createdAt": -1 });
      console.log('✅ Created userId+createdAt compound index');

      // Driver bookings compound index
      await Booking.collection.createIndex({ "driverId": 1, "createdAt": -1 });
      console.log('✅ Created driverId+createdAt compound index');

      // Vehicle bookings index
      await Booking.collection.createIndex({ "vehicleId": 1 });
      console.log('✅ Created vehicleId index');

      // Status and scheduled date compound index
      await Booking.collection.createIndex({ "status": 1, "scheduledDate": 1 });
      console.log('✅ Created status+scheduledDate compound index');

      // Geospatial index for pickup location
      await Booking.collection.createIndex({ "pickupLocation.coordinates": "2dsphere" });
      console.log('✅ Created pickupLocation geospatial index');

      // Geospatial index for dropoff location
      await Booking.collection.createIndex({ "dropoffLocation.coordinates": "2dsphere" });
      console.log('✅ Created dropoffLocation geospatial index');

      // Payment status index
      await Booking.collection.createIndex({ "paymentStatus": 1 });
      console.log('✅ Created paymentStatus index');

      // Corporate booking index
      await Booking.collection.createIndex({ "isCorporateBooking": 1 });
      console.log('✅ Created isCorporateBooking index');

      // Quote reference index
      await Booking.collection.createIndex({ "quoteId": 1 });
      console.log('✅ Created quoteId index');

    } catch (error) {
      console.error('❌ Error creating Booking indexes:', error);
      throw error;
    }
  }

  async createDriverIndexes() {
    console.log('🔍 Creating Driver collection indexes...');
    
    try {
      // Driver ID index
      await Driver.collection.createIndex({ "driverId": 1 }, { unique: true });
      console.log('✅ Created driverId index');

      // License number index
      await Driver.collection.createIndex({ "licenseNumber": 1 }, { unique: true });
      console.log('✅ Created licenseNumber index');

      // Geospatial index for current location
      await Driver.collection.createIndex({ "currentLocation.coordinates": "2dsphere" });
      console.log('✅ Created currentLocation geospatial index');

      // Availability status index
      await Driver.collection.createIndex({ "availability.status": 1 });
      console.log('✅ Created availability.status index');

      // Driver status index
      await Driver.collection.createIndex({ "status": 1 });
      console.log('✅ Created status index');

      // User reference index
      await Driver.collection.createIndex({ "userId": 1 });
      console.log('✅ Created userId index');

      // Performance rating index
      await Driver.collection.createIndex({ "performance.rating": -1 });
      console.log('✅ Created performance.rating index');

    } catch (error) {
      console.error('❌ Error creating Driver indexes:', error);
      throw error;
    }
  }

  async createVehicleIndexes() {
    console.log('🔍 Creating Vehicle collection indexes...');
    
    try {
      // Vehicle ID index
      await Vehicle.collection.createIndex({ "vehicleId": 1 }, { unique: true });
      console.log('✅ Created vehicleId index');

      // Driver reference index
      await Vehicle.collection.createIndex({ "driverId": 1 });
      console.log('✅ Created driverId index');

      // Geospatial index for current location
      await Vehicle.collection.createIndex({ "currentLocation.coordinates": "2dsphere" });
      console.log('✅ Created currentLocation geospatial index');

      // Status index
      await Vehicle.collection.createIndex({ "status": 1 });
      console.log('✅ Created status index');

      // Category index
      await Vehicle.collection.createIndex({ "category": 1 });
      console.log('✅ Created category index');

      // Availability compound index
      await Vehicle.collection.createIndex({ "availability.isAvailable": 1, "status": 1 });
      console.log('✅ Created availability compound index');

      // License plate index
      await Vehicle.collection.createIndex({ "licensePlate": 1 }, { unique: true });
      console.log('✅ Created licensePlate index');

      // VIN index
      await Vehicle.collection.createIndex({ "vin": 1 }, { unique: true, sparse: true });
      console.log('✅ Created vin index');

      // Passenger capacity index
      await Vehicle.collection.createIndex({ "passengerCapacity": 1 });
      console.log('✅ Created passengerCapacity index');

      // Base price index for search
      await Vehicle.collection.createIndex({ "pricing.baseFare": 1 });
      console.log('✅ Created pricing.baseFare index');

    } catch (error) {
      console.error('❌ Error creating Vehicle indexes:', error);
      throw error;
    }
  }

  async createQuoteIndexes() {
    console.log('🔍 Creating Quote collection indexes...');
    
    try {
      // User quotes compound index
      await Quote.collection.createIndex({ "userId": 1, "createdAt": -1 });
      console.log('✅ Created userId+createdAt compound index');

      // Valid until index for cleanup
      await Quote.collection.createIndex({ "validUntil": 1 });
      console.log('✅ Created validUntil index');

      // Quote ID index
      await Quote.collection.createIndex({ "quoteId": 1 }, { unique: true });
      console.log('✅ Created quoteId index');

      // Geospatial index for pickup location
      await Quote.collection.createIndex({ "pickupLocation.coordinates": "2dsphere" });
      console.log('✅ Created pickupLocation geospatial index');

      // Geospatial index for dropoff location
      await Quote.collection.createIndex({ "dropoffLocation.coordinates": "2dsphere" });
      console.log('✅ Created dropoffLocation geospatial index');

    } catch (error) {
      console.error('❌ Error creating Quote indexes:', error);
      throw error;
    }
  }

  async createAllIndexes() {
    try {
      await this.connect();
      
      await this.createUserIndexes();
      await this.createBookingIndexes();
      await this.createDriverIndexes();
      await this.createVehicleIndexes();
      await this.createQuoteIndexes();
      
      console.log('✅ All indexes created successfully!');
      
    } catch (error) {
      console.error('❌ Error creating indexes:', error);
      throw error;
    } finally {
      if (this.connection) {
        await mongoose.disconnect();
        console.log('📊 Disconnected from MongoDB');
      }
    }
  }
}

// Run if called directly
if (require.main === module) {
  const indexManager = new IndexManager();
  indexManager.createAllIndexes()
    .then(() => {
      console.log('🎉 Index creation completed successfully!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('💥 Index creation failed:', error);
      process.exit(1);
    });
}

module.exports = IndexManager;
