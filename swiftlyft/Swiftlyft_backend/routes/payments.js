const express = require('express');
const { PaymentMethod, Payment } = require('../models/Payment');
const User = require('../models/User');
const Booking = require('../models/Booking');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// All payment routes require authentication
router.use(authenticateToken);

// @route   POST /api/payments/process
// @desc    Process a payment transaction
// @access  Private
router.post('/process', async (req, res, next) => {
  try {
    const { bookingId, paymentMethodId, amount, description, metadata } = req.body;
    const userId = req.user.id;


    // Validate required fields
    if (!bookingId || !paymentMethodId || !amount) {
      return res.status(400).json({
        success: false,
        message: 'Booking ID, payment method ID, and amount are required'
      });
    }

    // Verify booking exists and belongs to user
    let booking;
    try {
      // First try to find by MongoDB ObjectId
      booking = await Booking.findById(bookingId);

      // If not found and bookingId looks like a custom booking ID (starts with 'BK'), try finding by bookingId field
      if (!booking && bookingId && bookingId.startsWith('BK')) {
        booking = await Booking.findOne({ bookingId: bookingId });
      }
    } catch (findError) {
      return res.status(400).json({
        success: false,
        message: `Invalid booking ID format: ${findError.message}`
      });
    }

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    if (booking.userId.toString() !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Unauthorized to process payment for this booking'
      });
    }

    // Verify payment method exists and belongs to user
    const paymentMethod = await PaymentMethod.findById(paymentMethodId);
    if (!paymentMethod) {
      return res.status(404).json({
        success: false,
        message: 'Payment method not found'
      });
    }

    if (paymentMethod.userId.toString() !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Unauthorized to use this payment method'
      });
    }

    // Check if payment method is active
    if (!paymentMethod.isActive) {
      return res.status(400).json({
        success: false,
        message: 'Payment method is not active'
      });
    }

    // Check if payment method is expired
    if (paymentMethod.isExpired()) {
      return res.status(400).json({
        success: false,
        message: 'Payment method has expired'
      });
    }

    // Validate amount
    if (amount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Amount must be greater than zero'
      });
    }

    // Calculate processing fee (example: 2.9% + R2.50)
    const processingFee = Math.round((amount * 0.029 + 2.50) * 100) / 100;
    const netAmount = amount - processingFee;

    // Create payment record
    const payment = new Payment({
      userId,
      bookingId,
      paymentMethodId,
      amount,
      processingFee,
      netAmount,
      description: description || `Payment for booking ${bookingId}`,
      metadata: metadata || {},
      status: 'pending',
      transactionType: 'payment'
    });

    await payment.save();

    // Simulate payment processing (in real implementation, integrate with payment processor)
    try {
      // Simulate processing delay
      await new Promise(resolve => setTimeout(resolve, 1000));

      // Simulate successful payment (90% success rate)
      const isSuccessful = Math.random() > 0.1;
      
      if (isSuccessful) {
        payment.status = 'completed';
        payment.completedAt = new Date();
        payment.processedAt = new Date();
        payment.externalTransactionId = `txn_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        payment.processorResponse = {
          code: '00',
          message: 'Transaction approved',
          rawResponse: { success: true }
        };
      } else {
        payment.status = 'failed';
        payment.failedAt = new Date();
        payment.failureReason = 'Transaction declined';
        payment.processorResponse = {
          code: '05',
          message: 'Transaction declined',
          rawResponse: { success: false, reason: 'Insufficient funds' }
        };
      }

      await payment.save();

      // Update booking status if payment successful
      if (payment.status === 'completed') {
        booking.paymentStatus = 'paid';
        booking.paymentId = payment._id;
        await booking.save();

        // Update user loyalty points
        const user = await User.findById(userId);
        const pointsEarned = Math.floor(amount / 10); // 1 point per R10
        user.addLoyaltyPoints(pointsEarned, 'Payment completed');
        user.totalSpent += amount;
        await user.save();

        // Referral rewards: also grant on first successful payment/completed trip path
        if (user.referredBy) {
          // Count completed bookings for the user to ensure first trip bonus
          const completedTrips = await require('../models/Booking').countDocuments({ userId: user._id, status: 'completed' });
          if (completedTrips === 1) {
            // Give referrer extra bonus points on first booking completion
            const referrerExtra = Math.round((booking.pricing?.total || amount) * 0.10);
            const referrerBonusPoints = 500; // Additional bonus on first booking completion
            const totalExtraPoints = referrerExtra + referrerBonusPoints;

            // Referrer bonuses (they already got 500 on signup)
            const referrer = await User.findById(user.referredBy);
            if (referrer) {
              referrer.addLoyaltyPoints(totalExtraPoints, 'Referral bonus: First booking completed');
              
              // Update the pending referral to completed status
              const pendingReferral = referrer.referrals.find(r => 
                r.referredUserId.toString() === user._id.toString() && r.status === 'pending'
              );
              if (pendingReferral) {
                pendingReferral.status = 'completed';
                pendingReferral.earnings = 500 + totalExtraPoints; // Total points: 500 (signup) + extra (booking)
                pendingReferral.completedAt = new Date();
              }
              
              await referrer.save();
            }
          }
        }
      }

      res.status(201).json({
        success: true,
        message: `Payment ${payment.status}`,
        data: {
          payment: payment.toJSON(),
          booking: booking.toJSON()
        }
      });

    } catch (processingError) {
      payment.status = 'failed';
      payment.failedAt = new Date();
      payment.failureReason = 'Processing error';
      payment.processorResponse = {
        code: '99',
        message: 'Processing error',
        rawResponse: { error: processingError.message }
      };
      await payment.save();

      res.status(500).json({
        success: false,
        message: 'Payment processing failed',
        data: {
          payment: payment.toJSON()
        }
      });
    }

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/users/:userId/payment-methods
// @desc    Get user's saved payment methods
// @access  Private
router.get('/users/:userId/payment-methods', async (req, res, next) => {
  try {
    const { userId } = req.params;
    const requestingUserId = req.user.id;

    // Check if user is requesting their own payment methods or is admin
    if (userId !== requestingUserId && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Unauthorized to access payment methods'
      });
    }

    const paymentMethods = await PaymentMethod.find({
      userId,
      isActive: true
    }).sort({ isDefault: -1, createdAt: -1 });

    res.json({
      success: true,
      data: {
        paymentMethods: paymentMethods.map(pm => ({
          id: pm._id,
          // Normalize backend types to frontend expectations
          type: ['credit_card', 'debit_card'].includes(pm.type) ? 'card' : (pm.type === 'digital_wallet' ? 'digital' : pm.type),
          // Expose a masked string so frontend can safely render
          cardNumber: `**** **** **** ${pm.lastFourDigits || '0000'}`,
          expiryMonth: pm.expiryMonth?.toString?.() || '',
          expiryYear: pm.expiryYear?.toString?.() || '',
          holderName: pm.cardholderName || '',
          brand: pm.provider || undefined,
          isDefault: pm.isDefault,
          createdAt: pm.createdAt,
          maskedCardNumber: pm.maskCardNumber(),
          isExpired: pm.isExpired()
        }))
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   POST /api/users/:userId/payment-methods
// @desc    Save new payment method
// @access  Private
router.post('/users/:userId/payment-methods', async (req, res, next) => {
  try {
    const { userId } = req.params;
    const requestingUserId = req.user.id;

    // Check if user is adding payment method to their own account or is admin
    if (userId !== requestingUserId && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Unauthorized to add payment method'
      });
    }

    const {
      type,
      cardNumber,
      expiryMonth,
      expiryYear,
      holderName,
      brand,
      isDefault,
      encryptedData
    } = req.body;

    // Validate required fields
    if (!type) {
      return res.status(400).json({
        success: false,
        message: 'Payment type is required'
      });
    }

    // Validate card-specific fields
    if (type === 'card' || type === 'credit_card' || type === 'debit_card') {
      if (!cardNumber || !expiryMonth || !expiryYear || !holderName || !brand) {
        return res.status(400).json({
          success: false,
          message: 'Card details are required for card payments'
        });
      }

      // Validate expiry date
      const now = new Date();
      const currentYear = now.getFullYear();
      const currentMonth = now.getMonth() + 1;

      const expiryYearInt = parseInt(expiryYear);
      const expiryMonthInt = parseInt(expiryMonth);

      if (expiryYearInt < currentYear || (expiryYearInt === currentYear && expiryMonthInt < currentMonth)) {
        return res.status(400).json({
          success: false,
          message: 'Card has expired'
        });
      }
    }

    // Create payment method
    const normalizedType = type === 'card' ? 'credit_card' : type;
    const paymentMethod = new PaymentMethod({
      userId,
      type: normalizedType,
      provider: brand || 'visa',
      lastFourDigits: (cardNumber || '').slice(-4),
      expiryMonth: parseInt(expiryMonth, 10),
      expiryYear: parseInt(expiryYear, 10),
      cardholderName: holderName,
      isDefault: isDefault || false,
      encryptedData: encryptedData || 'encrypted_data_placeholder'
    });

    await paymentMethod.save();

    res.status(201).json({
      success: true,
      message: 'Payment method added successfully',
      data: {
        paymentMethod: {
          id: paymentMethod._id,
          type: ['credit_card', 'debit_card'].includes(paymentMethod.type) ? 'card' : (paymentMethod.type === 'digital_wallet' ? 'digital' : paymentMethod.type),
          cardNumber: `**** **** **** ${paymentMethod.lastFourDigits}`,
          expiryMonth: paymentMethod.expiryMonth?.toString?.() || '',
          expiryYear: paymentMethod.expiryYear?.toString?.() || '',
          holderName: paymentMethod.cardholderName || '',
          brand: paymentMethod.provider,
          isDefault: paymentMethod.isDefault,
          createdAt: paymentMethod.createdAt,
          maskedCardNumber: paymentMethod.maskCardNumber()
        }
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   DELETE /api/payment-methods/:id
// @desc    Remove saved payment method
// @access  Private
router.delete('/payment-methods/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const paymentMethod = await PaymentMethod.findById(id);
    if (!paymentMethod) {
      return res.status(404).json({
        success: false,
        message: 'Payment method not found'
      });
    }

    // Check if user owns this payment method or is admin
    if (paymentMethod.userId.toString() !== userId && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Unauthorized to delete this payment method'
      });
    }

    // Check if payment method is being used in any pending payments
    const pendingPayments = await Payment.find({
      paymentMethodId: id,
      status: { $in: ['pending', 'processing'] }
    });

    if (pendingPayments.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete payment method with pending payments'
      });
    }

    // Soft delete by marking as inactive
    paymentMethod.isActive = false;
    await paymentMethod.save();

    res.json({
      success: true,
      message: 'Payment method removed successfully'
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/users/:userId/payments
// @desc    Get user's payment history
// @access  Private
router.get('/users/:userId/payments', async (req, res, next) => {
  try {
    const { userId } = req.params;
    const requestingUserId = req.user.id;
    const { status, limit = 50, page = 1, dateFrom, dateTo } = req.query;

    // Check if user is requesting their own payments or is admin
    if (userId !== requestingUserId && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Unauthorized to access payment history'
      });
    }

    const options = {
      status,
      limit: parseInt(limit),
      dateFrom,
      dateTo
    };

    const payments = await Payment.findByUser(userId, options);
    const totalPayments = await Payment.countDocuments({ userId });

    res.json({
      success: true,
      data: {
        payments: payments.map(payment => ({
          id: payment._id,
          bookingId: payment.bookingId,
          paymentMethodId: payment.paymentMethodId,
          amount: payment.amount,
          currency: payment.currency,
          status: ['pending', 'processing'].includes(payment.status) ? 'pending' : (payment.status === 'completed' ? 'completed' : (payment.status === 'failed' ? 'failed' : 'refunded')),
          failureReason: payment.failureReason,
          createdAt: payment.createdAt,
          completedAt: payment.completedAt,
          // Normalize refund flags for frontend expectations
          refunded: ['refunded', 'partially_refunded'].includes(payment.status),
          refundAmount: payment.totalRefunded || 0
        })),
        pagination: {
          total: totalPayments,
          page: parseInt(page),
          limit: parseInt(limit),
          pages: Math.ceil(totalPayments / parseInt(limit))
        }
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   POST /api/payments/:id/refund
// @desc    Process refund for a payment
// @access  Private
router.post('/:id/refund', async (req, res, next) => {
  try {
    const { id } = req.params;
    const { amount, reason } = req.body;
    const userId = req.user.id;

    if (!reason) {
      return res.status(400).json({
        success: false,
        message: 'Refund reason is required'
      });
    }

    const payment = await Payment.findById(id);
    if (!payment) {
      return res.status(404).json({
        success: false,
        message: 'Payment not found'
      });
    }

    // Check if user owns this payment or is admin
    if (payment.userId.toString() !== userId && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Unauthorized to refund this payment'
      });
    }

    // Check if payment can be refunded
    if (!payment.canRefund()) {
      return res.status(400).json({
        success: false,
        message: 'Payment cannot be refunded'
      });
    }

    const refundableAmount = payment.getRefundableAmount();
    const refundAmount = amount || refundableAmount;

    if (refundAmount > refundableAmount) {
      return res.status(400).json({
        success: false,
        message: `Refund amount cannot exceed ${refundableAmount}`
      });
    }

    // Create refund
    const refundData = {
      amount: refundAmount,
      reason,
      externalRefundId: `refund_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
    };

    await payment.addRefund(refundData);

    // Simulate refund processing
    try {
      await new Promise(resolve => setTimeout(resolve, 1000));

      // Simulate successful refund (deterministic in tests)
      const isSuccessful = process.env.NODE_ENV === 'test' ? true : (Math.random() > 0.05);
      
      if (isSuccessful) {
        // Update the refund status to completed first
        const lastRefund = payment.refunds[payment.refunds.length - 1];
        if (lastRefund) {
          lastRefund.status = 'completed';
          lastRefund.processedAt = new Date();
        }
        payment.status = 'refunded';
        payment.completedAt = new Date();
      } else {
        payment.status = 'failed';
        payment.failureReason = 'Refund processing failed';
        // Update the refund status to failed
        const lastRefund = payment.refunds[payment.refunds.length - 1];
        if (lastRefund) {
          lastRefund.status = 'failed';
        }
      }

      await payment.save();

      res.json({
        success: true,
        message: `Refund ${isSuccessful ? 'completed' : 'failed'}`,
        data: {
          payment: {
            id: payment._id,
            bookingId: payment.bookingId,
            paymentMethodId: payment.paymentMethodId,
            amount: payment.amount,
            currency: payment.currency,
            status: payment.status,
            failureReason: payment.failureReason,
            createdAt: payment.createdAt,
            completedAt: payment.completedAt,
            refunded: payment.refunded,
            refundAmount: payment.totalRefunded
          }
        }
      });

    } catch (processingError) {
      payment.status = 'failed';
      payment.failureReason = 'Refund processing error';
      await payment.save();

      res.status(500).json({
        success: false,
        message: 'Refund processing failed',
        data: {
          payment: {
            id: payment._id,
            bookingId: payment.bookingId,
            paymentMethodId: payment.paymentMethodId,
            amount: payment.amount,
            currency: payment.currency,
            status: payment.status,
            failureReason: payment.failureReason,
            createdAt: payment.createdAt,
            completedAt: payment.completedAt,
            refunded: payment.refunded,
            refundAmount: payment.totalRefunded
          }
        }
      });
    }

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/payments/:id/status
// @desc    Check payment status
// @access  Private
router.get('/:id/status', async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const payment = await Payment.findById(id)
      .populate('bookingId', 'pickupLocation dropoffLocation scheduledTime')
      .populate('paymentMethodId', 'type brand lastFourDigits');

    if (!payment) {
      return res.status(404).json({
        success: false,
        message: 'Payment not found'
      });
    }

    // Check if user owns this payment or is admin
    if (payment.userId.toString() !== userId && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Unauthorized to view this payment'
      });
    }

    res.json({
      success: true,
      data: {
        payment: {
          id: payment._id,
          bookingId: payment.bookingId,
          paymentMethodId: payment.paymentMethodId,
          amount: payment.amount,
          currency: payment.currency,
          status: payment.status,
          failureReason: payment.failureReason,
          createdAt: payment.createdAt,
          completedAt: payment.completedAt,
          refunded: payment.refunded,
          refundAmount: payment.refundAmount
        },
        canRefund: payment.canRefund(),
        refundableAmount: payment.getRefundableAmount()
      }
    });

  } catch (error) {
    next(error);
  }
});

module.exports = router;
