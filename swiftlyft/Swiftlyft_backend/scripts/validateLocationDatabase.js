const mongoose = require('mongoose');
const Location = require('../models/Location');
require('dotenv').config();

class LocationDatabaseValidator {
  constructor() {
    this.connection = null;
    this.errors = [];
    this.warnings = [];
  }

  // Connect to MongoDB
  async connect() {
    try {
      const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_locations';
      
      this.connection = await mongoose.connect(mongoUri, {
        useNewUrlParser: true,
        useUnifiedTopology: true,
      });

      console.log('✅ Connected to MongoDB for Location validation');
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
      console.log('🔍 Validating Location database connection...');
      
      if (!this.connection) {
        this.addError('No database connection established');
        return false;
      }

      // Test basic operations
      await this.connection.connection.db.admin().ping();
      console.log('✅ Location database connection is healthy');
      return true;
    } catch (error) {
      this.addError('Database connection failed', error.message);
      return false;
    }
  }

  // Validate collection exists and has proper structure
  async validateCollection() {
    try {
      console.log('🔍 Validating Location collection...');
      
      const collections = await this.connection.connection.db.listCollections().toArray();
      const locationCollection = collections.find(col => col.name === 'locations');
      
      if (!locationCollection) {
        this.addError('Locations collection does not exist');
        return false;
      }

      console.log('✅ Locations collection exists');
      
      // Check collection stats
      const stats = await this.connection.connection.db.collection('locations').stats();
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
      console.log('🔍 Validating Location database indexes...');
      
      const indexes = await Location.collection.getIndexes();
      const requiredIndexes = [
        'latitude_1_longitude_1',
        'location_2dsphere',
        'userId_1',
        'driverId_1',
        'bookingId_1',
        'type_1',
        'category_1',
        'serviceArea.isInServiceArea_1',
        'serviceArea.name_1',
        'serviceArea.city_1',
        'address.city_1',
        'address.state_1',
        'address.country_1',
        'metadata.source_1',
        'metadata.confidence_1',
        'timestamp_-1',
        'lastUpdated_-1',
        'createdAt_-1',
        'updatedAt_-1',
        'isActive_1',
        'accuracy_1',
        'altitude_1',
        'heading_1',
        'speed_1',
        'coordinates.lat_1_coordinates.lng_1'
      ];

      const existingIndexNames = typeof indexes === 'object' ? Object.keys(indexes) : [];
      
      for (const requiredIndex of requiredIndexes) {
        if (!existingIndexNames.includes(requiredIndex)) {
          this.addError(`Required index missing: ${requiredIndex}`);
        } else {
          console.log(`✅ Index exists: ${requiredIndex}`);
        }
      }

      console.log(`📊 Total indexes: ${Object.keys(indexes).length}`);

      console.log('✅ Location indexes validation completed');
      return this.errors.length === 0;
    } catch (error) {
      this.addError('Index validation failed', error.message);
      return false;
    }
  }

