const mongoose = require('mongoose');
const Driver = require('../models/Driver');
require('dotenv').config();

class DriversDatabaseSeeder {
  constructor() {
    this.connection = null;
  }

  // Connect to MongoDB
  async connect() {
    try {
      const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_drivers';
      
      this.connection = await mongoose.connect(mongoUri, {
        useNewUrlParser: true,
        useUnifiedTopology: true,
      });

      console.log('✅ Connected to MongoDB for Drivers seeding');
      console.log(`📊 Database: ${mongoose.connection.name}`);
      return this.connection;
    } catch (error) {
      console.error('❌ MongoDB connection error:', error);
      throw error;
    }
  }

  // Generate random location data
  generateLocationData(city = 'Cape Town', province = 'Western Cape') {
    const locations = {
      'Cape Town': {
        center: { latitude: -33.9249, longitude: 18.4241 },
        addresses: [
          '123 Main Street, Cape Town, South Africa',
          '456 Long Street, Cape Town, South Africa',
          '789 Kloof Street, Cape Town, South Africa',
          '321 V&A Waterfront, Cape Town, South Africa',
          '654 Table Mountain Road, Cape Town, South Africa',
          '987 Camps Bay Drive, Cape Town, South Africa',
          '147 Sea Point Promenade, Cape Town, South Africa',
          '258 Green Point, Cape Town, South Africa',
          '369 Gardens, Cape Town, South Africa',
          '741 Observatory, Cape Town, South Africa'
        ]
      },
      'Johannesburg': {
        center: { latitude: -26.2041, longitude: 28.0473 },
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
      }
    };

    const cityData = locations[city] || locations['Cape Town'];
    const randomAddress = cityData.addresses[Math.floor(Math.random() * cityData.addresses.length)];
    
    // Add some randomness to coordinates
    const randomLat = cityData.center.latitude + (Math.random() - 0.5) * 0.1;
    const randomLng = cityData.center.longitude + (Math.random() - 0.5) * 0.1;

    return {
      coordinates: {
        latitude: randomLat,
        longitude: randomLng
      },
      address: randomAddress,
      lastUpdated: new Date()
    };
  }

  // Generate random vehicle data
  generateVehicleData(vehicleType) {
    const vehicleData = {
      sedan: {
        makes: ['Toyota', 'Honda', 'Nissan', 'Hyundai', 'Kia'],
        models: ['Camry', 'Accord', 'Altima', 'Elantra', 'Optima'],
        colors: ['White', 'Black', 'Silver', 'Gray', 'Blue'],
        capacity: 4,
        features: ['wifi', 'leather_seats', 'tinted_windows', 'premium_sound']
      },
      suv: {
        makes: ['BMW', 'Audi', 'Mercedes-Benz', 'Toyota', 'Honda'],
        models: ['X5', 'Q5', 'GLC', 'RAV4', 'CR-V'],
        colors: ['Black', 'White', 'Silver', 'Gray', 'Blue'],
        capacity: 7,
        features: ['wifi', 'leather_seats', 'tinted_windows', 'premium_sound', 'third_row_seating']
      },
      luxury: {
        makes: ['Mercedes-Benz', 'BMW', 'Audi', 'Lexus', 'Jaguar'],
        models: ['E-Class', '5 Series', 'A6', 'ES', 'XF'],
        colors: ['Black', 'Silver', 'White', 'Gray', 'Blue'],
        capacity: 4,
        features: ['wifi', 'leather_seats', 'tinted_windows', 'premium_sound', 'massage_seats', 'heated_seats']
      },
      van: {
        makes: ['Ford', 'Mercedes-Benz', 'Volkswagen', 'Toyota', 'Nissan'],
        models: ['Transit', 'Sprinter', 'Crafter', 'Hiace', 'NV200'],
        colors: ['White', 'Blue', 'Gray', 'Black', 'Silver'],
        capacity: 12,
        features: ['wifi', 'air_conditioning', 'comfortable_seats', 'storage_space']
      },
      truck: {
        makes: ['Ford', 'Chevrolet', 'GMC', 'Ram', 'Toyota'],
        models: ['F-150', 'Silverado', 'Sierra', '1500', 'Tundra'],
        colors: ['White', 'Black', 'Silver', 'Gray', 'Blue'],
        capacity: 5,
        features: ['wifi', 'leather_seats', 'tinted_windows', 'premium_sound', 'towing_capacity']
      },
      motorcycle: {
        makes: ['Honda', 'Yamaha', 'Kawasaki', 'Suzuki', 'Ducati'],
        models: ['CBR', 'YZF', 'Ninja', 'GSX', 'Monster'],
        colors: ['Red', 'Black', 'White', 'Blue', 'Yellow'],
        capacity: 2,
        features: ['helmet_provided', 'windshield', 'storage_compartment']
      }
    };

    const typeData = vehicleData[vehicleType] || vehicleData.sedan;
    const make = typeData.makes[Math.floor(Math.random() * typeData.makes.length)];
    const model = typeData.models[Math.floor(Math.random() * typeData.models.length)];
    const color = typeData.colors[Math.floor(Math.random() * typeData.colors.length)];
    const year = Math.floor(Math.random() * 5) + 2019; // 2019-2023

    return {
      make: make,
      model: model,
      year: year,
      color: color,
      licensePlate: this.generateLicensePlate(),
      vehicleType: vehicleType,
      passengerCapacity: typeData.capacity,
      hasAC: Math.random() > 0.1, // 90% have AC
      features: typeData.features.slice(0, Math.floor(Math.random() * typeData.features.length) + 1)
    };
  }

