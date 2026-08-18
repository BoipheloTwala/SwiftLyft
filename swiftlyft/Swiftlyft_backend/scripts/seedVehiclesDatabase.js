const mongoose = require('mongoose');
const Vehicle = require('../models/Vehicle');
require('dotenv').config();

class VehiclesDatabaseSeeder {
  constructor(){ this.connection=null; }
  async connect(){
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_vehicles';
    this.connection = await mongoose.connect(mongoUri, { useNewUrlParser:true, useUnifiedTopology:true });
    console.log('✅ Connected to MongoDB for Vehicles seeding');
      console.log(`📊 Database: ${mongoose.connection.name}`);
  }

  randomCoord(base, i){ return Math.round((base + (Math.random()*0.02 - 0.01) + i*0.005) * 100000) / 100000; }

  async seed({ count=12, clearExisting=false }={}){
    try{
      if (clearExisting){
        console.log('🗑️ Clearing existing vehicles...');
        await Vehicle.deleteMany({});
      }

      const categories = ['sedan','suv','luxury','van','hybrid','electric'];
      const makes = [ ['Toyota','Corolla'], ['VW','Tiguan'], ['BMW','3 Series'], ['Mercedes','Vito'], ['Tesla','Model 3'], ['Toyota','Prius'] ];
      const colors = ['Black','White','Silver','Blue','Grey'];

      const docs = [];
      for (let i=0;i<count;i++){
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
          year: 2019 + (i % 6),
          color,
          licensePlate: `REG-${idSuffix}`,
          category: cat,
          seatingCapacity: cat === 'van' ? 8 : (cat === 'suv' ? 5 : 4),
          passengerCapacity: cat === 'van' ? 8 : (cat === 'suv' ? 5 : 4),
          basePrice: 120 + (i*7),
          pricing: { baseFare: 120 + (i*7), perKmRate: 9 + (i%4), perMinuteRate: 1, minimumFare: 100, currency: 'ZAR' },
          features: ['airConditioning','bluetooth', ...(i%3===0?['wifi']:[])],
          currentLocation: { address: 'CBD', coordinates: { latitude: this.randomCoord(-26.2,i), longitude: this.randomCoord(28.04,i) }, city: 'Johannesburg', province: 'Gauteng' },
          availability: { isAvailable: i % 2 === 0 },
          status: i % 2 === 0 ? 'available' : 'offline'
        });
      }

      if (docs.length) await Vehicle.insertMany(docs, { ordered:false });
      const total = await Vehicle.countDocuments();
      console.log(`🎉 Seeded vehicles. Total now: ${total}`);
    }catch(e){
      console.error('❌ Vehicles seeding failed:', e);
      throw e;
    }
  }
}

if (require.main === module){
  const args = process.argv.slice(2);
  const opts = {};
  const cIdx = args.indexOf('--count'); if (cIdx!==-1) opts.count = parseInt(args[cIdx+1]);
  if (args.includes('--clear-existing')) opts.clearExisting = true;

  const seeder = new VehiclesDatabaseSeeder();
  seeder.connect()
    .then(()=>seeder.seed(opts))
    .then(()=>{ console.log('✅ Vehicles seeding completed successfully'); process.exit(0); })
    .catch((e)=>{ console.error('❌ Vehicles seeding failed:', e); process.exit(1); });
}

module.exports = VehiclesDatabaseSeeder;
