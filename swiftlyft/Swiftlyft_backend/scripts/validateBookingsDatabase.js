const mongoose = require('mongoose');
const Booking = require('../models/Booking');
const User = require('../models/User');
const Driver = require('../models/Driver');
const Vehicle = require('../models/Vehicle');
require('dotenv').config();

class BookingsDatabaseValidator {
  constructor() {
    this.connection = null;
    this.errors = [];
    this.warnings = [];
  }

  // Connect to MongoDB
  async connect() {
    try {
      const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_bookings';
      
      this.connection = await mongoose.connect(mongoUri, {
        useNewUrlParser: true,
        useUnifiedTopology: true,
      });

      console.log('✅ Connected to MongoDB for Bookings validation');
      console.log(`📊 Database: ${mongoose.connection.name}`);
      return this.connection;
    } catch (error) {
      console.error('❌ MongoDB connection error:', error);
      throw error;
    }
  }

  // Add error to validation results
  addError(message, details = null) {
    this.errors.push({ message, details, timestamp: new Date() });
  }

  // Add warning to validation results
  addWarning(message, details = null) {
    this.warnings.push({ message, details, timestamp: new Date() });
  }

  // Validate database connection
  async validateConnection() {
    try {
      console.log('🔍 Validating Bookings database connection...');
      
      if (!this.connection) {
        this.addError('No database connection established');
        return false;
      }

      // Test basic operations
      await this.connection.connection.db.admin().ping();
      console.log('✅ Bookings database connection is healthy');
      return true;
    } catch (error) {
      this.addError('Database connection failed', error.message);
      return false;
    }
  }

  // Validate collection exists and has proper structure
  async validateCollection() {
    try {
      console.log('🔍 Validating Bookings collection...');
      
      const collections = await this.connection.connection.db.listCollections().toArray();
      const bookingsCollection = collections.find(col => col.name === 'bookings');
      
      if (!bookingsCollection) {
        this.addError('Bookings collection does not exist');
        return false;
      }

      console.log('✅ Bookings collection exists');
      
      // Check collection stats
      const stats = await this.connection.connection.db.collection('bookings').stats();
      console.log(`📊 Collection size: ${(stats.size / 1024 / 1024).toFixed(2)} MB`);
      console.log(`📊 Document count: ${stats.count}`);
      
      return true;
    } catch (error) {
      this.addError('Collection validation failed', error.message);
      return false;
    }
  }

  // Validate indexes
  async validateIndexes() {
    try {
      console.log('🔍 Validating Bookings database indexes...');
      
      const indexes = await Booking.collection.getIndexes();
      const requiredIndexes = [
        'bookingId_1',
        'tripId_1',
        'userId_1_createdAt_-1',
        'driverId_1_createdAt_-1',
        'vehicleId_1',
        'status_1_scheduledDate_1',
        'scheduledDate_1',
        'pickupLocation.coordinates_2dsphere',
        'dropoffLocation.coordinates_2dsphere',
        'paymentStatus_1',
        'isCorporateBooking_1',
        'createdAt_-1',
        'updatedAt_-1',
        'vehicleType_1',
        'serviceType_1',
        'paymentMethod_1',
        'finalPrice_1',
        'rating_1',
        'corporateAccountId_1'
      ];

      const existingIndexNames = typeof indexes === 'object' ? Object.keys(indexes) : [];
      
      for (const requiredIndex of requiredIndexes) {
        if (!existingIndexNames.includes(requiredIndex)) {
          this.addError(`Required index missing: ${requiredIndex}`);
        } else {
          console.log(`✅ Index exists: ${requiredIndex}`);
        }
      }

      // Note: Unique constraints are handled at the schema level and tested during setup
      console.log(`📊 Total indexes: ${Object.keys(indexes).length}`);

      console.log('✅ Bookings indexes validation completed');
      return this.errors.length === 0;
    } catch (error) {
      this.addError('Index validation failed', error.message);
      return false;
    }
  }

