// Quick MongoDB connection test
const mongoose = require('mongoose');
require('dotenv').config();

const testConnection = async () => {
  try {
    console.log('🔄 Testing MongoDB connection...');
    
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    
    console.log('✅ MongoDB connection successful!');
    console.log('📊 Database:', mongoose.connection.db.databaseName);
    console.log('🌐 Host:', mongoose.connection.host);
    
    // Test creating a simple document
    const testSchema = new mongoose.Schema({ test: String });
    const TestModel = mongoose.model('Test', testSchema);
    
    const testDoc = new TestModel({ test: 'SwiftLyft Auth API Connection Test' });
    await testDoc.save();
    console.log('✅ Test document created successfully!');
    
    // Clean up test document
    await TestModel.deleteOne({ _id: testDoc._id });
    console.log('🧹 Test document cleaned up');
    
  } catch (error) {
    console.error('❌ MongoDB connection failed:', error.message);
  } finally {
    await mongoose.connection.close();
    console.log('🔌 Connection closed');
    process.exit(0);
  }
};

testConnection();


