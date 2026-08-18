const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const User = require('../models/User');
const Driver = require('../models/Driver');
const Vehicle = require('../models/Vehicle');
const Booking = require('../models/Booking');
const Trip = require('../models/Trip');

class DatabaseMigration {
  constructor() {
    this.connection = null;
  }

  async connect() {
    try {
      this.connection = await mongoose.connect(process.env.MONGODB_URI, {
        useNewUrlParser: true,
        useUnifiedTopology: true,
      });
      console.log('✅ Connected to MongoDB for migration');
    } catch (error) {
      console.error('❌ MongoDB connection error:', error);
      throw error;
    }
  }

  async disconnect() {
    if (this.connection) {
      await mongoose.disconnect();
      console.log('📤 Disconnected from MongoDB');
    }
  }

  async migrateBookingsToTrips() {
    console.log('🔄 Migrating bookings to trips...');
    
    try {
      // Find all completed bookings that don't have trips
      const completedBookings = await Booking.find({
        status: 'completed',
        tripId: { $exists: false }
      });
      
      console.log(`Found ${completedBookings.length} completed bookings to migrate`);
      
      for (const booking of completedBookings) {
        try {
          // Create trip from booking
          const tripData = {
            tripId: `TR${Date.now().toString(36).slice(-4)}${Math.random().toString(36).substring(2, 6)}`.toUpperCase(),
            bookingId: booking._id,
            userId: booking.userId,
            driverId: booking.driverId,
            vehicleId: booking.vehicleId,
            status: 'completed',
            startTime: booking.tripStartedAt || booking.actualPickupTime || booking.pickupTime,
            endTime: booking.tripCompletedAt || booking.actualDropoffTime,
            duration: booking.tripDetails?.actualDuration || booking.tripDetails?.duration || 0,
            passengerCount: booking.passengerCount,
            luggageCount: booking.luggageCount,
            route: {
              totalDistance: booking.tripDetails?.actualDistance || booking.tripDetails?.distance || 0,
              totalDuration: booking.tripDetails?.actualDuration || booking.tripDetails?.duration || 0,
              trafficConditions: booking.tripDetails?.trafficConditions || 'moderate',
              weatherConditions: booking.tripDetails?.weatherConditions || 'clear'
            },
            safetyMetrics: {
              maxSpeed: booking.tripDetails?.maxSpeed || 0,
              averageSpeed: booking.tripDetails?.averageSpeed || 0,
              harshBrakingCount: booking.tripDetails?.harshBraking || 0,
              harshAccelerationCount: booking.tripDetails?.harshAcceleration || 0,
              safetyScore: 100
            },
            environmentalMetrics: {
              fuelConsumed: booking.tripDetails?.fuelConsumed || 0,
              carbonFootprint: booking.tripDetails?.carbonFootprint || 0,
              efficiency: booking.tripDetails?.efficiency || 0,
              ecoFriendlyScore: 100
            },
            performanceMetrics: {
              onTimePickup: booking.actualPickupTime ? 
                Math.abs(booking.actualPickupTime - booking.pickupTime) <= 15 * 60 * 1000 : false,
              tripDuration: booking.tripDetails?.actualDuration || booking.tripDetails?.duration || 0,
              estimatedDuration: booking.tripDetails?.duration || 0,
              overallScore: 100
            },
            specialRequirements: {
              wheelchairAccess: booking.specialNotes?.toLowerCase().includes('wheelchair') || false,
              childSeat: booking.specialNotes?.toLowerCase().includes('child') || false,
              petTransport: booking.specialNotes?.toLowerCase().includes('pet') || false,
              closeProtection: booking.closeProtectionOfficer || false,
              medicalTransport: booking.specialNotes?.toLowerCase().includes('medical') || false
            },
            driverNotes: booking.internalNotes || '',
            customerNotes: booking.customerNotes || '',
            internalNotes: booking.internalNotes || ''
          };
          
          const trip = new Trip(tripData);
          await trip.save();
          
          // Update booking with trip ID
          booking.tripId = trip.tripId;
          await booking.save();
          
          console.log(`✅ Migrated booking ${booking.bookingId} to trip ${trip.tripId}`);
          
        } catch (error) {
          console.error(`❌ Error migrating booking ${booking.bookingId}:`, error.message);
        }
      }
      
      console.log('✅ Booking to trip migration completed');
    } catch (error) {
      console.error('❌ Error in booking migration:', error);
      throw error;
    }
  }

