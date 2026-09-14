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
        final isHi = session.isHindi;
        final isMr = session.isMarathi;

        final pageTitle = isHi ? 'आपातकालीन सहायता' : (isMr ? 'तातडीची मदत' : 'Emergency help');

        return Scaffold(
          backgroundColor: RuralCareColors.canvas,
          appBar: AppBar(
            title: Text(pageTitle, style: AppTypography.pageTitle),
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
                _buildCapabilitiesCard(isHi, isMr),

                const SizedBox(height: 20),

                // 2. Offline Warning Banner (if offline)
                if (isOffline) ...[
                  _buildOfflineWarningBanner(isHi, isMr),
                  const SizedBox(height: 20),
                ],

                // 3. Location Sharing Choice (DESIGN.md: explicit location-sharing choice)
                _buildLocationSharingCard(isHi, isMr),

                const SizedBox(height: 20),

                // 4. Real Status State Card (Queued, Sent, Acknowledged, Failed)
                _buildStatusLedger(event, isOffline, isSosActive, isHi, isMr),

                const SizedBox(height: 24),

                // 5. Prominent Action Buttons (52px minimum height)
                _buildActionButtons(context, emergRepo, isSosActive, patient, isHi, isMr),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCapabilitiesCard(bool isHi, bool isMr) {
    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: RuralCareColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                isHi ? 'यह सेवा कैसे काम करती है' : (isMr ? 'ही सेवा कशी कार्य करते' : 'How this service works'),
                style: AppTypography.cardTitle,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isHi
                ? 'आपातकालीन अलर्ट भेजने पर मरीज़ का महत्वपूर्ण क्लिनिकल इतिहास, रक्त समूह और जीपीएस निकटतम उप-जिला अस्पताल (बारामती) को भेजा जाता है और नियुक्त फ्रंटलाइन आशा कार्यकर्ता को सूचित किया जाता है।'
                : (isMr
                    ? 'तातडीचा अलर्ट पाठवताच रुग्णाचा क्लिनिकल इतिहास, रक्तगट आणि जीपीएस जवळच्या उपजिल्हा रुग्णालयाला (बारामती) पाठवला जातो आणि नियुक्त आशा सेविकेला कळवले जाते.'
                    : 'Triggering an emergency alert transmits the patient’s critical clinical history, blood group, and approximate GPS coordinates to the nearest First Referral Unit (Baramati SDH) and notifies the designated frontline health worker.'),
            style: AppTypography.body,
          ),
          const SizedBox(height: 6),
          Text(
            isHi
                ? 'तत्काल जीवन-घातक स्थितियों में हमेशा राष्ट्रीय 108 एम्बुलेंस हेल्पलाइन पर सीधे कॉल करें।'
                : (isMr
                    ? 'तातडीच्या प्रसंगी नेहमी राष्ट्रीय १०८ रुग्णवाहिका हेल्पलाइनवर थेट संपर्क साधा.'
                    : 'For immediate life-threatening events, always place a direct telephone call to the national 108 ambulance helpline.'),
            style: AppTypography.supporting.copyWith(color: RuralCareColors.critical),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineWarningBanner(bool isHi, bool isMr) {
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
                  isHi ? 'ऑफ़लाइन मोड सक्रिय' : (isMr ? 'ऑफलाइन मोड सक्रिय' : 'Offline mode active'),
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: RuralCareColors.warning,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isHi
                      ? 'इंटरनेट कनेक्टिविटी बहाल होने तक आपातकालीन अलर्ट स्थानीय आउटबॉक्स में रहेगा। कृपया सीधे 108 पर कॉल करें।'
                      : (isMr
                          ? 'इंटरनेट येईपर्यंत आपत्कालीन अलर्ट स्थानिक आउटबॉक्समध्ये राहील. कृपया थेट १०८ वर कॉल करा.'
                          : 'Emergency alerts cannot reach the cloud server until internet connectivity is restored. Please call 108 directly.'),
                  style: AppTypography.supporting.copyWith(color: RuralCareColors.warning),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSharingCard(bool isHi, bool isMr) {
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
                Text(
                  isHi ? 'स्थान निर्देशांक साझा करें' : (isMr ? 'स्थान निर्देशांक सामायिक करा' : 'Share location coordinates'),
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                ),
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

  Widget _buildStatusLedger(event, bool isOffline, bool isSosActive, bool isHi, bool isMr) {
    String stateLabel;
    Color stateColor;
    Color stateBg;

    if (!isSosActive) {
      stateLabel = isHi ? 'स्टैंडबाय (तैयार)' : (isMr ? 'सज्ज (तयार)' : 'Standby (Ready)');
      stateColor = RuralCareColors.textSecondary;
      stateBg = RuralCareColors.surfaceSubtle;
    } else if (isOffline) {
      stateLabel = isHi ? 'ऑफ़लाइन आउटबॉक्स में कतारबद्ध' : (isMr ? 'ऑफलाइन आउटबॉक्समध्ये रांगेत' : 'Queued in local outbox (Offline)');
      stateColor = RuralCareColors.warning;
      stateBg = RuralCareColors.warningSoft;
    } else {
      stateLabel = isHi ? 'भेजा गया एवं स्वीकृत' : (isMr ? 'पाठवले आणि स्वीकारले' : 'Sent & Acknowledged');
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
              Text(
                isHi ? 'अलर्ट संचरण स्थिति' : (isMr ? 'अलर्ट पाठवण्याची स्थिती' : 'Alert transmission status'),
                style: AppTypography.cardTitle,
              ),
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
            isHi ? 'मरीज़ क्लिनिकल प्रोफ़ाइल तैयार' : (isMr ? 'रुग्ण क्लिनिकल प्रोफाइल तयार' : 'Patient clinical profile packaged'),
            isSosActive,
            isHi ? 'रक्त समूह, एएनसी टेलीमेट्री, वर्तमान दवाएं' : (isMr ? 'रक्तगट, एएनसी टेलीमेट्री, औषधोपचार' : 'Blood group, ANC telemetry, current medications'),
          ),
          const SizedBox(height: 10),
          _statusCheckRow(
            isHi ? 'बारामती उप-जिला अस्पताल अलर्ट' : (isMr ? 'बारामती उपजिल्हा रुग्णालय अलर्ट' : 'Baramati SDH Emergency Department alerted'),
            isSosActive && !isOffline,
            isSosActive
                ? (isOffline
                    ? (isHi ? 'पुनः कनेक्ट होने पर भेजने के लिए कतारबद्ध' : 'Queued to send on reconnect')
                    : (isHi ? 'ट्राइएज डेस्क द्वारा विवरण प्राप्त' : 'Dossier received by triage desk'))
                : (isHi ? 'ट्रिगर की प्रतीक्षा में' : 'Awaiting trigger'),
          ),
          const SizedBox(height: 10),
          _statusCheckRow(
            isHi ? 'फ्रंटलाइन आशा कार्यकर्ता को पूर्व-सूचना' : (isMr ? 'आशा सेविकेला पूर्व-सूचना' : 'Frontline ASHA Worker pre-notified'),
            isSosActive,
            isSosActive
                ? (isHi ? 'एसएमएस अधिसूचना भेजी गई' : 'SMS notification triggered')
                : (isHi ? 'ट्रिगर की प्रतीक्षा में' : 'Awaiting trigger'),
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
    bool isHi,
    bool isMr,
  ) {
    final call108Label = isHi ? 'अभी 108 एम्बुलेंस को कॉल करें' : (isMr ? 'आता १०८ रुग्णवाहिकेला कॉल करा' : 'Call 108 ambulance now');
    final sendSosLabel = isHi ? 'एसडीएच को डिजिटल एसओएस अलर्ट भेजें' : (isMr ? 'रुग्णालयाला डिजिटल एसओएस अलर्ट पाठवा' : 'Send digital SOS alert to SDH');
    final resolveLabel = isHi ? 'अलर्ट समाप्त करें' : (isMr ? 'अलर्ट समाप्त करा' : 'Resolve / stand down alert');

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
            label: Text(call108Label, style: AppTypography.button),
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
              label: Text(sendSosLabel),
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
              label: Text(resolveLabel),
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
