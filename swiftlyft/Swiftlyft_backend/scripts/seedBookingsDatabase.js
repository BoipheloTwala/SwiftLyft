const mongoose = require('mongoose');
const Booking = require('../models/Booking');
require('dotenv').config();

class BookingsDatabaseSeeder {
  constructor() {
    this.connection = null;
  }

  // Connect to MongoDB
  async connect() {
    try {
      const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/swiftlyft_bookings';
      
      this.connection = await mongoose.connect(mongoUri, {
        useNewUrlParser: true,
        useUnifiedTopology: true,
      });

      console.log('✅ Connected to MongoDB for Bookings seeding');
      console.log(`📊 Database: ${mongoose.connection.name}`);
      return this.connection;
    } catch (error) {
      console.error('❌ MongoDB connection error:', error);
      throw error;
    }
  }

  // Generate random location data
  generateLocationData(city = 'Cape Town', province = 'Western Cape') {
    const locations = {
      'Cape Town': {
        center: { latitude: -33.9249, longitude: 18.4241 },
        addresses: [
          '123 Main Street, Cape Town, South Africa',
          '456 Long Street, Cape Town, South Africa',
          '789 Kloof Street, Cape Town, South Africa',
          '321 V&A Waterfront, Cape Town, South Africa',
          '654 Table Mountain Road, Cape Town, South Africa',
          '987 Camps Bay Drive, Cape Town, South Africa',
          '147 Sea Point Promenade, Cape Town, South Africa',
          '258 Green Point, Cape Town, South Africa',
          '369 Gardens, Cape Town, South Africa',
          '741 Observatory, Cape Town, South Africa'
        ],
        postalCodes: ['8001', '8002', '8005', '8006', '8007', '8008', '8009', '8010', '8011', '8012']
      },
      'Johannesburg': {
        center: { latitude: -26.2041, longitude: 28.0473 },
        addresses: [
          '123 Sandton City, Johannesburg, South Africa',
          '456 Rosebank, Johannesburg, South Africa',
          '789 Melrose Arch, Johannesburg, South Africa',
          '321 Fourways, Johannesburg, South Africa',
          '654 Randburg, Johannesburg, South Africa',
          '987 Midrand, Johannesburg, South Africa',
          '147 Centurion, Johannesburg, South Africa',
          '258 Pretoria, Johannesburg, South Africa',
          '369 Bryanston, Johannesburg, South Africa',
          '741 Rivonia, Johannesburg, South Africa'
        ],
        postalCodes: ['2000', '2001', '2002', '2003', '2004', '2005', '2006', '2007', '2008', '2009']
      },
      'Durban': {
        center: { latitude: -29.8587, longitude: 31.0218 },
        addresses: [
          '123 uShaka Marine World, Durban, South Africa',
          '456 Gateway Theatre, Durban, South Africa',
          '789 Pavilion Shopping Centre, Durban, South Africa',
          '321 Umhlanga Rocks, Durban, South Africa',
          '654 Ballito, Durban, South Africa',
          '987 Amanzimtoti, Durban, South Africa',
          '147 Westville, Durban, South Africa',
          '258 Pinetown, Durban, South Africa',
          '369 Hillcrest, Durban, South Africa',
          '741 Kloof, Durban, South Africa'
        ],
        postalCodes: ['4000', '4001', '4002', '4003', '4004', '4005', '4006', '4007', '4008', '4009']
      }
    };

    const cityData = locations[city] || locations['Cape Town'];
    const randomAddress = cityData.addresses[Math.floor(Math.random() * cityData.addresses.length)];
    const randomPostalCode = cityData.postalCodes[Math.floor(Math.random() * cityData.postalCodes.length)];
    
    // Add some randomness to coordinates
    const randomLat = cityData.center.latitude + (Math.random() - 0.5) * 0.1;
    const randomLng = cityData.center.longitude + (Math.random() - 0.5) * 0.1;

    return {
      address: randomAddress,
      coordinates: {
        latitude: randomLat,
        longitude: randomLng
      },
      city: city,
      province: province,
      postalCode: randomPostalCode,
      instructions: Math.random() > 0.5 ? 'Ring the doorbell' : 'Wait at the main entrance',
      contactPhone: '+27' + Math.floor(Math.random() * 900000000 + 100000000),
      landmark: Math.random() > 0.5 ? 'Near the shopping center' : 'Near the park',
      buildingName: Math.random() > 0.5 ? 'Business Tower' : 'Residential Complex',
      floor: Math.random() > 0.5 ? 'Ground Floor' : `${Math.floor(Math.random() * 10) + 1}th Floor`,
      unit: Math.random() > 0.5 ? 'Unit ' + Math.floor(Math.random() * 100 + 1) : 'Suite ' + Math.floor(Math.random() * 100 + 1)
    };
  }

