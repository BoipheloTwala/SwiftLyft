/// Notification model
class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? expiresAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.expiresAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] ?? {},
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? expiresAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

/// Notification preferences model
class NotificationPreferences {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final Map<String, bool> categories;
  final String frequency;
  final List<String> quietHours;
  final DateTime updatedAt;

  NotificationPreferences({
    required this.pushEnabled,
    required this.emailEnabled,
    required this.smsEnabled,
    required this.categories,
    required this.frequency,
    required this.quietHours,
    required this.updatedAt,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      pushEnabled: json['pushEnabled'] ?? true,
      emailEnabled: json['emailEnabled'] ?? true,
      smsEnabled: json['smsEnabled'] ?? false,
      categories: Map<String, bool>.from(json['categories'] ?? {}),
      frequency: json['frequency'] ?? 'immediate',
      quietHours: List<String>.from(json['quietHours'] ?? []),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushEnabled': pushEnabled,
      'emailEnabled': emailEnabled,
      'smsEnabled': smsEnabled,
      'categories': categories,
      'frequency': frequency,
      'quietHours': quietHours,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Notification statistics model
class NotificationStats {
  final int totalSent;
  final int totalRead;
  final double readRate;
  final Map<String, int> byType;
  final Map<String, int> byPlatform;
  final Map<String, int> byTimeRange;
  final DateTime lastUpdated;

  NotificationStats({
    required this.totalSent,
    required this.totalRead,
    required this.readRate,
    required this.byType,
    required this.byPlatform,
    required this.byTimeRange,
    required this.lastUpdated,
  });

  factory NotificationStats.fromJson(Map<String, dynamic> json) {
    return NotificationStats(
      totalSent: json['totalSent'] ?? 0,
      totalRead: json['totalRead'] ?? 0,
      readRate: (json['readRate'] ?? 0.0).toDouble(),
      byType: Map<String, int>.from(json['byType'] ?? {}),
      byPlatform: Map<String, int>.from(json['byPlatform'] ?? {}),
      byTimeRange: Map<String, int>.from(json['byTimeRange'] ?? {}),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSent': totalSent,
      'totalRead': totalRead,
      'readRate': readRate,
      'byType': byType,
      'byPlatform': byPlatform,
      'byTimeRange': byTimeRange,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

/// Notification template model
class NotificationTemplate {
  final String id;
  final String name;
  final String type;
  final String subject;
  final String message;
  final Map<String, dynamic> variables;
  final List<String> channels;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.subject,
    required this.message,
    required this.variables,
    required this.channels,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationTemplate.fromJson(Map<String, dynamic> json) {
    return NotificationTemplate(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      subject: json['subject'] ?? '',
      message: json['message'] ?? '',
      variables: json['variables'] ?? {},
      channels: List<String>.from(json['channels'] ?? []),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'subject': subject,
      'message': message,
      'variables': variables,
      'channels': channels,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
