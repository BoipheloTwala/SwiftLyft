const express = require('express');
const router = express.Router();
const Vehicle = require('../models/Vehicle');
const Driver = require('../models/Driver');
const { authenticateToken } = require('../middleware/auth');

// Helper function to transform vehicle to frontend-compatible format
function transformVehicleForFrontend(vehicle, includeDetails = false) {
  // Handle both Mongoose documents and plain objects (from lean())
  const vehicleDoc = vehicle.toObject ? vehicle.toObject() : vehicle;
  
  const baseTransform = {
    id: vehicleDoc._id?.toString() || vehicleDoc.id,
    vehicleId: vehicleDoc.vehicleId,
    name: vehicleDoc.name || vehicleDoc.fullName || 'Unknown Vehicle',
    description: vehicleDoc.description || `${vehicleDoc.year || ''} ${vehicleDoc.make || ''} ${vehicleDoc.model || ''}`.trim() || 'Vehicle description',
    category: vehicleDoc.category,
    imageUrl: vehicleDoc.imageUrl || (vehicleDoc.images?.exterior?.[0] || ''),
    imageGallery: vehicleDoc.imageGallery || vehicleDoc.images?.exterior || [],
    seatingCapacity: vehicleDoc.passengerCapacity || vehicleDoc.seatingCapacity || 4,
    passengerCapacity: vehicleDoc.passengerCapacity || vehicleDoc.seatingCapacity || 4,
    features: vehicleDoc.features || [],
    basePrice: vehicleDoc.pricing?.baseFare || vehicleDoc.basePrice || 0,
    city: vehicleDoc.currentLocation?.city || vehicleDoc.city || 'Unknown',
    status: vehicleDoc.status,
    availability: vehicleDoc.availability,
    isAvailable: vehicleDoc.availability?.isAvailable !== false && vehicleDoc.status !== 'inactive'
  };

  if (includeDetails) {
    return {
      ...baseTransform,
      make: vehicleDoc.make,
      model: vehicleDoc.model,
      year: vehicleDoc.year,
      color: vehicleDoc.color,
      licensePlate: vehicleDoc.licensePlate,
      passengerCapacity: vehicleDoc.passengerCapacity || vehicleDoc.seatingCapacity || 4,
      luggageCapacity: vehicleDoc.luggageCapacity,
      fuelType: vehicleDoc.fuelType,
      transmission: vehicleDoc.transmission,
      mileage: vehicleDoc.mileage,
      rating: vehicleDoc.rating || 0,
      totalTrips: vehicleDoc.totalTrips || 0,
      totalEarnings: vehicleDoc.totalEarnings || 0,
      driver: vehicleDoc.driverId ? {
        id: vehicleDoc.driverId._id?.toString() || vehicleDoc.driverId.id,
        driverId: vehicleDoc.driverId.driverId,
        name: vehicleDoc.driverId.userId?.name || 'Unknown',
        phone: vehicleDoc.driverId.userId?.phoneNumber || 'Unknown',
        photo: vehicleDoc.driverId.userId?.profileImageUrl || '',
        rating: vehicleDoc.driverId.rating || 0,
        performance: vehicleDoc.driverId.performance || {}
      } : null,
      pricing: vehicleDoc.pricing || {},
      currentLocation: vehicleDoc.currentLocation || {},
      maintenance: vehicleDoc.maintenance || {},
      insurance: vehicleDoc.insurance || {},
      documents: vehicleDoc.documents || {}
    };
  }

  return baseTransform;
}

