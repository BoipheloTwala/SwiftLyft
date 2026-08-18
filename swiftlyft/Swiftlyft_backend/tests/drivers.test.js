const mongoose = require('mongoose');
const {
  createTestUser,
  createTestDriver,
  createMockRequest,
  createMockResponse,
  createMockNext
} = require('./setup');
const {
  request,
  authenticatedRequest,
  adminRequest,
  expectSuccess,
  expectError,
  validateDriverResponse,
  testDriverData
} = require('./testUtils');

describe('Driver Management APIs (API 7)', () => {
  describe('POST /api/drivers - Driver Registration', () => {
    test('should register driver successfully with valid data', async () => {
      const user = await createTestUser();

      const { request } = await authenticatedRequest('POST', '/api/drivers');

      const response = await request.send(testDriverData);
      const result = expectSuccess(response, 201);

      expect(result.data).toHaveProperty('driver');
      validateDriverResponse(result.data.driver);

      // Verify driver data
      const driver = result.data.driver;
      expect(driver.userId).toBe(user._id.toString());
      expect(driver.licenseNumber).toBe(testDriverData.licenseNumber);
      expect(driver.vehicleInfo.make).toBe(testDriverData.vehicleInfo.make);
      expect(driver.vehicleInfo.vehicleType).toBe(testDriverData.vehicleInfo.vehicleType);
      expect(driver.status).toBe('pending'); // Should start as pending
    });

    test('should fail if user already has a driver profile', async () => {
      const user = await createTestUser();
      await createTestDriver(user._id); // Create first driver profile

      const { request } = await authenticatedRequest('POST', '/api/drivers');

      const response = await request.send(testDriverData);
      expectError(response, 400);
    });

    test('should fail with invalid license expiry date', async () => {
      const { request } = await authenticatedRequest('POST', '/api/drivers');

      const invalidData = {
        ...testDriverData,
        licenseExpiry: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString() // Past date
      };

      const response = await request.send(invalidData);
      const result = expectError(response, 400);
      expect(result.errors).toContain('Valid license expiry date is required');
    });

    test('should fail with missing vehicle information', async () => {
      const { request } = await authenticatedRequest('POST', '/api/drivers');

      const invalidData = {
        ...testDriverData,
        vehicleInfo: {} // Empty vehicle info
      };

      const response = await request.send(invalidData);
      const result = expectError(response, 400);
      expect(result.errors).toContain('Vehicle information is required');
    });

    test('should fail with missing bank details', async () => {
      const { request } = await authenticatedRequest('POST', '/api/drivers');

      const invalidData = {
        ...testDriverData,
        bankDetails: {} // Empty bank details
      };

      const response = await request.send(invalidData);
      const result = expectError(response, 400);
      expect(result.errors).toContain('Bank details are required');
    });

    test('should fail without authentication', async () => {
      const response = await request
        .post('/api/drivers')
        .send(testDriverData);

      expectError(response, 401);
    });

    test('should handle file uploads (documents)', async () => {
      const user = await createTestUser();

      const { request } = await authenticatedRequest('POST', '/api/drivers');

      // Mock file upload by adding files to the request
      const response = await request
        .field('licenseNumber', testDriverData.licenseNumber)
        .field('licenseExpiry', testDriverData.licenseExpiry)
        .field('vehicleInfo', JSON.stringify(testDriverData.vehicleInfo))
        .field('bankDetails', JSON.stringify(testDriverData.bankDetails))
        .field('emergencyContact', JSON.stringify(testDriverData.emergencyContact))
        .attach('licensePhoto', Buffer.from('fake image'), 'license.jpg')
        .attach('vehicleRegistration', Buffer.from('fake image'), 'registration.jpg')
        .attach('vehicleInsurance', Buffer.from('fake image'), 'insurance.jpg');

      expectSuccess(response, 201);
    });
  });

  describe('GET /api/drivers/:id - Get Driver Details', () => {
    test('should get driver details for profile owner', async () => {
      const user = await createTestUser();
      const driver = await createTestDriver(user._id);

      const { request } = await authenticatedRequest('GET', `/api/drivers/${driver._id}`);

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data).toHaveProperty('driver');
      validateDriverResponse(result.data.driver);
      expect(result.data.driver.id).toBe(driver._id.toString());
    });

    test('should get driver details for admin', async () => {
      const user = await createTestUser();
      const driver = await createTestDriver(user._id);

      const { request } = await adminRequest('GET', `/api/drivers/${driver._id}`);

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data).toHaveProperty('driver');
      validateDriverResponse(result.data.driver);
      expect(result.data.driver.userId.name).toBeDefined(); // Should populate user info
    });

    test('should fail for non-owner non-admin user', async () => {
      const user1 = await createTestUser({ email: 'user1@test.com' });
      const user2 = await createTestUser({ email: 'user2@test.com' });
      const driver = await createTestDriver(user1._id);

      const { request } = await authenticatedRequest('GET', `/api/drivers/${driver._id}`, user2);

      const response = await request;
      expectError(response, 403);
    });

    test('should return 404 for non-existent driver', async () => {
      const { request } = await authenticatedRequest('GET', '/api/drivers/507f1f77bcf86cd799439011');

      const response = await request;
      expectError(response, 404);
    });
  });

  describe('PUT /api/drivers/:id/availability - Update Driver Availability', () => {
    test('should update driver availability to online', async () => {
      const user = await createTestUser();
      const driver = await createTestDriver(user._id);

      const { request } = await authenticatedRequest('PUT', `/api/drivers/${driver._id}/availability`, user);

      const response = await request.send({
        status: 'online',
        workingHours: {
          start: '08:00',
          end: '18:00'
        }
      });
      const result = expectSuccess(response);

      expect(result.data.availability.status).toBe('online');
      expect(result.data.availability.workingHours.start).toBe('08:00');
      expect(result.data.availability.workingHours.end).toBe('18:00');
    });

    test('should update driver availability to offline', async () => {
      const user = await createTestUser();
      const driver = await createTestDriver(user._id);

      const { request } = await authenticatedRequest('PUT', `/api/drivers/${driver._id}/availability`, user);

      const response = await request.send({ status: 'offline' });
      const result = expectSuccess(response);

      expect(result.data.availability.status).toBe('offline');
    });

    test('should fail for non-owner user', async () => {
      const user1 = await createTestUser({ email: 'user1@test.com' });
      const user2 = await createTestUser({ email: 'user2@test.com' });
      const driver = await createTestDriver(user1._id);

      const { request } = await authenticatedRequest('PUT', `/api/drivers/${driver._id}/availability`, user2);

      const response = await request.send({ status: 'online' });
      expectError(response, 403);
    });

    test('should validate availability status', async () => {
      const user = await createTestUser();
      const driver = await createTestDriver(user._id);

      const { request } = await authenticatedRequest('PUT', `/api/drivers/${driver._id}/availability`, user);

      const response = await request.send({ status: 'invalid_status' });
      expectError(response, 400);
    });

    test('should handle available until date', async () => {
      const user = await createTestUser();
      const driver = await createTestDriver(user._id);

      const { request } = await authenticatedRequest('PUT', `/api/drivers/${driver._id}/availability`, user);

      const futureDate = new Date(Date.now() + 8 * 60 * 60 * 1000); // 8 hours from now
      const response = await request.send({
        status: 'busy',
        availableUntil: futureDate.toISOString()
      });
      const result = expectSuccess(response);

      expect(result.data.availability.status).toBe('busy');
      expect(result.data.availability.availableUntil).toBeDefined();
    });
  });

  describe('PUT /api/drivers/:id/location - Update Driver Location', () => {
    test('should update driver location successfully', async () => {
      const user = await createTestUser();
      const driver = await createTestDriver(user._id);

      const { request } = await authenticatedRequest('PUT', `/api/drivers/${driver._id}/location`, user);

      const newLocation = {
        latitude: -25.7479,
        longitude: 28.2293,
        address: 'New Location, Pretoria'
      };

      const response = await request.send(newLocation);
      const result = expectSuccess(response);

      expect(result.data.location.coordinates.latitude).toBe(newLocation.latitude);
      expect(result.data.location.coordinates.longitude).toBe(newLocation.longitude);
      expect(result.data.location.address).toBe(newLocation.address);
    });

    test('should fail with missing coordinates', async () => {
      const user = await createTestUser();
      const driver = await createTestDriver(user._id);

      const { request } = await authenticatedRequest('PUT', `/api/drivers/${driver._id}/location`);

      const response = await request.send({ address: 'Test Address' });
      expectError(response, 400);
    });

    test('should fail for non-owner user', async () => {
      const user1 = await createTestUser();
      const user2 = await createTestUser();
      const driver = await createTestDriver(user1._id);

      const { request } = await authenticatedRequest('PUT', `/api/drivers/${driver._id}/location`, user2);

      const response = await request.send({
        latitude: -25.7479,
        longitude: 28.2293
      });
      expectError(response, 403);
    });

    test('should update location timestamp', async () => {
      const user = await createTestUser();
      const driver = await createTestDriver(user._id);

      const beforeUpdate = new Date();

      const { request } = await authenticatedRequest('PUT', `/api/drivers/${driver._id}/location`, user);

      const response = await request.send({
        latitude: -25.7479,
        longitude: 28.2293
      });
      const result = expectSuccess(response);

      const updatedAt = new Date(result.data.location.lastUpdated);
      expect(updatedAt.getTime()).toBeGreaterThanOrEqual(beforeUpdate.getTime());
    });
  });

  describe('GET /api/drivers/:id/assignments - Get Driver Assignments', () => {
    test('should get driver assignments for owner', async () => {
      const user = await createTestUser();
      const driver = await createTestDriver(user._id);

      const { request } = await authenticatedRequest('GET', `/api/drivers/${driver._id}/assignments`);

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data).toHaveProperty('assignments');
      expect(result.data).toHaveProperty('currentBookingId');
      expect(Array.isArray(result.data.assignments)).toBe(true);
    });

    test('should get driver assignments for admin', async () => {
      const user = await createTestUser();
      const driver = await createTestDriver(user._id);

      const { request } = await adminRequest('GET', `/api/drivers/${driver._id}/assignments`);

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data).toHaveProperty('assignments');
      expect(result.data).toHaveProperty('currentBookingId');
    });

    test('should fail for non-owner non-admin user', async () => {
      const user1 = await createTestUser({ email: 'user1@test.com' });
      const user2 = await createTestUser({ email: 'user2@test.com' });
      const driver = await createTestDriver(user1._id);

      const { request } = await authenticatedRequest('GET', `/api/drivers/${driver._id}/assignments`, user2);

      const response = await request;
      expectError(response, 403);
    });

    test('should return empty assignments when no current booking', async () => {
      const user = await createTestUser();
      const driver = await createTestDriver(user._id);

      const { request } = await authenticatedRequest('GET', `/api/drivers/${driver._id}/assignments`);

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data.assignments).toHaveLength(0);
      expect(result.data.currentBookingId).toBeFalsy();
    });
  });

  describe('GET /api/drivers/:id/performance - Get Driver Performance', () => {
    test('should get driver performance metrics for owner', async () => {
      const user = await createTestUser();
      const driver = await createTestDriver(user._id);

      const { request } = await authenticatedRequest('GET', `/api/drivers/${driver._id}/performance`);

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data).toHaveProperty('performance');
      expect(result.data).toHaveProperty('overallRating');
      expect(result.data).toHaveProperty('totalTrips');
      expect(result.data).toHaveProperty('completionRate');
      expect(result.data).toHaveProperty('status');
    });

    test('should get driver performance metrics for admin', async () => {
      const user = await createTestUser();
      const driver = await createTestDriver(user._id);

      const { request } = await adminRequest('GET', `/api/drivers/${driver._id}/performance`);

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data).toHaveProperty('performance');
      expect(result.data).toHaveProperty('overallRating');
      expect(result.data).toHaveProperty('totalTrips');
    });

    test('should fail for non-owner non-admin user', async () => {
      const user1 = await createTestUser({ email: 'user1@test.com' });
      const user2 = await createTestUser({ email: 'user2@test.com' });
      const driver = await createTestDriver(user1._id);

      const { request } = await authenticatedRequest('GET', `/api/drivers/${driver._id}/performance`, user2);

      const response = await request;
      expectError(response, 403);
    });

    test('should return 404 for non-existent driver', async () => {
      const { request } = await authenticatedRequest('GET', '/api/drivers/507f1f77bcf86cd799439011/performance');

      const response = await request;
      expectError(response, 404);
    });
  });

  describe('GET /api/drivers/available - Find Available Drivers (Admin)', () => {
    test('should find available drivers within distance', async () => {
      // Create multiple drivers with different locations
      const user1 = await createTestUser({ email: 'driver1@test.com' });
      const user2 = await createTestUser({ email: 'driver2@test.com' });
      const driver1 = await createTestDriver(user1._id, {
        currentLocation: {
          coordinates: { latitude: -26.2041, longitude: 28.0473 },
          address: 'Near Johannesburg'
        },
        availability: { status: 'online' },
        status: 'active'
      });

      const driver2 = await createTestDriver(user2._id, {
        currentLocation: {
          coordinates: { latitude: -25.7479, longitude: 28.2293 },
          address: 'Near Pretoria'
        },
        availability: { status: 'online' },
        status: 'active'
      });

      const { request } = await adminRequest('GET', '/api/drivers/available?latitude=-26.2041&longitude=28.0473&maxDistance=10000');

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data).toHaveProperty('drivers');
      expect(result.data).toHaveProperty('count');
      expect(Array.isArray(result.data.drivers)).toBe(true);
      expect(result.data.count).toBeGreaterThan(0);

      // Check driver data structure
      result.data.drivers.forEach(driver => {
        expect(driver).toHaveProperty('id');
        expect(driver).toHaveProperty('driverId');
        expect(driver).toHaveProperty('name');
        expect(driver).toHaveProperty('phone');
        expect(driver).toHaveProperty('vehicleType');
        expect(driver).toHaveProperty('rating');
        expect(driver).toHaveProperty('location');
      });
    });

    test('should filter by vehicle type', async () => {
      const user1 = await createTestUser({ email: 'driver1@test.com' });
      const driver1 = await createTestDriver(user1._id, {
        vehicleInfo: {
          make: 'Toyota',
          model: 'Corolla',
          year: 2020,
          color: 'White',
          licensePlate: `ABC${Date.now().toString().slice(-3)}`,
          vehicleType: 'sedan',
          passengerCapacity: 4
        },
        availability: { status: 'online' },
        status: 'active'
      });

      const user2 = await createTestUser({ email: 'driver2@test.com' });
      const driver2 = await createTestDriver(user2._id, {
        vehicleInfo: {
          make: 'Mercedes',
          model: 'S-Class',
          year: 2022,
          color: 'Black',
          licensePlate: `XYZ${Date.now().toString().slice(-3)}`,
          vehicleType: 'luxury',
          passengerCapacity: 4
        },
        availability: { status: 'online' },
        status: 'active'
      });

      const { request } = await adminRequest('GET', '/api/drivers/available?latitude=-26.2041&longitude=28.0473&vehicleType=luxury');

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data.drivers.length).toBeGreaterThan(0);
      result.data.drivers.forEach(driver => {
        expect(driver.vehicleType).toBe('luxury');
      });
    });

    test('should fail without coordinates', async () => {
      const { request } = await adminRequest('GET', '/api/drivers/available');

      const response = await request;
      expectError(response, 400);
    });

    test('should fail for non-admin user', async () => {
      const { request } = await authenticatedRequest('GET', '/api/drivers/available');

      const response = await request;
      expectError(response, 403);
    });
  });

  describe('PUT /api/drivers/:id/status - Update Driver Status (Admin)', () => {
    test('should approve driver application', async () => {
      const user = await createTestUser();
      const driver = await createTestDriver(user._id);

      const { request } = await adminRequest('PUT', `/api/drivers/${driver._id}/status`);

      const response = await request.send({
        status: 'approved',
        notes: 'Application approved'
      });
      const result = expectSuccess(response);

      expect(result.data.driver.status).toBe('approved');
    });

    test('should reject driver application', async () => {
      const user = await createTestUser();
      const driver = await createTestDriver(user._id);

      const { request } = await adminRequest('PUT', `/api/drivers/${driver._id}/status`);

      const response = await request.send({
        status: 'rejected',
        notes: 'Application incomplete'
      });
      const result = expectSuccess(response);

      expect(result.data.driver.status).toBe('rejected');
    });

    test('should suspend active driver', async () => {
      const user = await createTestUser();
      const driver = await createTestDriver(user._id, { status: 'active' });

      const { request } = await adminRequest('PUT', `/api/drivers/${driver._id}/status`);

      const response = await request.send({
        status: 'suspended',
        notes: 'Violation of terms'
      });
      const result = expectSuccess(response);

      expect(result.data.driver.status).toBe('suspended');
    });

    test('should validate status values', async () => {
      const user = await createTestUser();
      const driver = await createTestDriver(user._id);

      const { request } = await adminRequest('PUT', `/api/drivers/${driver._id}/status`);

      const response = await request.send({ status: 'invalid_status' });
      expectError(response, 400);
    });

    test('should fail for non-admin user', async () => {
      const user = await createTestUser();
      const driver = await createTestDriver(user._id);

      const { request } = await authenticatedRequest('PUT', `/api/drivers/${driver._id}/status`);

      const response = await request.send({ status: 'approved' });
      expectError(response, 403);
    });
  });

  describe('Driver Model Methods', () => {
    test('should update location correctly', async () => {
      const user = await createTestUser();
      const driver = await createTestDriver(user._id);

      const newLat = -25.7479;
      const newLng = 28.2293;
      const newAddress = 'Updated Location';

      await driver.updateLocation(newLat, newLng, newAddress);

      expect(driver.currentLocation.coordinates.latitude).toBe(newLat);
      expect(driver.currentLocation.coordinates.longitude).toBe(newLng);
      expect(driver.currentLocation.address).toBe(newAddress);
      expect(driver.currentLocation.lastUpdated).toBeDefined();
    });

    test('should update availability correctly', async () => {
      const user = await createTestUser();
      const driver = await createTestDriver(user._id);

      await driver.updateAvailability('busy');

      expect(driver.availability.status).toBe('busy');

      const futureDate = new Date(Date.now() + 2 * 60 * 60 * 1000); // 2 hours
      await driver.updateAvailability('online', futureDate);

      expect(driver.availability.status).toBe('online');
      expect(driver.availability.availableUntil).toEqual(futureDate);
    });

    test('should calculate virtual properties correctly', async () => {
      const user = await createTestUser();
      const driver = await createTestDriver(user._id, {
        availability: { status: 'online' },
        status: 'active',
        currentBookingId: null
      });

      expect(driver.isAvailable).toBe(true);

      // Test when driver has booking
      driver.currentBookingId = new mongoose.Types.ObjectId();
      expect(driver.isAvailable).toBe(false);

      // Test when driver is offline
      driver.availability.status = 'offline';
      expect(driver.isAvailable).toBe(false);
    });

    test('should update performance metrics', async () => {
      const user = await createTestUser();
      const driver = await createTestDriver(user._id);

      await driver.updatePerformance({
        rating: 4.5,
        earnings: 50,
        completed: true
      });

      expect(driver.performance.totalRides).toBe(1);
      expect(driver.performance.completedRides).toBe(1);
      expect(driver.performance.totalEarnings).toBe(50);
      expect(driver.performance.rating).toBe(4.5);
    });
  });
});
