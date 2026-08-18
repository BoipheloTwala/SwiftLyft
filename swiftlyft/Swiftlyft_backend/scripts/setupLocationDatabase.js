const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Location = require('../models/Location');

class LocationDatabaseSetup {
  constructor() {
    this.connection = null;
  }
    
    // Connect to MongoDB
  async connect() {
    try {
      const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_locations';
      
      this.connection = await mongoose.connect(mongoUri, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    
      console.log('✅ Connected to MongoDB for Locations');
      console.log(`📊 Database: ${mongoose.connection.name}`);
      return this.connection;
  } catch (error) {
      console.error('❌ MongoDB connection error:', error);
      throw error;
    }
  }
  
  // Create indexes for optimal performance
  async createIndexes() {
    try {
      console.log('🔍 Creating Location database indexes...');

      // Basic coordinate indexes
      await Location.collection.createIndex({ "latitude": 1, "longitude": 1 });
      console.log('✅ Created latitude + longitude index');

      // Geospatial index for location-based queries
      await Location.collection.createIndex({ "location": "2dsphere" });
      console.log('✅ Created location 2dsphere index');

      // User relationship indexes
      await Location.collection.createIndex({ "userId": 1 });
      console.log('✅ Created userId index');

      await Location.collection.createIndex({ "driverId": 1 });
      console.log('✅ Created driverId index');

      await Location.collection.createIndex({ "bookingId": 1 });
      console.log('✅ Created bookingId index');

      // Type and category indexes
      await Location.collection.createIndex({ "type": 1 });
      console.log('✅ Created type index');

      await Location.collection.createIndex({ "category": 1 });
      console.log('✅ Created category index');

      // Service area indexes
      await Location.collection.createIndex({ "serviceArea.isInServiceArea": 1 });
      console.log('✅ Created serviceArea.isInServiceArea index');

      await Location.collection.createIndex({ "serviceArea.name": 1 });
      console.log('✅ Created serviceArea.name index');

      await Location.collection.createIndex({ "serviceArea.city": 1 });
      console.log('✅ Created serviceArea.city index');

      // Address indexes
      await Location.collection.createIndex({ "address.city": 1 });
      console.log('✅ Created address.city index');

      await Location.collection.createIndex({ "address.state": 1 });
      console.log('✅ Created address.state index');

      await Location.collection.createIndex({ "address.country": 1 });
      console.log('✅ Created address.country index');

      // Metadata indexes
      await Location.collection.createIndex({ "metadata.source": 1 });
      console.log('✅ Created metadata.source index');

      await Location.collection.createIndex({ "metadata.confidence": 1 });
      console.log('✅ Created metadata.confidence index');

      // Time-based indexes
      await Location.collection.createIndex({ "timestamp": -1 });
      console.log('✅ Created timestamp index');

      await Location.collection.createIndex({ "lastUpdated": -1 });
      console.log('✅ Created lastUpdated index');

      await Location.collection.createIndex({ "createdAt": -1 });
      console.log('✅ Created createdAt index');

      await Location.collection.createIndex({ "updatedAt": -1 });
      console.log('✅ Created updatedAt index');

      // Status index
      await Location.collection.createIndex({ "isActive": 1 });
      console.log('✅ Created isActive index');

      // Compound indexes for complex queries
      await Location.collection.createIndex({ 
        "userId": 1, 
        "isActive": 1, 
        "timestamp": -1 
      });
      console.log('✅ Created userId + isActive + timestamp compound index');

      await Location.collection.createIndex({ 
        "driverId": 1, 
        "isActive": 1, 
        "timestamp": -1 
      });
      console.log('✅ Created driverId + isActive + timestamp compound index');

      await Location.collection.createIndex({ 
        "type": 1, 
        "isActive": 1, 
        "timestamp": -1 
      });
      console.log('✅ Created type + isActive + timestamp compound index');

      await Location.collection.createIndex({ 
        "serviceArea.name": 1, 
        "serviceArea.isInServiceArea": 1, 
        "isActive": 1 
      });
      console.log('✅ Created serviceArea compound index');

      await Location.collection.createIndex({ 
        "category": 1, 
        "isActive": 1, 
        "timestamp": -1 
      });
      console.log('✅ Created category + isActive + timestamp compound index');

      await Location.collection.createIndex({ 
        "metadata.source": 1, 
        "metadata.confidence": 1, 
        "timestamp": -1 
      });
      console.log('✅ Created metadata compound index');

      // Text search index for address information
      await Location.collection.createIndex({ 
        "address.formatted": "text", 
        "address.streetName": "text", 
        "address.suburb": "text", 
        "address.city": "text" 
      });
      console.log('✅ Created text search index');

      // Accuracy and altitude indexes
      await Location.collection.createIndex({ "accuracy": 1 });
      console.log('✅ Created accuracy index');

      await Location.collection.createIndex({ "altitude": 1 });
      console.log('✅ Created altitude index');

      // Heading and speed indexes
      await Location.collection.createIndex({ "heading": 1 });
      console.log('✅ Created heading index');

      await Location.collection.createIndex({ "speed": 1 });
      console.log('✅ Created speed index');

      // Coordinates sync index for Flutter compatibility
      await Location.collection.createIndex({ "coordinates.lat": 1, "coordinates.lng": 1 });
      console.log('✅ Created coordinates sync index');

      console.log('🎉 All Location indexes created successfully!');
    } catch (error) {
      console.error('❌ Error creating Location indexes:', error);
      throw error;
    }
  }

  // Validate database schema
  async validateSchema() {
    try {
      console.log('🔍 Validating Location database schema...');

      // Test Location creation with validation
      const testLocation = new Location({
        latitude: -33.9249,
        longitude: 18.4241,
        coordinates: {
          lat: -33.9249,
          lng: 18.4241
        },
        address: {
          formatted: 'Cape Town Central, Cape Town, South Africa',
          streetNumber: '123',
          streetName: 'Main Street',
          suburb: 'City Bowl',
          city: 'Cape Town',
          state: 'Western Cape',
        country: 'South Africa',
          countryCode: 'ZA',
          postcode: '8001'
        },
        accuracy: 5.0,
        altitude: 10.0,
        heading: 45.0,
        speed: 25.0,
        serviceArea: {
        name: 'Cape Town',
        city: 'Cape Town',
          isInServiceArea: true,
        center: {
          latitude: -33.9249,
          longitude: 18.4241
        },
          radius: 50.0
        },
        type: 'landmark',
        category: 'commercial',
        userId: new mongoose.Types.ObjectId(),
        driverId: new mongoose.Types.ObjectId(),
        bookingId: new mongoose.Types.ObjectId(),
        timestamp: new Date(),
        lastUpdated: new Date(),
        metadata: {
          source: 'gps',
          confidence: 'high',
          notes: 'Test location',
          tags: ['test', 'landmark']
        },
        isActive: true
      });

      // Validate the document
      await testLocation.validate();
      console.log('✅ Location schema validation passed');

      // Test virtual fields
      console.log('🔍 Testing virtual fields...');
      const location = testLocation.toJSON();
      console.log(`Location object: ${JSON.stringify(location.location)}`);

      // Test instance methods
      console.log('🔍 Testing instance methods...');
      
      // Test distance calculation
      const otherLocation = {
        latitude: -33.9250,
        longitude: 18.4242
      };
      const distance = testLocation.distanceTo(otherLocation);
      console.log(`✅ Distance calculation method works: ${distance.toFixed(4)} km`);

      // Test service area check
      const serviceArea = testLocation.checkServiceArea();
      console.log(`✅ Service area check method works: ${serviceArea.name}`);

      console.log('🎉 Location schema validation completed successfully!');
    } catch (error) {
      console.error('❌ Location schema validation failed:', error);
      throw error;
    }
  }

  // Create sample data for testing
  async createSampleData() {
    try {
      console.log('🌱 Creating Location sample data...');

      // Check if sample data already exists
      const existingLocations = await Location.countDocuments();
      if (existingLocations > 0) {
        console.log('⚠️ Location sample data already exists, skipping...');
        return;
      }

      // Create sample locations
    const sampleLocations = [
      {
        latitude: -26.2041,
        longitude: 28.0473,
        coordinates: {
          lat: -26.2041,
          lng: 28.0473
        },
        address: {
          formatted: 'Johannesburg Central, Johannesburg, South Africa',
            streetNumber: '1',
            streetName: 'Carlton Centre',
            suburb: 'CBD',
          city: 'Johannesburg',
          state: 'Gauteng',
          country: 'South Africa',
            countryCode: 'ZA',
            postcode: '2000'
          },
          accuracy: 3.0,
          altitude: 1753.0,
          heading: 0.0,
          speed: 0.0,
        serviceArea: {
          name: 'Johannesburg',
          city: 'Johannesburg',
          isInServiceArea: true,
          center: {
            latitude: -26.2041,
            longitude: 28.0473
          },
          radius: 50.0
        },
          type: 'landmark',
          category: 'commercial',
          userId: new mongoose.Types.ObjectId(),
          driverId: null,
          bookingId: null,
          timestamp: new Date(),
          lastUpdated: new Date(),
        metadata: {
          source: 'geocoded',
          confidence: 'high',
            notes: 'Johannesburg city center landmark',
            tags: ['landmark', 'central', 'commercial']
          },
          isActive: true
      },
      {
        latitude: -33.9249,
        longitude: 18.4241,
        coordinates: {
          lat: -33.9249,
          lng: 18.4241
        },
        address: {
          formatted: 'Cape Town Central, Cape Town, South Africa',
            streetNumber: '1',
            streetName: 'Adderley Street',
            suburb: 'City Bowl',
          city: 'Cape Town',
          state: 'Western Cape',
          country: 'South Africa',
            countryCode: 'ZA',
            postcode: '8001'
          },
          accuracy: 2.5,
          altitude: 10.0,
          heading: 180.0,
          speed: 0.0,
        serviceArea: {
          name: 'Cape Town',
          city: 'Cape Town',
          isInServiceArea: true,
          center: {
            latitude: -33.9249,
            longitude: 18.4241
          },
          radius: 50.0
        },
          type: 'landmark',
          category: 'commercial',
          userId: new mongoose.Types.ObjectId(),
          driverId: null,
          bookingId: null,
          timestamp: new Date(),
          lastUpdated: new Date(),
          metadata: {
            source: 'geocoded',
            confidence: 'high',
            notes: 'Cape Town city center landmark',
            tags: ['landmark', 'central', 'commercial']
          },
          isActive: true
        },
        {
          latitude: -29.8587,
          longitude: 31.0218,
          coordinates: {
            lat: -29.8587,
            lng: 31.0218
          },
          address: {
            formatted: 'Durban Central, Durban, South Africa',
            streetNumber: '1',
            streetName: 'West Street',
            suburb: 'CBD',
            city: 'Durban',
            state: 'KwaZulu-Natal',
            country: 'South Africa',
            countryCode: 'ZA',
            postcode: '4001'
          },
          accuracy: 4.0,
          altitude: 5.0,
          heading: 90.0,
          speed: 0.0,
          serviceArea: {
            name: 'Durban',
            city: 'Durban',
            isInServiceArea: true,
            center: {
              latitude: -29.8587,
              longitude: 31.0218
            },
            radius: 50.0
          },
          type: 'landmark',
          category: 'commercial',
          userId: new mongoose.Types.ObjectId(),
          driverId: null,
          bookingId: null,
          timestamp: new Date(),
          lastUpdated: new Date(),
          metadata: {
            source: 'geocoded',
            confidence: 'high',
            notes: 'Durban city center landmark',
            tags: ['landmark', 'central', 'commercial']
          },
          isActive: true
        },
        {
          latitude: -25.7479,
          longitude: 28.2293,
          coordinates: {
            lat: -25.7479,
            lng: 28.2293
          },
          address: {
            formatted: 'Pretoria Central, Pretoria, South Africa',
            streetNumber: '1',
            streetName: 'Church Square',
            suburb: 'CBD',
            city: 'Pretoria',
            state: 'Gauteng',
            country: 'South Africa',
            countryCode: 'ZA',
            postcode: '0002'
          },
          accuracy: 3.5,
          altitude: 1339.0,
          heading: 270.0,
          speed: 0.0,
          serviceArea: {
            name: 'Pretoria',
            city: 'Pretoria',
            isInServiceArea: true,
            center: {
              latitude: -25.7479,
              longitude: 28.2293
            },
            radius: 50.0
          },
          type: 'landmark',
          category: 'commercial',
          userId: new mongoose.Types.ObjectId(),
          driverId: null,
          bookingId: null,
          timestamp: new Date(),
          lastUpdated: new Date(),
        metadata: {
          source: 'geocoded',
          confidence: 'high',
            notes: 'Pretoria city center landmark',
            tags: ['landmark', 'central', 'commercial']
          },
          isActive: true
        },
        {
          latitude: -26.2041,
          longitude: 28.0473,
          coordinates: {
            lat: -26.2041,
            lng: 28.0473
          },
          address: {
            formatted: 'Sandton City, Sandton, Johannesburg, South Africa',
            streetNumber: '123',
            streetName: 'Rivonia Road',
            suburb: 'Sandton',
            city: 'Johannesburg',
            state: 'Gauteng',
            country: 'South Africa',
            countryCode: 'ZA',
            postcode: '2196'
          },
          accuracy: 5.0,
          altitude: 1600.0,
          heading: 45.0,
          speed: 0.0,
          serviceArea: {
            name: 'Johannesburg',
            city: 'Johannesburg',
            isInServiceArea: true,
            center: {
              latitude: -26.2041,
              longitude: 28.0473
            },
            radius: 50.0
          },
          type: 'pickup',
          category: 'commercial',
          userId: new mongoose.Types.ObjectId(),
          driverId: null,
          bookingId: new mongoose.Types.ObjectId(),
        timestamp: new Date(),
        lastUpdated: new Date(),
          metadata: {
            source: 'manual',
            confidence: 'medium',
            notes: 'Sandton City pickup location',
            tags: ['pickup', 'shopping', 'commercial']
          },
          isActive: true
        }
      ];

      // Create locations
      for (const locationData of sampleLocations) {
        const location = new Location(locationData);
        await location.save();
        console.log(`✅ Created location: ${location.address.formatted}`);
      }

      console.log('🎉 Location sample data created successfully!');
    } catch (error) {
      console.error('❌ Error creating Location sample data:', error);
      throw error;
    }
  }

  // Run database health check
  async healthCheck() {
    try {
      console.log('🏥 Running Location database health check...');

      // Check connection
      if (!this.connection) {
        throw new Error('No database connection');
      }

      // Check database stats
      const stats = await this.connection.connection.db.stats();
      console.log(`📊 Database size: ${(stats.dataSize / 1024 / 1024).toFixed(2)} MB`);
      console.log(`📊 Collections: ${stats.collections}`);
      console.log(`📊 Documents: ${stats.objects || 0}`);

      // Check Location collection stats
      const locationCount = await Location.countDocuments();
      const activeLocations = await Location.countDocuments({ isActive: true });
      const landmarks = await Location.countDocuments({ type: 'landmark' });
      const pickupLocations = await Location.countDocuments({ type: 'pickup' });
      const dropoffLocations = await Location.countDocuments({ type: 'dropoff' });
      const inServiceArea = await Location.countDocuments({ 'serviceArea.isInServiceArea': true });

      console.log(`📊 Total locations: ${locationCount}`);
      console.log(`📊 Active locations: ${activeLocations}`);
      console.log(`📊 Landmarks: ${landmarks}`);
      console.log(`📊 Pickup locations: ${pickupLocations}`);
      console.log(`📊 Dropoff locations: ${dropoffLocations}`);
      console.log(`📊 In service area: ${inServiceArea}`);

      // Check indexes
      const indexes = await Location.collection.getIndexes();
      console.log(`🔍 Indexes: ${Object.keys(indexes).length}`);

      // Check type distribution
      const typeStats = await Location.aggregate([
        { $group: { _id: '$type', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]);

      console.log('\n📍 Type Distribution:');
      typeStats.forEach(stat => {
        console.log(`  ${stat._id}: ${stat.count}`);
      });

      // Check category distribution
      const categoryStats = await Location.aggregate([
        { $group: { _id: '$category', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]);

      console.log('\n🏢 Category Distribution:');
      categoryStats.forEach(stat => {
        console.log(`  ${stat._id}: ${stat.count}`);
      });

      // Check service area distribution
      const serviceAreaStats = await Location.aggregate([
        { $group: { _id: '$serviceArea.name', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]);

      console.log('\n🌍 Service Area Distribution:');
      serviceAreaStats.forEach(stat => {
        console.log(`  ${stat._id}: ${stat.count}`);
      });

      // Check metadata source distribution
      const sourceStats = await Location.aggregate([
        { $group: { _id: '$metadata.source', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]);

      console.log('\n📡 Metadata Source Distribution:');
      sourceStats.forEach(stat => {
        console.log(`  ${stat._id}: ${stat.count}`);
      });

      // Check confidence distribution
      const confidenceStats = await Location.aggregate([
        { $group: { _id: '$metadata.confidence', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]);

      console.log('\n🎯 Confidence Distribution:');
      confidenceStats.forEach(stat => {
        console.log(`  ${stat._id}: ${stat.count}`);
      });

      console.log('🎉 Location health check completed successfully!');
      return true;
    } catch (error) {
      console.error('❌ Location database health check failed:', error);
      return false;
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

  // Full database setup
  async setup(options = {}) {
    const {
      createIndexes = true,
      validateSchema = true,
      createSampleData = false,
      runHealthCheck = true
    } = options;

    try {
      console.log('🚀 Starting Location database setup...');

      // Connect to database
      await this.connect();

      // Create indexes
      if (createIndexes) {
        await this.createIndexes();
      }

      // Validate schema
      if (validateSchema) {
        await this.validateSchema();
      }

      // Create sample data
      if (createSampleData) {
        await this.createSampleData();
      }

      // Run health check
      if (runHealthCheck) {
        await this.healthCheck();
      }

      console.log('🎉 Location database setup completed successfully!');
    } catch (error) {
      console.error('❌ Location database setup failed:', error);
      throw error;
    }
  }
}

// CLI interface
if (require.main === module) {
  const args = process.argv.slice(2);
  const options = {};

  // Parse command line arguments
  if (args.includes('--sample-data')) {
    options.createSampleData = true;
  }
  if (args.includes('--no-indexes')) {
    options.createIndexes = false;
  }
  if (args.includes('--no-validation')) {
    options.validateSchema = false;
  }
  if (args.includes('--no-health-check')) {
    options.runHealthCheck = false;
  }

  const locationSetup = new LocationDatabaseSetup();
  
  locationSetup.setup(options)
    .then(() => {
      console.log('✅ Location setup completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Location setup failed:', error);
      process.exit(1);
    });
}

module.exports = LocationDatabaseSetup;