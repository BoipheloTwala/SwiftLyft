const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

// Import models
const User = require('../models/User');

class DatabaseSeeder {
  constructor() {
    this.connection = null;
  }

  // Connect to MongoDB
  async connect() {
    try {
      const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_users';
      
      this.connection = await mongoose.connect(mongoUri, {
        useNewUrlParser: true,
        useUnifiedTopology: true,
      });

      console.log('✅ Connected to MongoDB for seeding');
      return this.connection;
    } catch (error) {
      console.error('❌ MongoDB connection error:', error);
      throw error;
    }
  }

  // Clear existing data
  async clearData() {
    try {
      console.log('🧹 Clearing existing data...');
      
      const userCount = await User.countDocuments();
      if (userCount > 0) {
        await User.deleteMany({});
        console.log(`✅ Cleared ${userCount} users`);
      } else {
        console.log('ℹ️ No users to clear');
      }
    } catch (error) {
      console.error('❌ Error clearing data:', error);
      throw error;
    }
  }

  // Generate random data
  generateRandomData() {
    const firstNames = ['John', 'Jane', 'Michael', 'Sarah', 'David', 'Lisa', 'Robert', 'Emily', 'James', 'Jessica'];
    const lastNames = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez'];
    const companies = ['Tech Solutions', 'Business Corp', 'Innovation Ltd', 'Global Services', 'Digital Works'];
    const cities = ['Cape Town', 'Johannesburg', 'Durban', 'Pretoria', 'Port Elizabeth'];
    const vehicleTypes = ['Sedan', 'SUV', 'Minivan', 'Luxury Car', 'Economy Car'];

    const randomFirstName = firstNames[Math.floor(Math.random() * firstNames.length)];
    const randomLastName = lastNames[Math.floor(Math.random() * lastNames.length)];
    const randomCompany = companies[Math.floor(Math.random() * companies.length)];
    const randomCity = cities[Math.floor(Math.random() * cities.length)];
    const randomVehicle = vehicleTypes[Math.floor(Math.random() * vehicleTypes.length)];

    return {
      firstName: randomFirstName,
      lastName: randomLastName,
      company: randomCompany,
      city: randomCity,
      vehicle: randomVehicle
    };
  }

  // Generate loyalty tier based on points
  generateLoyaltyTier(points) {
    if (points >= 10000) return 'Diamond';
    if (points >= 5000) return 'Platinum';
    if (points >= 2500) return 'Gold';
    if (points >= 1000) return 'Silver';
    return 'Bronze';
  }

  // Generate sample addresses
  generateAddresses(userId) {
    const addresses = [];
    const addressTypes = ['Home', 'Work', 'Other'];
    
    for (let i = 0; i < Math.floor(Math.random() * 3) + 1; i++) {
      const randomData = this.generateRandomData();
      addresses.push({
        label: addressTypes[i] || 'Other',
        address: `${Math.floor(Math.random() * 999) + 1} ${randomData.firstName} Street, ${randomData.city}, South Africa`,
        coordinates: {
          latitude: -33.9249 + (Math.random() - 0.5) * 2,
          longitude: 18.4241 + (Math.random() - 0.5) * 2
        },
        isDefault: i === 0
      });
    }
    
    return addresses;
  }

  // Generate sample rewards
  generateRewards(type = 'earned') {
    const rewardTemplates = [
      {
        name: 'Free Ride',
        description: 'One free ride up to R50',
        type: 'free_ride',
        pointsCost: 1000,
        discountPercentage: 0
      },
      {
        name: '10% Discount',
        description: '10% off your next ride',
        type: 'discount',
        pointsCost: 500,
        discountPercentage: 10
      },
      {
        name: 'Priority Booking',
        description: 'Priority booking for next 5 rides',
        type: 'priority',
        pointsCost: 2000,
        discountPercentage: 0
      },
      {
        name: 'Vehicle Upgrade',
        description: 'Free upgrade to premium vehicle',
        type: 'upgrade',
        pointsCost: 1500,
        discountPercentage: 0
      }
    ];

    const rewards = [];
    const numRewards = Math.floor(Math.random() * 3) + 1;
    
    for (let i = 0; i < numRewards; i++) {
      const template = rewardTemplates[Math.floor(Math.random() * rewardTemplates.length)];
      rewards.push({
        ...template,
        isActive: Math.random() > 0.2, // 80% chance of being active
        expiresAt: new Date(Date.now() + Math.random() * 365 * 24 * 60 * 60 * 1000),
        redeemedAt: type === 'earned' && Math.random() > 0.5 ? new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000) : null
      });
    }
    
