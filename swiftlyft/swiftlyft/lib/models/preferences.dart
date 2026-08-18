/// User preferences model
class UserPreferences {
  final String userId;
  final NotificationPreferences notifications;
  final PrivacyPreferences privacy;
  final AppPreferences app;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserPreferences({
    required this.userId,
    required this.notifications,
    required this.privacy,
    required this.app,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      userId: json['userId'] ?? '',
      notifications: NotificationPreferences.fromJson(json['notifications'] ?? {}),
      privacy: PrivacyPreferences.fromJson(json['privacy'] ?? {}),
      app: AppPreferences.fromJson(json['app'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'notifications': notifications.toJson(),
      'privacy': privacy.toJson(),
      'app': app.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Notification preferences
class NotificationPreferences {
  final bool emailNotifications;
  final bool pushNotifications;
  final bool smsNotifications;
  final bool bookingUpdates;
  final bool promotionalOffers;
  final bool driverMessages;
  final bool paymentUpdates;
  final bool weeklyReports;

  NotificationPreferences({
    required this.emailNotifications,
    required this.pushNotifications,
    required this.smsNotifications,
    required this.bookingUpdates,
    required this.promotionalOffers,
    required this.driverMessages,
    required this.paymentUpdates,
    required this.weeklyReports,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      emailNotifications: json['emailNotifications'] ?? true,
      pushNotifications: json['pushNotifications'] ?? true,
      smsNotifications: json['smsNotifications'] ?? false,
      bookingUpdates: json['bookingUpdates'] ?? true,
      promotionalOffers: json['promotionalOffers'] ?? true,
      driverMessages: json['driverMessages'] ?? true,
      paymentUpdates: json['paymentUpdates'] ?? true,
      weeklyReports: json['weeklyReports'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'smsNotifications': smsNotifications,
      'bookingUpdates': bookingUpdates,
      'promotionalOffers': promotionalOffers,
      'driverMessages': driverMessages,
      'paymentUpdates': paymentUpdates,
      'weeklyReports': weeklyReports,
    };
  }
}

/// Privacy preferences
class PrivacyPreferences {
  final bool profileVisible;
  final bool showPhoneNumber;
  final bool showEmail;
  final bool allowDataCollection;
  final bool shareLocation;
  final bool allowMarketing;

  PrivacyPreferences({
    required this.profileVisible,
    required this.showPhoneNumber,
    required this.showEmail,
    required this.allowDataCollection,
    required this.shareLocation,
    required this.allowMarketing,
  });

  factory PrivacyPreferences.fromJson(Map<String, dynamic> json) {
    return PrivacyPreferences(
      profileVisible: json['profileVisible'] ?? true,
      showPhoneNumber: json['showPhoneNumber'] ?? false,
      showEmail: json['showEmail'] ?? false,
      allowDataCollection: json['allowDataCollection'] ?? true,
      shareLocation: json['shareLocation'] ?? true,
      allowMarketing: json['allowMarketing'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profileVisible': profileVisible,
      'showPhoneNumber': showPhoneNumber,
      'showEmail': showEmail,
      'allowDataCollection': allowDataCollection,
      'shareLocation': shareLocation,
      'allowMarketing': allowMarketing,
    };
  }
}

/// App preferences
class AppPreferences {
  final String language;
  final String currency;
  final String theme;
  final String dateFormat;
  final String timeFormat;
  final bool autoUpdate;
  final bool offlineMode;

  AppPreferences({
    required this.language,
    required this.currency,
    required this.theme,
    required this.dateFormat,
    required this.timeFormat,
    required this.autoUpdate,
    required this.offlineMode,
  });

  factory AppPreferences.fromJson(Map<String, dynamic> json) {
    return AppPreferences(
      language: json['language'] ?? 'en',
      currency: json['currency'] ?? 'ZAR',
      theme: json['theme'] ?? 'system',
      dateFormat: json['dateFormat'] ?? 'DD/MM/YYYY',
      timeFormat: json['timeFormat'] ?? '24h',
      autoUpdate: json['autoUpdate'] ?? true,
      offlineMode: json['offlineMode'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'currency': currency,
      'theme': theme,
      'dateFormat': dateFormat,
      'timeFormat': timeFormat,
      'autoUpdate': autoUpdate,
      'offlineMode': offlineMode,
    };
  }
}