  // Validate documents
  async validateDocuments() {
    try {
      console.log('🔍 Validating Location documents...');
      
      const totalLocations = await Location.countDocuments();
      if (totalLocations === 0) {
        this.addWarning('No locations found in database');
        return true;
      }

      console.log(`📊 Total locations: ${totalLocations}`);

      // Validate required fields
      const locationsWithoutLatitude = await Location.countDocuments({ latitude: { $exists: false } });
      if (locationsWithoutLatitude > 0) {
        this.addError(`${locationsWithoutLatitude} locations missing latitude field`);
      }

      const locationsWithoutLongitude = await Location.countDocuments({ longitude: { $exists: false } });
      if (locationsWithoutLongitude > 0) {
        this.addError(`${locationsWithoutLongitude} locations missing longitude field`);
      }

      const locationsWithoutAddress = await Location.countDocuments({ 'address.formatted': { $exists: false } });
      if (locationsWithoutAddress > 0) {
        this.addError(`${locationsWithoutAddress} locations missing address.formatted field`);
      }

      // Validate coordinate ranges
      const invalidLatitudes = await Location.countDocuments({
        $or: [
          { latitude: { $lt: -90 } },
          { latitude: { $gt: 90 } }
        ]
      });
      if (invalidLatitudes > 0) {
        this.addError(`${invalidLatitudes} locations have invalid latitude values (must be -90 to 90)`);
      }

      const invalidLongitudes = await Location.countDocuments({
        $or: [
          { longitude: { $lt: -180 } },
          { longitude: { $gt: 180 } }
        ]
      });
      if (invalidLongitudes > 0) {
        this.addError(`${invalidLongitudes} locations have invalid longitude values (must be -180 to 180)`);
      }

      // Validate type values
      const invalidTypes = await Location.countDocuments({
        type: { $nin: ['pickup', 'dropoff', 'waypoint', 'driver', 'landmark', 'other'] }
      });
      if (invalidTypes > 0) {
        this.addError(`${invalidTypes} locations have invalid type values`);
      }

      // Validate category values
      const invalidCategories = await Location.countDocuments({
        category: { $nin: ['residential', 'commercial', 'airport', 'station', 'hospital', 'school', 'other'] }
      });
      if (invalidCategories > 0) {
        this.addError(`${invalidCategories} locations have invalid category values`);
      }

      // Validate metadata source values
      const invalidSources = await Location.countDocuments({
        'metadata.source': { $nin: ['gps', 'manual', 'geocoded', 'reverse_geocoded'] }
      });
      if (invalidSources > 0) {
        this.addError(`${invalidSources} locations have invalid metadata.source values`);
      }

      // Validate metadata confidence values
      const invalidConfidence = await Location.countDocuments({
        'metadata.confidence': { $nin: ['high', 'medium', 'low'] }
      });
      if (invalidConfidence > 0) {
        this.addError(`${invalidConfidence} locations have invalid metadata.confidence values`);
      }

      // Validate accuracy values
      const invalidAccuracy = await Location.countDocuments({
        accuracy: { $lt: 0 }
      });
      if (invalidAccuracy > 0) {
        this.addError(`${invalidAccuracy} locations have invalid accuracy values (must be >= 0)`);
      }

      // Validate heading values
      const invalidHeading = await Location.countDocuments({
        $or: [
          { heading: { $lt: 0 } },
          { heading: { $gt: 360 } }
        ]
      });
      if (invalidHeading > 0) {
        this.addError(`${invalidHeading} locations have invalid heading values (must be 0-360)`);
      }

      // Validate speed values
      const invalidSpeed = await Location.countDocuments({
        speed: { $lt: 0 }
      });
      if (invalidSpeed > 0) {
        this.addError(`${invalidSpeed} locations have invalid speed values (must be >= 0)`);
      }

      // Validate coordinates sync
      const locationsWithMismatchedCoordinates = await Location.countDocuments({
        $expr: {
          $or: [
            { $ne: ['$latitude', '$coordinates.lat'] },
            { $ne: ['$longitude', '$coordinates.lng'] }
          ]
        }
      });
      if (locationsWithMismatchedCoordinates > 0) {
        this.addWarning(`${locationsWithMismatchedCoordinates} locations have mismatched coordinates (latitude/longitude vs coordinates.lat/lng)`);
      }

      // Validate service area data
      const locationsWithoutServiceArea = await Location.countDocuments({
        'serviceArea.isInServiceArea': { $exists: false }
      });
      if (locationsWithoutServiceArea > 0) {
        this.addWarning(`${locationsWithoutServiceArea} locations missing service area information`);
      }

      // Validate timestamp consistency
      const locationsWithInvalidTimestamps = await Location.countDocuments({
        $expr: { $gt: ['$timestamp', '$lastUpdated'] }
      });
      if (locationsWithInvalidTimestamps > 0) {
        this.addWarning(`${locationsWithInvalidTimestamps} locations have timestamp after lastUpdated`);
      }

      console.log('✅ Location document validation completed');
      return this.errors.length === 0;
    } catch (error) {
      this.addError('Document validation failed', error.message);
      return false;
    }
  }