  // Generate random pricing data
  generatePricingData(vehicleType, serviceType, distance = 15) {
    const baseRates = {
      sedan: { base: 40, perKm: 8, perMin: 1.5 },
      suv: { base: 60, perKm: 12, perMin: 2.0 },
      luxury: { base: 100, perKm: 20, perMin: 3.0 },
      van: { base: 80, perKm: 15, perMin: 2.5 },
      truck: { base: 120, perKm: 25, perMin: 3.5 },
      motorcycle: { base: 30, perKm: 6, perMin: 1.0 },
      electric: { base: 50, perKm: 10, perMin: 1.8 },
      hybrid: { base: 45, perKm: 9, perMin: 1.6 }
    };

    const serviceMultipliers = {
      standard: 1.0,
      premium: 1.3,
      corporate: 1.5,
      airport: 1.2,
      security: 2.0,
      medical: 1.8,
      event: 1.4
    };

    const rate = baseRates[vehicleType] || baseRates.sedan;
    const multiplier = serviceMultipliers[serviceType] || 1.0;
    const estimatedTime = Math.max(20, distance * 2); // minutes

    const baseFare = rate.base * multiplier;
    const distanceFare = distance * rate.perKm * multiplier;
    const timeFare = estimatedTime * rate.perMin * multiplier;
    const serviceFee = Math.round(baseFare * 0.1);
    const taxes = Math.round((baseFare + distanceFare + timeFare + serviceFee) * 0.15);
    const discount = Math.random() > 0.7 ? Math.round(baseFare * 0.1) : 0;
    const loyaltyDiscount = Math.random() > 0.8 ? Math.round(baseFare * 0.05) : 0;
    const surgeMultiplier = Math.random() > 0.9 ? 1.5 : 1.0;
    const waitingFee = Math.random() > 0.8 ? Math.round(baseFare * 0.2) : 0;

    const subtotal = baseFare + distanceFare + timeFare + serviceFee + taxes - discount - loyaltyDiscount;
    const total = Math.round(subtotal * surgeMultiplier + waitingFee);

    return {
      baseFare: Math.round(baseFare),
      distanceFare: Math.round(distanceFare),
      timeFare: Math.round(timeFare),
      serviceFee: serviceFee,
      taxes: taxes,
      discount: discount,
      loyaltyDiscount: loyaltyDiscount,
      surgeMultiplier: surgeMultiplier,
      waitingFee: waitingFee,
      cancellationFee: 0,
      total: total,
      currency: 'ZAR',
      breakdown: {
        baseFare: Math.round(baseFare),
        distanceFare: Math.round(distanceFare),
        timeFare: Math.round(timeFare),
        serviceFee: serviceFee,
        taxes: taxes,
        discount: discount,
        loyaltyDiscount: loyaltyDiscount,
        surgeMultiplier: surgeMultiplier,
        waitingFee: waitingFee,
        cancellationFee: 0
      }
    };
  }

