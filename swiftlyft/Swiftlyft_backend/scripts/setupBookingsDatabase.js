const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Booking = require('../models/Booking');

class BookingsDatabaseSetup {
  constructor() {
    this.connection = null;
  }

  // Connect to MongoDB
  async connect() {
    try {
      const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_bookings';
      
      this.connection = await mongoose.connect(mongoUri, {
        useNewUrlParser: true,
        useUnifiedTopology: true,
      });

      console.log('✅ Connected to MongoDB for Bookings');
      console.log(`📊 Database: ${mongoose.connection.name}`);
      return this.connection;
    } catch (error) {
      console.error('❌ MongoDB connection error:', error);
      throw error;
    }
  }

  // Create indexes for optimal performance
  async createIndexes() {
    try {
      console.log('🔍 Creating Bookings database indexes...');

      // Core identifier indexes
      await Booking.collection.createIndex({ "bookingId": 1 }, { unique: true });
      console.log('✅ Created bookingId index');

      await Booking.collection.createIndex({ "tripId": 1 }, { unique: true, sparse: true });
      console.log('✅ Created tripId index');

      // User and driver indexes
      await Booking.collection.createIndex({ "userId": 1, "createdAt": -1 });
      console.log('✅ Created userId + createdAt index');

      await Booking.collection.createIndex({ "driverId": 1, "createdAt": -1 });
      console.log('✅ Created driverId + createdAt index');

      await Booking.collection.createIndex({ "vehicleId": 1 });
      console.log('✅ Created vehicleId index');

      // Status and scheduling indexes
      await Booking.collection.createIndex({ "status": 1, "scheduledDate": 1 });
      console.log('✅ Created status + scheduledDate index');

      await Booking.collection.createIndex({ "scheduledDate": 1 });
      console.log('✅ Created scheduledDate index');

      // Geographic indexes for location-based queries
      await Booking.collection.createIndex({ "pickupLocation.coordinates": "2dsphere" });
      console.log('✅ Created pickupLocation 2dsphere index');

      await Booking.collection.createIndex({ "dropoffLocation.coordinates": "2dsphere" });
      console.log('✅ Created dropoffLocation 2dsphere index');

      // Payment and business logic indexes
      await Booking.collection.createIndex({ "paymentStatus": 1 });
      console.log('✅ Created paymentStatus index');

      await Booking.collection.createIndex({ "isCorporateBooking": 1 });
      console.log('✅ Created isCorporateBooking index');

      // Time-based indexes
      await Booking.collection.createIndex({ "createdAt": -1 });
      console.log('✅ Created createdAt index');

      await Booking.collection.createIndex({ "updatedAt": -1 });
      console.log('✅ Created updatedAt index');

      // Vehicle type and service type indexes
      await Booking.collection.createIndex({ "vehicleType": 1 });
      console.log('✅ Created vehicleType index');

      await Booking.collection.createIndex({ "serviceType": 1 });
      console.log('✅ Created serviceType index');

      // Compound indexes for complex queries
      await Booking.collection.createIndex({ 
        "status": 1, 
        "vehicleType": 1, 
        "scheduledDate": 1 
      });
      console.log('✅ Created status + vehicleType + scheduledDate compound index');

      await Booking.collection.createIndex({ 
        "userId": 1, 
        "status": 1, 
        "createdAt": -1 
      });
      console.log('✅ Created userId + status + createdAt compound index');

      await Booking.collection.createIndex({ 
        "driverId": 1, 
        "status": 1, 
        "scheduledDate": 1 
      });
      console.log('✅ Created driverId + status + scheduledDate compound index');

      // Text search index for addresses and notes
      await Booking.collection.createIndex({ 
        "pickupAddress": "text", 
        "dropoffAddress": "text", 
        "specialNotes": "text" 
      });
      console.log('✅ Created text search index');

      // Payment and pricing indexes
      await Booking.collection.createIndex({ "paymentMethod": 1 });
      console.log('✅ Created paymentMethod index');

      await Booking.collection.createIndex({ "finalPrice": 1 });
      console.log('✅ Created finalPrice index');

      // Rating and feedback indexes
      await Booking.collection.createIndex({ "rating": 1 });
      console.log('✅ Created rating index');

      // Corporate booking indexes
      await Booking.collection.createIndex({ "corporateAccountId": 1 });
      console.log('✅ Created corporateAccountId index');

      console.log('🎉 All Bookings indexes created successfully!');
    } catch (error) {
      console.error('❌ Error creating Bookings indexes:', error);
      throw error;
    }
  }

