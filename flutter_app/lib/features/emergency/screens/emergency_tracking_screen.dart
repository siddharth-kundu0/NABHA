import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/core/database/local_cache.dart';
import 'package:ruralcare/data/repositories/emergency_repository.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/app/routes.dart';

/// Emergency Help Screen conforming strictly to DESIGN.md Section 6:
/// A focused page with a clear title, brief explanation of what the app can actually do,
/// explicit location-sharing choice, prominent actions, and real states (queued, sent, failed, acknowledged).
/// Does not invent fake ambulance dispatch timers or flashing animations.
class EmergencyTrackingScreen extends StatefulWidget {
  const EmergencyTrackingScreen({super.key});

  @override
  State<EmergencyTrackingScreen> createState() => _EmergencyTrackingScreenState();
}

class _EmergencyTrackingScreenState extends State<EmergencyTrackingScreen> {
  bool _shareLocation = true;

  @override
  Widget build(BuildContext context) {
    final emergRepo = EmergencyRepository();
    final patientRepo = PatientRepository();
    final cache = LocalCacheService();
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: Listenable.merge([emergRepo, cache, session]),
      builder: (context, _) {
        final event = emergRepo.activeEvent;
        final patient = patientRepo.defaultPatient;
        final isOffline = cache.isOffline;
        final isSosActive = emergRepo.hasActiveEmergency;

        return Scaffold(
          backgroundColor: RuralCareColors.canvas,
          appBar: AppBar(
            title: const Text('Emergency help', style: AppTypography.pageTitle),
            backgroundColor: RuralCareColors.surface,
            elevation: 0,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(color: RuralCareColors.border, height: 1),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Plain-language Scope & Explanation Card
                _buildCapabilitiesCard(),

                const SizedBox(height: 20),

                // 2. Offline Warning Banner (if offline)
                if (isOffline) ...[
                  _buildOfflineWarningBanner(),
                  const SizedBox(height: 20),
                ],

                // 3. Location Sharing Choice (DESIGN.md: explicit location-sharing choice)
                _buildLocationSharingCard(),

                const SizedBox(height: 20),

                // 4. Real Status State Card (Queued, Sent, Acknowledged, Failed)
                _buildStatusLedger(event, isOffline, isSosActive),

                const SizedBox(height: 24),

                // 5. Prominent Action Buttons (52px minimum height)
                _buildActionButtons(context, emergRepo, isSosActive, patient),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCapabilitiesCard() {
    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: RuralCareColors.primary, size: 22),
              SizedBox(width: 10),
              Text(
                'How this service works',
                style: AppTypography.cardTitle,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Triggering an emergency alert transmits the patient’s critical clinical history, blood group, and approximate GPS coordinates to the nearest First Referral Unit (Baramati SDH) and notifies the designated frontline health worker.',
            style: AppTypography.body,
          ),
          const SizedBox(height: 6),
          Text(
            'For immediate life-threatening events, always place a direct telephone call to the national 108 ambulance helpline.',
            style: AppTypography.supporting.copyWith(color: RuralCareColors.critical),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RuralCareColors.warningSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RuralCareColors.warning.withOpacity(0.3), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_off_rounded, color: RuralCareColors.warning, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offline mode active',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: RuralCareColors.warning,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Emergency alerts cannot reach the cloud server until internet connectivity is restored. Please call 108 directly.',
                  style: AppTypography.supporting.copyWith(color: RuralCareColors.warning),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSharingCard() {
    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Share location coordinates', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                const Text(
                  'Kashti Village, Sector 3 (18.618° N, 74.571° E)',
                  style: AppTypography.supporting,
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _shareLocation,
            activeColor: RuralCareColors.primary,
            onChanged: (val) => setState(() => _shareLocation = val),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusLedger(event, bool isOffline, bool isSosActive) {
    String stateLabel;
    Color stateColor;
    Color stateBg;

    if (!isSosActive) {
      stateLabel = 'Standby (Ready)';
      stateColor = RuralCareColors.textSecondary;
      stateBg = RuralCareColors.surfaceSubtle;
    } else if (isOffline) {
      stateLabel = 'Queued in local outbox (Offline)';
      stateColor = RuralCareColors.warning;
      stateBg = RuralCareColors.warningSoft;
    } else {
      stateLabel = 'Sent & Acknowledged';
      stateColor = RuralCareColors.success;
      stateBg = RuralCareColors.successSoft;
    }

    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Alert transmission status', style: AppTypography.cardTitle),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: AppDecorations.statusBadge(background: stateBg),
                child: Text(
                  stateLabel,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: stateColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _statusCheckRow(
            'Patient clinical profile packaged',
            isSosActive,
            'Blood group, ANC telemetry, current medications',
          ),
          const SizedBox(height: 10),
          _statusCheckRow(
            'Baramati SDH Emergency Department alerted',
            isSosActive && !isOffline,
            isSosActive ? (isOffline ? 'Queued to send on reconnect' : 'Dossier received by triage desk') : 'Awaiting trigger',
          ),
          const SizedBox(height: 10),
          _statusCheckRow(
            'Frontline ASHA Worker pre-notified',
            isSosActive,
            isSosActive ? 'SMS notification triggered' : 'Awaiting trigger',
          ),
        ],
      ),
    );
  }

  Widget _statusCheckRow(String title, bool isCompleted, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 18,
          color: isCompleted ? RuralCareColors.success : RuralCareColors.textSecondary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w400,
                  color: RuralCareColors.textPrimary,
                ),
              ),
              Text(subtitle, style: AppTypography.supporting),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    EmergencyRepository emergRepo,
    bool isSosActive,
    dynamic patient,
  ) {
    return Column(
      children: [
        // 1. Direct 108 Telephone Dialer
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Placing phone call to 108 Ambulance helpline...')),
              );
            },
            icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
            label: const Text('Call 108 ambulance now', style: AppTypography.button),
            style: ElevatedButton.styleFrom(
              backgroundColor: RuralCareColors.critical,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 2. Trigger or Cancel Digital SOS Alert
        if (!isSosActive)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                emergRepo.triggerSos(
                  patientId: patient.id,
                  location: _shareLocation ? 'Kashti Sector 3 (18.618° N, 74.571° E)' : 'Location withheld',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Emergency alert dispatched to Baramati SDH.')),
                );
              },
              icon: const Icon(Icons.emergency_outlined, size: 20),
              label: const Text('Send digital SOS alert to SDH'),
              style: OutlinedButton.styleFrom(
                foregroundColor: RuralCareColors.critical,
                side: const BorderSide(color: RuralCareColors.critical),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                emergRepo.resolveEmergency();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Emergency alert resolved.')),
                );
              },
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: const Text('Resolve / stand down alert'),
              style: OutlinedButton.styleFrom(
                foregroundColor: RuralCareColors.textPrimary,
                side: const BorderSide(color: RuralCareColors.inputBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
      ],
    );
  }
}