  // Generate random trip details
  generateTripDetails(estimatedDistance, estimatedDuration) {
    const actualDistance = estimatedDistance + (Math.random() - 0.5) * 5; // ±2.5km variation
    const actualDuration = estimatedDuration + (Math.random() - 0.5) * 20; // ±10min variation

    const trafficConditions = ['light', 'moderate', 'heavy', 'severe'][Math.floor(Math.random() * 4)];
    const weatherConditions = ['clear', 'rainy', 'stormy', 'foggy', 'snowy'][Math.floor(Math.random() * 5)];

    const route = [];
    const numPoints = Math.floor(Math.random() * 5) + 3; // 3-7 route points
    for (let i = 0; i < numPoints; i++) {
      route.push({
        latitude: -33.9249 + (Math.random() - 0.5) * 0.1,
        longitude: 18.4241 + (Math.random() - 0.5) * 0.1,
        timestamp: new Date(Date.now() - (numPoints - i) * 60000),
        speed: Math.floor(Math.random() * 80) + 20,
        heading: Math.floor(Math.random() * 360),
        accuracy: Math.floor(Math.random() * 10) + 1
      });
    }

    return {
      estimatedDistance: estimatedDistance,
      estimatedDuration: estimatedDuration,
      actualDistance: Math.round(actualDistance * 10) / 10,
      actualDuration: Math.round(actualDuration),
      route: route,
      startTime: new Date(Date.now() - actualDuration * 60000),
      endTime: new Date(),
      waitingTime: Math.floor(Math.random() * 15),
      trafficConditions: trafficConditions,
      weatherConditions: weatherConditions,
      routeOptimized: Math.random() > 0.3,
      alternativeRoutes: Math.random() > 0.7 ? [{
        distance: actualDistance + 2,
        duration: actualDuration + 5,
        reason: 'Heavy traffic on main route'
      }] : [],
      maxSpeed: Math.floor(Math.random() * 40) + 60,
      averageSpeed: Math.floor(Math.random() * 20) + 30,
      harshBraking: Math.floor(Math.random() * 3),
      harshAcceleration: Math.floor(Math.random() * 3),
      fuelConsumed: Math.round((actualDistance / 12) * 100) / 100, // ~12km/L average
      carbonFootprint: Math.round(actualDistance * 0.15 * 100) / 100, // ~0.15kg CO2/km
      efficiency: Math.round((actualDistance / (actualDistance / 12)) * 100) / 100
    };
  }

  // Generate random status history
  generateStatusHistory(status, createdAt) {
    const statusOrder = ['pending', 'confirmed', 'driverAssigned', 'driverEnRoute', 'driverArrived', 'inProgress', 'completed'];
    const currentStatusIndex = statusOrder.indexOf(status);
    const history = [];

    for (let i = 0; i <= currentStatusIndex; i++) {
      const statusTime = new Date(createdAt.getTime() + (i * 15 * 60000)); // 15 minutes between statuses
      history.push({
        status: statusOrder[i],
        timestamp: statusTime,
        notes: this.getStatusNote(statusOrder[i]),
        correlationId: `corr_${Date.now()}_${i}`,
        updatedBy: this.getStatusUpdatedBy(statusOrder[i]),
        location: {
          latitude: -33.9249 + (Math.random() - 0.5) * 0.1,
          longitude: 18.4241 + (Math.random() - 0.5) * 0.1,
          address: 'Location during status update'
        },
        estimatedTimeToNext: i < currentStatusIndex ? 15 : 0,
        reason: this.getStatusReason(statusOrder[i])
      });
    }

    return history;
  }

  // Get status note
  getStatusNote(status) {
    const notes = {
      pending: 'Booking created',
      confirmed: 'Booking confirmed by system',
      driverAssigned: 'Driver assigned to booking',
      driverEnRoute: 'Driver en route to pickup location',
      driverArrived: 'Driver arrived at pickup location',
      inProgress: 'Trip in progress',
      completed: 'Trip completed successfully'
    };
    return notes[status] || 'Status updated';
  }

  // Get status updated by
  getStatusUpdatedBy(status) {
    const updatedBy = {
      pending: 'user',
      confirmed: 'system',
      driverAssigned: 'system',
      driverEnRoute: 'driver',
      driverArrived: 'driver',
      inProgress: 'driver',
      completed: 'driver'
    };
    return updatedBy[status] || 'system';
  }

