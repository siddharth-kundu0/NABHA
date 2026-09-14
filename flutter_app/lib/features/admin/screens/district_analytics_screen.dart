import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/app/routes.dart';

import 'package:ruralcare/features/admin/widgets/admin_dashboard_tab.dart';
import 'package:ruralcare/features/admin/widgets/admin_users_tab.dart';
import 'package:ruralcare/features/admin/widgets/admin_facilities_tab.dart';
import 'package:ruralcare/features/admin/widgets/admin_system_audit_tab.dart';

/// District Administration Master Console conforming strictly to:
/// - Stitch Screens: d4584434, e22f160b, 4645b058, fec523c1
/// - MASTER_SPECIFICATION_RuralCare.md (Sec 14 & 24)
/// - DESIGN.md (District Admin Profile & Clinical Aesthetics)
class DistrictAnalyticsScreen extends StatefulWidget {
  const DistrictAnalyticsScreen({super.key});

  @override
  State<DistrictAnalyticsScreen> createState() => _DistrictAnalyticsScreenState();
}

class _DistrictAnalyticsScreenState extends State<DistrictAnalyticsScreen> {
  int _activeTabIndex = 0;
  final SessionCoordinator _session = SessionCoordinator();

  void _showBroadcastModal() {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    String priority = 'URGENT';
    String targetGroup = 'ALL_FACILITIES';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.campaign_rounded, color: Color(0xFF005140)),
                SizedBox(width: 10),
                Text('Broadcast Cluster Notice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dispatches real-time broadcast alert to all connected PHCs, CHCs, and ASHA tablets.',
                    style: TextStyle(fontSize: 12, color: RuralCareColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notice Subject *',
                      hintText: 'e.g. Cold Chain Alert or Heavy Rainfall Protocol',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: targetGroup,
                    decoration: const InputDecoration(
                      labelText: 'Recipient Scope',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ALL_FACILITIES', child: Text('All Facilities & Field Units')),
                      DropdownMenuItem(value: 'HOSPITALS_ONLY', child: Text('Referral Hospitals (SDH / CHC)')),
                      DropdownMenuItem(value: 'ASHAS_ONLY', child: Text('ASHA & CHO Field Force')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => targetGroup = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority Level',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'NORMAL', child: Text('Normal Advisory')),
                      DropdownMenuItem(value: 'URGENT', child: Text('Urgent Clinical Notice')),
                      DropdownMenuItem(value: 'CRITICAL', child: Text('Critical Emergency Flash (108 Relay)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => priority = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: msgCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Broadcast Instructions *',
                      hintText: 'Provide actionable operational guidelines...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005140),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty || msgCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter notice subject and message.')),
                    );
                    return;
                  }

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Dispatched: "${titleCtrl.text.trim()}" to $targetGroup ($priority)',
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF005140),
                    ),
                  );
                },
                child: const Text('Send Broadcast'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _session,
      builder: (context, _) {
        final isMr = _session.isMr;
        final isHi = _session.isHi;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FF),
          drawer: _buildDrawer(isHi, isMr),
          appBar: _buildTopAppBar(context, isHi, isMr),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 850;

              if (isWide) {
                // Persistent Sidebar for Desktop/Tablet Viewports
                return Row(
                  children: [
                    _buildPersistentSidebar(isHi, isMr),
                    const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
                    Expanded(child: _buildActiveTabContent()),
                  ],
                );
              } else {
                // Mobile Viewport with Tab Content + Bottom Segmented Navigation
                return Column(
                  children: [
                    Expanded(child: _buildActiveTabContent()),
                    _buildMobileBottomNav(isHi, isMr),
                  ],
                );
              }
            },
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildTopAppBar(BuildContext context, bool isHi, bool isMr) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Color(0xFF005140)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF005140).withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.admin_panel_settings_rounded, size: 16, color: Color(0xFF005140)),
                SizedBox(width: 6),
                Text(
                  'NABHA RuralCare',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF005140),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Text('v2.4 LTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
          ),
          const SizedBox(width: 12),
          // Live status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Color(0xFF15803D), size: 6),
                SizedBox(width: 6),
                Text(
                  'Operational • Sync Live',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Language switcher (EN | हि | म)
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _langButton('en', 'EN', _session.isEnglish),
              _langButton('hi', 'हि', _session.isHindi),
              _langButton('mr', 'म', _session.isMarathi),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Super Admin Profile Chip
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Color(0xFF005140),
                child: Text('SA', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: 6),
              Text('Dr. Sharma', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: RuralCareColors.textSecondary),
          tooltip: 'Sign Out',
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Sign Out?'),
                content: const Text('Are you sure you want to exit the District Administration portal?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _session.clearAuthenticatedUser();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(color: Color(0xFFE2E8F0), height: 1),
      ),
    );
  }

  Widget _langButton(String code, String label, bool isSelected) {
    return InkWell(
      onTap: () => _session.switchLanguage(code),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF005140) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildPersistentSidebar(bool isHi, bool isMr) {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              isMr ? 'प्रशासन मॉड्यूल्स' : (isHi ? 'प्रशासन मॉड्यूल्स' : 'ADMIN NAVIGATION'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: RuralCareColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _sidebarItem(0, isMr ? 'डॅशबोर्ड' : (isHi ? 'डैशबोर्ड' : 'Dashboard'), Icons.dashboard_rounded),
          _sidebarItem(1, isMr ? 'वापरकर्ते व अधिकार' : (isHi ? 'उपयोगकर्ता एवं रोल' : 'Users & Roles'), Icons.manage_accounts_rounded),
          _sidebarItem(2, isMr ? 'आरोग्य संस्था' : (isHi ? 'स्वास्थ्य केंद्र' : 'Facilities'), Icons.domain_rounded),
          _sidebarItem(3, isMr ? 'सिस्टम व ऑडिट' : (isHi ? 'सिस्टम एवं ऑडिट' : 'System & Audit'), Icons.shield_rounded),
          const Spacer(),
          // Sidebar footer with cluster node confirmation
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock_rounded, size: 14, color: Color(0xFF005140)),
                    SizedBox(width: 6),
                    Text('Node Rampur-HQ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Zone 04 • ABDM HFR Connected',
                  style: TextStyle(fontSize: 10, color: RuralCareColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, String title, IconData icon) {
    final isSelected = _activeTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _activeTabIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF005140) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : const Color(0xFF475569)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : RuralCareColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(bool isHi, bool isMr) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00382B), Color(0xFF005140)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 36),
                SizedBox(height: 8),
                Text('NABHA RuralCare Admin', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Rampur District Cluster HQ', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_rounded),
            title: Text(isMr ? 'डॅशबोर्ड' : (isHi ? 'डैशबोर्ड' : 'Dashboard')),
            selected: _activeTabIndex == 0,
            onTap: () {
              Navigator.pop(context);
              setState(() => _activeTabIndex = 0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts_rounded),
            title: Text(isMr ? 'वापरकर्ते व अधिकार' : (isHi ? 'उपयोगकर्ता एवं रोल' : 'Users & Roles')),
            selected: _activeTabIndex == 1,
            onTap: () {
              Navigator.pop(context);
              setState(() => _activeTabIndex = 1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.domain_rounded),
            title: Text(isMr ? 'आरोग्य संस्था' : (isHi ? 'स्वास्थ्य केंद्र' : 'Facilities')),
            selected: _activeTabIndex == 2,
            onTap: () {
              Navigator.pop(context);
              setState(() => _activeTabIndex = 2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.shield_rounded),
            title: Text(isMr ? 'सिस्टम व ऑडिट' : (isHi ? 'सिस्टम एवं ऑडिट' : 'System & Audit')),
            selected: _activeTabIndex == 3,
            onTap: () {
              Navigator.pop(context);
              setState(() => _activeTabIndex = 3);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBottomNav(bool isHi, bool isMr) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: BottomNavigationBar(
        currentIndex: _activeTabIndex,
        onTap: (index) => setState(() => _activeTabIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF005140),
        unselectedItemColor: RuralCareColors.textSecondary,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_rounded),
            label: isMr ? 'डॅशबोर्ड' : (isHi ? 'डैशबोर्ड' : 'Dashboard'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.manage_accounts_rounded),
            label: isMr ? 'वापरकर्ते' : (isHi ? 'उपयोगकर्ता' : 'Users'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.domain_rounded),
            label: isMr ? 'संस्था' : (isHi ? 'केंद्र' : 'Facilities'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shield_rounded),
            label: isMr ? 'ऑडिट' : (isHi ? 'ऑडिट' : 'Audit'),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTabIndex) {
      case 0:
        return AdminDashboardTab(
          onNavigateTab: (idx) => setState(() => _activeTabIndex = idx),
          onBroadcastNotice: _showBroadcastModal,
        );
      case 1:
        return const AdminUsersTab();
      case 2:
        return const AdminFacilitiesTab();
      case 3:
        return const AdminSystemAuditTab();
      default:
        return const SizedBox.shrink();
    }
  }
}