// GET /api/vehicles/available - List available vehicles by location
router.get('/available', async (req, res) => {
  try {
    const { latitude, longitude, maxDistance = 10000, category, passengerCount, features, limit = 50 } = req.query;

    // Validate required coordinates
    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'Latitude and longitude are required'
      });
    }

    // Parse coordinates
    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);
    const maxDist = parseInt(maxDistance);

    if (isNaN(lat) || isNaN(lng) || isNaN(maxDist)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid coordinates or distance parameters'
      });
    }

    // Build query - simplified for better performance
    // Accept both 'active' and 'available' status, and check availability flag
    const query = {
      $or: [
        { status: 'active' },
        { status: 'available' }
      ],
      'availability.isAvailable': true,
    };

    // Add location filter if coordinates exist in database
    // Use a broader range to catch vehicles, then filter if needed
    if (maxDist < 100000) { // Only apply location filter for reasonable distances
      query['currentLocation.coordinates.latitude'] = {
        $gte: lat - (maxDist / 111000),
        $lte: lat + (maxDist / 111000)
      };
      query['currentLocation.coordinates.longitude'] = {
        $gte: lng - (maxDist / (111000 * Math.cos(lat * Math.PI / 180))),
        $lte: lng + (maxDist / (111000 * Math.cos(lat * Math.PI / 180)))
      };
    }

    // Add filters
    if (category) query.category = category;
    if (passengerCount) query.passengerCapacity = { $gte: parseInt(passengerCount) };
    if (features) {
      const featureArray = Array.isArray(features) ? features : features.split(',');
      query.features = { $in: featureArray };
    }

    // Optimize query: only select needed fields, skip populate for list view (driver not needed)
    const vehicles = await Vehicle.find(query)
      .select('vehicleId name description category passengerCapacity features pricing.baseFare basePrice currentLocation status availability imageUrl images year make model') // Only select needed fields
      .lean() // Use lean() for faster queries (returns plain JS objects, works better without populate)
      .limit(parseInt(limit))
      .maxTimeMS(5000); // Add timeout to prevent hanging queries

    // Transform vehicles efficiently
    const frontendVehicles = vehicles.map(vehicle => 
      transformVehicleForFrontend(vehicle, false)
    );

    res.json({
      success: true,
      data: frontendVehicles,
      count: frontendVehicles.length,
      message: 'Available vehicles retrieved successfully'
    });
  } catch (error) {
    console.error('Error fetching available vehicles:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch available vehicles',
      error: error.message
    });
  }
});

// GET /api/vehicles/categories - Vehicle type categories
router.get('/categories', async (req, res) => {
  try {
    const categories = await Vehicle.getVehicleCategories();
    
    // Get additional stats for each category
    const categoryStats = await Vehicle.getVehicleStats();

    const categoryData = categories.map(category => {
      const stats = categoryStats.find(stat => stat._id === category);
      return {
        category,
        count: stats ? stats.count : 0,
        available: stats ? stats.available : 0,
        averageRating: stats ? Math.round((stats.averageRating || 0) * 10) / 10 : 0
      };
    });

    res.json({
      success: true,
      data: categoryData,
      message: 'Vehicle categories retrieved successfully'
    });
  } catch (error) {
    console.error('Error fetching vehicle categories:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch vehicle categories',
      error: error.message
    });
  }
});

// GET /api/vehicles/search - Search vehicles by criteria
router.get('/search', async (req, res) => {
  try {
    const {
      latitude,
      longitude,
      maxDistance = 10000,
      category,
      passengerCount,
      features,
      make,
      model,
      year,
      minPrice,
      maxPrice,
      limit = 50,
      page = 1
    } = req.query;

    // Build search criteria
    const searchCriteria = {
      latitude: parseFloat(latitude),
      longitude: parseFloat(longitude),
      maxDistance: parseInt(maxDistance),
      category,
      passengerCount: passengerCount ? parseInt(passengerCount) : undefined,
      features: features ? features.split(',') : undefined,
      make,
      model,
      year: year ? parseInt(year) : undefined,
      minPrice: minPrice ? parseFloat(minPrice) : undefined,
      maxPrice: maxPrice ? parseFloat(maxPrice) : undefined,
      limit: parseInt(limit),
      page: parseInt(page)
    };

    // Validate required coordinates
    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'Latitude and longitude are required for vehicle search'
      });
    }

    const vehicles = await Vehicle.searchVehicles(searchCriteria);
    const total = await Vehicle.countDocuments({ isActive: true });

    res.json({
      success: true,
      data: vehicles,
      searchCriteria,
      pagination: {
        currentPage: searchCriteria.page,
        totalPages: Math.ceil(total / searchCriteria.limit),
        totalResults: total,
        limit: searchCriteria.limit
      },
      message: 'Vehicle search completed successfully'
    });
  } catch (error) {
    console.error('Error searching vehicles:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to search vehicles',
      error: error.message
    });
  }
});

