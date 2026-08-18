const mongoose = require('mongoose');
require('dotenv').config();

const Vehicle = require('../models/Vehicle');

// Vehicle data organized by category
const vehiclesByCategory = {
  sedan: [
    { make: 'Mercedes-Benz', model: 'E-Class', color: 'Black', year: 2024, basePrice: 280 },
    { make: 'BMW', model: '7 Series', color: 'White', year: 2024, basePrice: 320 },
    { make: 'Audi', model: 'A6', color: 'Silver', year: 2024, basePrice: 290 },
    { make: 'Lexus', model: 'LS 500', color: 'Grey', year: 2024, basePrice: 310 },
    { make: 'Jaguar', model: 'XF', color: 'Blue', year: 2023, basePrice: 275 },
  ],
  suv: [
    { make: 'Toyota', model: 'RAV4', color: 'Grey', year: 2024, basePrice: 180 },
    { make: 'Honda', model: 'CR-V', color: 'White', year: 2023, basePrice: 175 },
    { make: 'Nissan', model: 'X-Trail', color: 'Black', year: 2024, basePrice: 185 },
  ],
  luxury: [
    { make: 'BMW', model: '3 Series', color: 'Black', year: 2024, basePrice: 250 },
    { make: 'Mercedes-Benz', model: 'C-Class', color: 'White', year: 2024, basePrice: 270 },
    { make: 'Audi', model: 'A4', color: 'Grey', year: 2023, basePrice: 260 },
    { make: 'BMW', model: '5 Series', color: 'Blue', year: 2024, basePrice: 300 },
  ],
  van: [
    { make: 'Mercedes-Benz', model: 'Sprinter', color: 'White', year: 2023, basePrice: 220 },
    { make: 'Toyota', model: 'Quantum', color: 'Silver', year: 2023, basePrice: 200 },
  ],
  hybrid: [
    { make: 'Tesla', model: 'Model 3', color: 'White', year: 2024, basePrice: 280 },
    { make: 'Tesla', model: 'Model Y', color: 'Black', year: 2024, basePrice: 320 },
    { make: 'Toyota', model: 'Prius', color: 'Silver', year: 2023, basePrice: 160 },
  ],
};

async function resetVehicles() {
  try {
    // Connect to MongoDB
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_vehicles';
    await mongoose.connect(mongoUri);
    console.log('✅ Connected to MongoDB');

    // Delete all existing vehicles
    const deleteResult = await Vehicle.deleteMany({});
    console.log(`🗑️  Deleted ${deleteResult.deletedCount} existing vehicles`);

    // Drop the id index if it exists (it causes issues with insertMany)
    try {
      await Vehicle.collection.dropIndex('id_1');
      console.log('🔧 Dropped id_1 index');
    } catch (error) {
      if (error.code !== 27) { // 27 = IndexNotFound
        console.log(`ℹ️  id_1 index doesn't exist or couldn't be dropped: ${error.message}`);
      }
    }

    // Create new vehicles
    const vehicleDocs = [];
    let vehicleIndex = 0;

    for (const [category, vehicles] of Object.entries(vehiclesByCategory)) {
      console.log(`\n📦 Creating ${category} vehicles...`);
      
      for (const vehicleData of vehicles) {
        vehicleIndex++;
        const idSuffix = `${Date.now().toString(36).slice(-4)}${Math.random().toString(36).substring(2, 6)}`.toUpperCase();
        
        const vehicle = {
          vehicleId: `VH${idSuffix}`,
          driverId: new mongoose.Types.ObjectId(),
          name: `${vehicleData.make} ${vehicleData.model}`,
          description: `${vehicleData.color} ${vehicleData.make} ${vehicleData.model}`,
          make: vehicleData.make,
          model: vehicleData.model,
          year: vehicleData.year,
          color: vehicleData.color,
          licensePlate: `GP-${idSuffix.substring(0, 6)}`,
          vin: `VIN${idSuffix}${Math.random().toString(36).substring(2, 10).toUpperCase()}`,
          category: category,
          seatingCapacity: category === 'van' ? 14 : (category === 'suv' ? 7 : 5),
          passengerCapacity: category === 'van' ? 14 : (category === 'suv' ? 7 : 5),
          luggageCapacity: category === 'van' ? 10 : (category === 'suv' ? 5 : 3),
          basePrice: vehicleData.basePrice,
          pricing: {
            baseFare: vehicleData.basePrice,
            perKmRate: Math.round(vehicleData.basePrice * 0.1),
            perMinuteRate: Math.round(vehicleData.basePrice * 0.02),
            minimumFare: Math.round(vehicleData.basePrice * 0.8),
            currency: 'ZAR',
          },
          currentLocation: {
            address: 'Sandton City, Johannesburg',
            coordinates: {
              latitude: -26.2041 + (Math.random() - 0.5) * 0.02, // Within 2km of search center
              longitude: 28.0473 + (Math.random() - 0.5) * 0.02,
            },
            city: 'Johannesburg',
            province: 'Gauteng',
            country: 'South Africa',
          },
          status: 'available',
          availability: {
            isAvailable: true,
            workingHours: {},
            operatingDays: [],
          },
          features: [
            'airConditioning',
            'bluetooth',
            ...(category === 'luxury' || category === 'hybrid' ? ['wifi', 'leatherSeats', 'sunroof'] : []),
            ...(category === 'van' ? ['wifi', 'charger'] : []),
          ],
          images: [],
          imageUrl: '',
          imageGallery: [],
        };

        vehicleDocs.push(vehicle);
        console.log(`  ✓ ${vehicle.name} (${category}) - R${vehicle.basePrice}/day`);
      }
    }

    // Insert all vehicles
    const createdVehicles = await Vehicle.insertMany(vehicleDocs);
    console.log(`\n✅ Successfully created ${createdVehicles.length} vehicles`);

    // Summary
    console.log('\n📊 Summary by category:');
    const summary = await Vehicle.aggregate([
      { $group: { _id: '$category', count: { $sum: 1 } } },
      { $sort: { _id: 1 } },
    ]);
    summary.forEach(item => {
      console.log(`  ${item._id}: ${item.count} vehicles`);
    });

    console.log('\n🎉 Vehicle database reset complete!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error resetting vehicles:', error);
    process.exit(1);
  }
}

// Run the script
resetVehicles();

