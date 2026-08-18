const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../server');
const Location = require('../models/Location');
const User = require('../models/User');
const Driver = require('../models/Driver');
const locationService = require('../utils/locationService');
const { generateAccessToken } = require('../utils/jwt');

// Mock the location service
jest.mock('../utils/locationService');

describe('Location APIs', () => {
  let authToken;
  let testUser;
  let testDriver;

  beforeAll(async () => {
    // Create test user
    testUser = new User({
      email: 'test@example.com',
      password: 'password123',
      name: 'Test User',
      phoneNumber: '+27123456789',
      role: 'user'
    });
    await testUser.save();

    // Create test driver
    testDriver = new Driver({
      userId: testUser._id,
      driverId: 'DRV-TEST-001',
      licenseNumber: 'DL123456',
      licenseExpiry: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
      vehicleInfo: {
        make: 'Toyota',
        model: 'Corolla',
        year: 2020,
        color: 'White',
        licensePlate: 'ABC123',
        vehicleType: 'sedan',
        passengerCapacity: 4,
        hasAC: true
      },
      documents: {
        licensePhoto: 'license.jpg',
        vehicleRegistration: 'registration.jpg',
        vehicleInsurance: 'insurance.jpg'
      },
      bankDetails: {
        accountHolder: 'Test Driver',
        accountNumber: '1234567890',
        bankName: 'Test Bank',
        branchCode: '123456'
      },
      currentLocation: {
        coordinates: { latitude: -26.2041, longitude: 28.0473 },
        address: 'Johannesburg, South Africa'
      },
      emergencyContact: {
        name: 'Emergency',
        phone: '+27123456780',
        relationship: 'Spouse'
      }
    });
    await testDriver.save();

    // Generate auth token directly
    authToken = generateAccessToken(testUser._id.toString());
  });

  afterAll(async () => {
    await User.deleteMany({});
    await Driver.deleteMany({});
    await Location.deleteMany({});
    await mongoose.connection.close();
  });

  beforeEach(async () => {
    jest.clearAllMocks();
    
    // Create test user
    testUser = new User({
      email: 'test@example.com',
      password: 'password123',
      name: 'Test User',
      phoneNumber: '+27123456789',
      role: 'user'
    });
    await testUser.save();

    // Create test driver
    testDriver = new Driver({
      userId: testUser._id,
      driverId: 'DRV-TEST-001',
      licenseNumber: 'DL123456',
      licenseExpiry: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
      vehicleInfo: {
        make: 'Toyota',
        model: 'Corolla',
        year: 2020,
        color: 'White',
        licensePlate: 'ABC123',
        vehicleType: 'sedan',
        passengerCapacity: 4,
        hasAC: true
      },
      documents: {
        licensePhoto: 'license.jpg',
        vehicleRegistration: 'registration.jpg',
        vehicleInsurance: 'insurance.jpg'
      },
      bankDetails: {
        accountHolder: 'Test Driver',
        bankName: 'Test Bank',
        accountNumber: '1234567890',
        branchCode: '123456'
      },
      emergencyContact: {
        name: 'Emergency Contact',
        phone: '+27123456788',
        relationship: 'Spouse'
      },
      currentLocation: {
        address: 'Johannesburg, South Africa',
        coordinates: {
          latitude: -26.2041,
          longitude: 28.0473
        },
        city: 'Johannesburg',
        province: 'Gauteng'
      },
      status: 'active'
    });
    await testDriver.save();

    // Generate auth token directly
    authToken = generateAccessToken(testUser._id.toString());
  });

  describe('POST /api/location/geocode', () => {
    it('should geocode an address successfully', async () => {
      const mockGeocodeResult = {
        latitude: -26.2041,
        longitude: 28.0473,
        formattedAddress: '123 Main St, Johannesburg, South Africa',
        address: {
          streetNumber: '123',
          streetName: 'Main St',
          city: 'Johannesburg',
          state: 'Gauteng',
          country: 'South Africa',
          countryCode: 'ZA',
          zipcode: '2000'
        },
        accuracy: 'high',
        coordinates: { lat: -26.2041, lng: 28.0473 },
        location: { latitude: -26.2041, longitude: 28.0473 }
      };

      locationService.geocode.mockResolvedValue(mockGeocodeResult);

      const response = await request(app)
        .post('/api/location/geocode')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          address: '123 Main St, Johannesburg'
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toEqual(mockGeocodeResult);
      expect(locationService.geocode).toHaveBeenCalledWith('123 Main St, Johannesburg');
    });

    it('should return error for missing address', async () => {
      const response = await request(app)
        .post('/api/location/geocode')
        .set('Authorization', `Bearer ${authToken}`)
        .send({});

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Address is required');
    });

    it('should save location when saveLocation is true', async () => {
      const mockGeocodeResult = {
        latitude: -26.2041,
        longitude: 28.0473,
        formattedAddress: '123 Main St, Johannesburg, South Africa',
        address: {
          streetNumber: '123',
          streetName: 'Main St',
          city: 'Johannesburg',
          state: 'Gauteng',
          country: 'South Africa',
          countryCode: 'ZA',
          zipcode: '2000',
          formatted: '123 Main St, Johannesburg, South Africa'
        },
        accuracy: 'high'
      };

      locationService.geocode.mockResolvedValue(mockGeocodeResult);

      const response = await request(app)
        .post('/api/location/geocode')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          address: '123 Main St, Johannesburg',
          saveLocation: true,
          type: 'pickup'
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.locationId).toBeDefined();

      // Verify location was saved
      const savedLocation = await Location.findById(response.body.data.locationId);
      expect(savedLocation).toBeTruthy();
      expect(savedLocation.latitude).toBe(-26.2041);
      expect(savedLocation.longitude).toBe(28.0473);
      expect(savedLocation.type).toBe('pickup');
    });
  });

  describe('POST /api/location/reverse-geocode', () => {
    it('should reverse geocode coordinates successfully', async () => {
      const mockReverseGeocodeResult = {
        latitude: -26.2041,
        longitude: 28.0473,
        formattedAddress: '123 Main St, Johannesburg, South Africa',
        address: {
          streetNumber: '123',
          streetName: 'Main St',
          city: 'Johannesburg',
          state: 'Gauteng',
          country: 'South Africa',
          countryCode: 'ZA',
          zipcode: '2000'
        },
        coordinates: {
          lat: -26.2041,
          lng: 28.0473
        },
        location: {
          latitude: -26.2041,
          longitude: 28.0473
        }
      };

      locationService.reverseGeocode.mockResolvedValue(mockReverseGeocodeResult);

      const response = await request(app)
        .post('/api/location/reverse-geocode')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          latitude: -26.2041,
          longitude: 28.0473
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toEqual(mockReverseGeocodeResult);
      expect(locationService.reverseGeocode).toHaveBeenCalledWith(-26.2041, 28.0473);
    });

    it('should return error for missing coordinates', async () => {
      const response = await request(app)
        .post('/api/location/reverse-geocode')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          latitude: -26.2041
        });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Latitude and longitude are required');
    });
  });

  describe('POST /api/location/route', () => {
    it('should calculate route successfully', async () => {
      const mockRouteResult = {
        distance: 5000, // meters
        duration: 600, // seconds
        coordinates: [
          { longitude: 28.0473, latitude: -26.2041 },
          { longitude: 28.0573, latitude: -26.2141 }
        ],
        waypoints: 2,
        profile: 'driving-car',
        instructions: [],
        origin: {
          latitude: -26.2041,
          longitude: 28.0473,
          coordinates: {
            lat: -26.2041,
            lng: 28.0473
          }
        },
        destination: {
          latitude: -26.2141,
          longitude: 28.0573,
          coordinates: {
            lat: -26.2141,
            lng: 28.0573
          }
        },
        routeCoordinates: [
          {
            latitude: -26.2041,
            longitude: 28.0473,
            coordinates: {
              lat: -26.2041,
              lng: 28.0473
            }
          },
          {
            latitude: -26.2141,
            longitude: 28.0573,
            coordinates: {
              lat: -26.2141,
              lng: 28.0573
            }
          }
        ]
      };

      locationService.calculateRoute.mockResolvedValue(mockRouteResult);

      const response = await request(app)
        .post('/api/location/route')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          origin: { latitude: -26.2041, longitude: 28.0473 },
          destination: { latitude: -26.2141, longitude: 28.0573 },
          options: { profile: 'driving-car' }
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toEqual(mockRouteResult);
    });

    it('should return error for missing origin or destination', async () => {
      const response = await request(app)
        .post('/api/location/route')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          origin: { latitude: -26.2041, longitude: 28.0473 }
        });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Origin and destination coordinates are required');
    });
  });

  describe('GET /api/location/places/search', () => {
    it('should search places successfully', async () => {
      const mockSearchResults = [
        {
          name: 'Johannesburg Central',
          latitude: -26.2041,
          longitude: 28.0473,
          type: 'city',
          importance: 0.8,
          address: {
            city: 'Johannesburg',
            state: 'Gauteng',
            country: 'South Africa'
          },
          coordinates: {
            lat: -26.2041,
            lng: 28.0473
          },
          location: {
            latitude: -26.2041,
            longitude: 28.0473
          }
        }
      ];

      locationService.searchPlaces.mockResolvedValue(mockSearchResults);

      const response = await request(app)
        .get('/api/location/places/search')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ q: 'Johannesburg' });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toEqual(mockSearchResults);
      expect(response.body.count).toBe(1);
    });

    it('should return error for missing query', async () => {
      const response = await request(app)
        .get('/api/location/places/search')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Search query is required');
    });
  });

  describe('GET /api/location/places/nearby', () => {
    it('should find nearby places successfully', async () => {
      const mockNearbyResults = [
        {
          id: 12345,
          name: 'Coffee Shop',
          latitude: -26.2041,
          longitude: 28.0473,
          type: 'cafe',
          distance: 100,
          tags: { amenity: 'cafe', name: 'Coffee Shop' },
          coordinates: {
            lat: -26.2041,
            lng: 28.0473
          },
          location: {
            latitude: -26.2041,
            longitude: 28.0473
          }
        }
      ];

      locationService.findNearbyPlaces.mockResolvedValue(mockNearbyResults);

      const response = await request(app)
        .get('/api/location/places/nearby')
        .set('Authorization', `Bearer ${authToken}`)
        .query({
          latitude: -26.2041,
          longitude: 28.0473,
          radius: 1000,
          category: 'amenity'
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toEqual(mockNearbyResults);
      expect(response.body.count).toBe(1);
    });

    it('should return error for missing coordinates', async () => {
      const response = await request(app)
        .get('/api/location/places/nearby')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ latitude: -26.2041 });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Latitude and longitude are required');
    });
  });

  describe('POST /api/location/service-area', () => {
    it('should check service area successfully', async () => {
      const mockServiceAreaResult = {
        isInServiceArea: true,
        serviceArea: 'Johannesburg',
        coordinates: { 
          lat: -26.2041,
          lng: 28.0473
        },
        location: {
          latitude: -26.2041,
          longitude: 28.0473
        },
        serviceAreas: [
          {
            city: 'Johannesburg',
            radius: 50,
            center: {
              latitude: -26.2041,
              longitude: 28.0473
            }
          }
        ]
      };

      locationService.checkServiceArea.mockReturnValue(mockServiceAreaResult);

      const response = await request(app)
        .post('/api/location/service-area')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          latitude: -26.2041,
          longitude: 28.0473
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toEqual(mockServiceAreaResult);
    });

    it('should return error for missing coordinates', async () => {
      const response = await request(app)
        .post('/api/location/service-area')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          latitude: -26.2041
        });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Latitude and longitude are required');
    });
  });

  describe('GET /api/drivers/:id/location', () => {
    it('should get driver location successfully', async () => {
      const mockDriverLocation = {
        driverId: testDriver._id.toString(),
        latitude: -26.2041,
        longitude: 28.0473,
        accuracy: 10,
        timestamp: new Date().toISOString(),
        status: 'active',
        heading: 180,
        speed: 30,
        coordinates: {
          lat: -26.2041,
          lng: 28.0473
        },
        location: {
          latitude: -26.2041,
          longitude: 28.0473
        }
      };

      locationService.getDriverLocation.mockResolvedValue(mockDriverLocation);

      const response = await request(app)
        .get(`/api/location/drivers/${testDriver._id}/location`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toEqual(mockDriverLocation);
    });

    it('should return 404 for non-existent driver', async () => {
      const fakeDriverId = new mongoose.Types.ObjectId();
      
      const response = await request(app)
        .get(`/api/location/drivers/${fakeDriverId}/location`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Driver not found');
    });
  });

  describe('GET /api/location/history', () => {
    beforeEach(async () => {
      // Create test locations
      await Location.create([
        {
          latitude: -26.2041,
          longitude: 28.0473,
          address: { formatted: 'Test Location 1' },
          type: 'pickup',
          userId: testUser._id
        },
        {
          latitude: -26.2141,
          longitude: 28.0573,
          address: { formatted: 'Test Location 2' },
          type: 'dropoff',
          userId: testUser._id
        }
      ]);
    });

    it('should get location history successfully', async () => {
      const response = await request(app)
        .get('/api/location/history')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(2);
      expect(response.body.pagination.total).toBe(2);
    });

    it('should filter by type', async () => {
      const response = await request(app)
        .get('/api/location/history')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ type: 'pickup' });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].type).toBe('pickup');
    });
  });

  describe('POST /api/location/save', () => {
    it('should save location successfully', async () => {
      const locationData = {
        latitude: -26.2041,
        longitude: 28.0473,
        address: {
          formatted: 'Test Location',
          city: 'Johannesburg',
          country: 'South Africa'
        },
        type: 'pickup',
        category: 'residential',
        notes: 'Test location'
      };

      const response = await request(app)
        .post('/api/location/save')
        .set('Authorization', `Bearer ${authToken}`)
        .send(locationData);

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data.latitude).toBe(-26.2041);
      expect(response.body.data.longitude).toBe(28.0473);
      expect(response.body.data.userId).toBe(testUser._id.toString());
    });

    it('should return error for missing coordinates', async () => {
      const response = await request(app)
        .post('/api/location/save')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          address: { formatted: 'Test Location' }
        });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Latitude and longitude are required');
    });
  });

  describe('GET /api/location/nearby-saved', () => {
    beforeEach(async () => {
      // Create test locations
      await Location.create([
        {
          latitude: -26.2041,
          longitude: 28.0473,
          address: { formatted: 'Nearby Location 1' },
          type: 'pickup',
          userId: testUser._id,
          isActive: true
        },
        {
          latitude: -26.2141,
          longitude: 28.0573,
          address: { formatted: 'Far Location' },
          type: 'dropoff',
          userId: testUser._id,
          isActive: true
        }
      ]);
    });

    it('should find nearby saved locations', async () => {
      const response = await request(app)
        .get('/api/location/nearby-saved')
        .set('Authorization', `Bearer ${authToken}`)
        .query({
          latitude: -26.2041,
          longitude: 28.0473,
          radius: 5
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.length).toBeGreaterThan(0);
    });
  });

  describe('PUT /api/location/:id', () => {
    let testLocation;

    beforeEach(async () => {
      testLocation = await Location.create({
        latitude: -26.2041,
        longitude: 28.0473,
        address: { formatted: 'Test Location' },
        type: 'pickup',
        userId: testUser._id
      });
    });

    it('should update location successfully', async () => {
      const updateData = {
        type: 'dropoff',
        notes: 'Updated location'
      };

      const response = await request(app)
        .put(`/api/location/${testLocation._id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(updateData);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.type).toBe('dropoff');
    });

    it('should return 404 for non-existent location', async () => {
      const fakeLocationId = new mongoose.Types.ObjectId();
      
      const response = await request(app)
        .put(`/api/location/${fakeLocationId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ type: 'dropoff' });

      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Location not found');
    });
  });

  describe('DELETE /api/location/:id', () => {
    let testLocation;

    beforeEach(async () => {
      testLocation = await Location.create({
        latitude: -26.2041,
        longitude: 28.0473,
        address: { formatted: 'Test Location' },
        type: 'pickup',
        userId: testUser._id
      });
    });

    it('should delete location successfully', async () => {
      const response = await request(app)
        .delete(`/api/location/${testLocation._id}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.message).toBe('Location deleted successfully');

      // Verify location is marked as inactive
      const deletedLocation = await Location.findById(testLocation._id);
      expect(deletedLocation.isActive).toBe(false);
    });

    it('should return 404 for non-existent location', async () => {
      const fakeLocationId = new mongoose.Types.ObjectId();
      
      const response = await request(app)
        .delete(`/api/location/${fakeLocationId}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Location not found');
    });
  });
});