  // Get status reason
  getStatusReason(status) {
    const reasons = {
      pending: 'Initial booking creation',
      confirmed: 'System confirmation',
      driverAssigned: 'Driver assignment',
      driverEnRoute: 'Driver started trip',
      driverArrived: 'Driver arrived at pickup',
      inProgress: 'Trip started',
      completed: 'Trip completed successfully'
    };
    return reasons[status] || 'Status change';
  }

  // Generate random notification data
  generateNotifications(statusHistory) {
    const notifications = [];
    const notificationTypes = {
      pending: ['booking_confirmed'],
      confirmed: ['booking_confirmed', 'driver_assigned'],
      driverAssigned: ['booking_confirmed', 'driver_assigned', 'driver_en_route'],
      driverEnRoute: ['booking_confirmed', 'driver_assigned', 'driver_en_route', 'driver_arrived'],
      driverArrived: ['booking_confirmed', 'driver_assigned', 'driver_en_route', 'driver_arrived', 'trip_started'],
      inProgress: ['booking_confirmed', 'driver_assigned', 'driver_en_route', 'driver_arrived', 'trip_started', 'trip_completed'],
      completed: ['booking_confirmed', 'driver_assigned', 'driver_en_route', 'driver_arrived', 'trip_started', 'trip_completed', 'payment_confirmed']
    };

    const currentStatus = statusHistory[statusHistory.length - 1]?.status || 'pending';
    const typesToSend = notificationTypes[currentStatus] || [];

    typesToSend.forEach((type, index) => {
      notifications.push({
        type: type,
        sentAt: new Date(Date.now() - (typesToSend.length - index) * 60000),
        status: ['sent', 'delivered', 'read'][Math.floor(Math.random() * 3)],
        recipient: ['user', 'driver'][Math.floor(Math.random() * 2)],
        method: ['push', 'sms', 'email', 'in_app'][Math.floor(Math.random() * 4)],
        content: this.getNotificationContent(type),
        metadata: {
          notificationId: `notif_${Date.now()}_${index}`,
          priority: ['low', 'medium', 'high'][Math.floor(Math.random() * 3)]
        }
      });
    });

    return notifications;
  }

  // Get notification content
  getNotificationContent(type) {
    const contents = {
      booking_confirmed: 'Your booking has been confirmed',
      driver_assigned: 'Driver has been assigned to your booking',
      driver_en_route: 'Your driver is en route to the pickup location',
      driver_arrived: 'Your driver has arrived at the pickup location',
      trip_started: 'Your trip has started',
      trip_completed: 'Your trip has been completed successfully',
      payment_confirmed: 'Payment has been processed successfully',
      booking_cancelled: 'Your booking has been cancelled',
      delay_notification: 'There may be a delay with your booking',
      route_update: 'Route has been updated for your trip'
    };
    return contents[type] || 'Notification sent';
  }

  // Generate random emergency contact
  generateEmergencyContact() {
    const relationships = ['spouse', 'parent', 'sibling', 'friend', 'colleague', 'assistant'];
    const names = ['John Doe', 'Jane Smith', 'Mike Johnson', 'Sarah Wilson', 'David Brown', 'Lisa Davis'];
    
    return {
      name: names[Math.floor(Math.random() * names.length)],
      phone: '+27' + Math.floor(Math.random() * 900000000 + 100000000),
      relationship: relationships[Math.floor(Math.random() * relationships.length)]
    };
  }

  // Generate random device info
  generateDeviceInfo() {
    const platforms = ['ios', 'android', 'web'];
    const versions = ['1.0.0', '1.1.0', '1.2.0', '2.0.0'];
    const userAgents = [
      'SwiftLyft/1.0.0 (iPhone; iOS 15.0)',
      'SwiftLyft/1.1.0 (Android; API 30)',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    ];

    return {
      platform: platforms[Math.floor(Math.random() * platforms.length)],
      version: versions[Math.floor(Math.random() * versions.length)],
      userAgent: userAgents[Math.floor(Math.random() * userAgents.length)],
      ipAddress: `192.168.1.${Math.floor(Math.random() * 255)}`
    };
  }

