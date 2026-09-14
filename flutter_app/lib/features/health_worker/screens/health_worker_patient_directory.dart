import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/core/database/local_cache.dart';
import 'package:ruralcare/data/repositories/patient_repository.dart';
import 'package:ruralcare/data/models/patient_dto.dart';
import 'package:ruralcare/data/models/vitals_dto.dart';
import 'package:ruralcare/app/routes.dart';
import '../utils/health_worker_strings.dart';
import 'health_worker_followup_screen.dart';

class HealthWorkerPatientDirectory extends StatefulWidget {
  final Function(int targetTab)? onNavigateTab;
  const HealthWorkerPatientDirectory({super.key, this.onNavigateTab});

  @override
  State<HealthWorkerPatientDirectory> createState() => _HealthWorkerPatientDirectoryState();
}

class _HealthWorkerPatientDirectoryState extends State<HealthWorkerPatientDirectory> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedFilter = 'All';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientRepo = PatientRepository();
    final cache = LocalCacheService();
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: Listenable.merge([patientRepo, cache, session]),
      builder: (context, _) {
        final strings = HealthWorkerStrings.of(session);
        final allPatients = patientRepo.patients;
        final query = _searchCtrl.text.trim().toLowerCase();

        final filtered = allPatients.where((p) {
          final matchesQuery = query.isEmpty ||
              p.fullName.toLowerCase().contains(query) ||
              p.ruralCareId.toLowerCase().contains(query) ||
              p.phoneNumber.contains(query) ||
              p.village.toLowerCase().contains(query);

          if (!matchesQuery) return false;

          switch (_selectedFilter) {
            case 'High Risk':
              return p.isHighRisk || p.highRiskConditions.isNotEmpty;
            case 'ANC':
              return p.isPregnant;
            case 'Due Today':
              return p.isPregnant || p.highRiskConditions.isNotEmpty;
            default:
              return true;
          }
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Page Header matching Stitch Screen 2
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.forestTeal.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_search_rounded, color: AppColors.forestTeal, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              strings.patientDirectoryTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkSlate,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              strings.searchPatientHeaderTag,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.forestTeal,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.skyBlueSoft,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.skyBlue.withOpacity(0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.local_hospital_outlined, size: 12, color: AppColors.navyBlue),
                                  SizedBox(width: 4),
                                  Text(
                                    'PHC Rampur',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.navyBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          strings.patientDirectorySubtitle,
                          style: const TextStyle(fontSize: 11, color: AppColors.slateGray),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2. Search Input Box
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.neutral300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 13, color: AppColors.darkSlate),
                  decoration: InputDecoration(
                    hintText: strings.searchPlaceholder,
                    hintStyle: const TextStyle(fontSize: 12, color: AppColors.slateGray),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.slateGray, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.slateGray),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 3. Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    {'key': 'All', 'label': strings.filterAll},
                    {'key': 'High Risk', 'label': strings.filterHighRisk},
                    {'key': 'ANC', 'label': strings.filterAnc},
                    {'key': 'Due Today', 'label': strings.filterDueToday},
                  ].map((filter) {
                    final isSel = _selectedFilter == filter['key'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter['label']!),
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          color: isSel ? Colors.white : AppColors.slateGray,
                        ),
                        selected: isSel,
                        selectedColor: AppColors.forestTeal,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: isSel ? AppColors.forestTeal : AppColors.neutral300,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onSelected: (val) {
                          if (val) setState(() => _selectedFilter = filter['key']!);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // 4. Patient Cards List
              if (filtered.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(Icons.search_off_rounded, size: 40, color: AppColors.slateGray),
                      const SizedBox(height: 8),
                      Text(
                        strings.isHi ? 'कोई मेल खाने वाला मरीज़ नहीं मिला' : (strings.isMr ? 'कोणताही जुळणारा रुग्ण आढळला नाही' : 'No matching patients found'),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.isHi ? 'अपने खोज मानदंड समायोजित करने का प्रयास करें' : (strings.isMr ? 'आपले शोध निकष समायोजित करण्याचा प्रयत्न करा' : 'Try adjusting your search criteria'),
                        style: const TextStyle(fontSize: 12, color: AppColors.slateGray),
                      ),
                    ],
                  ),
                )
              else
                ...filtered.map((patient) => _buildPatientCard(context, patient)),

              const SizedBox(height: 16),

              // 5. Offline Storage Banner matching Stitch Screen 2
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF4EB), // Warm subtle beige/amber
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF3E4D2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_done_outlined, size: 18, color: AppColors.earthOchre),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Showing ${filtered.length} of ${allPatients.length} assigned local records • Available offline',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.earthOchreDark),
                          ),
                          const SizedBox(height: 1),
                          const Text(
                            'स्थानीय डेटा सुरक्षित • इंटरनेट के बिना भी उपलब्ध',
                            style: TextStyle(fontSize: 10, color: AppColors.earthOchreDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 6. Register New Patient Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _showRegisterPatientModal(context),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 20, color: AppColors.forestTeal),
                  label: const Text(
                    '+ Register New Patient',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.forestTeal,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.forestTeal, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPatientCard(BuildContext context, PatientDto p) {
    // Dynamic status pill
    String statusLabel = '● Routine Checkup';
    Color statusBg = const Color(0xFFE8F5E9);
    Color statusColor = const Color(0xFF2E7D32);

    if (p.isPregnant && p.highRiskConditions.isNotEmpty) {
      statusLabel = '● High Priority ANC';
      statusBg = const Color(0xFFFFF3E0);
      statusColor = const Color(0xFFE65100);
    } else if (p.isPregnant) {
      statusLabel = '● ANC Checkup Due';
      statusBg = const Color(0xFFE0F2FE);
      statusColor = const Color(0xFF0369A1);
    } else if (p.latestVitals?.isHighRisk ?? false) {
      statusLabel = '● Overdue Review';
      statusBg = const Color(0xFFFFEBEE);
      statusColor = const Color(0xFFC62828);
    } else {
      statusLabel = '● Follow-up Due Today';
      statusBg = const Color(0xFFFEF3C7);
      statusColor = const Color(0xFF92400E);
    }

    final initials = p.fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Avatar, Names, ID Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.forestTeal.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.forestTeal.withOpacity(0.2)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.forestTealDark,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: p.isHighRisk ? AppColors.terracotta : AppColors.forestTeal,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.fullName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkSlate,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${p.age} yrs • ${p.gender == "FEMALE" ? "Female" : "Male"} • ${p.village}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.slateGray,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.skyBlueSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.badge_outlined, size: 11, color: AppColors.navyBlue),
                    const SizedBox(width: 4),
                    Text(
                      p.ruralCareId,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.neutral200),
          const SizedBox(height: 10),

          // Row 2: Phone number & Status pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 14, color: AppColors.forestTeal),
                  const SizedBox(width: 6),
                  Text(
                    p.phoneNumber,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkSlate,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 3: Select Patient Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: () => _showPatientCareSummaryModal(context, p),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestTealDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Select Patient',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Patient Care Summary Bottom Sheet matching Stitch Screen 3
  void _showPatientCareSummaryModal(BuildContext context, PatientDto p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.neutral300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkSlate)),
                      Text('${p.age} yrs • ${p.gender} • ${p.village}', style: const TextStyle(fontSize: 12, color: AppColors.slateGray)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.slateGray),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.neutral200),
              const SizedBox(height: 12),

              // Recent Vitals & Conditions
              const Text('Clinical Profile & Vitals', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkSlate)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.neutral300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _vitalPill('BP', '${p.latestVitals?.systolicBp ?? 120}/${p.latestVitals?.diastolicBp ?? 80}', 'mmHg'),
                    _vitalPill('Pulse', '${p.latestVitals?.pulse ?? 76}', 'bpm'),
                    _vitalPill('SpO₂', '${p.latestVitals?.spO2 ?? 98}', '%'),
                    _vitalPill('Hb', '${p.latestVitals?.haemoglobin ?? 12.0}', 'g/dL'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Quick Field Actions Grid matching Stitch Screen 3
              const Text('QUICK FIELD ACTIONS / त्वरित कार्य', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slateGray, letterSpacing: 0.5)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      icon: Icons.note_add_outlined,
                      label: 'Add Note\nटिप्पणी',
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Field observation note drafted locally')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _actionButton(
                      icon: Icons.calendar_today_outlined,
                      label: 'Schedule\nतारीख तय करें',
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Follow-up schedule reminder logged')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _actionButton(
                      icon: Icons.call_outlined,
                      label: 'Call Patient\nफ़ोन करें',
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Calling ${p.phoneNumber}...')),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Governance Notice matching Stitch Screen 3
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.skyBlueSoft.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.skyBlue.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: AppColors.navyBlue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Role Boundary: Clinical decisions, diagnosis, and drug prescriptions remain with the supervising doctor.',
                        style: TextStyle(fontSize: 10, color: AppColors.navyBlue),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Record Follow-up Visit Primary Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (c) => HealthWorkerFollowUpScreen(patientId: p.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.assignment_turned_in_outlined, color: Colors.white, size: 20),
                  label: const Text(
                    'Record Follow-up Visit (जांच दर्ज करें)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestTealDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _vitalPill(String title, String val, String unit) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 10, color: AppColors.slateGray)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkSlate)),
        Text(unit, style: const TextStyle(fontSize: 9, color: AppColors.slateGray)),
      ],
    );
  }

  Widget _actionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neutral300),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.forestTeal, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.darkSlate),
            ),
          ],
        ),
      ),
    );
  }

  // Register New Patient Sheet
  void _showRegisterPatientModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final villageCtrl = TextEditingController(text: 'Rampur');
    String gender = 'FEMALE';
    bool isPregnant = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Register New Beneficiary',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppColors.slateGray),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Will be saved locally and synced to PHC Rampur registry',
                        style: TextStyle(fontSize: 12, color: AppColors.slateGray),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Full Name / पूरा नाम', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: ageCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Age / उम्र', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: gender,
                              decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                                DropdownMenuItem(value: 'MALE', child: Text('Male')),
                                DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                              ],
                              onChanged: (val) => setModalState(() => gender = val ?? 'FEMALE'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone Number / मोबाइल', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: villageCtrl,
                        decoration: const InputDecoration(labelText: 'Village / गाँव', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Maternal Beneficiary (Pregnant)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Enables ANC trimester tracking queue', style: TextStyle(fontSize: 11)),
                        value: isPregnant,
                        activeColor: AppColors.forestTeal,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setModalState(() => isPregnant = val),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            final name = nameCtrl.text.trim();
                            final age = int.tryParse(ageCtrl.text.trim()) ?? 25;
                            final phone = phoneCtrl.text.trim().isEmpty ? '+91 98000 00000' : phoneCtrl.text.trim();
                            final village = villageCtrl.text.trim().isEmpty ? 'Rampur' : villageCtrl.text.trim();

                            if (name.isEmpty) return;

                            final newPat = PatientDto(
                              id: 'pat-${DateTime.now().millisecondsSinceEpoch}',
                              ruralCareId: 'RC-MH-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                              abhaId: '91-4421-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}-001',
                              fullName: name,
                              age: age,
                              gender: gender,
                              phoneNumber: phone,
                              village: village,
                              subCentre: 'Kashti Sub-Centre',
                              district: 'Pune Rural',
                              assignedAsha: 'Kavita Verma',
                              isPregnant: isPregnant,
                              emergencyContact: const EmergencyContactDto(
                                name: 'Family Contact',
                                relationship: 'FAMILY',
                                phoneNumber: '+91 98000 00000',
                              ),
                              latestVitals: VitalsDto(
                                id: 'vit-${DateTime.now().millisecondsSinceEpoch}',
                                patientId: 'pat-new',
                                recordedById: 'hw-4412',
                                recordedByRole: 'HEALTH_WORKER',
                                recordedAt: DateTime.now(),
                                systolicBp: 120,
                                diastolicBp: 80,
                                pulse: 72,
                                spO2: 99,
                                temperature: 98.4,
                                bloodSugar: 100,
                                haemoglobin: 12.0,
                              ),
                            );

                            PatientRepository().addPatient(newPat);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Beneficiary registered: ${newPat.fullName}')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.forestTealDark,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Save & Add Beneficiary', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