  // Validate documents
  async validateDocuments() {
    try {
      console.log('🔍 Validating Bookings documents...');
      
      const totalBookings = await Booking.countDocuments();
      if (totalBookings === 0) {
        this.addWarning('No bookings found in database');
        return true;
      }

      console.log(`📊 Total bookings: ${totalBookings}`);

      // Validate required fields
      const bookingsWithoutBookingId = await Booking.countDocuments({ bookingId: { $exists: false } });
      if (bookingsWithoutBookingId > 0) {
        this.addError(`${bookingsWithoutBookingId} bookings missing bookingId field`);
      }

      const bookingsWithoutUserId = await Booking.countDocuments({ userId: { $exists: false } });
      if (bookingsWithoutUserId > 0) {
        this.addError(`${bookingsWithoutUserId} bookings missing userId field`);
      }

      const bookingsWithoutVehicleName = await Booking.countDocuments({ vehicleName: { $exists: false } });
      if (bookingsWithoutVehicleName > 0) {
        this.addError(`${bookingsWithoutVehicleName} bookings missing vehicleName field`);
      }

      const bookingsWithoutPickupAddress = await Booking.countDocuments({ pickupAddress: { $exists: false } });
      if (bookingsWithoutPickupAddress > 0) {
        this.addError(`${bookingsWithoutPickupAddress} bookings missing pickupAddress field`);
      }

      const bookingsWithoutDropoffAddress = await Booking.countDocuments({ dropoffAddress: { $exists: false } });
      if (bookingsWithoutDropoffAddress > 0) {
        this.addError(`${bookingsWithoutDropoffAddress} bookings missing dropoffAddress field`);
      }

      // Validate vehicle type values
      const invalidVehicleTypes = await Booking.countDocuments({
        vehicleType: { $nin: ['sedan', 'suv', 'luxury', 'van', 'truck', 'motorcycle', 'electric', 'hybrid'] }
      });
      if (invalidVehicleTypes > 0) {
        this.addError(`${invalidVehicleTypes} bookings have invalid vehicleType`);
      }

      // Validate service type values
      const invalidServiceTypes = await Booking.countDocuments({
        serviceType: { $nin: ['standard', 'premium', 'corporate', 'airport', 'security', 'medical', 'event'] }
      });
      if (invalidServiceTypes > 0) {
        this.addError(`${invalidServiceTypes} bookings have invalid serviceType`);
      }

      // Validate status values
      const invalidStatuses = await Booking.countDocuments({
        status: { $nin: ['pending', 'confirmed', 'driverAssigned', 'driverEnRoute', 'driverArrived', 'inProgress', 'completed', 'cancelled', 'expired', 'disputed'] }
      });
      if (invalidStatuses > 0) {
        this.addError(`${invalidStatuses} bookings have invalid status`);
      }

      // Validate payment status values
      const invalidPaymentStatuses = await Booking.countDocuments({
        paymentStatus: { $nin: ['pending', 'paid', 'failed', 'refunded', 'partially_refunded', 'disputed'] }
      });
      if (invalidPaymentStatuses > 0) {
        this.addError(`${invalidPaymentStatuses} bookings have invalid paymentStatus`);
      }

      // Validate payment method values
      const invalidPaymentMethods = await Booking.countDocuments({
        paymentMethod: { $nin: ['cash', 'card', 'wallet', 'corporate', 'crypto'] }
      });
      if (invalidPaymentMethods > 0) {
        this.addError(`${invalidPaymentMethods} bookings have invalid paymentMethod`);
      }

      // Validate numeric fields
      const bookingsWithNegativePassengerCount = await Booking.countDocuments({ passengerCount: { $lt: 1 } });
      if (bookingsWithNegativePassengerCount > 0) {
        this.addError(`${bookingsWithNegativePassengerCount} bookings have invalid passengerCount (less than 1)`);
      }

      const bookingsWithNegativeLuggageCount = await Booking.countDocuments({ luggageCount: { $lt: 0 } });
      if (bookingsWithNegativeLuggageCount > 0) {
        this.addError(`${bookingsWithNegativeLuggageCount} bookings have invalid luggageCount (negative)`);
      }

      const bookingsWithNegativeBasePrice = await Booking.countDocuments({ basePrice: { $lt: 0 } });
      if (bookingsWithNegativeBasePrice > 0) {
        this.addError(`${bookingsWithNegativeBasePrice} bookings have invalid basePrice (negative)`);
      }

      const bookingsWithNegativeFinalPrice = await Booking.countDocuments({ finalPrice: { $lt: 0 } });
      if (bookingsWithNegativeFinalPrice > 0) {
        this.addError(`${bookingsWithNegativeFinalPrice} bookings have invalid finalPrice (negative)`);
      }

      // Validate rating values
      const bookingsWithInvalidRating = await Booking.countDocuments({
        $or: [
          { rating: { $lt: 1 } },
          { rating: { $gt: 5 } }
        ]
      });
      if (bookingsWithInvalidRating > 0) {
        this.addError(`${bookingsWithInvalidRating} bookings have invalid rating (must be 1-5)`);
      }

      console.log('✅ Bookings document validation completed');
      return this.errors.length === 0;
    } catch (error) {
      this.addError('Document validation failed', error.message);
      return false;
    }
  }

