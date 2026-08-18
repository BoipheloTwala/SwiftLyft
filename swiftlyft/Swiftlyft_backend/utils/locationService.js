const NodeGeocoder = require('node-geocoder');
const axios = require('axios');

// Initialize geocoder with OpenStreetMap provider (free)
const geocoder = NodeGeocoder({
  provider: 'openstreetmap',
  httpAdapter: 'https',
  formatter: null,
  extra: {
    'User-Agent': 'SwiftLyft/1.0 (https://swiftlyft.com)',
    'Referer': 'https://swiftlyft.com'
  }
});

// Alternative geocoder for Google Maps (requires API key)
const googleGeocoder = NodeGeocoder({
  provider: 'google',
  httpAdapter: 'https',
  apiKey: process.env.GOOGLE_MAPS_API_KEY,
  formatter: null
});

class LocationService {
  constructor() {
    this.serviceAreas = [
      // Johannesburg area
      { name: 'Johannesburg', bounds: { north: -26.0, south: -26.3, east: 28.2, west: 27.8 } },
      // Cape Town area
      { name: 'Cape Town', bounds: { north: -33.7, south: -34.0, east: 18.6, west: 18.3 } },
      // Durban area
      { name: 'Durban', bounds: { north: -29.7, south: -30.0, east: 31.1, west: 30.8 } },
      // Pretoria area
      { name: 'Pretoria', bounds: { north: -25.6, south: -25.8, east: 28.3, west: 28.0 } }
    ];
  }

  /**
   * Convert address to coordinates
   * @param {string} address - Address to geocode
   * @returns {Promise<Object>} - Coordinates and address details
   */
  async geocode(address) {
    try {
      if (!address || typeof address !== 'string') {
        throw new Error('Valid address is required');
      }

      // Try Google Maps first if API key is available
      if (process.env.GOOGLE_MAPS_API_KEY) {
        try {
          const results = await googleGeocoder.geocode(address);
          if (results && results.length > 0) {
            return this.formatGeocodeResult(results[0]);
          }
        } catch (error) {
          console.warn('Google Geocoding failed, falling back to OpenStreetMap:', error.message);
        }
      }

      // Use direct Nominatim API with proper headers
      const encodedAddress = encodeURIComponent(address);
      const url = `https://nominatim.openstreetmap.org/search?format=json&q=${encodedAddress}&limit=1&addressdetails=1`;
      
      const response = await axios.get(url, {
        headers: {
          'User-Agent': 'SwiftLyft/1.0 (https://swiftlyft.com)',
          'Referer': 'https://swiftlyft.com',
          'Accept': 'application/json'
        },
        timeout: 10000 // 10 second timeout
      });

      if (!response.data || response.data.length === 0) {
        throw new Error('Address not found');
      }

      const result = response.data[0];
      return this.formatNominatimResult(result);
    } catch (error) {
      throw new Error(`Geocoding failed: ${error.message}`);
    }
  }

  /**
   * Convert coordinates to address
   * @param {number} latitude - Latitude coordinate
   * @param {number} longitude - Longitude coordinate
   * @returns {Promise<Object>} - Address details
   */
  async reverseGeocode(latitude, longitude) {
    try {
      if (!latitude || !longitude || typeof latitude !== 'number' || typeof longitude !== 'number') {
        throw new Error('Valid latitude and longitude are required');
      }

      // Try Google Maps first if API key is available
      if (process.env.GOOGLE_MAPS_API_KEY) {
        try {
          const results = await googleGeocoder.reverse({ lat: latitude, lon: longitude });
          if (results && results.length > 0) {
            return this.formatReverseGeocodeResult(results[0]);
          }
        } catch (error) {
          console.warn('Google Reverse Geocoding failed, falling back to OpenStreetMap:', error.message);
        }
      }

      // Use direct Nominatim API with proper headers
      const url = `https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}&addressdetails=1`;
      
      const response = await axios.get(url, {
        headers: {
          'User-Agent': 'SwiftLyft/1.0 (https://swiftlyft.com)',
          'Referer': 'https://swiftlyft.com',
          'Accept': 'application/json'
        },
        timeout: 10000 // 10 second timeout
      });

      if (!response.data) {
        throw new Error('Location not found');
      }

      return this.formatNominatimReverseResult(response.data);
    } catch (error) {
      throw new Error(`Reverse geocoding failed: ${error.message}`);
    }
  }

