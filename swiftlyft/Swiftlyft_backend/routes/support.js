const express = require('express');
const rateLimit = require('express-rate-limit');
const {
  SupportTicket,
  SupportMessage,
  FAQ
} = require('../models/Support');
const { authenticateToken, requireAdmin } = require('../middleware/auth');
const { sendEmail } = require('../utils/email');

const router = express.Router();

// Rate limiting
const supportLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  message: {
    success: false,
    message: 'Too many support requests, please try again later'
  }
});

// @route   POST /api/support/tickets
// @desc    Create support ticket
// @access  Private
router.post('/tickets', authenticateToken, supportLimiter, async (req, res, next) => {
  try {
    const {
      subject,
      category,
      description,
      priority = 'normal',
      relatedBookingId,
      relatedQuoteId
    } = req.body;

    if (!subject || !category || !description) {
      return res.status(400).json({
        success: false,
        message: 'Subject, category, and description are required'
      });
    }

    // Validate category
    const validCategories = [
      'booking_issue', 'payment_problem', 'driver_issue', 'app_technical',
      'account_issue', 'billing_inquiry', 'safety_concern', 'feature_request',
      'general_inquiry', 'corporate_support'
    ];

    if (!validCategories.includes(category)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid category'
      });
    }

    // Generate ticket ID
    const ticketId = SupportTicket.generateTicketId();

    // Create ticket
    const ticket = new SupportTicket({
      ticketId,
      userId: req.userId,
      subject,
      category,
      description,
      priority,
      relatedBookingId,
      relatedQuoteId
    });

    // Ensure the created ticket references the authenticated user id in JSON output

    await ticket.save();

    // Send confirmation email
    try {
      const emailSubject = `Support Ticket #${ticketId} - ${subject}`;
      const emailBody = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2>Support Ticket Created</h2>
          <p>Dear ${req.user.name || 'Valued Customer'},</p>
          <p>Your support ticket has been created successfully.</p>
          <div style="background: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0;">
            <strong>Ticket ID:</strong> ${ticketId}<br>
            <strong>Subject:</strong> ${subject}<br>
            <strong>Category:</strong> ${category}<br>
            <strong>Priority:</strong> ${priority}<br>
            <strong>Status:</strong> Open
          </div>
          <p>Our support team will respond to your ticket within 24 hours. You can check the status of your ticket in the app.</p>
          <p>Thank you for using SwiftLyft!</p>
        </div>
      `;

      await sendEmail(req.user.email, emailSubject, emailBody);
    } catch (emailError) {
      console.error('Failed to send ticket confirmation email:', emailError);
    }

    res.status(201).json({
      success: true,
      message: 'Support ticket created successfully',
      data: {
        ticket: ticket.toJSON()
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/users/:userId/support-tickets
// @desc    Get user's support tickets
// @access  Private
router.get('/user/:userId/tickets', authenticateToken, async (req, res, next) => {
  try {
    const { userId } = req.params;
    const { status, category, page = 1, limit = 20 } = req.query;

    // Check permissions
    if (userId !== req.userId.toString() && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    const tickets = await SupportTicket.getUserTickets(userId, status, limit);

    // Get pagination info
    const query = { userId };
    if (status) query.status = status;
    if (category) query.category = category;

    const total = await SupportTicket.countDocuments(query);

    res.json({
      success: true,
      data: {
        tickets: tickets.map(ticket => ticket.toJSON()),
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/support/tickets/:ticketId
// @desc    Get ticket details and messages
// @access  Private
router.get('/tickets/:ticketId', authenticateToken, async (req, res, next) => {
  try {
    const { ticketId } = req.params;

    const ticket = await SupportTicket.findOne({ ticketId })
      .populate('assignedTo', 'name email')
      .populate('userId', 'name email');

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: 'Ticket not found'
      });
    }

    // Check permissions
    if (ticket.userId._id.toString() !== req.userId.toString() && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Get messages
    const messages = await SupportMessage.find({ ticketId: ticket._id })
      .populate('senderId', 'name')
      .sort({ createdAt: 1 });

    res.json({
      success: true,
      data: {
        ticket: ticket.toJSON(),
        messages: messages.map(msg => msg.toJSON())
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   POST /api/support/tickets/:ticketId/messages
// @desc    Add message to ticket
// @access  Private
router.post('/tickets/:ticketId/messages', authenticateToken, async (req, res, next) => {
  try {
    const { ticketId } = req.params;
    const { message, isInternal = false } = req.body;

    if (!message) {
      return res.status(400).json({
        success: false,
        message: 'Message is required'
      });
    }

    const ticket = await SupportTicket.findOne({ ticketId });

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: 'Ticket not found'
      });
    }

    // Check permissions
    if (ticket.userId.toString() !== req.userId.toString() && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Only admins can send internal messages
    if (isInternal && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Internal messages can only be sent by support agents'
      });
    }

    const senderType = req.user.role === 'admin' ? 'agent' : 'user';

    const newMessage = await ticket.addMessage(req.userId, senderType, message, [], isInternal);

    // Update ticket status if user responds to resolved ticket
    if (ticket.status === 'resolved' && senderType === 'user') {
      ticket.status = 'open';
      await ticket.save();
    }

    res.status(201).json({
      success: true,
      message: 'Message added successfully',
      data: {
        message: newMessage.toJSON()
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   PUT /api/support/tickets/:ticketId/status
// @desc    Update ticket status (admin only)
// @access  Private/Admin
router.put('/tickets/:ticketId/status', authenticateToken, requireAdmin, async (req, res, next) => {
  try {
    const { ticketId } = req.params;
    const { status, assignedTo, priority, notes } = req.body;

    const ticket = await SupportTicket.findOne({ ticketId });

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: 'Ticket not found'
      });
    }

    // Update ticket
    if (status) ticket.status = status;
    if (assignedTo) await ticket.assignTo(assignedTo);
    if (priority) ticket.priority = priority;
    if (notes) ticket.internalNotes = notes;

    await ticket.save();

    res.json({
      success: true,
      message: 'Ticket updated successfully',
      data: {
        ticket: ticket.toJSON()
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   POST /api/support/tickets/:ticketId/resolve
// @desc    Resolve ticket (admin only)
// @access  Private/Admin
router.post('/tickets/:ticketId/resolve', authenticateToken, requireAdmin, async (req, res, next) => {
  try {
    const { ticketId } = req.params;
    const { solution, satisfaction } = req.body;

    const ticket = await SupportTicket.findOne({ ticketId });

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: 'Ticket not found'
      });
    }

    await ticket.resolve(req.userId, solution, satisfaction);

    res.json({
      success: true,
      message: 'Ticket resolved successfully',
      data: {
        ticket: ticket.toJSON()
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/support/faq
// @desc    Get FAQ list
// @access  Public
router.get('/faq', async (req, res, next) => {
  try {
    const { category, search, limit = 50 } = req.query;

    const faqs = await FAQ.searchFAQs(search, category, limit);

    res.json({
      success: true,
      data: {
        faqs: faqs.map(faq => faq.toJSON()),
        total: faqs.length
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/support/faq/categories
// @desc    Get FAQ categories
// @access  Public
router.get('/faq/categories', async (req, res, next) => {
  try {
    const categories = await FAQ.distinct('category', { isActive: true });

    res.json({
      success: true,
      data: {
        categories: categories.map(category => ({
          id: category,
          name: category.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase()),
          count: 0 // Would need to count in production
        }))
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   POST /api/support/faq/:faqId/helpful
// @desc    Mark FAQ as helpful
// @access  Public
router.post('/faq/:faqId/helpful', async (req, res, next) => {
  try {
    const { faqId } = req.params;

    const faq = await FAQ.findByIdAndUpdate(
      faqId,
      { $inc: { helpfulCount: 1, viewCount: 1 } },
      { new: true }
    );

    if (!faq) {
      return res.status(404).json({
        success: false,
        message: 'FAQ not found'
      });
    }

    res.json({
      success: true,
      message: 'Thank you for your feedback'
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/support/contact
// @desc    Get company contact information
// @access  Public
router.get('/contact', async (req, res, next) => {
  try {
    // In production, this could be stored in a configuration collection
    const contactInfo = {
      company: {
        name: 'SwiftLyft',
        address: '123 Business Street, Johannesburg, South Africa',
        phone: '+27 21 123 4567',
        email: 'support@swiftlyft.co.za',
        website: 'https://swiftlyft.co.za'
      },
      support: {
        email: 'support@swiftlyft.co.za',
        phone: '+27 21 123 4567',
        hours: '24/7 Customer Support',
        emergency: '+27 21 987 6543'
      },
      sales: {
        email: 'sales@swiftlyft.co.za',
        phone: '+27 21 555 0123',
        corporate: 'corporate@swiftlyft.co.za'
      },
      social: {
        facebook: 'https://facebook.com/swiftlyft',
        twitter: 'https://twitter.com/swiftlyft',
        instagram: 'https://instagram.com/swiftlyft'
      }
    };

    res.json({
      success: true,
      data: contactInfo
    });

  } catch (error) {
    next(error);
  }
});

// Admin routes for managing FAQs
router.post('/admin/faq', authenticateToken, requireAdmin, async (req, res, next) => {
  try {
    const { question, answer, category, tags } = req.body;

    if (!question || !answer || !category) {
      return res.status(400).json({
        success: false,
        message: 'Question, answer, and category are required'
      });
    }

    const faq = new FAQ({
      question,
      answer,
      category,
      tags: tags || [],
      createdBy: req.userId
    });

    await faq.save();

    res.status(201).json({
      success: true,
      message: 'FAQ created successfully',
      data: {
        faq: faq.toJSON()
      }
    });

  } catch (error) {
    next(error);
  }
});

router.put('/admin/faq/:faqId', authenticateToken, requireAdmin, async (req, res, next) => {
  try {
    const { faqId } = req.params;
    const updates = req.body;

    const faq = await FAQ.findByIdAndUpdate(faqId, updates, { new: true });

    if (!faq) {
      return res.status(404).json({
        success: false,
        message: 'FAQ not found'
      });
    }

    res.json({
      success: true,
      message: 'FAQ updated successfully',
      data: {
        faq: faq.toJSON()
      }
    });

  } catch (error) {
    next(error);
  }
});

module.exports = router;
