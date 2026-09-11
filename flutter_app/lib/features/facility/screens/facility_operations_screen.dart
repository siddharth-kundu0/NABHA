import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/demo_role_switcher.dart';
import '../../data/repositories/facility_repository.dart';
import '../../data/repositories/referral_repository.dart';

class FacilityOperationsScreen extends StatefulWidget {
  const FacilityOperationsScreen({super.key});

  @override
  State<FacilityOperationsScreen> createState() => _FacilityOperationsScreenState();
}

class _FacilityOperationsScreenState extends State<FacilityOperationsScreen> {
  int _availableBeds = 22;
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
    final facilities = facRepo.facilities;
    final facility = facilities.firstWhere((f) => f.id == 'FAC-SDH-301', orElse: () => facilities.first);

    return ListenableBuilder(
      listenable: Listenable.merge([facRepo, refRepo]),
      builder: (context, _) {
        final referrals = refRepo.referrals;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(facility.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Text('Hospital Intake Desk & Resource Control', style: TextStyle(fontSize: 11, color: AppColors.forestTealLight)),
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
                // Bed Occupancy Dashboard Gauge
                _buildBedGaugeCard(context, facility),
                const SizedBox(height: 16),

                // Fast-Track QR Referral Intake Desk
                Text('Fast-Track Referral Intake Desk (QR Scan)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.slateNavy)),
                const SizedBox(height: 8),
                _buildQrIntakeCard(context, refRepo, referrals),
                const SizedBox(height: 20),

                // Live Blood Bank Units
                Text('Blood Bank Inventory (रक्तपेढी)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.slateNavy)),
                const SizedBox(height: 8),
                _buildBloodBankCard(context, facility),
                const SizedBox(height: 20),

                // Pharmacy Stock Live Status
                Text('Critical Emergency Medicines Stock', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.slateNavy)),
                const SizedBox(height: 8),
                _buildPharmacyControlCard(context, facility),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBedGaugeCard(BuildContext context, dynamic facility) {
    final occupancyPct = ((facility.totalBeds - _availableBeds) / facility.totalBeds * 100).toInt();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Live Bed Availability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                  child: Text('$_availableBeds Vacant', style: const TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (facility.totalBeds - _availableBeds) / facility.totalBeds,
              backgroundColor: AppColors.neutral200,
              color: occupancyPct > 85 ? AppColors.criticalRed : AppColors.forestTeal,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Occupancy: $occupancyPct% (${facility.totalBeds - _availableBeds} / ${facility.totalBeds} Beds)', style: const TextStyle(fontSize: 12, color: AppColors.neutral700)),
                Text('Type: ${facility.typeDisplay}', style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Adjust Vacant Beds (Intake / Discharge):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    IconButton.filledTonal(
                      icon: const Icon(Icons.remove, size: 16),
                      onPressed: () {
                        if (_availableBeds > 0) setState(() => _availableBeds--);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('$_availableBeds', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.add, size: 16),
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
      ),
    );
  }

  Widget _buildQrIntakeCard(BuildContext context, ReferralRepository refRepo, List<dynamic> referrals) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qrInputCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Scan or Enter Referral Pass Token',
                      prefixIcon: Icon(Icons.qr_code_scanner, color: AppColors.forestTeal),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final code = _qrInputCtrl.text.trim();
                    refRepo.advanceStatus(code);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Verified Token $code! Patient admitted and bed allocated in Maternity ward.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  child: const Text('Admit Patient'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (referrals.isNotEmpty) ...[
              const Text('Incoming Patient Pre-Alerts:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              ...referrals.map((r) => Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAntiGlare,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.neutral300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${r.id} • ${r.patientName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('Origin: ${r.referringFacility} • ${r.urgency}', style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.terracotta.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                          child: Text(r.statusDisplay, style: const TextStyle(color: AppColors.terracotta, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBloodBankCard(BuildContext context, dynamic facility) {
    final Map<String, int> blood = facility.availableBloodUnits;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: blood.entries.map((e) {
            return Column(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.criticalRed.withOpacity(0.12),
                  radius: 20,
                  child: Text(e.key, style: const TextStyle(color: AppColors.criticalRed, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(height: 6),
                Text('${e.value} Units', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const Text('Available', style: TextStyle(fontSize: 10, color: AppColors.neutral600)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPharmacyControlCard(BuildContext context, dynamic facility) {
    final meds = [
      {'name': 'Tab. Labetalol 100mg', 'stock': '140 Strips', 'isCritical': true},
      {'name': 'Inj. Oxytocin 10 IU', 'stock': '45 Ampoules', 'isCritical': true},
      {'name': 'Inj. Magnesium Sulphate 50%', 'stock': '28 Vials', 'isCritical': true},
      {'name': 'Tab. Iron & Folic Acid', 'stock': '1,200 Tabs', 'isCritical': false},
      {'name': 'Inj. Iron Sucrose 100mg', 'stock': '35 Vials', 'isCritical': true},
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: meds.map((m) {
            return ListTile(
              dense: true,
              leading: const Icon(Icons.medication, color: AppColors.forestTeal),
              title: Text(m['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              subtitle: Text('Current Stock: ${m['stock']}', style: const TextStyle(fontSize: 11)),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceAntiGlare,
                  foregroundColor: AppColors.slateNavy,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(60, 30),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Restock requisition generated for ${m['name']}!')),
                  );
                },
                child: const Text('Reorder', style: TextStyle(fontSize: 10)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
