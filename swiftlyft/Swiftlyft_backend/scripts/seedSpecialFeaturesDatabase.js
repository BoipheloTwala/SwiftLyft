const mongoose = require('mongoose');
const {
  Offer,
  CorporateBooking,
  SecurityService,
  AirportService
} = require('../models/SpecialFeatures');
require('dotenv').config();

class SpecialFeaturesDatabaseSeeder {
  constructor(){ this.connection=null; }
  async connect(){
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_special_features';
    this.connection = await mongoose.connect(mongoUri, { useNewUrlParser:true, useUnifiedTopology:true });
    console.log('✅ Connected to MongoDB for SpecialFeatures seeding');
      console.log(`📊 Database: ${mongoose.connection.name}`);
  }

  async seed({ offers=5, corpBookings=2, security=2, airport=2, clearExisting=false }={}){
    try{
      console.log(`🌱 Seeding SpecialFeatures: offers=${offers}, corporate=${corpBookings}, security=${security}, airport=${airport}`);
      if (clearExisting){
        console.log('🗑️ Clearing existing SpecialFeatures data...');
        await Promise.all([
          Offer.deleteMany({}),
          CorporateBooking.deleteMany({}),
          SecurityService.deleteMany({}),
          AirportService.deleteMany({})
        ]);
        console.log('✅ Cleared');
      }

      // Offers
      const now = new Date();
      const offerDocs = [];
      for (let i=0; i<offers; i++){
        offerDocs.push({
          title: `Offer ${i+1}`,
          description: `Special offer ${i+1}`,
          type: i%2===0 ? 'discount_percentage' : 'discount_fixed',
          discountValue: i%2===0 ? 10 + (i%3)*5 : 50,
          conditions: { minBookingAmount: 50, vehicleTypes: ['sedan','suv'] },
          minBookingAmount: 50,
          promoCode: `PROMO${1000+i}`,
          isActive: true,
          startDate: new Date(now.getTime()-86400000),
          endDate: new Date(now.getTime()+14*86400000),
          targetAudience: 'all'
        });
      }
      if (offerDocs.length) await Offer.insertMany(offerDocs);

      // Corporate bookings
      for (let i=0; i<corpBookings; i++){
        await CorporateBooking.create({
          corporateAccountId: new mongoose.Types.ObjectId(),
          userId: new mongoose.Types.ObjectId(),
          title: `Corporate Booking ${i+1}`,
          bookingType: 'business_travel',
          trips: [
            { tripId: `C${i+1}-1`, pickupLocation: { address: 'HQ' }, dropoffLocation: { address: 'Client' }, scheduledDate: new Date(now.getTime()+2*3600000), passengerCount: 2, status: 'pending', actualCost: 250 },
            { tripId: `C${i+1}-2`, pickupLocation: { address: 'Client' }, dropoffLocation: { address: 'HQ' }, scheduledDate: new Date(now.getTime()+5*3600000), passengerCount: 2, status: 'pending', actualCost: 260 }
          ],
          totalEstimatedCost: 600,
          discountApplied: 50
        });
      }

      // Security services
      const secTypes = ['close_protection','security_escort','asset_transport','event_security'];
      const levels = ['standard','enhanced','premium'];
      for (let i=0; i<security; i++){
        await SecurityService.create({
          bookingId: new mongoose.Types.ObjectId(),
          userId: new mongoose.Types.ObjectId(),
          serviceType: secTypes[i % secTypes.length],
          protectionLevel: levels[i % levels.length],
          duration: 2 + (i%4),
          personnelCount: 2 + (i%3)
        });
      }

      // Airport services
      const airTypes = ['pickup','dropoff','meet_and_greet','vip_service','group_transport'];
      for (let i=0; i<airport; i++){
        await AirportService.create({
          bookingId: new mongoose.Types.ObjectId(),
          userId: new mongoose.Types.ObjectId(),
          serviceType: airTypes[i % airTypes.length],
          flightDetails: { airline: 'SAA', flightNumber: `SA${100+i}`, scheduledTime: new Date(now.getTime()+ (2+i)*3600000) },
          passengerDetails: { count: 1 + (i%4) }
        });
      }

      const counts = await Promise.all([
        Offer.countDocuments(), CorporateBooking.countDocuments(), SecurityService.countDocuments(), AirportService.countDocuments()
      ]);
      console.log(`🎉 Seeding complete. Offers=${counts[0]} Corporate=${counts[1]} Security=${counts[2]} Airport=${counts[3]}`);
    }catch(e){
      console.error('❌ SpecialFeatures seeding failed:', e);
      throw e;
    }
  }
}

if (require.main === module){
  const args = process.argv.slice(2);
  const opts = {};
  const oIdx = args.indexOf('--offers'); if (oIdx!==-1) opts.offers = parseInt(args[oIdx+1]);
  const cIdx = args.indexOf('--corporate'); if (cIdx!==-1) opts.corpBookings = parseInt(args[cIdx+1]);
  const sIdx = args.indexOf('--security'); if (sIdx!==-1) opts.security = parseInt(args[sIdx+1]);
  const aIdx = args.indexOf('--airport'); if (aIdx!==-1) opts.airport = parseInt(args[aIdx+1]);
  if (args.includes('--clear-existing')) opts.clearExisting = true;

  const seeder = new SpecialFeaturesDatabaseSeeder();
  seeder.connect()
    .then(()=>seeder.seed(opts))
    .then(()=>{ console.log('✅ SpecialFeatures seeding completed successfully'); process.exit(0); })
    .catch((e)=>{ console.error('❌ SpecialFeatures seeding failed:', e); process.exit(1); });
}

module.exports = SpecialFeaturesDatabaseSeeder;
