const mongoose = require('mongoose');
require('dotenv').config();
const { SupportTicket, SupportMessage, FAQ } = require('../models/Support');

class SupportDatabaseSeeder {
  constructor(){ this.connection=null; }
  async connect(){
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_support';
    this.connection = await mongoose.connect(mongoUri, { useNewUrlParser:true, useUnifiedTopology:true });
    console.log('✅ Connected to MongoDB for Support seeding');
      console.log(`📊 Database: ${mongoose.connection.name}`);
  }

  async seed({ faqs=6, tickets=3, messagesPerTicket=2, clearExisting=false }={}){
    try{
      if (clearExisting){
        console.log('🗑️ Clearing existing Support data...');
        await Promise.all([
          SupportMessage.deleteMany({}),
          SupportTicket.deleteMany({}),
          FAQ.deleteMany({})
        ]);
      }

      // Seed FAQs
      const faqCount = await FAQ.countDocuments();
      if (faqCount === 0){
        const categories = ['general','getting_started','booking','payment','driver','account','safety','corporate','technical'];
        const docs = [];
        for (let i=0;i<faqs;i++){
          docs.push({
            question: `FAQ Question ${i+1}?`,
            answer: `This is the detailed answer for question ${i+1}.`,
            category: categories[i % categories.length],
            tags: ['faq','help','info']
          });
        }
        await FAQ.insertMany(docs);
        console.log(`✅ Seeded ${docs.length} FAQs`);
      }

      // Seed Tickets + Messages
      for (let t=0;t<tickets;t++){
        const userId = new mongoose.Types.ObjectId();
        const ticket = new SupportTicket({
          ticketId: SupportTicket.generateTicketId(),
          userId,
          subject: `Issue ${t+1}`,
          category: t%2===0 ? 'booking_issue' : 'payment_problem',
          description: `Description for issue ${t+1}`,
          priority: t%3===0 ? 'high' : 'normal'
        });
        await ticket.save();

        for (let m=0;m<messagesPerTicket;m++){
          await new SupportMessage({
            ticketId: ticket._id,
            senderId: userId,
            senderType: m%2===0 ? 'user' : 'agent',
            message: `Message ${m+1} for ticket ${ticket.ticketId}`
          }).save();
        }
      }

      const [ticketsCount, messagesCount] = await Promise.all([
        SupportTicket.countDocuments(),
        SupportMessage.countDocuments()
      ]);
      console.log(`🎉 Seeding complete. Tickets=${ticketsCount} Messages=${messagesCount}`);
    }catch(e){
      console.error('❌ Support seeding failed:', e);
      throw e;
    }
  }
}

if (require.main === module){
  const args = process.argv.slice(2);
  const opts = {};
  const fIdx = args.indexOf('--faqs'); if (fIdx!==-1) opts.faqs = parseInt(args[fIdx+1]);
  const tIdx = args.indexOf('--tickets'); if (tIdx!==-1) opts.tickets = parseInt(args[tIdx+1]);
  const mIdx = args.indexOf('--messages'); if (mIdx!==-1) opts.messagesPerTicket = parseInt(args[mIdx+1]);
  if (args.includes('--clear-existing')) opts.clearExisting = true;

  const seeder = new SupportDatabaseSeeder();
  seeder.connect()
    .then(()=>seeder.seed(opts))
    .then(()=>{ console.log('✅ Support seeding completed successfully'); process.exit(0); })
    .catch((e)=>{ console.error('❌ Support seeding failed:', e); process.exit(1); });
}

module.exports = SupportDatabaseSeeder;
