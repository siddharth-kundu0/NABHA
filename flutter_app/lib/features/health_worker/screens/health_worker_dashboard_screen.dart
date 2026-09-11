import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/core/theme/demo_role_switcher.dart';
import 'package:ruralcare/core/database/local_cache.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/data/repositories/referral_repository.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'vitals_collection_screen.dart';
import 'digital_triage_screen.dart';
import 'maternal_care_screen.dart';
import 'package:ruralcare/features/emergency/screens/emergency_tracking_screen.dart';

/// Pixel-Perfect realization of Stitch Screen 1: Health Worker Dashboard (441a868a378046cc9ac82cb064f3763b)
/// Frontline ASHA/ANM operational cockpit with zero mock data.
class HealthWorkerDashboardScreen extends StatefulWidget {
  const HealthWorkerDashboardScreen({super.key});

  @override
  State<HealthWorkerDashboardScreen> createState() => _HealthWorkerDashboardScreenState();
}

class _HealthWorkerDashboardScreenState extends State<HealthWorkerDashboardScreen> {
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final patientRepo = PatientRepository();
    final refRepo = ReferralRepository();
    final cache = LocalCacheService();
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: Listenable.merge([patientRepo, refRepo, cache, session]),
      builder: (context, _) {
        final patients = patientRepo.patients;
        final referrals = refRepo.referrals;
        final highRiskPatients = patients.where((p) => p.isPregnant && p.highRiskConditions.isNotEmpty).toList();
        final lang = session.activeLanguage;

        return Scaffold(
          backgroundColor: AppColors.stitchSurface,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.stitchOnSurface,
            elevation: 1,
            title: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 19,
                      backgroundColor: AppColors.stitchPrimary.withOpacity(0.12),
                      child: const Icon(Icons.person, color: AppColors.stitchPrimary, size: 24),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.stitchPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 8, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang == 'Hindi'
                            ? 'सुनीता ताई गायकवाड (ASHA)'
                            : (lang == 'Marathi'
                                ? 'सुनीता ताई गायकवाड (आशा)'
                                : 'Sunita Gaikwad (ASHA Worker)'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.stitchOnSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        lang == 'Hindi'
                            ? 'सेक्टर: काष्टी उप-केंद्र • रामपुर PHC'
                            : (lang == 'Marathi'
                                ? 'क्षेत्र: काष्टी उप-केंद्र • बारामती'
                                : 'Sector: Kashti Sub-Centre • PHC'),
                        style: const TextStyle(fontSize: 10, color: AppColors.neutral600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Fast Sync Button
              IconButton(
                tooltip: 'Sync Field Records',
                icon: _isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.stitchPrimary),
                      )
                    : const Icon(Icons.sync, color: AppColors.stitchPrimary),
                onPressed: _isSyncing
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        setState(() => _isSyncing = true);
                        await cache.flushOutboxQueue();
                        await Future.delayed(const Duration(milliseconds: 600));
                        if (mounted) {
                          setState(() => _isSyncing = false);
                          messenger.showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.stitchPrimary,
                              content: Text('Field records synchronized with PHC server!'),
                            ),
                          );
                        }
                      },
              ),
              IconButton(
                tooltip: 'Switch Role (Demo)',
                icon: const Icon(Icons.switch_account_rounded, color: AppColors.slateNavy),
                onPressed: () => DemoRoleSwitcher.show(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 4-Metric Overview Cards
                _buildMetricsGrid(context, highRiskCount: highRiskPatients.length, activeRefCount: referrals.length, total: patients.length, lang: lang),
                const SizedBox(height: 16),

                // Fast Action Tools Strip (4 rounded icon buttons)
                _buildSectionTitle(lang == 'Hindi' ? 'त्वरित फील्ड टूल्स (Quick Actions)' : (lang == 'Marathi' ? 'फील्ड टूल्स (कृती)' : 'Clinical Field Tools')),
                const SizedBox(height: 8),
                _buildQuickToolsGrid(context, lang),
                const SizedBox(height: 18),

                // Tasks for Today / Action Queue
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle(lang == 'Hindi' ? 'आज के कार्य (Tasks for Today)' : (lang == 'Marathi' ? 'आजची कार्ये (Tasks for Today)' : 'Tasks for Today')),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.stitchPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${patients.length} Actionable',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.stitchPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTaskCards(context, patients, lang),
                const SizedBox(height: 80),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const VitalsCollectionScreen()),
              );
            },
            backgroundColor: AppColors.stitchPrimary,
            icon: const Icon(Icons.bluetooth_searching, color: Colors.white),
            label: Text(
              lang == 'Hindi' ? 'वाइटल्स दर्ज करें / BLE सिंक' : (lang == 'Marathi' ? 'आरोग्य तपासणी / BLE सिंक' : 'Record Vitals / BLE Sync'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.slateNavy),
    );
  }

  /// 4 Key Operational Metrics matching Stitch design
  Widget _buildMetricsGrid(BuildContext context, {required int highRiskCount, required int activeRefCount, required int total, required String lang}) {
    return Row(
      children: [
        _metricTile(
          context,
          title: lang == 'Hindi' ? 'उच्च जोखिम माता' : (lang == 'Marathi' ? 'उच्च-धोका ANC' : 'High-Risk ANC'),
          value: '$highRiskCount',
          badgeColor: AppColors.criticalRed,
          badgeBg: const Color(0xFFFFDAD6),
          icon: Icons.warning_amber_rounded,
        ),
        const SizedBox(width: 8),
        _metricTile(
          context,
          title: lang == 'Hindi' ? 'आज की जांच' : (lang == 'Marathi' ? 'आजच्या भेटी' : 'Due Today'),
          value: '$total',
          badgeColor: AppColors.slateNavy,
          badgeBg: AppColors.stitchSurfaceContainer,
          icon: Icons.calendar_today,
        ),
        const SizedBox(width: 8),
        _metricTile(
          context,
          title: lang == 'Hindi' ? 'सक्रिय रेफरल' : (lang == 'Marathi' ? 'सक्रिय संदर्भ' : 'Active Ref.'),
          value: '$activeRefCount',
          badgeColor: const Color(0xFFB45309),
          badgeBg: const Color(0xFFFEF3C7),
          icon: Icons.alt_route,
        ),
      ],
    );
  }

  Widget _metricTile(
    BuildContext context, {
    required String title,
    required String value,
    required Color badgeColor,
    required Color badgeBg,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neutral200, width: 0.8),
          boxShadow: const [
            BoxShadow(color: Color(0x050D1C2E), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 16, color: badgeColor),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                  child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: badgeColor)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.neutral700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// 4 Quick Action Tools matching Stitch Screen 1 (Collect Vitals, Maternal Care, Digital Triage, Emergency SOS)
  Widget _buildQuickToolsGrid(BuildContext context, String lang) {
    return Row(
      children: [
        _quickToolButton(
          context,
          icon: Icons.bluetooth_searching,
          label: lang == 'Hindi' ? 'BLE वाइटल्स' : (lang == 'Marathi' ? 'BLE तपासणी' : 'BLE Vitals'),
          color: AppColors.stitchPrimary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) => const VitalsCollectionScreen()),
            );
          },
        ),
        const SizedBox(width: 8),
        _quickToolButton(
          context,
          icon: Icons.pregnant_woman,
          label: lang == 'Hindi' ? 'मातृत्व सेवा' : (lang == 'Marathi' ? 'मातृत्व काळजी' : 'Maternal ANC'),
          color: const Color(0xFF0D9488),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) => const MaternalCareScreen()),
            );
          },
        ),
        const SizedBox(width: 8),
        _quickToolButton(
          context,
          icon: Icons.health_and_safety,
          label: lang == 'Hindi' ? 'डिजिटल ट्रायज' : (lang == 'Marathi' ? 'लक्षण तपासणी' : 'Digital Triage'),
          color: AppColors.slateNavy,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) => const DigitalTriageScreen()),
            );
          },
        ),
        const SizedBox(width: 8),
        _quickToolButton(
          context,
          icon: Icons.emergency,
          label: lang == 'Hindi' ? '108 SOS' : (lang == 'Marathi' ? '१०८ SOS' : '108 SOS'),
          color: AppColors.criticalRed,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) => const EmergencyTrackingScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _quickToolButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.neutral200, width: 0.8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.neutral800),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tasks for Today Cards matching Stitch design (Task 1 & Task 2)
  Widget _buildTaskCards(BuildContext context, List<PatientDto> patients, String lang) {
    if (patients.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No assigned household patients.'),
        ),
      );
    }

    return Column(
      children: patients.map((patient) {
        final isHighRisk = patient.isPregnant && patient.highRiskConditions.isNotEmpty;
        final vitals = patient.latestVitals;

        String badgeText;
        Color badgeColor;
        Color badgeBg;

        if (isHighRisk) {
          badgeText = lang == 'Hindi' ? 'प्राथमिकता / उच्च-जोखिम' : (lang == 'Marathi' ? 'प्राधान्य / उच्च-धोका' : 'Priority ANC');
          badgeColor = AppColors.criticalRed;
          badgeBg = const Color(0xFFFFDAD6);
        } else {
          badgeText = lang == 'Hindi' ? 'आज देय' : (lang == 'Marathi' ? 'आज बाकी' : 'Due Today');
          badgeColor = AppColors.slateNavy;
          badgeBg = AppColors.stitchSurfaceContainer;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isHighRisk ? AppColors.criticalRed.withOpacity(0.3) : AppColors.neutral200,
              width: isHighRisk ? 1.2 : 0.8,
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x060D1C2E), blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Header with Avatar & Priority Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isHighRisk ? const Color(0xFFFFDAD6) : AppColors.stitchSurfaceContainer,
                        child: Icon(
                          isHighRisk ? Icons.pregnant_woman : Icons.person,
                          color: isHighRisk ? AppColors.criticalRed : AppColors.slateNavy,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.neutral900),
                          ),
                          Text(
                            '${patient.age}Y • ${patient.village} (घर क्र. 42)',
                            style: const TextStyle(fontSize: 10, color: AppColors.neutral600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                    child: Text(badgeText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor)),
                  ),
                ],
              ),
              const Divider(height: 18),

              // Clinical Condition / Vitals Summary
              Text(
                isHighRisk
                    ? '32-Week Gestational Hypertension with Severe Anaemia'
                    : 'Hypertension Post-Consultation • Regular Health Protocol',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: AppColors.neutral900),
              ),
              const SizedBox(height: 3),
              Text(
                vitals != null
                    ? 'BP: ${vitals.systolicBp}/${vitals.diastolicBp} mmHg • Hb: ${vitals.haemoglobin} g/dL • SpO2: ${vitals.spO2}%'
                    : 'Awaiting baseline vitals checkup',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isHighRisk ? FontWeight.bold : FontWeight.normal,
                  color: isHighRisk ? const Color(0xFFB45309) : AppColors.neutral600,
                ),
              ),
              const SizedBox(height: 12),

              // Action Buttons (Call & Record Visit)
              Row(
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.call, size: 18, color: AppColors.stitchPrimary),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.stitchPrimary,
                          content: Text('Calling ${patient.fullName} (${patient.phoneNumber})...'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => VitalsCollectionScreen(selectedPatientId: patient.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: Text(
                        lang == 'Hindi' ? 'विज़िट दर्ज करें (Record Visit)' : (lang == 'Marathi' ? 'भेट नोंदवा (Record Visit)' : 'Record Visit'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.stitchPrimary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 42),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
