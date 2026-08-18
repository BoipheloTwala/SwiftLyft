const mongoose = require('mongoose');

const locationSchema = new mongoose.Schema({
  // Basic location information (Flutter LatLng compatible)
  latitude: {
    type: Number,
    required: true,
    min: -90,
    max: 90
  },
  longitude: {
    type: Number,
    required: true,
    min: -180,
    max: 180
  },
  
  // Flutter-specific location data
  coordinates: {
    lat: {
      type: Number,
      min: -90,
      max: 90
    },
    lng: {
      type: Number,
      min: -180,
      max: 180
    }
  },
  
  // Address information
  address: {
    formatted: {
      type: String,
      required: true
    },
    streetNumber: String,
    streetName: String,
    suburb: String,
    city: String,
    state: String,
    country: String,
    countryCode: String,
    postcode: String
  },
  
  // Location metadata
  accuracy: {
    type: Number,
    default: null // GPS accuracy in meters
  },
  altitude: {
    type: Number,
    default: null // Altitude in meters
  },
  heading: {
    type: Number,
    min: 0,
    max: 360,
    default: null // Direction in degrees
  },
  speed: {
    type: Number,
    default: null // Speed in km/h
  },
  
  // Service area information (Flutter compatible)
  serviceArea: {
    name: String,
    isInServiceArea: {
      type: Boolean,
      default: false
    },
    nearestServiceArea: {
      name: String,
      distance: Number, // in meters
      center: {
        latitude: Number,
        longitude: Number
      }
    },
    // Flutter service area data
    city: String,
    radius: Number, // in km
    center: {
      latitude: Number,
      longitude: Number
    }
  },
  
  // Location type and category
  type: {
    type: String,
    enum: ['pickup', 'dropoff', 'waypoint', 'driver', 'landmark', 'other'],
    default: 'other'
  },
  category: {
    type: String,
    enum: ['residential', 'commercial', 'airport', 'station', 'hospital', 'school', 'other'],
    default: 'other'
  },
  
  // Associated entities
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  driverId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Driver',
    default: null
  },
  bookingId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Booking',
    default: null
  },
  
  // Timestamps
  timestamp: {
    type: Date,
    default: Date.now
  },
  lastUpdated: {
    type: Date,
    default: Date.now
  },
  
  // Additional metadata
  metadata: {
    source: {
      type: String,
      enum: ['gps', 'manual', 'geocoded', 'reverse_geocoded'],
      default: 'manual'
    },
    confidence: {
      type: String,
      enum: ['high', 'medium', 'low'],
      default: 'medium'
    },
    notes: String,
    tags: [String]
  },
  
  // Status
  isActive: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
});

// Indexes for efficient querying
locationSchema.index({ latitude: 1, longitude: 1 });
locationSchema.index({ userId: 1 });
locationSchema.index({ driverId: 1 });
locationSchema.index({ bookingId: 1 });
locationSchema.index({ type: 1 });
locationSchema.index({ 'serviceArea.isInServiceArea': 1 });
locationSchema.index({ timestamp: -1 });

// Geospatial index for location-based queries
locationSchema.index({ 
  location: '2dsphere' 
});

// Virtual field for geospatial queries
locationSchema.virtual('location').get(function() {
  return {
    type: 'Point',
    coordinates: [this.longitude, this.latitude]
  };
});

// Pre-save middleware to update lastUpdated and sync coordinates
locationSchema.pre('save', function(next) {
  this.lastUpdated = new Date();
  
  // Sync coordinates for Flutter compatibility
  if (this.latitude !== undefined && this.longitude !== undefined) {
    this.coordinates = {
      lat: this.latitude,
      lng: this.longitude
    };
  }
  
  next();
});

// Static method to find locations within a radius
locationSchema.statics.findNearby = function(latitude, longitude, radiusInKm = 10, options = {}) {
  const query = {
    latitude: {
      $gte: latitude - (radiusInKm / 111), // Rough conversion: 1 degree ≈ 111 km
      $lte: latitude + (radiusInKm / 111)
    },
    longitude: {
      $gte: longitude - (radiusInKm / (111 * Math.cos(latitude * Math.PI / 180))),
      $lte: longitude + (radiusInKm / (111 * Math.cos(latitude * Math.PI / 180)))
    },
    isActive: true
  };

  // Add additional filters
  if (options.type) {
    query.type = options.type;
  }
  if (options.category) {
    query.category = options.category;
  }
  if (options.userId) {
    query.userId = options.userId;
  }
  if (options.driverId) {
    query.driverId = options.driverId;
  }

  return this.find(query).limit(options.limit || 50);
};

