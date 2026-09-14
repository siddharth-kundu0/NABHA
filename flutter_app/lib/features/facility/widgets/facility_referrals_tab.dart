import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/repositories/referral_repository.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';
import 'package:ruralcare/data/repositories/doctor_repository.dart';
import 'package:ruralcare/data/models/referral_dto.dart';
import 'package:ruralcare/features/facility/utils/facility_strings.dart';
import 'package:ruralcare/app/routes.dart';

/// Referral Coordination Desk Tab (Stitch Screen 4 & Flow 22)
/// Fully expanded end-to-end referral workflow:
/// 1. Prioritized Inbound Queue (Emergencies top-ranked).
/// 2. Clinical Validation & Pre-transfer Vitals Telemetry.
/// 3. Facility Capability Check Matrix (Beds, Specialists, Diagnostics, Blood Bank).
/// 4. 3 Decision Paths: Accept & Specific Resource Reservation, Re-route, or Reject.
/// 5. Live 108 Ambulance Tracking with Overdue Delay Escalation.
/// 6. Fast-Track Token Arrival Check-In Linkage.
/// 7. Attending Clinical Handoff Sheet.
/// 8. Post-Arrival Disposition (Admit, Treat, Counter-Refer, Escalate).
/// 9. Formal Counter-Referral Care Plan to Sub-Centre/PHC with Red Flags.
class FacilityReferralsTab extends StatefulWidget {
  const FacilityReferralsTab({super.key});

  @override
  State<FacilityReferralsTab> createState() => _FacilityReferralsTabState();
}

class _FacilityReferralsTabState extends State<FacilityReferralsTab> {
  bool _isInbound = true;