  /**
   * Calculate route between two points
   * @param {Object} origin - Origin coordinates {latitude, longitude}
   * @param {Object} destination - Destination coordinates {latitude, longitude}
   * @param {Object} options - Route options
   * @returns {Promise<Object>} - Route information
   */
  async calculateRoute(origin, destination, options = {}) {
    try {
      if (!origin || !destination || !origin.latitude || !origin.longitude || 
          !destination.latitude || !destination.longitude) {
        throw new Error('Valid origin and destination coordinates are required');
      }

      // Use OpenRouteService API for routing (free tier available)
      const apiKey = process.env.OPENROUTE_API_KEY;
      if (!apiKey) {
        // Fallback to simple distance calculation
        return this.calculateSimpleRoute(origin, destination, options);
      }

      const profile = options.profile || 'driving-car';
      const url = `https://api.openrouteservice.org/v2/directions/${profile}`;
      
      const response = await axios.post(url, {
        coordinates: [
          [origin.longitude, origin.latitude],
          [destination.longitude, destination.latitude]
        ],
        options: {
          avoid_features: options.avoid || [],
          avoid_borders: options.avoidBorders || 'none'
        }
      }, {
        headers: {
          'Authorization': apiKey,
          'Content-Type': 'application/json'
        }
      });

      if (!response.data || !response.data.features || response.data.features.length === 0) {
        throw new Error('No route found');
      }

      const route = response.data.features[0];
      const properties = route.properties;
      const summary = properties.summary;

      return {
        distance: summary.distance, // in meters
        duration: summary.duration, // in seconds
        coordinates: route.geometry.coordinates.map(coord => ({
          longitude: coord[0],
          latitude: coord[1]
        })),
        waypoints: route.geometry.coordinates.length,
        profile: profile,
        instructions: properties.segments ? this.formatInstructions(properties.segments) : []
      };
    } catch (error) {
      // Fallback to simple calculation
      return this.calculateSimpleRoute(origin, destination, options);
    }
  }

  /**
   * Simple route calculation using Haversine formula
   */
  calculateSimpleRoute(origin, destination, options = {}) {
    const distance = this.calculateDistance(origin, destination);
    const averageSpeed = options.averageSpeed || 50; // km/h
    const duration = (distance / averageSpeed) * 3600; // seconds

    return {
      distance: distance * 1000, // convert to meters
      duration: duration,
      coordinates: [
        { longitude: origin.longitude, latitude: origin.latitude },
        { longitude: destination.longitude, latitude: destination.latitude }
      ],
      waypoints: 2,
      profile: 'simple',
      instructions: []
    };
  }

