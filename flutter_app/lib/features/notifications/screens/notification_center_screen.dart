import 'package:flutter/material.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/notification_item_dto.dart';
import 'package:ruralcare/data/repositories/notification_repository.dart';
import 'package:ruralcare/features/notifications/widgets/notification_item_card.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  String _activeFilter = 'all';

  void _handleNotificationAction(NotificationItemDto item) {
    if (item.actionRoute != null) {
      Navigator.of(context).pop(); // Dismiss notifications center back to dashboard
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigating to: ${item.actionLabel ?? item.title}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionCoordinator();
    final notifRepo = NotificationRepository();

    return ListenableBuilder(
      listenable: notifRepo,
      builder: (context, _) {
        final role = session.activeRole;
        final unreadCount = notifRepo.getUnreadCount(role);
        final filteredItems = notifRepo.getFilteredNotifications(
          role: role,
          categoryFilter: _activeFilter,
        );

        final urgentItems = filteredItems.where((n) => n.isUrgent).toList();
        final todayItems = filteredItems.where((n) => !n.isUrgent && DateTime.now().difference(n.timestamp).inHours < 24).toList();
        final earlierItems = filteredItems.where((n) => !n.isUrgent && DateTime.now().difference(n.timestamp).inHours >= 24).toList();

        return Scaffold(
          backgroundColor: RuralCareColors.canvas,
          appBar: _buildHeader(context, session),
          body: SafeArea(
            child: Column(
              children: [
                // Top Global Bar: Title + Unread Count + Mark Read
                Container(
                  color: RuralCareColors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                session.isHindi ? 'सूचनाएं' : (session.isMarathi ? 'सूचना' : 'Notifications'),
                                style: AppTypography.pageTitle.copyWith(fontSize: 22),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: unreadCount > 0
                                      ? const Color(0xFF0A6B56)
                                      : RuralCareColors.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$unreadCount New',
                                  style: TextStyle(
                                    color: unreadCount > 0 ? Colors.white : RuralCareColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (unreadCount > 0)
                            TextButton.icon(
                              onPressed: () => notifRepo.markAllAsRead(role),
                              icon: const Icon(Icons.done_all, size: 16, color: Color(0xFF0A6B56)),
                              label: Text(
                                session.isHindi ? 'सभी पढ़ें' : (session.isMarathi ? 'सर्व वाचा' : 'Mark read'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0A6B56),
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        session.isHindi
                            ? 'सूचनाएं एवं महत्वपूर्ण संदेश'
                            : (session.isMarathi ? 'महत्त्वाच्या आरोग्य सूचना व अद्यतने' : 'Health alerts & care coordination updates'),
                        style: const TextStyle(fontSize: 12, color: RuralCareColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                // Horizontal Filter Chips Rail
                Container(
                  color: RuralCareColors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip('all', 'All (${notifRepo.getNotificationsForRole(role).length})'),
                        const SizedBox(width: 8),
                        _filterChip('alerts', 'Alerts (${notifRepo.getFilteredNotifications(role: role, categoryFilter: 'alerts').length})', isAlert: true),
                        const SizedBox(width: 8),
                        _filterChip('reminders', 'Reminders (${notifRepo.getFilteredNotifications(role: role, categoryFilter: 'reminders').length})'),
                        const SizedBox(width: 8),
                        _filterChip('reports', 'Reports (${notifRepo.getFilteredNotifications(role: role, categoryFilter: 'reports').length})'),
                        const SizedBox(width: 8),
                        _filterChip('referrals', 'Referrals (${notifRepo.getFilteredNotifications(role: role, categoryFilter: 'referrals').length})'),
                        if (role == AppRole.facilityStaff) ...[
                          const SizedBox(width: 8),
                          _filterChip('verification', 'Approvals (${notifRepo.getFilteredNotifications(role: role, categoryFilter: 'verification').length})'),
                        ],
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1, color: RuralCareColors.border),

                // Notifications Feed List
                Expanded(
                  child: filteredItems.isEmpty
                      ? _buildEmptyState(session)
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          children: [
                            // 1. Urgent Section
                            if (urgentItems.isNotEmpty) ...[
                              _buildSectionHeader('Urgent / तातडीचे', Icons.bolt, const Color(0xFFC2410C)),
                              const SizedBox(height: 8),
                              ...urgentItems.map((n) => NotificationItemCard(
                                    notification: n,
                                    onActionTap: () => _handleNotificationAction(n),
                                  )),
                              const SizedBox(height: 16),
                            ],

                            // 2. Today Section
                            if (todayItems.isNotEmpty) ...[
                              _buildSectionHeader('Today / आज', Icons.today, const Color(0xFF0A6B56)),
                              const SizedBox(height: 8),
                              ...todayItems.map((n) => NotificationItemCard(
                                    notification: n,
                                    onActionTap: () => _handleNotificationAction(n),
                                  )),
                              const SizedBox(height: 16),
                            ],

                            // 3. Earlier Section
                            if (earlierItems.isNotEmpty) ...[
                              _buildSectionHeader('Earlier / मागील', Icons.history, RuralCareColors.textSecondary),
                              const SizedBox(height: 8),
                              ...earlierItems.map((n) => NotificationItemCard(
                                    notification: n,
                                    onActionTap: () => _handleNotificationAction(n),
                                  )),
                              const SizedBox(height: 16),
                            ],

                            // Offline Guarantee Banner
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: RuralCareColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.offline_pin_outlined, size: 16, color: Color(0xFF0A6B56)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Updates save offline and sync when connected',
                                    style: AppTypography.supporting.copyWith(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildHeader(BuildContext context, SessionCoordinator session) {
    return AppBar(
      backgroundColor: RuralCareColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF0A6B56)),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF0A6B56),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.health_and_safety, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          const Text(
            'RuralCare',
            style: TextStyle(color: Color(0xFF0A6B56), fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(color: Color(0xFF15803D), shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                const Text('Active', style: TextStyle(color: Color(0xFF15803D), fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Language Toggle Pills
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: RuralCareColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              _langButton('EN', session.isEnglish, () => session.switchLanguage('en')),
              _langButton('हि', session.isHindi, () => session.switchLanguage('hi')),
              _langButton('म', session.isMarathi, () => session.switchLanguage('mr')),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Emergency Alert Pill
        IconButton(
          icon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFB91C1C),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emergency_outlined, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              ],
            ),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Emergency Alert Active: Local care team notified.')),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _langButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 2)] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF0A6B56) : RuralCareColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String category, String label, {bool isAlert = false}) {
    final isSelected = _activeFilter == category;
    return InkWell(
      onTap: () => setState(() => _activeFilter = category),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0A6B56) : RuralCareColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAlert) ...[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: Color(0xFFB91C1C), shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : RuralCareColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(SessionCoordinator session) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: RuralCareColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.inbox_outlined, color: Color(0xFF0A6B56), size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              session.isHindi ? 'कोई नई सूचना नहीं' : (session.isMarathi ? 'कोणतीही नवीन सूचना नाही' : 'No notifications in this filter'),
              style: AppTypography.cardTitle,
            ),
            const SizedBox(height: 6),
            Text(
              session.isHindi
                  ? 'इस श्रेणी में वर्तमान में कोई सक्रिय सूचना उपलब्ध नहीं है।'
                  : (session.isMarathi ? 'या श्रेणीमध्ये कोणतीही सक्रिय सूचना नाही.' : 'All clinical updates and tasks are up to date.'),
              style: AppTypography.supporting,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() => _activeFilter = 'all'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A6B56),
                foregroundColor: Colors.white,
              ),
              child: const Text('Show All Notifications'),
            ),
          ],
        ),
      ),
    );
  }
}
