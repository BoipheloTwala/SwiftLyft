const {
  Offer,
  CorporateBooking,
  SecurityService,
  AirportService
} = require('../models/SpecialFeatures');
const {
  createTestUser,
  createTestOffer
} = require('./setup');
const {
  request,
  authenticatedRequest,
  adminRequest,
  expectSuccess,
  expectError,
  validateOfferResponse,
  testOfferData
} = require('./testUtils');

describe('Special Features APIs (API 11)', () => {
  describe('GET /api/offers - Get Available Offers', () => {
    test('should get active offers', async () => {
      await createTestOffer();
      await createTestOffer({
        title: 'Second Offer',
        promoCode: 'SECOND20',
        type: 'discount',
        discountValue: 25
      });

      const response = await request.get('/api/offers');
      const result = expectSuccess(response);

      expect(result.data).toHaveProperty('offers');
      expect(result.data).toHaveProperty('count');
      expect(Array.isArray(result.data.offers)).toBe(true);
      expect(result.data.count).toBe(2);

      result.data.offers.forEach(validateOfferResponse);
    });

    test('should filter offers by user type', async () => {
      await createTestOffer({ targetAudience: 'new_users' });
      await createTestOffer({ targetAudience: 'loyalty_members' });

      const response = await request.get('/api/offers?userType=new_users');
      const result = expectSuccess(response);

      expect(result.data.offers.length).toBe(1);
      expect(result.data.offers[0].targetAudience).toBe('new_users');
    });

    test('should filter offers by vehicle type', async () => {
      await createTestOffer({
        title: 'Sedan Offer',
        conditions: { vehicleTypes: ['sedan'] }
      });
      await createTestOffer({
        title: 'SUV Offer',
        conditions: { vehicleTypes: ['suv'] }
      });

      const response = await request.get('/api/offers?vehicleType=sedan');
      const result = expectSuccess(response);

      expect(result.data.offers.length).toBe(1);
      expect(result.data.offers[0].title).toBe('Sedan Offer');
    });

    test('should implement pagination', async () => {
      // Create multiple offers
      for (let i = 0; i < 5; i++) {
        await createTestOffer({
          title: `Offer ${i}`,
          promoCode: `OFFER${i}`
        });
      }

      const response = await request.get('/api/offers?limit=2');
      const result = expectSuccess(response);

      expect(result.data.offers.length).toBe(2);
    });

    test('should check eligibility for authenticated users', async () => {
      const user = await createTestUser({ totalTrips: 0 }); // New user
      await createTestOffer({ targetAudience: 'new_users' });

      const { request: authRequest } = await authenticatedRequest('GET', '/api/offers');

      const response = await authRequest;
      const result = expectSuccess(response);

      // Should include the new user offer
      expect(result.data.offers.length).toBe(1);
    });
  });

  describe('POST /api/offers/validate - Validate Promo Code', () => {
    test('should validate valid promo code', async () => {
      const offer = await createTestOffer();

      const response = await request
        .post('/api/offers/validate')
        .send({
          promoCode: offer.promoCode,
          bookingAmount: 200
        });

      const result = expectSuccess(response);

      expect(result.data).toHaveProperty('offer');
      expect(result.data.offer.id).toBe(offer._id.toString());
      expect(result.data.offer.valid).toBe(true);
    });

    test('should reject invalid promo code', async () => {
      const response = await request
        .post('/api/offers/validate')
        .send({
          promoCode: 'INVALID123',
          bookingAmount: 200
        });

      expectError(response, 404);
    });

    test('should reject expired promo code', async () => {
      const expiredOffer = await createTestOffer({
        endDate: new Date(Date.now() - 24 * 60 * 60 * 1000) // Yesterday
      });

      const response = await request
        .post('/api/offers/validate')
        .send({
          promoCode: expiredOffer.promoCode,
          bookingAmount: 200
        });

      expectError(response, 400);
    });

    test('should validate usage conditions', async () => {
      const offer = await createTestOffer({
        minBookingAmount: 100,
        maxDiscountAmount: 50
      });

      // Test with insufficient amount
      const response = await request
        .post('/api/offers/validate')
        .send({
          promoCode: offer.promoCode,
          bookingAmount: 50 // Below minimum
        });

      expectError(response, 400);
    });

    test('should work without authentication', async () => {
      const offer = await createTestOffer();

      const response = await request
        .post('/api/offers/validate')
        .send({
          promoCode: offer.promoCode,
          bookingAmount: 200
        });

      expectSuccess(response);
    });
  });

  describe('POST /api/corporate/bookings - Create Corporate Booking', () => {
    test('should create corporate booking for corporate user', async () => {
      const corporateUser = await createTestUser({
        isCorporateUser: true,
        corporateAccount: {
          companyName: 'Test Corp',
          discountPercentage: 10
        }
      });

      const { request } = await authenticatedRequest('POST', '/api/corporate/bookings');

      const bookingData = {
        title: 'Team Building Event',
        description: 'Transportation for team building',
        bookingType: 'event_transport',
        trips: [
          {
            tripId: 'TRIP001',
            pickupLocation: 'Office A',
            dropoffLocation: 'Event Venue',
            estimatedCost: 500,
            pickupTime: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
            passengerCount: 10
          }
        ],
        specialInstructions: 'VIP service required'
      };

      const response = await request.send(bookingData);
      const result = expectSuccess(response, 201);

      expect(result.data).toHaveProperty('booking');
      const booking = result.data.booking;
      expect(booking.title).toBe(bookingData.title);
      expect(booking.bookingType).toBe(bookingData.bookingType);
      expect(booking.trips).toHaveLength(1);
      expect(booking.status).toBe('pending');
    });

    test('should calculate total estimated cost', async () => {
      const corporateUser = await createTestUser({
        isCorporateUser: true,
        corporateAccount: {
          companyName: 'Test Corp'
        }
      });

      const { request } = await authenticatedRequest('POST', '/api/corporate/bookings');

      const response = await request.send({
        title: 'Multi-trip booking',
        description: 'Multiple destinations',
        bookingType: 'business_travel',
        trips: [
          { tripId: 'TRIP001', estimatedCost: 300, pickupLocation: 'A', dropoffLocation: 'B', pickupTime: new Date().toISOString(), passengerCount: 2 },
          { tripId: 'TRIP002', estimatedCost: 450, pickupLocation: 'B', dropoffLocation: 'C', pickupTime: new Date().toISOString(), passengerCount: 3 }
        ]
      });

      const result = expectSuccess(response, 201);
      expect(result.data.booking.totalEstimatedCost).toBe(750); // 300 + 450
    });

    test('should fail for non-corporate user', async () => {
      const regularUser = await createTestUser();

      const { request } = await authenticatedRequest('POST', '/api/corporate/bookings');

      const response = await request.send({
        title: 'Test booking',
        bookingType: 'business',
        trips: [{
          tripId: 'TRIP001',
          pickupLocation: 'A',
          dropoffLocation: 'B',
          estimatedCost: 100,
          pickupTime: new Date().toISOString(),
          passengerCount: 1
        }]
      });

      expectError(response, 403);
    });

    test('should validate required fields', async () => {
      const corporateUser = await createTestUser({
        isCorporateUser: true,
        corporateAccount: { companyName: 'Test Corp' }
      });

      const { request } = await authenticatedRequest('POST', '/api/corporate/bookings');

      const response = await request.send({
        title: 'Test booking'
        // Missing bookingType and trips
      });

      expectError(response, 400);
    });
  });

  describe('GET /api/users/:userId/corporate/bookings - Get Corporate Bookings', () => {
    test('should get user corporate bookings', async () => {
      const corporateUser = await createTestUser({
        isCorporateUser: true,
        corporateAccount: { companyName: 'Test Corp' }
      });

      // Create a corporate booking
      await CorporateBooking.create({
        corporateAccountId: corporateUser.corporateAccount._id,
        userId: corporateUser._id,
        title: 'Test Booking',
        description: 'Test description',
        bookingType: 'business_travel',
        trips: [{
          tripId: 'TRIP001',
          pickupLocation: 'A',
          dropoffLocation: 'B',
          estimatedCost: 200,
          pickupTime: new Date(),
          passengerCount: 2
        }],
        totalEstimatedCost: 200
      });

      const { request } = await authenticatedRequest('GET', `/api/users/${corporateUser._id}/corporate/bookings`);

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data).toHaveProperty('bookings');
      expect(result.data).toHaveProperty('pagination');
      expect(Array.isArray(result.data.bookings)).toBe(true);
      expect(result.data.bookings.length).toBe(1);
    });

    test('should filter by status', async () => {
      const corporateUser = await createTestUser({
        isCorporateUser: true,
        corporateAccount: { companyName: 'Test Corp' }
      });

      await CorporateBooking.create([
        {
          corporateAccountId: corporateUser.corporateAccount._id,
          userId: corporateUser._id,
          title: 'Pending Booking',
          status: 'pending',
          bookingType: 'business',
          trips: [{ tripId: 'T1', pickupLocation: 'A', dropoffLocation: 'B', estimatedCost: 100, pickupTime: new Date(), passengerCount: 1 }],
          totalEstimatedCost: 100
        },
        {
          corporateAccountId: corporateUser.corporateAccount._id,
          userId: corporateUser._id,
          title: 'Approved Booking',
          status: 'approved',
          bookingType: 'business',
          trips: [{ tripId: 'T2', pickupLocation: 'C', dropoffLocation: 'D', estimatedCost: 150, pickupTime: new Date(), passengerCount: 1 }],
          totalEstimatedCost: 150
        }
      ]);

      const { request } = await authenticatedRequest('GET', `/api/users/${corporateUser._id}/corporate/bookings?status=approved`);

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data.bookings.length).toBe(1);
      expect(result.data.bookings[0].status).toBe('approved');
    });
  });

  describe('POST /api/bookings/security - Request Security Service', () => {
    test('should create security service request', async () => {
      const user = await createTestUser();

      const { request } = await authenticatedRequest('POST', '/api/bookings/security');

      const securityData = {
        bookingId: '507f1f77bcf86cd799439011', // Mock booking ID
        serviceType: 'close_protection',
        protectionLevel: 'standard',
        duration: 4, // 4 hours
        personnelCount: 2,
        requirements: {
          specialEquipment: ['bulletproof_vest'],
          language: 'English'
        },
        routeDetails: {
          pickupLocation: {
            address: 'Hotel',
            coordinates: { latitude: -26.2041, longitude: 28.0473 }
          },
          stops: [{
            address: 'Restaurant',
            coordinates: { latitude: -26.2041, longitude: 28.0473 },
            purpose: 'Dinner',
            duration: 60
          }],
          finalDestination: {
            address: 'Conference Center',
            coordinates: { latitude: -26.2041, longitude: 28.0473 }
          }
        },
        threatAssessment: {
          riskLevel: 'medium',
          specialConsiderations: 'Low to medium risk'
        },
        emergencyContacts: [
          { name: 'Emergency Contact', phone: '+1234567890', relationship: 'Assistant', priority: 1 }
        ],
        cost: {
          baseRate: 500,
          additionalCharges: 200,
          totalCost: 4200
        }
      };

      const response = await request.send(securityData);
      const result = expectSuccess(response, 201);

      expect(result.data).toHaveProperty('securityService');
      const service = result.data.securityService;
      expect(service.serviceType).toBe('close_protection');
      expect(service.protectionLevel).toBe('standard');
      expect(service.cost.totalCost).toBe(4100); // 500 * 4 * 2 = 4000 base, plus 100 equipment
    });

    test('should calculate cost based on service parameters', async () => {
      const user = await createTestUser();

      const { request } = await authenticatedRequest('POST', '/api/bookings/security');

      const response = await request.send({
        bookingId: '507f1f77bcf86cd799439011',
        serviceType: 'security_escort',
        protectionLevel: 'premium',
        duration: 2,
        personnelCount: 1,
        requirements: {},
        routeDetails: {
          pickupLocation: {
            address: 'Location A',
            coordinates: { latitude: -26.2041, longitude: 28.0473 }
          },
          finalDestination: {
            address: 'Location B',
            coordinates: { latitude: -25.7479, longitude: 28.2293 }
          }
        },
        threatAssessment: {
          riskLevel: 'low'
        },
        emergencyContacts: [],
        cost: {
          baseRate: 600,
          additionalCharges: 0,
          totalCost: 1200
        }
      });

      const result = expectSuccess(response, 201);
      expect(result.data.securityService.cost.totalCost).toBe(1200); // 600 * 2 * 1 = 1200
    });

    test('should validate required fields', async () => {
      const user = await createTestUser();

      const { request } = await authenticatedRequest('POST', '/api/bookings/security');

      const response = await request.send({
        serviceType: 'close_protection'
        // Missing other required fields
      });

      expectError(response, 400);
    });
  });

  describe('GET /api/services/airport - Get Airport Services Info', () => {
    test('should return airport services information', async () => {
      const response = await request.get('/api/services/airport');
      const result = expectSuccess(response);

      expect(result.data).toHaveProperty('supportedAirports');
      expect(result.data).toHaveProperty('services');
      expect(result.data).toHaveProperty('pricing');
      expect(result.data).toHaveProperty('advanceBooking');

      expect(Array.isArray(result.data.supportedAirports)).toBe(true);
      expect(Array.isArray(result.data.services)).toBe(true);
      expect(result.data.supportedAirports.length).toBeGreaterThan(0);
      expect(result.data.services.length).toBeGreaterThan(0);

      // Check specific airport
      const jnb = result.data.supportedAirports.find(airport => airport.code === 'JNB');
      expect(jnb).toBeDefined();
      expect(jnb.name).toBe('OR Tambo International Airport');
    });

    test('should include pricing information', async () => {
      const response = await request.get('/api/services/airport');
      const result = expectSuccess(response);

      const pricing = result.data.pricing;
      expect(pricing).toHaveProperty('baseFare');
      expect(pricing).toHaveProperty('airportSurcharge');
      expect(pricing).toHaveProperty('vipSurcharge');
      expect(pricing).toHaveProperty('waitingTimeRate');

      expect(pricing.baseFare).toBe(150);
      expect(pricing.airportSurcharge).toBe(50);
    });
  });

  describe('POST /api/bookings/airport - Book Airport Transfer', () => {
    test('should create airport transfer booking', async () => {
      const user = await createTestUser();

      const { request } = await authenticatedRequest('POST', '/api/bookings/airport');

      const airportData = {
        bookingId: '507f1f77bcf86cd799439011', // Mock booking ID
        serviceType: 'pickup',
        flightDetails: {
          airline: 'South African Airways',
          flightNumber: 'SA123',
          scheduledTime: new Date(Date.now() + 2 * 60 * 60 * 1000).toISOString(), // 2 hours from now
          departureTime: new Date(Date.now() + 2 * 60 * 60 * 1000).toISOString(),
          arrivalTime: new Date(Date.now() + 4 * 60 * 60 * 1000).toISOString()
        },
        passengerDetails: {
          count: 2,
          names: ['John Doe', 'Jane Doe'],
          specialNeeds: false
        },
        luggageDetails: {
          checkedBags: 2,
          carryOnBags: 1
        },
        vehicleRequirements: {
          vehicleType: 'sedan',
          features: ['AC', 'WiFi']
        },
        pickupLocation: {
          airport: 'JNB',
          terminal: 'International',
          address: 'OR Tambo International Airport'
        },
        notifications: {
          smsEnabled: true,
          emailEnabled: true
        },
        cost: {
          baseFare: 150,
          airportSurcharge: 50,
          waitingTimeCharges: 0,
          totalCost: 250
        }
      };

      const response = await request.send(airportData);
      const result = expectSuccess(response, 201);

      expect(result.data).toHaveProperty('airportService');
      const service = result.data.airportService;
      expect(service.serviceType).toBe('pickup');
      expect(service.flightDetails.airline).toBe('South African Airways');
      expect(service.passengerDetails.count).toBe(2);
      expect(service.cost.totalCost).toBe(250); // 150 + 50 + 50 (passenger surcharge)
    });

    test('should calculate VIP surcharge correctly', async () => {
      const user = await createTestUser();

      const { request } = await authenticatedRequest('POST', '/api/bookings/airport');

      const response = await request.send({
        bookingId: '507f1f77bcf86cd799439011',
        serviceType: 'meet_and_greet',
        flightDetails: {
          airline: 'British Airways',
          flightNumber: 'BA456',
          scheduledTime: new Date().toISOString(),
          departureTime: new Date().toISOString()
        },
        passengerDetails: { count: 1 },
        luggageDetails: {},
        vehicleRequirements: { vehicleType: 'luxury' },
        pickupLocation: { airport: 'JNB' },
        cost: {
          baseFare: 150,
          airportSurcharge: 50,
          waitingTimeCharges: 0,
          totalCost: 350
        }
      });

      const result = expectSuccess(response, 201);
      expect(result.data.airportService.cost.totalCost).toBe(350); // 150 + 50 + 150 (VIP) = 350
    });
  });

  describe('Offer Model Methods', () => {
    test('should check if offer can be applied', async () => {
      const user = await createTestUser({ totalTrips: 0 });
      const offer = await createTestOffer({
        targetAudience: 'new_users',
        minBookingAmount: 100,
        maxUsageCount: 100
      });

      expect(offer.canBeApplied(user, 150)).toBe(true);
      expect(offer.canBeApplied(user, 50)).toBe(false); // Below minimum amount

      // Test for non-new user
      const regularUser = await createTestUser({ totalTrips: 10 });
      expect(offer.canBeApplied(regularUser, 150)).toBe(false);
    });

    test('should check if offer is valid', async () => {
      const validOffer = await createTestOffer({
        isActive: true,
        startDate: new Date(Date.now() - 24 * 60 * 60 * 1000), // Started yesterday
        endDate: new Date(Date.now() + 24 * 60 * 60 * 1000) // Ends tomorrow
      });

      const expiredOffer = await createTestOffer({
        endDate: new Date(Date.now() - 24 * 60 * 60 * 1000) // Ended yesterday
      });

      expect(validOffer.isValid).toBe(true);
      expect(expiredOffer.isValid).toBe(false);
    });
  });

  describe('Corporate Booking Model Methods', () => {
    test('should update booking status', async () => {
      const corporateUser = await createTestUser({
        isCorporateUser: true,
        corporateAccount: { companyName: 'Test Corp' }
      });

      const booking = await CorporateBooking.create({
        corporateAccountId: corporateUser.corporateAccount._id,
        userId: corporateUser._id,
        title: 'Test Booking',
        bookingType: 'business',
        trips: [{ tripId: 'T1', pickupLocation: 'A', dropoffLocation: 'B', estimatedCost: 100, pickupTime: new Date(), passengerCount: 1 }],
        totalEstimatedCost: 100
      });

      await booking.updateStatus('confirmed');

      // Reload booking from database to get updated status
      const updatedBooking = await CorporateBooking.findById(booking._id);
      expect(updatedBooking.trips[0].status).toBe('confirmed');
    });

    test('should calculate total cost with discount', async () => {
      const corporateUser = await createTestUser({
        isCorporateUser: true,
        corporateAccount: {
          companyName: 'Test Corp',
          discountPercentage: 15
        }
      });

      const booking = new CorporateBooking({
        corporateAccountId: corporateUser.corporateAccount._id,
        userId: corporateUser._id,
        title: 'Discounted Booking',
        bookingType: 'business',
        trips: [
          { tripId: 'T1', estimatedCost: 200, pickupLocation: { address: 'A', coordinates: { latitude: 0, longitude: 0 } }, dropoffLocation: { address: 'B', coordinates: { latitude: 0, longitude: 0 } }, pickupTime: new Date(), passengerCount: 1 },
          { tripId: 'T2', estimatedCost: 300, pickupLocation: { address: 'B', coordinates: { latitude: 0, longitude: 0 } }, dropoffLocation: { address: 'C', coordinates: { latitude: 0, longitude: 0 } }, pickupTime: new Date(), passengerCount: 1 }
        ],
        totalEstimatedCost: 500
      });

      expect(booking.getDiscountedTotal()).toBe(425); // 500 - 15% = 425
    });
  });

  describe('Security Service Model Methods', () => {
    test('should calculate security service cost', () => {
      const service = new SecurityService({
        serviceType: 'close_protection',
        protectionLevel: 'standard',
        duration: 3,
        personnelCount: 2,
        requirements: {
          specialEquipment: ['radio', 'first_aid']
        }
      });

      const cost = service.calculateCost();
      expect(cost.baseRate).toBe(500);
      expect(cost.totalCost).toBe(3200); // 500 * 3 * 2 + (2 * 100) = 3000 + 200 = 3200
    });

    test('should update service status', async () => {
      const user = await createTestUser();
      const service = await SecurityService.create({
        userId: user._id,
        serviceType: 'close_protection',
        protectionLevel: 'standard',
        duration: 2,
        personnelCount: 1
      });

      await service.updateStatus('active');

      expect(service.status).toBe('active');
    });
  });

  describe('Airport Service Model Methods', () => {
    test('should calculate airport service cost', () => {
      const service = new AirportService({
        serviceType: 'pickup',
        passengerDetails: { count: 3 },
        flightDetails: { airline: 'Test Airline' }
      });

      const cost = service.calculateCost();
      expect(cost.baseFare).toBe(150);
      expect(cost.airportSurcharge).toBe(50);
      expect(cost.passengerSurcharge).toBe(75); // 3 * 25 = 75
      expect(cost.totalCost).toBe(275);
    });

    test('should track flight status', async () => {
      const user = await createTestUser();
      const service = await AirportService.create({
        userId: user._id,
        serviceType: 'pickup',
        flightDetails: {
          flightNumber: 'SA123',
          departureTime: new Date(Date.now() + 2 * 60 * 60 * 1000)
        },
        passengerDetails: { count: 1 }
      });

      await service.updateFlightStatus('on_time');

      expect(service.flightStatus).toBe('on_time');
    });
  });
});