  // Validate data consistency
  async validateDataConsistency() {
    try {
      console.log('🔍 Validating Bookings data consistency...');
      
      // Check for bookings with driver assigned but no driver info
      const bookingsWithDriverButNoInfo = await Booking.countDocuments({
        driverId: { $exists: true, $ne: null },
        $or: [
          { driverName: { $exists: false } },
          { driverName: '' }
        ]
      });
      if (bookingsWithDriverButNoInfo > 0) {
        this.addWarning(`${bookingsWithDriverButNoInfo} bookings have driver assigned but missing driver info`);
      }

      // Check for completed bookings without trip details
      const completedBookingsWithoutTripDetails = await Booking.countDocuments({
        status: 'completed',
        tripDetails: { $exists: false }
      });
      if (completedBookingsWithoutTripDetails > 0) {
        this.addWarning(`${completedBookingsWithoutTripDetails} completed bookings missing trip details`);
      }

      // Check for bookings with trip details but not completed
      const bookingsWithTripDetailsButNotCompleted = await Booking.countDocuments({
        status: { $ne: 'completed' },
        tripDetails: { $exists: true }
      });
      if (bookingsWithTripDetailsButNotCompleted > 0) {
        this.addWarning(`${bookingsWithTripDetailsButNotCompleted} bookings have trip details but are not completed`);
      }

      // Check for bookings with ratings but not completed
      const bookingsWithRatingButNotCompleted = await Booking.countDocuments({
        status: { $ne: 'completed' },
        rating: { $exists: true, $ne: null }
      });
      if (bookingsWithRatingButNotCompleted > 0) {
        this.addWarning(`${bookingsWithRatingButNotCompleted} bookings have ratings but are not completed`);
      }

      // Check for corporate bookings without corporate account
      const corporateBookingsWithoutAccount = await Booking.countDocuments({
        isCorporateBooking: true,
        corporateAccountId: { $exists: false }
      });
      if (corporateBookingsWithoutAccount > 0) {
        this.addWarning(`${corporateBookingsWithoutAccount} corporate bookings missing corporate account ID`);
      }

      // Check for bookings with invalid scheduled dates (in the past for pending/confirmed)
      const now = new Date();
      const invalidScheduledDates = await Booking.countDocuments({
        status: { $in: ['pending', 'confirmed', 'driverAssigned', 'driverEnRoute', 'driverArrived', 'inProgress'] },
        scheduledDate: { $lt: now }
      });
      if (invalidScheduledDates > 0) {
        this.addWarning(`${invalidScheduledDates} active bookings have scheduled dates in the past`);
      }

      // Check for bookings with invalid pickup times
      const invalidPickupTimes = await Booking.countDocuments({
        pickupTime: { $lt: now },
        status: { $in: ['pending', 'confirmed', 'driverAssigned', 'driverEnRoute', 'driverArrived'] }
      });
      if (invalidPickupTimes > 0) {
        this.addWarning(`${invalidPickupTimes} active bookings have pickup times in the past`);
      }

      console.log('✅ Bookings data consistency validation completed');
      return true;
    } catch (error) {
      this.addError('Data consistency validation failed', error.message);
      return false;
    }
  }

