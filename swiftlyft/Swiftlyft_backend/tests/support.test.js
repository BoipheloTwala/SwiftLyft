const {
  SupportTicket,
  SupportMessage,
  FAQ
} = require('../models/Support');
const {
  createTestUser,
  createTestSupportTicket
} = require('./setup');
const {
  request,
  authenticatedRequest,
  adminRequest,
  expectSuccess,
  expectError,
  validateSupportTicketResponse,
  testSupportTicketData
} = require('./testUtils');

describe('Support & Help APIs (API 10)', () => {
  describe('POST /api/support/tickets - Create Support Ticket', () => {
    test('should create support ticket successfully', async () => {
      const user = await createTestUser();

      const { request } = await authenticatedRequest('POST', '/api/support/tickets');

      const response = await request.send(testSupportTicketData);
      const result = expectSuccess(response, 201);

      expect(result.data).toHaveProperty('ticket');
      validateSupportTicketResponse(result.data.ticket);

      const ticket = result.data.ticket;
      expect(ticket.userId).toBe(user._id.toString());
      expect(ticket.subject).toBe(testSupportTicketData.subject);
      expect(ticket.category).toBe(testSupportTicketData.category);
      expect(ticket.status).toBe('open');
      expect(ticket.priority).toBe('normal');
      expect(ticket.ticketId).toMatch(/^TKT-/);
    });

    test('should validate required fields', async () => {
      const { request } = await authenticatedRequest('POST', '/api/support/tickets');

      const response = await request.send({
        subject: 'Test Subject'
        // Missing category and description
      });

      expectError(response, 400);
    });

    test('should validate category', async () => {
      const { request } = await authenticatedRequest('POST', '/api/support/tickets');

      const invalidData = {
        ...testSupportTicketData,
        category: 'invalid_category'
      };

      const response = await request.send(invalidData);
      expectError(response, 400);
    });

    test('should validate priority', async () => {
      const { request } = await authenticatedRequest('POST', '/api/support/tickets');

      const response = await request.send({
        ...testSupportTicketData,
        priority: 'invalid_priority'
      });

      expectError(response, 400);
    });

    test('should generate unique ticket ID', async () => {
      const user = await createTestUser();

      // Create first ticket
      const { request: request1 } = await authenticatedRequest('POST', '/api/support/tickets');
      const response1 = await request1.send(testSupportTicketData);
      const ticket1 = response1.body.data.ticket;

      // Create second ticket with separate request
      const { request: request2 } = await authenticatedRequest('POST', '/api/support/tickets');
      const response2 = await request2.send({
        ...testSupportTicketData,
        subject: 'Different Subject'
      });
      const ticket2 = response2.body.data.ticket;

      expect(ticket1.ticketId).not.toBe(ticket2.ticketId);
      expect(ticket1.ticketId).toMatch(/^TKT-/);
      expect(ticket2.ticketId).toMatch(/^TKT-/);
    });
  });

  describe('GET /api/users/:userId/support-tickets - Get User Support Tickets', () => {
    test('should get user support tickets list', async () => {
      const user = await createTestUser();
      const ticket1 = await createTestSupportTicket(user._id);
      const ticket2 = await createTestSupportTicket(user._id, { status: 'resolved' });

      const { request } = await authenticatedRequest('GET', `/api/users/${user._id}/support-tickets`);

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data).toHaveProperty('tickets');
      expect(result.data).toHaveProperty('pagination');
      expect(Array.isArray(result.data.tickets)).toBe(true);
      expect(result.data.tickets.length).toBe(2);

      result.data.tickets.forEach(validateSupportTicketResponse);
    });

    test('should filter tickets by status', async () => {
      const user = await createTestUser();
      await createTestSupportTicket(user._id, { status: 'open' });
      await createTestSupportTicket(user._id, { status: 'resolved' });

      const { request } = await authenticatedRequest('GET', `/api/users/${user._id}/support-tickets?status=resolved`);

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data.tickets.length).toBe(1);
      expect(result.data.tickets[0].status).toBe('resolved');
    });

    test('should implement pagination', async () => {
      const user = await createTestUser();

      // Create multiple tickets
      for (let i = 0; i < 5; i++) {
        await createTestSupportTicket(user._id);
      }

      const { request } = await authenticatedRequest('GET', `/api/users/${user._id}/support-tickets?limit=2&page=2`);

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data.tickets.length).toBe(2);
      expect(result.data.pagination.page).toBe(2);
      expect(result.data.pagination.limit).toBe(2);
      expect(result.data.pagination.total).toBe(5);
    });

    test('should fail for non-owner user', async () => {
      const user1 = await createTestUser({ email: 'user1@test.com' });
      const user2 = await createTestUser({ email: 'user2@test.com' });

      const { request } = await authenticatedRequest('GET', `/api/users/${user1._id}/support-tickets`, user2);

      const response = await request;
      expectError(response, 403);
    });
  });

  describe('GET /api/support/tickets/:ticketId - Get Ticket Details', () => {
    test('should get ticket details with messages', async () => {
      const user = await createTestUser();
      const ticket = await createTestSupportTicket(user._id);

      // Add a message to the ticket
      await ticket.addMessage(user._id, 'user', 'Test message');

      const { request } = await authenticatedRequest('GET', `/api/support/tickets/${ticket.ticketId}`);

      const response = await request;
      const result = expectSuccess(response);

      expect(result.data).toHaveProperty('ticket');
      expect(result.data).toHaveProperty('messages');
      validateSupportTicketResponse(result.data.ticket);
      expect(result.data.ticket.ticketId).toBe(ticket.ticketId);
      expect(Array.isArray(result.data.messages)).toBe(true);
      expect(result.data.messages.length).toBe(1);
    });

    test('should allow admin to view any ticket', async () => {
      const user = await createTestUser();
      const ticket = await createTestSupportTicket(user._id);

      const { request } = await adminRequest('GET', `/api/support/tickets/${ticket.ticketId}`);

      const response = await request;
      expectSuccess(response);
    });

    test('should fail for non-owner non-admin user', async () => {
      const user1 = await createTestUser({ email: 'user1@test.com' });
      const user2 = await createTestUser({ email: 'user2@test.com' });
      const ticket = await createTestSupportTicket(user1._id);

      const { request } = await authenticatedRequest('GET', `/api/support/tickets/${ticket.ticketId}`, user2);

      const response = await request;
      expectError(response, 403);
    });

    test('should return 404 for non-existent ticket', async () => {
      const { request } = await authenticatedRequest('GET', '/api/support/tickets/TKT-NONEXISTENT');

      const response = await request;
      expectError(response, 404);
    });
  });

  describe('POST /api/support/tickets/:ticketId/messages - Add Message', () => {
    test('should add message to ticket', async () => {
      const user = await createTestUser();
      const ticket = await createTestSupportTicket(user._id);

      const { request } = await authenticatedRequest('POST', `/api/support/tickets/${ticket.ticketId}/messages`);

      const messageData = {
        message: 'This is a test message',
        isInternal: false
      };

      const response = await request.send(messageData);
      const result = expectSuccess(response, 201);

      expect(result.data).toHaveProperty('message');
      expect(result.data.message.message).toBe(messageData.message);
      expect(result.data.message.senderType).toBe('user');
      expect(result.data.message.isInternal).toBe(false);
    });

    test('should allow admin to add internal messages', async () => {
      const user = await createTestUser();
      const ticket = await createTestSupportTicket(user._id);

      const { request } = await adminRequest('POST', `/api/support/tickets/${ticket.ticketId}/messages`);

      const response = await request.send({
        message: 'Internal admin note',
        isInternal: true
      });

      expectSuccess(response, 201);
    });

    test('should fail when user tries to send internal message', async () => {
      const user = await createTestUser();
      const ticket = await createTestSupportTicket(user._id);

      const { request } = await authenticatedRequest('POST', `/api/support/tickets/${ticket.ticketId}/messages`);

      const response = await request.send({
        message: 'Trying to send internal message',
        isInternal: true
      });

      expectError(response, 403);
    });

    test('should reopen resolved ticket when user responds', async () => {
      const user = await createTestUser();
      const ticket = await createTestSupportTicket(user._id, { status: 'resolved' });

      const { request } = await authenticatedRequest('POST', `/api/support/tickets/${ticket.ticketId}/messages`, user);

      const response = await request.send({ message: 'User response to resolved ticket' });
      expectSuccess(response, 201);

      // Check if ticket status changed
      const updatedTicket = await SupportTicket.findById(ticket._id);
      expect(updatedTicket.status).toBe('open');
    });
  });

  describe('PUT /api/support/tickets/:ticketId/status - Update Ticket Status (Admin)', () => {
    test('should update ticket status', async () => {
      const user = await createTestUser();
      const ticket = await createTestSupportTicket(user._id);

      const { request } = await adminRequest('PUT', `/api/support/tickets/${ticket.ticketId}/status`);

      const response = await request.send({
        status: 'in_progress',
        priority: 'high',
        notes: 'Working on this issue'
      });

      const result = expectSuccess(response);
      expect(result.data.ticket.status).toBe('in_progress');
      expect(result.data.ticket.priority).toBe('high');
    });

    test('should assign ticket to agent', async () => {
      const user = await createTestUser();
      const agent = await createTestUser({ email: 'agent@test.com' });
      const ticket = await createTestSupportTicket(user._id);

      const { request } = await adminRequest('PUT', `/api/support/tickets/${ticket.ticketId}/status`);

      const response = await request.send({
        assignedTo: agent._id.toString()
      });

      const result = expectSuccess(response);
      expect(result.data.ticket.assignedTo.toString()).toBe(agent._id.toString());
    });

    test('should fail for non-admin user', async () => {
      const user = await createTestUser();
      const ticket = await createTestSupportTicket(user._id);

      const { request } = await authenticatedRequest('PUT', `/api/support/tickets/${ticket.ticketId}/status`);

      const response = await request.send({ status: 'in_progress' });
      expectError(response, 403);
    });
  });

  describe('POST /api/support/tickets/:ticketId/resolve - Resolve Ticket (Admin)', () => {
    test('should resolve ticket with solution', async () => {
      const user = await createTestUser();
      const ticket = await createTestSupportTicket(user._id);

      const { request, user: adminUser } = await adminRequest('POST', `/api/support/tickets/${ticket.ticketId}/resolve`);

      const response = await request.send({
        solution: 'Issue resolved by resetting user preferences',
        satisfaction: 5
      });

      const result = expectSuccess(response);
      expect(result.data.ticket.status).toBe('resolved');
      expect(result.data.ticket.resolution.solution).toBe('Issue resolved by resetting user preferences');
      expect(result.data.ticket.resolution.satisfaction).toBe(5);
      expect(result.data.ticket.resolution.resolvedBy.toString()).toBe(adminUser._id.toString());
    });

    test('should fail for non-admin user', async () => {
      const user = await createTestUser();
      const ticket = await createTestSupportTicket(user._id);

      const { request } = await authenticatedRequest('POST', `/api/support/tickets/${ticket.ticketId}/resolve`);

      const response = await request.send({
        solution: 'User trying to resolve ticket'
      });

      expectError(response, 403);
    });
  });

  describe('GET /api/support/faq - Get FAQ List', () => {
    test('should get FAQ list', async () => {
      // Create some FAQs
      await FAQ.create([
        {
          question: 'How do I book a ride?',
          answer: 'Open the app and select your destination',
          category: 'getting_started',
          tags: ['booking', 'app']
        },
        {
          question: 'How do I cancel a booking?',
          answer: 'Go to your bookings and select cancel',
          category: 'booking',
          tags: ['booking', 'cancel']
        }
      ]);

      const response = await request.get('/api/support/faq');
      const result = expectSuccess(response);

      expect(result.data).toHaveProperty('faqs');
      expect(result.data).toHaveProperty('total');
      expect(Array.isArray(result.data.faqs)).toBe(true);
      expect(result.data.total).toBe(2);
    });

    test('should filter FAQs by category', async () => {
      await FAQ.create([
        {
          question: 'Payment question',
          answer: 'Answer about payment',
          category: 'payment'
        },
        {
          question: 'Booking question',
          answer: 'Answer about booking',
          category: 'booking'
        }
      ]);

      const response = await request.get('/api/support/faq?category=booking');
      const result = expectSuccess(response);

      expect(result.data.faqs.length).toBe(1);
      expect(result.data.faqs[0].category).toBe('booking');
    });

    test('should search FAQs by text', async () => {
      await FAQ.create([
        {
          question: 'How to pay with card',
          answer: 'Use credit card option',
          category: 'payment'
        },
        {
          question: 'How to book a luxury car',
          answer: 'Select luxury option',
          category: 'booking'
        }
      ]);

      const response = await request.get('/api/support/faq?search=card');
      const result = expectSuccess(response);

      expect(result.data.faqs.length).toBe(1);
      expect(result.data.faqs[0].question).toContain('card');
    });
  });

  describe('GET /api/support/faq/categories - Get FAQ Categories', () => {
    test('should get FAQ categories', async () => {
      await FAQ.create([
        { question: 'Q1', answer: 'A1', category: 'getting_started' },
        { question: 'Q2', answer: 'A2', category: 'payment' },
        { question: 'Q3', answer: 'A3', category: 'getting_started' }
      ]);

      const response = await request.get('/api/support/faq/categories');
      const result = expectSuccess(response);

      expect(result.data).toHaveProperty('categories');
      expect(Array.isArray(result.data.categories)).toBe(true);
      expect(result.data.categories.length).toBe(2);

      const categories = result.data.categories;
      expect(categories.some(cat => cat.id === 'getting_started')).toBe(true);
      expect(categories.some(cat => cat.id === 'payment')).toBe(true);
    });
  });

  describe('POST /api/support/faq/:faqId/helpful - Mark FAQ Helpful', () => {
    test('should increment helpful count', async () => {
      const faq = await FAQ.create({
        question: 'Test question',
        answer: 'Test answer',
        category: 'booking'
      });

      const response = await request.post(`/api/support/faq/${faq._id}/helpful`);
      expectSuccess(response);

      const updatedFaq = await FAQ.findById(faq._id);
      expect(updatedFaq.helpfulCount).toBe(1);
      expect(updatedFaq.viewCount).toBe(1);
    });

    test('should return 404 for non-existent FAQ', async () => {
      const response = await request.post('/api/support/faq/507f1f77bcf86cd799439011/helpful');
      expectError(response, 404);
    });
  });

  describe('GET /api/support/contact - Get Contact Information', () => {
    test('should return company contact information', async () => {
      const response = await request.get('/api/support/contact');
      const result = expectSuccess(response);

      expect(result.data).toHaveProperty('company');
      expect(result.data).toHaveProperty('support');
      expect(result.data).toHaveProperty('sales');
      expect(result.data).toHaveProperty('social');

      const company = result.data.company;
      expect(company).toHaveProperty('name');
      expect(company).toHaveProperty('address');
      expect(company).toHaveProperty('phone');
      expect(company).toHaveProperty('email');
    });
  });

  describe('Support Ticket Model Methods', () => {
    test('should assign ticket to agent', async () => {
      const user = await createTestUser();
      const agent = await createTestUser({ email: 'agent@test.com' });
      const ticket = await createTestSupportTicket(user._id);

      await ticket.assignTo(agent._id);

      expect(ticket.assignedTo.toString()).toBe(agent._id.toString());
      expect(ticket.status).toBe('in_progress');
    });

    test('should resolve ticket', async () => {
      const user = await createTestUser();
      const agent = await createTestUser({ email: 'agent@test.com' });
      const ticket = await createTestSupportTicket(user._id);

      await ticket.resolve(agent._id, 'Issue resolved', 4);

      expect(ticket.status).toBe('resolved');
      expect(ticket.resolution.resolvedBy.toString()).toBe(agent._id.toString());
      expect(ticket.resolution.solution).toBe('Issue resolved');
      expect(ticket.resolution.satisfaction).toBe(4);
    });

    test('should add message to ticket', async () => {
      const user = await createTestUser();
      const ticket = await createTestSupportTicket(user._id);

      const message = await ticket.addMessage(user._id, 'user', 'Test message', [], false);

      expect(message.message).toBe('Test message');
      expect(message.senderType).toBe('user');
      expect(message.isInternal).toBe(false);

      // Check that ticket was updated
      const updatedTicket = await SupportTicket.findById(ticket._id);
      expect(updatedTicket.updatedAt.getTime()).toBeGreaterThan(ticket.updatedAt.getTime());
    });

    test('should calculate virtual properties', async () => {
      const user = await createTestUser();
      const ticket = await createTestSupportTicket(user._id);

      expect(ticket.isResolved).toBe(false);

      ticket.status = 'resolved';
      expect(ticket.isResolved).toBe(true);
    });
  });

  describe('FAQ Model Static Methods', () => {
    test('should search FAQs correctly', async () => {
      await FAQ.create([
        {
          question: 'How to book',
          answer: 'Booking instructions',
          category: 'booking',
          tags: ['book', 'ride']
        },
        {
          question: 'Payment methods',
          answer: 'Payment info',
          category: 'payment',
          tags: ['pay', 'card']
        }
      ]);

      const results = await FAQ.searchFAQs('book', 'booking');
      expect(results.length).toBe(1);
      expect(results[0].question).toBe('How to book');

      const allResults = await FAQ.searchFAQs('pay');
      expect(allResults.length).toBe(1);
      expect(allResults[0].category).toBe('payment');
    });
  });
});
