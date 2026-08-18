const mongoose = require('mongoose');

const supportTicketSchema = new mongoose.Schema({
  ticketId: {
    type: String,
    unique: true,
    required: true
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'User ID is required']
  },
  subject: {
    type: String,
    required: [true, 'Subject is required'],
    maxlength: [200, 'Subject cannot exceed 200 characters']
  },
  category: {
    type: String,
    required: true,
    enum: [
      'booking_issue',
      'payment_problem',
      'driver_issue',
      'app_technical',
      'account_issue',
      'billing_inquiry',
      'safety_concern',
      'feature_request',
      'general_inquiry',
      'corporate_support'
    ]
  },
  priority: {
    type: String,
    enum: ['low', 'normal', 'high', 'urgent'],
    default: 'normal'
  },
  status: {
    type: String,
    enum: ['open', 'in_progress', 'waiting_for_user', 'resolved', 'closed'],
    default: 'open'
  },
  description: {
    type: String,
    required: [true, 'Description is required'],
    maxlength: [2000, 'Description cannot exceed 2000 characters']
  },
  attachments: [{
    filename: String,
    url: String,
    uploadedAt: { type: Date, default: Date.now }
  }],
  assignedTo: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User' // Support agent
  },
  tags: [String], // For categorization and search
  relatedBookingId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Booking'
  },
  relatedQuoteId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Quote'
  },
  resolution: {
    resolvedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    resolvedAt: Date,
    solution: String,
    satisfaction: {
      type: Number,
      min: 1,
      max: 5
    }
  }
}, {
  timestamps: true,
  toJSON: {
    transform: function(doc, ret) {
      ret.id = ret._id;
      delete ret._id;
      delete ret.__v;
      return ret;
    }
  }
});

// Message schema for ticket conversations
const messageSchema = new mongoose.Schema({
  ticketId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'SupportTicket',
    required: true
  },
  senderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  senderType: {
    type: String,
    enum: ['user', 'agent', 'system'],
    required: true
  },
  message: {
    type: String,
    required: true,
    maxlength: [1000, 'Message cannot exceed 1000 characters']
  },
  attachments: [{
    filename: String,
    url: String,
    uploadedAt: { type: Date, default: Date.now }
  }],
  isInternal: {
    type: Boolean,
    default: false // Internal notes between agents
  },
  readBy: [{
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    readAt: { type: Date, default: Date.now }
  }]
}, {
  timestamps: true,
  toJSON: {
    transform: function(doc, ret) {
      ret.id = ret._id;
      delete ret._id;
      delete ret.__v;
      return ret;
    }
  }
});

// FAQ schema
const faqSchema = new mongoose.Schema({
  question: {
    type: String,
    required: true,
    maxlength: [500, 'Question cannot exceed 500 characters']
  },
  answer: {
    type: String,
    required: true,
    maxlength: [2000, 'Answer cannot exceed 2000 characters']
  },
  category: {
    type: String,
    required: true,
    enum: [
      'general',
      'getting_started',
      'booking',
      'payment',
      'driver',
      'account',
      'safety',
      'corporate',
      'technical'
    ]
  },
  tags: [String],
  isActive: {
    type: Boolean,
    default: true
  },
  viewCount: {
    type: Number,
    default: 0
  },
  helpfulCount: {
    type: Number,
    default: 0
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }
}, {
  timestamps: true,
  toJSON: {
    transform: function(doc, ret) {
      ret.id = ret._id;
      delete ret._id;
      delete ret.__v;
      return ret;
    }
  }
});

// Indexes
supportTicketSchema.index({ ticketId: 1 });
supportTicketSchema.index({ userId: 1, createdAt: -1 });
supportTicketSchema.index({ status: 1, priority: 1 });
supportTicketSchema.index({ category: 1 });

messageSchema.index({ ticketId: 1, createdAt: 1 });

faqSchema.index({ category: 1, isActive: 1 });
faqSchema.index({ tags: 1 });

// Virtuals
supportTicketSchema.virtual('isResolved').get(function() {
  return ['resolved', 'closed'].includes(this.status);
});

supportTicketSchema.virtual('responseTime').get(function() {
  if (!this.assignedTo || this.status === 'open') return null;
  return this.updatedAt - this.createdAt;
});

// Instance methods
supportTicketSchema.methods.assignTo = function(agentId) {
  this.assignedTo = agentId;
  this.status = 'in_progress';
  return this.save();
};

supportTicketSchema.methods.resolve = function(agentId, solution, satisfaction = null) {
  this.status = 'resolved';
  this.resolution = {
    resolvedBy: agentId,
    resolvedAt: new Date(),
    solution,
    satisfaction
  };
  return this.save();
};

supportTicketSchema.methods.addMessage = async function(senderId, senderType, message, attachments = [], isInternal = false) {
  const SupportMessage = mongoose.model('SupportMessage');
  const newMessage = new SupportMessage({
    ticketId: this._id,
    senderId,
    senderType,
    message,
    attachments,
    isInternal
  });

  await newMessage.save();

  // Force updatedAt to change by updating the document
  await SupportTicket.findByIdAndUpdate(this._id, { $set: { updatedAt: new Date() } });

  return newMessage;
};

// Static methods
supportTicketSchema.statics.generateTicketId = function() {
  const crypto = require('crypto');

  // Generate a UUID-like string for guaranteed uniqueness
  const randomBytes = crypto.randomBytes(16);
  const uuid = [
    randomBytes.toString('hex', 0, 4),
    randomBytes.toString('hex', 4, 6),
    randomBytes.toString('hex', 6, 8),
    randomBytes.toString('hex', 8, 10),
    randomBytes.toString('hex', 10, 16)
  ].join('-').toUpperCase();

  return `TKT-${uuid.substring(0, 8)}`;
};

supportTicketSchema.statics.getUserTickets = function(userId, status = null, limit = 50) {
  const query = { userId };
  if (status) query.status = status;

  return this.find(query)
    .sort({ createdAt: -1 })
    .limit(limit)
    .populate('assignedTo', 'name');
};

faqSchema.statics.searchFAQs = function(searchTerm, category = null, limit = 20) {
  const query = { isActive: true };

  if (category) query.category = category;

  if (searchTerm) {
    query.$or = [
      { question: new RegExp(searchTerm, 'i') },
      { answer: new RegExp(searchTerm, 'i') },
      { tags: new RegExp(searchTerm, 'i') }
    ];
  }

  return this.find(query)
    .sort({ viewCount: -1, helpfulCount: -1 })
    .limit(limit);
};

// Models
const SupportTicket = mongoose.model('SupportTicket', supportTicketSchema);
const SupportMessage = mongoose.model('SupportMessage', messageSchema);
const FAQ = mongoose.model('FAQ', faqSchema);

module.exports = {
  SupportTicket,
  SupportMessage,
  FAQ
};