  // Validate data consistency
  async validateDataConsistency() {
    try {
      console.log('🔍 Validating Location data consistency...');
      
      // Check for locations with missing coordinates sync
      const locationsWithMissingCoordinates = await Location.countDocuments({
        $or: [
          { 'coordinates.lat': { $exists: false } },
          { 'coordinates.lng': { $exists: false } }
        ]
      });
      if (locationsWithMissingCoordinates > 0) {
        this.addWarning(`${locationsWithMissingCoordinates} locations missing coordinates sync for Flutter compatibility`);
      }

      // Check for locations with invalid service area data
      const locationsWithInvalidServiceArea = await Location.countDocuments({
        'serviceArea.isInServiceArea': true,
        'serviceArea.name': { $exists: false }
      });
      if (locationsWithInvalidServiceArea > 0) {
        this.addError(`${locationsWithInvalidServiceArea} locations marked as in service area but missing service area name`);
      }

      // Check for locations with invalid address data
      const locationsWithInvalidAddress = await Location.countDocuments({
        'address.formatted': { $exists: true },
        'address.city': { $exists: false }
      });
      if (locationsWithInvalidAddress > 0) {
        this.addWarning(`${locationsWithInvalidAddress} locations have formatted address but missing city information`);
      }

      // Check for locations with invalid metadata
      const locationsWithInvalidMetadata = await Location.countDocuments({
        'metadata.source': { $exists: true },
        'metadata.confidence': { $exists: false }
      });
      if (locationsWithInvalidMetadata > 0) {
        this.addWarning(`${locationsWithInvalidMetadata} locations have metadata source but missing confidence level`);
      }

      // Check for locations with invalid accuracy data
      const locationsWithInvalidAccuracy = await Location.countDocuments({
        accuracy: { $gt: 100 }
      });
      if (locationsWithInvalidAccuracy > 0) {
        this.addWarning(`${locationsWithInvalidAccuracy} locations have very high accuracy values (>100m)`);
      }

      // Check for locations with invalid altitude data
      const locationsWithInvalidAltitude = await Location.countDocuments({
        altitude: { $gt: 10000 }
      });
      if (locationsWithInvalidAltitude > 0) {
        this.addWarning(`${locationsWithInvalidAltitude} locations have very high altitude values (>10km)`);
      }

      // Check for locations with invalid speed data
      const locationsWithInvalidSpeed = await Location.countDocuments({
        speed: { $gt: 200 }
      });
      if (locationsWithInvalidSpeed > 0) {
        this.addWarning(`${locationsWithInvalidSpeed} locations have very high speed values (>200 km/h)`);
      }

      // Check for locations with invalid heading data
      const locationsWithInvalidHeading = await Location.countDocuments({
        heading: { $gt: 360 }
      });
      if (locationsWithInvalidHeading > 0) {
        this.addError(`${locationsWithInvalidHeading} locations have invalid heading values (>360 degrees)`);
      }

      console.log('✅ Location data consistency validation completed');
      return true;
    } catch (error) {
      this.addError('Data consistency validation failed', error.message);
      return false;
    }
  }