// Static method to find locations in service area
locationSchema.statics.findInServiceArea = function(serviceAreaName) {
  return this.find({
    'serviceArea.name': serviceAreaName,
    'serviceArea.isInServiceArea': true,
    isActive: true
  });
};

// Instance method to calculate distance to another location
locationSchema.methods.distanceTo = function(otherLocation) {
  const R = 6371; // Earth's radius in kilometers
  const dLat = this.toRadians(otherLocation.latitude - this.latitude);
  const dLon = this.toRadians(otherLocation.longitude - this.longitude);
  
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(this.toRadians(this.latitude)) * Math.cos(this.toRadians(otherLocation.latitude)) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
  
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c; // Distance in kilometers
};

// Helper method to convert degrees to radians
locationSchema.methods.toRadians = function(degrees) {
  return degrees * (Math.PI / 180);
};

// Instance method to check if location is in service area (Flutter compatible)
locationSchema.methods.checkServiceArea = function() {
  const serviceAreas = [
    // Johannesburg area (matches Flutter frontend)
    { 
      name: 'Johannesburg', 
      city: 'Johannesburg',
      bounds: { north: -26.0, south: -26.3, east: 28.2, west: 27.8 },
      center: { latitude: -26.2041, longitude: 28.0473 },
      radius: 50.0 // km
    },
    // Cape Town area (matches Flutter frontend)
    { 
      name: 'Cape Town', 
      city: 'Cape Town',
      bounds: { north: -33.7, south: -34.0, east: 18.6, west: 18.3 },
      center: { latitude: -33.9249, longitude: 18.4241 },
      radius: 50.0 // km
    },
    // Durban area
    { 
      name: 'Durban', 
      city: 'Durban',
      bounds: { north: -29.7, south: -30.0, east: 31.1, west: 30.8 },
      center: { latitude: -29.8587, longitude: 31.0218 },
      radius: 50.0 // km
    },
    // Pretoria area
    { 
      name: 'Pretoria', 
      city: 'Pretoria',
      bounds: { north: -25.6, south: -25.8, east: 28.3, west: 28.0 },
      center: { latitude: -25.7479, longitude: 28.2293 },
      radius: 50.0 // km
    }
  ];

  for (const area of serviceAreas) {
    if (this.latitude <= area.bounds.north && this.latitude >= area.bounds.south &&
        this.longitude <= area.bounds.east && this.longitude >= area.bounds.west) {
      this.serviceArea = {
        name: area.name,
        city: area.city,
        isInServiceArea: true,
        center: area.center,
        radius: area.radius
      };
      return this.serviceArea;
    }
  }

  // Find nearest service area
  let nearest = null;
  let minDistance = Infinity;

  for (const area of serviceAreas) {
    const centerLat = (area.bounds.north + area.bounds.south) / 2;
    const centerLon = (area.bounds.east + area.bounds.west) / 2;
    
    const distance = this.distanceTo({ latitude: centerLat, longitude: centerLon });

    if (distance < minDistance) {
      minDistance = distance;
      nearest = {
        name: area.name,
        city: area.city,
        distance: distance * 1000, // meters
        center: area.center,
        radius: area.radius
      };
    }
  }

  this.serviceArea = {
    isInServiceArea: false,
    nearestServiceArea: nearest
  };

  return this.serviceArea;
};

// Transform output for Flutter compatibility
locationSchema.methods.toJSON = function() {
  const obj = this.toObject();
  
  // Ensure coordinates are always present for Flutter
  if (obj.latitude !== undefined && obj.longitude !== undefined) {
    obj.coordinates = {
      lat: obj.latitude,
      lng: obj.longitude
    };
  }
  
  // Add Flutter-compatible location object
  obj.location = {
    latitude: obj.latitude,
    longitude: obj.longitude
  };
  
  return obj;
};

module.exports = mongoose.model('Location', locationSchema);