  // Validate virtual fields
  async validateVirtualFields() {
    try {
      console.log('🔍 Validating Bookings virtual fields...');
      
      const bookings = await Booking.find({}).limit(10);
      let virtualFieldErrors = 0;

      for (const booking of bookings) {
        try {
          // Test virtual field calculations
          const isActive = booking.isActive;
          const isCompleted = booking.isCompleted;
          const isCancelled = booking.isCancelled;
          const isDisputed = booking.isDisputed;

          // Validate virtual field types
          if (typeof isActive !== 'boolean') {
            virtualFieldErrors++;
            this.addError(`Invalid isActive for booking ${booking.bookingId}`);
          }

          if (typeof isCompleted !== 'boolean') {
            virtualFieldErrors++;
            this.addError(`Invalid isCompleted for booking ${booking.bookingId}`);
          }

          if (typeof isCancelled !== 'boolean') {
            virtualFieldErrors++;
            this.addError(`Invalid isCancelled for booking ${booking.bookingId}`);
          }

          if (typeof isDisputed !== 'boolean') {
            virtualFieldErrors++;
            this.addError(`Invalid isDisputed for booking ${booking.bookingId}`);
          }

          // Test booking duration calculation
          if (booking.tripDetails && booking.tripDetails.startTime && booking.tripDetails.endTime) {
            const bookingDuration = booking.bookingDuration;
            if (typeof bookingDuration !== 'number' || bookingDuration < 0) {
              virtualFieldErrors++;
              this.addError(`Invalid bookingDuration for booking ${booking.bookingId}`);
            }
          }

        } catch (error) {
          virtualFieldErrors++;
          this.addError(`Virtual field calculation error for booking ${booking.bookingId}`, error.message);
        }
      }

      if (virtualFieldErrors === 0) {
        console.log('✅ Bookings virtual fields validation passed');
      } else {
        this.addError(`${virtualFieldErrors} virtual field calculation errors`);
      }

      return virtualFieldErrors === 0;
    } catch (error) {
      this.addError('Virtual fields validation failed', error.message);
      return false;
    }
  }

  // Validate static methods
  async validateStaticMethods() {
    try {
      console.log('🔍 Validating Bookings static methods...');
      
      // Test findByBookingId
      const testBooking = await Booking.findOne({});
      if (testBooking) {
        const foundBooking = await Booking.findByBookingId(testBooking.bookingId);
        if (!foundBooking || foundBooking._id.toString() !== testBooking._id.toString()) {
          this.addError('findByBookingId method not working correctly');
        }
      }

      // Test findUserBookings
      const userBookings = await Booking.findUserBookings(new mongoose.Types.ObjectId(), { limit: 5 });
      if (!Array.isArray(userBookings)) {
        this.addError('findUserBookings method did not return an array');
      }

      // Test findDriverBookings
      const driverBookings = await Booking.findDriverBookings(new mongoose.Types.ObjectId(), { limit: 5 });
      if (!Array.isArray(driverBookings)) {
        this.addError('findDriverBookings method did not return an array');
      }

      // Test findActiveBookings
      const activeBookings = await Booking.findActiveBookings();
      if (!Array.isArray(activeBookings)) {
        this.addError('findActiveBookings method did not return an array');
      }

      // Test getBookingStats
      const bookingStats = await Booking.getBookingStats();
      if (!Array.isArray(bookingStats)) {
        this.addError('getBookingStats method did not return an array');
      }

      // Test getRevenueStats
      const revenueStats = await Booking.getRevenueStats();
      if (!Array.isArray(revenueStats)) {
        this.addError('getRevenueStats method did not return an array');
      }

      console.log('✅ Bookings static methods validation completed');
      return true;
    } catch (error) {
      this.addError('Static methods validation failed', error.message);
      return false;
    }
  }