// GET /api/vehicles/stats - Get vehicle statistics
router.get('/stats', async (req, res) => {
  try {
    const stats = await Vehicle.getVehicleStats();
    
    res.json({
      success: true,
      data: stats,
      message: 'Vehicle statistics retrieved successfully'
    });
  } catch (error) {
    console.error('Error fetching vehicle statistics:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch vehicle statistics',
      error: error.message
    });
  }
});

// GET /api/vehicles/driver/{driverId} - Get all vehicles for a driver
router.get('/driver/:driverId', async (req, res) => {
  try {
    const { driverId } = req.params;

    // Find driver by driverId (not ObjectId)
    const driver = await Driver.findOne({ driverId });
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found'
      });
    }

    // Get vehicles for this driver
    const vehicles = await Vehicle.find({ driverId: driver._id })
      .populate('driverId', 'driverId performance rating userId')
      .populate('driverId.userId', 'name phoneNumber profileImageUrl');

    const frontendVehicles = vehicles.map(vehicle => 
      transformVehicleForFrontend(vehicle, true)
    );

    res.json({
      success: true,
      data: frontendVehicles,
      message: 'Driver vehicles retrieved successfully'
    });
  } catch (error) {
    console.error('Error fetching driver vehicles:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch driver vehicles',
      error: error.message
    });
  }
});

// GET /api/vehicles/{id} - Detailed vehicle information
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const vehicle = await Vehicle.findByVehicleId(id)
      .populate('driverId', 'driverId performance rating userId')
      .populate('driverId.userId', 'name phoneNumber profileImageUrl');

    if (!vehicle) {
      return res.status(404).json({
        success: false,
        message: 'Vehicle not found'
      });
    }

    // Transform vehicle to frontend-compatible format
    const frontendVehicle = transformVehicleForFrontend(vehicle, true);

    res.json({
      success: true,
      data: frontendVehicle,
      message: 'Vehicle details retrieved successfully'
    });
  } catch (error) {
    console.error('Error fetching vehicle details:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch vehicle details',
      error: error.message
    });
  }
});

// GET /api/vehicles/{id}/availability - Check real-time availability
router.get('/:id/availability', async (req, res) => {
  try {
    const { id } = req.params;

    const vehicle = await Vehicle.findByVehicleId(id);
    if (!vehicle) {
      return res.status(404).json({
        success: false,
        message: 'Vehicle not found'
      });
    }

    // Check availability status
    const isAvailable = vehicle.availability?.isAvailable !== false && 
                       vehicle.status === 'active';

    res.json({
      success: true,
      data: {
        vehicleId: vehicle.vehicleId,
        isAvailable,
        status: vehicle.status,
        availability: vehicle.availability,
        nextAvailableTime: vehicle.availability?.nextAvailableTime || null,
        currentBooking: vehicle.currentBooking || null
      },
      message: 'Vehicle availability checked successfully'
    });
  } catch (error) {
    console.error('Error checking vehicle availability:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to check vehicle availability',
      error: error.message
    });
  }
});

