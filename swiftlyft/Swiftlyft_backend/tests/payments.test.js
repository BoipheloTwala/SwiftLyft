const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../server');
const { PaymentMethod, Payment } = require('../models/Payment');
const User = require('../models/User');
const Booking = require('../models/Booking');
const { generateAccessToken } = require('../utils/jwt');

describe('Payment Processing APIs', () => {
  let authToken;
  let userId;
  let bookingId;
  let paymentMethodId;

  beforeAll(async () => {
    // DB connection is managed globally in tests/setup.js
    process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-secret';
  });

  afterAll(async () => {
    await mongoose.connection.close();
  });

  beforeEach(async () => {
    // Clean up database
    await User.deleteMany({});
    await Booking.deleteMany({});
    await PaymentMethod.deleteMany({});
    await Payment.deleteMany({});

    // Create test user
    const user = new User({
      email: 'test@example.com',
      password: 'password123',
      name: 'Test User',
      phoneNumber: '+27123456789'
    });
    await user.save();
    userId = user._id;

    // Generate auth token
    authToken = generateAccessToken(userId.toString());

    // Create test booking (match Booking schema requirements)
    const booking = new Booking({
      bookingId: `BK${Date.now()}`,
      userId,
      vehicleName: 'Toyota Camry',
      pickupAddress: '123 Main St, Johannesburg',
      dropoffAddress: '456 Oak Ave, Johannesburg',
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
      vehicleType: 'sedan',
      serviceType: 'standard',
      passengerCount: 2,
      pickupTime: new Date(Date.now() + 23 * 60 * 60 * 1000),
      scheduledDate: new Date(Date.now() + 24 * 60 * 60 * 1000),
      basePrice: 70,
      finalPrice: 74.75,
      pricing: {
        baseFare: 25,
        distanceFare: 15,
        timeFare: 20,
        serviceFee: 5,
        taxes: 9.75,
        total: 74.75,
        currency: 'ZAR'
      },
      status: 'confirmed',
      paymentStatus: 'pending'
    });
    await booking.save();
    bookingId = booking._id;

    // Create test payment method
    const paymentMethod = new PaymentMethod({
      userId,
      type: 'credit_card',
      provider: 'visa',
      lastFourDigits: '1234',
      expiryMonth: 12,
      expiryYear: 2025,
      cardholderName: 'Test User',
      isDefault: true,
      isActive: true,
      encryptedData: 'encrypted_card_data_placeholder'
    });
    await paymentMethod.save();
    paymentMethodId = paymentMethod._id;
  });

  describe('POST /api/payments/process', () => {
    it('should process a payment successfully', async () => {
      const response = await request(app)
        .post('/api/payments/process')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          bookingId,
          paymentMethodId,
          amount: 100.00,
          description: 'Test payment'
        });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data.payment).toBeDefined();
      expect(response.body.data.payment.amount).toBe(100.00);
      expect(response.body.data.payment.status).toMatch(/completed|failed/);
    });

    it('should fail with missing required fields', async () => {
      const response = await request(app)
        .post('/api/payments/process')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          bookingId,
          // Missing paymentMethodId and amount
        });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('required');
    });

    it('should fail with invalid booking ID', async () => {
      const response = await request(app)
        .post('/api/payments/process')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          bookingId: new mongoose.Types.ObjectId(),
          paymentMethodId,
          amount: 100.00
        });

      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Booking not found');
    });

    it('should fail with invalid payment method ID', async () => {
      const response = await request(app)
        .post('/api/payments/process')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          bookingId,
          paymentMethodId: new mongoose.Types.ObjectId(),
          amount: 100.00
        });

      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Payment method not found');
    });

    it('should fail with invalid amount', async () => {
      const response = await request(app)
        .post('/api/payments/process')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          bookingId,
          paymentMethodId,
          amount: -10.00
        });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Amount must be greater than zero');
    });

    it('should fail without authentication', async () => {
      const response = await request(app)
        .post('/api/payments/process')
        .send({
          bookingId,
          paymentMethodId,
          amount: 100.00
        });

      expect(response.status).toBe(401);
    });
  });

  describe('GET /api/users/:userId/payment-methods', () => {
    it('should get user payment methods', async () => {
      const response = await request(app)
        .get(`/api/payments/users/${userId}/payment-methods`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.paymentMethods).toHaveLength(1);
      expect(response.body.data.paymentMethods[0].brand).toBe('visa');
    });

    it('should fail for unauthorized user', async () => {
      const otherUser = new User({
        email: 'other@example.com',
        password: 'password123',
        name: 'Other User'
      });
      await otherUser.save();

      const response = await request(app)
        .get(`/api/payments/users/${otherUser._id}/payment-methods`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(403);
      expect(response.body.success).toBe(false);
    });

    it('should fail without authentication', async () => {
      const response = await request(app)
        .get(`/api/payments/users/${userId}/payment-methods`);

      expect(response.status).toBe(401);
    });
  });

  describe('POST /api/users/:userId/payment-methods', () => {
    it('should add new payment method', async () => {
      const response = await request(app)
        .post(`/api/payments/users/${userId}/payment-methods`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          type: 'card',
          cardNumber: '1234567890123456',
          expiryMonth: '6',
          expiryYear: '2026',
          holderName: 'Test User',
          brand: 'mastercard',
          encryptedData: 'encrypted_data_placeholder'
        });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data.paymentMethod.type).toBe('card');
      expect(response.body.data.paymentMethod.brand).toBe('mastercard');
    });

    it('should fail with missing required fields', async () => {
      const response = await request(app)
        .post(`/api/payments/users/${userId}/payment-methods`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          type: 'card'
          // Missing required fields
        });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });

    it('should fail with expired card', async () => {
      const response = await request(app)
        .post(`/api/payments/users/${userId}/payment-methods`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          type: 'card',
          cardNumber: '1234567890123456',
          expiryMonth: '1',
          expiryYear: '2020', // Expired
          holderName: 'Test User',
          brand: 'visa',
          encryptedData: 'encrypted_data_placeholder'
        });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Card has expired');
    });

    it('should fail for unauthorized user', async () => {
      const otherUser = new User({
        email: 'other@example.com',
        password: 'password123',
        name: 'Other User'
      });
      await otherUser.save();

      const response = await request(app)
        .post(`/api/payments/users/${otherUser._id}/payment-methods`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          type: 'card',
          cardNumber: '1234567890123456',
          expiryMonth: '12',
          expiryYear: '2025',
          holderName: 'Other User',
          brand: 'visa',
          encryptedData: 'encrypted_data_placeholder'
        });

      expect(response.status).toBe(403);
      expect(response.body.success).toBe(false);
    });
  });

  describe('DELETE /api/payment-methods/:id', () => {
    it('should remove payment method', async () => {
      const response = await request(app)
        .delete(`/api/payments/payment-methods/${paymentMethodId}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);

      // Verify payment method is marked as inactive
      const paymentMethod = await PaymentMethod.findById(paymentMethodId);
      expect(paymentMethod.isActive).toBe(false);
    });

    it('should fail with invalid payment method ID', async () => {
      const response = await request(app)
        .delete(`/api/payments/payment-methods/${new mongoose.Types.ObjectId()}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
    });

    it('should fail for unauthorized user', async () => {
      const otherUser = new User({
        email: 'other@example.com',
        password: 'password123',
        name: 'Other User'
      });
      await otherUser.save();

      const otherPaymentMethod = new PaymentMethod({
        userId: otherUser._id,
        type: 'credit_card',
        provider: 'visa',
        lastFourDigits: '9999',
        expiryMonth: 12,
        expiryYear: 2025,
        cardholderName: 'Other User',
        isDefault: false,
        isActive: true,
        encryptedData: 'encrypted_card_data_placeholder_2'
      });
      await otherPaymentMethod.save();

      const response = await request(app)
        .delete(`/api/payments/payment-methods/${otherPaymentMethod._id}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(403);
      expect(response.body.success).toBe(false);
    });
  });

  describe('GET /api/users/:userId/payments', () => {
    beforeEach(async () => {
      // Create test payment
      const payment = new Payment({
        userId,
        bookingId,
        paymentMethodId,
        amount: 150.00,
        processingFee: 6.85,
        netAmount: 143.15,
        status: 'completed',
        transactionType: 'payment',
        description: 'Test payment',
        transactionType: 'payment'
      });
      await payment.save();
    });

    it('should get user payment history', async () => {
      const response = await request(app)
        .get(`/api/payments/users/${userId}/payments`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.payments).toHaveLength(1);
      expect(response.body.data.payments[0].amount).toBe(150.00);
      expect(response.body.data.pagination).toBeDefined();
    });

    it('should filter payments by status', async () => {
      const response = await request(app)
        .get(`/api/payments/users/${userId}/payments?status=completed`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.payments).toHaveLength(1);
    });

    it('should filter payments by status with no results', async () => {
      const response = await request(app)
        .get(`/api/payments/users/${userId}/payments?status=failed`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.payments).toHaveLength(0);
    });

    it('should fail for unauthorized user', async () => {
      const otherUser = new User({
        email: 'other@example.com',
        password: 'password123',
        name: 'Other User'
      });
      await otherUser.save();

      const response = await request(app)
        .get(`/api/payments/users/${otherUser._id}/payments`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(403);
      expect(response.body.success).toBe(false);
    });
  });

  describe('POST /api/payments/:id/refund', () => {
    let paymentId;

    beforeEach(async () => {
      const payment = new Payment({
        userId,
        bookingId,
        paymentMethodId,
        amount: 200.00,
        processingFee: 8.30,
        netAmount: 191.70,
        status: 'completed',
        transactionType: 'payment',
        description: 'Test payment for refund',
        transactionType: 'payment'
      });
      await payment.save();
      paymentId = payment._id;
    });

    it('should process refund successfully', async () => {
      const response = await request(app)
        .post(`/api/payments/${paymentId}/refund`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          amount: 100.00,
          reason: 'Customer requested refund'
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.payment).toBeDefined();
      expect(response.body.data.payment.refundAmount).toBe(100.00);
    });

    it('should process full refund when no amount specified', async () => {
      const response = await request(app)
        .post(`/api/payments/${paymentId}/refund`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          reason: 'Full refund requested'
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.payment.refundAmount).toBe(200.00);
    });

    it('should fail with missing reason', async () => {
      const response = await request(app)
        .post(`/api/payments/${paymentId}/refund`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          amount: 100.00
          // Missing reason
        });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Refund reason is required');
    });

    it('should fail with invalid payment ID', async () => {
      const response = await request(app)
        .post(`/api/payments/${new mongoose.Types.ObjectId()}/refund`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          amount: 100.00,
          reason: 'Test refund'
        });

      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
    });

    it('should fail with refund amount exceeding payment', async () => {
      const response = await request(app)
        .post(`/api/payments/${paymentId}/refund`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          amount: 300.00, // More than payment amount
          reason: 'Test refund'
        });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('cannot exceed');
    });

    it('should fail for unauthorized user', async () => {
      const otherUser = new User({
        email: 'other@example.com',
        password: 'password123',
        name: 'Other User'
      });
      await otherUser.save();

      const otherPayment = new Payment({
        userId: otherUser._id,
        bookingId,
        paymentMethodId,
        amount: 100.00,
        processingFee: 5.40,
        netAmount: 94.60,
        status: 'completed',
        transactionType: 'payment'
      });
      await otherPayment.save();

      const response = await request(app)
        .post(`/api/payments/${otherPayment._id}/refund`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          amount: 50.00,
          reason: 'Test refund'
        });

      expect(response.status).toBe(403);
      expect(response.body.success).toBe(false);
    });
  });

  describe('GET /api/payments/:id/status', () => {
    let paymentId;

    beforeEach(async () => {
      const payment = new Payment({
        userId,
        bookingId,
        paymentMethodId,
        amount: 250.00,
        processingFee: 9.75,
        netAmount: 240.25,
        status: 'completed',
        transactionType: 'payment',
        description: 'Test payment for status check'
      });
      await payment.save();
      paymentId = payment._id;
    });

    it('should get payment status', async () => {
      const response = await request(app)
        .get(`/api/payments/${paymentId}/status`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.payment).toBeDefined();
      expect(response.body.data.payment.status).toBe('completed');
      expect(response.body.data.canRefund).toBe(true);
      expect(response.body.data.refundableAmount).toBe(250.00);
    });

    it('should fail with invalid payment ID', async () => {
      const response = await request(app)
        .get(`/api/payments/${new mongoose.Types.ObjectId()}/status`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
    });

    it('should fail for unauthorized user', async () => {
      const otherUser = new User({
        email: 'other@example.com',
        password: 'password123',
        name: 'Other User'
      });
      await otherUser.save();

      const otherPayment = new Payment({
        userId: otherUser._id,
        bookingId,
        paymentMethodId,
        amount: 100.00,
        processingFee: 5.40,
        netAmount: 94.60,
        status: 'completed',
        transactionType: 'payment'
      });
      await otherPayment.save();

      const response = await request(app)
        .get(`/api/payments/${otherPayment._id}/status`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(403);
      expect(response.body.success).toBe(false);
    });
  });
});
