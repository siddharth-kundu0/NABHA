import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/demo_role_switcher.dart';
import '../../data/repositories/facility_repository.dart';

class DistrictAnalyticsScreen extends StatelessWidget {
  const DistrictAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final facRepo = FacilityRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('District Health Command', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text('Pune Rural District Administration (जिल्हा प्रशासन)', style: TextStyle(fontSize: 11, color: AppColors.forestTealLight)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Switch Role (Demo)',
            icon: const Icon(Icons.switch_account),
            onPressed: () => DemoRoleSwitcher.show(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Grid
            Text('District Health KPIs (Live Telemetry)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.slateNavy)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.4,
              children: [
                _kpiCard('Referral Completion Rate', '91.4%', 'Target > 85% • Baseline 64%', Icons.check_circle, AppColors.forestTeal),
                _kpiCard('Avg Transit Time (108)', '28.5 min', 'Target < 45 min • Baramati corridor', Icons.timer, AppColors.slateNavy),
                _kpiCard('Institutional Delivery %', '98.2%', 'High risk tracking active', Icons.pregnant_woman, const Color(0xFFBE185D)),
                _kpiCard('Offline Sync Integrity', '100%', 'Zero data loss across 14 Sub-centres', Icons.cloud_done, AppColors.terracotta),
              ],
            ),
            const SizedBox(height: 20),

            // Tiered Facility Network
            Text('Tiered Facility Registry & Real-Time Capacity', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.slateNavy)),
            const SizedBox(height: 10),
            ...facRepo.facilities.map((fac) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.slateNavy.withOpacity(0.12),
                      child: const Icon(Icons.apartment, color: AppColors.slateNavy),
                    ),
                    title: Text(fac.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('${fac.typeDisplay} • ${fac.distanceKm} km\nBeds: ${fac.availableBeds}/${fac.totalBeds} Available • Specialists: ${fac.onDutySpecialists.length}', style: const TextStyle(fontSize: 11)),
                    isThreeLine: true,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                      child: const Text('Operational', style: TextStyle(color: Color(0xFF15803D), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                )),
            const SizedBox(height: 20),

            // ABDM / PM-JAY Audit Trail
            Text('ABDM Digital Health Audit Trail', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.slateNavy)),
            const SizedBox(height: 10),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _auditRow('ABHA Patient Registry', 'Verified 14,820 accounts in sector', 'PASS'),
                    const Divider(height: 16),
                    _auditRow('FHIR E-Prescription Bundle', '100% digitally signed prescriptions', 'PASS'),
                    const Divider(height: 16),
                    _auditRow('Offline Outbox Sync Engine', 'Auto-resync on network reconnect', 'ACTIVE'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(String title, String val, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.neutral900)),
          Text(subtitle, style: const TextStyle(fontSize: 9, color: AppColors.neutral600), maxLines: 1, overflow: TextOverflow.ellipsis),
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
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text(desc, style: const TextStyle(fontSize: 10, color: AppColors.neutral600)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
          child: Text(status, style: const TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 10)),
        ),
      ],
    );
  }
}
