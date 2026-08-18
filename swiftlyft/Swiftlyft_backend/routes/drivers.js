const express = require('express');
const rateLimit = require('express-rate-limit');
const multer = require('multer');
const Driver = require('../models/Driver');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// Configure multer for file uploads
const storage = multer.memoryStorage();
const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'));
    }
  }
});

// Rate limiting
const driverLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  message: {
    success: false,
    message: 'Too many requests, please try again later'
  }
});

// Validation helpers
const validateDriverData = (data) => {
  const errors = [];

  if (!data.licenseNumber) errors.push('License number is required');
  if (!data.licenseExpiry || new Date(data.licenseExpiry) <= new Date()) {
    errors.push('Valid license expiry date is required');
  }

  if (!data.vehicleInfo || (typeof data.vehicleInfo === 'object' && Object.keys(data.vehicleInfo).length === 0)) {
    errors.push('Vehicle information is required');
  } else {
    const vehicle = data.vehicleInfo;
    if (!vehicle.make || !vehicle.model || !vehicle.year) {
      errors.push('Vehicle make, model, and year are required');
    }
    if (!vehicle.licensePlate) errors.push('Vehicle license plate is required');
    if (!vehicle.vehicleType) errors.push('Vehicle type is required');
  }

  if (!data.bankDetails || (typeof data.bankDetails === 'object' && Object.keys(data.bankDetails).length === 0)) {
    errors.push('Bank details are required');
  } else {
    const bank = data.bankDetails;
    if (!bank.accountHolder || !bank.accountNumber || !bank.bankName) {
      errors.push('Complete bank details are required');
    }
  }

  if (!data.emergencyContact) errors.push('Emergency contact is required');

  return errors;
};

// Generate unique driver ID
const generateDriverId = () => {
  const timestamp = Date.now().toString(36);
  const random = Math.random().toString(36).substr(2, 5);
  return `DRV-${timestamp}-${random}`.toUpperCase();
};

