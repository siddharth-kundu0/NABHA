import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/core/theme/demo_role_switcher.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';
import 'package:ruralcare/data/repositories/referral_repository.dart';
import 'package:ruralcare/data/models/facility_dto.dart';
import 'package:ruralcare/data/models/referral_dto.dart';
import 'package:ruralcare/app/routes.dart';

class FacilityOperationsScreen extends StatefulWidget {
  const FacilityOperationsScreen({super.key});

  @override
  State<FacilityOperationsScreen> createState() => _FacilityOperationsScreenState();
}

class _FacilityOperationsScreenState extends State<FacilityOperationsScreen> {
  int _availableBeds = 22;
  String _activeTab = 'medicines'; // 'medicines', 'diagnostics', 'services'
  String _selectedRole = 'Admin';
  final TextEditingController _qrInputCtrl = TextEditingController(text: 'REF-11021');

  @override
  void dispose() {
    _qrInputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final facRepo = FacilityRepository();
    final refRepo = ReferralRepository();
    final session = SessionCoordinator();
    final facilities = facRepo.facilities;
    final facility = facilities.firstWhere((f) => f.id == 'FAC-SDH-301', orElse: () => facilities.first);

    return ListenableBuilder(
      listenable: Listenable.merge([facRepo, refRepo, session]),
      builder: (context, _) {
        final referrals = refRepo.referrals;
        final currentLang = session.activeLanguage;

        return Scaffold(
          backgroundColor: AppColors.stitchSurface,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(110),
            child: _buildStitchFacilityHeader(context, facility, session, currentLang),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Facility Shift Banner
                _buildShiftBanner(facility, currentLang),
                const SizedBox(height: 12),

                // 2. High Priority Operational Alerts
                _buildOperationalAlerts(currentLang),
                const SizedBox(height: 14),

                // 3. Key Operational Metrics (4-Card Grid)
                _buildOperationalMetricsGrid(currentLang),
                const SizedBox(height: 16),

                // 4. Quick Operations Grid (>=48px touch targets)
                _buildQuickOperationsGrid(context, refRepo),
                const SizedBox(height: 18),

                // 5. Live Bed Occupancy Gauge (Stitch Style)
                _buildBedGaugeCard(facility),
                const SizedBox(height: 16),

                // 6. Real-time Blood Bank Units
                _buildBloodBankCard(facility),
                const SizedBox(height: 18),

                // 7. Inbound Urgent Case & Fast-Track QR Referral Intake Desk
                _buildInboundPreAlertCard(context, refRepo, referrals),
                const SizedBox(height: 18),

                // 8. Service & Inventory Availability Tabs (Medicines, Diagnostics, Services)
                _buildInventoryCategoryTabs(currentLang),
                const SizedBox(height: 12),
                _buildInventoryContent(facility, currentLang),
                const SizedBox(height: 28),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStitchFacilityHeader(
    BuildContext context,
    FacilityDto facility,
    SessionCoordinator session,
    String currentLang,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.stitchSurface.withOpacity(0.95),
        border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.stitchPrimary,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(color: Color(0x33005140), blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'RuralCare',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.stitchPrimary,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'Facility Staff • ${facility.name}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.slateNavy,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Language selector pill
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF4FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            _buildLangChip('EN', currentLang == 'English', () => session.switchLanguage('English')),
                            _buildLangChip('हि', currentLang == 'Hindi', () => session.switchLanguage('Hindi')),
                            _buildLangChip('म', currentLang == 'Marathi', () => session.switchLanguage('Marathi')),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Role Switcher Avatar
                      InkWell(
                        onTap: () => DemoRoleSwitcher.show(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.stitchPrimary.withOpacity(0.3), width: 2),
                            color: const Color(0xFFD5E3FC),
                          ),
                          child: const Icon(Icons.person, color: AppColors.stitchPrimary, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(radius: 3.5, backgroundColor: Color(0xFF15803D)),
                        SizedBox(width: 6),
                        Text(
                          'Online • Saved Locally',
                          style: TextStyle(fontSize: 11, color: Color(0xFF15803D), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${facility.name} (24x7)',
                    style: const TextStyle(fontSize: 11, color: AppColors.neutral600, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.stitchPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.slateNavy,
          ),
        ),
      ),
    );
  }

  Widget _buildShiftBanner(FacilityDto facility, String currentLang) {
    final hindiFacility = currentLang == 'HI'
        ? 'बारामती उप-ज़िला अस्पताल'
        : currentLang == 'MR'
            ? 'बारामती उप-जिल्हा रुग्णालय'
            : 'Baramati Sub-District Hospital';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        facility.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.neutral900),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4F1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        facility.typeDisplay,
                        style: const TextStyle(color: AppColors.stitchPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const CircleAvatar(radius: 3, backgroundColor: Color(0xFF15803D)),
                    const SizedBox(width: 5),
                    Text(
                      'Shift Active • $hindiFacility',
                      style: const TextStyle(fontSize: 11, color: AppColors.slateNavy, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Role switcher dropdown
          PopupMenuButton<String>(
            initialValue: _selectedRole,
            onSelected: (val) => setState(() => _selectedRole = val),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'Admin', child: Text('Facility Admin')),
              const PopupMenuItem(value: 'Doctor', child: Text('Medical Officer')),
              const PopupMenuItem(value: 'Pharmacist', child: Text('Chief Pharmacist')),
              const PopupMenuItem(value: 'Diagnostic', child: Text('Diagnostic Staff')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.badge_outlined, size: 16, color: AppColors.stitchPrimary),
                  const SizedBox(width: 4),
                  Text(_selectedRole, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.stitchPrimary)),
                  const Icon(Icons.expand_more, size: 16, color: AppColors.stitchPrimary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalAlerts(String currentLang) {
    return Column(
      children: [
        // Alert 1: Low stock alert
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFB45309).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.medication, size: 16, color: Color(0xFFB45309)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Amoxicillin & ORS (Low Stock)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFB45309),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('3d left', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, size: 18, color: Color(0xFFB45309)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Alert 2: Vaccine cold chain storage
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF15803D).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.ac_unit, size: 16, color: Color(0xFF15803D)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Vaccine Storage 4.2°C (Secure)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                ),
              ),
              const Row(
                children: [
                  CircleAvatar(radius: 3, backgroundColor: Color(0xFF15803D)),
                  SizedBox(width: 4),
                  Text(
                    'ILR 1 Verified',
                    style: TextStyle(color: Color(0xFF15803D), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOperationalMetricsGrid(String currentLang) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        _buildMetricCard(
          title: 'Appointments',
          value: '28',
          subLabel: 'Total',
          footer: '18 Done • 10 Left',
          footerColor: const Color(0xFF15803D),
          icon: Icons.calendar_today_rounded,
          iconBg: const Color(0xFFE6EEFF),
          iconColor: AppColors.stitchPrimary,
        ),
        _buildMetricCard(
          title: 'Queue Waiting',
          value: '7',
          subLabel: 'in line',
          footer: '● 2 In Consultation',
          footerColor: AppColors.stitchPrimary,
          icon: Icons.schedule_rounded,
          iconBg: const Color(0xFFFFEDD5),
          iconColor: const Color(0xFFC2410C),
        ),
        _buildMetricCard(
          title: 'Active Referrals',
          value: '4',
          subLabel: 'Active',
          footer: '2 In • 2 Out',
          footerColor: AppColors.slateNavy,
          icon: Icons.swap_horiz_rounded,
          iconBg: const Color(0xFFE6EEFF),
          iconColor: AppColors.slateNavy,
        ),
        _buildMetricCard(
          title: 'Lab Diagnostics',
          value: '6',
          subLabel: 'Pending',
          footer: '4 Col. • 2 Due',
          footerColor: AppColors.neutral700,
          icon: Icons.biotech_rounded,
          iconBg: const Color(0xFFE6EEFF),
          iconColor: AppColors.stitchPrimary,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subLabel,
    required String footer,
    required Color footerColor,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slateNavy)),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(6)),
                child: Icon(icon, size: 14, color: iconColor),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.neutral900)),
              const SizedBox(width: 4),
              Text(subLabel, style: const TextStyle(fontSize: 10, color: AppColors.neutral600)),
            ],
          ),
          Container(
            padding: const EdgeInsets.only(top: 4),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
            child: Text(footer, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: footerColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickOperationsGrid(BuildContext context, ReferralRepository refRepo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Operations (त्वरित संचालन)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.neutral900),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.2,
          children: [
            _buildActionCard(
              title: 'Queue Desk',
              subtitle: 'कतार प्रबंधन',
              badge: '7',
              icon: Icons.format_list_numbered_rounded,
              bgColor: AppColors.stitchPrimary,
              iconColor: Colors.white,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(backgroundColor: AppColors.stitchPrimary, content: Text('Opening Facility Triage & OPD Queue Desk...')),
                );
              },
            ),
            _buildActionCard(
              title: 'Patient Intake',
              subtitle: 'मरीज पंजीकरण',
              icon: Icons.person_search_rounded,
              bgColor: const Color(0xFF93F5D8),
              iconColor: const Color(0xFF005140),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(backgroundColor: AppColors.stitchPrimary, content: Text('Ready for ABHA / QR Patient Registration.')),
                );
              },
            ),
            _buildActionCard(
              title: 'Referral Network',
              subtitle: 'रेफरल नेटवर्क',
              badge: '${refRepo.referrals.length}',
              icon: Icons.local_shipping_rounded,
              bgColor: const Color(0xFFD5E3FC),
              iconColor: AppColors.slateNavy,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(backgroundColor: AppColors.slateNavy, content: Text('Accessing 108 Emergency Ambulance & Sub-Centre Network.')),
                );
              },
            ),
            _buildActionCard(
              title: 'Service Status',
              subtitle: 'दवा व सेवा स्थिति',
              icon: Icons.medical_services_rounded,
              bgColor: const Color(0xFFEFF4FF),
              iconColor: AppColors.stitchPrimary,
              onTap: () => setState(() => _activeTab = 'medicines'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    String? badge,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 3, offset: Offset(0, 1))],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Color(0xFFC2410C), shape: BoxShape.circle),
                      child: Text(
                        badge,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.neutral900), overflow: TextOverflow.ellipsis),
                  Text(subtitle, style: const TextStyle(fontSize: 9, color: AppColors.neutral600), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBedGaugeCard(FacilityDto facility) {
    final occupancyPct = ((facility.totalBeds - _availableBeds) / facility.totalBeds * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bed_rounded, color: AppColors.stitchPrimary, size: 18),
                  SizedBox(width: 6),
                  Text('Live Bed Occupancy Gauge', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.neutral900)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: occupancyPct > 85 ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_availableBeds Vacant',
                  style: TextStyle(
                    color: occupancyPct > 85 ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (facility.totalBeds - _availableBeds) / facility.totalBeds,
              backgroundColor: const Color(0xFFE2E8F0),
              color: occupancyPct > 85 ? const Color(0xFFBA1A1A) : AppColors.stitchPrimary,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Occupancy: $occupancyPct% (${facility.totalBeds - _availableBeds} / ${facility.totalBeds} Beds)',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slateNavy),
              ),
              const Text('Maternity & ICU Active', style: TextStyle(fontSize: 10, color: AppColors.neutral600)),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bed Stepper (Intake / Discharge):',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral700),
              ),
              Row(
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.remove, size: 16),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      if (_availableBeds > 0) setState(() => _availableBeds--);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('$_availableBeds', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add, size: 16),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      if (_availableBeds < facility.totalBeds) setState(() => _availableBeds++);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBloodBankCard(FacilityDto facility) {
    final Map<String, int> blood = facility.availableBloodUnits;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bloodtype_rounded, color: Color(0xFFBA1A1A), size: 18),
                  SizedBox(width: 6),
                  Text('Blood Bank Inventory (रक्तपेढी)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.neutral900)),
                ],
              ),
              Text('Live Cold Ledger', style: TextStyle(fontSize: 10, color: AppColors.neutral600, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: blood.entries.map((e) {
              final isLow = e.value < 5;
              return Column(
                children: [
                  CircleAvatar(
                    backgroundColor: isLow ? const Color(0xFFFEE2E2) : const Color(0xFFEFF4FF),
                    radius: 20,
                    child: Text(
                      e.key,
                      style: TextStyle(
                        color: isLow ? const Color(0xFFB91C1C) : AppColors.stitchPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${e.value} U', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(isLow ? 'Low Stock' : 'Adequate', style: TextStyle(fontSize: 9, color: isLow ? const Color(0xFFB91C1C) : AppColors.neutral600)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInboundPreAlertCard(
    BuildContext context,
    ReferralRepository refRepo,
    List<ReferralDto> referrals,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC2410C).withOpacity(0.4), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDD5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.emergency_rounded, color: Color(0xFFC2410C), size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('INBOUND URGENT', style: TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.bold, fontSize: 10)),
                          SizedBox(width: 6),
                          Text('• ETA 25 Min', style: TextStyle(color: Color(0xFFC2410C), fontWeight: FontWeight.bold, fontSize: 10)),
                        ],
                      ),
                      Text('Pre-Alert Referral Desk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.neutral900)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Priority 1', style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Kavita Rajesh Devi (Age 26) • 32 Wks Pregnant',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.neutral900),
          ),
          const Text(
            'Suspected Gestational Hypertension with Anaemia • Kashti Sub-Centre',
            style: TextStyle(fontSize: 11, color: AppColors.slateNavy),
          ),
          const SizedBox(height: 12),
          // QR Fast-Track Intake input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qrInputCtrl,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                    hintText: 'Scan or Enter Referral Pass Token',
                    prefixIcon: const Icon(Icons.qr_code_scanner, color: AppColors.stitchPrimary, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final code = _qrInputCtrl.text.trim();
                    refRepo.advanceStatus(code);
                    if (_availableBeds > 0) {
                      setState(() => _availableBeds--);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.stitchPrimary,
                        content: Text('Verified Token $code! Patient admitted and Maternity Bed allocated.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.assignment_turned_in, size: 16),
                  label: const Text('Admit Patient', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.stitchPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCategoryTabs(String currentLang) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildCategoryTabItem(
            id: 'medicines',
            title: 'Medicines',
            sub: 'दवाइयां',
            isActive: _activeTab == 'medicines',
            onTap: () => setState(() => _activeTab = 'medicines'),
          ),
          _buildCategoryTabItem(
            id: 'diagnostics',
            title: 'Diagnostics',
            sub: 'जांच सेवाएं',
            isActive: _activeTab == 'diagnostics',
            onTap: () => setState(() => _activeTab = 'diagnostics'),
          ),
          _buildCategoryTabItem(
            id: 'services',
            title: 'Services',
            sub: 'स्वास्थ्य सेवाएं',
            isActive: _activeTab == 'services',
            onTap: () => setState(() => _activeTab = 'services'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabItem({
    required String id,
    required String title,
    required String sub,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? AppColors.stitchPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive ? const [BoxShadow(color: Color(0x14000000), blurRadius: 4)] : null,
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : AppColors.slateNavy,
                ),
              ),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 9,
                  color: isActive ? Colors.white70 : AppColors.neutral600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryContent(FacilityDto facility, String currentLang) {
    if (_activeTab == 'medicines') {
      final items = [
        {'name': 'Paracetamol 500mg', 'status': 'Available', 'sub': 'Adequate stock in dispensary', 'color': const Color(0xFF15803D), 'bg': const Color(0xFFDCFCE7), 'icon': Icons.medication},
        {'name': 'Amoxicillin 250mg', 'status': 'Low Stock', 'sub': 'Reorder requested • 3d left', 'color': const Color(0xFFB45309), 'bg': const Color(0xFFFEF3C7), 'icon': Icons.medication_liquid_rounded},
        {'name': 'Tab. Labetalol 100mg', 'status': 'Available', 'sub': '140 strips in stock', 'color': const Color(0xFF15803D), 'bg': const Color(0xFFDCFCE7), 'icon': Icons.medication},
        {'name': 'Inj. Oxytocin 10 IU', 'status': 'Adequate', 'sub': '45 Ampoules in OT stock', 'color': const Color(0xFF15803D), 'bg': const Color(0xFFDCFCE7), 'icon': Icons.vaccines},
        {'name': 'Rabies Vaccine', 'status': 'Unavailable', 'sub': 'Cold-chain restock scheduled', 'color': const Color(0xFFB91C1C), 'bg': const Color(0xFFFEE2E2), 'icon': Icons.healing},
      ];
      return _buildItemList(items);
    } else if (_activeTab == 'diagnostics') {
      final items = [
        {'name': 'Hemoglobin (CBC / Strip)', 'status': 'Available', 'sub': 'Reagents verified', 'color': const Color(0xFF15803D), 'bg': const Color(0xFFDCFCE7), 'icon': Icons.bloodtype},
        {'name': 'Blood Glucose Rapid', 'status': 'Available', 'sub': 'Test strips active', 'color': const Color(0xFF15803D), 'bg': const Color(0xFFDCFCE7), 'icon': Icons.biotech},
        {'name': 'Malaria Rapid Test Kit', 'status': 'Available', 'sub': 'Stock adequate', 'color': const Color(0xFF15803D), 'bg': const Color(0xFFDCFCE7), 'icon': Icons.pest_control},
        {'name': 'Urine Albumin / Sugar', 'status': 'Low Stock', 'sub': 'Microcuvettes low', 'color': const Color(0xFFB45309), 'bg': const Color(0xFFFEF3C7), 'icon': Icons.science},
        {'name': 'Sputum AFB Collection', 'status': 'Update Required', 'sub': 'Sample courier pickup 2:00 PM', 'color': const Color(0xFF0284C7), 'bg': const Color(0xFFE0F2FE), 'icon': Icons.inventory_2},
      ];
      return _buildItemList(items);
    } else {
      final items = [
        {'name': 'General OPD Clinic', 'status': 'Available', 'sub': 'Mon–Sat, 9:00 AM – 2:00 PM', 'color': const Color(0xFF15803D), 'bg': const Color(0xFFDCFCE7), 'icon': Icons.health_and_safety},
        {'name': 'MCH & Immunization', 'status': 'Available', 'sub': 'Every Wednesday & Friday', 'color': const Color(0xFF15803D), 'bg': const Color(0xFFDCFCE7), 'icon': Icons.child_care},
        {'name': '24x7 Emergency Stabilization', 'status': 'Available', 'sub': 'Medical Officer on duty', 'color': const Color(0xFF15803D), 'bg': const Color(0xFFDCFCE7), 'icon': Icons.emergency},
        {'name': 'Telemedicine Consultation', 'status': 'Available', 'sub': 'High-speed specialist link online', 'color': const Color(0xFF15803D), 'bg': const Color(0xFFDCFCE7), 'icon': Icons.video_call},
      ];
      return _buildItemList(items);
    }
  }

  Widget _buildItemList(List<Map<String, dynamic>> items) {
    return Column(
      children: items.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item['icon'] as IconData, size: 18, color: AppColors.stitchPrimary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.neutral900)),
                    Text(item['sub'] as String, style: const TextStyle(fontSize: 10, color: AppColors.neutral600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item['bg'] as Color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item['status'] as String,
                  style: TextStyle(color: item['color'] as Color, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
