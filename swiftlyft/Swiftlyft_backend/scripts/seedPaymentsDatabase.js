const mongoose = require('mongoose');
const { PaymentMethod, Payment } = require('../models/Payment');
require('dotenv').config();

class PaymentsDatabaseSeeder {
  constructor(){ this.connection=null; }
  async connect(){
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_payments';
    this.connection = await mongoose.connect(mongoUri, { useNewUrlParser: true, useUnifiedTopology: true });
    console.log('✅ Connected to MongoDB for Payments seeding');
      console.log(`📊 Database: ${mongoose.connection.name}`);
  }

  generatePaymentMethod(userId, i){
    const types = ['credit_card','debit_card','digital_wallet','bank_transfer','cash'];
    const providerMap = {
      credit_card: ['visa','mastercard','amex'],
      debit_card: ['visa','mastercard'],
      digital_wallet: ['paypal','apple_pay','google_pay'],
      bank_transfer: ['eft'],
      cash: ['cash']
    };
    const type = types[i % types.length];
    const providerList = providerMap[type];
    const provider = providerList[Math.floor(Math.random() * providerList.length)];

    const isCard = ['credit_card','debit_card'].includes(type);
    const isCash = type === 'cash';

    const lastFour = isCash ? undefined : (isCard ? ('' + (1000 + Math.floor(Math.random()*9000))) : '0000');
    const encryptedData = isCash ? undefined : ('enc_'+Math.random().toString(36).slice(2,10));

    return {
      userId,
      type,
      provider,
      lastFourDigits: lastFour,
      expiryMonth: isCard ? (1 + Math.floor(Math.random()*12)) : undefined,
      expiryYear: isCard ? (new Date().getFullYear() + 1 + Math.floor(Math.random()*4)) : undefined,
      cardholderName: isCard ? 'Seeder User' : undefined,
      isDefault: i===0,
      isActive: true,
      encryptedData
    };
  }

  generatePayment(userId, pmId, i){
    const amount = Math.round((50 + Math.random()*500) * 100)/100;
    const processingFee = Math.round((amount * 0.029 + 2.50) * 100) / 100;
    const netAmount = Math.max(0, amount - processingFee);
    const statuses = ['pending','processing','completed','failed'];
    const status = statuses[i % statuses.length];
    const transactionType = 'payment';
    return {
      userId,
      bookingId: new mongoose.Types.ObjectId(),
      paymentMethodId: pmId,
      amount,
      currency: 'ZAR',
      status,
      transactionType,
      externalTransactionId: status==='completed' ? `txn_${Date.now()}_${Math.random().toString(36).slice(2,8)}` : undefined,
      processingFee,
      netAmount,
      description: `Seed payment ${i+1}`,
      metadata: { seed:true, index:i },
      createdAt: new Date(Date.now() - i*3600*1000),
      updatedAt: new Date(Date.now() - i*3600*1000)
    };
  }

  async seed({ users=5, methodsPerUser=2, paymentsPerUser=8, clearExisting=false }={}){
    try{
      console.log(`🌱 Seeding Payments: users=${users}, methods/user=${methodsPerUser}, payments/user=${paymentsPerUser}`);
      if (clearExisting){
        console.log('🗑️ Clearing existing PaymentMethods and Payments...');
        await Payment.deleteMany({});
        await PaymentMethod.deleteMany({});
        console.log('✅ Cleared');
      }

      const existing = await Payment.countDocuments();
      if (existing>0 && !clearExisting){
        console.log(`⚠️ ${existing} payments already exist; use --clear-existing to replace`);
        return;
      }

      for (let u=0; u<users; u++){
        const userId = new mongoose.Types.ObjectId();
        const methods = [];
        for (let i=0; i<methodsPerUser; i++) methods.push(this.generatePaymentMethod(userId, u*methodsPerUser+i));
        const insertedPM = await PaymentMethod.insertMany(methods);

        const payments = [];
        for (let p=0; p<paymentsPerUser; p++){
          const pm = insertedPM[p % insertedPM.length];
          payments.push(this.generatePayment(userId, pm._id, u*paymentsPerUser+p));
        }
        await Payment.insertMany(payments);
        console.log(`✅ Seeded user ${u+1}/${users}: methods=${insertedPM.length}, payments=${payments.length}`);
      }

      const totals = { methods: await PaymentMethod.countDocuments(), payments: await Payment.countDocuments() };
      console.log(`🎉 Seeding complete. Methods=${totals.methods}, Payments=${totals.payments}`);
    }catch(e){
      console.error('❌ Payments seeding failed:', e);
      throw e;
    }
  }
}

if (require.main === module){
  const args = process.argv.slice(2);
  const opts = {};
  const uIdx = args.indexOf('--users'); if (uIdx!==-1) opts.users = parseInt(args[uIdx+1]);
  const mIdx = args.indexOf('--methods'); if (mIdx!==-1) opts.methodsPerUser = parseInt(args[mIdx+1]);
  const pIdx = args.indexOf('--payments'); if (pIdx!==-1) opts.paymentsPerUser = parseInt(args[pIdx+1]);
  if (args.includes('--clear-existing')) opts.clearExisting = true;

  const seeder = new PaymentsDatabaseSeeder();
  seeder.connect()
    .then(()=>seeder.seed(opts))
    .then(()=>{ console.log('✅ Payments seeding completed successfully'); process.exit(0); })
    .catch((e)=>{ console.error('❌ Payments seeding failed:', e); process.exit(1); });
}

module.exports = PaymentsDatabaseSeeder;
