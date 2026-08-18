const mongoose = require('mongoose');
require('dotenv').config();

const { SupportTicket, SupportMessage, FAQ } = require('../models/Support');

class SupportDatabaseSetup {
  constructor(){ this.connection=null; }

  async connect(){
    try{
      const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_support';
      this.connection = await mongoose.connect(mongoUri, { useNewUrlParser:true, useUnifiedTopology:true });
      console.log('✅ Connected to MongoDB for Support');
      console.log(`📊 Database: ${mongoose.connection.name}`);
    }catch(e){
      console.error('❌ MongoDB connection error:', e);
      throw e;
    }
  }

  async safeCreateIndex(collection, key, options = {}){
    try {
      await collection.createIndex(key, { background:true, ...options });
    } catch (error) {
      if (error && (error.code === 85 || error.code === 86)) {
        console.log(`ℹ️  Index exists/conflicts, skipping: ${JSON.stringify(key)}`);
      } else {
        throw error;
      }
    }
  }

  async createIndexes(){
    console.log('🔍 Creating Support indexes...');
    await this.safeCreateIndex(SupportTicket.collection, { ticketId: 1 });
    await this.safeCreateIndex(SupportTicket.collection, { userId: 1, createdAt: -1 });
    await this.safeCreateIndex(SupportTicket.collection, { status: 1, priority: 1 });
    await this.safeCreateIndex(SupportTicket.collection, { category: 1 });

    await this.safeCreateIndex(SupportMessage.collection, { ticketId: 1, createdAt: 1 });

    await this.safeCreateIndex(FAQ.collection, { category: 1, isActive: 1 });
    await this.safeCreateIndex(FAQ.collection, { tags: 1 });

    console.log('✅ Support indexes ensured');
  }

  async validateSchema(){
    console.log('🔍 Validating Support schemas...');

    const ticket = new SupportTicket({
      ticketId: `TKT-${Date.now().toString(36).toUpperCase()}`,
      userId: new mongoose.Types.ObjectId(),
      subject: 'Test issue',
      category: 'general_inquiry',
      description: 'Just testing',
      priority: 'normal'
    });
    await ticket.validate();
    ticket.isResolved; ticket.responseTime;

    const message = new SupportMessage({
      ticketId: new mongoose.Types.ObjectId(),
      senderId: new mongoose.Types.ObjectId(),
      senderType: 'user',
      message: 'Hello Support'
    });
    await message.validate();

    const faq = new FAQ({
      question: 'How to book a ride?',
      answer: 'Open the app and follow prompts.',
      category: 'getting_started',
      tags: ['booking','start']
    });
    await faq.validate();

    console.log('✅ Support schema validation passed');
  }

  async createSampleData(){
    console.log('🌱 Creating Support sample data...');

    const faqCount = await FAQ.countDocuments();
    if (faqCount === 0){
      await FAQ.insertMany([
        { question: 'How do I reset my password?', answer: 'Use the Forgot Password option.', category: 'account', tags: ['password','account'] },
        { question: 'How are fares calculated?', answer: 'Base fare + time + distance.', category: 'payment', tags: ['fare','payment'] },
        { question: 'How to contact support?', answer: 'Email support@swiftlyft.co.za', category: 'general', tags: ['support','contact'] }
      ]);
      console.log('✅ Seeded FAQs');
    }

    const userId = new mongoose.Types.ObjectId();
    const tkt = new SupportTicket({
      ticketId: SupportTicket.generateTicketId(),
      userId,
      subject: 'App is crashing',
      category: 'app_technical',
      description: 'The app crashes when opening bookings.',
      priority: 'high'
    });
    await tkt.save();

    await new SupportMessage({
      ticketId: tkt._id,
      senderId: userId,
      senderType: 'user',
      message: 'Happens after latest update.'
    }).save();

    console.log('✅ Seeded support ticket and message');
  }

  async healthCheck(){
    const stats = await this.connection.connection.db.stats();
    console.log(`📊 Collections: ${stats.collections}, Objects: ${stats.objects || 0}`);

    const [tickets, messages, faqs] = await Promise.all([
      SupportTicket.countDocuments(),
      SupportMessage.countDocuments(),
      FAQ.countDocuments()
    ]);
    console.log(`📊 Counts -> Tickets=${tickets} Messages=${messages} FAQs=${faqs}`);
  }

  async setup(options={}){
    const { createIndexes=true, validateSchema=true, createSampleData=false, runHealthCheck=true } = options;
    console.log('🚀 Starting Support database setup...');
    await this.connect();
    if (createIndexes) await this.createIndexes();
    if (validateSchema) await this.validateSchema();
    if (createSampleData) await this.createSampleData();
    if (runHealthCheck) await this.healthCheck();
    console.log('🎉 Support database setup completed successfully!');
  }
}

if (require.main === module){
  const args = process.argv.slice(2);
  const options = {};
  if (args.includes('--sample-data')) options.createSampleData = true;
  if (args.includes('--no-indexes')) options.createIndexes = false;
  if (args.includes('--no-validation')) options.validateSchema = false;
  if (args.includes('--no-health-check')) options.runHealthCheck = false;

  new SupportDatabaseSetup().setup(options)
    .then(()=>{ console.log('✅ Support setup completed successfully'); process.exit(0); })
    .catch((e)=>{ console.error('❌ Support setup failed:', e); process.exit(1); });
}

module.exports = SupportDatabaseSetup;