  async updateVehicleSchema() {
    console.log('🔄 Updating vehicle schema...');
    
    try {
      // Find vehicles without frontend-compatible fields
      const vehiclesToUpdate = await Vehicle.find({
        $or: [
          { id: { $exists: false } },
          { name: { $exists: false } },
          { description: { $exists: false } },
          { seatingCapacity: { $exists: false } },
          { basePrice: { $exists: false } },
          { isAvailable: { $exists: false } },
          { features: { $exists: false } },
          { badges: { $exists: false } },
          { specifications: { $exists: false } }
        ]
      });
      
      console.log(`Found ${vehiclesToUpdate.length} vehicles to update`);
      
      for (const vehicle of vehiclesToUpdate) {
        try {
          const updates = {};
          
          // Add missing frontend fields
          if (!vehicle.id) {
            updates.id = vehicle.vehicleId;
          }
          
          if (!vehicle.name) {
            updates.name = `${vehicle.year} ${vehicle.make} ${vehicle.model}`;
          }
          
          if (!vehicle.description) {
            updates.description = `Premium ${vehicle.category} vehicle`;
          }
          
          if (!vehicle.seatingCapacity && vehicle.passengerCapacity) {
            updates.seatingCapacity = vehicle.passengerCapacity;
          }
          
          if (!vehicle.basePrice && vehicle.pricing?.baseFare) {
            updates.basePrice = vehicle.pricing.baseFare;
          }
          
          if (!vehicle.isAvailable && vehicle.availability?.isAvailable !== undefined) {
            updates.isAvailable = vehicle.availability.isAvailable;
          }
          
          if (!vehicle.features) {
            updates.features = [];
            if (vehicle.featuresDetails) {
              // Convert featuresDetails object to features array
              const featuresArray = [];
              Object.keys(vehicle.featuresDetails).forEach(key => {
                if (vehicle.featuresDetails[key] === true) {
                  featuresArray.push(key);
                }
              });
              updates.features = featuresArray;
            }
          }
          
          if (!vehicle.badges) {
            updates.badges = [];
          }
          
          if (!vehicle.specifications) {
            updates.specifications = {};
          }
          
          // Apply updates
          if (Object.keys(updates).length > 0) {
            await Vehicle.findByIdAndUpdate(vehicle._id, updates);
            console.log(`✅ Updated vehicle ${vehicle.vehicleId}`);
          }
          
        } catch (error) {
          console.error(`❌ Error updating vehicle ${vehicle.vehicleId}:`, error.message);
        }
      }
      
      console.log('✅ Vehicle schema update completed');
    } catch (error) {
      console.error('❌ Error updating vehicle schema:', error);
      throw error;
    }
  }

  async updateBookingSchema() {
    console.log('🔄 Updating booking schema...');
    
    try {
      // Find bookings without new fields
      const bookingsToUpdate = await Booking.find({
        $or: [
          { tripId: { $exists: false } },
          { emergency: { $exists: false } },
          { analytics: { $exists: false } },
          { qualityCheck: { $exists: false } }
        ]
      });
      
      console.log(`Found ${bookingsToUpdate.length} bookings to update`);
      
      for (const booking of bookingsToUpdate) {
        try {
          const updates = {};
          
          // Add missing fields with default values
          if (!booking.emergency) {
            updates.emergency = {
              safetyCheckCompleted: false,
              incidentReport: {
                hasIncident: false,
                severity: 'low'
              }
            };
          }
          
          if (!booking.analytics) {
            updates.analytics = {
              bookingSource: 'app',
              referralCode: '',
              campaignId: '',
              utmSource: '',
              utmMedium: '',
              utmCampaign: ''
            };
          }
          
          if (!booking.qualityCheck) {
            updates.qualityCheck = {
              completed: false,
              score: 0,
              notes: ''
            };
          }
          
          // Apply updates
          if (Object.keys(updates).length > 0) {
            await Booking.findByIdAndUpdate(booking._id, updates);
            console.log(`✅ Updated booking ${booking.bookingId}`);
          }
          
        } catch (error) {
          console.error(`❌ Error updating booking ${booking.bookingId}:`, error.message);
        }
      }
      
      console.log('✅ Booking schema update completed');
    } catch (error) {
      console.error('❌ Error updating booking schema:', error);
      throw error;
    }
  }