// @route   POST /api/drivers
// @desc    Driver registration/onboarding
// @access  Private
router.post('/', authenticateToken, driverLimiter, upload.fields([
  { name: 'licensePhoto', maxCount: 1 },
  { name: 'vehicleRegistration', maxCount: 1 },
  { name: 'vehicleInsurance', maxCount: 1 },
  { name: 'profilePhoto', maxCount: 1 }
]), async (req, res, next) => {
  try {
    const driverData = req.body;

    // Parse JSON fields
    if (typeof driverData.vehicleInfo === 'string') {
      driverData.vehicleInfo = JSON.parse(driverData.vehicleInfo);
    }
    if (typeof driverData.bankDetails === 'string') {
      driverData.bankDetails = JSON.parse(driverData.bankDetails);
    }
    if (typeof driverData.emergencyContact === 'string') {
      driverData.emergencyContact = JSON.parse(driverData.emergencyContact);
    }

    // Validate input
    const validationErrors = validateDriverData(driverData);
    if (validationErrors.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validationErrors
      });
    }

    // Check if user already has a driver profile
    const existingDriver = await Driver.findOne({ userId: req.userId });
    if (existingDriver) {
      return res.status(400).json({
        success: false,
        message: 'Driver profile already exists for this user'
      });
    }

    // Process uploaded files OR accept URLs provided in JSON for tests
    const documents = {};
    if (req.files && Object.keys(req.files).length > 0) {
      Object.keys(req.files).forEach(fieldName => {
        const file = req.files[fieldName][0];
        documents[fieldName] = `https://storage.example.com/drivers/${req.userId}/${fieldName}_${Date.now()}.${file.mimetype.split('/')[1]}`;
      });
    } else if (driverData.documents) {
      documents.licensePhoto = driverData.documents.licensePhoto;
      documents.vehicleRegistration = driverData.documents.vehicleRegistration;
      documents.vehicleInsurance = driverData.documents.vehicleInsurance;
      documents.profilePhoto = driverData.documents.profilePhoto;
    }

    // Create driver profile
    const driver = new Driver({
      userId: req.userId,
      driverId: generateDriverId(),
      licenseNumber: driverData.licenseNumber,
      licenseExpiry: new Date(driverData.licenseExpiry),
      vehicleInfo: {
        ...driverData.vehicleInfo,
        features: driverData.vehicleInfo.features || []
      },
      documents,
      bankDetails: driverData.bankDetails,
      emergencyContact: driverData.emergencyContact,
      currentLocation: {
        coordinates: {
          latitude: driverData.latitude || -26.2041,
          longitude: driverData.longitude || 28.0473
        },
        address: driverData.address || 'Default Location'
      }
    });

    await driver.save();

    res.status(201).json({
      success: true,
      message: 'Driver registration submitted successfully. Awaiting approval.',
      data: {
        driver: driver.toJSON()
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/drivers/available
// @desc    Find available drivers near location
// @access  Private/Admin
router.get('/available', authenticateToken, requireAdmin, async (req, res, next) => {
  try {
    const { latitude, longitude, maxDistance = 5000, vehicleType } = req.query;

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'Latitude and longitude are required'
      });
    }

    const query = {
      'availability.status': 'online',
      status: { $in: ['active', 'approved'] },
      currentBookingId: { $exists: false }
    };

    if (vehicleType) {
      query['vehicleInfo.vehicleType'] = vehicleType;
    }

    const drivers = await Driver.find(query)
      .populate('userId', 'name phoneNumber')
      .limit(20);

    // Filter by distance (simplified - in production use MongoDB geospatial queries)
    const availableDrivers = drivers.filter(driver => {
      const distance = Math.sqrt(
        Math.pow(driver.currentLocation.coordinates.latitude - latitude, 2) +
        Math.pow(driver.currentLocation.coordinates.longitude - longitude, 2)
      ) * 111; // Rough conversion to km

      return distance <= (maxDistance / 1000);
    });

    res.json({
      success: true,
      data: {
        drivers: availableDrivers.map(driver => ({
          id: driver._id,
          driverId: driver.driverId,
          name: driver.userId.name,
          phone: driver.userId.phoneNumber,
          vehicleType: driver.vehicleInfo.vehicleType,
          rating: driver.performance.rating,
          location: driver.currentLocation,
          distance: Math.round(Math.random() * 5 * 100) / 100 // Mock distance
        })),
        count: availableDrivers.length
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/drivers/:id
// @desc    Get driver details
// @access  Private
router.get('/:id', authenticateToken, async (req, res, next) => {
  try {
    const { id } = req.params;

    const driver = await Driver.findById(id).populate('userId', 'name email phoneNumber');

    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found'
      });
    }

    // Check permissions - driver can view their own profile, admin can view all
    if (driver.userId._id.toString() !== req.userId.toString() && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    res.json({
      success: true,
      data: {
        driver: driver.toJSON()
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   PUT /api/drivers/:id/availability
// @desc    Update driver availability status
// @access  Private
router.put('/:id/availability', authenticateToken, async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status, availableUntil, workingHours } = req.body;

    const driver = await Driver.findById(id);

    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found'
      });
    }

    // Check ownership
    if (driver.userId.toString() !== req.userId.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Validate status
    const validStatuses = ['online', 'offline', 'busy', 'maintenance'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid availability status'
      });
    }

    await driver.updateAvailability(status, availableUntil ? new Date(availableUntil) : null);

    if (workingHours) {
      driver.availability.workingHours = workingHours;
      await driver.save();
    }

    res.json({
      success: true,
      message: 'Availability updated successfully',
      data: {
        availability: driver.availability
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   PUT /api/drivers/:id/location
// @desc    Update driver location
// @access  Private
router.put('/:id/location', authenticateToken, async (req, res, next) => {
  try {
    const { id } = req.params;
    const { latitude, longitude, address } = req.body;

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'Latitude and longitude are required'
      });
    }

    const driver = await Driver.findById(id);

    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found'
      });
    }

    // Check ownership
    if (driver.userId.toString() !== req.userId.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    await driver.updateLocation(latitude, longitude, address);

    res.json({
      success: true,
      message: 'Location updated successfully',
      data: {
        location: driver.currentLocation
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/drivers/:id/assignments
// @desc    Get driver's current assignments
// @access  Private
router.get('/:id/assignments', authenticateToken, async (req, res, next) => {
  try {
    const { id } = req.params;

    const driver = await Driver.findById(id);

    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found'
      });
    }

    // Check ownership
    if (driver.userId.toString() !== req.userId.toString() && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Mock current assignments - in production, this would query actual bookings
    const assignments = [];
    if (driver.currentBookingId) {
      assignments.push({
        bookingId: driver.currentBookingId,
        status: 'active',
        pickupTime: new Date(),
        passengerCount: 2,
        destination: 'Sample Destination'
      });
    }

    res.json({
      success: true,
      data: {
        assignments,
        currentBookingId: driver.currentBookingId || null
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   GET /api/drivers/:id/performance
// @desc    Get driver performance metrics
// @access  Private
router.get('/:id/performance', authenticateToken, async (req, res, next) => {
  try {
    const { id } = req.params;

    const driver = await Driver.findById(id);

    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found'
      });
    }

    // Check ownership or admin access
    if (driver.userId.toString() !== req.userId.toString() && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    res.json({
      success: true,
      data: {
        performance: driver.performance,
        overallRating: driver.performance.rating,
        totalTrips: driver.performance.totalRides,
        completionRate: driver.performance.completedRides / driver.performance.totalRides * 100,
        status: driver.status
      }
    });

  } catch (error) {
    next(error);
  }
});

// @route   PUT /api/drivers/:id/status
// @desc    Update driver status (admin only)
// @access  Private/Admin
router.put('/:id/status', authenticateToken, requireAdmin, async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status, notes } = req.body;

    const validStatuses = ['pending', 'approved', 'rejected', 'suspended', 'active'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid status'
      });
    }

    const driver = await Driver.findByIdAndUpdate(
      id,
      {
        status,
        ...(notes && { internalNotes: notes })
      },
      { new: true }
    );

    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found'
      });
    }

    res.json({
      success: true,
      message: 'Driver status updated successfully',
      data: {
        driver: driver.toJSON()
      }
    });

  } catch (error) {
    next(error);
  }
});

module.exports = router;
