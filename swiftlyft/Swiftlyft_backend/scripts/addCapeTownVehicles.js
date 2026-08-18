const mongoose = require('mongoose');
const Vehicle = require('../models/Vehicle');
require('dotenv').config();

/**
 * Script to add Cape Town vehicles to the database
 * Usage: node scripts/addCapeTownVehicles.js [--clear-existing]
 */

class CapeTownVehicleSeeder {
  constructor() {
    this.connection = null;
  }

  async connect() {
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft';
    this.connection = await mongoose.connect(mongoUri, {
      useNewUrlParser: true,
      useUnifiedTopology: true
    });
    console.log('✅ Connected to MongoDB');
    console.log(`📊 Database: ${mongoose.connection.name}`);
  }

  async disconnect() {
    if (this.connection) {
      await mongoose.disconnect();
      console.log('✅ Disconnected from MongoDB');
    }
  }

  // Get or create a dummy driver ID for vehicles
  async getDummyDriverId() {
    try {
      const Driver = require('../models/Driver');
      // Try to find an existing driver
      const existingDriver = await Driver.findOne();
      if (existingDriver) {
        return existingDriver._id;
      }
      // Create a dummy ObjectId if no drivers exist
      return new mongoose.Types.ObjectId();
    } catch (e) {
      // If Driver model doesn't exist or has issues, use a dummy ID
      return new mongoose.Types.ObjectId();
    }
  }