  // Generate random analytics data
  generateAnalyticsData() {
    const sources = ['organic', 'referral', 'google', 'facebook', 'corporate_portal'];
    const referralCodes = ['REF123', 'REF456', 'REF789', 'REFABC', 'REFXYZ', ''];
    const campaigns = ['airport_promo', 'business_travel', 'corporate_package', 'summer_promo', ''];

    return {
      bookingSource: sources[Math.floor(Math.random() * sources.length)],
      referralCode: referralCodes[Math.floor(Math.random() * referralCodes.length)],
      campaignId: campaigns[Math.floor(Math.random() * campaigns.length)],
      utmSource: ['google', 'facebook', 'twitter', 'corporate', ''][Math.floor(Math.random() * 5)],
      utmMedium: ['search', 'social', 'email', 'portal', ''][Math.floor(Math.random() * 5)],
      utmCampaign: ['airport_transfers', 'business_promotion', 'vip_service', 'summer_campaign', ''][Math.floor(Math.random() * 5)]
    };
  }

  // Create sample booking
  async createSampleBooking() {
    const vehicleTypes = ['sedan', 'suv', 'luxury', 'van', 'truck', 'motorcycle', 'electric', 'hybrid'];
    const serviceTypes = ['standard', 'premium', 'corporate', 'airport', 'security', 'medical', 'event'];
    const statuses = ['pending', 'confirmed', 'driverAssigned', 'driverEnRoute', 'driverArrived', 'inProgress', 'completed', 'cancelled'];
    const paymentMethods = ['cash', 'card', 'wallet', 'corporate', 'crypto'];
    const paymentStatuses = ['pending', 'paid', 'failed', 'refunded', 'partially_refunded', 'disputed'];
    const cities = ['Cape Town', 'Johannesburg', 'Durban'];
    const provinces = ['Western Cape', 'Gauteng', 'KwaZulu-Natal'];

    const vehicleType = vehicleTypes[Math.floor(Math.random() * vehicleTypes.length)];
    const serviceType = serviceTypes[Math.floor(Math.random() * serviceTypes.length)];
    const status = statuses[Math.floor(Math.random() * statuses.length)];
    const paymentMethod = paymentMethods[Math.floor(Math.random() * paymentMethods.length)];
    const paymentStatus = paymentStatuses[Math.floor(Math.random() * paymentStatuses.length)];
    const city = cities[Math.floor(Math.random() * cities.length)];
    const province = provinces[Math.floor(Math.random() * provinces.length)];

    const passengerCount = Math.floor(Math.random() * 4) + 1;
    const luggageCount = Math.floor(Math.random() * 3);
    const distance = Math.floor(Math.random() * 50) + 5; // 5-55km
    const duration = Math.floor(Math.random() * 120) + 20; // 20-140 minutes

    const pickupLocation = this.generateLocationData(city, province);
    const dropoffLocation = this.generateLocationData(city, province);
    const pricing = this.generatePricingData(vehicleType, serviceType, distance);

    const createdAt = new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000); // Random date within last 30 days
    const scheduledDate = new Date(createdAt.getTime() + Math.random() * 7 * 24 * 60 * 60 * 1000); // Within next 7 days

    const statusHistory = this.generateStatusHistory(status, createdAt);
    const notifications = this.generateNotifications(statusHistory);