  // Generate random license plate
  generateLicensePlate() {
    const provinces = ['CA', 'GP', 'KZN', 'WC', 'FS', 'EC', 'LP', 'MP', 'NW'];
    const province = provinces[Math.floor(Math.random() * provinces.length)];
    const numbers = Math.floor(Math.random() * 9000) + 1000;
    return `${province}${numbers}`;
  }

  // Generate random bank details
  generateBankDetails() {
    const banks = [
      { name: 'Standard Bank', branchCode: '051001' },
      { name: 'FNB', branchCode: '250655' },
      { name: 'Absa', branchCode: '632005' },
      { name: 'Nedbank', branchCode: '198765' },
      { name: 'Capitec', branchCode: '470010' }
    ];

    const bank = banks[Math.floor(Math.random() * banks.length)];
    const accountNumber = Math.floor(Math.random() * 9000000000) + 1000000000;

    return {
      accountHolder: this.generateName(),
      accountNumber: accountNumber.toString(),
      bankName: bank.name,
      branchCode: bank.branchCode
    };
  }

  // Generate random name
  generateName() {
    const firstNames = ['John', 'Jane', 'Mike', 'Sarah', 'David', 'Lisa', 'Robert', 'Mary', 'James', 'Emma', 'William', 'Olivia', 'Michael', 'Sophia', 'Daniel', 'Isabella'];
    const lastNames = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson', 'Thomas'];
    
    const firstName = firstNames[Math.floor(Math.random() * firstNames.length)];
    const lastName = lastNames[Math.floor(Math.random() * lastNames.length)];
    
    return `${firstName} ${lastName}`;
  }

  // Generate random emergency contact
  generateEmergencyContact() {
    const relationships = ['spouse', 'parent', 'sibling', 'friend', 'colleague'];
    const name = this.generateName();
    const phone = '+27' + Math.floor(Math.random() * 900000000 + 100000000);
    const relationship = relationships[Math.floor(Math.random() * relationships.length)];
    
    return {
      name: name,
      phone: phone,
      relationship: relationship
    };
  }

  // Generate random performance data
  generatePerformanceData() {
    const totalRides = Math.floor(Math.random() * 500) + 50; // 50-550 rides
    const completedRides = Math.floor(totalRides * (0.85 + Math.random() * 0.15)); // 85-100% completion rate
    const cancelledRides = totalRides - completedRides;
    const rating = 3.5 + Math.random() * 1.5; // 3.5-5.0 rating
    const totalEarnings = completedRides * (80 + Math.random() * 120); // R80-R200 per ride
    const averageResponseTime = 2 + Math.random() * 8; // 2-10 minutes
    const onTimePickup = 85 + Math.random() * 15; // 85-100%
    const customerSatisfaction = 85 + Math.random() * 15; // 85-100%

    return {
      rating: Math.round(rating * 10) / 10,
      totalRides: totalRides,
      completedRides: completedRides,
      cancelledRides: cancelledRides,
      totalEarnings: Math.round(totalEarnings * 100) / 100,
      averageResponseTime: Math.round(averageResponseTime * 10) / 10,
      onTimePickup: Math.round(onTimePickup * 10) / 10,
      customerSatisfaction: Math.round(customerSatisfaction * 10) / 10
    };
  }