  // Validate database schema
  async validateSchema() {
    try {
      console.log('🔍 Validating Bookings database schema...');

      // Test Booking creation with validation
      const testBooking = new Booking({
        bookingId: 'BK' + Date.now().toString(36).slice(-4).toUpperCase(),
        userId: new mongoose.Types.ObjectId(),
        vehicleId: new mongoose.Types.ObjectId(),
        vehicleName: 'Test Vehicle',
        pickupAddress: '123 Test Street, Cape Town, South Africa',
        dropoffAddress: '456 Test Avenue, Cape Town, South Africa',
        pickupLocation: {
          address: '123 Test Street, Cape Town, South Africa',
          coordinates: {
            latitude: -33.9249,
            longitude: 18.4241
          },
          city: 'Cape Town',
          province: 'Western Cape',
          postalCode: '8001',
          instructions: 'Ring the doorbell',
          contactPhone: '+27123456789',
          landmark: 'Near the shopping center',
          buildingName: 'Test Building',
          floor: 'Ground Floor',
          unit: 'Unit 1'
        },
        dropoffLocation: {
          address: '456 Test Avenue, Cape Town, South Africa',
          coordinates: {
            latitude: -33.9250,
            longitude: 18.4242
          },
          city: 'Cape Town',
          province: 'Western Cape',
          postalCode: '8002',
          instructions: 'Wait at the main entrance',
          contactPhone: '+27987654321',
          landmark: 'Near the park',
          buildingName: 'Test Office Building',
          floor: '5th Floor',
          unit: 'Suite 501'
        },
        vehicleType: 'sedan',
        serviceType: 'standard',
        passengerCount: 2,
        luggageCount: 1,
        pickupTime: new Date(Date.now() + 24 * 60 * 60 * 1000), // Tomorrow
        scheduledDate: new Date(Date.now() + 24 * 60 * 60 * 1000),
        isFlexibleTime: false,
        flexibleWindow: 15,
        basePrice: 150.00,
        finalPrice: 180.00,
        pricing: {
          baseFare: 50.00,
          distanceFare: 80.00,
          timeFare: 20.00,
          serviceFee: 10.00,
          taxes: 20.00,
          discount: 0.00,
          loyaltyDiscount: 0.00,
          surgeMultiplier: 1.0,
          waitingFee: 0.00,
          cancellationFee: 0.00,
          total: 180.00,
          currency: 'ZAR',
          breakdown: {
            baseFare: 50.00,
            distanceFare: 80.00,
            timeFare: 20.00,
            serviceFee: 10.00,
            taxes: 20.00,
            discount: 0.00,
            loyaltyDiscount: 0.00,
            surgeMultiplier: 1.0,
            waitingFee: 0.00,
            cancellationFee: 0.00
          }
        },
        status: 'pending',
        statusHistory: [{
          status: 'pending',
          timestamp: new Date(),
          notes: 'Booking created',
          updatedBy: 'user',
          location: {
            latitude: -33.9249,
            longitude: 18.4241,
            address: '123 Test Street, Cape Town, South Africa'
          },
          estimatedTimeToNext: 30,
          reason: 'Initial booking creation',
          metadata: {
            source: 'mobile_app',
            version: '1.0.0'
          }
        }],
        paymentMethod: 'card',
        paymentStatus: 'pending',
        specialNotes: 'Please arrive 5 minutes early',
        closeProtectionOfficer: false,
        customerNotes: 'Customer prefers quiet ride',
        emergency: {
          emergencyContact: {
            name: 'John Doe',
            phone: '+27123456789',
            relationship: 'spouse'
          },
          safetyCheckCompleted: false,
          safetyCheckTimestamp: null,
          safetyNotes: '',
          incidentReport: {
            hasIncident: false,
            incidentType: '',
            description: '',
            reportedAt: null,
            reportedBy: '',
            severity: 'low'
          }
        },
        notificationsSent: [{
          type: 'booking_confirmed',
          sentAt: new Date(),
          status: 'sent',
          recipient: 'user',
          method: 'push',
          content: 'Your booking has been confirmed',
          metadata: {
            notificationId: 'notif_123',
            priority: 'high'
          }
        }],
        source: 'app',
        deviceInfo: {
          platform: 'ios',
          version: '1.0.0',
          userAgent: 'SwiftLyft/1.0.0 (iPhone; iOS 15.0)',
          ipAddress: '192.168.1.100'
        },
        analytics: {
          bookingSource: 'organic',
          referralCode: '',
          campaignId: '',
          utmSource: '',
          utmMedium: '',
          utmCampaign: ''
        },
        termsAccepted: true,
        termsAcceptedAt: new Date(),
        privacyPolicyAccepted: true,
        privacyPolicyAcceptedAt: new Date(),
        qualityCheck: {
          completed: false,
          checkedAt: null,
          checkedBy: '',
          score: null,
          notes: ''
        }
      });

      // Validate the document
      await testBooking.validate();
      console.log('✅ Booking schema validation passed');

      // Test virtual fields
      console.log('🔍 Testing virtual fields...');
      console.log(`Is active: ${testBooking.isActive}`);
      console.log(`Is completed: ${testBooking.isCompleted}`);
      console.log(`Is cancelled: ${testBooking.isCancelled}`);
      console.log(`Is disputed: ${testBooking.isDisputed}`);

      // Test instance methods
      console.log('🔍 Testing instance methods...');
      
      // Test status update
      await testBooking.updateStatus('confirmed', 'system', 'Booking confirmed');
      console.log(`✅ Status update method works: ${testBooking.status}`);

      // Test driver assignment
      const testDriverId = new mongoose.Types.ObjectId();
      await testBooking.assignDriver(testDriverId);
      console.log(`✅ Driver assignment method works: ${testBooking.driverId}`);

      // Test rating addition
      await testBooking.addRating(5, 'Excellent service!', {
        cleanliness: 5,
        punctuality: 5,
        friendliness: 5,
        driving: 5,
        vehicleCondition: 5,
        communication: 5
      });
      console.log(`✅ Rating method works: ${testBooking.rating}`);

      console.log('🎉 Bookings schema validation completed successfully!');
    } catch (error) {
      console.error('❌ Bookings schema validation failed:', error);
      throw error;
    }
  }

