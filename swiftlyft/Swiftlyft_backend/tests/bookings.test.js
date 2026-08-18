const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../server');
const User = require('../models/User');
const Driver = require('../models/Driver');
const Booking = require('../models/Booking');
const Quote = require('../models/Quote');
const { generateAccessToken } = require('../utils/jwt');

describe('Booking API Tests', () => {
  let authToken;
  let userId;
  let driverId;
  let bookingId;

  beforeAll(async () => {
    // Create test user for authentication
    const user = new User({
      email: 'test@example.com',
      password: 'password123',
      name: 'Test User',
      phoneNumber: '+1234567890'
    });
    await user.save();
    userId = user._id;

    // Create test driver
    const driver = new Driver({
      userId: userId,
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
        vehicleRegistration: 'registration.pdf',
        vehicleInsurance: 'insurance.pdf'
      },
      bankDetails: {
        accountHolder: 'Test Driver',
        accountNumber: '1234567890',
        bankName: 'Test Bank',
        branchCode: '001'
      },
      currentLocation: {
        coordinates: { latitude: -26.2041, longitude: 28.0473 },
        address: 'Johannesburg, South Africa'
      },
      availability: {
        status: 'online'
      },
      status: 'active',
      emergencyContact: {
        name: 'Emergency Contact',
        phone: '+1234567890',
        relationship: 'spouse'
      }
    });
    await driver.save();
    driverId = driver._id;

    // Generate auth token by logging in
    const loginResponse = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'test@example.com',
        password: 'password123'
      });
    
    if (!loginResponse.body.data || !loginResponse.body.data.tokens) {
      throw new Error(`Login failed: ${JSON.stringify(loginResponse.body)}`);
    }
    
    authToken = loginResponse.body.data.tokens.accessToken;
  });

  afterAll(async () => {
    await mongoose.connection.close();
  });

  beforeEach(async () => {
    try {
      // Clean up bookings before each test
      await Booking.deleteMany({});
      
      // Recreate test user (since setup.js clears all collections)
      const user = new User({
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
        phoneNumber: '+1234567890'
      });
      await user.save();
      userId = user._id;

      // Recreate test driver
      const driver = new Driver({
        userId: userId,
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
          vehicleRegistration: 'registration.pdf',
          vehicleInsurance: 'insurance.pdf'
        },
        bankDetails: {
          accountHolder: 'Test Driver',
          accountNumber: '1234567890',
          bankName: 'Test Bank',
          branchCode: '001'
        },
        currentLocation: {
          coordinates: { latitude: -26.2041, longitude: 28.0473 },
          address: 'Johannesburg, South Africa'
        },
        availability: {
          status: 'online'
        },
        status: 'active',
        emergencyContact: {
          name: 'Emergency Contact',
          phone: '+1234567890',
          relationship: 'spouse'
        }
      });
      await driver.save();
      driverId = driver._id;

      // Generate auth token directly to avoid rate limiting
      authToken = generateAccessToken(userId.toString());
    } catch (error) {
      console.error('Error in beforeEach:', error);
      throw error;
    }
  });

  describe('POST /api/bookings - Create Booking', () => {
    it('should create a new booking successfully', async () => {
      const bookingData = {
        pickupLocation: {
          address: '123 Main St, Johannesburg',
          coordinates: { latitude: -26.2041, longitude: 28.0473 },
          city: 'Johannesburg',
          province: 'Gauteng'
        },
        dropoffLocation: {
          address: '456 Oak Ave, Johannesburg',
          coordinates: { latitude: -26.2042, longitude: 28.0474 },
          city: 'Johannesburg',
          province: 'Gauteng'
        },
        pickupAddress: '123 Main St, Johannesburg',
        dropoffAddress: '456 Oak Ave, Johannesburg',
        vehicleId: new mongoose.Types.ObjectId(),
        vehicleName: 'Toyota Camry',
        vehicleType: 'sedan',
        serviceType: 'standard',
        passengerCount: 2,
        luggageCount: 1,
        scheduledDate: new Date(Date.now() + 24 * 60 * 60 * 1000), // Tomorrow
        basePrice: 25,
        finalPrice: 74.75,
        pricing: {
          baseFare: 25,
          distanceFare: 15,
          timeFare: 20,
          serviceFee: 5,
          taxes: 9.75,
          total: 74.75
        },
        specialRequirements: 'Please call when arriving',
        paymentMethod: 'card',
        bookingId: 'BK' + Date.now().toString(36).slice(-4) + Math.random().toString(36).substring(2, 6).toUpperCase()
      };

      const response = await request(app)
        .post('/api/bookings')
        .set('Authorization', `Bearer ${authToken}`)
        .send(bookingData);

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('bookingId');
      expect(response.body.data.userId).toBe(userId.toString());
      expect(response.body.data.status).toBe('pending');
      
      bookingId = response.body.data._id;
    });

    it('should fail to create booking with missing required fields', async () => {
      const incompleteData = {
        pickupLocation: {
          address: '123 Main St, Johannesburg',
          coordinates: { latitude: -26.2041, longitude: 28.0473 }
        }
        // Missing dropoffLocation, vehicleType, etc.
      };

      const response = await request(app)
        .post('/api/bookings')
        .set('Authorization', `Bearer ${authToken}`)
        .send(incompleteData);

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });

    it('should fail to create booking with past scheduled date', async () => {
      const bookingData = {
        pickupLocation: {
          address: '123 Main St, Johannesburg',
          coordinates: { latitude: -26.2041, longitude: 28.0473 },
          city: 'Johannesburg',
          province: 'Gauteng'
        },
        dropoffLocation: {
          address: '456 Oak Ave, Johannesburg',
          coordinates: { latitude: -26.2042, longitude: 28.0474 },
          city: 'Johannesburg',
          province: 'Gauteng'
        },
        pickupAddress: '123 Main St, Johannesburg',
        dropoffAddress: '456 Oak Ave, Johannesburg',
        vehicleId: new mongoose.Types.ObjectId(),
        vehicleName: 'Toyota Camry',
        vehicleType: 'sedan',
        serviceType: 'standard',
        passengerCount: 2,
        pickupTime: new Date(Date.now() - 24 * 60 * 60 * 1000), // Yesterday
        scheduledDate: new Date(Date.now() - 24 * 60 * 60 * 1000), // Yesterday
        basePrice: 25,
        finalPrice: 74.75,
        pricing: {
          baseFare: 25,
          distanceFare: 15,
          timeFare: 20,
          serviceFee: 5,
          taxes: 9.75,
          total: 74.75
        },
        status: 'pending',
        paymentStatus: 'pending'
      };

      const response = await request(app)
        .post('/api/bookings')
        .set('Authorization', `Bearer ${authToken}`)
        .send(bookingData);

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('future');
    });
  });

  describe('GET /api/bookings/:id - Get Booking', () => {
    beforeEach(async () => {
      // Create a test booking
      const booking = new Booking({
        bookingId: 'BK' + Date.now().toString(36).slice(-4) + Math.random().toString(36).substring(2, 6).toUpperCase(),
        userId: userId,
        pickupLocation: {
          address: '123 Main St, Johannesburg',
          coordinates: { latitude: -26.2041, longitude: 28.0473 },
          city: 'Johannesburg',
          province: 'Gauteng'
        },
        dropoffLocation: {
          address: '456 Oak Ave, Johannesburg',
          coordinates: { latitude: -26.2042, longitude: 28.0474 },
          city: 'Johannesburg',
          province: 'Gauteng'
        },
        pickupAddress: '123 Main St, Johannesburg',
        dropoffAddress: '456 Oak Ave, Johannesburg',
        vehicleId: new mongoose.Types.ObjectId(),
        vehicleName: 'Toyota Camry',
        vehicleType: 'sedan',
        serviceType: 'standard',
        passengerCount: 2,
        pickupTime: new Date(Date.now() + 24 * 60 * 60 * 1000),
        scheduledDate: new Date(Date.now() + 24 * 60 * 60 * 1000),
        basePrice: 25,
        finalPrice: 74.75,
        pricing: {
          baseFare: 25,
          distanceFare: 15,
          timeFare: 20,
          serviceFee: 5,
          taxes: 9.75,
          total: 74.75
        },
        status: 'pending',
        paymentStatus: 'pending'
      });
      await booking.save();
      bookingId = booking._id;
    });

    it('should retrieve booking details successfully', async () => {
      const response = await request(app)
        .get(`/api/bookings/${bookingId}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.id).toBe(bookingId.toString());
      expect(response.body.data.userId).toBe(userId.toString());
    });

    it('should fail to retrieve non-existent booking', async () => {
      const fakeId = new mongoose.Types.ObjectId();
      const response = await request(app)
        .get(`/api/bookings/${fakeId}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
    });
  });

  describe('PUT /api/bookings/:id - Update Booking', () => {
    beforeEach(async () => {
      const booking = new Booking({
        bookingId: 'BK' + Date.now().toString(36).slice(-4) + Math.random().toString(36).substring(2, 6).toUpperCase(),
        userId: userId,
        pickupLocation: {
          address: '123 Main St, Johannesburg',
          coordinates: { latitude: -26.2041, longitude: 28.0473 },
          city: 'Johannesburg',
          province: 'Gauteng'
        },
        dropoffLocation: {
          address: '456 Oak Ave, Johannesburg',
          coordinates: { latitude: -26.2042, longitude: 28.0474 },
          city: 'Johannesburg',
          province: 'Gauteng'
        },
        pickupAddress: '123 Main St, Johannesburg',
        dropoffAddress: '456 Oak Ave, Johannesburg',
        vehicleId: new mongoose.Types.ObjectId(),
        vehicleName: 'Toyota Camry',
        vehicleType: 'sedan',
        serviceType: 'standard',
        passengerCount: 2,
        pickupTime: new Date(Date.now() + 24 * 60 * 60 * 1000),
        scheduledDate: new Date(Date.now() + 24 * 60 * 60 * 1000),
        basePrice: 25,
        finalPrice: 74.75,
        pricing: {
          baseFare: 25,
          distanceFare: 15,
          timeFare: 20,
          serviceFee: 5,
          taxes: 9.75,
          total: 74.75
        },
        status: 'pending',
        paymentStatus: 'pending'
      });
      await booking.save();
      bookingId = booking._id;
    });

    it('should update booking successfully', async () => {
      const updateData = {
        specialNotes: 'Updated requirements',
        customerNotes: 'Please be punctual'
      };

      const response = await request(app)
        .put(`/api/bookings/${bookingId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(updateData);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.specialNotes).toBe('Updated requirements');
    });
  });

  describe('DELETE /api/bookings/:id - Cancel Booking', () => {
    beforeEach(async () => {
      const booking = new Booking({
        bookingId: 'BK' + Date.now().toString(36).slice(-4) + Math.random().toString(36).substring(2, 6).toUpperCase(),
        userId: userId,
        pickupLocation: {
          address: '123 Main St, Johannesburg',
          coordinates: { latitude: -26.2041, longitude: 28.0473 },
          city: 'Johannesburg',
          province: 'Gauteng'
        },
        dropoffLocation: {
          address: '456 Oak Ave, Johannesburg',
          coordinates: { latitude: -26.2042, longitude: 28.0474 },
          city: 'Johannesburg',
          province: 'Gauteng'
        },
        pickupAddress: '123 Main St, Johannesburg',
        dropoffAddress: '456 Oak Ave, Johannesburg',
        vehicleId: new mongoose.Types.ObjectId(),
        vehicleName: 'Toyota Camry',
        vehicleType: 'sedan',
        serviceType: 'standard',
        passengerCount: 2,
        pickupTime: new Date(Date.now() + 24 * 60 * 60 * 1000),
        scheduledDate: new Date(Date.now() + 24 * 60 * 60 * 1000),
        basePrice: 25,
        finalPrice: 74.75,
        pricing: {
          baseFare: 25,
          distanceFare: 15,
          timeFare: 20,
          serviceFee: 5,
          taxes: 9.75,
          total: 74.75
        },
        status: 'confirmed',
        paymentStatus: 'pending'
      });
      await booking.save();
      bookingId = booking._id;
    });

    it('should cancel booking successfully', async () => {
      const response = await request(app)
        .delete(`/api/bookings/${bookingId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ reason: 'Change of plans' });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.cancellationFee).toBeDefined();

      // Verify booking status was updated
      const updatedBooking = await Booking.findById(bookingId);
      expect(updatedBooking.status).toBe('cancelled');
    });

    it('should fail to cancel completed booking', async () => {
      // Update booking to completed status
      await Booking.findByIdAndUpdate(bookingId, { status: 'trip_completed' });

      const response = await request(app)
        .delete(`/api/bookings/${bookingId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ reason: 'Change of plans' });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });
  });

  describe('GET /api/users/:userId/bookings - User Bookings', () => {
    beforeEach(async () => {
      // Create multiple test bookings
      const bookings = [
        {
          bookingId: 'BK' + Date.now().toString(36).slice(-4) + Math.random().toString(36).substring(2, 6).toUpperCase(),
          userId: userId,
          pickupLocation: {
            address: '123 Main St, Johannesburg',
            coordinates: { latitude: -26.2041, longitude: 28.0473 },
            city: 'Johannesburg',
            province: 'Gauteng'
          },
          dropoffLocation: {
            address: '456 Oak Ave, Johannesburg',
            coordinates: { latitude: -26.2042, longitude: 28.0474 },
            city: 'Johannesburg',
            province: 'Gauteng'
          },
          pickupAddress: '123 Main St, Johannesburg',
          dropoffAddress: '456 Oak Ave, Johannesburg',
          vehicleId: new mongoose.Types.ObjectId(),
          vehicleName: 'Toyota Camry',
          vehicleType: 'sedan',
          serviceType: 'standard',
          passengerCount: 2,
          pickupTime: new Date(Date.now() + 24 * 60 * 60 * 1000),
          scheduledDate: new Date(Date.now() + 24 * 60 * 60 * 1000),
          basePrice: 25,
          finalPrice: 74.75,
          pricing: { baseFare: 25, distanceFare: 15, timeFare: 20, serviceFee: 5, taxes: 9.75, total: 74.75 },
          status: 'confirmed',
          paymentStatus: 'pending'
        },
        {
          bookingId: 'BK' + Date.now().toString(36).slice(-4) + Math.random().toString(36).substring(2, 6).toUpperCase(),
          userId: userId,
          pickupLocation: {
            address: '789 Pine St, Johannesburg',
            coordinates: { latitude: -26.2043, longitude: 28.0475 },
            city: 'Johannesburg',
            province: 'Gauteng'
          },
          dropoffLocation: {
            address: '321 Elm St, Johannesburg',
            coordinates: { latitude: -26.2044, longitude: 28.0476 },
            city: 'Johannesburg',
            province: 'Gauteng'
          },
          pickupAddress: '789 Pine St, Johannesburg',
          dropoffAddress: '321 Elm St, Johannesburg',
          vehicleId: new mongoose.Types.ObjectId(),
          vehicleName: 'BMW X5',
          vehicleType: 'suv',
          serviceType: 'premium',
          passengerCount: 4,
          pickupTime: new Date(Date.now() + 48 * 60 * 60 * 1000),
          scheduledDate: new Date(Date.now() + 48 * 60 * 60 * 1000),
          basePrice: 35,
          finalPrice: 101.2,
          pricing: { baseFare: 35, distanceFare: 20, timeFare: 25, serviceFee: 8, taxes: 13.2, total: 101.2 },
          status: 'completed',
          paymentStatus: 'paid'
        }
      ];

      for (const bookingData of bookings) {
        const booking = new Booking(bookingData);
        await booking.save();
      }
    });

    it('should retrieve user bookings successfully', async () => {
      const response = await request(app)
        .get(`/api/bookings/user/${userId}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(2);
    });

    it('should filter bookings by status', async () => {
      const response = await request(app)
        .get(`/api/bookings/user/${userId}?status=confirmed`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].status).toBe('confirmed');
    });
  });

  describe('GET /api/users/:userId/bookings/active - Active Bookings', () => {
    beforeEach(async () => {
      const bookings = [
        {
          bookingId: 'BK' + Date.now().toString(36).slice(-4) + Math.random().toString(36).substring(2, 6).toUpperCase(),
          userId: userId,
          pickupLocation: {
            address: '123 Main St, Johannesburg',
            coordinates: { latitude: -26.2041, longitude: 28.0473 },
            city: 'Johannesburg',
            province: 'Gauteng'
          },
          dropoffLocation: {
            address: '456 Oak Ave, Johannesburg',
            coordinates: { latitude: -26.2042, longitude: 28.0474 },
            city: 'Johannesburg',
            province: 'Gauteng'
          },
          pickupAddress: '123 Main St, Johannesburg',
          dropoffAddress: '456 Oak Ave, Johannesburg',
          vehicleId: new mongoose.Types.ObjectId(),
          vehicleName: 'Toyota Camry',
          vehicleType: 'sedan',
          serviceType: 'standard',
          passengerCount: 2,
          pickupTime: new Date(Date.now() + 24 * 60 * 60 * 1000),
          scheduledDate: new Date(Date.now() + 24 * 60 * 60 * 1000),
          basePrice: 25,
          finalPrice: 74.75,
          pricing: { baseFare: 25, distanceFare: 15, timeFare: 20, serviceFee: 5, taxes: 9.75, total: 74.75 },
          status: 'driverAssigned',
          paymentStatus: 'pending'
        },
        {
          bookingId: 'BK' + Date.now().toString(36).slice(-4) + Math.random().toString(36).substring(2, 6).toUpperCase(),
          userId: userId,
          pickupLocation: {
            address: '789 Pine St, Johannesburg',
            coordinates: { latitude: -26.2043, longitude: 28.0475 },
            city: 'Johannesburg',
            province: 'Gauteng'
          },
          dropoffLocation: {
            address: '321 Elm St, Johannesburg',
            coordinates: { latitude: -26.2044, longitude: 28.0476 },
            city: 'Johannesburg',
            province: 'Gauteng'
          },
          pickupAddress: '789 Pine St, Johannesburg',
          dropoffAddress: '321 Elm St, Johannesburg',
          vehicleId: new mongoose.Types.ObjectId(),
          vehicleName: 'BMW X5',
          vehicleType: 'suv',
          serviceType: 'premium',
          passengerCount: 4,
          pickupTime: new Date(Date.now() + 48 * 60 * 60 * 1000),
          scheduledDate: new Date(Date.now() + 48 * 60 * 60 * 1000),
          basePrice: 35,
          finalPrice: 101.2,
          pricing: { baseFare: 35, distanceFare: 20, timeFare: 25, serviceFee: 8, taxes: 13.2, total: 101.2 },
          status: 'completed',
          paymentStatus: 'paid'
        }
      ];

      for (const bookingData of bookings) {
        const booking = new Booking(bookingData);
        await booking.save();
      }
    });

    it('should retrieve only active bookings', async () => {
      const response = await request(app)
        .get(`/api/bookings/user/${userId}/active`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].status).toBe('driverAssigned');
    });
  });

  describe('POST /api/bookings/:id/assign-driver - Assign Driver', () => {
    beforeEach(async () => {
      const booking = new Booking({
        bookingId: 'BK' + Date.now().toString(36).slice(-4) + Math.random().toString(36).substring(2, 6).toUpperCase(),
        userId: userId,
        pickupLocation: {
          address: '123 Main St, Johannesburg',
          coordinates: { latitude: -26.2041, longitude: 28.0473 },
          city: 'Johannesburg',
          province: 'Gauteng'
        },
        dropoffLocation: {
          address: '456 Oak Ave, Johannesburg',
          coordinates: { latitude: -26.2042, longitude: 28.0474 },
          city: 'Johannesburg',
          province: 'Gauteng'
        },
        pickupAddress: '123 Main St, Johannesburg',
        dropoffAddress: '456 Oak Ave, Johannesburg',
        vehicleId: new mongoose.Types.ObjectId(),
        vehicleName: 'Toyota Camry',
        vehicleType: 'sedan',
        serviceType: 'standard',
        passengerCount: 2,
        pickupTime: new Date(Date.now() + 24 * 60 * 60 * 1000),
        scheduledDate: new Date(Date.now() + 24 * 60 * 60 * 1000),
        basePrice: 25,
        finalPrice: 74.75,
        pricing: { baseFare: 25, distanceFare: 15, timeFare: 20, serviceFee: 5, taxes: 9.75, total: 74.75 },
        status: 'confirmed',
        paymentStatus: 'pending'
      });
      await booking.save();
      bookingId = booking._id;
    });

    it('should assign driver successfully', async () => {
      const response = await request(app)
        .post(`/api/bookings/${bookingId}/assign-driver`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ driverId: driverId });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.driverId).toBe(driverId.toString());
      expect(response.body.data.status).toBe('driverAssigned');
    });

    it('should fail to assign driver to completed booking', async () => {
      await Booking.findByIdAndUpdate(bookingId, { status: 'completed' });

      const response = await request(app)
        .post(`/api/bookings/${bookingId}/assign-driver`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ driverId: driverId });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });
  });

  describe('PUT /api/bookings/:id/status - Update Status', () => {
    beforeEach(async () => {
      const booking = new Booking({
        bookingId: 'BK' + Date.now().toString(36).slice(-4) + Math.random().toString(36).substring(2, 6).toUpperCase(),
        userId: userId,
        driverId: driverId,
        pickupLocation: {
          address: '123 Main St, Johannesburg',
          coordinates: { latitude: -26.2041, longitude: 28.0473 },
          city: 'Johannesburg',
          province: 'Gauteng'
        },
        dropoffLocation: {
          address: '456 Oak Ave, Johannesburg',
          coordinates: { latitude: -26.2042, longitude: 28.0474 },
          city: 'Johannesburg',
          province: 'Gauteng'
        },
        pickupAddress: '123 Main St, Johannesburg',
        dropoffAddress: '456 Oak Ave, Johannesburg',
        vehicleId: new mongoose.Types.ObjectId(),
        vehicleName: 'Toyota Camry',
        vehicleType: 'sedan',
        serviceType: 'standard',
        passengerCount: 2,
        pickupTime: new Date(Date.now() + 24 * 60 * 60 * 1000),
        scheduledDate: new Date(Date.now() + 24 * 60 * 60 * 1000),
        basePrice: 25,
        finalPrice: 74.75,
        pricing: { baseFare: 25, distanceFare: 15, timeFare: 20, serviceFee: 5, taxes: 9.75, total: 74.75 },
        status: 'driverAssigned',
        paymentStatus: 'pending'
      });
      await booking.save();
      bookingId = booking._id;
    });

    it('should update booking status successfully', async () => {
      const response = await request(app)
        .put(`/api/bookings/${bookingId}/status`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ 
          status: 'driverEnRoute',
          notes: 'Driver is on the way'
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.status).toBe('driverEnRoute');
    });
  });

  describe('POST /api/bookings/:id/rating - Submit Rating', () => {
    beforeEach(async () => {
      const booking = new Booking({
        bookingId: 'BK' + Date.now().toString(36).slice(-4) + Math.random().toString(36).substring(2, 6).toUpperCase(),
        userId: userId,
        driverId: driverId,
        pickupLocation: {
          address: '123 Main St, Johannesburg',
          coordinates: { latitude: -26.2041, longitude: 28.0473 },
          city: 'Johannesburg',
          province: 'Gauteng'
        },
        dropoffLocation: {
          address: '456 Oak Ave, Johannesburg',
          coordinates: { latitude: -26.2042, longitude: 28.0474 },
          city: 'Johannesburg',
          province: 'Gauteng'
        },
        pickupAddress: '123 Main St, Johannesburg',
        dropoffAddress: '456 Oak Ave, Johannesburg',
        vehicleId: new mongoose.Types.ObjectId(),
        vehicleName: 'Toyota Camry',
        vehicleType: 'sedan',
        serviceType: 'standard',
        passengerCount: 2,
        pickupTime: new Date(Date.now() - 24 * 60 * 60 * 1000), // Yesterday
        scheduledDate: new Date(Date.now() - 24 * 60 * 60 * 1000), // Yesterday
        basePrice: 25,
        finalPrice: 74.75,
        pricing: { baseFare: 25, distanceFare: 15, timeFare: 20, serviceFee: 5, taxes: 9.75, total: 74.75 },
        status: 'completed',
        paymentStatus: 'paid'
      });
      await booking.save();
      bookingId = booking._id;
    });

    it('should submit rating successfully', async () => {
      const ratingData = {
        rating: 5,
        review: 'Excellent service!',
        categories: {
          cleanliness: 5,
          punctuality: 4,
          friendliness: 5,
          driving: 5
        }
      };

      const response = await request(app)
        .post(`/api/bookings/${bookingId}/rating`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(ratingData);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.rating).toBe(5);
      expect(response.body.data.review).toBe('Excellent service!');
    });

    it('should fail to rate non-completed booking', async () => {
      await Booking.findByIdAndUpdate(bookingId, { status: 'confirmed' });

      const ratingData = {
        rating: 5,
        review: 'Excellent service!'
      };

      const response = await request(app)
        .post(`/api/bookings/${bookingId}/rating`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(ratingData);

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });

    it('should fail to rate with invalid rating', async () => {
      const ratingData = {
        rating: 6, // Invalid rating
        review: 'Excellent service!'
      };

      const response = await request(app)
        .post(`/api/bookings/${bookingId}/rating`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(ratingData);

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });
  });

  describe('Authentication Tests', () => {
    it('should fail to access booking endpoints without authentication', async () => {
      const response = await request(app)
        .get('/api/bookings/nonexistent-id');

      expect(response.status).toBe(401);
    });

    it('should fail to access booking endpoints with invalid token', async () => {
      const response = await request(app)
        .get('/api/bookings/nonexistent-id')
        .set('Authorization', 'Bearer invalid-token');

      expect(response.status).toBe(401);
    });
  });
});