  // Generate random availability data
  generateAvailabilityData() {
    const statuses = ['online', 'offline', 'busy', 'maintenance'];
    const status = statuses[Math.floor(Math.random() * statuses.length)];
    
    const workingHours = {
      start: `${6 + Math.floor(Math.random() * 2)}:${Math.floor(Math.random() * 60).toString().padStart(2, '0')}`,
      end: `${20 + Math.floor(Math.random() * 3)}:${Math.floor(Math.random() * 60).toString().padStart(2, '0')}`
    };

    let availableUntil = null;
    if (status === 'online' || status === 'busy') {
      availableUntil = new Date(Date.now() + Math.random() * 8 * 60 * 60 * 1000); // 0-8 hours from now
    }

    return {
      status: status,
      availableUntil: availableUntil,
      workingHours: workingHours
    };
  }

  // Generate random verification status
  generateVerificationStatus() {
    return {
      backgroundCheck: Math.random() > 0.2, // 80% have background check
      documentsVerified: Math.random() > 0.3, // 70% have documents verified
      vehicleInspected: Math.random() > 0.4 // 60% have vehicle inspected
    };
  }

  // Generate random driver status
  generateDriverStatus() {
    const statuses = ['pending', 'approved', 'rejected', 'suspended', 'active'];
    const weights = [0.1, 0.2, 0.05, 0.05, 0.6]; // 60% active, 20% approved, etc.
    
    const random = Math.random();
    let cumulative = 0;
    
    for (let i = 0; i < statuses.length; i++) {
      cumulative += weights[i];
      if (random <= cumulative) {
        return statuses[i];
      }
    }
    
    return 'active';
  }

  // Generate random documents
  generateDocuments() {
    return {
      licensePhoto: `https://example.com/license_${Math.random().toString(36).substring(2, 8)}.jpg`,
      vehicleRegistration: `https://example.com/registration_${Math.random().toString(36).substring(2, 8)}.pdf`,
      vehicleInsurance: `https://example.com/insurance_${Math.random().toString(36).substring(2, 8)}.pdf`,
      profilePhoto: `https://example.com/profile_${Math.random().toString(36).substring(2, 8)}.jpg`
    };
  }

  // Create sample driver
  async createSampleDriver() {
    const vehicleTypes = ['sedan', 'suv', 'luxury', 'van', 'truck', 'motorcycle'];
    const cities = ['Cape Town', 'Johannesburg', 'Durban'];
    const provinces = ['Western Cape', 'Gauteng', 'KwaZulu-Natal'];

    const vehicleType = vehicleTypes[Math.floor(Math.random() * vehicleTypes.length)];
    const city = cities[Math.floor(Math.random() * cities.length)];
    const province = provinces[Math.floor(Math.random() * provinces.length)];

    const driverId = 'DRV-' + Date.now().toString(36).slice(-4).toUpperCase() + Math.random().toString(36).substring(2, 4).toUpperCase();
    const licenseNumber = 'LIC' + Math.floor(Math.random() * 90000000 + 10000000);
    const licenseExpiry = new Date(Date.now() + Math.random() * 365 * 24 * 60 * 60 * 1000); // Random date within next year

    const driverData = {
      userId: new mongoose.Types.ObjectId(),
      driverId: driverId,
      licenseNumber: licenseNumber,
      licenseExpiry: licenseExpiry,
      vehicleInfo: this.generateVehicleData(vehicleType),
      documents: this.generateDocuments(),
      bankDetails: this.generateBankDetails(),
      currentLocation: this.generateLocationData(city, province),
      availability: this.generateAvailabilityData(),
      performance: this.generatePerformanceData(),
      currentBookingId: Math.random() > 0.8 ? new mongoose.Types.ObjectId() : null,
      status: this.generateDriverStatus(),
      verificationStatus: this.generateVerificationStatus(),
      emergencyContact: this.generateEmergencyContact()
    };

    return new Driver(driverData);
  }

