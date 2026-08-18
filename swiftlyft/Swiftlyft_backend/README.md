# SwiftLyft Backend API

A comprehensive ride-sharing and logistics platform backend built with Node.js, Express, and MongoDB.

## 📚 Documentation

**👉 [View Comprehensive Documentation](COMPREHENSIVE_DOCUMENTATION.md)**

The comprehensive documentation includes:
- Complete API reference
- Database schema documentation
- Security and authentication guide
- Setup and deployment instructions
- Testing and troubleshooting guides

## 🚀 Quick Start

```bash
# Install dependencies
npm install

# Setup environment
cp env.example .env
# Edit .env with your configuration

# Setup database
npm run db:setup
npm run db:indexes

# Start development server
npm run dev
```

## 🔧 Available Scripts

- `npm start` - Start production server
- `npm run dev` - Start development server with nodemon
- `npm test` - Run test suite
- `npm run db:setup` - Setup database with indexes
- `npm run db:indexes` - Create database indexes
- `npm run db:seed` - Seed database with sample data

## 📋 Features

- **User Management**: Registration, authentication, profiles, loyalty programs
- **Vehicle Management**: Vehicle registration, availability tracking
- **Booking System**: Trip booking, real-time tracking
- **Payment Processing**: Multiple payment methods, transaction tracking
- **Location Services**: Geospatial queries, route calculation
- **Analytics**: Comprehensive reporting and statistics
- **Security**: JWT authentication, input validation, rate limiting

## 🔗 API Endpoints

- **Base URL**: `http://localhost:3000/api`
- **Documentation**: `http://localhost:3000/api-docs`
- **Health Check**: `http://localhost:3000/api/health`

## 📖 For Complete Documentation

See [COMPREHENSIVE_DOCUMENTATION.md](COMPREHENSIVE_DOCUMENTATION.md) for detailed information about:
- API endpoints and usage
- Database schema and setup
- Security implementation
- Deployment instructions
- Testing guidelines
- Troubleshooting tips

---

**Version**: 1.0.0  
**Last Updated**: December 2024