  // Validate API endpoint compatibility
  async validateAPICompatibility() {
    try {
      console.log('🔍 Validating Bookings API endpoint compatibility...');
      
      const bookings = await Booking.find({}).limit(5);
      let apiErrors = 0;

      for (const booking of bookings) {
        try {
          // Test booking data structure for API
          const bookingData = booking.toJSON();
          
          // Check required fields for API responses
          const requiredFields = ['id', 'bookingId', 'userId', 'vehicleName', 'pickupAddress', 'dropoffAddress', 'status'];
          for (const field of requiredFields) {
            if (!(field in bookingData)) {
              apiErrors++;
              this.addError(`Missing required field '${field}' in Bookings API response for booking ${booking.bookingId}`);
            }
          }

          // Validate status values
          const validStatuses = ['pending', 'confirmed', 'driverAssigned', 'driverEnRoute', 'driverArrived', 'inProgress', 'completed', 'cancelled', 'expired', 'disputed'];
          if (!validStatuses.includes(bookingData.status)) {
            apiErrors++;
            this.addError(`Invalid status '${bookingData.status}' in Bookings API response for booking ${booking.bookingId}`);
          }

          // Validate payment status values
          const validPaymentStatuses = ['pending', 'paid', 'failed', 'refunded', 'partially_refunded', 'disputed'];
          if (bookingData.paymentStatus && !validPaymentStatuses.includes(bookingData.paymentStatus)) {
            apiErrors++;
            this.addError(`Invalid paymentStatus '${bookingData.paymentStatus}' in Bookings API response for booking ${booking.bookingId}`);
          }

          // Validate vehicle type values
          const validVehicleTypes = ['sedan', 'suv', 'luxury', 'van', 'truck', 'motorcycle', 'electric', 'hybrid'];
          if (!validVehicleTypes.includes(bookingData.vehicleType)) {
            apiErrors++;
            this.addError(`Invalid vehicleType '${bookingData.vehicleType}' in Bookings API response for booking ${booking.bookingId}`);
          }

          // Validate service type values
          const validServiceTypes = ['standard', 'premium', 'corporate', 'airport', 'security', 'medical', 'event'];
          if (!validServiceTypes.includes(bookingData.serviceType)) {
            apiErrors++;
            this.addError(`Invalid serviceType '${bookingData.serviceType}' in Bookings API response for booking ${booking.bookingId}`);
          }

        } catch (error) {
          apiErrors++;
          this.addError(`API compatibility error for booking ${booking.bookingId}`, error.message);
        }
      }

      if (apiErrors === 0) {
        console.log('✅ Bookings API compatibility validation passed');
      } else {
        this.addError(`${apiErrors} Bookings API compatibility errors`);
      }

      return apiErrors === 0;
    } catch (error) {
      this.addError('API compatibility validation failed', error.message);
      return false;
    }
  }

