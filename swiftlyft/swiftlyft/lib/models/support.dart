/// Support ticket model
class SupportTicket {
  final String id;
  final String ticketId;
  final String userId;
  final String subject;
  final String category;
  final String description;
  final String priority;
  final String status;
  final String? relatedBookingId;
  final String? relatedQuoteId;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final String? assignedTo;

  SupportTicket({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.subject,
    required this.category,
    required this.description,
    required this.priority,
    required this.status,
    this.relatedBookingId,
    this.relatedQuoteId,
    required this.tags,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.assignedTo,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] ?? '',
      ticketId: json['ticketId'] ?? '',
      userId: json['userId'] ?? '',
      subject: json['subject'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'normal',
      status: json['status'] ?? 'open',
      relatedBookingId: json['relatedBookingId'],
      relatedQuoteId: json['relatedQuoteId'],
      tags: List<String>.from(json['tags'] ?? []),
      metadata: json['metadata'] ?? {},
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
      assignedTo: json['assignedTo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketId': ticketId,
      'userId': userId,
      'subject': subject,
      'category': category,
      'description': description,
      'priority': priority,
      'status': status,
      'relatedBookingId': relatedBookingId,
      'relatedQuoteId': relatedQuoteId,
      'tags': tags,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'assignedTo': assignedTo,
    };
  }
}

/// Support message model
class SupportMessage {
  final String id;
  final String ticketId;
  final String senderId;
  final String senderType; // 'user' or 'agent'
  final String message;
  final List<String> attachments;
  final bool isRead;
  final DateTime sentAt;
  final DateTime? readAt;

  SupportMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderType,
    required this.message,
    required this.attachments,
    required this.isRead,
    required this.sentAt,
    this.readAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id'] ?? '',
      ticketId: json['ticketId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderType: json['senderType'] ?? 'user',
      message: json['message'] ?? '',
      attachments: List<String>.from(json['attachments'] ?? []),
      isRead: json['isRead'] ?? false,
      sentAt: DateTime.parse(json['sentAt'] ?? DateTime.now().toIso8601String()),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketId': ticketId,
      'senderId': senderId,
      'senderType': senderType,
      'message': message,
      'attachments': attachments,
      'isRead': isRead,
      'sentAt': sentAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }
}

/// FAQ category model
class FAQCategory {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int faqCount;
  final bool isActive;
  final int sortOrder;

  FAQCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.faqCount,
    required this.isActive,
    required this.sortOrder,
  });

  factory FAQCategory.fromJson(Map<String, dynamic> json) {
    return FAQCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      faqCount: json['faqCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      sortOrder: json['sortOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'faqCount': faqCount,
      'isActive': isActive,
      'sortOrder': sortOrder,
    };
  }
}

