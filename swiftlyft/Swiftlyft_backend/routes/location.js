const express = require('express');
const router = express.Router();
const locationService = require('../utils/locationService');
const Location = require('../models/Location');
const Driver = require('../models/Driver');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

/**
 * @route POST /api/location/geocode
 * @desc Convert addresses to coordinates
 * @access Public
 */
router.post('/geocode', async (req, res) => {
  try {
    const { address } = req.body;

    if (!address) {
      return res.status(400).json({
        success: false,
        message: 'Address is required'
      });
    }

    const result = await locationService.geocode(address);
    
    // Add Flutter-compatible response format
    const flutterResult = {
      ...result,
      coordinates: {
        lat: result.latitude,
        lng: result.longitude
      },
      location: {
        latitude: result.latitude,
        longitude: result.longitude
      }
    };
    
    // Optionally save the geocoded location
    if (req.body.saveLocation) {
      const location = new Location({
        latitude: result.latitude,
        longitude: result.longitude,
        address: result.address,
        type: req.body.type || 'other',
        category: req.body.category || 'other',
        userId: req.user?.id,
        metadata: {
          source: 'geocoded',
          confidence: result.accuracy === 'high' ? 'high' : 'medium'
        }
      });

      await location.save();
      flutterResult.locationId = location._id;
    }

    res.json({
      success: true,
      data: flutterResult
    });
  } catch (error) {
    console.error('Geocoding error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

/**
 * @route POST /api/location/reverse-geocode
 * @desc Convert coordinates to addresses
 * @access Public
 */
router.post('/reverse-geocode', async (req, res) => {
  try {
    const { latitude, longitude } = req.body;

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'Latitude and longitude are required'
      });
    }

    const result = await locationService.reverseGeocode(latitude, longitude);
    
    // Add Flutter-compatible response format
    const flutterResult = {
      ...result,
      coordinates: {
        lat: result.latitude,
        lng: result.longitude
      },
      location: {
        latitude: result.latitude,
        longitude: result.longitude
      }
    };
    
    // Optionally save the reverse geocoded location
    if (req.body.saveLocation) {
      const location = new Location({
        latitude: result.latitude,
        longitude: result.longitude,
        address: result.address,
        type: req.body.type || 'other',
        category: req.body.category || 'other',
        userId: req.user?.id,
        metadata: {
          source: 'reverse_geocoded',
          confidence: 'medium'
        }
      });

      await location.save();
      flutterResult.locationId = location._id;
    }

    res.json({
      success: true,
      data: flutterResult
    });
  } catch (error) {
    console.error('Reverse geocoding error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

/**
 * @route POST /api/location/route
 * @desc Calculate routes and travel time
 * @access Public
 */
router.post('/route', async (req, res) => {
  try {
    const { origin, destination, options = {} } = req.body;

    if (!origin || !destination) {
      return res.status(400).json({
        success: false,
        message: 'Origin and destination coordinates are required'
      });
    }

    if (!origin.latitude || !origin.longitude || !destination.latitude || !destination.longitude) {
      return res.status(400).json({
        success: false,
        message: 'Valid origin and destination coordinates are required'
      });
    }

    const result = await locationService.calculateRoute(origin, destination, options);

    // Add Flutter-compatible route format
    const flutterResult = {
      ...result,
      origin: {
        latitude: origin.latitude,
        longitude: origin.longitude,
        coordinates: {
          lat: origin.latitude,
          lng: origin.longitude
        }
      },
      destination: {
        latitude: destination.latitude,
        longitude: destination.longitude,
        coordinates: {
          lat: destination.latitude,
          lng: destination.longitude
        }
      },
      // Convert coordinates array to Flutter LatLng format
      routeCoordinates: result.coordinates.map(coord => ({
        latitude: coord.latitude,
        longitude: coord.longitude,
        coordinates: {
          lat: coord.latitude,
          lng: coord.longitude
        }
      }))
    };

    res.json({
      success: true,
      data: flutterResult
    });
  } catch (error) {
    console.error('Route calculation error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

/**
 * @route GET /api/location/places/search
 * @desc Search for places/addresses
 * @access Public
 */
router.get('/places/search', async (req, res) => {
  try {
    const { q: query, limit = 10, bounds } = req.query;

    if (!query) {
      return res.status(400).json({
        success: false,
        message: 'Search query is required'
      });
    }

    const options = {
      limit: parseInt(limit),
      bounds: bounds ? JSON.parse(bounds) : undefined
    };

    const results = await locationService.searchPlaces(query, options);

    // Add Flutter-compatible format for places
    const flutterResults = results.map(place => ({
      ...place,
      coordinates: {
        lat: place.latitude,
        lng: place.longitude
      },
      location: {
        latitude: place.latitude,
        longitude: place.longitude
      }
    }));

    res.json({
      success: true,
      data: flutterResults,
      count: flutterResults.length
    });
  } catch (error) {
    console.error('Place search error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

/**
 * @route GET /api/location/places/nearby
 * @desc Find nearby locations
 * @access Public
 */
router.get('/places/nearby', async (req, res) => {
  try {
    const { latitude, longitude, radius = 1000, category = 'amenity', limit = 20 } = req.query;

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'Latitude and longitude are required'
      });
    }

    const options = {
      radius: parseInt(radius),
      category,
      limit: parseInt(limit)
    };

    const results = await locationService.findNearbyPlaces(
      parseFloat(latitude),
      parseFloat(longitude),
      options
    );

    // Add Flutter-compatible format for nearby places
    const flutterResults = results.map(place => ({
      ...place,
      coordinates: {
        lat: place.latitude,
        lng: place.longitude
      },
      location: {
        latitude: place.latitude,
        longitude: place.longitude
      }
    }));

    res.json({
      success: true,
      data: flutterResults,
      count: flutterResults.length
    });
  } catch (error) {
    console.error('Nearby places error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

/**
 * @route POST /api/location/service-area
 * @desc Verify service coverage
 * @access Public
 */
router.post('/service-area', async (req, res) => {
  try {
    const { latitude, longitude } = req.body;

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'Latitude and longitude are required'
      });
    }

    const result = await locationService.checkServiceArea(latitude, longitude);

    // Add Flutter-compatible service area response
    const flutterResult = {
      ...result,
      coordinates: {
        lat: latitude,
        lng: longitude
      },
      location: {
        latitude: latitude,
        longitude: longitude
      },
      // Add Flutter service area format
      serviceAreas: result.isInServiceArea ? [{
        city: result.serviceArea,
        center: {
          latitude: latitude,
          longitude: longitude
        },
        radius: 50.0 // km
      }] : []
    };

    res.json({
      success: true,
      data: flutterResult
    });
  } catch (error) {
    console.error('Service area check error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

/**
 * @route GET /api/drivers/:id/location
 * @desc Real-time driver tracking
 * @access Private (Driver/Admin)
 */
router.get('/drivers/:id/location', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    // Verify driver exists first
    const driver = await Driver.findById(id);
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found'
      });
    }

    // Check if user is authorized to view this driver's location
    if (req.user.role !== 'admin' && req.user.role !== 'driver') {
      // Check if the user owns this driver profile
      if (driver.userId.toString() !== req.userId.toString()) {
        return res.status(403).json({
          success: false,
          message: 'Not authorized to view this driver location'
        });
      }
    }

    const location = await locationService.getDriverLocation(id);

    // Add Flutter-compatible driver location format
    const flutterLocation = {
      ...location,
      coordinates: {
        lat: location.latitude,
        lng: location.longitude
      },
      location: {
        latitude: location.latitude,
        longitude: location.longitude
      }
    };

    res.json({
      success: true,
      data: flutterLocation
    });
  } catch (error) {
    console.error('Driver location error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

/**
 * @route GET /api/location/history
 * @desc Get location history for a user
 * @access Private
 */
router.get('/history', authenticateToken, async (req, res) => {
  try {
    const { type, limit = 50, page = 1 } = req.query;
    
    const query = { userId: req.user.id, isActive: true };
    if (type) {
      query.type = type;
    }

    const locations = await Location.find(query)
      .sort({ timestamp: -1 })
      .limit(parseInt(limit))
      .skip((parseInt(page) - 1) * parseInt(limit));

    const total = await Location.countDocuments(query);

    res.json({
      success: true,
      data: locations,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Location history error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

/**
 * @route POST /api/location/save
 * @desc Save a location
 * @access Private
 */
router.post('/save', authenticateToken, async (req, res) => {
  try {
    const {
      latitude,
      longitude,
      address,
      type = 'other',
      category = 'other',
      accuracy,
      altitude,
      heading,
      speed,
      notes,
      tags
    } = req.body;

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'Latitude and longitude are required'
      });
    }

    const location = new Location({
      latitude,
      longitude,
      address,
      type,
      category,
      accuracy,
      altitude,
      heading,
      speed,
      userId: req.user.id,
      metadata: {
        source: 'manual',
        confidence: 'medium',
        notes,
        tags
      }
    });

    // Check service area
    location.checkServiceArea();

    await location.save();

    res.status(201).json({
      success: true,
      data: location
    });
  } catch (error) {
    console.error('Save location error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

/**
 * @route GET /api/location/nearby-saved
 * @desc Find nearby saved locations
 * @access Private
 */
router.get('/nearby-saved', authenticateToken, async (req, res) => {
  try {
    const { latitude, longitude, radius = 10, type, limit = 20 } = req.query;

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'Latitude and longitude are required'
      });
    }

    const options = {
      type,
      limit: parseInt(limit)
    };

    const locations = await Location.findNearby(
      parseFloat(latitude),
      parseFloat(longitude),
      parseFloat(radius),
      options
    );

    res.json({
      success: true,
      data: locations,
      count: locations.length
    });
  } catch (error) {
    console.error('Nearby saved locations error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

/**
 * @route PUT /api/location/:id
 * @desc Update a saved location
 * @access Private
 */
router.put('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    const location = await Location.findOne({ _id: id, userId: req.user.id });
    if (!location) {
      return res.status(404).json({
        success: false,
        message: 'Location not found'
      });
    }

    // Update location data
    Object.keys(updateData).forEach(key => {
      if (updateData[key] !== undefined) {
        location[key] = updateData[key];
      }
    });

    // Recheck service area if coordinates changed
    if (updateData.latitude || updateData.longitude) {
      location.checkServiceArea();
    }

    await location.save();

    res.json({
      success: true,
      data: location
    });
  } catch (error) {
    console.error('Update location error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

/**
 * @route DELETE /api/location/:id
 * @desc Delete a saved location
 * @access Private
 */
router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    const location = await Location.findOne({ _id: id, userId: req.user.id });
    if (!location) {
      return res.status(404).json({
        success: false,
        message: 'Location not found'
      });
    }

    location.isActive = false;
    await location.save();

    res.json({
      success: true,
      message: 'Location deleted successfully'
    });
  } catch (error) {
    console.error('Delete location error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

/**
 * @route POST /api/location/validate
 * @desc Validate address for Flutter frontend
 * @access Public
 */
router.post('/validate', async (req, res) => {
  try {
    const { address, latitude, longitude } = req.body;

    if (!address && (!latitude || !longitude)) {
      return res.status(400).json({
        success: false,
        message: 'Either address or coordinates are required'
      });
    }

    let validationResult = {
      isValid: false,
      address: null,
      coordinates: null,
      serviceArea: null,
      suggestions: []
    };

    // Validate address if provided
    if (address) {
      if (address.trim().length < 10) {
        validationResult.suggestions.push('Address must be at least 10 characters long');
      } else {
        try {
          const geocodeResult = await locationService.geocode(address);
          validationResult.isValid = true;
          validationResult.address = geocodeResult.formattedAddress;
          validationResult.coordinates = {
            lat: geocodeResult.latitude,
            lng: geocodeResult.longitude
          };
          
          // Check service area
          const serviceAreaResult = await locationService.checkServiceArea(
            geocodeResult.latitude, 
            geocodeResult.longitude
          );
          validationResult.serviceArea = serviceAreaResult;
        } catch (error) {
          validationResult.suggestions.push('Address not found. Please try a more specific address.');
        }
      }
    }

    // Validate coordinates if provided
    if (latitude && longitude) {
      try {
        const reverseGeocodeResult = await locationService.reverseGeocode(latitude, longitude);
        validationResult.isValid = true;
        validationResult.address = reverseGeocodeResult.formattedAddress;
        validationResult.coordinates = {
          lat: latitude,
          lng: longitude
        };
        
        // Check service area
        const serviceAreaResult = await locationService.checkServiceArea(latitude, longitude);
        validationResult.serviceArea = serviceAreaResult;
      } catch (error) {
        validationResult.suggestions.push('Invalid coordinates provided');
      }
    }

    res.json({
      success: true,
      data: validationResult
    });
  } catch (error) {
    console.error('Location validation error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

/**
 * @route GET /api/location/nearby/vehicles
 * @desc Find nearby vehicles
 * @access Public
 */
router.get('/nearby/vehicles', async (req, res) => {
  try {
    const { latitude, longitude, radius = 5000, category, limit = 20 } = req.query;

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'Latitude and longitude are required'
      });
    }

    const Vehicle = require('../models/Vehicle');
    
    // Build query for nearby vehicles
    const query = {
      'currentLocation.coordinates.latitude': {
        $gte: parseFloat(latitude) - 0.05, // ~5km radius
        $lte: parseFloat(latitude) + 0.05
      },
      'currentLocation.coordinates.longitude': {
        $gte: parseFloat(longitude) - 0.05,
        $lte: parseFloat(longitude) + 0.05
      },
      'availability.isAvailable': true,
      status: 'available'
    };

    if (category) {
      query.category = category;
    }

    const vehicles = await Vehicle.find(query)
      .limit(parseInt(limit))
      .select('vehicleId name make model year color category passengerCapacity currentLocation pricing features');

    // Calculate distances and sort
    const vehiclesWithDistance = vehicles.map(vehicle => {
      const distance = calculateDistance(
        { latitude: parseFloat(latitude), longitude: parseFloat(longitude) },
        { 
          latitude: vehicle.currentLocation.coordinates.latitude, 
          longitude: vehicle.currentLocation.coordinates.longitude 
        }
      );

      return {
        ...vehicle.toObject(),
        distance: distance * 1000, // Convert to meters
        distanceKm: distance
      };
    }).filter(vehicle => vehicle.distance <= parseInt(radius))
      .sort((a, b) => a.distance - b.distance);

    res.json({
      success: true,
      data: vehiclesWithDistance,
      count: vehiclesWithDistance.length,
      searchParams: {
        latitude: parseFloat(latitude),
        longitude: parseFloat(longitude),
        radius: parseInt(radius),
        category: category || 'all'
      }
    });
  } catch (error) {
    console.error('Nearby vehicles error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

/**
 * @route GET /api/location/nearby/drivers
 * @desc Find nearby drivers
 * @access Public
 */
router.get('/nearby/drivers', async (req, res) => {
  try {
    const { latitude, longitude, radius = 5000, status = 'online', limit = 20 } = req.query;

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'Latitude and longitude are required'
      });
    }

    const Driver = require('../models/Driver');
    
    // Build query for nearby drivers
    const query = {
      latitude: {
        $gte: parseFloat(latitude) - 0.05, // ~5km radius
        $lte: parseFloat(latitude) + 0.05
      },
      longitude: {
        $gte: parseFloat(longitude) - 0.05,
        $lte: parseFloat(longitude) + 0.05
      },
      status: status
    };

    const drivers = await Driver.find(query)
      .limit(parseInt(limit))
      .select('id licenseNumber vehicleInfo bankDetails emergencyContact latitude longitude address status availability');

    // Calculate distances and sort
    const driversWithDistance = drivers.map(driver => {
      const distance = calculateDistance(
        { latitude: parseFloat(latitude), longitude: parseFloat(longitude) },
        { latitude: driver.latitude, longitude: driver.longitude }
      );

      return {
        ...driver.toObject(),
        distance: distance * 1000, // Convert to meters
        distanceKm: distance
      };
    }).filter(driver => driver.distance <= parseInt(radius))
      .sort((a, b) => a.distance - b.distance);

    res.json({
      success: true,
      data: driversWithDistance,
      count: driversWithDistance.length,
      searchParams: {
        latitude: parseFloat(latitude),
        longitude: parseFloat(longitude),
        radius: parseInt(radius),
        status: status
      }
    });
  } catch (error) {
    console.error('Nearby drivers error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

/**
 * @route PUT /api/location/user/update
 * @desc Update user location
 * @access Private
 */
router.put('/user/update', authenticateToken, async (req, res) => {
  try {
    const { latitude, longitude, address, accuracy } = req.body;

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'Latitude and longitude are required'
      });
    }

    // Update user's last known location
    const User = require('../models/User');
    await User.findByIdAndUpdate(req.user.id, {
      'location.latitude': parseFloat(latitude),
      'location.longitude': parseFloat(longitude),
      'location.address': address,
      'location.accuracy': accuracy,
      'location.lastUpdated': new Date()
    });

    res.json({
      success: true,
      data: {
        location: {
          latitude: parseFloat(latitude),
          longitude: parseFloat(longitude),
          address: address,
          accuracy: accuracy,
          lastUpdated: new Date()
        }
      },
      message: 'Location updated successfully'
    });
  } catch (error) {
    console.error('Update location error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// Helper function to calculate distance between two points
function calculateDistance(point1, point2) {
  const R = 6371; // Earth's radius in kilometers
  const dLat = toRadians(point2.latitude - point1.latitude);
  const dLon = toRadians(point2.longitude - point1.longitude);
  
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(toRadians(point1.latitude)) * Math.cos(toRadians(point2.latitude)) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
  
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c; // Distance in kilometers
}

function toRadians(degrees) {
  return degrees * (Math.PI / 180);
}

/**
 * @route GET /api/location/service-areas
 * @desc Get all service areas for Flutter frontend
 * @access Public
 */
router.get('/service-areas', async (req, res) => {
  try {
    const serviceAreas = [
      {
        city: 'Johannesburg',
        center: {
          latitude: -26.2041,
          longitude: 28.0473
        },
        radius: 50.0, // km
        bounds: {
          north: -26.0,
          south: -26.3,
          east: 28.2,
          west: 27.8
        }
      },
      {
        city: 'Cape Town',
        center: {
          latitude: -33.9249,
          longitude: 18.4241
        },
        radius: 50.0, // km
        bounds: {
          north: -33.7,
          south: -34.0,
          east: 18.6,
          west: 18.3
        }
      },
      {
        city: 'Durban',
        center: {
          latitude: -29.8587,
          longitude: 31.0218
        },
        radius: 50.0, // km
        bounds: {
          north: -29.7,
          south: -30.0,
          east: 31.1,
          west: 30.8
        }
      },
      {
        city: 'Pretoria',
        center: {
          latitude: -25.7479,
          longitude: 28.2293
        },
        radius: 50.0, // km
        bounds: {
          north: -25.6,
          south: -25.8,
          east: 28.3,
          west: 28.0
        }
      }
    ];

    res.json({
      success: true,
      data: serviceAreas
    });
  } catch (error) {
    console.error('Service areas error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

module.exports = router;