  // Create sample data for testing
  async createSampleData() {
    try {
      console.log('🌱 Creating Bookings sample data...');

      // Check if sample data already exists
      const existingBookings = await Booking.countDocuments();
      if (existingBookings > 0) {
        console.log('⚠️ Bookings sample data already exists, skipping...');
        return;
      }

      // Create sample bookings
      const sampleBookings = [
        {
          bookingId: 'BK' + Date.now().toString(36).slice(-4).toUpperCase(),
          userId: new mongoose.Types.ObjectId(),
          vehicleId: new mongoose.Types.ObjectId(),
          vehicleName: 'Luxury Sedan',
          pickupAddress: '123 Main Street, Cape Town, South Africa',
          dropoffAddress: 'Cape Town International Airport, South Africa',
          pickupLocation: {
            address: '123 Main Street, Cape Town, South Africa',
            coordinates: {
              latitude: -33.9249,
              longitude: 18.4241
            },
            city: 'Cape Town',
            province: 'Western Cape',
            postalCode: '8001',
            instructions: 'Ring the doorbell twice',
            contactPhone: '+27123456789',
            landmark: 'Near the shopping center',
            buildingName: 'Main Street Apartments',
            floor: 'Ground Floor',
            unit: 'Unit 5'
          },
          dropoffLocation: {
            address: 'Cape Town International Airport, South Africa',
            coordinates: {
              latitude: -33.9715,
              longitude: 18.6021
            },
            city: 'Cape Town',
            province: 'Western Cape',
            postalCode: '7490',
            instructions: 'Drop off at terminal 1',
            contactPhone: '+27111222333',
            landmark: 'Airport terminal',
            buildingName: 'Cape Town International Airport',
            floor: 'Ground Floor',
            unit: 'Terminal 1'
          },
          vehicleType: 'luxury',
          serviceType: 'airport',
          passengerCount: 2,
          luggageCount: 3,
          pickupTime: new Date(Date.now() + 2 * 60 * 60 * 1000), // 2 hours from now
          scheduledDate: new Date(Date.now() + 2 * 60 * 60 * 1000),
          isFlexibleTime: false,
          flexibleWindow: 15,
          basePrice: 350.00,
          finalPrice: 420.00,
          pricing: {
            baseFare: 100.00,
            distanceFare: 250.00,
            timeFare: 40.00,
            serviceFee: 20.00,
            taxes: 30.00,
            discount: 0.00,
            loyaltyDiscount: 20.00,
            surgeMultiplier: 1.0,
            waitingFee: 0.00,
            cancellationFee: 0.00,
            total: 420.00,
            currency: 'ZAR'
          },
          status: 'confirmed',
          statusHistory: [
            {
              status: 'pending',
              timestamp: new Date(Date.now() - 30 * 60 * 1000),
              notes: 'Booking created',
              correlationId: 'corr_001',
              updatedBy: 'user',
              location: {
                latitude: -33.9249,
                longitude: 18.4241,
                address: '123 Main Street, Cape Town, South Africa'
              },
              estimatedTimeToNext: 30,
              reason: 'Initial booking creation'
            },
            {
              status: 'confirmed',
              timestamp: new Date(Date.now() - 25 * 60 * 1000),
              notes: 'Booking confirmed',
              correlationId: 'corr_002',
              updatedBy: 'system',
              location: {
                latitude: -33.9249,
                longitude: 18.4241,
                address: '123 Main Street, Cape Town, South Africa'
              },
              estimatedTimeToNext: 90,
              reason: 'System confirmation'
            }
          ],
          paymentMethod: 'card',
          paymentStatus: 'paid',
          paymentMethodId: 'pm_12345',
          paymentId: 'pi_67890',
          paidAt: new Date(Date.now() - 20 * 60 * 1000),
          specialNotes: 'Please arrive 10 minutes early for airport transfer',
          closeProtectionOfficer: false,
          customerNotes: 'Customer has heavy luggage',
          emergency: {
            emergencyContact: {
              name: 'Jane Smith',
              phone: '+27123456789',
              relationship: 'spouse'
            },
            safetyCheckCompleted: true,
            safetyCheckTimestamp: new Date(Date.now() - 15 * 60 * 1000),
            safetyNotes: 'All safety checks completed',
            incidentReport: {
              hasIncident: false,
              incidentType: '',
              description: '',
              reportedAt: null,
              reportedBy: '',
              severity: 'low'
            }
          },
          notificationsSent: [
            {
              type: 'booking_confirmed',
              sentAt: new Date(Date.now() - 25 * 60 * 1000),
              status: 'delivered',
              recipient: 'user',
              method: 'push',
              content: 'Your airport transfer has been confirmed'
            }
          ],
          source: 'app',
          deviceInfo: {
            platform: 'ios',
            version: '1.2.0',
            userAgent: 'SwiftLyft/1.2.0 (iPhone; iOS 15.0)',
            ipAddress: '192.168.1.100'
          },
          analytics: {
            bookingSource: 'organic',
            referralCode: 'REF123',
            campaignId: 'airport_promo',
            utmSource: 'google',
            utmMedium: 'search',
            utmCampaign: 'airport_transfers'
          },
          termsAccepted: true,
          termsAcceptedAt: new Date(Date.now() - 35 * 60 * 1000),
          privacyPolicyAccepted: true,
          privacyPolicyAcceptedAt: new Date(Date.now() - 35 * 60 * 1000),
          qualityCheck: {
            completed: true,
            checkedAt: new Date(Date.now() - 10 * 60 * 1000),
            checkedBy: 'system',
            score: 95,
            notes: 'High quality booking with complete information'
          }
        },
        {
          bookingId: 'BK' + (Date.now() + 1).toString(36).slice(-4).toUpperCase(),
          userId: new mongoose.Types.ObjectId(),
          vehicleId: new mongoose.Types.ObjectId(),
          vehicleName: 'Standard Sedan',
          pickupAddress: '456 Business District, Johannesburg, South Africa',
          dropoffAddress: '789 Shopping Mall, Johannesburg, South Africa',
          pickupLocation: {
            address: '456 Business District, Johannesburg, South Africa',
            coordinates: {
              latitude: -26.2041,
              longitude: 28.0473
            },
            city: 'Johannesburg',
            province: 'Gauteng',
            postalCode: '2000',
            instructions: 'Wait at the main entrance',
            contactPhone: '+27987654321',
            landmark: 'Near the bank',
            buildingName: 'Business Tower',
            floor: '10th Floor',
            unit: 'Suite 1001'
          },
          dropoffLocation: {
            address: '789 Shopping Mall, Johannesburg, South Africa',
            coordinates: {
              latitude: -26.2050,
              longitude: 28.0480
            },
            city: 'Johannesburg',
            province: 'Gauteng',
            postalCode: '2001',
            instructions: 'Drop off at the main entrance',
            contactPhone: '+27987654322',
            landmark: 'Shopping mall entrance',
            buildingName: 'City Shopping Mall',
            floor: 'Ground Floor',
            unit: 'Main Entrance'
          },
          vehicleType: 'sedan',
          serviceType: 'standard',
          passengerCount: 1,
          luggageCount: 0,
          pickupTime: new Date(Date.now() + 4 * 60 * 60 * 1000), // 4 hours from now
          scheduledDate: new Date(Date.now() + 4 * 60 * 60 * 1000),
          isFlexibleTime: true,
          flexibleWindow: 30,
          basePrice: 120.00,
          finalPrice: 140.00,
          pricing: {
            baseFare: 40.00,
            distanceFare: 60.00,
            timeFare: 20.00,
            serviceFee: 10.00,
            taxes: 15.00,
            discount: 5.00,
            loyaltyDiscount: 0.00,
            surgeMultiplier: 1.0,
            waitingFee: 0.00,
            cancellationFee: 0.00,
            total: 140.00,
            currency: 'ZAR'
          },
          status: 'pending',
          statusHistory: [
            {
              status: 'pending',
              timestamp: new Date(Date.now() - 15 * 60 * 1000),
              notes: 'Booking created',
              correlationId: 'corr_003',
              updatedBy: 'user',
              location: {
                latitude: -26.2041,
                longitude: 28.0473,
                address: '456 Business District, Johannesburg, South Africa'
              },
              estimatedTimeToNext: 60,
              reason: 'Initial booking creation'
            }
          ],
          paymentMethod: 'wallet',
          paymentStatus: 'pending',
          specialNotes: 'Customer prefers non-smoking vehicle',
          closeProtectionOfficer: false,
          customerNotes: 'Regular customer',
          emergency: {
            emergencyContact: {
              name: 'Mike Johnson',
              phone: '+27987654321',
              relationship: 'friend'
            },
            safetyCheckCompleted: false,
            safetyCheckTimestamp: null,
            safetyNotes: '',
            incidentReport: {
              hasIncident: false,
              incidentType: '',
              description: '',
              reportedAt: null,
              reportedBy: '',
              severity: 'low'
            }
          },
          notificationsSent: [],
          source: 'web',
          deviceInfo: {
            platform: 'web',
            version: '2.0.0',
            userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            ipAddress: '192.168.1.101'
          },
          analytics: {
            bookingSource: 'referral',
            referralCode: 'REF456',
            campaignId: 'business_travel',
            utmSource: 'facebook',
            utmMedium: 'social',
            utmCampaign: 'business_promotion'
          },
          termsAccepted: true,
          termsAcceptedAt: new Date(Date.now() - 20 * 60 * 1000),
          privacyPolicyAccepted: true,
          privacyPolicyAcceptedAt: new Date(Date.now() - 20 * 60 * 1000),
          qualityCheck: {
            completed: false,
            checkedAt: null,
            checkedBy: '',
            score: null,
            notes: ''
          }
        },
        {
          bookingId: 'BK' + (Date.now() + 2).toString(36).slice(-4).toUpperCase(),
          userId: new mongoose.Types.ObjectId(),
          driverId: new mongoose.Types.ObjectId(),
          vehicleId: new mongoose.Types.ObjectId(),
          vehicleName: 'Premium SUV',
          driverName: 'John Driver',
          driverPhone: '+27111222333',
          driverPhotoUrl: 'https://example.com/driver-photo.jpg',
          pickupAddress: '321 Corporate Office, Durban, South Africa',
          dropoffAddress: '654 Hotel District, Durban, South Africa',
          pickupLocation: {
            address: '321 Corporate Office, Durban, South Africa',
            coordinates: {
              latitude: -29.8587,
              longitude: 31.0218
            },
            city: 'Durban',
            province: 'KwaZulu-Natal',
            postalCode: '4000',
            instructions: 'Wait at the corporate entrance',
            contactPhone: '+27345678901',
            landmark: 'Near the convention center',
            buildingName: 'Corporate Plaza',
            floor: '15th Floor',
            unit: 'Suite 1501'
          },
          dropoffLocation: {
            address: '654 Hotel District, Durban, South Africa',
            coordinates: {
              latitude: -29.8590,
              longitude: 31.0220
            },
            city: 'Durban',
            province: 'KwaZulu-Natal',
            postalCode: '4001',
            instructions: 'Drop off at hotel lobby',
            contactPhone: '+27345678902',
            landmark: 'Hotel entrance',
            buildingName: 'Grand Hotel',
            floor: 'Ground Floor',
            unit: 'Main Lobby'
          },
          vehicleType: 'suv',
          serviceType: 'corporate',
          passengerCount: 3,
          luggageCount: 2,
          pickupTime: new Date(Date.now() - 2 * 60 * 60 * 1000), // 2 hours ago
          actualPickupTime: new Date(Date.now() - 1.5 * 60 * 60 * 1000),
          actualDropoffTime: new Date(Date.now() - 30 * 60 * 1000),
          scheduledDate: new Date(Date.now() - 2 * 60 * 60 * 1000),
          isFlexibleTime: false,
          flexibleWindow: 15,
          basePrice: 280.00,
          finalPrice: 320.00,
          pricing: {
            baseFare: 80.00,
            distanceFare: 180.00,
            timeFare: 30.00,
            serviceFee: 15.00,
            taxes: 25.00,
            discount: 0.00,
            loyaltyDiscount: 10.00,
            surgeMultiplier: 1.0,
            waitingFee: 5.00,
            cancellationFee: 0.00,
            total: 320.00,
            currency: 'ZAR'
          },
          tripDetails: {
            estimatedDistance: 25.5,
            estimatedDuration: 45,
            actualDistance: 27.2,
            actualDuration: 48,
            route: [
              {
                latitude: -29.8587,
                longitude: 31.0218,
                timestamp: new Date(Date.now() - 1.5 * 60 * 60 * 1000),
                speed: 0,
                heading: 0,
                accuracy: 5
              },
              {
                latitude: -29.8590,
                longitude: 31.0220,
                timestamp: new Date(Date.now() - 30 * 60 * 1000),
                speed: 0,
                heading: 0,
                accuracy: 5
              }
            ],
            startTime: new Date(Date.now() - 1.5 * 60 * 60 * 1000),
            endTime: new Date(Date.now() - 30 * 60 * 1000),
            waitingTime: 5,
            trafficConditions: 'moderate',
            weatherConditions: 'clear',
            routeOptimized: true,
            alternativeRoutes: [
              {
                distance: 28.5,
                duration: 52,
                reason: 'Heavy traffic on main route'
              }
            ],
            maxSpeed: 65,
            averageSpeed: 35,
            harshBraking: 0,
            harshAcceleration: 1,
            fuelConsumed: 2.1,
            carbonFootprint: 4.2,
            efficiency: 12.9
          },
          status: 'completed',
          statusHistory: [
            {
              status: 'pending',
              timestamp: new Date(Date.now() - 3 * 60 * 60 * 1000),
              notes: 'Booking created',
              correlationId: 'corr_004',
              updatedBy: 'user',
              location: {
                latitude: -29.8587,
                longitude: 31.0218,
                address: '321 Corporate Office, Durban, South Africa'
              },
              estimatedTimeToNext: 30,
              reason: 'Initial booking creation'
            },
            {
              status: 'confirmed',
              timestamp: new Date(Date.now() - 2.5 * 60 * 60 * 1000),
              notes: 'Booking confirmed',
              correlationId: 'corr_005',
              updatedBy: 'system',
              location: {
                latitude: -29.8587,
                longitude: 31.0218,
                address: '321 Corporate Office, Durban, South Africa'
              },
              estimatedTimeToNext: 120,
              reason: 'System confirmation'
            },
            {
              status: 'driverAssigned',
              timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000),
              notes: 'Driver assigned',
              correlationId: 'corr_006',
              updatedBy: 'system',
              location: {
                latitude: -29.8587,
                longitude: 31.0218,
                address: '321 Corporate Office, Durban, South Africa'
              },
              estimatedTimeToNext: 60,
              reason: 'Driver assignment'
            },
            {
              status: 'driverEnRoute',
              timestamp: new Date(Date.now() - 1.8 * 60 * 60 * 1000),
              notes: 'Driver en route',
              correlationId: 'corr_007',
              updatedBy: 'driver',
              location: {
                latitude: -29.8590,
                longitude: 31.0220,
                address: '654 Hotel District, Durban, South Africa'
              },
              estimatedTimeToNext: 20,
              reason: 'Driver started trip'
            },
            {
              status: 'driverArrived',
              timestamp: new Date(Date.now() - 1.6 * 60 * 60 * 1000),
              notes: 'Driver arrived',
              correlationId: 'corr_008',
              updatedBy: 'driver',
              location: {
                latitude: -29.8587,
                longitude: 31.0218,
                address: '321 Corporate Office, Durban, South Africa'
              },
              estimatedTimeToNext: 5,
              reason: 'Driver arrived at pickup'
            },
            {
              status: 'inProgress',
              timestamp: new Date(Date.now() - 1.5 * 60 * 60 * 1000),
              notes: 'Trip in progress',
              correlationId: 'corr_009',
              updatedBy: 'driver',
              location: {
                latitude: -29.8587,
                longitude: 31.0218,
                address: '321 Corporate Office, Durban, South Africa'
              },
              estimatedTimeToNext: 45,
              reason: 'Trip started'
            },
            {
              status: 'completed',
              timestamp: new Date(Date.now() - 30 * 60 * 1000),
              notes: 'Trip completed',
              correlationId: 'corr_010',
              updatedBy: 'driver',
              location: {
                latitude: -29.8590,
                longitude: 31.0220,
                address: '654 Hotel District, Durban, South Africa'
              },
              estimatedTimeToNext: 0,
              reason: 'Trip completed successfully'
            }
          ],
          assignedAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
          driverAcceptedAt: new Date(Date.now() - 1.9 * 60 * 60 * 1000),
          driverArrivedAt: new Date(Date.now() - 1.6 * 60 * 60 * 1000),
          tripStartedAt: new Date(Date.now() - 1.5 * 60 * 60 * 1000),
          tripCompletedAt: new Date(Date.now() - 30 * 60 * 1000),
          paymentMethod: 'corporate',
          paymentStatus: 'paid',
          paymentMethodId: 'pm_corp_123',
          paymentId: 'pi_corp_456',
          paidAt: new Date(Date.now() - 25 * 60 * 1000),
          specialNotes: 'Corporate client - VIP service required',
          closeProtectionOfficer: true,
          customerNotes: 'VIP client with security requirements',
          isCorporateBooking: true,
          corporateAccountId: 'corp_789',
          corporateApprovalRequired: false,
          corporateApprovedAt: new Date(Date.now() - 2.8 * 60 * 60 * 1000),
          corporateApprovedBy: 'corporate_admin',
          emergency: {
            emergencyContact: {
              name: 'Sarah Wilson',
              phone: '+27345678901',
              relationship: 'assistant'
            },
            safetyCheckCompleted: true,
            safetyCheckTimestamp: new Date(Date.now() - 1.4 * 60 * 60 * 1000),
            safetyNotes: 'All safety checks completed for corporate client',
            incidentReport: {
              hasIncident: false,
              incidentType: '',
              description: '',
              reportedAt: null,
              reportedBy: '',
              severity: 'low'
            }
          },
          notificationsSent: [
            {
              type: 'booking_confirmed',
              sentAt: new Date(Date.now() - 2.5 * 60 * 60 * 1000),
              status: 'delivered',
              recipient: 'user',
              method: 'push',
              content: 'Your corporate booking has been confirmed'
            },
            {
              type: 'driver_assigned',
              sentAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
              status: 'delivered',
              recipient: 'user',
              method: 'push',
              content: 'Driver John Driver has been assigned to your booking'
            },
            {
              type: 'driver_en_route',
              sentAt: new Date(Date.now() - 1.8 * 60 * 60 * 1000),
              status: 'delivered',
              recipient: 'user',
              method: 'push',
              content: 'Your driver is en route to the pickup location'
            },
            {
              type: 'driver_arrived',
              sentAt: new Date(Date.now() - 1.6 * 60 * 60 * 1000),
              status: 'delivered',
              recipient: 'user',
              method: 'push',
              content: 'Your driver has arrived at the pickup location'
            },
            {
              type: 'trip_started',
              sentAt: new Date(Date.now() - 1.5 * 60 * 60 * 1000),
              status: 'delivered',
              recipient: 'user',
              method: 'push',
              content: 'Your trip has started'
            },
            {
              type: 'trip_completed',
              sentAt: new Date(Date.now() - 30 * 60 * 1000),
              status: 'delivered',
              recipient: 'user',
              method: 'push',
              content: 'Your trip has been completed successfully'
            },
            {
              type: 'payment_confirmed',
              sentAt: new Date(Date.now() - 25 * 60 * 1000),
              status: 'delivered',
              recipient: 'user',
              method: 'push',
              content: 'Payment has been processed successfully'
            }
          ],
          rating: 5,
          review: 'Excellent service! Professional driver and comfortable vehicle.',
          driverRating: {
            rating: 5,
            review: 'Excellent service! Professional driver and comfortable vehicle.',
            categories: {
              cleanliness: 5,
              punctuality: 5,
              friendliness: 5,
              driving: 5,
              vehicleCondition: 5,
              communication: 5
            },
            tags: ['excellent', 'professional', 'safe', 'clean', 'punctual'],
            submittedAt: new Date(Date.now() - 20 * 60 * 1000),
            isAnonymous: false
          },
          source: 'app',
          deviceInfo: {
            platform: 'android',
            version: '1.1.5',
            userAgent: 'SwiftLyft/1.1.5 (Android; API 30)',
            ipAddress: '192.168.1.102'
          },
          analytics: {
            bookingSource: 'corporate_portal',
            referralCode: '',
            campaignId: 'corporate_package',
            utmSource: 'corporate',
            utmMedium: 'portal',
            utmCampaign: 'vip_service'
          },
          termsAccepted: true,
          termsAcceptedAt: new Date(Date.now() - 3.5 * 60 * 60 * 1000),
          privacyPolicyAccepted: true,
          privacyPolicyAcceptedAt: new Date(Date.now() - 3.5 * 60 * 60 * 1000),
          qualityCheck: {
            completed: true,
            checkedAt: new Date(Date.now() - 10 * 60 * 1000),
            checkedBy: 'quality_team',
            score: 98,
            notes: 'Exceptional service quality for corporate client'
          }
        }
      ];

      // Create bookings
      for (const bookingData of sampleBookings) {
        const booking = new Booking(bookingData);
        await booking.save();
        console.log(`✅ Created booking: ${booking.bookingId}`);
      }

      console.log('🎉 Bookings sample data created successfully!');
    } catch (error) {
      console.error('❌ Error creating Bookings sample data:', error);
      throw error;
    }
  }

  // Run database health check
  async healthCheck() {
    try {
      console.log('🏥 Running Bookings database health check...');

      // Check connection
      if (!this.connection) {
        throw new Error('No database connection');
      }

      // Check database stats
      const stats = await this.connection.connection.db.stats();
      console.log(`📊 Database size: ${(stats.dataSize / 1024 / 1024).toFixed(2)} MB`);
      console.log(`📊 Collections: ${stats.collections}`);
      console.log(`📊 Documents: ${stats.objects || 0}`);

      // Check Bookings collection stats
      const bookingCount = await Booking.countDocuments();
      const activeBookings = await Booking.countDocuments({
        status: { $in: ['confirmed', 'driverAssigned', 'driverEnRoute', 'driverArrived', 'inProgress'] }
      });
      const completedBookings = await Booking.countDocuments({ status: 'completed' });
      const cancelledBookings = await Booking.countDocuments({ status: 'cancelled' });
      const pendingBookings = await Booking.countDocuments({ status: 'pending' });

      console.log(`📊 Total bookings: ${bookingCount}`);
      console.log(`📊 Active bookings: ${activeBookings}`);
      console.log(`📊 Completed bookings: ${completedBookings}`);
      console.log(`📊 Cancelled bookings: ${cancelledBookings}`);
      console.log(`📊 Pending bookings: ${pendingBookings}`);

      // Check indexes
      const indexes = await Booking.collection.getIndexes();
      console.log(`🔍 Indexes: ${Object.keys(indexes).length}`);

      // Check vehicle type distribution
      const vehicleTypeStats = await Booking.aggregate([
        { $group: { _id: '$vehicleType', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]);

      console.log('\n🚗 Vehicle Type Distribution:');
      vehicleTypeStats.forEach(stat => {
        console.log(`  ${stat._id}: ${stat.count}`);
      });

      // Check service type distribution
      const serviceTypeStats = await Booking.aggregate([
        { $group: { _id: '$serviceType', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]);

      console.log('\n🎯 Service Type Distribution:');
      serviceTypeStats.forEach(stat => {
        console.log(`  ${stat._id}: ${stat.count}`);
      });

      // Check payment method distribution
      const paymentMethodStats = await Booking.aggregate([
        { $group: { _id: '$paymentMethod', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]);

      console.log('\n💳 Payment Method Distribution:');
      paymentMethodStats.forEach(stat => {
        console.log(`  ${stat._id}: ${stat.count}`);
      });

      // Check average rating
      const ratingStats = await Booking.aggregate([
        { $match: { rating: { $exists: true, $ne: null } } },
        { $group: { _id: null, avgRating: { $avg: '$rating' }, totalRatings: { $sum: 1 } } }
      ]);

      if (ratingStats.length > 0) {
        console.log(`\n⭐ Average Rating: ${ratingStats[0].avgRating.toFixed(2)} (${ratingStats[0].totalRatings} ratings)`);
      }

      // Check total revenue
      const revenueStats = await Booking.aggregate([
        { $match: { status: 'completed' } },
        { $group: { _id: null, totalRevenue: { $sum: '$finalPrice' } } }
      ]);

      if (revenueStats.length > 0) {
        console.log(`\n💰 Total Revenue: R${revenueStats[0].totalRevenue.toLocaleString()}`);
      }

      console.log('🎉 Bookings health check completed successfully!');
      return true;
    } catch (error) {
      console.error('❌ Bookings database health check failed:', error);
      return false;
    }
  }

  // Close database connection
  async close() {
    try {
      if (this.connection) {
        await mongoose.connection.close();
        console.log('✅ Bookings database connection closed');
      }
    } catch (error) {
      console.error('❌ Error closing Bookings database connection:', error);
    }
  }

  // Full database setup
  async setup(options = {}) {
    const {
      createIndexes = true,
      validateSchema = true,
      createSampleData = false,
      runHealthCheck = true
    } = options;

    try {
      console.log('🚀 Starting Bookings database setup...');

      // Connect to database
      await this.connect();

      // Create indexes
      if (createIndexes) {
        await this.createIndexes();
      }

      // Validate schema
      if (validateSchema) {
        await this.validateSchema();
      }

      // Create sample data
      if (createSampleData) {
        await this.createSampleData();
      }

      // Run health check
      if (runHealthCheck) {
        await this.healthCheck();
      }

      console.log('🎉 Bookings database setup completed successfully!');
    } catch (error) {
      console.error('❌ Bookings database setup failed:', error);
      throw error;
    }
  }
}

// CLI interface
if (require.main === module) {
  const args = process.argv.slice(2);
  const options = {};

  // Parse command line arguments
  if (args.includes('--sample-data')) {
    options.createSampleData = true;
  }
  if (args.includes('--no-indexes')) {
    options.createIndexes = false;
  }
  if (args.includes('--no-validation')) {
    options.validateSchema = false;
  }
  if (args.includes('--no-health-check')) {
    options.runHealthCheck = false;
  }

  const bookingsSetup = new BookingsDatabaseSetup();
  
  bookingsSetup.setup(options)
    .then(() => {
      console.log('✅ Bookings setup completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Bookings setup failed:', error);
      process.exit(1);
    });
}

module.exports = BookingsDatabaseSetup;