  async seedCapeTownVehicles({ clearExisting = false } = {}) {
    try {
      // Clear existing Cape Town vehicles if requested
      if (clearExisting) {
        console.log('🗑️  Clearing existing Cape Town vehicles...');
        const deleted = await Vehicle.deleteMany({
          'currentLocation.city': 'Cape Town'
        });
        console.log(`   Deleted ${deleted.deletedCount} vehicles`);
      }

      const driverId = await this.getDummyDriverId();
      const now = new Date();
      
      // Cape Town coordinates
      const capeTownLat = -33.9249;
      const capeTownLng = 18.4241;

      const vehicles = [
        // LUXURY SEDANS (category: 'sedan')
        {
          vehicleId: `CPT-LUX-SED-${Date.now().toString(36).slice(-4)}`,
          driverId: driverId,
          name: 'Mercedes-Benz S-Class',
          description: 'Premium luxury sedan with advanced comfort features and cutting-edge technology',
          make: 'Mercedes-Benz',
          model: 'S-Class',
          year: 2023,
          color: 'Obsidian Black',
          licensePlate: `CPT${Math.random().toString(36).substring(2, 6).toUpperCase()}`,
          category: 'sedan',
          subcategory: 'executive',
          passengerCapacity: 4,
          luggageCapacity: 2,
          seatingCapacity: 4,
          engineType: 'petrol',
          transmission: 'automatic',
          basePrice: 450,
          imageUrl: '',
          imageGallery: [],
          features: ['Leather Interior', 'Wi-Fi', 'Climate Control', 'Premium Audio', 'Massage Seats', 'Ambient Lighting'],
          badges: ['Top Choice'],
          specifications: {
            Engine: '3.0L V6',
            Transmission: '9-Speed Automatic',
            FuelType: 'Petrol'
          },
          currentLocation: {
            address: 'Cape Town City Centre, Western Cape',
            coordinates: {
              latitude: capeTownLat + (Math.random() * 0.02 - 0.01),
              longitude: capeTownLng + (Math.random() * 0.02 - 0.01)
            },
            city: 'Cape Town',
            province: 'Western Cape'
          },
          pricing: {
            baseFare: 450,
            perKmRate: 12,
            perMinuteRate: 1.5,
            minimumFare: 300,
            currency: 'ZAR'
          },
          availability: {
            isAvailable: true,
            workingHours: { start: '06:00', end: '23:00' },
            operatingDays: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
          },
          status: 'available',
          performance: {
            rating: 4.8,
            totalTrips: 156,
            averageRating: 4.8
          }
        },
        {
          vehicleId: `CPT-LUX-SED-${Date.now().toString(36).slice(-5)}`,
          driverId: driverId,
          name: 'BMW 7 Series',
          description: 'Executive luxury sedan with cutting-edge technology and premium comfort',
          make: 'BMW',
          model: '7 Series',
          year: 2024,
          color: 'Mineral White',
          licensePlate: `CPT${Math.random().toString(36).substring(2, 6).toUpperCase()}`,
          category: 'sedan',
          subcategory: 'executive',
          passengerCapacity: 4,
          luggageCapacity: 2,
          seatingCapacity: 4,
          engineType: 'petrol',
          transmission: 'automatic',
          basePrice: 420,
          imageUrl: '',
          imageGallery: [],
          features: ['Leather Interior', 'Wi-Fi', 'Climate Control', 'Premium Audio', 'Massage Seats'],
          badges: ['Popular'],
          specifications: {
            Engine: '4.4L V8',
            Transmission: '8-Speed Automatic',
            FuelType: 'Petrol'
          },
          currentLocation: {
            address: 'Cape Town City Centre, Western Cape',
            coordinates: {
              latitude: capeTownLat + (Math.random() * 0.02 - 0.01),
              longitude: capeTownLng + (Math.random() * 0.02 - 0.01)
            },
            city: 'Cape Town',
            province: 'Western Cape'
          },
          pricing: {
            baseFare: 420,
            perKmRate: 11.5,
            perMinuteRate: 1.4,
            minimumFare: 280,
            currency: 'ZAR'
          },
          availability: {
            isAvailable: true,
            workingHours: { start: '06:00', end: '23:00' },
            operatingDays: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
          },
          status: 'available',
          performance: {
            rating: 4.7,
            totalTrips: 132,
            averageRating: 4.7
          }
        },
        {
          vehicleId: `CPT-LUX-SED-${Date.now().toString(36).slice(-6)}`,
          driverId: driverId,
          name: 'Audi A8',
          description: 'Luxurious full-size sedan with Quattro all-wheel drive and premium amenities',
          make: 'Audi',
          model: 'A8',
          year: 2023,
          color: 'Florett Silver',
          licensePlate: `CPT${Math.random().toString(36).substring(2, 6).toUpperCase()}`,
          category: 'sedan',
          subcategory: 'executive',
          passengerCapacity: 4,
          luggageCapacity: 2,
          seatingCapacity: 4,
          engineType: 'petrol',
          transmission: 'automatic',
          basePrice: 400,
          imageUrl: '',
          imageGallery: [],
          features: ['Leather Interior', 'Wi-Fi', 'Climate Control', 'Premium Audio'],
          badges: [],
          specifications: {
            Engine: '3.0L V6',
            Transmission: '8-Speed Automatic',
            FuelType: 'Petrol'
          },
          currentLocation: {
            address: 'Cape Town City Centre, Western Cape',
            coordinates: {
              latitude: capeTownLat + (Math.random() * 0.02 - 0.01),
              longitude: capeTownLng + (Math.random() * 0.02 - 0.01)
            },
            city: 'Cape Town',
            province: 'Western Cape'
          },
          pricing: {
            baseFare: 400,
            perKmRate: 11,
            perMinuteRate: 1.3,
            minimumFare: 270,
            currency: 'ZAR'
          },
          availability: {
            isAvailable: true,
            workingHours: { start: '06:00', end: '23:00' },
            operatingDays: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
          },
          status: 'available',
          performance: {
            rating: 4.6,
            totalTrips: 98,
            averageRating: 4.6
          }
        },

        // SUVs (category: 'suv')
        {
          vehicleId: `CPT-SUV-${Date.now().toString(36).slice(-4)}`,
          driverId: driverId,
          name: 'Range Rover Sport',
          description: 'Luxury SUV perfect for family trips and business travel with superior comfort',
          make: 'Land Rover',
          model: 'Range Rover Sport',
          year: 2023,
          color: 'Santorini Black',
          licensePlate: `CPT${Math.random().toString(36).substring(2, 6).toUpperCase()}`,
          category: 'suv',
          subcategory: 'premium',
          passengerCapacity: 6,
          luggageCapacity: 4,
          seatingCapacity: 6,
          engineType: 'petrol',
          transmission: 'automatic',
          basePrice: 550,
          imageUrl: '',
          imageGallery: [],
          features: ['Leather Interior', 'Wi-Fi', 'Climate Control', 'Premium Audio', 'All-Wheel Drive'],
          badges: ['Popular'],
          specifications: {
            Engine: '5.0L V8',
            Transmission: '8-Speed Automatic',
            FuelType: 'Petrol'
          },
          currentLocation: {
            address: 'Cape Town City Centre, Western Cape',
            coordinates: {
              latitude: capeTownLat + (Math.random() * 0.02 - 0.01),
              longitude: capeTownLng + (Math.random() * 0.02 - 0.01)
            },
            city: 'Cape Town',
            province: 'Western Cape'
          },
          pricing: {
            baseFare: 550,
            perKmRate: 13,
            perMinuteRate: 1.6,
            minimumFare: 350,
            currency: 'ZAR'
          },
          availability: {
            isAvailable: true,
            workingHours: { start: '06:00', end: '23:00' },
            operatingDays: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
          },
          status: 'available',
          performance: {
            rating: 4.6,
            totalTrips: 98,
            averageRating: 4.6
          }
        },
        {
          vehicleId: `CPT-SUV-${Date.now().toString(36).slice(-5)}`,
          driverId: driverId,
          name: 'Audi Q7',
          description: 'Spacious luxury SUV with premium amenities and seven-seat capability',
          make: 'Audi',
          model: 'Q7',
          year: 2023,
          color: 'Nardo Gray',
          licensePlate: `CPT${Math.random().toString(36).substring(2, 6).toUpperCase()}`,
          category: 'suv',
          subcategory: 'premium',
          passengerCapacity: 6,
          luggageCapacity: 4,
          seatingCapacity: 6,
          engineType: 'diesel',
          transmission: 'automatic',
          basePrice: 500,
          imageUrl: '',
          imageGallery: [],
          features: ['Leather Interior', 'Wi-Fi', 'Climate Control', 'Premium Audio'],
          badges: [],
          specifications: {
            Engine: '3.0L V6 Diesel',
            Transmission: '8-Speed Automatic',
            FuelType: 'Diesel'
          },
          currentLocation: {
            address: 'Cape Town City Centre, Western Cape',
            coordinates: {
              latitude: capeTownLat + (Math.random() * 0.02 - 0.01),
              longitude: capeTownLng + (Math.random() * 0.02 - 0.01)
            },
            city: 'Cape Town',
            province: 'Western Cape'
          },
          pricing: {
            baseFare: 500,
            perKmRate: 12.5,
            perMinuteRate: 1.5,
            minimumFare: 330,
            currency: 'ZAR'
          },
          availability: {
            isAvailable: true,
            workingHours: { start: '06:00', end: '23:00' },
            operatingDays: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
          },
          status: 'available',
          performance: {
            rating: 4.5,
            totalTrips: 87,
            averageRating: 4.5
          }
        },
        {
          vehicleId: `CPT-SUV-${Date.now().toString(36).slice(-6)}`,
          driverId: driverId,
          name: 'BMW X5',
          description: 'Premium SUV combining performance, luxury, and practicality',
          make: 'BMW',
          model: 'X5',
          year: 2024,
          color: 'Phytonic Blue',
          licensePlate: `CPT${Math.random().toString(36).substring(2, 6).toUpperCase()}`,
          category: 'suv',
          subcategory: 'premium',
          passengerCapacity: 5,
          luggageCapacity: 3,
          seatingCapacity: 5,
          engineType: 'petrol',
          transmission: 'automatic',
          basePrice: 480,
          imageUrl: '',
          imageGallery: [],
          features: ['Leather Interior', 'Wi-Fi', 'Climate Control', 'Premium Audio'],
          badges: [],
          specifications: {
            Engine: '3.0L Inline-6',
            Transmission: '8-Speed Automatic',
            FuelType: 'Petrol'
          },
          currentLocation: {
            address: 'Cape Town City Centre, Western Cape',
            coordinates: {
              latitude: capeTownLat + (Math.random() * 0.02 - 0.01),
              longitude: capeTownLng + (Math.random() * 0.02 - 0.01)
            },
            city: 'Cape Town',
            province: 'Western Cape'
          },
          pricing: {
            baseFare: 480,
            perKmRate: 12,
            perMinuteRate: 1.4,
            minimumFare: 320,
            currency: 'ZAR'
          },
          availability: {
            isAvailable: true,
            workingHours: { start: '06:00', end: '23:00' },
            operatingDays: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
          },
          status: 'available',
          performance: {
            rating: 4.7,
            totalTrips: 112,
            averageRating: 4.7
          }
        },

        // LUXURY VANS (category: 'van')
        {
          vehicleId: `CPT-VAN-${Date.now().toString(36).slice(-4)}`,
          driverId: driverId,
          name: 'Mercedes-Benz V-Class',
          description: 'Premium luxury van ideal for group travel and corporate events',
          make: 'Mercedes-Benz',
          model: 'V-Class',
          year: 2023,
          color: 'Obsidian Black',
          licensePlate: `CPT${Math.random().toString(36).substring(2, 6).toUpperCase()}`,
          category: 'van',
          subcategory: 'executive',
          passengerCapacity: 7,
          luggageCapacity: 5,
          seatingCapacity: 7,
          engineType: 'diesel',
          transmission: 'automatic',
          basePrice: 650,
          imageUrl: '',
          imageGallery: [],
          features: ['Leather Interior', 'Wi-Fi', 'Climate Control', 'Premium Audio', 'Massage Seats'],
          badges: ['Top Choice'],
          specifications: {
            Engine: '2.0L Diesel',
            Transmission: '9-Speed Automatic',
            FuelType: 'Diesel'
          },
          currentLocation: {
            address: 'Cape Town City Centre, Western Cape',
            coordinates: {
              latitude: capeTownLat + (Math.random() * 0.02 - 0.01),
              longitude: capeTownLng + (Math.random() * 0.02 - 0.01)
            },
            city: 'Cape Town',
            province: 'Western Cape'
          },
          pricing: {
            baseFare: 650,
            perKmRate: 14,
            perMinuteRate: 1.8,
            minimumFare: 400,
            currency: 'ZAR'
          },
          availability: {
            isAvailable: true,
            workingHours: { start: '06:00', end: '23:00' },
            operatingDays: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
          },
          status: 'available',
          performance: {
            rating: 4.7,
            totalTrips: 64,
            averageRating: 4.7
          }
        },
        {
          vehicleId: `CPT-VAN-${Date.now().toString(36).slice(-5)}`,
          driverId: driverId,
          name: 'Toyota Alphard',
          description: 'Executive luxury van with spacious interior and premium features',
          make: 'Toyota',
          model: 'Alphard',
          year: 2023,
          color: 'Pearl White',
          licensePlate: `CPT${Math.random().toString(36).substring(2, 6).toUpperCase()}`,
          category: 'van',
          subcategory: 'executive',
          passengerCapacity: 6,
          luggageCapacity: 4,
          seatingCapacity: 6,
          engineType: 'petrol',
          transmission: 'automatic',
          basePrice: 580,
          imageUrl: '',
          imageGallery: [],
          features: ['Leather Interior', 'Wi-Fi', 'Climate Control', 'Premium Audio'],
          badges: [],
          specifications: {
            Engine: '3.5L V6',
            Transmission: '8-Speed CVT',
            FuelType: 'Petrol'
          },
          currentLocation: {
            address: 'Cape Town City Centre, Western Cape',
            coordinates: {
              latitude: capeTownLat + (Math.random() * 0.02 - 0.01),
              longitude: capeTownLng + (Math.random() * 0.02 - 0.01)
            },
            city: 'Cape Town',
            province: 'Western Cape'
          },
          pricing: {
            baseFare: 580,
            perKmRate: 13.5,
            perMinuteRate: 1.7,
            minimumFare: 380,
            currency: 'ZAR'
          },
          availability: {
            isAvailable: true,
            workingHours: { start: '06:00', end: '23:00' },
            operatingDays: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
          },
          status: 'available',
          performance: {
            rating: 4.6,
            totalTrips: 52,
            averageRating: 4.6
          }
        },

        // SPORTS CARS (category: 'luxury')
        {
          vehicleId: `CPT-SPORTS-${Date.now().toString(36).slice(-4)}`,
          driverId: driverId,
          name: 'Porsche 911',
          description: 'Iconic sports car for thrilling rides with legendary performance',
          make: 'Porsche',
          model: '911',
          year: 2024,
          color: 'Guards Red',
          licensePlate: `CPT${Math.random().toString(36).substring(2, 6).toUpperCase()}`,
          category: 'luxury',
          subcategory: 'premium',
          passengerCapacity: 1,
          luggageCapacity: 1,
          seatingCapacity: 2,
          engineType: 'petrol',
          transmission: 'automatic',
          basePrice: 750,
          imageUrl: '',
          imageGallery: [],
          features: ['Leather Interior', 'Premium Audio', 'Sport Mode'],
          badges: ['Top Choice'],
          specifications: {
            Engine: '3.0L Flat-6 Turbo',
            Transmission: '8-Speed PDK',
            FuelType: 'Petrol'
          },
          currentLocation: {
            address: 'Cape Town City Centre, Western Cape',
            coordinates: {
              latitude: capeTownLat + (Math.random() * 0.02 - 0.01),
              longitude: capeTownLng + (Math.random() * 0.02 - 0.01)
            },
            city: 'Cape Town',
            province: 'Western Cape'
          },
          pricing: {
            baseFare: 750,
            perKmRate: 15,
            perMinuteRate: 2.0,
            minimumFare: 500,
            currency: 'ZAR'
          },
          availability: {
            isAvailable: true,
            workingHours: { start: '06:00', end: '23:00' },
            operatingDays: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
          },
          status: 'available',
          performance: {
            rating: 4.9,
            totalTrips: 45,
            averageRating: 4.9
          }
        },
        {
          vehicleId: `CPT-SPORTS-${Date.now().toString(36).slice(-5)}`,
          driverId: driverId,
          name: 'Audi R8',
          description: 'High-performance sports car with stunning design and V10 engine',
          make: 'Audi',
          model: 'R8',
          year: 2023,
          color: 'Vegas Yellow',
          licensePlate: `CPT${Math.random().toString(36).substring(2, 6).toUpperCase()}`,
          category: 'luxury',
          subcategory: 'premium',
          passengerCapacity: 1,
          luggageCapacity: 1,
          seatingCapacity: 2,
          engineType: 'petrol',
          transmission: 'automatic',
          basePrice: 720,
          imageUrl: '',
          imageGallery: [],
          features: ['Leather Interior', 'Premium Audio', 'Sport Mode'],
          badges: [],
          specifications: {
            Engine: '5.2L V10',
            Transmission: '7-Speed S-Tronic',
            FuelType: 'Petrol'
          },
          currentLocation: {
            address: 'Cape Town City Centre, Western Cape',
            coordinates: {
              latitude: capeTownLat + (Math.random() * 0.02 - 0.01),
              longitude: capeTownLng + (Math.random() * 0.02 - 0.01)
            },
            city: 'Cape Town',
            province: 'Western Cape'
          },
          pricing: {
            baseFare: 720,
            perKmRate: 14.5,
            perMinuteRate: 1.9,
            minimumFare: 480,
            currency: 'ZAR'
          },
          availability: {
            isAvailable: true,
            workingHours: { start: '06:00', end: '23:00' },
            operatingDays: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
          },
          status: 'available',
          performance: {
            rating: 4.8,
            totalTrips: 38,
            averageRating: 4.8
          }
        },

        // HYBRIDS (category: 'hybrid')
        {
          vehicleId: `CPT-HYBRID-${Date.now().toString(36).slice(-4)}`,
          driverId: driverId,
          name: 'Toyota Prius Hybrid',
          description: 'Eco-friendly hybrid vehicle perfect for city travel with excellent fuel economy',
          make: 'Toyota',
          model: 'Prius',
          year: 2023,
          color: 'Electric Storm Blue',
          licensePlate: `CPT${Math.random().toString(36).substring(2, 6).toUpperCase()}`,
          category: 'hybrid',
          subcategory: 'comfort',
          passengerCapacity: 4,
          luggageCapacity: 2,
          seatingCapacity: 4,
          engineType: 'hybrid',
          transmission: 'cvt',
          basePrice: 180,
          imageUrl: '',
          imageGallery: [],
          features: ['Wi-Fi', 'Climate Control', 'Eco Mode'],
          badges: ['Popular'],
          specifications: {
            Engine: '1.8L Hybrid',
            Transmission: 'CVT',
            FuelType: 'Hybrid'
          },
          currentLocation: {
            address: 'Cape Town City Centre, Western Cape',
            coordinates: {
              latitude: capeTownLat + (Math.random() * 0.02 - 0.01),
              longitude: capeTownLng + (Math.random() * 0.02 - 0.01)
            },
            city: 'Cape Town',
            province: 'Western Cape'
          },
          pricing: {
            baseFare: 180,
            perKmRate: 8,
            perMinuteRate: 0.8,
            minimumFare: 120,
            currency: 'ZAR'
          },
          availability: {
            isAvailable: true,
            workingHours: { start: '06:00', end: '23:00' },
            operatingDays: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
          },
          status: 'available',
          performance: {
            rating: 4.4,
            totalTrips: 201,
            averageRating: 4.4
          }
        },
        {
          vehicleId: `CPT-HYBRID-${Date.now().toString(36).slice(-5)}`,
          driverId: driverId,
          name: 'Lexus ES Hybrid',
          description: 'Luxury hybrid sedan combining comfort and efficiency',
          make: 'Lexus',
          model: 'ES Hybrid',
          year: 2023,
          color: 'Atomic Silver',
          licensePlate: `CPT${Math.random().toString(36).substring(2, 6).toUpperCase()}`,
          category: 'hybrid',
          subcategory: 'premium',
          passengerCapacity: 4,
          luggageCapacity: 2,
          seatingCapacity: 4,
          engineType: 'hybrid',
          transmission: 'cvt',
          basePrice: 350,
          imageUrl: '',
          imageGallery: [],
          features: ['Leather Interior', 'Wi-Fi', 'Climate Control', 'Premium Audio', 'Eco Mode'],
          badges: [],
          specifications: {
            Engine: '2.5L Hybrid',
            Transmission: 'CVT',
            FuelType: 'Hybrid'
          },
          currentLocation: {
            address: 'Cape Town City Centre, Western Cape',
            coordinates: {
              latitude: capeTownLat + (Math.random() * 0.02 - 0.01),
              longitude: capeTownLng + (Math.random() * 0.02 - 0.01)
            },
            city: 'Cape Town',
            province: 'Western Cape'
          },
          pricing: {
            baseFare: 350,
            perKmRate: 10,
            perMinuteRate: 1.2,
            minimumFare: 230,
            currency: 'ZAR'
          },
          availability: {
            isAvailable: true,
            workingHours: { start: '06:00', end: '23:00' },
            operatingDays: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
          },
          status: 'available',
          performance: {
            rating: 4.6,
            totalTrips: 167,
            averageRating: 4.6
          }
        },
        {
          vehicleId: `CPT-HYBRID-${Date.now().toString(36).slice(-6)}`,
          driverId: driverId,
          name: 'BMW 530e Hybrid',
          description: 'Executive hybrid sedan with premium features and plug-in capability',
          make: 'BMW',
          model: '530e',
          year: 2024,
          color: 'Bluestone Metallic',
          licensePlate: `CPT${Math.random().toString(36).substring(2, 6).toUpperCase()}`,
          category: 'hybrid',
          subcategory: 'executive',
          passengerCapacity: 4,
          luggageCapacity: 2,
          seatingCapacity: 4,
          engineType: 'hybrid',
          transmission: 'automatic',
          basePrice: 380,
          imageUrl: '',
          imageGallery: [],
          features: ['Leather Interior', 'Wi-Fi', 'Climate Control', 'Premium Audio', 'Eco Mode'],
          badges: [],
          specifications: {
            Engine: '2.0L Turbo Hybrid',
            Transmission: '8-Speed Automatic',
            FuelType: 'Hybrid'
          },
          currentLocation: {
            address: 'Cape Town City Centre, Western Cape',
            coordinates: {
              latitude: capeTownLat + (Math.random() * 0.02 - 0.01),
              longitude: capeTownLng + (Math.random() * 0.02 - 0.01)
            },
            city: 'Cape Town',
            province: 'Western Cape'
          },
          pricing: {
            baseFare: 380,
            perKmRate: 10.5,
            perMinuteRate: 1.3,
            minimumFare: 250,
            currency: 'ZAR'
          },
          availability: {
            isAvailable: true,
            workingHours: { start: '06:00', end: '23:00' },
            operatingDays: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
          },
          status: 'available',
          performance: {
            rating: 4.5,
            totalTrips: 124,
            averageRating: 4.5
          }
        }
      ];

      // Insert vehicles
      console.log(`🚗 Creating ${vehicles.length} Cape Town vehicles...`);
      const result = await Vehicle.insertMany(vehicles, { ordered: false });
      console.log(`✅ Successfully created ${result.length} vehicles`);

      // Print summary by category
      const categoryCounts = {};
      result.forEach(vehicle => {
        const category = vehicle.category;
        categoryCounts[category] = (categoryCounts[category] || 0) + 1;
      });

      console.log('\n📊 Summary by category:');
      console.log('   Luxury Sedans (sedan):', categoryCounts.sedan || 0);
      console.log('   SUVs (suv):', categoryCounts.suv || 0);
      console.log('   Luxury Vans (van):', categoryCounts.van || 0);
      console.log('   Sports Cars (luxury):', categoryCounts.luxury || 0);
      console.log('   Hybrids (hybrid):', categoryCounts.hybrid || 0);

      const totalCapeTown = await Vehicle.countDocuments({
        'currentLocation.city': 'Cape Town'
      });
      console.log(`\n🎉 Total Cape Town vehicles in database: ${totalCapeTown}`);

    } catch (error) {
      console.error('❌ Error seeding Cape Town vehicles:', error);
      throw error;
    }
  }
}

// Run script if called directly
if (require.main === module) {
  const args = process.argv.slice(2);
  const clearExisting = args.includes('--clear-existing');

  const seeder = new CapeTownVehicleSeeder();
  
  seeder.connect()
    .then(() => seeder.seedCapeTownVehicles({ clearExisting }))
    .then(() => {
      console.log('\n✅ Cape Town vehicle seeding completed successfully');
      return seeder.disconnect();
    })
    .then(() => process.exit(0))
    .catch((error) => {
      console.error('\n❌ Cape Town vehicle seeding failed:', error);
      seeder.disconnect()
        .then(() => process.exit(1))
        .catch(() => process.exit(1));
    });
}

module.exports = CapeTownVehicleSeeder;