  // Seed database with sample data
  async seedDatabase(options = {}) {
    const {
      numDrivers = 30,
      clearExisting = false
    } = options;

    try {
      console.log(`🌱 Seeding Drivers database with ${numDrivers} drivers...`);

      // Clear existing data if requested
      if (clearExisting) {
        console.log('🗑️ Clearing existing Drivers data...');
        await Driver.deleteMany({});
        console.log('✅ Existing Drivers data cleared');
      }

      // Check if data already exists
      const existingCount = await Driver.countDocuments();
      if (existingCount > 0 && !clearExisting) {
        console.log(`⚠️ Drivers database already contains ${existingCount} drivers`);
        console.log('Use --clear-existing to replace existing data');
        return;
      }

      // Create drivers in batches
      const batchSize = 10;
      const batches = Math.ceil(numDrivers / batchSize);

      for (let batch = 0; batch < batches; batch++) {
        const batchDrivers = [];
        const currentBatchSize = Math.min(batchSize, numDrivers - batch * batchSize);

        for (let i = 0; i < currentBatchSize; i++) {
          const driver = await this.createSampleDriver();
          batchDrivers.push(driver);
        }

        // Save batch
        await Driver.insertMany(batchDrivers);
        console.log(`✅ Created batch ${batch + 1}/${batches} (${currentBatchSize} drivers)`);
      }

      // Generate summary statistics
      const totalDrivers = await Driver.countDocuments();
      const statusStats = await Driver.aggregate([
        { $group: { _id: '$status', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]);

      const vehicleTypeStats = await Driver.aggregate([
        { $group: { _id: '$vehicleInfo.vehicleType', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]);

      const availabilityStats = await Driver.aggregate([
        { $group: { _id: '$availability.status', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]);

      const verificationStats = await Driver.aggregate([
        { $group: { _id: null, backgroundCheck: { $sum: { $cond: ['$verificationStatus.backgroundCheck', 1, 0] } }, documentsVerified: { $sum: { $cond: ['$verificationStatus.documentsVerified', 1, 0] } }, vehicleInspected: { $sum: { $cond: ['$verificationStatus.vehicleInspected', 1, 0] } } } }
      ]);

      console.log('\n📊 Drivers Seeding Summary:');
      console.log(`  Total drivers created: ${totalDrivers}`);

      console.log('\n📈 Status Distribution:');
      statusStats.forEach(stat => {
        console.log(`  ${stat._id}: ${stat.count}`);
      });

      console.log('\n🚗 Vehicle Type Distribution:');
      vehicleTypeStats.forEach(stat => {
        console.log(`  ${stat._id}: ${stat.count}`);
      });

      console.log('\n🟢 Availability Distribution:');
      availabilityStats.forEach(stat => {
        console.log(`  ${stat._id}: ${stat.count}`);
      });

      if (verificationStats.length > 0) {
        console.log('\n✅ Verification Status:');
        console.log(`  Background Check: ${verificationStats[0].backgroundCheck}/${totalDrivers}`);
        console.log(`  Documents Verified: ${verificationStats[0].documentsVerified}/${totalDrivers}`);
        console.log(`  Vehicle Inspected: ${verificationStats[0].vehicleInspected}/${totalDrivers}`);
      }

      // Calculate total earnings
      const earningsStats = await Driver.aggregate([
        { $group: { _id: null, totalEarnings: { $sum: '$performance.totalEarnings' } } }
      ]);

      if (earningsStats.length > 0) {
        console.log(`\n💰 Total Earnings: R${earningsStats[0].totalEarnings.toLocaleString()}`);
      }

      // Calculate average rating
      const ratingStats = await Driver.aggregate([
        { $group: { _id: null, avgRating: { $avg: '$performance.rating' } } }
      ]);

      if (ratingStats.length > 0) {
        console.log(`\n⭐ Average Rating: ${ratingStats[0].avgRating.toFixed(2)}`);
      }

      console.log('🎉 Drivers database seeding completed successfully!');
    } catch (error) {
      console.error('❌ Error seeding Drivers database:', error);
      throw error;
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
  const args = process.argv.slice(2);
  const options = {};

  // Parse command line arguments
  const numDriversIndex = args.indexOf('--num-drivers');
  if (numDriversIndex !== -1 && args[numDriversIndex + 1]) {
    options.numDrivers = parseInt(args[numDriversIndex + 1]);
  }

  if (args.includes('--clear-existing')) {
    options.clearExisting = true;
  }

  const seeder = new DriversDatabaseSeeder();
  
  seeder.connect()
    .then(() => seeder.seedDatabase(options))
    .then(() => {
      console.log('✅ Drivers seeding completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Drivers seeding failed:', error);
      process.exit(1);
    });
}

module.exports = DriversDatabaseSeeder;
