const mongoose = require('mongoose');
const Quote = require('../models/Quote');
require('dotenv').config();

class QuotesDatabaseSeeder {
  constructor(){ this.connection=null; }
  async connect(){
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_quotes';
    this.connection = await mongoose.connect(mongoUri, { useNewUrlParser:true, useUnifiedTopology:true });
    console.log('✅ Connected to MongoDB for Quotes seeding');
      console.log(`📊 Database: ${mongoose.connection.name}`);
  }

  generateQuote(i, userId){
    const vehicleTypes = ['sedan','suv','luxury','van','truck','motorcycle'];
    const serviceTypes = ['standard','premium','corporate','airport','security'];
    const vt = vehicleTypes[i % vehicleTypes.length];
    const st = serviceTypes[i % serviceTypes.length];
    const pax = 1 + (i % 5);
    const dist = Math.round((5 + Math.random() * 40) * 100) / 100;
    const dur = Math.round(dist * (1.8 + Math.random() * 0.6));
    const price = Quote.calculatePricing(dist, dur, vt, st, pax);

    const pickup = { address: `Pickup ${i+1}`, coordinates: { latitude: -33.92 + Math.random()*0.1, longitude: 18.42 + Math.random()*0.1 } };
    const dropoff = { address: `Dropoff ${i+1}`, coordinates: { latitude: -33.95 + Math.random()*0.1, longitude: 18.37 + Math.random()*0.1 } };

    return {
      userId,
      pickupLocation: pickup,
      dropoffLocation: dropoff,
      vehicleType: vt,
      serviceType: st,
      passengerCount: pax,
      luggageCount: i % 3,
      scheduledDate: new Date(Date.now() + (i+2) * 60 * 60 * 1000),
      isFlexibleTime: i % 2 === 0,
      estimatedDistance: dist,
      estimatedDuration: dur,
      estimatedPrice: price,
      status: i % 5 === 0 ? 'quoted' : 'pending',
      validUntil: new Date(Date.now() + 24 * 60 * 60 * 1000),
      createdAt: new Date(Date.now() - i * 3600 * 1000),
      updatedAt: new Date(Date.now() - i * 3600 * 1000)
    };
  }

  async seed({ users=3, quotesPerUser=8, clearExisting=false }={}){
    try{
      console.log(`🌱 Seeding Quotes: users=${users}, quotes/user=${quotesPerUser}`);
      if (clearExisting){
        console.log('🗑️ Clearing existing Quotes...');
        await Quote.deleteMany({});
        console.log('✅ Cleared');
      }

      const existing = await Quote.countDocuments();
      if (existing>0 && !clearExisting){
        console.log(`⚠️ ${existing} quotes already exist; use --clear-existing to replace`);
        return;
      }

      for (let u=0; u<users; u++){
        const userId = new mongoose.Types.ObjectId();
        const docs = [];
        for (let i=0; i<quotesPerUser; i++) docs.push(this.generateQuote(u*quotesPerUser+i, userId));
        await Quote.insertMany(docs);
        console.log(`✅ Seeded user ${u+1}/${users}: quotes=${docs.length}`);
      }

      const total = await Quote.countDocuments();
      console.log(`🎉 Seeding complete. Quotes=${total}`);
    }catch(e){
      console.error('❌ Quotes seeding failed:', e);
      throw e;
    }
  }
}

if (require.main === module){
  const args = process.argv.slice(2);
  const opts = {};
  const uIdx = args.indexOf('--users'); if (uIdx!==-1) opts.users = parseInt(args[uIdx+1]);
  const qIdx = args.indexOf('--quotes'); if (qIdx!==-1) opts.quotesPerUser = parseInt(args[qIdx+1]);
  if (args.includes('--clear-existing')) opts.clearExisting = true;

  const seeder = new QuotesDatabaseSeeder();
  seeder.connect()
    .then(()=>seeder.seed(opts))
    .then(()=>{ console.log('✅ Quotes seeding completed successfully'); process.exit(0); })
    .catch((e)=>{ console.error('❌ Quotes seeding failed:', e); process.exit(1); });
}

module.exports = QuotesDatabaseSeeder;
