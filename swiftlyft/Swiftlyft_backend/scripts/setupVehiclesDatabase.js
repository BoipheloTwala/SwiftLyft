const mongoose = require('mongoose');
require('dotenv').config();

const Vehicle = require('../models/Vehicle');

class VehiclesDatabaseSetup {
  constructor(){ this.connection = null; }

  async connect(){
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_vehicles';
    this.connection = await mongoose.connect(mongoUri, { useNewUrlParser:true, useUnifiedTopology:true });
    console.log('✅ Connected to MongoDB for Vehicles');
      console.log(`📊 Database: ${mongoose.connection.name}`);
  }

  async safeCreateIndex(collection, key, options = {}){
    try {
      await collection.createIndex(key, { background:true, ...options });
    } catch (error) {
      if (error && (error.code === 85 || error.code === 86)) {
        console.log(`ℹ️  Index exists/conflicts, skipping: ${JSON.stringify(key)}`);
      } else {
        // Some environments may fail 2dsphere on non-GeoJSON; skip gracefully
        if (options.ignoreErrors) {
          console.log(`ℹ️  Ignoring index error for ${JSON.stringify(key)}: ${error.message}`);
        } else {
          throw error;
        }
      }
    }
  }

  async createIndexes(){
    console.log('🔍 Creating Vehicles indexes...');
    await this.safeCreateIndex(Vehicle.collection, { vehicleId: 1 });
    await this.safeCreateIndex(Vehicle.collection, { driverId: 1 });
    await this.safeCreateIndex(Vehicle.collection, { status: 1 });
    await this.safeCreateIndex(Vehicle.collection, { category: 1 });
    await this.safeCreateIndex(Vehicle.collection, { licensePlate: 1 });
    await this.safeCreateIndex(Vehicle.collection, { vin: 1 });
    // The schema defines a 2dsphere index on a non-GeoJSON field; best-effort attempt, ignore errors
    await this.safeCreateIndex(Vehicle.collection, { 'currentLocation.coordinates': '2dsphere' }, { ignoreErrors: true });
    console.log('✅ Vehicle indexes ensured');
  }

  async validateSchema(){
    console.log('🔍 Validating Vehicle schema...');
    const sample = new Vehicle({
      id: `VH${Date.now().toString(36).slice(-4).toUpperCase()}`,
      vehicleId: `VH${Date.now().toString(36).slice(-4).toUpperCase()}${Math.random().toString(36).substring(2,4).toUpperCase()}`,
      driverId: new mongoose.Types.ObjectId(),
      name: 'Test Sedan',
      description: 'Comfortable sedan',
      make: 'Toyota',
      model: 'Corolla',
      year: 2022,
      color: 'White',
      licensePlate: `TEST${Math.random().toString(36).substring(2,6).toUpperCase()}`,
      category: 'sedan',
      seatingCapacity: 4,
      passengerCapacity: 4,
      basePrice: 100,
      pricing: { baseFare: 100, perKmRate: 12, perMinuteRate: 1, minimumFare: 80, currency: 'ZAR' },
      currentLocation: { address: 'CBD', coordinates: { latitude: -26.2041, longitude: 28.0473 }, city: 'Johannesburg', province: 'Gauteng' },
      availability: { isAvailable: true }
    });
    await sample.validate();
    sample.fullName; sample.displayName; sample.isCurrentlyAvailable; sample.age;
    console.log('✅ Vehicle schema validation passed');
  }

  async createSampleData(){
    console.log('🌱 Creating sample vehicles...');
    const count = await Vehicle.countDocuments();
    if (count > 0) {
      console.log('ℹ️ Vehicles already exist, skipping seeding');
      return;
    }
    const categories = ['sedan','suv','luxury','van'];
    const colors = ['Black','White','Silver','Blue'];
    const makes = [ ['Toyota','Corolla'], ['Volkswagen','Polo'], ['BMW','X5'], ['Mercedes','C200'] ];
    const docs = [];
    for (let i=0;i<8;i++){
      const [make, model] = makes[i % makes.length];
      const cat = categories[i % categories.length];
      const color = colors[i % colors.length];
      const idSuffix = `${Date.now().toString(36).slice(-4)}${Math.random().toString(36).substring(2,4)}`.toUpperCase();
      docs.push({
        id: `VH${idSuffix}`,
        vehicleId: `VH${idSuffix}`,
        driverId: new mongoose.Types.ObjectId(),
        name: `${make} ${model}`,
        description: `${color} ${make} ${model}`,
        make, model,
        year: 2020 + (i % 4),
        color,
        licensePlate: `REG-${idSuffix}`,
        category: cat,
        seatingCapacity: cat === 'van' ? 8 : (cat === 'suv' ? 5 : 4),
        passengerCapacity: cat === 'van' ? 8 : (cat === 'suv' ? 5 : 4),
        basePrice: 120 + (i*5),
        pricing: { baseFare: 120 + (i*5), perKmRate: 10 + (i%3), perMinuteRate: 1, minimumFare: 100, currency: 'ZAR' },
        features: ['airConditioning','bluetooth'],
        currentLocation: { address: 'CBD', coordinates: { latitude: -26.20 + i*0.01, longitude: 28.04 + i*0.01 }, city: 'Johannesburg', province: 'Gauteng' },
        availability: { isAvailable: i % 2 === 0 }
      });
    }
    await Vehicle.insertMany(docs);
    console.log(`✅ Inserted ${docs.length} vehicles`);
  }

  async healthCheck(){
    const stats = await this.connection.connection.db.stats();
    console.log(`📊 Collections: ${stats.collections}, Objects: ${stats.objects || 0}`);
    const total = await Vehicle.countDocuments();
    const available = await Vehicle.countDocuments({ status: 'available' });
    console.log(`📊 Vehicles total=${total} availableStatus=${available}`);
  }

  async setup(options={}){
    const { createIndexes=true, validateSchema=true, createSampleData=false, runHealthCheck=true } = options;
    console.log('🚀 Starting Vehicles database setup...');
    await this.connect();
    if (createIndexes) await this.createIndexes();
    if (validateSchema) await this.validateSchema();
    if (createSampleData) await this.createSampleData();
    if (runHealthCheck) await this.healthCheck();
    console.log('🎉 Vehicles database setup completed successfully!');
  }
}

if (require.main === module){
  const args = process.argv.slice(2);
  const options = {};
  if (args.includes('--sample-data')) options.createSampleData = true;
  if (args.includes('--no-indexes')) options.createIndexes = false;
  if (args.includes('--no-validation')) options.validateSchema = false;
  if (args.includes('--no-health-check')) options.runHealthCheck = false;

  new VehiclesDatabaseSetup().setup(options)
    .then(()=>{ console.log('✅ Vehicles setup completed successfully'); process.exit(0); })
    .catch((e)=>{ console.error('❌ Vehicles setup failed:', e); process.exit(1); });
}

module.exports = VehiclesDatabaseSetup;
