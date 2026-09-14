import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/notification_item_dto.dart';
import 'package:ruralcare/data/repositories/notification_repository.dart';

class NotificationItemCard extends StatelessWidget {
  final NotificationItemDto notification;
  final VoidCallback? onActionTap;

  const NotificationItemCard({
    super.key,
    required this.notification,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final (bgIconColor, iconColor, catBgColor, catTextColor, iconData) = _getCategoryStyles();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: RuralCareColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: notification.isUrgent
              ? const Color(0xFFB91C1C).withOpacity(0.3)
              : (notification.isRead ? RuralCareColors.border : const Color(0xFF0A6B56).withOpacity(0.2)),
          width: notification.isUrgent || !notification.isRead ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bgIconColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),

              // Title and Category Chip
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: catBgColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            notification.category.label,
                            style: TextStyle(
                              color: catTextColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(notification.timestamp),
                          style: AppTypography.supporting.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.title,
                      style: AppTypography.cardTitle.copyWith(fontSize: 14),
                    ),
                    if (notification.bilingualTitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        notification.bilingualTitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0A6B56),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Unread Dot
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4, left: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0284C7),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Message Body
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Text(
              notification.message,
              style: AppTypography.supporting.copyWith(fontSize: 13, height: 1.3),
            ),
          ),

          // Action Button
          if (notification.actionLabel != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 32,
                child: ElevatedButton.icon(
                  onPressed: () {
                    NotificationRepository().markAsRead(notification.id);
                    onActionTap?.call();
                  },
                  icon: const Icon(Icons.arrow_forward, size: 14),
                  label: Text(notification.actionLabel!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: notification.isUrgent ? const Color(0xFFB91C1C) : const Color(0xFF0A6B56),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  (Color, Color, Color, Color, IconData) _getCategoryStyles() {
    switch (notification.category) {
      case NotificationCategory.alerts:
        return (
          const Color(0xFFFEE2E2),
          const Color(0xFFB91C1C),
          const Color(0xFFFEE2E2),
          const Color(0xFFB91C1C),
          Icons.verified_user_outlined,
        );
      case NotificationCategory.reminders:
        return (
          const Color(0xFFE0F2FE),
          const Color(0xFF0284C7),
          const Color(0xFFE0F2FE),
          const Color(0xFF0284C7),
          Icons.calendar_today_outlined,
        );
      case NotificationCategory.reports:
        return (
          const Color(0xFFDCFCE7),
          const Color(0xFF15803D),
          const Color(0xFFDCFCE7),
          const Color(0xFF15803D),
          Icons.biotech_outlined,
        );
      case NotificationCategory.referrals:
        return (
          const Color(0xFFE8F5F2),
          const Color(0xFF0A6B56),
          const Color(0xFFE8F5F2),
          const Color(0xFF0A6B56),
          Icons.sync_alt_outlined,
        );
      case NotificationCategory.verification:
        return (
          const Color(0xFFFEF3C7),
          const Color(0xFFB45309),
          const Color(0xFFFEF3C7),
          const Color(0xFFB45309),
          Icons.badge_outlined,
        );
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
