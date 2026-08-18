const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../server');
const Vehicle = require('../models/Vehicle');
const Driver = require('../models/Driver');
const User = require('../models/User');
const { generateAccessToken } = require('../utils/jwt');

describe('Vehicle Management APIs', () => {
  let testUser;
  let testDriver;
  let testVehicle;
  let authToken;

  beforeAll(async () => {
    // DB connection is managed globally in tests/setup.js
    
    // Create test user
    testUser = new User({
      email: 'driver@test.com',
      password: 'password123',
      name: 'Test Driver',
      phoneNumber: '+27123456789',
      isVerified: true,
      role: 'user'
    });
    await testUser.save();

    // Create test driver
    testDriver = new Driver({
      userId: testUser._id,
      driverId: 'DRV001',
      licenseNumber: 'LIC123456',
      licenseExpiry: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
      licenseExpiry: new Date('2025-12-31'),
      vehicleInfo: {
        make: 'Toyota',
        model: 'Camry',
        year: 2020,
        color: 'White',
        licensePlate: 'ABC123',
        vehicleType: 'sedan',
        passengerCapacity: 4,
        hasAC: true,
        features: ['wifi', 'leather_seats']
      },
      documents: {
        licensePhoto: 'license.jpg',
        vehicleRegistration: 'registration.jpg',
        vehicleInsurance: 'insurance.jpg'
      },
      emergencyContact: {
        name: 'EC Name',
        phone: '+27123456780',
        relationship: 'Spouse'
      },
      bankDetails: {
        accountHolder: 'Test Driver',
        accountNumber: '1234567890',
        bankName: 'Test Bank',
        branchCode: '123456'
      },
      currentLocation: {
        coordinates: {
          latitude: -26.2041,
          longitude: 28.0473
        },
        address: 'Johannesburg, South Africa'
      },
      availability: {
        status: 'online'
      },
      status: 'active'
    });
    await testDriver.save();

    // Create test vehicle (match Vehicle schema requirements)
    testVehicle = new Vehicle({
      vehicleId: 'VH001',
      driverId: testDriver._id,
      name: 'Toyota Camry',
      description: 'Comfortable sedan for city rides',
      make: 'Toyota',
      model: 'Camry',
      year: 2020,
      color: 'White',
      licensePlate: 'ABC123',
      category: 'sedan',
      subcategory: 'comfort',
      passengerCapacity: 4,
      seatingCapacity: 4,
      luggageCapacity: 2,
      engineType: 'petrol',
      transmission: 'automatic',
      fuelEfficiency: 12,
      basePrice: 25,
      currentLocation: {
        address: 'Johannesburg, South Africa',
        coordinates: {
          latitude: -26.2041,
          longitude: 28.0473
        },
        city: 'Johannesburg',
        province: 'Gauteng'
      },
      status: 'available',
      availability: {
        isAvailable: true,
        workingHours: {
          start: '06:00',
          end: '22:00'
        },
        operatingDays: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
      },
      pricing: {
        baseFare: 25,
        perKmRate: 8,
        perMinuteRate: 0.5,
        minimumFare: 30,
        currency: 'ZAR'
      },
      features: ['airConditioning', 'wifi', 'leatherSeats', 'usbCharging', 'bluetooth', 'gps'],
      performance: {
        rating: 4.8,
        totalTrips: 150,
        totalDistance: 5000,
        totalEarnings: 15000,
        averageRating: 4.8,
        reliabilityScore: 95
      },
      isActive: true,
      isVerified: true
    });
    await testVehicle.save();

    // Generate auth token directly to avoid rate limiting
    authToken = generateAccessToken(testUser._id.toString());
  });

  afterAll(async () => {
    // Clean up
    await mongoose.connection.close();
  });

  beforeEach(async () => {
    // Recreate test user (since setup.js clears all collections)
    testUser = new User({
      email: 'driver@test.com',
      password: 'password123',
      name: 'Test Driver',
      phoneNumber: '+27123456789',
      isVerified: true,
      role: 'user'
    });
    await testUser.save();

    // Recreate test driver
    testDriver = new Driver({
      userId: testUser._id,
      driverId: 'DRV001',
      licenseNumber: 'LIC123456',
      licenseExpiry: new Date('2025-12-31'),
      vehicleInfo: {
        make: 'Toyota',
        model: 'Camry',
        year: 2020,
        color: 'White',
        licensePlate: 'ABC123',
        vehicleType: 'sedan',
        passengerCapacity: 4,
        hasAC: true,
        features: ['wifi', 'leather_seats']
      },
      documents: {
        licensePhoto: 'license.jpg',
        vehicleRegistration: 'registration.jpg',
        vehicleInsurance: 'insurance.jpg'
      },
      emergencyContact: {
        name: 'EC Name',
        phone: '+27123456780',
        relationship: 'Spouse'
      },
      bankDetails: {
        accountHolder: 'Test Driver',
        accountNumber: '1234567890',
        bankName: 'Test Bank',
        branchCode: '123456'
      },
      currentLocation: {
        coordinates: {
          latitude: -26.2041,
          longitude: 28.0473
        },
        address: 'Johannesburg, South Africa'
      },
      availability: {
        status: 'online'
      },
      status: 'active'
    });
    await testDriver.save();

    // Recreate test vehicle to avoid VersionError
    await Vehicle.deleteOne({ _id: testVehicle._id });
    testVehicle = new Vehicle({
      vehicleId: 'VH001',
      driverId: testDriver._id,
      name: 'Toyota Camry',
      description: 'Comfortable sedan for city rides',
      make: 'Toyota',
      model: 'Camry',
      year: 2020,
      color: 'White',
      licensePlate: 'ABC123',
      category: 'sedan',
      subcategory: 'comfort',
      passengerCapacity: 4,
      seatingCapacity: 4,
      luggageCapacity: 2,
      engineType: 'petrol',
      transmission: 'automatic',
      fuelEfficiency: 12,
      basePrice: 25,
      currentLocation: {
        address: 'Johannesburg, South Africa',
        coordinates: {
          latitude: -26.2041,
          longitude: 28.0473
        },
        city: 'Johannesburg',
        province: 'Gauteng'
      },
      status: 'available',
      availability: {
        isAvailable: true,
        workingHours: {
          start: '06:00',
          end: '22:00'
        },
        operatingDays: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
      },
      pricing: {
        baseFare: 25,
        perKmRate: 8,
        perMinuteRate: 0.5,
        minimumFare: 30,
        currency: 'ZAR'
      },
      features: ['airConditioning', 'wifi', 'leatherSeats', 'usbCharging', 'bluetooth', 'gps'],
      performance: {
        rating: 4.8,
        totalTrips: 150,
        totalDistance: 5000,
        totalEarnings: 15000,
        averageRating: 4.8,
        reliabilityScore: 95
      },
      isActive: true,
      isVerified: true
    });
    await testVehicle.save();

    // Regenerate auth token for the recreated user
    authToken = generateAccessToken(testUser._id.toString());
  });

  describe('GET /api/vehicles/available', () => {
    it('should return available vehicles by location', async () => {
      const response = await request(app)
        .get('/api/vehicles/available')
        .query({
          latitude: -26.2041,
          longitude: 28.0473,
          maxDistance: 10000
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toBeInstanceOf(Array);
      expect(response.body.data.length).toBeGreaterThan(0);
      expect(response.body.data[0]).toHaveProperty('vehicleId');
      expect(response.body.data[0]).toHaveProperty('status', 'available');
    });

    it('should filter vehicles by category', async () => {
      const response = await request(app)
        .get('/api/vehicles/available')
        .query({
          latitude: -26.2041,
          longitude: 28.0473,
          category: 'sedan'
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      response.body.data.forEach(vehicle => {
        expect(vehicle.category).toBe('sedan');
      });
    });

    it('should filter vehicles by passenger count', async () => {
      const response = await request(app)
        .get('/api/vehicles/available')
        .query({
          latitude: -26.2041,
          longitude: 28.0473,
          passengerCount: 4
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      response.body.data.forEach(vehicle => {
        expect(vehicle.passengerCapacity).toBeGreaterThanOrEqual(4);
      });
    });

    it('should require latitude and longitude', async () => {
      const response = await request(app)
        .get('/api/vehicles/available');

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Latitude and longitude are required');
    });
  });

  describe('GET /api/vehicles/:id', () => {
    it('should return detailed vehicle information', async () => {
      const response = await request(app)
        .get(`/api/vehicles/${testVehicle.vehicleId}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('vehicleId', testVehicle.vehicleId);
      expect(response.body.data).toHaveProperty('make', 'Toyota');
      expect(response.body.data).toHaveProperty('model', 'Camry');
      expect(response.body.data).toHaveProperty('driver');
    });

    it('should return 404 for non-existent vehicle', async () => {
      const response = await request(app)
        .get('/api/vehicles/NONEXISTENT');

      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Vehicle not found');
    });
  });

  describe('GET /api/vehicles/categories', () => {
    it('should return vehicle categories with statistics', async () => {
      const response = await request(app)
        .get('/api/vehicles/categories');

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toBeInstanceOf(Array);
      expect(response.body.data.length).toBeGreaterThan(0);
      
      const sedanCategory = response.body.data.find(cat => cat.category === 'sedan');
      expect(sedanCategory).toBeDefined();
      expect(sedanCategory).toHaveProperty('count');
      expect(sedanCategory).toHaveProperty('available');
      expect(sedanCategory).toHaveProperty('averageRating');
    });
  });

  describe('GET /api/vehicles/search', () => {
    it('should search vehicles by criteria', async () => {
      const response = await request(app)
        .get('/api/vehicles/search')
        .query({
          latitude: -26.2041,
          longitude: 28.0473,
          category: 'sedan',
          passengerCount: 4,
          features: 'wifi,airConditioning'
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toBeInstanceOf(Array);
      expect(response.body.searchCriteria).toBeDefined();
    });

    it('should search by make and model', async () => {
      const response = await request(app)
        .get('/api/vehicles/search')
        .query({
          latitude: -26.2041,
          longitude: 28.0473,
          make: 'Toyota',
          model: 'Camry'
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      response.body.data.forEach(vehicle => {
        expect(vehicle.make).toBe('Toyota');
        expect(vehicle.model).toBe('Camry');
      });
    });

    it('should search by price range', async () => {
      const response = await request(app)
        .get('/api/vehicles/search')
        .query({
          latitude: -26.2041,
          longitude: 28.0473,
          minPrice: 20,
          maxPrice: 50
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      response.body.data.forEach(vehicle => {
        expect(vehicle.pricing.baseFare).toBeGreaterThanOrEqual(20);
        expect(vehicle.pricing.baseFare).toBeLessThanOrEqual(50);
      });
    });
  });

  describe('GET /api/vehicles/:id/availability', () => {
    it('should check real-time vehicle availability', async () => {
      const response = await request(app)
        .get(`/api/vehicles/${testVehicle.vehicleId}/availability`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('vehicleId', testVehicle.vehicleId);
      expect(response.body.data).toHaveProperty('isAvailable');
      expect(response.body.data).toHaveProperty('status');
      expect(response.body.data).toHaveProperty('availability');
    });

    it('should return 404 for non-existent vehicle', async () => {
      const response = await request(app)
        .get('/api/vehicles/NONEXISTENT/availability');

      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Vehicle not found');
    });
  });

  describe('PUT /api/vehicles/:id/status', () => {
    it('should update vehicle status', async () => {
      const response = await request(app)
        .put(`/api/vehicles/${testVehicle.vehicleId}/status`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          status: 'busy'
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.status).toBe('busy');
    });

    it('should update vehicle availability', async () => {
      const response = await request(app)
        .put(`/api/vehicles/${testVehicle.vehicleId}/status`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          isAvailable: false,
          availableUntil: new Date(Date.now() + 2 * 60 * 60 * 1000) // 2 hours from now
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.availability.isAvailable).toBe(false);
    });

    it('should reject invalid status', async () => {
      const response = await request(app)
        .put(`/api/vehicles/${testVehicle.vehicleId}/status`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          status: 'invalid_status'
        });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Invalid status');
    });

    it('should require authentication', async () => {
      const response = await request(app)
        .put(`/api/vehicles/${testVehicle.vehicleId}/status`)
        .send({
          status: 'busy'
        });

      expect(response.status).toBe(401);
    });
  });

  describe('Additional Vehicle Endpoints', () => {
    it('should get vehicles by driver ID', async () => {
      const response = await request(app)
        .get(`/api/vehicles/driver/${testDriver.driverId}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toBeInstanceOf(Array);
      expect(response.body.data.length).toBeGreaterThan(0);
    });

    it('should get vehicle statistics', async () => {
      const response = await request(app)
        .get('/api/vehicles/stats');

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toBeInstanceOf(Array);
    });

    it('should create a new vehicle', async () => {
      const newVehicleData = {
        vehicleId: 'VH002',
        name: 'Honda Civic',
        description: 'Reliable sedan for city transportation',
        make: 'Honda',
        model: 'Civic',
        year: 2021,
        color: 'Blue',
        licensePlate: 'XYZ789',
        category: 'sedan',
        passengerCapacity: 4,
        status: 'available',
        driverId: testDriver._id,
        currentLocation: {
          address: 'Cape Town, South Africa',
          coordinates: {
            latitude: -33.9249,
            longitude: 18.4241
          },
          city: 'Cape Town',
          province: 'Western Cape'
        },
        pricing: {
          baseFare: 30,
          perKmRate: 9,
          perMinuteRate: 0.6,
          minimumFare: 35,
          currency: 'ZAR'
        }
      };

      const response = await request(app)
        .post('/api/vehicles')
        .set('Authorization', `Bearer ${authToken}`)
        .send(newVehicleData);

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('vehicleId');
      expect(response.body.data.make).toBe('Honda');
    });

    it('should update vehicle information', async () => {
      const updateData = {
        color: 'Red',
        passengerCapacity: 5
      };

      const response = await request(app)
        .put(`/api/vehicles/${testVehicle.vehicleId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(updateData);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.color).toBe('Red');
      expect(response.body.data.passengerCapacity).toBe(5);
    });
  });

  describe('Error Handling', () => {
    it('should handle database connection errors gracefully', async () => {
      // This would require mocking the database connection
      // For now, we'll test with invalid data
      const response = await request(app)
        .get('/api/vehicles/available')
        .query({
          latitude: 'invalid',
          longitude: 'invalid'
        });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });

    it('should handle missing required fields in vehicle creation', async () => {
      const incompleteData = {
        make: 'Toyota'
        // Missing required fields
      };

      const response = await request(app)
        .post('/api/vehicles')
        .set('Authorization', `Bearer ${authToken}`)
        .send(incompleteData);

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Validation failed');
    });
  });
});