/// FAQ model
class FAQ {
  final String id;
  final String question;
  final String answer;
  final String categoryId;
  final String categoryName;
  final List<String> tags;
  final int viewCount;
  final int helpfulCount;
  final int notHelpfulCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  FAQ({
    required this.id,
    required this.question,
    required this.answer,
    required this.categoryId,
    required this.categoryName,
    required this.tags,
    required this.viewCount,
    required this.helpfulCount,
    required this.notHelpfulCount,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FAQ.fromJson(Map<String, dynamic> json) {
    return FAQ(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      viewCount: json['viewCount'] ?? 0,
      helpfulCount: json['helpfulCount'] ?? 0,
      notHelpfulCount: json['notHelpfulCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'tags': tags,
      'viewCount': viewCount,
      'helpfulCount': helpfulCount,
      'notHelpfulCount': notHelpfulCount,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Support statistics model
class SupportStats {
  final int totalTickets;
  final int openTickets;
  final int resolvedTickets;
  final int pendingTickets;
  final double averageResolutionTime;
  final Map<String, int> ticketsByCategory;
  final Map<String, int> ticketsByPriority;
  final Map<String, double> satisfactionByCategory;
  final DateTime lastUpdated;

  SupportStats({
    required this.totalTickets,
    required this.openTickets,
    required this.resolvedTickets,
    required this.pendingTickets,
    required this.averageResolutionTime,
    required this.ticketsByCategory,
    required this.ticketsByPriority,
    required this.satisfactionByCategory,
    required this.lastUpdated,
  });

  factory SupportStats.fromJson(Map<String, dynamic> json) {
    return SupportStats(
      totalTickets: json['totalTickets'] ?? 0,
      openTickets: json['openTickets'] ?? 0,
      resolvedTickets: json['resolvedTickets'] ?? 0,
      pendingTickets: json['pendingTickets'] ?? 0,
      averageResolutionTime: (json['averageResolutionTime'] ?? 0.0).toDouble(),
      ticketsByCategory: Map<String, int>.from(json['ticketsByCategory'] ?? {}),
      ticketsByPriority: Map<String, int>.from(json['ticketsByPriority'] ?? {}),
      satisfactionByCategory: Map<String, double>.from(json['satisfactionByCategory'] ?? {}),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTickets': totalTickets,
      'openTickets': openTickets,
      'resolvedTickets': resolvedTickets,
      'pendingTickets': pendingTickets,
      'averageResolutionTime': averageResolutionTime,
      'ticketsByCategory': ticketsByCategory,
      'ticketsByPriority': ticketsByPriority,
      'satisfactionByCategory': satisfactionByCategory,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

/// Callback request model
class CallbackRequest {
  final String id;
  final String phoneNumber;
  final String preferredTime;
  final String? issue;
  final String? ticketId;
  final String status;
  final DateTime requestedAt;
  final DateTime? scheduledAt;
  final DateTime? completedAt;

  CallbackRequest({
    required this.id,
    required this.phoneNumber,
    required this.preferredTime,
    this.issue,
    this.ticketId,
    required this.status,
    required this.requestedAt,
    this.scheduledAt,
    this.completedAt,
  });

  factory CallbackRequest.fromJson(Map<String, dynamic> json) {
    return CallbackRequest(
      id: json['id'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      preferredTime: json['preferredTime'] ?? '',
      issue: json['issue'],
      ticketId: json['ticketId'],
      status: json['status'] ?? 'pending',
      requestedAt: DateTime.parse(json['requestedAt'] ?? DateTime.now().toIso8601String()),
      scheduledAt: json['scheduledAt'] != null ? DateTime.parse(json['scheduledAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'preferredTime': preferredTime,
      'issue': issue,
      'ticketId': ticketId,
      'status': status,
      'requestedAt': requestedAt.toIso8601String(),
      'scheduledAt': scheduledAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}

/// Live chat availability model
class LiveChatAvailability {
  final bool isAvailable;
  final int waitTime;
  final List<String> availableAgents;
  final String? message;
  final Map<String, dynamic> operatingHours;

  LiveChatAvailability({
    required this.isAvailable,
    required this.waitTime,
    required this.availableAgents,
    this.message,
    required this.operatingHours,
  });

  factory LiveChatAvailability.fromJson(Map<String, dynamic> json) {
    return LiveChatAvailability(
      isAvailable: json['isAvailable'] ?? false,
      waitTime: json['waitTime'] ?? 0,
      availableAgents: List<String>.from(json['availableAgents'] ?? []),
      message: json['message'],
      operatingHours: json['operatingHours'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isAvailable': isAvailable,
      'waitTime': waitTime,
      'availableAgents': availableAgents,
      'message': message,
      'operatingHours': operatingHours,
    };
  }
}

/// Live chat session model
class LiveChatSession {
  final String id;
  final String userId;
  final String? initialMessage;
  final String? relatedTicketId;
  final String status;
  final String? assignedAgentId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final Duration? duration;

  LiveChatSession({
    required this.id,
    required this.userId,
    this.initialMessage,
    this.relatedTicketId,
    required this.status,
    this.assignedAgentId,
    required this.startedAt,
    this.endedAt,
    this.duration,
  });

  factory LiveChatSession.fromJson(Map<String, dynamic> json) {
    return LiveChatSession(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      initialMessage: json['initialMessage'],
      relatedTicketId: json['relatedTicketId'],
      status: json['status'] ?? 'active',
      assignedAgentId: json['assignedAgentId'],
      startedAt: DateTime.parse(json['startedAt'] ?? DateTime.now().toIso8601String()),
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
      duration: json['duration'] != null ? Duration(seconds: json['duration']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'initialMessage': initialMessage,
      'relatedTicketId': relatedTicketId,
      'status': status,
      'assignedAgentId': assignedAgentId,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'duration': duration?.inSeconds,
    };
  }
}

/// Live chat message model
class LiveChatMessage {
  final String id;
  final String sessionId;
  final String senderId;
  final String senderType;
  final String message;
  final List<String> attachments;
  final DateTime sentAt;
  final bool isRead;

  LiveChatMessage({
    required this.id,
    required this.sessionId,
    required this.senderId,
    required this.senderType,
    required this.message,
    required this.attachments,
    required this.sentAt,
    required this.isRead,
  });

  factory LiveChatMessage.fromJson(Map<String, dynamic> json) {
    return LiveChatMessage(
      id: json['id'] ?? '',
      sessionId: json['sessionId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderType: json['senderType'] ?? 'user',
      message: json['message'] ?? '',
      attachments: List<String>.from(json['attachments'] ?? []),
      sentAt: DateTime.parse(json['sentAt'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'senderId': senderId,
      'senderType': senderType,
      'message': message,
      'attachments': attachments,
      'sentAt': sentAt.toIso8601String(),
      'isRead': isRead,
    };
  }
}

/// System status model
class SystemStatus {
  final String status;
  final String message;
  final Map<String, bool> services;
  final DateTime lastChecked;
  final DateTime? maintenanceStart;
  final DateTime? maintenanceEnd;

  SystemStatus({
    required this.status,
    required this.message,
    required this.services,
    required this.lastChecked,
    this.maintenanceStart,
    this.maintenanceEnd,
  });

  factory SystemStatus.fromJson(Map<String, dynamic> json) {
    return SystemStatus(
      status: json['status'] ?? 'operational',
      message: json['message'] ?? '',
      services: Map<String, bool>.from(json['services'] ?? {}),
      lastChecked: DateTime.parse(json['lastChecked'] ?? DateTime.now().toIso8601String()),
      maintenanceStart: json['maintenanceStart'] != null ? DateTime.parse(json['maintenanceStart']) : null,
      maintenanceEnd: json['maintenanceEnd'] != null ? DateTime.parse(json['maintenanceEnd']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'services': services,
      'lastChecked': lastChecked.toIso8601String(),
      'maintenanceStart': maintenanceStart?.toIso8601String(),
      'maintenanceEnd': maintenanceEnd?.toIso8601String(),
    };
  }
}