  async createMissingIndexes() {
    console.log('🔄 Creating missing indexes...');
    
    try {
      // Vehicle indexes
      try {
        await Vehicle.collection.createIndex({ id: 1 }, { unique: true });
        console.log('✅ Created vehicle id index');
      } catch (error) {
        console.log('ℹ️ Vehicle id index already exists');
      }
      
      // Booking indexes
      try {
        await Booking.collection.createIndex({ tripId: 1 }, { unique: true, sparse: true });
        console.log('✅ Created booking tripId index');
      } catch (error) {
        console.log('ℹ️ Booking tripId index already exists');
      }
      
      // Trip indexes
      try {
        await Trip.collection.createIndex({ tripId: 1 }, { unique: true });
        console.log('✅ Created trip tripId index');
      } catch (error) {
        console.log('ℹ️ Trip tripId index already exists');
      }
      
      console.log('✅ Missing indexes creation completed');
    } catch (error) {
      console.error('❌ Error creating missing indexes:', error);
      throw error;
    }
  }

  async validateDataIntegrity() {
    console.log('🔍 Validating data integrity...');
    
    try {
      // Check for orphaned trips
      const orphanedTrips = await Trip.find({
        bookingId: { $nin: await Booking.distinct('_id') }
      });
      
      if (orphanedTrips.length > 0) {
        console.log(`⚠️ Found ${orphanedTrips.length} orphaned trips`);
        // Optionally clean up orphaned trips
        // await Trip.deleteMany({ _id: { $in: orphanedTrips.map(t => t._id) } });
      }
      
      // Check for bookings without trips (completed ones)
      const completedBookingsWithoutTrips = await Booking.find({
        status: 'completed',
        tripId: { $exists: false }
      });
      
      if (completedBookingsWithoutTrips.length > 0) {
        console.log(`⚠️ Found ${completedBookingsWithoutTrips.length} completed bookings without trips`);
      }
      
      // Check for vehicles without drivers
      const vehiclesWithoutDrivers = await Vehicle.find({
        driverId: { $nin: await Driver.distinct('_id') }
      });
      
      if (vehiclesWithoutDrivers.length > 0) {
        console.log(`⚠️ Found ${vehiclesWithoutDrivers.length} vehicles without drivers`);
      }
      
      console.log('✅ Data integrity validation completed');
    } catch (error) {
      console.error('❌ Error validating data integrity:', error);
      throw error;
    }
  }

  async performMigration(options = {}) {
    const {
      migrateBookings = true,
      updateVehicleSchema = true,
      updateBookingSchema = true,
      createIndexes = true,
      validateIntegrity = true
    } = options;
    
    try {
      console.log('🚀 Starting database migration...');
      
      // Connect to database
      await this.connect();
      
      // Migrate bookings to trips
      if (migrateBookings) {
        await this.migrateBookingsToTrips();
      }
      
      // Update vehicle schema
      if (updateVehicleSchema) {
        await this.updateVehicleSchema();
      }
      
      // Update booking schema
      if (updateBookingSchema) {
        await this.updateBookingSchema();
      }
      
      // Create missing indexes
      if (createIndexes) {
        await this.createMissingIndexes();
      }
      
      // Validate data integrity
      if (validateIntegrity) {
        await this.validateDataIntegrity();
      }
      
      console.log('🎉 Database migration completed successfully!');
      
    } catch (error) {
      console.error('💥 Database migration failed:', error);
      throw error;
    } finally {
      await this.disconnect();
    }
  }
}

// Export for use in other scripts
module.exports = DatabaseMigration;

// If this script is run directly
if (require.main === module) {
  const migration = new DatabaseMigration();
  
  const args = process.argv.slice(2);
  const options = {
    migrateBookings: !args.includes('--no-booking-migration'),
    updateVehicleSchema: !args.includes('--no-vehicle-update'),
    updateBookingSchema: !args.includes('--no-booking-update'),
    createIndexes: !args.includes('--no-indexes'),
    validateIntegrity: !args.includes('--no-validation')
  };
  
  migration.performMigration(options)
    .then(() => {
      console.log('✅ Migration completed');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Migration failed:', error);
      process.exit(1);
    });
}