// PUT /api/vehicles/{id}/status - Update availability status
router.put('/:id/status', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { status, availability } = req.body;

    const vehicle = await Vehicle.findByVehicleId(id);
    if (!vehicle) {
      return res.status(404).json({
        success: false,
        message: 'Vehicle not found'
      });
    }

    // Validate status
    const validStatuses = ['active', 'inactive', 'busy', 'maintenance'];
    if (status && !validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid status. Must be one of: ' + validStatuses.join(', ')
      });
    }

    // Update vehicle status and availability
    const updateData = {};
    if (status) updateData.status = status;
    
    // Handle availability updates
    if (availability) {
      updateData.availability = availability;
    } else {
      // Handle individual availability fields
      if (req.body.isAvailable !== undefined) {
        updateData['availability.isAvailable'] = req.body.isAvailable;
      }
      if (req.body.availableUntil) {
        updateData['availability.availableUntil'] = req.body.availableUntil;
      }
      if (req.body.availableFrom) {
        updateData['availability.availableFrom'] = req.body.availableFrom;
      }
    }

    const updatedVehicle = await Vehicle.findByIdAndUpdate(
      vehicle._id,
      updateData,
      { new: true, runValidators: true }
    );

    res.json({
      success: true,
      data: transformVehicleForFrontend(updatedVehicle, true),
      message: 'Vehicle status updated successfully'
    });
  } catch (error) {
    console.error('Error updating vehicle status:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update vehicle status',
      error: error.message
    });
  }
});

// POST /api/vehicles - Create a new vehicle (for drivers)
router.post('/', authenticateToken, async (req, res) => {
  try {
    const vehicleData = req.body;
    
    // Add driver ID from authenticated user if not provided
    if (!vehicleData.driverId) {
      vehicleData.driverId = req.userId;
    }

    // Generate vehicle ID
    const timestamp = Date.now().toString(36).slice(-4);
    const random = Math.random().toString(36).substring(2, 6);
    vehicleData.vehicleId = `VH${timestamp}${random}`.toUpperCase();

    // Set default values
    vehicleData.status = vehicleData.status || 'active';
    vehicleData.availability = vehicleData.availability || { isAvailable: true };
    vehicleData.rating = vehicleData.rating || 0;
    vehicleData.totalTrips = vehicleData.totalTrips || 0;
    vehicleData.totalEarnings = vehicleData.totalEarnings || 0;

    const vehicle = new Vehicle(vehicleData);
    await vehicle.save();

    // Populate driver information
    await vehicle.populate('driverId', 'driverId performance rating userId');
    await vehicle.populate('driverId.userId', 'name phoneNumber profileImageUrl');

    res.status(201).json({
      success: true,
      data: transformVehicleForFrontend(vehicle, true),
      message: 'Vehicle created successfully'
    });
  } catch (error) {
    console.error('Error creating vehicle:', error);
    
    // Handle validation errors
    if (error.name === 'ValidationError') {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: Object.keys(error.errors).map(key => ({
          field: key,
          message: error.errors[key].message
        }))
      });
    }
    
    res.status(500).json({
      success: false,
      message: 'Failed to create vehicle',
      error: error.message
    });
  }
});

// PUT /api/vehicles/{id} - Update vehicle information
router.put('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    const vehicle = await Vehicle.findByVehicleId(id);
    if (!vehicle) {
      return res.status(404).json({
        success: false,
        message: 'Vehicle not found'
      });
    }

    // Check if user owns this vehicle or is admin
    // First, check if the vehicle's driver belongs to the authenticated user
    const driver = await Driver.findById(vehicle.driverId);
    if (!driver || driver.userId.toString() !== req.userId.toString()) {
      if (req.user.role !== 'admin') {
        return res.status(403).json({
          success: false,
          message: 'Not authorized to update this vehicle'
        });
      }
    }

    const updatedVehicle = await Vehicle.findByIdAndUpdate(
      vehicle._id,
      updateData,
      { new: true, runValidators: true }
    );

    // Populate driver information
    await updatedVehicle.populate('driverId', 'driverId performance rating userId');
    await updatedVehicle.populate('driverId.userId', 'name phoneNumber profileImageUrl');

    res.json({
      success: true,
      data: transformVehicleForFrontend(updatedVehicle, true),
      message: 'Vehicle updated successfully'
    });
  } catch (error) {
    console.error('Error updating vehicle:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update vehicle',
      error: error.message
    });
  }
});

module.exports = router;