  // Performance testing
  async validatePerformance() {
    try {
      console.log('🔍 Validating Bookings database performance...');
      
      const startTime = Date.now();
      
      // Test common booking queries
      await Booking.find({ status: 'completed' }).limit(100);
      const completedBookingsTime = Date.now() - startTime;
      
      const activeStartTime = Date.now();
      await Booking.find({ status: { $in: ['confirmed', 'driverAssigned', 'driverEnRoute', 'driverArrived', 'inProgress'] } }).limit(50);
      const activeBookingsTime = Date.now() - activeStartTime;
      
      const userStartTime = Date.now();
      await Booking.find({ userId: new mongoose.Types.ObjectId() }).limit(20);
      const userBookingsTime = Date.now() - userStartTime;
      
      const driverStartTime = Date.now();
      await Booking.find({ driverId: new mongoose.Types.ObjectId() }).limit(20);
      const driverBookingsTime = Date.now() - driverStartTime;
      
      // Performance thresholds (in milliseconds)
      const thresholds = {
        completedBookings: 500,
        activeBookings: 300,
        userBookings: 200,
        driverBookings: 200
      };

      if (completedBookingsTime > thresholds.completedBookings) {
        this.addWarning(`Completed bookings query slow: ${completedBookingsTime}ms (threshold: ${thresholds.completedBookings}ms)`);
      }

      if (activeBookingsTime > thresholds.activeBookings) {
        this.addWarning(`Active bookings query slow: ${activeBookingsTime}ms (threshold: ${thresholds.activeBookings}ms)`);
      }

      if (userBookingsTime > thresholds.userBookings) {
        this.addWarning(`User bookings query slow: ${userBookingsTime}ms (threshold: ${thresholds.userBookings}ms)`);
      }

      if (driverBookingsTime > thresholds.driverBookings) {
        this.addWarning(`Driver bookings query slow: ${driverBookingsTime}ms (threshold: ${thresholds.driverBookings}ms)`);
      }

      console.log(`📊 Bookings query performance:`);
      console.log(`  Completed bookings: ${completedBookingsTime}ms`);
      console.log(`  Active bookings: ${activeBookingsTime}ms`);
      console.log(`  User bookings: ${userBookingsTime}ms`);
      console.log(`  Driver bookings: ${driverBookingsTime}ms`);

      console.log('✅ Bookings performance validation completed');
      return true;
    } catch (error) {
      this.addError('Performance validation failed', error.message);
      return false;
    }
  }

  // Generate validation report
  generateReport() {
    console.log('\n📋 BOOKINGS VALIDATION REPORT');
    console.log('='.repeat(50));
    
    if (this.errors.length === 0) {
      console.log('✅ All Bookings validations passed successfully!');
    } else {
      console.log(`❌ ${this.errors.length} errors found:`);
      this.errors.forEach((error, index) => {
        console.log(`  ${index + 1}. ${error.message}`);
        if (error.details) {
          console.log(`     Details: ${error.details}`);
        }
      });
    }

    if (this.warnings.length > 0) {
      console.log(`\n⚠️ ${this.warnings.length} warnings:`);
      this.warnings.forEach((warning, index) => {
        console.log(`  ${index + 1}. ${warning.message}`);
        if (warning.details) {
          console.log(`     Details: ${warning.details}`);
        }
      });
    }

    console.log('\n📊 Bookings Summary:');
    console.log(`  Errors: ${this.errors.length}`);
    console.log(`  Warnings: ${this.warnings.length}`);
    console.log(`  Status: ${this.errors.length === 0 ? 'PASS' : 'FAIL'}`);

    return {
      errors: this.errors,
      warnings: this.warnings,
      passed: this.errors.length === 0
    };
  }

  // Run all validations
  async runAllValidations() {
    try {
      console.log('🚀 Starting comprehensive Bookings database validation...\n');

      // Connect to database first
      await this.connect();
      
      await this.validateConnection();
      await this.validateCollection();
      await this.validateIndexes();
      await this.validateDocuments();
      await this.validateDataConsistency();
      await this.validateVirtualFields();
      await this.validateStaticMethods();
      await this.validateAPICompatibility();
      await this.validatePerformance();

      const report = this.generateReport();
      return report;
    } catch (error) {
      console.error('❌ Bookings validation process failed:', error);
      this.addError('Validation process failed', error.message);
      return this.generateReport();
    }
  }

  // Close database connection
  async close() {
    try {
      if (this.connection) {
        await mongoose.connection.close();
        console.log('✅ Bookings database connection closed');
      }
    } catch (error) {
      console.error('❌ Error closing Bookings database connection:', error);
    }
  }
}

// CLI interface
if (require.main === module) {
  const validator = new BookingsDatabaseValidator();
  
  validator.runAllValidations()
    .then((report) => {
      const exitCode = report.passed ? 0 : 1;
      console.log(`\n🏁 Bookings validation completed with ${report.passed ? 'SUCCESS' : 'FAILURE'}`);
      process.exit(exitCode);
    })
    .catch((error) => {
      console.error('❌ Bookings validation failed:', error);
      process.exit(1);
    });
}

module.exports = BookingsDatabaseValidator;