    const bookingData = {
      bookingId: 'BK' + Date.now().toString(36).slice(-4).toUpperCase(),
      userId: new mongoose.Types.ObjectId(),
      driverId: Math.random() > 0.3 ? new mongoose.Types.ObjectId() : null,
      vehicleId: new mongoose.Types.ObjectId(),
      vehicleName: `${vehicleType.charAt(0).toUpperCase() + vehicleType.slice(1)} Vehicle`,
      driverName: Math.random() > 0.3 ? ['John Driver', 'Jane Driver', 'Mike Driver', 'Sarah Driver'][Math.floor(Math.random() * 4)] : '',
      driverPhone: Math.random() > 0.3 ? '+27' + Math.floor(Math.random() * 900000000 + 100000000) : '',
      driverPhotoUrl: Math.random() > 0.3 ? 'https://example.com/driver-photo.jpg' : '',
      pickupAddress: pickupLocation.address,
      dropoffAddress: dropoffLocation.address,
      pickupLocation: pickupLocation,
      dropoffLocation: dropoffLocation,
      waypoints: Math.random() > 0.8 ? [this.generateLocationData(city, province)] : [],
      vehicleType: vehicleType,
      serviceType: serviceType,
      passengerCount: passengerCount,
      luggageCount: luggageCount,
      pickupTime: scheduledDate,
      actualPickupTime: status === 'completed' ? new Date(scheduledDate.getTime() + Math.random() * 600000) : undefined,
      actualDropoffTime: status === 'completed' ? new Date(scheduledDate.getTime() + duration * 60000) : undefined,
      scheduledDate: scheduledDate,
      isFlexibleTime: Math.random() > 0.7,
      flexibleWindow: Math.floor(Math.random() * 30) + 15,
      basePrice: pricing.baseFare,
      finalPrice: pricing.total,
      pricing: pricing,
      tripDetails: status === 'completed' ? this.generateTripDetails(distance, duration) : null,
      status: status,
      statusHistory: statusHistory,
      assignedAt: statusHistory.find(s => s.status === 'driverAssigned')?.timestamp || undefined,
      driverAcceptedAt: statusHistory.find(s => s.status === 'driverEnRoute')?.timestamp || undefined,
      driverArrivedAt: statusHistory.find(s => s.status === 'driverArrived')?.timestamp || undefined,
      tripStartedAt: statusHistory.find(s => s.status === 'inProgress')?.timestamp || undefined,
      tripCompletedAt: statusHistory.find(s => s.status === 'completed')?.timestamp || undefined,
      specialNotes: Math.random() > 0.7 ? ['Please arrive 5 minutes early', 'Customer prefers quiet ride', 'VIP service required', 'Non-smoking vehicle preferred'][Math.floor(Math.random() * 4)] : '',
      closeProtectionOfficer: Math.random() > 0.9,
      internalNotes: Math.random() > 0.8 ? 'Internal notes for this booking' : '',
      customerNotes: Math.random() > 0.7 ? 'Customer notes visible to driver' : '',
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      paymentMethodId: paymentStatus === 'paid' ? 'pm_' + Math.random().toString(36).substring(2, 8) : undefined,
      paymentId: paymentStatus === 'paid' ? 'pi_' + Math.random().toString(36).substring(2, 8) : undefined,
      paidAt: paymentStatus === 'paid' ? new Date(createdAt.getTime() + Math.random() * 24 * 60 * 60 * 1000) : undefined,
      refundedAt: paymentStatus === 'refunded' ? new Date(createdAt.getTime() + Math.random() * 48 * 60 * 60 * 1000) : undefined,
      refundAmount: paymentStatus === 'refunded' ? Math.round(pricing.total * 0.8) : undefined,
      refundReason: paymentStatus === 'refunded' ? 'Customer cancellation' : '',
      rating: status === 'completed' && Math.random() > 0.3 ? Math.floor(Math.random() * 5) + 1 : null,
      review: status === 'completed' && Math.random() > 0.4 ? ['Excellent service!', 'Good trip overall', 'Professional driver', 'Comfortable ride', 'Will use again'][Math.floor(Math.random() * 5)] : '',
      driverRating: status === 'completed' && Math.random() > 0.3 ? {
        rating: Math.floor(Math.random() * 5) + 1,
        review: ['Excellent service!', 'Good trip overall', 'Professional driver', 'Comfortable ride'][Math.floor(Math.random() * 4)],
        categories: {
          cleanliness: Math.floor(Math.random() * 5) + 1,
          punctuality: Math.floor(Math.random() * 5) + 1,
          friendliness: Math.floor(Math.random() * 5) + 1,
          driving: Math.floor(Math.random() * 5) + 1,
          vehicleCondition: Math.floor(Math.random() * 5) + 1,
          communication: Math.floor(Math.random() * 5) + 1
        },
        tags: ['excellent', 'professional', 'safe', 'clean', 'punctual'].slice(0, Math.floor(Math.random() * 3) + 1),
        submittedAt: new Date(createdAt.getTime() + Math.random() * 7 * 24 * 60 * 60 * 1000),
        isAnonymous: Math.random() > 0.8
      } : null,
      userRating: null,
      cancelledAt: status === 'cancelled' ? new Date(createdAt.getTime() + Math.random() * 24 * 60 * 60 * 1000) : undefined,
      cancelledBy: status === 'cancelled' ? ['user', 'driver', 'system', 'admin', 'support'][Math.floor(Math.random() * 5)] : undefined,
      cancellationReason: status === 'cancelled' ? ['Customer cancelled', 'Driver cancelled', 'System cancellation', 'Weather conditions', 'Emergency'][Math.floor(Math.random() * 5)] : '',
      cancellationFee: status === 'cancelled' ? Math.round(pricing.total * 0.2) : 0,
      cancellationPolicy: status === 'cancelled' ? 'Standard cancellation policy' : '',
      isCorporateBooking: Math.random() > 0.8,
      corporateAccountId: Math.random() > 0.8 ? 'corp_' + Math.random().toString(36).substring(2, 8) : '',
      corporateApprovalRequired: Math.random() > 0.9,
      corporateApprovedAt: Math.random() > 0.8 ? new Date(createdAt.getTime() + Math.random() * 60 * 60 * 1000) : undefined,
      corporateApprovedBy: Math.random() > 0.8 ? 'corporate_admin' : '',
      emergency: {
        emergencyContact: this.generateEmergencyContact(),
        safetyCheckCompleted: Math.random() > 0.7,
        safetyCheckTimestamp: Math.random() > 0.7 ? new Date(createdAt.getTime() + Math.random() * 60 * 60 * 1000) : undefined,
        safetyNotes: Math.random() > 0.8 ? 'All safety checks completed' : '',
        incidentReport: {
          hasIncident: Math.random() > 0.95,
          incidentType: Math.random() > 0.95 ? ['minor_accident', 'vehicle_breakdown', 'weather_delay', 'customer_issue'][Math.floor(Math.random() * 4)] : '',
          description: Math.random() > 0.95 ? 'Incident description' : '',
          reportedAt: Math.random() > 0.95 ? new Date(createdAt.getTime() + Math.random() * 24 * 60 * 60 * 1000) : undefined,
          reportedBy: Math.random() > 0.95 ? ['driver', 'customer', 'admin'][Math.floor(Math.random() * 3)] : '',
          severity: Math.random() > 0.95 ? ['low', 'medium', 'high', 'critical'][Math.floor(Math.random() * 4)] : 'low'
        }
      },
      notificationsSent: notifications,
      routeInfo: status === 'completed' ? {
        routeId: 'route_' + Math.random().toString(36).substring(2, 8),
        distance: distance,
        duration: duration,
        trafficLevel: ['light', 'moderate', 'heavy'][Math.floor(Math.random() * 3)]
      } : undefined,
      source: ['app', 'web', 'api', 'admin', 'phone'][Math.floor(Math.random() * 5)],
      deviceInfo: this.generateDeviceInfo(),
      analytics: this.generateAnalyticsData(),
      termsAccepted: true,
      termsAcceptedAt: new Date(createdAt.getTime() - Math.random() * 60 * 60 * 1000),
      privacyPolicyAccepted: true,
      privacyPolicyAcceptedAt: new Date(createdAt.getTime() - Math.random() * 60 * 60 * 1000),
      qualityCheck: {
        completed: Math.random() > 0.6,
        checkedAt: Math.random() > 0.6 ? new Date(createdAt.getTime() + Math.random() * 24 * 60 * 60 * 1000) : undefined,
        checkedBy: Math.random() > 0.6 ? ['system', 'quality_team', 'admin'][Math.floor(Math.random() * 3)] : '',
        score: Math.random() > 0.6 ? Math.floor(Math.random() * 40) + 60 : null,
        notes: Math.random() > 0.8 ? 'Quality check notes' : ''
      }
    };