  @override
  Widget build(BuildContext context) {
    final session = SessionCoordinator();
    final refRepo = ReferralRepository();
    final facRepo = FacilityRepository();

    return ListenableBuilder(
      listenable: Listenable.merge([refRepo, facRepo, session]),
      builder: (context, _) {
        final strings = FacilityStrings.of(session);
        final allReferrals = refRepo.referrals;

        // Separate inbound vs outbound dynamically from repository
        final inboundRefs = allReferrals.where((r) {
          return r.targetFacilityId == 'FAC-SDH-301' ||
              r.targetFacilityName.toLowerCase().contains('baramati') ||
              r.targetFacilityName.toLowerCase().contains('sdh') ||
              !r.referringFacility.toLowerCase().contains('baramati');
        }).toList();

        // Sort inbound referrals: EMERGENCY first, then URGENT, then latest created
        inboundRefs.sort((a, b) {
          if (a.isEmergency && !b.isEmergency) return -1;
          if (!a.isEmergency && b.isEmergency) return 1;
          if (a.isUrgent && !b.isUrgent) return -1;
          if (!a.isUrgent && b.isUrgent) return 1;
          return b.createdAt.compareTo(a.createdAt);
        });

        final outboundRefs = allReferrals.where((r) {
          return r.referringFacility.toLowerCase().contains('baramati') ||
              r.targetFacilityId == 'FAC-DH-401' ||
              r.targetFacilityId == 'FAC-CHC-201';
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Connectivity Status Banner
              _buildConnectivityBanner(strings),

              const SizedBox(height: 14),

              // 2. Screen Identity & Live Transit Quick Counters
              _buildHeaderSnapshot(context, strings, inboundRefs.length, outboundRefs.length),

              const SizedBox(height: 16),

              // 3. Stream Direction Switcher (Inbound / Outbound)
              _buildStreamSwitcher(strings, inboundRefs.length, outboundRefs.length),

              const SizedBox(height: 18),

              // 4. Stream Cards
              if (_isInbound)
                _buildInboundSection(context, refRepo, facRepo, inboundRefs, strings)
              else
                _buildOutboundSection(context, refRepo, facRepo, outboundRefs, strings),

              const SizedBox(height: 24),

              // 5. Create Outbound Referral CTA
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateOutboundModal(context, refRepo, facRepo, strings),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                  label: Text(
                    strings.createOutbound,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RuralCareColors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectivityBanner(FacilityStrings strings) {
    return Container(
      decoration: BoxDecoration(
        color: RuralCareColors.tealSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RuralCareColors.teal.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: RuralCareColors.teal,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              strings.isHi
                  ? 'स्थानीय रूप से सुरक्षित • क्लिनिकल रेफरल समन्वय (PHC / SDH / DH)'
                  : (strings.isMr
                      ? 'स्थानिक सुरक्षित • क्लिनिकल संदर्भ समन्वय (PHC / SDH / DH)'
                      : 'Saved locally • Clinical Referral Coordination (PHC / SDH / DH)'),
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: RuralCareColors.teal,
              ),
            ),
          ),
          const Icon(Icons.cloud_done_rounded, color: RuralCareColors.teal, size: 18),
        ],
      ),
    );
  }

  Widget _buildHeaderSnapshot(BuildContext context, FacilityStrings strings, int inCount, int outCount) {
    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.referralCoordination, style: AppTypography.sectionTitle),
                  const SizedBox(height: 2),
                  const Text('Sub-District Referral Desk • Baramati SDH', style: AppTypography.supporting),
                ],
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: RuralCareColors.tealSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.swap_horiz_rounded, color: RuralCareColors.teal, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: RuralCareColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: RuralCareColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inbox_rounded, color: RuralCareColors.teal, size: 20),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strings.inbound, style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary)),
                          Text(
                            '$inCount Active',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: RuralCareColors.teal),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: RuralCareColors.warningSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: RuralCareColors.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.outbox_rounded, color: RuralCareColors.warning, size: 20),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strings.outbound, style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary)),
                          Text(
                            '$outCount Tracked',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: RuralCareColors.warning),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreamSwitcher(FacilityStrings strings, int inCount, int outCount) {
    return Container(
      decoration: BoxDecoration(
        color: RuralCareColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RuralCareColors.border),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _isInbound = true),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isInbound ? RuralCareColors.teal : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.south_west_rounded, size: 16, color: _isInbound ? Colors.white : RuralCareColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      '${strings.inbound} ($inCount)',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: _isInbound ? FontWeight.w700 : FontWeight.w500,
                        color: _isInbound ? Colors.white : RuralCareColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _isInbound = false),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isInbound ? RuralCareColors.teal : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.north_east_rounded, size: 16, color: !_isInbound ? Colors.white : RuralCareColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      '${strings.outbound} ($outCount)',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: !_isInbound ? FontWeight.w700 : FontWeight.w500,
                        color: !_isInbound ? Colors.white : RuralCareColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInboundSection(
    BuildContext context,
    ReferralRepository refRepo,
    FacilityRepository facRepo,
    List<ReferralDto> inboundRefs,
    FacilityStrings strings,
  ) {
    if (inboundRefs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        decoration: AppDecorations.card(),
        child: const Text('No inbound referrals pending review.', style: AppTypography.supporting),
      );
    }

    return Column(
      children: inboundRefs.map((r) {
        final isEmergency = r.isEmergency;
        final isUrgent = r.isUrgent;
        final isAccepted = r.status == 'ACCEPTED' || r.status == 'RESOURCE_RESERVED';
        final isInTransit = r.status == 'IN_TRANSIT' || r.status == 'PATIENT_EN_ROUTE';
        final isArrived = r.status == 'ARRIVED' || r.status == 'PATIENT_ARRIVED';
        final isCheckedIn = r.status == 'CHECKED_IN' || r.status == 'UNDER_EVALUATION';
        final isCounterReferred = r.status == 'COUNTER_REFERRED';

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: RuralCareColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEmergency
                  ? RuralCareColors.critical
                  : (isUrgent ? const Color(0xFFD97706) : RuralCareColors.border),
              width: isEmergency ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Priority Indicator Stripe
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: isEmergency
                      ? RuralCareColors.critical
                      : (isUrgent ? const Color(0xFFD97706) : RuralCareColors.teal),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                ),
              ),

              // Emergency Banner
              if (isEmergency)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  color: RuralCareColors.criticalSoft,
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 16, color: RuralCareColors.critical),
                      SizedBox(width: 6),
                      Text(
                        'HIGH PRIORITY EMERGENCY CASE • FAST-TRACK TRIAGE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: RuralCareColors.critical,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: isEmergency
                                  ? RuralCareColors.criticalSoft
                                  : (isUrgent ? const Color(0xFFFEF3C7) : RuralCareColors.tealSoft),
                              child: Text(
                                r.patientName.isNotEmpty ? r.patientName.substring(0, 1) : 'P',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isEmergency
                                      ? RuralCareColors.critical
                                      : (isUrgent ? const Color(0xFFB45309) : RuralCareColors.teal),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.patientName, style: AppTypography.cardTitle),
                                Text(
                                  'Age ${r.patientAge} • ${r.patientGender} • ${r.patientVillage} (${r.id})',
                                  style: AppTypography.supporting,
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: AppDecorations.statusBadge(
                            background: isEmergency
                                ? RuralCareColors.criticalSoft
                                : (isUrgent ? const Color(0xFFFEF3C7) : RuralCareColors.tealSoft),
                          ),
                          child: Text(
                            r.urgency,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isEmergency
                                  ? RuralCareColors.critical
                                  : (isUrgent ? const Color(0xFFB45309) : RuralCareColors.teal),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Specialty & Reason Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isEmergency
                            ? RuralCareColors.criticalSoft.withOpacity(0.3)
                            : RuralCareColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isEmergency
                              ? RuralCareColors.critical.withOpacity(0.2)
                              : RuralCareColors.border,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isEmergency ? Icons.emergency : Icons.medical_services_outlined,
                                size: 14,
                                color: isEmergency ? RuralCareColors.critical : RuralCareColors.teal,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'REQUIRED: ${r.requiredSpecialty.toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isEmergency ? RuralCareColors.critical : RuralCareColors.teal,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            r.reasonSummary,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.near_me_outlined, size: 12, color: RuralCareColors.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'From: ${r.referringFacility} (${r.referringProviderName}, ${r.referringProviderRole})',
                                  style: AppTypography.supporting,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Pre-transfer Vitals Strip (if available)
                    if (r.vitals != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _vitalsItem('BP', '${r.vitals!.systolicBp}/${r.vitals!.diastolicBp}', r.vitals!.systolicBp >= 140),
                            _vitalsItem('SpO2', '${r.vitals!.spO2}%', r.vitals!.spO2 < 92),
                            _vitalsItem('Pulse', '${r.vitals!.pulse} bpm', r.vitals!.pulse > 100),
                            _vitalsItem('Hb', '${r.vitals!.haemoglobin} g/dL', r.vitals!.haemoglobin < 8.0),
                          ],
                        ),
                      ),
                    ],

                    // Resource Reservation Strip (if accepted)
                    if (r.bedReservation != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.hotel_outlined, size: 16, color: Color(0xFF15803D)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Reserved: ${r.bedReservation!.wardUnit} (${r.bedReservation!.bedType}) • Specialist: ${r.bedReservation!.assignedSpecialist}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Overdue Delay Escalation Banner
                    if (r.isOverdue) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.access_time_filled, size: 16, color: Color(0xFFB91C1C)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Arrival Delayed — Expected transit exceeded! Transport coordinator / referring Sub-Centre should be contacted immediately.',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    _buildLifecycleStepper(r.currentStage),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Status: ${r.statusDisplay}',
                          style: AppTypography.supporting.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (r.checkInToken != null)
                          Text(
                            'Token: ${r.checkInToken}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RuralCareColors.teal),
                          ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Contextual Action Buttons
                    Row(
                      children: [
                        // Primary Action Button
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (r.status == 'REFERRED' || r.status == 'CREATED' || r.status == 'TRIAGED') {
                                _showClinicalReferralDossier(context, r, refRepo, facRepo, strings);
                              } else if (isAccepted || isInTransit) {
                                refRepo.acknowledgeArrival(r.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Patient ${r.patientName} arrival acknowledged at reception.'),
                                    backgroundColor: RuralCareColors.teal,
                                  ),
                                );
                              } else if (isArrived) {
                                _showFastTrackTokenCheckInDialog(context, r, refRepo, strings);
                              } else if (isCheckedIn) {
                                _showClinicalHandoffModal(context, r, refRepo, strings);
                              } else if (isCounterReferred) {
                                refRepo.closeReferral(r.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Referral case ${r.id} officially closed.'),
                                    backgroundColor: RuralCareColors.teal,
                                  ),
                                );
                              }
                            },
                            icon: Icon(
                              (r.status == 'REFERRED' || r.status == 'CREATED' || r.status == 'TRIAGED')
                                  ? Icons.fact_check_outlined
                                  : (isAccepted || isInTransit
                                      ? Icons.pin_drop_outlined
                                      : (isArrived
                                          ? Icons.qr_code_scanner
                                          : (isCheckedIn ? Icons.assignment_ind_outlined : Icons.done_all))),
                              size: 16,
                            ),
                            label: Text(
                              (r.status == 'REFERRED' || r.status == 'CREATED' || r.status == 'TRIAGED')
                                  ? 'Validate & Accept'
                                  : (isAccepted || isInTransit
                                      ? 'Acknowledge Arrival'
                                      : (isArrived
                                          ? 'Fast-Track Check-In'
                                          : (isCheckedIn
                                              ? 'Clinical Handoff & Disposition'
                                              : (isCounterReferred ? 'Close Referral' : 'Case Completed')))),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isEmergency ? RuralCareColors.critical : RuralCareColors.teal,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size(0, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Secondary Action Button
                        Expanded(
                          flex: 2,
                          child: OutlinedButton(
                            onPressed: () {
                              if (isCheckedIn) {
                                _showCounterReferralModal(context, r, refRepo, strings);
                              } else {
                                _showClinicalReferralDossier(context, r, refRepo, facRepo, strings);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: RuralCareColors.teal,
                              side: const BorderSide(color: RuralCareColors.border),
                              minimumSize: const Size(0, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              isCheckedIn ? 'Counter-Refer' : strings.viewReferralDetails,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _vitalsItem(String label, String value, bool isAbnormal) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: RuralCareColors.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isAbnormal ? RuralCareColors.critical : RuralCareColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildOutboundSection(
    BuildContext context,
    ReferralRepository refRepo,
    FacilityRepository facRepo,
    List<ReferralDto> outboundRefs,
    FacilityStrings strings,
  ) {
    if (outboundRefs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        decoration: AppDecorations.card(),
        child: const Text('No outbound referrals logged.', style: AppTypography.supporting),
      );
    }

    return Column(
      children: outboundRefs.map((r) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: AppDecorations.card(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: RuralCareColors.warningSoft,
                        child: Text(
                          r.patientName.isNotEmpty ? r.patientName.substring(0, 1) : 'O',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: RuralCareColors.warning),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.patientName, style: AppTypography.cardTitle),
                          Text('${r.id} • ${r.patientId}', style: AppTypography.supporting),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: AppDecorations.statusBadge(background: RuralCareColors.warningSoft),
                    child: Text(
                      r.statusDisplay,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RuralCareColors.warning),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RuralCareColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: RuralCareColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_hospital_rounded, size: 16, color: RuralCareColors.teal),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            r.targetFacilityName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(r.reasonSummary, style: AppTypography.body),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildLifecycleStepper(r.currentStage),
              const SizedBox(height: 8),
              Text(
                r.transportDetails != null
                    ? 'Transport: ${r.transportDetails!.vehicleId ?? "108 Ambulance"} (${r.transportDetails!.transportStatus})'
                    : 'Transport: Arranged via 108 Ambulance / Escort Staff',
                style: AppTypography.supporting,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showClinicalReferralDossier(context, r, refRepo, facRepo, strings),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: RuralCareColors.teal,
                    side: const BorderSide(color: RuralCareColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(strings.viewReferralDetails),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLifecycleStepper(int currentStage) {
    final stages = ['Created', 'Triaged', 'Accepted', 'En Route', 'Arrived', 'Complete'];

    return Row(
      children: List.generate(stages.length * 2 - 1, (index) {
        if (index.isOdd) {
          final step = index ~/ 2;
          final isPast = step < currentStage;
          return Expanded(
            child: Container(
              height: 2,
              color: isPast ? RuralCareColors.teal : RuralCareColors.border,
            ),
          );
        } else {
          final step = index ~/ 2;
          final isDone = step <= currentStage;
          return Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isDone ? RuralCareColors.teal : RuralCareColors.surfaceSubtle,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDone ? RuralCareColors.teal : RuralCareColors.border,
                  ),
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 2),
              Text(
                stages[step],
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                  color: isDone ? RuralCareColors.teal : RuralCareColors.textSecondary,
                ),
              ),
            ],
          );
        }
      }),
    );
  }

  // 1. Clinical Referral Dossier & Decision Desk
  void _showClinicalReferralDossier(
    BuildContext context,
    ReferralDto r,
    ReferralRepository refRepo,
    FacilityRepository facRepo,
    FacilityStrings strings,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final facility = facRepo.facilities.firstWhere(
          (f) => f.id == 'FAC-SDH-301',
          orElse: () => facRepo.facilities.first,
        );

        // Capability checks
        final hasBed = facility.availableBeds > 0;
        final hasSpecialist = facility.onDutySpecialists.any((s) =>
            s.toLowerCase().contains(r.requiredSpecialty.toLowerCase()) ||
            (r.requiredSpecialty.toLowerCase().contains('obstetric') && s.toLowerCase().contains('obstetric')) ||
            (r.requiredSpecialty.toLowerCase().contains('pulmonolog') && s.toLowerCase().contains('pulmonolog')));
        final hasDiagnostics = r.requiredResources.isEmpty ||
            facility.availableDiagnostics.isNotEmpty;
        final bloodNeeded = r.bloodUnitsRequired;
        bool hasBlood = true;
        if (bloodNeeded.isNotEmpty) {
          for (final entry in bloodNeeded.entries) {
            if ((facility.availableBloodUnits[entry.key] ?? 0) < entry.value) {
              hasBlood = false;
              break;
            }
          }
        }

        return Container(
          decoration: const BoxDecoration(
            color: RuralCareColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.assignment_outlined, color: RuralCareColors.teal),
                        const SizedBox(width: 8),
                        Text('Referral Dossier: ${r.id}', style: AppTypography.sectionTitle),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(),

                // Patient Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r.patientName, style: AppTypography.cardTitle.copyWith(fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: AppDecorations.statusBadge(
                        background: r.isEmergency ? RuralCareColors.criticalSoft : RuralCareColors.tealSoft,
                      ),
                      child: Text(
                        r.urgency,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: r.isEmergency ? RuralCareColors.critical : RuralCareColors.teal,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Age ${r.patientAge} • ${r.patientGender} • Phone: ${r.patientPhone} • Village: ${r.patientVillage}',
                  style: AppTypography.supporting,
                ),
                Text('Referring Center: ${r.referringFacility} (${r.referringProviderName})', style: AppTypography.supporting),
                const SizedBox(height: 12),

                // Clinical Reason & Required Resources
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: RuralCareColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: RuralCareColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Clinical Reason for Transfer:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(r.reason, style: AppTypography.body),
                      const SizedBox(height: 8),
                      const Text('Required Specialty & Resources:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('• Specialty: ${r.requiredSpecialty}', style: AppTypography.supporting),
                      ...r.requiredResources.map((res) => Text('• $res', style: AppTypography.supporting)),
                      if (r.bloodUnitsRequired.isNotEmpty)
                        Text('• Blood Required: ${r.bloodUnitsRequired.entries.map((e) => "${e.value} units ${e.key}").join(", ")}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB91C1C), fontSize: 12)),
                    ],
                  ),
                ),

                // Pre-Transfer Vitals
                if (r.vitals != null) ...[
                  const SizedBox(height: 14),
                  const Text('Pre-Transfer Field Vitals (Transmitted by Frontline Worker):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _vitalsDetail('Blood Pressure', '${r.vitals!.systolicBp}/${r.vitals!.diastolicBp} mmHg', r.vitals!.systolicBp >= 140),
                            _vitalsDetail('SpO2', '${r.vitals!.spO2}%', r.vitals!.spO2 < 92),
                            _vitalsDetail('Pulse', '${r.vitals!.pulse} bpm', r.vitals!.pulse > 100),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _vitalsDetail('Haemoglobin', '${r.vitals!.haemoglobin} g/dL', r.vitals!.haemoglobin < 8.0),
                            _vitalsDetail('Blood Sugar', '${r.vitals!.bloodSugar} mg/dL', r.vitals!.bloodSugar >= 180),
                            _vitalsDetail('Temperature', '${r.vitals!.temperature}°F', r.vitals!.temperature >= 101.0),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Facility Capability Check Matrix
                const Text('Receiving Facility Capability Verification:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    children: [
                      _capabilityRow('Bed Capacity', '${facility.availableBeds} beds available in facility', hasBed),
                      _capabilityRow('Required Specialist', 'On-duty: ${facility.onDutySpecialists.join(", ")}', hasSpecialist),
                      _capabilityRow('Diagnostic Capability', 'Verified: ${facility.availableDiagnostics.take(4).join(", ")}', hasDiagnostics),
                      if (r.bloodUnitsRequired.isNotEmpty)
                        _capabilityRow(
                          'Blood Bank Availability',
                          'Units On-Hand: ${r.bloodUnitsRequired.keys.map((k) => "$k: ${facility.availableBloodUnits[k] ?? 0}u").join(", ")}',
                          hasBlood,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Decision Action Buttons
                const Text('Coordination Decision:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),

                Row(
                  children: [
                    // Accept & Reserve Resources
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showResourceReservationSheet(context, r, refRepo, facRepo, strings);
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Accept & Reserve', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RuralCareColors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Re-Route
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showRerouteModal(context, r, refRepo, strings);
                        },
                        icon: const Icon(Icons.alt_route, size: 14),
                        label: const Text('Re-Route', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFD97706),
                          side: const BorderSide(color: Color(0xFFD97706)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Reject
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showRejectModal(context, r, refRepo, strings);
                        },
                        icon: const Icon(Icons.cancel_outlined, size: 14),
                        label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: RuralCareColors.critical,
                          side: const BorderSide(color: RuralCareColors.critical),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _vitalsDetail(String label, String val, bool isAlert) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: RuralCareColors.textSecondary)),
        const SizedBox(height: 2),
        Text(
          val,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isAlert ? RuralCareColors.critical : RuralCareColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _capabilityRow(String label, String value, bool isCapable) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isCapable ? Icons.check_circle : Icons.warning_amber_rounded,
            size: 16,
            color: isCapable ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF166534))),
                Text(value, style: const TextStyle(fontSize: 11, color: Color(0xFF14532D))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Resource Reservation Sheet
  void _showResourceReservationSheet(
    BuildContext context,
    ReferralDto r,
    ReferralRepository refRepo,
    FacilityRepository facRepo,
    FacilityStrings strings,
  ) {
    String selectedWard = r.requiredSpecialty.toLowerCase().contains('obstetric')
        ? 'Maternity Wing - Room 1'
        : (r.isEmergency ? 'Emergency Room (ER Suite 1)' : 'General Medical Ward');
    String selectedBedType = r.requiredSpecialty.toLowerCase().contains('obstetric')
        ? 'MCH High Dependency Bed'
        : (r.isEmergency ? 'Emergency Resuscitation Bay' : 'General Inpatient Bed');
    String selectedSpecialist = r.requiredSpecialty.toLowerCase().contains('obstetric')
        ? 'Dr. Anjali Rao (OB/GYN)'
        : 'Dr. Anita Roy (Emergency MO)';
    bool reserveBlood = r.bloodUnitsRequired.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: RuralCareColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.hotel_class, color: RuralCareColors.teal),
                      SizedBox(width: 8),
                      Text('Specific Resource Reservation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              Text('Patient: ${r.patientName} (${r.id})', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Ward Unit
              const Text('Assigned Ward / Unit:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: selectedWard,
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: const [
                  DropdownMenuItem(value: 'Maternity Wing - Room 1', child: Text('Maternity Wing - Room 1 (MCH)')),
                  DropdownMenuItem(value: 'Emergency Room (ER Suite 1)', child: Text('Emergency Room (ER Suite 1)')),
                  DropdownMenuItem(value: 'General Medical Ward', child: Text('General Medical Ward')),
                  DropdownMenuItem(value: 'NCD Observation Ward', child: Text('NCD Observation Ward')),
                ],
                onChanged: (v) => setSheetState(() => selectedWard = v ?? selectedWard),
              ),

              const SizedBox(height: 10),

              // Bed Type
              const Text('Bed Classification:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: selectedBedType,
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: const [
                  DropdownMenuItem(value: 'MCH High Dependency Bed', child: Text('MCH High Dependency Bed')),
                  DropdownMenuItem(value: 'Emergency Resuscitation Bay', child: Text('Emergency Resuscitation Bay')),
                  DropdownMenuItem(value: 'General Inpatient Bed', child: Text('General Inpatient Bed')),
                  DropdownMenuItem(value: 'Isolation Bed', child: Text('Isolation Bed')),
                ],
                onChanged: (v) => setSheetState(() => selectedBedType = v ?? selectedBedType),
              ),

              const SizedBox(height: 10),

              // Assigned Specialist
              const Text('Assigned On-Duty Specialist:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: selectedSpecialist,
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: const [
                  DropdownMenuItem(value: 'Dr. Anjali Rao (OB/GYN)', child: Text('Dr. Anjali Rao (OB/GYN)')),
                  DropdownMenuItem(value: 'Dr. Anita Roy (Emergency MO)', child: Text('Dr. Anita Roy (Emergency MO)')),
                  DropdownMenuItem(value: 'Dr. Vinod Gaikwad (Pediatrician)', child: Text('Dr. Vinod Gaikwad (Pediatrician)')),
                  DropdownMenuItem(value: 'Dr. Sanjay Kadam (General Surgeon)', child: Text('Dr. Sanjay Kadam (General Surgeon)')),
                ],
                onChanged: (v) => setSheetState(() => selectedSpecialist = v ?? selectedSpecialist),
              ),

              if (r.bloodUnitsRequired.isNotEmpty) ...[
                const SizedBox(height: 10),
                CheckboxListTile(
                  title: Text(
                    'Reserve Blood Bank Units: ${r.bloodUnitsRequired.entries.map((e) => "${e.value}u ${e.key}").join(", ")}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
                  ),
                  subtitle: const Text('Will lock refrigerated units in blood bank ledger exclusively for this referral.', style: TextStyle(fontSize: 11)),
                  value: reserveBlood,
                  activeColor: const Color(0xFFB91C1C),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setSheetState(() => reserveBlood = v ?? false),
                ),
              ],

              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final reservation = BedReservationDto(
                      bedType: selectedBedType,
                      wardUnit: selectedWard,
                      assignedSpecialist: selectedSpecialist,
                      reservedEquipment: r.requiredResources,
                      reservationStatus: 'RESERVED',
                      reservedAt: DateTime.now(),
                      bedNumber: 'BED-${DateTime.now().millisecondsSinceEpoch % 50 + 1}',
                    );

                    refRepo.acceptReferral(
                      r.id,
                      reservation: reservation,
                      bloodUnitsToReserve: reserveBlood ? r.bloodUnitsRequired : null,
                    );

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Referral ${r.id} accepted. $selectedWard ($selectedBedType) reserved.'),
                        backgroundColor: RuralCareColors.teal,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Confirm & Notify Referring Facility', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RuralCareColors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. Fast-Track Arrival Token Check-In
  void _showFastTrackTokenCheckInDialog(
    BuildContext context,
    ReferralDto r,
    ReferralRepository refRepo,
    FacilityStrings strings,
  ) {
    final tokenCtrl = TextEditingController(text: r.id);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.qr_code_scanner, color: RuralCareColors.teal),
            const SizedBox(width: 8),
            Text(strings.fastTrackCheckin, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scan or enter arriving referral pass for ${r.patientName}:'),
            const SizedBox(height: 10),
            TextField(
              controller: tokenCtrl,
              decoration: const InputDecoration(labelText: 'Referral / Token ID', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(strings.cancel)),
          ElevatedButton(
            onPressed: () {
              final checked = refRepo.checkInReferralByToken(tokenCtrl.text.trim());
              Navigator.pop(ctx);
              if (checked != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Patient ${checked.patientName} checked in. Token: ${checked.checkInToken}.'),
                    backgroundColor: RuralCareColors.teal,
                    action: SnackBarAction(
                      label: 'Clinical Handoff',
                      textColor: Colors.white,
                      onPressed: () => _showClinicalHandoffModal(context, checked, refRepo, strings),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: RuralCareColors.teal, foregroundColor: Colors.white),
            child: const Text('Complete Check-In'),
          ),
        ],
      ),
    );
  }

  // 4. Clinical Handoff Modal
  void _showClinicalHandoffModal(
    BuildContext context,
    ReferralDto r,
    ReferralRepository refRepo,
    FacilityStrings strings,
  ) {
    final doctorCtrl = TextEditingController(text: DoctorRepository().registeredDoctors.isNotEmpty ? DoctorRepository().registeredDoctors.first.name : 'Dr. Anita Roy');
    final notesCtrl = TextEditingController(
      text: 'Patient assessed on arrival. Vitals stable under observation. IV line patent.',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: RuralCareColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.assignment_ind, color: RuralCareColors.teal),
                      SizedBox(width: 8),
                      Text('Clinical Handoff & Disposition', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              Text('Beneficiary: ${r.patientName} (${r.id})', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Referring Center: ${r.referringFacility} (${r.referringProviderName})', style: AppTypography.supporting),
              const SizedBox(height: 10),

              // Continuity dossier card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: RuralCareColors.surfaceSubtle, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Transferred Clinical Information:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('• Reason: ${r.reason}', style: AppTypography.supporting),
                    if (r.vitals != null)
                      Text('• Field Vitals: BP ${r.vitals!.systolicBp}/${r.vitals!.diastolicBp}, SpO2 ${r.vitals!.spO2}%, Hb ${r.vitals!.haemoglobin}', style: AppTypography.supporting),
                    if (r.priorMedications.isNotEmpty)
                      Text('• Pre-transfer meds: ${r.priorMedications.join(", ")}', style: AppTypography.supporting),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              const Text('Attending Clinician:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(controller: doctorCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Doctor Name')),

              const SizedBox(height: 10),
              const Text('Evaluation / Examination Notes:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(controller: notesCtrl, maxLines: 2, decoration: const InputDecoration(border: OutlineInputBorder())),

              const SizedBox(height: 16),
              const Text('Post-Arrival Disposition:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        refRepo.completeClinicalHandoff(r.id, receivingDoctor: doctorCtrl.text.trim(), handoffNotes: notesCtrl.text.trim());
                        refRepo.recordDisposition(r.id, disposition: 'ADMITTED', notes: notesCtrl.text.trim());
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Patient ${r.patientName} admitted to inpatient ward.'), backgroundColor: RuralCareColors.teal),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: RuralCareColors.teal, foregroundColor: Colors.white),
                      child: const Text('Admit Inpatient', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        refRepo.completeClinicalHandoff(r.id, receivingDoctor: doctorCtrl.text.trim(), handoffNotes: notesCtrl.text.trim());
                        refRepo.recordDisposition(r.id, disposition: 'TREATED_DISCHARGED', notes: notesCtrl.text.trim());
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Patient ${r.patientName} treated and discharged.'), backgroundColor: RuralCareColors.teal),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
                      child: const Text('Treat & Discharge', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showCounterReferralModal(context, r, refRepo, strings);
                  },
                  icon: const Icon(Icons.reply_all_rounded, size: 16),
                  label: const Text('Counter-Refer to Frontline Sub-Centre / PHC', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(foregroundColor: RuralCareColors.teal, side: const BorderSide(color: RuralCareColors.teal)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 5. Formal Counter-Referral Care Plan Sheet
  void _showCounterReferralModal(
    BuildContext context,
    ReferralDto r,
    ReferralRepository refRepo,
    FacilityStrings strings,
  ) {
    final diagCtrl = TextEditingController(
      text: r.reason.contains('Gestational')
          ? 'Gestational Hypertension stabilized. Secondary severe anaemia corrected via blood transfusion.'
          : 'Acute asthma attack resolved with nebulization. Maintenance inhaler prescribed.',
    );
    final treatCtrl = TextEditingController(
      text: r.reason.contains('Gestational')
          ? 'IV Labetalol 20mg stat given; 2 units O+ PRBC transfused; ultrasound showed normal fetal heart rate.'
          : 'High-flow O2 given for 2 hours; Salbutamol nebulization 2 cycles; SpO2 improved to 98%.',
    );
    final medsCtrl = TextEditingController(
      text: r.reason.contains('Gestational')
          ? 'Tab Labetalol 100mg BD x 14 days, Tab IFA 1 OD, Tab Calcium 500mg BD'
          : 'Budecort Inhaler 200mcg 1 puff BD, Asthalin Inhaler SOS',
    );
    final instrCtrl = TextEditingController(
      text: 'Daily morning BP & fetal movement check by ASHA. Review at Sub-District Hospital in 7 days.',
    );
    final warningCtrl = TextEditingController(
      text: 'Severe frontal headache, visual blurring, breathing difficulty, pedal edema',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: RuralCareColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.reply_all, color: RuralCareColors.teal),
                      SizedBox(width: 8),
                      Text('Counter-Referral Care Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              Text('Patient: ${r.patientName} • Returning to: ${r.referringFacility}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 12),

              const Text('Final Diagnosis:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(controller: diagCtrl, decoration: const InputDecoration(border: OutlineInputBorder())),

              const SizedBox(height: 10),
              const Text('Clinical Treatment Provided:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(controller: treatCtrl, maxLines: 2, decoration: const InputDecoration(border: OutlineInputBorder())),

              const SizedBox(height: 10),
              const Text('Discharge Medicines Prescribed:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(controller: medsCtrl, decoration: const InputDecoration(border: OutlineInputBorder())),

              const SizedBox(height: 10),
              const Text('Follow-Up Instructions for Frontline ASHA:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(controller: instrCtrl, maxLines: 2, decoration: const InputDecoration(border: OutlineInputBorder())),

              const SizedBox(height: 10),
              const Text('Danger Signs & Red Flags to Watch:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(controller: warningCtrl, decoration: const InputDecoration(border: OutlineInputBorder())),

              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final counterReferral = CounterReferralDto(
                      diagnosis: diagCtrl.text.trim(),
                      treatmentProvided: treatCtrl.text.trim(),
                      prescribedMedicines: medsCtrl.text.split(',').map((s) => s.trim()).toList(),
                      followUpInstructions: instrCtrl.text.trim(),
                      warningSigns: warningCtrl.text.split(',').map((s) => s.trim()).toList(),
                      followUpDate: DateTime.now().add(const Duration(days: 7)),
                      reasonForReturn: 'Acute condition stabilized; continuing maintenance care at Sub-Centre.',
                      receivingFacility: r.referringFacility,
                      dispatchedAt: DateTime.now(),
                      dispatchedBy: 'Sister Sarita Patil / Dr. Anita Roy',
                    );

                    refRepo.dispatchCounterReferral(referralId: r.id, counterReferral: counterReferral);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Counter-referral dispatched to ${r.referringFacility}. Frontline team notified.'),
                        backgroundColor: RuralCareColors.teal,
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Dispatch Counter-Referral to ASHA', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RuralCareColors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 6. Re-route Modal
  void _showRerouteModal(BuildContext context, ReferralDto r, ReferralRepository refRepo, FacilityStrings strings) {
    String selectedDest = 'FAC-DH-401';
    final reasonCtrl = TextEditingController(text: 'Specialist ICU bed and tertiary critical care facility required.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Re-Route Referral', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assign another appropriate facility for ${r.patientName}:'),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedDest,
              items: const [
                DropdownMenuItem(value: 'FAC-DH-401', child: Text('Aundh District Hospital (DH)')),
                DropdownMenuItem(value: 'FAC-CHC-201', child: Text('Daund Community Health Centre (CHC)')),
              ],
              onChanged: (v) => selectedDest = v ?? selectedDest,
            ),
            const SizedBox(height: 10),
            TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Transfer Rationale', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(strings.cancel)),
          ElevatedButton(
            onPressed: () {
              final targetName = selectedDest == 'FAC-DH-401' ? 'Aundh District Hospital' : 'Daund CHC';
              refRepo.rerouteReferral(r.id, targetFacilityId: selectedDest, targetFacilityName: targetName, reason: reasonCtrl.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Referral re-routed to $targetName.'), backgroundColor: const Color(0xFFD97706)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
            child: const Text('Confirm Re-Route'),
          ),
        ],
      ),
    );
  }

  // 7. Reject Modal
  void _showRejectModal(BuildContext context, ReferralDto r, ReferralRepository refRepo, FacilityStrings strings) {
    final reasonCtrl = TextEditingController(text: 'Facility at 100% capacity; unable to safely stabilize patient.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Referral', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Specify clinical or administrative reason for rejecting ${r.patientName}:'),
            const SizedBox(height: 10),
            TextField(controller: reasonCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Rejection Reason', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(strings.cancel)),
          ElevatedButton(
            onPressed: () {
              refRepo.rejectReferral(r.id, reason: reasonCtrl.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Referral ${r.id} rejected. Referring center notified.'), backgroundColor: RuralCareColors.critical),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: RuralCareColors.critical, foregroundColor: Colors.white),
            child: const Text('Confirm Reject'),
          ),
        ],
      ),
    );
  }

  // 8. Create Outbound Referral Modal
  void _showCreateOutboundModal(
    BuildContext context,
    ReferralRepository refRepo,
    FacilityRepository facRepo,
    FacilityStrings strings,
  ) {
    final patientCtrl = TextEditingController(text: 'Anand Shinde');
    final reasonCtrl = TextEditingController(text: 'Complex fracture reduction requiring Orthopedic Theatre');
    String selectedTarget = 'FAC-DH-401';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: RuralCareColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(strings.createOutbound, style: AppTypography.sectionTitle),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Patient Name', style: AppTypography.supporting),
            const SizedBox(height: 4),
            TextField(controller: patientCtrl, decoration: const InputDecoration(hintText: 'Enter patient full name')),
            const SizedBox(height: 12),
            const Text('Clinical Reason & Urgency', style: AppTypography.supporting),
            const SizedBox(height: 4),
            TextField(controller: reasonCtrl, decoration: const InputDecoration(hintText: 'Detailed referral reason')),
            const SizedBox(height: 12),
            const Text('Receiving Facility', style: AppTypography.supporting),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: selectedTarget,
              items: const [
                DropdownMenuItem(value: 'FAC-DH-401', child: Text('Aundh District Hospital (जिल्हा रुग्णालय)')),
                DropdownMenuItem(value: 'FAC-CHC-201', child: Text('Daund Community Health Centre (CHC)')),
              ],
              onChanged: (v) => selectedTarget = v ?? selectedTarget,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  refRepo.createReferral(
                    patientId: 'pat-005',
                    patientName: patientCtrl.text.trim(),
                    referringFacility: 'Baramati Sub-District Hospital (SDH)',
                    targetFacilityId: selectedTarget,
                    targetFacilityName: selectedTarget == 'FAC-DH-401'
                        ? 'Aundh District Hospital'
                        : 'Daund Community Health Centre',
                    reason: reasonCtrl.text.trim(),
                    urgency: 'URGENT',
                    requiredSpecialty: 'Orthopedics / Secondary Surgery',
                  );
                  Navigator.pop(ctx);
                  setState(() => _isInbound = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(strings.toastUpdated),
                      backgroundColor: RuralCareColors.teal,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: RuralCareColors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Transmit Outbound Referral'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
