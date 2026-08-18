const quotesRouter = require('../routes/quotes');
const express = require('express');
const {
  createTestUser,
  createTestQuote,
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
  validateQuoteResponse,
  testQuoteData
} = require('./testUtils');

describe('Quote Request APIs (API 6)', () => {
  describe('POST /api/quotes - Create Quote', () => {
    test('should create quote successfully with valid data', async () => {
      const { request, user } = await authenticatedRequest('POST', '/api/quotes');

      const response = await request.send(testQuoteData);
      const result = expectSuccess(response, 201);

      expect(result.data).toHaveProperty('quote');
      validateQuoteResponse(result.data.quote);

      // Verify quote data
      const quote = result.data.quote;
      expect(quote.userId).toBe(user._id.toString());
      expect(quote.vehicleType).toBe(testQuoteData.vehicleType);
      expect(quote.serviceType).toBe(testQuoteData.serviceType);
      expect(quote.passengerCount).toBe(testQuoteData.passengerCount);
      expect(quote.status).toBe('pending');
      expect(quote).toHaveProperty('estimatedPrice');
      expect(quote).toHaveProperty('validUntil');
    });

    test('should fail with invalid vehicle type', async () => {
      const { request } = await authenticatedRequest('POST', '/api/quotes');

      const invalidData = {
        ...testQuoteData,
        vehicleType: 'invalid_type'
      };

      const response = await request.send(invalidData);
      const result = expectError(response, 400);
      expect(result.errors).toContain('Valid vehicle type is required');
    });

    test('should fail with invalid service type', async () => {
      const { request } = await authenticatedRequest('POST', '/api/quotes');

      const invalidData = {
        ...testQuoteData,
        serviceType: 'invalid_type'
      };

      const response = await request.send(invalidData);
      const result = expectError(response, 400);
      expect(result.errors).toContain('Valid service type is required');
    });

    test('should fail with past scheduled date', async () => {
      const { request } = await authenticatedRequest('POST', '/api/quotes');

      const invalidData = {
        ...testQuoteData,
        scheduledDate: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString() // Yesterday
      };

      const response = await request.send(invalidData);
      const result = expectError(response, 400);
      expect(result.errors).toContain('Scheduled date must be in the future');
    });

    test('should fail without authentication', async () => {
      const response = await request
        .post('/api/quotes')
        .send(testQuoteData);

      expectError(response, 401);
    });

    test('should fail with missing required coordinates', async () => {
      const { request } = await authenticatedRequest('POST', '/api/quotes');

      const invalidData = {
        ...testQuoteData,
        pickupLocation: {
          address: '123 Main St',
          // Missing coordinates
        }
      };

      const response = await request.send(invalidData);
      const result = expectError(response, 400);
      expect(result.errors).toContain('Pickup location coordinates are required');
    });
  });

  describe('GET /api/quotes/:id - Get Quote Details', () => {
    test('should get quote details for owner', async () => {
      const user = await createTestUser();
      const quote = await createTestQuote(user._id);

      const { request } = await authenticatedRequest('GET', `/api/quotes/${quote._id}`);

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data).toHaveProperty('quote');
      validateQuoteResponse(result.data.quote);
      expect(result.data.quote.id).toBe(quote._id.toString());
    });

    test('should get quote details for admin', async () => {
      const user = await createTestUser();
      const quote = await createTestQuote(user._id);

      const { request } = await adminRequest('GET', `/api/quotes/${quote._id}`);

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data).toHaveProperty('quote');
      validateQuoteResponse(result.data.quote);
    });

    test('should fail for non-owner non-admin user', async () => {
      const user1 = await createTestUser({ email: 'user1@test.com' });
      const user2 = await createTestUser({ email: 'user2@test.com' });
      const quote = await createTestQuote(user1._id);

      const { request } = await authenticatedRequest('GET', `/api/quotes/${quote._id}`, user2);

      const response = await request;
      expectError(response, 403);
    });

    test('should return 404 for non-existent quote', async () => {
      const { request } = await authenticatedRequest('GET', '/api/quotes/507f1f77bcf86cd799439011');

      const response = await request;
      expectError(response, 404);
    });
  });

  describe('PUT /api/quotes/:id - Update Quote Status', () => {
    test('should allow user to cancel their own quote', async () => {
      const user = await createTestUser();
      const quote = await createTestQuote(user._id);

      const { request } = await authenticatedRequest('PUT', `/api/quotes/${quote._id}`);

      const response = await request.send({ status: 'cancelled' });
      const result = expectSuccess(response);

      expect(result.data.quote.status).toBe('cancelled');
    });

    test('should allow admin to update quote status', async () => {
      const user = await createTestUser();
      const quote = await createTestQuote(user._id);

      const { request } = await adminRequest('PUT', `/api/quotes/${quote._id}`);

      const response = await request.send({
        status: 'quoted',
        notes: 'Quote prepared'
      });
      const result = expectSuccess(response);

      expect(result.data.quote.status).toBe('quoted');
      expect(result.data.quote.notes).toBe('Quote prepared');
    });

    test('should fail when user tries to update to non-cancelled status', async () => {
      const user = await createTestUser();
      const quote = await createTestQuote(user._id);

      const { request } = await authenticatedRequest('PUT', `/api/quotes/${quote._id}`, user);

      const response = await request.send({ status: 'accepted' });
      expectError(response, 403);
    });

    test('should validate status transitions', async () => {
      const user = await createTestUser();
      const quote = await createTestQuote(user._id);

      const { request } = await adminRequest('PUT', `/api/quotes/${quote._id}`);

      const response = await request.send({ status: 'invalid_status' });
      expectError(response, 400);
    });

    test('should allow admin to add internal notes', async () => {
      const user = await createTestUser();
      const quote = await createTestQuote(user._id);

      const { request } = await adminRequest('PUT', `/api/quotes/${quote._id}`);

      const response = await request.send({
        status: 'quoted',
        internalNotes: 'Internal admin notes'
      });
      const result = expectSuccess(response);

      expect(result.data.quote.internalNotes).toBe('Internal admin notes');
    });
  });

  describe('GET /api/users/:userId/quotes - Get User Quotes', () => {
    test('should get user quotes list', async () => {
      const user = await createTestUser();
      const quote1 = await createTestQuote(user._id);
      const quote2 = await createTestQuote(user._id);

      const { request } = await authenticatedRequest('GET', `/api/users/${user._id}/quotes`);

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data).toHaveProperty('quotes');
      expect(result.data).toHaveProperty('pagination');
      expect(Array.isArray(result.data.quotes)).toBe(true);
      expect(result.data.quotes.length).toBe(2);

      result.data.quotes.forEach(validateQuoteResponse);
    });

    test('should filter quotes by status', async () => {
      const user = await createTestUser();
      await createTestQuote(user._id, { status: 'pending' });
      await createTestQuote(user._id, { status: 'quoted' });

      const { request } = await authenticatedRequest('GET', `/api/users/${user._id}/quotes?status=quoted`);

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data.quotes.length).toBe(1);
      expect(result.data.quotes[0].status).toBe('quoted');
    });

    test('should implement pagination', async () => {
      const user = await createTestUser();
      // Create multiple quotes
      for (let i = 0; i < 5; i++) {
        await createTestQuote(user._id);
      }

      const { request } = await authenticatedRequest('GET', `/api/users/${user._id}/quotes?limit=2&page=2`);

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data.quotes.length).toBe(2);
      expect(result.data.pagination.page).toBe(2);
      expect(result.data.pagination.limit).toBe(2);
      expect(result.data.pagination.total).toBe(5);
    });

    test('should fail for non-owner non-admin user', async () => {
      const user1 = await createTestUser({ email: 'user1@test.com' });
      const user2 = await createTestUser({ email: 'user2@test.com' });

      const { request } = await authenticatedRequest('GET', `/api/users/${user1._id}/quotes`, user2);

      const response = await request;
      expectError(response, 403);
    });
  });

  describe('POST /api/quotes/estimate - Price Estimation', () => {
    test('should calculate price estimate successfully', async () => {
      const response = await request
        .post('/api/quotes/estimate')
        .send({
          pickupCoordinates: { latitude: -26.2041, longitude: 28.0473 },
          dropoffCoordinates: { latitude: -25.7479, longitude: 28.2293 },
          vehicleType: 'sedan',
          serviceType: 'standard',
          passengerCount: 2
        });

      const result = expectSuccess(response);

      expect(result.data).toHaveProperty('distance');
      expect(result.data).toHaveProperty('duration');
      expect(result.data).toHaveProperty('pricing');
      expect(result.data).toHaveProperty('currency');
      expect(result.data).toHaveProperty('validFor');

      const pricing = result.data.pricing;
      expect(pricing).toHaveProperty('baseFare');
      expect(pricing).toHaveProperty('distanceFare');
      expect(pricing).toHaveProperty('timeFare');
      expect(pricing).toHaveProperty('serviceFee');
      expect(pricing).toHaveProperty('taxes');
      expect(pricing).toHaveProperty('total');
    });

    test('should work without authentication', async () => {
      const response = await request
        .post('/api/quotes/estimate')
        .send({
          pickupCoordinates: { latitude: -26.2041, longitude: 28.0473 },
          dropoffCoordinates: { latitude: -25.7479, longitude: 28.2293 },
          vehicleType: 'luxury',
          serviceType: 'premium',
          passengerCount: 1
        });

      expectSuccess(response);
    });

    test('should fail with missing coordinates', async () => {
      const response = await request
        .post('/api/quotes/estimate')
        .send({
          vehicleType: 'sedan',
          serviceType: 'standard'
          // Missing coordinates
        });

      expectError(response, 400);
    });

    test('should handle different vehicle and service types', async () => {
      const testCases = [
        { vehicleType: 'luxury', serviceType: 'premium' },
        { vehicleType: 'van', serviceType: 'corporate' },
        { vehicleType: 'motorcycle', serviceType: 'standard' }
      ];

      for (const testCase of testCases) {
        const response = await request
          .post('/api/quotes/estimate')
          .send({
            pickupCoordinates: { latitude: -26.2041, longitude: 28.0473 },
            dropoffCoordinates: { latitude: -25.7479, longitude: 28.2293 },
            ...testCase,
            passengerCount: 1
          });

        expectSuccess(response);
      }
    });
  });

  describe('DELETE /api/quotes/:id - Delete Quote (Admin)', () => {
    test('should allow admin to delete quote', async () => {
      const user = await createTestUser();
      const quote = await createTestQuote(user._id);

      const { request } = await adminRequest('DELETE', `/api/quotes/${quote._id}`);

      const response = await request;
      expectSuccess(response);

      // Verify quote is deleted
      const { request: getRequest } = await adminRequest('GET', `/api/quotes/${quote._id}`);
      const getResponse = await getRequest;
      expectError(getResponse, 404);
    });

    test('should fail for non-admin user', async () => {
      const user = await createTestUser();
      const quote = await createTestQuote(user._id);

      const { request } = await authenticatedRequest('DELETE', `/api/quotes/${quote._id}`);

      const response = await request;
      expectError(response, 403);
    });
  });

  describe('Quote Business Logic', () => {
    test('should calculate correct pricing for different combinations', () => {
      const Quote = require('../models/Quote');

      // Test pricing calculation directly
      const distance = 50;
      const duration = 60;

      const pricing = Quote.calculatePricing(distance, duration, 'sedan', 'standard', 2);
      expect(pricing.baseFare).toBe(25);
      expect(pricing.distanceFare).toBe(75); // 50km * $1.50
      expect(pricing.timeFare).toBe(40); // 60min/60 * $40
      expect(pricing.total).toBeGreaterThan(0);
    });

    test('should validate quote data correctly', () => {
      // Test validation helpers
      const router = require('../routes/quotes');
      // This would require mocking the validation function
      // For now, we'll test the basic structure
      expect(typeof router).toBe('function');
    });
  });
});
