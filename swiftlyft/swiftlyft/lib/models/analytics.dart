/// Analytics dashboard model
class AnalyticsDashboard {
  final int totalUsers;
  final int activeUsers;
  final int totalBookings;
  final int completedBookings;
  final double totalRevenue;
  final double averageBookingValue;
  final Map<String, int> bookingsByStatus;
  final Map<String, double> revenueByMonth;
  final Map<String, int> usersByTier;
  final Map<String, int> topVehicles;
  final List<AnalyticsTrend> trends;
  final DateTime lastUpdated;

  AnalyticsDashboard({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalBookings,
    required this.completedBookings,
    required this.totalRevenue,
    required this.averageBookingValue,
    required this.bookingsByStatus,
    required this.revenueByMonth,
    required this.usersByTier,
    required this.topVehicles,
    required this.trends,
    required this.lastUpdated,
  });

  factory AnalyticsDashboard.fromJson(Map<String, dynamic> json) {
    return AnalyticsDashboard(
      totalUsers: json['totalUsers'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      totalBookings: json['totalBookings'] ?? 0,
      completedBookings: json['completedBookings'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0.0).toDouble(),
      averageBookingValue: (json['averageBookingValue'] ?? 0.0).toDouble(),
      bookingsByStatus: Map<String, int>.from(json['bookingsByStatus'] ?? {}),
      revenueByMonth: Map<String, double>.from(json['revenueByMonth'] ?? {}),
      usersByTier: Map<String, int>.from(json['usersByTier'] ?? {}),
      topVehicles: Map<String, int>.from(json['topVehicles'] ?? {}),
      trends: (json['trends'] as List<dynamic>?)
          ?.map((trend) => AnalyticsTrend.fromJson(trend))
          .toList() ?? [],
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'totalBookings': totalBookings,
      'completedBookings': completedBookings,
      'totalRevenue': totalRevenue,
      'averageBookingValue': averageBookingValue,
      'bookingsByStatus': bookingsByStatus,
      'revenueByMonth': revenueByMonth,
      'usersByTier': usersByTier,
      'topVehicles': topVehicles,
      'trends': trends.map((trend) => trend.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

/// Analytics trend model
class AnalyticsTrend {
  final String metric;
  final String period;
  final double currentValue;
  final double previousValue;
  final double change;
  final double changePercent;
  final String direction;

  AnalyticsTrend({
    required this.metric,
    required this.period,
    required this.currentValue,
    required this.previousValue,
    required this.change,
    required this.changePercent,
    required this.direction,
  });

  factory AnalyticsTrend.fromJson(Map<String, dynamic> json) {
    return AnalyticsTrend(
      metric: json['metric'] ?? '',
      period: json['period'] ?? '',
      currentValue: (json['currentValue'] ?? 0.0).toDouble(),
      previousValue: (json['previousValue'] ?? 0.0).toDouble(),
      change: (json['change'] ?? 0.0).toDouble(),
      changePercent: (json['changePercent'] ?? 0.0).toDouble(),
      direction: json['direction'] ?? 'stable',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metric': metric,
      'period': period,
      'currentValue': currentValue,
      'previousValue': previousValue,
      'change': change,
      'changePercent': changePercent,
      'direction': direction,
    };
  }
}

/// User analytics model
class UserAnalytics {
  final String userId;
  final int totalBookings;
  final double totalSpent;
  final double averageRating;
  final Map<String, int> bookingsByMonth;
  final Map<String, double> spendingByCategory;
  final List<String> preferredVehicles;
  final List<String> preferredLocations;
  final Map<String, int> activityByHour;
  final Map<String, int> activityByDay;
  final DateTime lastActivity;
  final DateTime firstBooking;

  UserAnalytics({
    required this.userId,
    required this.totalBookings,
    required this.totalSpent,
    required this.averageRating,
    required this.bookingsByMonth,
    required this.spendingByCategory,
    required this.preferredVehicles,
    required this.preferredLocations,
    required this.activityByHour,
    required this.activityByDay,
    required this.lastActivity,
    required this.firstBooking,
  });

  factory UserAnalytics.fromJson(Map<String, dynamic> json) {
    return UserAnalytics(
      userId: json['userId'] ?? '',
      totalBookings: json['totalBookings'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0.0).toDouble(),
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      bookingsByMonth: Map<String, int>.from(json['bookingsByMonth'] ?? {}),
      spendingByCategory: Map<String, double>.from(json['spendingByCategory'] ?? {}),
      preferredVehicles: List<String>.from(json['preferredVehicles'] ?? []),
      preferredLocations: List<String>.from(json['preferredLocations'] ?? []),
      activityByHour: Map<String, int>.from(json['activityByHour'] ?? {}),
      activityByDay: Map<String, int>.from(json['activityByDay'] ?? {}),
      lastActivity: DateTime.parse(json['lastActivity'] ?? DateTime.now().toIso8601String()),
      firstBooking: DateTime.parse(json['firstBooking'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalBookings': totalBookings,
      'totalSpent': totalSpent,
      'averageRating': averageRating,
      'bookingsByMonth': bookingsByMonth,
      'spendingByCategory': spendingByCategory,
      'preferredVehicles': preferredVehicles,
      'preferredLocations': preferredLocations,
      'activityByHour': activityByHour,
      'activityByDay': activityByDay,
      'lastActivity': lastActivity.toIso8601String(),
      'firstBooking': firstBooking.toIso8601String(),
    };
  }
}

/// Booking analytics model
class BookingAnalytics {
  final int totalBookings;
  final int completedBookings;
  final int cancelledBookings;
  final double totalRevenue;
  final double averageBookingValue;
  final Map<String, int> bookingsByStatus;
  final Map<String, int> bookingsByVehicleType;
  final Map<String, int> bookingsByHour;
  final Map<String, int> bookingsByDayOfWeek;
  final Map<String, double> revenueByVehicleType;
  final Map<String, int> cancellationReasons;
  final List<BookingPeakTime> peakTimes;
  final DateTime lastUpdated;

  BookingAnalytics({
    required this.totalBookings,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.totalRevenue,
    required this.averageBookingValue,
    required this.bookingsByStatus,
    required this.bookingsByVehicleType,
    required this.bookingsByHour,
    required this.bookingsByDayOfWeek,
    required this.revenueByVehicleType,
    required this.cancellationReasons,
    required this.peakTimes,
    required this.lastUpdated,
  });

  factory BookingAnalytics.fromJson(Map<String, dynamic> json) {
    return BookingAnalytics(
      totalBookings: json['totalBookings'] ?? 0,
      completedBookings: json['completedBookings'] ?? 0,
      cancelledBookings: json['cancelledBookings'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0.0).toDouble(),
      averageBookingValue: (json['averageBookingValue'] ?? 0.0).toDouble(),
      bookingsByStatus: Map<String, int>.from(json['bookingsByStatus'] ?? {}),
      bookingsByVehicleType: Map<String, int>.from(json['bookingsByVehicleType'] ?? {}),
      bookingsByHour: Map<String, int>.from(json['bookingsByHour'] ?? {}),
      bookingsByDayOfWeek: Map<String, int>.from(json['bookingsByDayOfWeek'] ?? {}),
      revenueByVehicleType: Map<String, double>.from(json['revenueByVehicleType'] ?? {}),
      cancellationReasons: Map<String, int>.from(json['cancellationReasons'] ?? {}),
      peakTimes: (json['peakTimes'] as List<dynamic>?)
          ?.map((time) => BookingPeakTime.fromJson(time))
          .toList() ?? [],
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalBookings': totalBookings,
      'completedBookings': completedBookings,
      'cancelledBookings': cancelledBookings,
      'totalRevenue': totalRevenue,
      'averageBookingValue': averageBookingValue,
      'bookingsByStatus': bookingsByStatus,
      'bookingsByVehicleType': bookingsByVehicleType,
      'bookingsByHour': bookingsByHour,
      'bookingsByDayOfWeek': bookingsByDayOfWeek,
      'revenueByVehicleType': revenueByVehicleType,
      'cancellationReasons': cancellationReasons,
      'peakTimes': peakTimes.map((time) => time.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

/// Booking peak time model
class BookingPeakTime {
  final String dayOfWeek;
  final int hour;
  final int bookingCount;
  final double averageValue;

  BookingPeakTime({
    required this.dayOfWeek,
    required this.hour,
    required this.bookingCount,
    required this.averageValue,
  });

  factory BookingPeakTime.fromJson(Map<String, dynamic> json) {
    return BookingPeakTime(
      dayOfWeek: json['dayOfWeek'] ?? '',
      hour: json['hour'] ?? 0,
      bookingCount: json['bookingCount'] ?? 0,
      averageValue: (json['averageValue'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': dayOfWeek,
      'hour': hour,
      'bookingCount': bookingCount,
      'averageValue': averageValue,
    };
  }
}

/// Revenue analytics model
class RevenueAnalytics {
  final double totalRevenue;
  final double monthlyRecurringRevenue;
  final double averageRevenuePerUser;
  final Map<String, double> revenueByMonth;
  final Map<String, double> revenueByServiceType;
  final Map<String, double> revenueByPaymentMethod;
  final List<RevenueTrend> trends;
  final Map<String, double> commissionByDriver;
  final double totalCommissions;
  final double netRevenue;
  final DateTime lastUpdated;

  RevenueAnalytics({
    required this.totalRevenue,
    required this.monthlyRecurringRevenue,
    required this.averageRevenuePerUser,
    required this.revenueByMonth,
    required this.revenueByServiceType,
    required this.revenueByPaymentMethod,
    required this.trends,
    required this.commissionByDriver,
    required this.totalCommissions,
    required this.netRevenue,
    required this.lastUpdated,
  });

  factory RevenueAnalytics.fromJson(Map<String, dynamic> json) {
    return RevenueAnalytics(
      totalRevenue: (json['totalRevenue'] ?? 0.0).toDouble(),
      monthlyRecurringRevenue: (json['monthlyRecurringRevenue'] ?? 0.0).toDouble(),
      averageRevenuePerUser: (json['averageRevenuePerUser'] ?? 0.0).toDouble(),
      revenueByMonth: Map<String, double>.from(json['revenueByMonth'] ?? {}),
      revenueByServiceType: Map<String, double>.from(json['revenueByServiceType'] ?? {}),
      revenueByPaymentMethod: Map<String, double>.from(json['revenueByPaymentMethod'] ?? {}),
      trends: (json['trends'] as List<dynamic>?)
          ?.map((trend) => RevenueTrend.fromJson(trend))
          .toList() ?? [],
      commissionByDriver: Map<String, double>.from(json['commissionByDriver'] ?? {}),
      totalCommissions: (json['totalCommissions'] ?? 0.0).toDouble(),
      netRevenue: (json['netRevenue'] ?? 0.0).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRevenue': totalRevenue,
      'monthlyRecurringRevenue': monthlyRecurringRevenue,
      'averageRevenuePerUser': averageRevenuePerUser,
      'revenueByMonth': revenueByMonth,
      'revenueByServiceType': revenueByServiceType,
      'revenueByPaymentMethod': revenueByPaymentMethod,
      'trends': trends.map((trend) => trend.toJson()).toList(),
      'commissionByDriver': commissionByDriver,
      'totalCommissions': totalCommissions,
      'netRevenue': netRevenue,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

/// Revenue trend model
class RevenueTrend {
  final String period;
  final double revenue;
  final double growth;
  final double growthPercent;

  RevenueTrend({
    required this.period,
    required this.revenue,
    required this.growth,
    required this.growthPercent,
  });

  factory RevenueTrend.fromJson(Map<String, dynamic> json) {
    return RevenueTrend(
      period: json['period'] ?? '',
      revenue: (json['revenue'] ?? 0.0).toDouble(),
      growth: (json['growth'] ?? 0.0).toDouble(),
      growthPercent: (json['growthPercent'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'revenue': revenue,
      'growth': growth,
      'growthPercent': growthPercent,
    };
  }
}

/// Driver analytics model
class DriverAnalytics {
  final int totalDrivers;
  final int activeDrivers;
  final int onlineDrivers;
  final double averageRating;
  final Map<String, int> driversByStatus;
  final Map<String, double> earningsByDriver;
  final Map<String, int> tripsByDriver;
  final List<DriverPerformance> topPerformers;
  final Map<String, int> driverRetention;
  final double averageEarningsPerDriver;
  final DateTime lastUpdated;

  DriverAnalytics({
    required this.totalDrivers,
    required this.activeDrivers,
    required this.onlineDrivers,
    required this.averageRating,
    required this.driversByStatus,
    required this.earningsByDriver,
    required this.tripsByDriver,
    required this.topPerformers,
    required this.driverRetention,
    required this.averageEarningsPerDriver,
    required this.lastUpdated,
  });

  factory DriverAnalytics.fromJson(Map<String, dynamic> json) {
    return DriverAnalytics(
      totalDrivers: json['totalDrivers'] ?? 0,
      activeDrivers: json['activeDrivers'] ?? 0,
      onlineDrivers: json['onlineDrivers'] ?? 0,
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      driversByStatus: Map<String, int>.from(json['driversByStatus'] ?? {}),
      earningsByDriver: Map<String, double>.from(json['earningsByDriver'] ?? {}),
      tripsByDriver: Map<String, int>.from(json['tripsByDriver'] ?? {}),
      topPerformers: (json['topPerformers'] as List<dynamic>?)
          ?.map((performer) => DriverPerformance.fromJson(performer))
          .toList() ?? [],
      driverRetention: Map<String, int>.from(json['driverRetention'] ?? {}),
      averageEarningsPerDriver: (json['averageEarningsPerDriver'] ?? 0.0).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDrivers': totalDrivers,
      'activeDrivers': activeDrivers,
      'onlineDrivers': onlineDrivers,
      'averageRating': averageRating,
      'driversByStatus': driversByStatus,
      'earningsByDriver': earningsByDriver,
      'tripsByDriver': tripsByDriver,
      'topPerformers': topPerformers.map((performer) => performer.toJson()).toList(),
      'driverRetention': driverRetention,
      'averageEarningsPerDriver': averageEarningsPerDriver,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

/// Driver performance model
class DriverPerformance {
  final String driverId;
  final String driverName;
  final double rating;
  final int totalTrips;
  final double totalEarnings;
  final double averageTripValue;
  final double acceptanceRate;
  final double cancellationRate;
  final Duration averageResponseTime;

  DriverPerformance({
    required this.driverId,
    required this.driverName,
    required this.rating,
    required this.totalTrips,
    required this.totalEarnings,
    required this.averageTripValue,
    required this.acceptanceRate,
    required this.cancellationRate,
    required this.averageResponseTime,
  });

  factory DriverPerformance.fromJson(Map<String, dynamic> json) {
    return DriverPerformance(
      driverId: json['driverId'] ?? '',
      driverName: json['driverName'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalTrips: json['totalTrips'] ?? 0,
      totalEarnings: (json['totalEarnings'] ?? 0.0).toDouble(),
      averageTripValue: (json['averageTripValue'] ?? 0.0).toDouble(),
      acceptanceRate: (json['acceptanceRate'] ?? 0.0).toDouble(),
      cancellationRate: (json['cancellationRate'] ?? 0.0).toDouble(),
      averageResponseTime: Duration(seconds: json['averageResponseTime'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'rating': rating,
      'totalTrips': totalTrips,
      'totalEarnings': totalEarnings,
      'averageTripValue': averageTripValue,
      'acceptanceRate': acceptanceRate,
      'cancellationRate': cancellationRate,
      'averageResponseTime': averageResponseTime.inSeconds,
    };
  }
}

/// Custom report model
class CustomReport {
  final String id;
  final String name;
  final String description;
  final List<String> metrics;
  final Map<String, dynamic> filters;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? lastRunAt;
  final String status;
  final String createdBy;

  CustomReport({
    required this.id,
    required this.name,
    required this.description,
    required this.metrics,
    required this.filters,
    required this.data,
    required this.createdAt,
    this.lastRunAt,
    required this.status,
    required this.createdBy,
  });

  factory CustomReport.fromJson(Map<String, dynamic> json) {
    return CustomReport(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      metrics: List<String>.from(json['metrics'] ?? []),
      filters: json['filters'] ?? {},
      data: json['data'] ?? {},
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastRunAt: json['lastRunAt'] != null ? DateTime.parse(json['lastRunAt']) : null,
      status: json['status'] ?? 'active',
      createdBy: json['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'metrics': metrics,
      'filters': filters,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'lastRunAt': lastRunAt?.toIso8601String(),
      'status': status,
      'createdBy': createdBy,
    };
  }
}