    return new Booking(bookingData);
  }

  // Seed database with sample data
  async seedDatabase(options = {}) {
    const {
      numBookings = 50,
      clearExisting = false
    } = options;

    try {
      console.log(`🌱 Seeding Bookings database with ${numBookings} bookings...`);

      // Clear existing data if requested
      if (clearExisting) {
        console.log('🗑️ Clearing existing Bookings data...');
        await Booking.deleteMany({});
        console.log('✅ Existing Bookings data cleared');
      }

      // Check if data already exists
      const existingCount = await Booking.countDocuments();
      if (existingCount > 0 && !clearExisting) {
        console.log(`⚠️ Bookings database already contains ${existingCount} bookings`);
        console.log('Use --clear-existing to replace existing data');
        return;
      }

      // Create bookings in batches
      const batchSize = 10;
      const batches = Math.ceil(numBookings / batchSize);

      for (let batch = 0; batch < batches; batch++) {
        const batchBookings = [];
        const currentBatchSize = Math.min(batchSize, numBookings - batch * batchSize);

        for (let i = 0; i < currentBatchSize; i++) {
          const booking = await this.createSampleBooking();
          batchBookings.push(booking);
        }

        // Save batch
        await Booking.insertMany(batchBookings);
        console.log(`✅ Created batch ${batch + 1}/${batches} (${currentBatchSize} bookings)`);
      }

      // Generate summary statistics
      const totalBookings = await Booking.countDocuments();
      const statusStats = await Booking.aggregate([
        { $group: { _id: '$status', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]);

      const vehicleTypeStats = await Booking.aggregate([
        { $group: { _id: '$vehicleType', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]);

      const serviceTypeStats = await Booking.aggregate([
        { $group: { _id: '$serviceType', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]);

      const paymentMethodStats = await Booking.aggregate([
        { $group: { _id: '$paymentMethod', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]);

      console.log('\n📊 Bookings Seeding Summary:');
      console.log(`  Total bookings created: ${totalBookings}`);

      console.log('\n📈 Status Distribution:');
      statusStats.forEach(stat => {
        console.log(`  ${stat._id}: ${stat.count}`);
      });

      console.log('\n🚗 Vehicle Type Distribution:');
      vehicleTypeStats.forEach(stat => {
        console.log(`  ${stat._id}: ${stat.count}`);
      });

      console.log('\n🎯 Service Type Distribution:');
      serviceTypeStats.forEach(stat => {
        console.log(`  ${stat._id}: ${stat.count}`);
      });

      console.log('\n💳 Payment Method Distribution:');
      paymentMethodStats.forEach(stat => {
        console.log(`  ${stat._id}: ${stat.count}`);
      });

      // Calculate total revenue
      const revenueStats = await Booking.aggregate([
        { $match: { status: 'completed' } },
        { $group: { _id: null, totalRevenue: { $sum: '$finalPrice' } } }
      ]);

      if (revenueStats.length > 0) {
        console.log(`\n💰 Total Revenue: R${revenueStats[0].totalRevenue.toLocaleString()}`);
      }

      console.log('🎉 Bookings database seeding completed successfully!');
    } catch (error) {
      console.error('❌ Error seeding Bookings database:', error);
      throw error;
    }
  }

  // Close database connection
  async close() {
    try {
      if (this.connection) {
        await mongoose.connection.close();
        console.log('✅ Bookings database connection closed');
      }
    } catch (error) {
      console.error('❌ Error closing Bookings database connection:', error);
    }
  }
}

// CLI interface
if (require.main === module) {
  const args = process.argv.slice(2);
  const options = {};

  // Parse command line arguments
  const numBookingsIndex = args.indexOf('--num-bookings');
  if (numBookingsIndex !== -1 && args[numBookingsIndex + 1]) {
    options.numBookings = parseInt(args[numBookingsIndex + 1]);
  }

  if (args.includes('--clear-existing')) {
    options.clearExisting = true;
  }

  const seeder = new BookingsDatabaseSeeder();
  
  seeder.connect()
    .then(() => seeder.seedDatabase(options))
    .then(() => {
      console.log('✅ Bookings seeding completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Bookings seeding failed:', error);
      process.exit(1);
    });
}

module.exports = BookingsDatabaseSeeder;
