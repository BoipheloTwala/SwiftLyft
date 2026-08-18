const mongoose = require('mongoose');
const Driver = require('../models/Driver');
const User = require('../models/User');
require('dotenv').config();

class DriversDatabaseValidator {
  constructor() {
    this.connection = null;
    this.errors = [];
    this.warnings = [];
  }

  // Connect to MongoDB
  async connect() {
    try {
      const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_drivers';
      
      this.connection = await mongoose.connect(mongoUri, {
        useNewUrlParser: true,
        useUnifiedTopology: true,
      });

      console.log('✅ Connected to MongoDB for Drivers validation');
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
      console.log('🔍 Validating Drivers database connection...');
      
      if (!this.connection) {
        this.addError('No database connection established');
        return false;
      }

      // Test basic operations
      await this.connection.connection.db.admin().ping();
      console.log('✅ Drivers database connection is healthy');
      return true;
    } catch (error) {
      this.addError('Database connection failed', error.message);
      return false;
    }
  }

  // Validate collection exists and has proper structure
  async validateCollection() {
    try {
      console.log('🔍 Validating Drivers collection...');
      
      const collections = await this.connection.connection.db.listCollections().toArray();
      const driversCollection = collections.find(col => col.name === 'drivers');
      
      if (!driversCollection) {
        this.addError('Drivers collection does not exist');
        return false;
      }

      console.log('✅ Drivers collection exists');
      
      // Check collection stats
      const stats = await this.connection.connection.db.collection('drivers').stats();
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
      console.log('🔍 Validating Drivers database indexes...');
      
      const indexes = await Driver.collection.getIndexes();
      const requiredIndexes = [
        'driverId_1',
        'licenseNumber_1',
        'vehicleInfo.licensePlate_1',
        'userId_1',
        'currentLocation.coordinates_2dsphere',
        'availability.status_1',
        'status_1',
        'vehicleInfo.vehicleType_1',
        'performance.rating_1',
        'currentBookingId_1',
        'verificationStatus.backgroundCheck_1',
        'verificationStatus.documentsVerified_1',
        'verificationStatus.vehicleInspected_1',
        'createdAt_-1',
        'updatedAt_-1',
        'licenseExpiry_1',
        'performance.totalEarnings_-1',
        'performance.totalRides_-1',
        'performance.completedRides_-1',
        'availability.workingHours.start_1',
        'availability.workingHours.end_1'
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

      console.log('✅ Drivers indexes validation completed');
      return this.errors.length === 0;
    } catch (error) {
      this.addError('Index validation failed', error.message);
      return false;
    }
  }

  // Validate documents
  async validateDocuments() {
    try {
      console.log('🔍 Validating Drivers documents...');
      
      const totalDrivers = await Driver.countDocuments();
      if (totalDrivers === 0) {
        this.addWarning('No drivers found in database');
        return true;
      }

      console.log(`📊 Total drivers: ${totalDrivers}`);

      // Validate required fields
      const driversWithoutDriverId = await Driver.countDocuments({ driverId: { $exists: false } });
      if (driversWithoutDriverId > 0) {
        this.addError(`${driversWithoutDriverId} drivers missing driverId field`);
      }

      const driversWithoutUserId = await Driver.countDocuments({ userId: { $exists: false } });
      if (driversWithoutUserId > 0) {
        this.addError(`${driversWithoutUserId} drivers missing userId field`);
      }

      const driversWithoutLicenseNumber = await Driver.countDocuments({ licenseNumber: { $exists: false } });
      if (driversWithoutLicenseNumber > 0) {
        this.addError(`${driversWithoutLicenseNumber} drivers missing licenseNumber field`);
      }

      const driversWithoutLicenseExpiry = await Driver.countDocuments({ licenseExpiry: { $exists: false } });
      if (driversWithoutLicenseExpiry > 0) {
        this.addError(`${driversWithoutLicenseExpiry} drivers missing licenseExpiry field`);
      }

      // Validate vehicle type values
      const invalidVehicleTypes = await Driver.countDocuments({
        'vehicleInfo.vehicleType': { $nin: ['sedan', 'suv', 'luxury', 'van', 'truck', 'motorcycle'] }
      });
      if (invalidVehicleTypes > 0) {
        this.addError(`${invalidVehicleTypes} drivers have invalid vehicleType`);
      }

      // Validate status values
      const invalidStatuses = await Driver.countDocuments({
        status: { $nin: ['pending', 'approved', 'rejected', 'suspended', 'active'] }
      });
      if (invalidStatuses > 0) {
        this.addError(`${invalidStatuses} drivers have invalid status`);
      }

      // Validate availability status values
      const invalidAvailabilityStatuses = await Driver.countDocuments({
        'availability.status': { $nin: ['online', 'offline', 'busy', 'maintenance'] }
      });
      if (invalidAvailabilityStatuses > 0) {
        this.addError(`${invalidAvailabilityStatuses} drivers have invalid availability status`);
      }

      // Validate numeric fields
      const driversWithInvalidPassengerCapacity = await Driver.countDocuments({ 'vehicleInfo.passengerCapacity': { $lt: 1 } });
      if (driversWithInvalidPassengerCapacity > 0) {
        this.addError(`${driversWithInvalidPassengerCapacity} drivers have invalid passengerCapacity (less than 1)`);
      }

      const driversWithInvalidRating = await Driver.countDocuments({
        $or: [
          { 'performance.rating': { $lt: 0 } },
          { 'performance.rating': { $gt: 5 } }
        ]
      });
      if (driversWithInvalidRating > 0) {
        this.addError(`${driversWithInvalidRating} drivers have invalid rating (must be 0-5)`);
      }

      // Validate license expiry dates
      const expiredLicenses = await Driver.countDocuments({ licenseExpiry: { $lt: new Date() } });
      if (expiredLicenses > 0) {
        this.addWarning(`${expiredLicenses} drivers have expired licenses`);
      }

      // Validate required vehicle info fields
      const driversWithoutVehicleMake = await Driver.countDocuments({ 'vehicleInfo.make': { $exists: false } });
      if (driversWithoutVehicleMake > 0) {
        this.addError(`${driversWithoutVehicleMake} drivers missing vehicle make`);
      }

      const driversWithoutVehicleModel = await Driver.countDocuments({ 'vehicleInfo.model': { $exists: false } });
      if (driversWithoutVehicleModel > 0) {
        this.addError(`${driversWithoutVehicleModel} drivers missing vehicle model`);
      }

      const driversWithoutVehicleYear = await Driver.countDocuments({ 'vehicleInfo.year': { $exists: false } });
      if (driversWithoutVehicleYear > 0) {
        this.addError(`${driversWithoutVehicleYear} drivers missing vehicle year`);
      }

      const driversWithoutLicensePlate = await Driver.countDocuments({ 'vehicleInfo.licensePlate': { $exists: false } });
      if (driversWithoutLicensePlate > 0) {
        this.addError(`${driversWithoutLicensePlate} drivers missing license plate`);
      }

      // Validate required bank details
      const driversWithoutBankDetails = await Driver.countDocuments({ bankDetails: { $exists: false } });
      if (driversWithoutBankDetails > 0) {
        this.addError(`${driversWithoutBankDetails} drivers missing bank details`);
      }

      // Validate required documents
      const driversWithoutLicensePhoto = await Driver.countDocuments({ 'documents.licensePhoto': { $exists: false } });
      if (driversWithoutLicensePhoto > 0) {
        this.addError(`${driversWithoutLicensePhoto} drivers missing license photo`);
      }

      const driversWithoutVehicleRegistration = await Driver.countDocuments({ 'documents.vehicleRegistration': { $exists: false } });
      if (driversWithoutVehicleRegistration > 0) {
        this.addError(`${driversWithoutVehicleRegistration} drivers missing vehicle registration`);
      }

      const driversWithoutVehicleInsurance = await Driver.countDocuments({ 'documents.vehicleInsurance': { $exists: false } });
      if (driversWithoutVehicleInsurance > 0) {
        this.addError(`${driversWithoutVehicleInsurance} drivers missing vehicle insurance`);
      }

      // Validate emergency contact
      const driversWithoutEmergencyContact = await Driver.countDocuments({ emergencyContact: { $exists: false } });
      if (driversWithoutEmergencyContact > 0) {
        this.addError(`${driversWithoutEmergencyContact} drivers missing emergency contact`);
      }

      console.log('✅ Drivers document validation completed');
      return this.errors.length === 0;
    } catch (error) {
      this.addError('Document validation failed', error.message);
      return false;
    }
  }

  // Validate data consistency
  async validateDataConsistency() {
    try {
      console.log('🔍 Validating Drivers data consistency...');
      
      // Check for drivers with current booking but not busy
      const driversWithBookingButNotBusy = await Driver.countDocuments({
        currentBookingId: { $exists: true, $ne: null },
        'availability.status': { $ne: 'busy' }
      });
      if (driversWithBookingButNotBusy > 0) {
        this.addWarning(`${driversWithBookingButNotBusy} drivers have current booking but are not marked as busy`);
      }

      // Check for drivers with negative performance metrics
      const driversWithNegativeRides = await Driver.countDocuments({ 'performance.totalRides': { $lt: 0 } });
      if (driversWithNegativeRides > 0) {
        this.addError(`${driversWithNegativeRides} drivers have negative total rides`);
      }

      const driversWithNegativeCompletedRides = await Driver.countDocuments({ 'performance.completedRides': { $lt: 0 } });
      if (driversWithNegativeCompletedRides > 0) {
        this.addError(`${driversWithNegativeCompletedRides} drivers have negative completed rides`);
      }

      const driversWithNegativeCancelledRides = await Driver.countDocuments({ 'performance.cancelledRides': { $lt: 0 } });
      if (driversWithNegativeCancelledRides > 0) {
        this.addError(`${driversWithNegativeCancelledRides} drivers have negative cancelled rides`);
      }

      const driversWithNegativeEarnings = await Driver.countDocuments({ 'performance.totalEarnings': { $lt: 0 } });
      if (driversWithNegativeEarnings > 0) {
        this.addError(`${driversWithNegativeEarnings} drivers have negative total earnings`);
      }

      // Check for drivers with more completed rides than total rides
      const driversWithMoreCompletedThanTotal = await Driver.countDocuments({
        $expr: { $gt: ['$performance.completedRides', '$performance.totalRides'] }
      });
      if (driversWithMoreCompletedThanTotal > 0) {
        this.addError(`${driversWithMoreCompletedThanTotal} drivers have more completed rides than total rides`);
      }

      // Check for drivers with more cancelled rides than total rides
      const driversWithMoreCancelledThanTotal = await Driver.countDocuments({
        $expr: { $gt: ['$performance.cancelledRides', '$performance.totalRides'] }
      });
      if (driversWithMoreCancelledThanTotal > 0) {
        this.addError(`${driversWithMoreCancelledThanTotal} drivers have more cancelled rides than total rides`);
      }

      // Check for drivers with invalid working hours
      const driversWithInvalidWorkingHours = await Driver.countDocuments({
        $and: [
          { 'availability.workingHours.start': { $exists: true } },
          { 'availability.workingHours.end': { $exists: true } },
          { $expr: { $gt: ['$availability.workingHours.start', '$availability.workingHours.end'] } }
        ]
      });
      if (driversWithInvalidWorkingHours > 0) {
        this.addWarning(`${driversWithInvalidWorkingHours} drivers have invalid working hours (start time after end time)`);
      }

      // Check for drivers with invalid response time
      const driversWithInvalidResponseTime = await Driver.countDocuments({ 'performance.averageResponseTime': { $lt: 0 } });
      if (driversWithInvalidResponseTime > 0) {
        this.addError(`${driversWithInvalidResponseTime} drivers have invalid response time (negative)`);
      }

      // Check for drivers with invalid pickup percentage
      const driversWithInvalidPickupPercentage = await Driver.countDocuments({
        $or: [
          { 'performance.onTimePickup': { $lt: 0 } },
          { 'performance.onTimePickup': { $gt: 100 } }
        ]
      });
      if (driversWithInvalidPickupPercentage > 0) {
        this.addError(`${driversWithInvalidPickupPercentage} drivers have invalid on-time pickup percentage (must be 0-100)`);
      }

      // Check for drivers with invalid customer satisfaction
      const driversWithInvalidSatisfaction = await Driver.countDocuments({
        $or: [
          { 'performance.customerSatisfaction': { $lt: 0 } },
          { 'performance.customerSatisfaction': { $gt: 100 } }
        ]
      });
      if (driversWithInvalidSatisfaction > 0) {
        this.addError(`${driversWithInvalidSatisfaction} drivers have invalid customer satisfaction percentage (must be 0-100)`);
      }

      console.log('✅ Drivers data consistency validation completed');
      return true;
    } catch (error) {
      this.addError('Data consistency validation failed', error.message);
      return false;
    }
  }

  // Validate virtual fields
  async validateVirtualFields() {
    try {
      console.log('🔍 Validating Drivers virtual fields...');
      
      const drivers = await Driver.find({}).limit(10);
      let virtualFieldErrors = 0;

      for (const driver of drivers) {
        try {
          // Test virtual field calculations
          const isAvailable = driver.isAvailable;

          // Validate virtual field types
          if (typeof isAvailable !== 'boolean') {
            virtualFieldErrors++;
            this.addError(`Invalid isAvailable for driver ${driver.driverId}`);
          }

        } catch (error) {
          virtualFieldErrors++;
          this.addError(`Virtual field calculation error for driver ${driver.driverId}`, error.message);
        }
      }

      if (virtualFieldErrors === 0) {
        console.log('✅ Drivers virtual fields validation passed');
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
      console.log('🔍 Validating Drivers static methods...');
      
      // Test findByDriverId
      const testDriver = await Driver.findOne({});
      if (testDriver) {
        const foundDriver = await Driver.findByDriverId(testDriver.driverId);
        if (!foundDriver || foundDriver._id.toString() !== testDriver._id.toString()) {
          this.addError('findByDriverId method not working correctly');
        }
      }

      // Test findAvailableDrivers
      const availableDrivers = await Driver.findAvailableDrivers(-33.9249, 18.4241, 5000);
      if (!Array.isArray(availableDrivers)) {
        this.addError('findAvailableDrivers method did not return an array');
      }

      console.log('✅ Drivers static methods validation completed');
      return true;
    } catch (error) {
      this.addError('Static methods validation failed', error.message);
      return false;
    }
  }

  // Validate API endpoint compatibility
  async validateAPICompatibility() {
    try {
      console.log('🔍 Validating Drivers API endpoint compatibility...');
      
      const drivers = await Driver.find({}).limit(5);
      let apiErrors = 0;

      for (const driver of drivers) {
        try {
          // Test driver data structure for API
          const driverData = driver.toJSON();
          
          // Check required fields for API responses
          const requiredFields = ['id', 'driverId', 'userId', 'vehicleInfo', 'status', 'availability'];
          for (const field of requiredFields) {
            if (!(field in driverData)) {
              apiErrors++;
              this.addError(`Missing required field '${field}' in Drivers API response for driver ${driver.driverId}`);
            }
          }

          // Validate status values
          const validStatuses = ['pending', 'approved', 'rejected', 'suspended', 'active'];
          if (!validStatuses.includes(driverData.status)) {
            apiErrors++;
            this.addError(`Invalid status '${driverData.status}' in Drivers API response for driver ${driver.driverId}`);
          }

          // Validate availability status values
          const validAvailabilityStatuses = ['online', 'offline', 'busy', 'maintenance'];
          if (!validAvailabilityStatuses.includes(driverData.availability.status)) {
            apiErrors++;
            this.addError(`Invalid availability status '${driverData.availability.status}' in Drivers API response for driver ${driver.driverId}`);
          }

          // Validate vehicle type values
          const validVehicleTypes = ['sedan', 'suv', 'luxury', 'van', 'truck', 'motorcycle'];
          if (!validVehicleTypes.includes(driverData.vehicleInfo.vehicleType)) {
            apiErrors++;
            this.addError(`Invalid vehicleType '${driverData.vehicleInfo.vehicleType}' in Drivers API response for driver ${driver.driverId}`);
          }

          // Check that sensitive bank details are not exposed
          if ('bankDetails' in driverData) {
            apiErrors++;
            this.addError(`Sensitive bank details exposed in Drivers API response for driver ${driver.driverId}`);
          }

        } catch (error) {
          apiErrors++;
          this.addError(`API compatibility error for driver ${driver.driverId}`, error.message);
        }
      }

      if (apiErrors === 0) {
        console.log('✅ Drivers API compatibility validation passed');
      } else {
        this.addError(`${apiErrors} Drivers API compatibility errors`);
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
      console.log('🔍 Validating Drivers database performance...');
      
      const startTime = Date.now();
      
      // Test common driver queries
      await Driver.find({ status: 'active' }).limit(100);
      const activeDriversTime = Date.now() - startTime;
      
      const onlineStartTime = Date.now();
      await Driver.find({ 'availability.status': 'online' }).limit(50);
      const onlineDriversTime = Date.now() - onlineStartTime;
      
      const vehicleTypeStartTime = Date.now();
      await Driver.find({ 'vehicleInfo.vehicleType': 'sedan' }).limit(50);
      const vehicleTypeDriversTime = Date.now() - vehicleTypeStartTime;
      
      const locationStartTime = Date.now();
      await Driver.findAvailableDrivers(-33.9249, 18.4241, 5000);
      const locationDriversTime = Date.now() - locationStartTime;
      
      // Performance thresholds (in milliseconds)
      const thresholds = {
        activeDrivers: 500,
        onlineDrivers: 300,
        vehicleTypeDrivers: 200,
        locationDrivers: 400
      };

      if (activeDriversTime > thresholds.activeDrivers) {
        this.addWarning(`Active drivers query slow: ${activeDriversTime}ms (threshold: ${thresholds.activeDrivers}ms)`);
      }

      if (onlineDriversTime > thresholds.onlineDrivers) {
        this.addWarning(`Online drivers query slow: ${onlineDriversTime}ms (threshold: ${thresholds.onlineDrivers}ms)`);
      }

      if (vehicleTypeDriversTime > thresholds.vehicleTypeDrivers) {
        this.addWarning(`Vehicle type drivers query slow: ${vehicleTypeDriversTime}ms (threshold: ${thresholds.vehicleTypeDrivers}ms)`);
      }

      if (locationDriversTime > thresholds.locationDrivers) {
        this.addWarning(`Location drivers query slow: ${locationDriversTime}ms (threshold: ${thresholds.locationDrivers}ms)`);
      }

      console.log(`📊 Drivers query performance:`);
      console.log(`  Active drivers: ${activeDriversTime}ms`);
      console.log(`  Online drivers: ${onlineDriversTime}ms`);
      console.log(`  Vehicle type drivers: ${vehicleTypeDriversTime}ms`);
      console.log(`  Location drivers: ${locationDriversTime}ms`);

      console.log('✅ Drivers performance validation completed');
      return true;
    } catch (error) {
      this.addError('Performance validation failed', error.message);
      return false;
    }
  }

  // Generate validation report
  generateReport() {
    console.log('\n📋 DRIVERS VALIDATION REPORT');
    console.log('='.repeat(50));
    
    if (this.errors.length === 0) {
      console.log('✅ All Drivers validations passed successfully!');
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

    console.log('\n📊 Drivers Summary:');
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
      console.log('🚀 Starting comprehensive Drivers database validation...\n');

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
      console.error('❌ Drivers validation process failed:', error);
      this.addError('Validation process failed', error.message);
      return this.generateReport();
    }
  }

  // Close database connection
  async close() {
    try {
      if (this.connection) {
        await mongoose.connection.close();
        console.log('✅ Drivers database connection closed');
      }
    } catch (error) {
      console.error('❌ Error closing Drivers database connection:', error);
    }
  }
}

// CLI interface
if (require.main === module) {
  const validator = new DriversDatabaseValidator();
  
  validator.runAllValidations()
    .then((report) => {
      const exitCode = report.passed ? 0 : 1;
      console.log(`\n🏁 Drivers validation completed with ${report.passed ? 'SUCCESS' : 'FAILURE'}`);
      process.exit(exitCode);
    })
    .catch((error) => {
      console.error('❌ Drivers validation failed:', error);
      process.exit(1);
    });
}

module.exports = DriversDatabaseValidator;