  // Validate virtual fields
  async validateVirtualFields() {
    try {
      console.log('🔍 Validating Location virtual fields...');
      
      const locations = await Location.find({}).limit(10);
      let virtualFieldErrors = 0;

      for (const location of locations) {
        try {
          // Test virtual field calculations
          const locationObject = location.toJSON();

          // Validate virtual field types
          if (!locationObject.location || typeof locationObject.location.latitude !== 'number') {
            virtualFieldErrors++;
            this.addError(`Invalid location virtual field for location ${location._id}`);
          }

          if (!locationObject.coordinates || typeof locationObject.coordinates.lat !== 'number') {
            virtualFieldErrors++;
            this.addError(`Invalid coordinates virtual field for location ${location._id}`);
          }

        } catch (error) {
          virtualFieldErrors++;
          this.addError(`Virtual field calculation error for location ${location._id}`, error.message);
        }
      }

      if (virtualFieldErrors === 0) {
        console.log('✅ Location virtual fields validation passed');
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
      console.log('🔍 Validating Location static methods...');
      
      // Test findNearby
      const nearbyLocations = await Location.findNearby(-33.9249, 18.4241, 10);
      if (!Array.isArray(nearbyLocations)) {
        this.addError('findNearby method did not return an array');
      }

      // Test findInServiceArea
      const serviceAreaLocations = await Location.findInServiceArea('Cape Town');
      if (!Array.isArray(serviceAreaLocations)) {
        this.addError('findInServiceArea method did not return an array');
      }

      console.log('✅ Location static methods validation completed');
      return true;
    } catch (error) {
      this.addError('Static methods validation failed', error.message);
      return false;
    }
  }

  // Validate API endpoint compatibility
  async validateAPICompatibility() {
    try {
      console.log('🔍 Validating Location API endpoint compatibility...');
      
      const locations = await Location.find({}).limit(5);
      let apiErrors = 0;

      for (const location of locations) {
        try {
          // Test location data structure for API
          const locationData = location.toJSON();
          
          // Check required fields for API responses
          const requiredFields = ['latitude', 'longitude', 'address', 'type', 'category'];
          for (const field of requiredFields) {
            if (!(field in locationData)) {
              apiErrors++;
              this.addError(`Missing required field '${field}' in Location API response for location ${location._id}`);
            }
          }

          // Validate type values
          const validTypes = ['pickup', 'dropoff', 'waypoint', 'driver', 'landmark', 'other'];
          if (!validTypes.includes(locationData.type)) {
            apiErrors++;
            this.addError(`Invalid type '${locationData.type}' in Location API response for location ${location._id}`);
          }

          // Validate category values
          const validCategories = ['residential', 'commercial', 'airport', 'station', 'hospital', 'school', 'other'];
          if (!validCategories.includes(locationData.category)) {
            apiErrors++;
            this.addError(`Invalid category '${locationData.category}' in Location API response for location ${location._id}`);
          }

          // Check Flutter compatibility
          if (!locationData.coordinates || !locationData.location) {
            apiErrors++;
            this.addError(`Missing Flutter compatibility fields in Location API response for location ${location._id}`);
          }

        } catch (error) {
          apiErrors++;
          this.addError(`API compatibility error for location ${location._id}`, error.message);
        }
      }

      if (apiErrors === 0) {
        console.log('✅ Location API compatibility validation passed');
      } else {
        this.addError(`${apiErrors} Location API compatibility errors`);
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
      console.log('🔍 Validating Location database performance...');
      
      const startTime = Date.now();
      
      // Test common location queries
      await Location.find({ isActive: true }).limit(100);
      const activeLocationsTime = Date.now() - startTime;
      
      const nearbyStartTime = Date.now();
      await Location.findNearby(-33.9249, 18.4241, 10);
      const nearbyLocationsTime = Date.now() - nearbyStartTime;
      
      const typeStartTime = Date.now();
      await Location.find({ type: 'landmark' }).limit(50);
      const typeLocationsTime = Date.now() - typeStartTime;
      
      const serviceAreaStartTime = Date.now();
      await Location.findInServiceArea('Cape Town');
      const serviceAreaLocationsTime = Date.now() - serviceAreaStartTime;
      
      // Performance thresholds (in milliseconds)
      const thresholds = {
        activeLocations: 500,
        nearbyLocations: 300,
        typeLocations: 200,
        serviceAreaLocations: 400
      };

      if (activeLocationsTime > thresholds.activeLocations) {
        this.addWarning(`Active locations query slow: ${activeLocationsTime}ms (threshold: ${thresholds.activeLocations}ms)`);
      }

      if (nearbyLocationsTime > thresholds.nearbyLocations) {
        this.addWarning(`Nearby locations query slow: ${nearbyLocationsTime}ms (threshold: ${thresholds.nearbyLocations}ms)`);
      }

      if (typeLocationsTime > thresholds.typeLocations) {
        this.addWarning(`Type locations query slow: ${typeLocationsTime}ms (threshold: ${thresholds.typeLocations}ms)`);
      }

      if (serviceAreaLocationsTime > thresholds.serviceAreaLocations) {
        this.addWarning(`Service area locations query slow: ${serviceAreaLocationsTime}ms (threshold: ${thresholds.serviceAreaLocations}ms)`);
      }

      console.log(`📊 Location query performance:`);
      console.log(`  Active locations: ${activeLocationsTime}ms`);
      console.log(`  Nearby locations: ${nearbyLocationsTime}ms`);
      console.log(`  Type locations: ${typeLocationsTime}ms`);
      console.log(`  Service area locations: ${serviceAreaLocationsTime}ms`);

      console.log('✅ Location performance validation completed');
      return true;
    } catch (error) {
      this.addError('Performance validation failed', error.message);
      return false;
    }
  }

  // Generate validation report
  generateReport() {
    console.log('\n📋 LOCATION VALIDATION REPORT');
    console.log('='.repeat(50));
    
    if (this.errors.length === 0) {
      console.log('✅ All Location validations passed successfully!');
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

    console.log('\n📊 Location Summary:');
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
      console.log('🚀 Starting comprehensive Location database validation...\n');

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
      console.error('❌ Location validation process failed:', error);
      this.addError('Validation process failed', error.message);
      return this.generateReport();
    }
  }

  // Close database connection
  async close() {
    try {
      if (this.connection) {
        await mongoose.connection.close();
        console.log('✅ Location database connection closed');
      }
    } catch (error) {
      console.error('❌ Error closing Location database connection:', error);
    }
  }
}

// CLI interface
if (require.main === module) {
  const validator = new LocationDatabaseValidator();
  
  validator.runAllValidations()
    .then((report) => {
      const exitCode = report.passed ? 0 : 1;
      console.log(`\n🏁 Location validation completed with ${report.passed ? 'SUCCESS' : 'FAILURE'}`);
      process.exit(exitCode);
    })
    .catch((error) => {
      console.error('❌ Location validation failed:', error);
      process.exit(1);
    });
}

module.exports = LocationDatabaseValidator;