  /**
   * Search for places/addresses
   * @param {string} query - Search query
   * @param {Object} options - Search options
   * @returns {Promise<Array>} - Array of place results
   */
  async searchPlaces(query, options = {}) {
    try {
      if (!query || typeof query !== 'string') {
        throw new Error('Valid search query is required');
      }

      const limit = options.limit || 10;
      const bounds = options.bounds;

      // Use Nominatim (OpenStreetMap) for place search
      let url = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(query)}&limit=${limit}`;
      
      if (bounds) {
        url += `&bounded=1&viewbox=${bounds.west},${bounds.south},${bounds.east},${bounds.north}`;
      }

      const response = await axios.get(url, {
        headers: {
          'User-Agent': 'SwiftLyft/1.0 (https://swiftlyft.com)',
          'Referer': 'https://swiftlyft.com',
          'Accept': 'application/json'
        },
        timeout: 10000
      });

      return response.data.map(place => ({
        name: place.display_name,
        latitude: parseFloat(place.lat),
        longitude: parseFloat(place.lon),
        type: place.type,
        importance: place.importance,
        address: {
          houseNumber: place.address?.house_number,
          road: place.address?.road,
          suburb: place.address?.suburb,
          city: place.address?.city,
          state: place.address?.state,
          country: place.address?.country,
          postcode: place.address?.postcode
        }
      }));
    } catch (error) {
      throw new Error(`Place search failed: ${error.message}`);
    }
  }

  /**
   * Find nearby places
   * @param {number} latitude - Center latitude
   * @param {number} longitude - Center longitude
   * @param {Object} options - Search options
   * @returns {Promise<Array>} - Array of nearby places
   */
  async findNearbyPlaces(latitude, longitude, options = {}) {
    try {
      if (!latitude || !longitude || typeof latitude !== 'number' || typeof longitude !== 'number') {
        throw new Error('Valid latitude and longitude are required');
      }

      const radius = options.radius || 1000; // meters
      const category = options.category || 'amenity';
      const limit = options.limit || 20;

      // Use Overpass API for nearby places
      const overpassQuery = `
        [out:json][timeout:25];
        (
          node["${category}"](around:${radius},${latitude},${longitude});
          way["${category}"](around:${radius},${latitude},${longitude});
          relation["${category}"](around:${radius},${latitude},${longitude});
        );
        out center;
      `;

      const response = await axios.post('https://overpass-api.de/api/interpreter', overpassQuery, {
        headers: {
          'Content-Type': 'text/plain'
        }
      });

      const places = response.data.elements.slice(0, limit).map(element => {
        const lat = element.lat || element.center?.lat;
        const lon = element.lon || element.center?.lon;
        
        return {
          id: element.id,
          name: element.tags?.name || 'Unnamed Place',
          latitude: lat,
          longitude: lon,
          type: element.tags?.amenity || element.tags?.shop || element.tags?.tourism || 'unknown',
          distance: this.calculateDistance(
            { latitude, longitude },
            { latitude: lat, longitude: lon }
          ) * 1000, // meters
          tags: element.tags
        };
      });

      return places.sort((a, b) => a.distance - b.distance);
    } catch (error) {
      throw new Error(`Nearby places search failed: ${error.message}`);
    }
  }

  /**
   * Check if location is within service area
   * @param {number} latitude - Latitude coordinate
   * @param {number} longitude - Longitude coordinate
   * @returns {Object} - Service area check result
   */
  checkServiceArea(latitude, longitude) {
    try {
      if (!latitude || !longitude || typeof latitude !== 'number' || typeof longitude !== 'number') {
        throw new Error('Valid latitude and longitude are required');
      }

      for (const area of this.serviceAreas) {
        if (latitude <= area.bounds.north && latitude >= area.bounds.south &&
            longitude <= area.bounds.east && longitude >= area.bounds.west) {
          return {
            isInServiceArea: true,
            serviceArea: area.name,
            coordinates: { latitude, longitude }
          };
        }
      }

      return {
        isInServiceArea: false,
        serviceArea: null,
        coordinates: { latitude, longitude },
        nearestServiceArea: this.findNearestServiceArea(latitude, longitude)
      };
    } catch (error) {
      throw new Error(`Service area check failed: ${error.message}`);
    }
  }

  /**
   * Get driver's current location (mock implementation)
   * @param {string} driverId - Driver ID
   * @returns {Object} - Driver location data
   */
  async getDriverLocation(driverId) {
    try {
      if (!driverId) {
        throw new Error('Driver ID is required');
      }

      // This would typically fetch from a real-time database or GPS service
      // For now, return mock data
      return {
        driverId,
        latitude: -26.2041 + (Math.random() - 0.5) * 0.1, // Johannesburg area
        longitude: 28.0473 + (Math.random() - 0.5) * 0.1,
        accuracy: Math.random() * 10 + 5, // meters
        timestamp: new Date().toISOString(),
        status: 'active',
        heading: Math.random() * 360, // degrees
        speed: Math.random() * 60 // km/h
      };
    } catch (error) {
      throw new Error(`Driver location retrieval failed: ${error.message}`);
    }
  }

  // Helper methods
  formatGeocodeResult(result) {
    return {
      latitude: result.latitude,
      longitude: result.longitude,
      formattedAddress: result.formattedAddress,
      address: {
        streetNumber: result.streetNumber,
        streetName: result.streetName,
        city: result.city,
        state: result.administrativeLevels?.level1long,
        country: result.country,
        countryCode: result.countryCode,
        zipcode: result.zipcode
      },
      accuracy: result.extra?.confidence || 'unknown'
    };
  }

  formatReverseGeocodeResult(result) {
    return {
      latitude: result.latitude,
      longitude: result.longitude,
      formattedAddress: result.formattedAddress,
      address: {
        streetNumber: result.streetNumber,
        streetName: result.streetName,
        city: result.city,
        state: result.administrativeLevels?.level1long,
        country: result.country,
        countryCode: result.countryCode,
        zipcode: result.zipcode
      }
    };
  }

  formatInstructions(segments) {
    return segments.flatMap(segment => 
      segment.steps.map(step => ({
        instruction: step.instruction,
        distance: step.distance,
        duration: step.duration,
        type: step.type
      }))
    );
  }

  calculateDistance(point1, point2) {
    const R = 6371; // Earth's radius in kilometers
    const dLat = this.toRadians(point2.latitude - point1.latitude);
    const dLon = this.toRadians(point2.longitude - point1.longitude);
    
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
              Math.cos(this.toRadians(point1.latitude)) * Math.cos(this.toRadians(point2.latitude)) *
              Math.sin(dLon / 2) * Math.sin(dLon / 2);
    
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c; // Distance in kilometers
  }

  toRadians(degrees) {
    return degrees * (Math.PI / 180);
  }

  findNearestServiceArea(latitude, longitude) {
    let nearest = null;
    let minDistance = Infinity;

    for (const area of this.serviceAreas) {
      const centerLat = (area.bounds.north + area.bounds.south) / 2;
      const centerLon = (area.bounds.east + area.bounds.west) / 2;
      
      const distance = this.calculateDistance(
        { latitude, longitude },
        { latitude: centerLat, longitude: centerLon }
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearest = {
          name: area.name,
          distance: distance * 1000, // meters
          center: { latitude: centerLat, longitude: centerLon }
        };
      }
    }

    return nearest;
  }

  /**
   * Format Nominatim geocoding result
   * @param {Object} result - Nominatim API result
   * @returns {Object} - Formatted result
   */
  formatNominatimResult(result) {
    const address = result.address || {};
    
    return {
      latitude: parseFloat(result.lat),
      longitude: parseFloat(result.lon),
      formattedAddress: result.display_name,
      address: {
        streetNumber: address.house_number || '',
        streetName: address.road || address.street || '',
        city: address.city || address.town || address.village || '',
        state: address.state || address.province || '',
        country: address.country || '',
        countryCode: address.country_code || '',
        zipcode: address.postcode || ''
      },
      accuracy: result.importance > 0.5 ? 'high' : 'medium'
    };
  }

  /**
   * Format Nominatim reverse geocoding result
   * @param {Object} result - Nominatim API result
   * @returns {Object} - Formatted result
   */
  formatNominatimReverseResult(result) {
    const address = result.address || {};
    
    return {
      latitude: parseFloat(result.lat),
      longitude: parseFloat(result.lon),
      formattedAddress: result.display_name,
      address: {
        streetNumber: address.house_number || '',
        streetName: address.road || address.street || '',
        city: address.city || address.town || address.village || '',
        state: address.state || address.province || '',
        country: address.country || '',
        countryCode: address.country_code || '',
        zipcode: address.postcode || ''
      }
    };
  }
}

module.exports = new LocationService();