    return rewards;
  }

  // Generate sample referrals
  generateReferrals() {
    const referrals = [];
    const numReferrals = Math.floor(Math.random() * 5);
    
    for (let i = 0; i < numReferrals; i++) {
      const randomData = this.generateRandomData();
      const statuses = ['pending', 'completed', 'cancelled'];
      const status = statuses[Math.floor(Math.random() * statuses.length)];
      
      referrals.push({
        referredUserEmail: `${randomData.firstName.toLowerCase()}.${randomData.lastName.toLowerCase()}@example.com`,
        referredUserName: `${randomData.firstName} ${randomData.lastName}`,
        status: status,
        earnings: status === 'completed' ? Math.floor(Math.random() * 100) + 25 : 0,
        createdAt: new Date(Date.now() - Math.random() * 90 * 24 * 60 * 60 * 1000),
        completedAt: status === 'completed' ? new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000) : null
      });
    }
    
    return referrals;
  }

  // Generate sample bulk bookings
  generateBulkBookings() {
    const bookings = [];
    const numBookings = Math.floor(Math.random() * 3);
    
    for (let i = 0; i < numBookings; i++) {
      const randomData = this.generateRandomData();
      const statuses = ['draft', 'pending', 'confirmed', 'completed', 'cancelled'];
      const status = statuses[Math.floor(Math.random() * statuses.length)];
      
      const items = [];
      const numItems = Math.floor(Math.random() * 3) + 1;
      
      for (let j = 0; j < numItems; j++) {
        items.push({
          vehicleId: new mongoose.Types.ObjectId(),
          vehicleName: `${randomData.vehicle} ${j + 1}`,
          quantity: Math.floor(Math.random() * 5) + 1,
          unitPrice: Math.floor(Math.random() * 200) + 50,
          pickupLocation: `${randomData.city} Office`,
          dropoffLocation: `${randomData.city} Convention Center`,
          pickupTime: new Date(Date.now() + Math.random() * 30 * 24 * 60 * 60 * 1000),
          passengerCount: Math.floor(Math.random() * 6) + 1
        });
      }
      
      const totalAmount = items.reduce((sum, item) => sum + (item.unitPrice * item.quantity), 0);
      const discountAmount = Math.floor(totalAmount * 0.1); // 10% discount
      
      bookings.push({
        title: `${randomData.company} Event Transportation`,
        description: `Transportation for ${randomData.company} corporate event`,
        items: items,
        status: status,
        totalAmount: totalAmount,
        discountAmount: discountAmount,
        createdAt: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000),
        scheduledDate: new Date(Date.now() + Math.random() * 30 * 24 * 60 * 60 * 1000),
        specialNotes: Math.random() > 0.5 ? 'Please arrive 15 minutes early' : null
      });
    }
    
    return bookings;
  }

  // Generate corporate account
  generateCorporateAccount() {
    const randomData = this.generateRandomData();
    const hasCorporateAccount = Math.random() > 0.7; // 30% chance of having corporate account
    
    if (!hasCorporateAccount) return null;
    
    return {
      companyName: `${randomData.company} Ltd`,
      companyEmail: `admin@${randomData.company.toLowerCase().replace(/\s+/g, '')}.co.za`,
      contactPerson: `${randomData.firstName} ${randomData.lastName}`,
      contactPhone: `+27${Math.floor(Math.random() * 900000000) + 100000000}`,
      discountPercentage: Math.floor(Math.random() * 20) + 5, // 5-25%
      monthlyBudget: Math.floor(Math.random() * 50000) + 10000, // R10k-R60k
      usedBudget: Math.floor(Math.random() * 20000), // Up to R20k used
      status: Math.random() > 0.1 ? 'active' : 'suspended', // 90% active
      createdAt: new Date(Date.now() - Math.random() * 180 * 24 * 60 * 60 * 1000),
      expiresAt: new Date(Date.now() + Math.random() * 365 * 24 * 60 * 60 * 1000),
      authorizedUsers: []
    };
  }

  // Create a single user
  async createUser(userIndex) {
    try {
      const randomData = this.generateRandomData();
      const email = `user${userIndex}@example.com`;
      const loyaltyPoints = Math.floor(Math.random() * 15000);
      const loyaltyTier = this.generateLoyaltyTier(loyaltyPoints);
      const totalTrips = Math.floor(Math.random() * 100);
      const totalSpent = Math.floor(Math.random() * 10000) + totalTrips * 50;
      
      const userData = {
        email: email,
        password: 'Password123',
        name: `${randomData.firstName} ${randomData.lastName}`,
        phoneNumber: `+27${Math.floor(Math.random() * 900000000) + 100000000}`,
        role: Math.random() > 0.95 ? 'admin' : 'user', // 5% chance of admin
        loyaltyTier: loyaltyTier,
        loyaltyPoints: loyaltyPoints,
        totalTrips: totalTrips,
        totalSpent: totalSpent,
        savedAddresses: this.generateAddresses(userIndex),
        paymentMethods: [],
        earnedRewards: this.generateRewards('earned'),
        availableRewards: this.generateRewards('available'),
        referrals: this.generateReferrals(),
        corporateAccount: this.generateCorporateAccount(),
        bulkBookings: this.generateBulkBookings(),
        isEmailVerified: Math.random() > 0.2, // 80% verified
        isPhoneVerified: Math.random() > 0.3, // 70% verified
        isActive: Math.random() > 0.05, // 95% active
        refreshTokens: [],
        lastLoginAt: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000), // Within last week
        lastLoginIP: `192.168.1.${Math.floor(Math.random() * 255)}`,
        loginCount: Math.floor(Math.random() * 100),
        notificationSettings: {
          push: Math.random() > 0.1,
          email: Math.random() > 0.2,
          sms: Math.random() > 0.7,
          bookingUpdates: Math.random() > 0.1,
          promotionalOffers: Math.random() > 0.3,
          paymentReminders: Math.random() > 0.2,
          driverMessages: Math.random() > 0.1
        },
        fcmToken: Math.random() > 0.3 ? `fcm_token_${userIndex}_${Math.random().toString(36).substr(2, 9)}` : null
      };

      const user = new User(userData);
      await user.save();
      
      return user;
    } catch (error) {
      console.error(`❌ Error creating user ${userIndex}:`, error);
      throw error;
    }
  }

  // Seed database with sample data
  async seed(count = 50) {
    try {
      console.log(`🌱 Seeding database with ${count} users...`);
      
      const startTime = Date.now();
      const createdUsers = [];
      
      // Create users in batches to avoid memory issues
      const batchSize = 10;
      for (let i = 0; i < count; i += batchSize) {
        const batchPromises = [];
        const batchEnd = Math.min(i + batchSize, count);
        
        for (let j = i; j < batchEnd; j++) {
          batchPromises.push(this.createUser(j + 1));
        }
        
        const batchUsers = await Promise.all(batchPromises);
        createdUsers.push(...batchUsers);
        
        console.log(`✅ Created batch ${Math.floor(i / batchSize) + 1}: users ${i + 1}-${batchEnd}`);
      }
      
      const endTime = Date.now();
      const duration = (endTime - startTime) / 1000;
      
      console.log(`🎉 Successfully created ${createdUsers.length} users in ${duration.toFixed(2)} seconds`);
      
      // Print summary statistics
      await this.printSummary();
      
      return createdUsers;
    } catch (error) {
      console.error('❌ Error seeding database:', error);
      throw error;
    }
  }

  // Print summary statistics
  async printSummary() {
    try {
      console.log('\n📊 Database Summary:');
      
      const totalUsers = await User.countDocuments();
      const activeUsers = await User.countDocuments({ isActive: true });
      const adminUsers = await User.countDocuments({ role: 'admin' });
      const corporateUsers = await User.countDocuments({ 'corporateAccount': { $exists: true } });
      const verifiedUsers = await User.countDocuments({ isEmailVerified: true });
      
      // Loyalty tier distribution
      const bronzeUsers = await User.countDocuments({ loyaltyTier: 'Bronze' });
      const silverUsers = await User.countDocuments({ loyaltyTier: 'Silver' });
      const goldUsers = await User.countDocuments({ loyaltyTier: 'Gold' });
      const platinumUsers = await User.countDocuments({ loyaltyTier: 'Platinum' });
      const diamondUsers = await User.countDocuments({ loyaltyTier: 'Diamond' });
      
      console.log(`👥 Total users: ${totalUsers}`);
      console.log(`✅ Active users: ${activeUsers}`);
      console.log(`👑 Admin users: ${adminUsers}`);
      console.log(`🏢 Corporate users: ${corporateUsers}`);
      console.log(`📧 Verified users: ${verifiedUsers}`);
      
      console.log('\n🏆 Loyalty Tier Distribution:');
      console.log(`🥉 Bronze: ${bronzeUsers}`);
      console.log(`🥈 Silver: ${silverUsers}`);
      console.log(`🥇 Gold: ${goldUsers}`);
      console.log(`💎 Platinum: ${platinumUsers}`);
      console.log(`💠 Diamond: ${diamondUsers}`);
      
      // Calculate totals
      const totalPoints = await User.aggregate([
        { $group: { _id: null, total: { $sum: '$loyaltyPoints' } } }
      ]);
      
      const totalSpent = await User.aggregate([
        { $group: { _id: null, total: { $sum: '$totalSpent' } } }
      ]);
      
      const totalTrips = await User.aggregate([
        { $group: { _id: null, total: { $sum: '$totalTrips' } } }
      ]);
      
      console.log('\n💰 Financial Summary:');
      console.log(`💎 Total loyalty points: ${totalPoints[0]?.total || 0}`);
      console.log(`💵 Total spent: R${(totalSpent[0]?.total || 0).toLocaleString()}`);
      console.log(`🚗 Total trips: ${totalTrips[0]?.total || 0}`);
      
    } catch (error) {
      console.error('❌ Error printing summary:', error);
    }
  }

  // Close database connection
  async close() {
    try {
      if (this.connection) {
        await mongoose.connection.close();
        console.log('✅ Database connection closed');
      }
    } catch (error) {
      console.error('❌ Error closing database connection:', error);
    }
  }

  // Full seeding process
  async run(options = {}) {
    const {
      clearData = false,
      count = 50
    } = options;

    try {
      console.log('🚀 Starting database seeding...');

      // Connect to database
      await this.connect();

      // Clear existing data if requested
      if (clearData) {
        await this.clearData();
      }

      // Seed database
      await this.seed(count);

      console.log('🎉 Database seeding completed successfully!');
  } catch (error) {
    console.error('❌ Database seeding failed:', error);
      throw error;
    }
  }
}

// CLI interface
if (require.main === module) {
  const args = process.argv.slice(2);
  const options = {};

  // Parse command line arguments
  if (args.includes('--clear')) {
    options.clearData = true;
  }
  
  const countArg = args.find(arg => arg.startsWith('--count='));
  if (countArg) {
    options.count = parseInt(countArg.split('=')[1]) || 50;
  }

  const seeder = new DatabaseSeeder();
  
  seeder.run(options)
    .then(() => {
      console.log('✅ Seeding completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Seeding failed:', error);
      process.exit(1);
    });
}

module.exports = DatabaseSeeder;