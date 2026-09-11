import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/core/theme/demo_role_switcher.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';

class DistrictAnalyticsScreen extends StatelessWidget {
  const DistrictAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final facRepo = FacilityRepository();

    return Scaffold(
      backgroundColor: AppColors.stitchSurface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: _buildStitchAdminHeader(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. District Header Overview
            _buildDistrictOverviewBanner(),
            const SizedBox(height: 16),

            // 2. Key Performance Indicators (4-Card Grid)
            const Text(
              'District Health KPIs (Live Telemetry)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.neutral900),
            ),
            const SizedBox(height: 10),
            _buildKpiGrid(),
            const SizedBox(height: 18),

            // 3. Tiered Facility Network & Live Capacity
            const Text(
              'Tiered Facility Registry & Real-Time Capacity',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.neutral900),
            ),
            const SizedBox(height: 10),
            _buildFacilityList(facRepo),
            const SizedBox(height: 18),

            // 4. ABDM / PM-JAY Digital Health Audit Trail
            const Text(
              'ABDM Digital Health Audit Trail',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.neutral900),
            ),
            const SizedBox(height: 10),
            _buildAuditTrailCard(),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildStitchAdminHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.stitchSurface.withOpacity(0.95),
        border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F3D6E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'District Health Command',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F3D6E)),
                      ),
                      Text(
                        'Pune Rural District Administration (जिल्हा प्रशासन)',
                        style: TextStyle(fontSize: 10, color: AppColors.neutral600),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                tooltip: 'Switch Role (Demo)',
                icon: const Icon(Icons.switch_account, color: AppColors.slateNavy),
                onPressed: () => DemoRoleSwitcher.show(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistrictOverviewBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD5E3FC)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFD5E3FC),
                child: Icon(Icons.location_city_rounded, color: Color(0xFF0F3D6E), size: 20),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Baramati & Daund Health Corridor',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.neutral900),
                  ),
                  Text(
                    '14 Sub-Centres • 3 CHCs • 1 Sub-District Hospital',
                    style: TextStyle(fontSize: 10, color: AppColors.slateNavy),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              CircleAvatar(radius: 3, backgroundColor: Color(0xFF15803D)),
              SizedBox(width: 4),
              Text('Live', style: TextStyle(color: Color(0xFF15803D), fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        _kpiCard(
          title: 'Referral Completion',
          val: '91.4%',
          subtitle: 'Target >85% • Baseline 64%',
          icon: Icons.check_circle_rounded,
          color: AppColors.stitchPrimary,
          bg: const Color(0xFFE6F4F1),
        ),
        _kpiCard(
          title: 'Avg 108 Transit Time',
          val: '28.5m',
          subtitle: 'Target <45m • Baramati corridor',
          icon: Icons.timer_rounded,
          color: AppColors.slateNavy,
          bg: const Color(0xFFEFF4FF),
        ),
        _kpiCard(
          title: 'Institutional Delivery',
          val: '98.2%',
          subtitle: 'High risk ANC tracking active',
          icon: Icons.pregnant_woman_rounded,
          color: const Color(0xFFBE185D),
          bg: const Color(0xFFFCE7F3),
        ),
        _kpiCard(
          title: 'Offline Sync Integrity',
          val: '100%',
          subtitle: 'Zero data loss across 14 SCs',
          icon: Icons.cloud_done_rounded,
          color: AppColors.terracotta,
          bg: const Color(0xFFFFEDD5),
        ),
      ],
    );
  }

  Widget _kpiCard({
    required String title,
    required String val,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.neutral900)),
              Text(subtitle, style: const TextStyle(fontSize: 9, color: AppColors.neutral600), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityList(FacilityRepository facRepo) {
    return Column(
      children: facRepo.facilities.map((fac) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_hospital_rounded, color: AppColors.stitchPrimary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fac.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.neutral900)),
                    Text('${fac.typeDisplay} • ${fac.distanceKm} km away', style: const TextStyle(fontSize: 10, color: AppColors.slateNavy)),
                    Text('Beds: ${fac.availableBeds}/${fac.totalBeds} Available • Specialists: ${fac.onDutySpecialists.length}', style: const TextStyle(fontSize: 9, color: AppColors.neutral600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Operational', style: TextStyle(color: Color(0xFF15803D), fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAuditTrailCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _auditRow('ABHA Patient Registry', 'Verified 14,820 accounts in sector', 'PASS'),
          const Divider(height: 16),
          _auditRow('FHIR E-Prescription Bundle', '100% digitally signed prescriptions', 'PASS'),
          const Divider(height: 16),
          _auditRow('Offline Outbox Sync Engine', 'Auto-resync on network reconnect', 'ACTIVE'),
        ],
      ),
    );
  }

  Widget _auditRow(String title, String desc, String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.neutral900)),
              Text(desc, style: const TextStyle(fontSize: 10, color: AppColors.neutral600)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            status,
            style: const TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 10),
          ),
        ),
      ],
    );
  }
}
