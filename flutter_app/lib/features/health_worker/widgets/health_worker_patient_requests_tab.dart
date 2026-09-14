import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/models/patient_request_dto.dart';
import 'package:ruralcare/data/models/triage_dto.dart';
import 'package:ruralcare/data/repositories/patient_request_repository.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/core/services/nlp_symptom_service.dart';
import 'package:ruralcare/features/emergency/screens/emergency_tracking_screen.dart';

class HealthWorkerPatientRequestsTab extends StatefulWidget {
  const HealthWorkerPatientRequestsTab({super.key});

  @override
  State<HealthWorkerPatientRequestsTab> createState() => _HealthWorkerPatientRequestsTabState();
}

class _HealthWorkerPatientRequestsTabState extends State<HealthWorkerPatientRequestsTab> {
  int _filterIndex = 0; // 0: All, 1: Pending, 2: Emergency (P0), 3: Escalated

  void _showNewRequestDialog(BuildContext context) {
    final patientRepo = PatientRepository();
    final patients = patientRepo.patients;
    if (patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please register a patient before creating a request.')),
      );
      return;
    }

    String selectedPatId = patients.first.id;
    final msgCtrl = TextEditingController(text: 'Mera pet dukhra hai aur subah se chakkar aa raha hai');
    final addrCtrl = TextEditingController(text: '${patients.first.village}, Near Primary School');
    String reqType = 'TELECONSULTATION';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final selPatient = patients.firstWhere((p) => p.id == selectedPatId);

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.add_alert_rounded, color: RuralCareColors.primary),
                SizedBox(width: 8),
                Text('Raise Patient Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Beneficiary:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: selectedPatId,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder()),
                    items: patients.map((p) => DropdownMenuItem(value: p.id, child: Text(p.fullName, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (id) {
                      if (id != null) {
                        setDialogState(() {
                          selectedPatId = id;
                          final p = patients.firstWhere((e) => e.id == id);
                          addrCtrl.text = '${p.village}, Landmark Home';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text('Patient Message (Natural Speech/Text):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: msgCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'e.g. "Mera pet dukhra hai"',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Village & Address / Landmark:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: addrCtrl,
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.all(10)),
                  ),
                  const SizedBox(height: 10),
                  const Text('Request Type:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: reqType,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'TELECONSULTATION', child: Text('Doctor Teleconsultation')),
                      DropdownMenuItem(value: 'HOME_VISIT', child: Text('Frontline Home Visit')),
                      DropdownMenuItem(value: 'MEDICINE_REFILL', child: Text('Medicine Refill')),
                      DropdownMenuItem(value: 'EMERGENCY_SOS', child: Text('Emergency SOS (108)')),
                    ],
                    onChanged: (val) => setDialogState(() => reqType = val ?? 'TELECONSULTATION'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: RuralCareColors.primary),
                onPressed: () {
                  final nlp = NlpSymptomService().parseMessage(msgCtrl.text.trim());
                  final newReq = PatientRequestDto(
                    id: 'REQ-${DateTime.now().millisecondsSinceEpoch % 10000}',
                    patientId: selPatient.id,
                    patientName: selPatient.fullName,
                    patientAge: selPatient.age,
                    patientGender: selPatient.gender,
                    patientPhone: selPatient.phoneNumber,
                    abhaId: selPatient.abhaId,
                    village: selPatient.village,
                    address: addrCtrl.text.trim(),
                    message: msgCtrl.text.trim(),
                    extractedSymptoms: nlp.extractedSymptoms,
                    triagePriority: nlp.suggestedPriority,
                    requestType: reqType,
                    createdAt: DateTime.now(),
                  );
                  PatientRequestRepository().addRequest(newReq);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Patient request submitted and queued for frontline attention.')),
                  );
                },
                child: const Text('Submit Request', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reqRepo = PatientRequestRepository();
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: Listenable.merge([reqRepo, session]),
      builder: (context, _) {
        final allRequests = reqRepo.requests;

        List<PatientRequestDto> filtered = allRequests;
        if (_filterIndex == 1) {
          filtered = allRequests.where((r) => r.status == 'PENDING').toList();
        } else if (_filterIndex == 2) {
          filtered = allRequests.where((r) => r.triagePriority == TriagePriority.p0Red).toList();
        } else if (_filterIndex == 3) {
          filtered = allRequests.where((r) => r.status == 'ESCALATED_TO_DOCTOR').toList();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.isHindi ? 'मरीज़ अनुरोध डेस्क' : (session.isMarathi ? 'रुग्ण विनंती कक्ष' : 'Patient Requests Desk'),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: RuralCareColors.textPrimary),
                      ),
                      const Text(
                        'Direct requests raised by beneficiaries across cluster',
                        style: TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: RuralCareColors.primary),
                    tooltip: 'Create Patient Request',
                    onPressed: () => _showNewRequestDialog(context),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'All (${allRequests.length})',
                    'Pending (${allRequests.where((r) => r.status == 'PENDING').length})',
                    'Emergency P0 (${allRequests.where((r) => r.triagePriority == TriagePriority.p0Red).length})',
                    'Escalated (${allRequests.where((r) => r.status == 'ESCALATED_TO_DOCTOR').length})',
                  ].asMap().entries.map((e) {
                    final isSel = _filterIndex == e.key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(e.value),
                        selected: isSel,
                        selectedColor: RuralCareColors.primary,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          color: isSel ? Colors.white : RuralCareColors.textPrimary,
                        ),
                        onSelected: (_) => setState(() => _filterIndex = e.key),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 14),

              if (filtered.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: RuralCareColors.border),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.inbox_outlined, size: 40, color: RuralCareColors.textSecondary),
                      const SizedBox(height: 8),
                      Text(
                        session.isHindi ? 'कोई सक्रिय मरीज़ अनुरोध नहीं है' : (session.isMarathi ? 'कोणतीही प्रलंबित विनंती नाही' : 'No Active Patient Requests'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Patient messages, teleconsultation requests, and SOS alerts will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _showNewRequestDialog(context),
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('Raise Demonstration Request', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ...filtered.map((req) => _buildRequestCard(context, req, reqRepo, session)),
              ],

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    PatientRequestDto req,
    PatientRequestRepository repo,
    SessionCoordinator session,
  ) {
    final isEmergency = req.triagePriority == TriagePriority.p0Red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEmergency ? RuralCareColors.critical : RuralCareColors.border,
          width: isEmergency ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Patient Name, Triage Badge & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        req.patientName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${req.patientAge}${req.patientGender == "Female" ? "F" : "M"})',
                        style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                      ),
                    ],
                  ),
                  Text(
                    'ABHA: ${req.abhaId.isNotEmpty ? req.abhaId : "ABHA-${req.patientId}"}',
                    style: const TextStyle(fontSize: 10, color: RuralCareColors.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isEmergency
                          ? RuralCareColors.criticalSoft
                          : (req.triagePriority == TriagePriority.p1Yellow ? RuralCareColors.warningSoft : RuralCareColors.successSoft),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${req.triagePriority.code} Priority',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isEmergency
                            ? RuralCareColors.critical
                            : (req.triagePriority == TriagePriority.p1Yellow ? RuralCareColors.warning : RuralCareColors.success),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: RuralCareColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      req.status,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: RuralCareColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Row 2: Patient Natural Message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isEmergency ? const Color(0xFFFFF7ED) : RuralCareColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isEmergency ? const Color(0xFFFED7AA) : RuralCareColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 12, color: RuralCareColors.textSecondary),
                    SizedBox(width: 4),
                    Text('Patient Message:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: RuralCareColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '"${req.message}"',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: RuralCareColors.textPrimary, fontStyle: FontStyle.italic),
                ),
                if (req.extractedSymptoms.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('Symptoms: ', style: TextStyle(fontSize: 10, color: RuralCareColors.textSecondary)),
                      Expanded(
                        child: Text(
                          req.extractedSymptoms.join(', '),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: RuralCareColors.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Row 3: Address & Village Location
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: RuralCareColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${req.address} (${req.village})',
                  style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Tel: ${req.patientPhone}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: RuralCareColors.border),
          const SizedBox(height: 10),

          // Row 4: Action Buttons
          Row(
            children: [
              // Phone Call
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.phone, size: 16, color: Color(0xFF2E7D32)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Calling beneficiary ${req.patientName} (${req.patientPhone})...')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Accept Visit Button
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      side: const BorderSide(color: RuralCareColors.teal),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      repo.acceptRequest(req.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Request accepted. Scheduled home visit for ${req.patientName}.')),
                      );
                    },
                    child: Text(
                      req.status == 'ACCEPTED' ? 'Visit Accepted ✓' : 'Accept Visit',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RuralCareColors.teal),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Escalate to Doctor or 108 Ambulance
              if (isEmergency) ...[
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RuralCareColors.critical,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (ctx) => const EmergencyTrackingScreen()),
                        );
                      },
                      icon: const Icon(Icons.local_shipping, size: 14),
                      label: const Text('Dispatch 108', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RuralCareColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        repo.escalateToDoctor(req.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Request escalated to on-duty specialist for ${req.patientName}.')),
                        );
                      },
                      child: Text(
                        req.status == 'ESCALATED_TO_DOCTOR' ? 'Escalated ✓' : 'Escalate Doctor',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
