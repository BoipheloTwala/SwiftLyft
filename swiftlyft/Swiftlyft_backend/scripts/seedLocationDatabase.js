const mongoose = require('mongoose');
const Location = require('../models/Location');
require('dotenv').config();

class LocationDatabaseSeeder {
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

      console.log('✅ Connected to MongoDB for Location seeding');
      console.log(`📊 Database: ${mongoose.connection.name}`);
      return this.connection;
    } catch (error) {
      console.error('❌ MongoDB connection error:', error);
      throw error;
    }
  }

  // Generate random location data
  generateLocationData(city = 'Cape Town', type = 'other', category = 'other') {
    const cities = {
      'Cape Town': {
        center: { latitude: -33.9249, longitude: 18.4241 },
        bounds: { north: -33.7, south: -34.0, east: 18.6, west: 18.3 },
        addresses: [
          '123 Long Street, Cape Town, South Africa',
          '456 Kloof Street, Cape Town, South Africa',
          '789 V&A Waterfront, Cape Town, South Africa',
          '321 Camps Bay Drive, Cape Town, South Africa',
          '654 Sea Point Promenade, Cape Town, South Africa',
          '987 Green Point, Cape Town, South Africa',
          '147 Gardens, Cape Town, South Africa',
          '258 Observatory, Cape Town, South Africa',
          '369 Woodstock, Cape Town, South Africa',
          '741 Rondebosch, Cape Town, South Africa'
        ]
      },
      'Johannesburg': {
        center: { latitude: -26.2041, longitude: 28.0473 },
        bounds: { north: -26.0, south: -26.3, east: 28.2, west: 27.8 },
        addresses: [
          '123 Sandton City, Johannesburg, South Africa',
          '456 Rosebank, Johannesburg, South Africa',
          '789 Melrose Arch, Johannesburg, South Africa',
          '321 Fourways, Johannesburg, South Africa',
          '654 Randburg, Johannesburg, South Africa',
          '987 Midrand, Johannesburg, South Africa',
          '147 Centurion, Johannesburg, South Africa',
          '258 Pretoria, Johannesburg, South Africa',
          '369 Bryanston, Johannesburg, South Africa',
          '741 Rivonia, Johannesburg, South Africa'
        ]
      },
      'Durban': {
        center: { latitude: -29.8587, longitude: 31.0218 },
        bounds: { north: -29.7, south: -30.0, east: 31.1, west: 30.8 },
        addresses: [
          '123 uShaka Marine World, Durban, South Africa',
          '456 Gateway Theatre, Durban, South Africa',
          '789 Pavilion Shopping Centre, Durban, South Africa',
          '321 Umhlanga Rocks, Durban, South Africa',
          '654 Ballito, Durban, South Africa',
          '987 Amanzimtoti, Durban, South Africa',
          '147 Westville, Durban, South Africa',
          '258 Pinetown, Durban, South Africa',
          '369 Hillcrest, Durban, South Africa',
          '741 Kloof, Durban, South Africa'
        ]
      },
      'Pretoria': {
        center: { latitude: -25.7479, longitude: 28.2293 },
        bounds: { north: -25.6, south: -25.8, east: 28.3, west: 28.0 },
        addresses: [
          '123 Church Square, Pretoria, South Africa',
          '456 Hatfield, Pretoria, South Africa',
          '789 Menlyn, Pretoria, South Africa',
          '321 Brooklyn, Pretoria, South Africa',
          '654 Sunnyside, Pretoria, South Africa',
          '987 Arcadia, Pretoria, South Africa',
          '147 Waterkloof, Pretoria, South Africa',
          '258 Groenkloof, Pretoria, South Africa',
          '369 Muckleneuk, Pretoria, South Africa',
          '741 Colbyn, Pretoria, South Africa'
        ]
      }
    };

    const cityData = cities[city] || cities['Cape Town'];
    const randomAddress = cityData.addresses[Math.floor(Math.random() * cityData.addresses.length)];
    
    // Add some randomness to coordinates
    const randomLat = cityData.center.latitude + (Math.random() - 0.5) * 0.1;
    const randomLng = cityData.center.longitude + (Math.random() - 0.5) * 0.1;

    return {
      latitude: randomLat,
      longitude: randomLng,
      coordinates: {
        lat: randomLat,
        lng: randomLng
      },
      address: {
        formatted: randomAddress,
        streetNumber: Math.floor(Math.random() * 999) + 1,
        streetName: randomAddress.split(',')[0].split(' ').slice(1).join(' '),
        suburb: randomAddress.split(',')[1]?.trim() || city,
        city: city,
        state: this.getStateForCity(city),
        country: 'South Africa',
        countryCode: 'ZA',
        postcode: Math.floor(Math.random() * 9000) + 1000
      },
      accuracy: Math.random() * 10 + 1,
      altitude: Math.random() * 1000 + 100,
      heading: Math.random() * 360,
      speed: Math.random() * 60,
      serviceArea: {
        name: city,
        city: city,
        isInServiceArea: true,
        center: cityData.center,
        radius: 50.0
      },
      type: type,
      category: category,
      timestamp: new Date(),
      lastUpdated: new Date(),
      metadata: {
        source: this.getRandomSource(),
        confidence: this.getRandomConfidence(),
        notes: `Generated ${type} location in ${city}`,
        tags: [type, category, city.toLowerCase().replace(' ', '_')]
      },
      isActive: true
    };
  }

  // Get state for city
  getStateForCity(city) {
    const states = {
      'Cape Town': 'Western Cape',
      'Johannesburg': 'Gauteng',
      'Durban': 'KwaZulu-Natal',
      'Pretoria': 'Gauteng'
    };
    return states[city] || 'Unknown';
  }

  // Get random source
  getRandomSource() {
    const sources = ['gps', 'manual', 'geocoded', 'reverse_geocoded'];
    return sources[Math.floor(Math.random() * sources.length)];
  }

  // Get random confidence
  getRandomConfidence() {
    const confidences = ['high', 'medium', 'low'];
    return confidences[Math.floor(Math.random() * confidences.length)];
  }

  // Generate random address components
  generateAddressComponents(city) {
    const streetNames = ['Main', 'First', 'Second', 'Oak', 'Pine', 'Maple', 'Cedar', 'Elm', 'Park', 'Church'];
    const streetTypes = ['Street', 'Road', 'Avenue', 'Drive', 'Lane', 'Court', 'Place', 'Way'];
    const suburbs = ['Central', 'North', 'South', 'East', 'West', 'Downtown', 'Uptown', 'Midtown'];

    const streetName = streetNames[Math.floor(Math.random() * streetNames.length)];
    const streetType = streetTypes[Math.floor(Math.random() * streetTypes.length)];
    const suburb = suburbs[Math.floor(Math.random() * suburbs.length)];

    return {
      streetName: `${streetName} ${streetType}`,
      suburb: `${suburb} ${city}`,
      streetNumber: Math.floor(Math.random() * 999) + 1
    };
  }

  // Generate random location type
  generateLocationType() {
    const types = ['pickup', 'dropoff', 'waypoint', 'driver', 'landmark', 'other'];
    return types[Math.floor(Math.random() * types.length)];
  }

  // Generate random category
  generateCategory() {
    const categories = ['residential', 'commercial', 'airport', 'station', 'hospital', 'school', 'other'];
    return categories[Math.floor(Math.random() * categories.length)];
  }

  // Generate random city
  generateCity() {
    const cities = ['Cape Town', 'Johannesburg', 'Durban', 'Pretoria'];
    return cities[Math.floor(Math.random() * cities.length)];
  }

  // Create sample location
  async createSampleLocation() {
    const city = this.generateCity();
    const type = this.generateLocationType();
    const category = this.generateCategory();

    const locationData = {
      ...this.generateLocationData(city, type, category),
      userId: Math.random() > 0.5 ? new mongoose.Types.ObjectId() : null,
      driverId: Math.random() > 0.7 ? new mongoose.Types.ObjectId() : null,
      bookingId: Math.random() > 0.8 ? new mongoose.Types.ObjectId() : null
    };

    return new Location(locationData);
  }

  // Seed database with sample data
  async seedDatabase(options = {}) {
    const {
      numLocations = 50,
      clearExisting = false
    } = options;

    try {
      console.log(`🌱 Seeding Location database with ${numLocations} locations...`);

      // Clear existing data if requested
      if (clearExisting) {
        console.log('🗑️ Clearing existing Location data...');
        await Location.deleteMany({});
        console.log('✅ Existing Location data cleared');
      }

      // Check if data already exists
      const existingCount = await Location.countDocuments();
      if (existingCount > 0 && !clearExisting) {
        console.log(`⚠️ Location database already contains ${existingCount} locations`);
        console.log('Use --clear-existing to replace existing data');
        return;
      }

      // Create locations in batches
      const batchSize = 10;
      const batches = Math.ceil(numLocations / batchSize);

      for (let batch = 0; batch < batches; batch++) {
        const batchLocations = [];
        const currentBatchSize = Math.min(batchSize, numLocations - batch * batchSize);

        for (let i = 0; i < currentBatchSize; i++) {
          const location = await this.createSampleLocation();
          batchLocations.push(location);
        }

        // Save batch
        await Location.insertMany(batchLocations);
        console.log(`✅ Created batch ${batch + 1}/${batches} (${currentBatchSize} locations)`);
      }

      // Generate summary statistics
      const totalLocations = await Location.countDocuments();
      const typeStats = await Location.aggregate([
        { $group: { _id: '$type', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]);

      const categoryStats = await Location.aggregate([
        { $group: { _id: '$category', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]);

      const serviceAreaStats = await Location.aggregate([
        { $group: { _id: '$serviceArea.name', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]);

      const sourceStats = await Location.aggregate([
        { $group: { _id: '$metadata.source', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]);

      const confidenceStats = await Location.aggregate([
        { $group: { _id: '$metadata.confidence', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]);

      console.log('\n📊 Location Seeding Summary:');
      console.log(`  Total locations created: ${totalLocations}`);

      console.log('\n📍 Type Distribution:');
      typeStats.forEach(stat => {
        console.log(`  ${stat._id}: ${stat.count}`);
      });

      console.log('\n🏢 Category Distribution:');
      categoryStats.forEach(stat => {
        console.log(`  ${stat._id}: ${stat.count}`);
      });

      console.log('\n🌍 Service Area Distribution:');
      serviceAreaStats.forEach(stat => {
        console.log(`  ${stat._id}: ${stat.count}`);
      });

      console.log('\n📡 Source Distribution:');
      sourceStats.forEach(stat => {
        console.log(`  ${stat._id}: ${stat.count}`);
      });

      console.log('\n🎯 Confidence Distribution:');
      confidenceStats.forEach(stat => {
        console.log(`  ${stat._id}: ${stat.count}`);
      });

      // Calculate average accuracy
      const accuracyStats = await Location.aggregate([
        { $group: { _id: null, avgAccuracy: { $avg: '$accuracy' } } }
      ]);

      if (accuracyStats.length > 0) {
        console.log(`\n🎯 Average Accuracy: ${accuracyStats[0].avgAccuracy.toFixed(2)} meters`);
      }

      // Calculate average altitude
      const altitudeStats = await Location.aggregate([
        { $group: { _id: null, avgAltitude: { $avg: '$altitude' } } }
      ]);

      if (altitudeStats.length > 0) {
        console.log(`\n⛰️ Average Altitude: ${altitudeStats[0].avgAltitude.toFixed(2)} meters`);
      }

      console.log('🎉 Location database seeding completed successfully!');
    } catch (error) {
      console.error('❌ Error seeding Location database:', error);
      throw error;
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
  const args = process.argv.slice(2);
  const options = {};

  // Parse command line arguments
  const numLocationsIndex = args.indexOf('--num-locations');
  if (numLocationsIndex !== -1 && args[numLocationsIndex + 1]) {
    options.numLocations = parseInt(args[numLocationsIndex + 1]);
  }

  if (args.includes('--clear-existing')) {
    options.clearExisting = true;
  }

  const seeder = new LocationDatabaseSeeder();
  
  seeder.connect()
    .then(() => seeder.seedDatabase(options))
    .then(() => {
      console.log('✅ Location seeding completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Location seeding failed:', error);
      process.exit(1);
    });
}

module.exports = LocationDatabaseSeeder;
