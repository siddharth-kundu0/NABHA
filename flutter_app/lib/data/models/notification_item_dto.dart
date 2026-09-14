import 'package:ruralcare/app/routes.dart';

enum NotificationCategory {
  alerts,
  reminders,
  reports,
  referrals,
  verification;

  String get label {
    switch (this) {
      case NotificationCategory.alerts:
        return 'Alerts';
      case NotificationCategory.reminders:
        return 'Reminders';
      case NotificationCategory.reports:
        return 'Reports';
      case NotificationCategory.referrals:
        return 'Referrals';
      case NotificationCategory.verification:
        return 'Staff & Approvals';
    }
  }

  String get labelHi {
    switch (this) {
      case NotificationCategory.alerts:
        return 'आपातकालीन सूचना';
      case NotificationCategory.reminders:
        return 'याद दिलाना';
      case NotificationCategory.reports:
        return 'जांच रिपोर्ट';
      case NotificationCategory.referrals:
        return 'रेफरल अपडेट';
      case NotificationCategory.verification:
        return 'सत्यापन';
    }
  }

  String get labelMr {
    switch (this) {
      case NotificationCategory.alerts:
        return 'तातडीची सूचना';
      case NotificationCategory.reminders:
        return 'आठवण';
      case NotificationCategory.reports:
        return 'तपासणी अहवाल';
      case NotificationCategory.referrals:
        return 'रेफरल अद्यतन';
      case NotificationCategory.verification:
        return 'पडताळणी';
    }
  }
}

class NotificationItemDto {
  final String id;
  final AppRole targetRole;
  final String title;
  final String bilingualTitle;
  final String message;
  final NotificationCategory category;
  final DateTime timestamp;
  final bool isRead;
  final bool isUrgent;
  final String? actionLabel;
  final String? actionRoute;
  final Map<String, dynamic>? actionPayload;

  const NotificationItemDto({
    required this.id,
    required this.targetRole,
    required this.title,
    required this.bilingualTitle,
    required this.message,
    required this.category,
    required this.timestamp,
    this.isRead = false,
    this.isUrgent = false,
    this.actionLabel,
    this.actionRoute,
    this.actionPayload,
  });

  NotificationItemDto copyWith({
    String? id,
    AppRole? targetRole,
    String? title,
    String? bilingualTitle,
    String? message,
    NotificationCategory? category,
    DateTime? timestamp,
    bool? isRead,
    bool? isUrgent,
    String? actionLabel,
    String? actionRoute,
    Map<String, dynamic>? actionPayload,
  }) {
    return NotificationItemDto(
      id: id ?? this.id,
      targetRole: targetRole ?? this.targetRole,
      title: title ?? this.title,
      bilingualTitle: bilingualTitle ?? this.bilingualTitle,
      message: message ?? this.message,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isUrgent: isUrgent ?? this.isUrgent,
      actionLabel: actionLabel ?? this.actionLabel,
      actionRoute: actionRoute ?? this.actionRoute,
      actionPayload: actionPayload ?? this.actionPayload,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'targetRole': targetRole.name,
        'title': title,
        'bilingualTitle': bilingualTitle,
        'message': message,
        'category': category.name,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
        'isUrgent': isUrgent,
        'actionLabel': actionLabel,
        'actionRoute': actionRoute,
        'actionPayload': actionPayload,
      };

  factory NotificationItemDto.fromJson(Map<String, dynamic> json) => NotificationItemDto(
        id: json['id'] as String? ?? '',
        targetRole: AppRole.values.firstWhere(
          (e) => e.name == (json['targetRole'] as String? ?? 'patient'),
          orElse: () => AppRole.patient,
        ),
        title: json['title'] as String? ?? '',
        bilingualTitle: json['bilingualTitle'] as String? ?? '',
        message: json['message'] as String? ?? '',
        category: NotificationCategory.values.firstWhere(
          (e) => e.name == (json['category'] as String? ?? 'reminders'),
          orElse: () => NotificationCategory.reminders,
        ),
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : DateTime.now(),
        isRead: json['isRead'] as bool? ?? false,
        isUrgent: json['isUrgent'] as bool? ?? false,
        actionLabel: json['actionLabel'] as String?,
        actionRoute: json['actionRoute'] as String?,
        actionPayload: json['actionPayload'] as Map<String, dynamic>?,
      );
}
