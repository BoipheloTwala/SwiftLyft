const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const swaggerUi = require('swagger-ui-express');
const swaggerSpecs = require('./config/swagger');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const quoteRoutes = require('./routes/quotes');
const driverRoutes = require('./routes/drivers');
const bookingRoutes = require('./routes/bookings');
const vehicleRoutes = require('./routes/vehicles');
const notificationRoutes = require('./routes/notifications');
const analyticsRoutes = require('./routes/analytics');
const supportRoutes = require('./routes/support');
const specialFeaturesRoutes = require('./routes/special-features');
const paymentRoutes = require('./routes/payments');
const locationRoutes = require('./routes/location');
const errorHandler = require('./middleware/errorHandler');

const app = express();

// Trust proxy for Render deployment
app.set('trust proxy', 1);

// Security middleware
app.use(helmet());
const defaultAllowedOrigins = ['http://localhost:3000', 'http://localhost:3001', 'https://swiftlyft-frontend.onrender.com'];
const configuredOrigins = process.env.CORS_ORIGIN ? process.env.CORS_ORIGIN.split(',') : [];
const allowedOrigins = [...new Set([...defaultAllowedOrigins, ...configuredOrigins])];

app.use(cors({
  origin: function(origin, callback) {
    // Allow non-browser requests (no origin) and health checks
    if (!origin) return callback(null, true);
    // Allow localhost and 127.0.0.1 on any port for development tools
    if (origin.startsWith('http://localhost:') || origin.startsWith('http://127.0.0.1:')) {
      return callback(null, true);
    }
    if (allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    return callback(new Error('CORS not allowed for origin: ' + origin), false);
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept']
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100, // limit each IP to 100 requests per windowMs
  message: {
    error: 'Too many requests from this IP, please try again later.'
  }
});
app.use('/api/', limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// MongoDB connection (skip in tests; Jest manages its own in-memory DB)
if (process.env.NODE_ENV !== 'test') {
  mongoose.connect(process.env.MONGODB_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .then(() => console.log('✅ Connected to MongoDB'))
  .catch((err) => console.error('❌ MongoDB connection error:', err));
}

// Swagger Documentation
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpecs, {
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: 'SwiftLyft API Documentation',
  swaggerOptions: {
    persistAuthorization: true,
    displayRequestDuration: true,
    filter: true,
    showExtensions: true,
    showCommonExtensions: true
  }
}));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/quotes', quoteRoutes);
app.use('/api/drivers', driverRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/vehicles', vehicleRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/support', supportRoutes);
app.use('/api', specialFeaturesRoutes); // Special features routes
app.use('/api/payments', paymentRoutes); // Payment routes
app.use('/api/location', locationRoutes); // Location & mapping routes

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'SwiftLyft API is running!',
    version: '1.0.0',
    endpoints: {
      health: '/api/health',
      auth: '/api/auth',
      users: '/api/users',
      quotes: '/api/quotes',
      drivers: '/api/drivers',
      bookings: '/api/bookings',
      vehicles: '/api/vehicles',
      notifications: '/api/notifications',
      analytics: '/api/analytics',
      support: '/api/support',
      offers: '/api/offers',
      corporate: '/api/corporate',
      services: '/api/services',
      payments: '/api/payments',
      location: '/api/location'
    },
    documentation: 'Visit /api-docs for Swagger API documentation'
  });
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Error handling middleware (must be last)
app.use(errorHandler);

// Handle 404
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'API endpoint not found'
  });
});

const PORT = process.env.PORT || 3000;

// Start the HTTP server unless explicitly disabled
// Allow starting in test mode if SERVER_START=true is set (for API testing)
const shouldStartServer = process.env.NODE_ENV !== 'test' || process.env.SERVER_START === 'true';

if (shouldStartServer) {
  app.listen(PORT, () => {
    console.log(`🚀 SwiftLyft API running on port ${PORT}`);
    console.log(`📖 Environment: ${process.env.NODE_ENV || 'development'}`);
  });
}

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  mongoose.connection.close(() => {
    process.exit(0);
  });
});

// Export the Express app for testing
module.exports = app;