import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/facility_dto.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';
import 'package:ruralcare/app/routes.dart';

/// Module 3: Healthcare Facility Management (Stitch Screen 3: 4645b058ab5349d6b22111b080de6a74)
/// Operational facility network directory with 4 KPI cards, Table vs Cards toggle,
/// jurisdictional block filters, read-only bed transparency, and "+ Register New Facility" modal.
class AdminFacilitiesTab extends StatefulWidget {
  const AdminFacilitiesTab({super.key});

  @override
  State<AdminFacilitiesTab> createState() => _AdminFacilitiesTabState();
}

class _AdminFacilitiesTabState extends State<AdminFacilitiesTab> {
  final FacilityRepository _facRepo = FacilityRepository();
  final SessionCoordinator _session = SessionCoordinator();

  bool _isTableView = false;
  String _searchQuery = '';
  String _selectedTypeFilter = 'ALL';
  String _selectedEmergencyFilter = 'ALL';

  void _showRegisterFacilityModal() {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final distCtrl = TextEditingController(text: '15.0');
    final totalBedsCtrl = TextEditingController(text: '20');
    final availBedsCtrl = TextEditingController(text: '5');
    String selectedType = 'PRIMARY_HEALTH_CENTRE';
    bool hasEmergency = true;
    bool hasAmbulance = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.add_business_rounded, color: Color(0xFF005140)),
                SizedBox(width: 8),
                Text('Register New Facility', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Onboard health sub-centres, PHCs, or referral hospitals to Rampur District Cluster Registry.',
                    style: TextStyle(fontSize: 12, color: RuralCareColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Facility Name *',
                      hintText: 'e.g. Shirur Primary Health Centre',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Facility Classification *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'SUB_CENTRE', child: Text('Health Sub-Centre (उप-केंद्र)')),
                      DropdownMenuItem(value: 'PRIMARY_HEALTH_CENTRE', child: Text('Primary Health Centre (PHC)')),
                      DropdownMenuItem(value: 'CHC', child: Text('Community Health Centre (CHC)')),
                      DropdownMenuItem(value: 'SUB_DISTRICT_HOSPITAL', child: Text('Sub-District Hospital (SDH)')),
                      DropdownMenuItem(value: 'DISTRICT_HOSPITAL', child: Text('District Hospital (जिल्हा रुग्णालय)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedType = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: distCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Distance (km) *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Contact Phone *',
                            hintText: '+91 2112...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Physical Address / Tehsil *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: totalBedsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Total Beds *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: availBedsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Available Beds *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('24x7 Emergency Department Ready', style: TextStyle(fontSize: 13)),
                    value: hasEmergency,
                    activeColor: const Color(0xFF005140),
                    onChanged: (val) => setDialogState(() => hasEmergency = val ?? false),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('108 Emergency Ambulance Stationed', style: TextStyle(fontSize: 13)),
                    value: hasAmbulance,
                    activeColor: const Color(0xFF005140),
                    onChanged: (val) => setDialogState(() => hasAmbulance = val ?? false),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005140),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all required fields.')),
                    );
                    return;
                  }

                  final totalBeds = int.tryParse(totalBedsCtrl.text.trim()) ?? 10;
                  final availBeds = int.tryParse(availBedsCtrl.text.trim()) ?? 2;
                  final dist = double.tryParse(distCtrl.text.trim()) ?? 10.0;

                  final newFac = FacilityDto(
                    id: 'FAC-${selectedType.substring(0, 3)}-${DateTime.now().millisecondsSinceEpoch % 1000}',
                    name: nameCtrl.text.trim(),
                    type: selectedType,
                    distanceKm: dist,
                    address: addressCtrl.text.trim().isEmpty ? 'Rampur Tehsil' : addressCtrl.text.trim(),
                    contactPhone: phoneCtrl.text.trim(),
                    totalBeds: totalBeds,
                    availableBeds: availBeds,
                    onDutySpecialists: ['Medical Officer (MBBS)', 'Staff Nurse'],
                    availableBloodUnits: {},
                    availableDiagnostics: ['Rapid Blood Sugar', 'Urine Albumin', 'CBC'],
                    availableMedicines: ['Paracetamol', 'Amoxicillin', 'ORS'],
                    hasEmergencyCapability: hasEmergency,
                    hasAmbulanceAvailable: hasAmbulance,
                  );

                  _facRepo.addFacility(newFac);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Facility "${newFac.name}" registered in cluster database.'),
                      backgroundColor: const Color(0xFF005140),
                    ),
                  );
                },
                child: const Text('Confirm Registration'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUpdateBedsDialog(FacilityDto fac) {
    int updatedBeds = fac.availableBeds;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBedsState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Adjust Beds: ${fac.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total Capacity: ${fac.totalBeds} beds', style: const TextStyle(fontSize: 13, color: RuralCareColors.textSecondary)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 28, color: Color(0xFF005140)),
                      onPressed: updatedBeds > 0 ? () => setBedsState(() => updatedBeds--) : null,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '$updatedBeds',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF005140)),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 28, color: Color(0xFF005140)),
                      onPressed: updatedBeds < fac.totalBeds ? () => setBedsState(() => updatedBeds++) : null,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('Available Bed Count for Referrals', style: TextStyle(fontSize: 11, color: RuralCareColors.textSecondary)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF005140), foregroundColor: Colors.white),
                onPressed: () {
                  _facRepo.updateAvailableBeds(fac.id, updatedBeds);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Updated ${fac.name} available beds to $updatedBeds.'),
                      backgroundColor: const Color(0xFF005140),
                    ),
                  );
                },
                child: const Text('Save Availability'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMr = _session.isMr;
    final isHi = _session.isHi;

    return ListenableBuilder(
      listenable: Listenable.merge([_facRepo, _session]),
      builder: (context, _) {
        final facilities = _facRepo.facilities;

        // KPI calculations
        final totalFacilities = facilities.length;
        final primaryUnits = facilities.where((f) => f.type == 'SUB_CENTRE' || f.type == 'PRIMARY_HEALTH_CENTRE').length;
        final referralHospitals = facilities.where((f) => f.type != 'SUB_CENTRE' && f.type != 'PRIMARY_HEALTH_CENTRE').length;
        final totalBeds = facilities.fold<int>(0, (sum, f) => sum + f.totalBeds);
        final availableBeds = facilities.fold<int>(0, (sum, f) => sum + f.availableBeds);

        // Filter list
        final filteredFacilities = facilities.where((fac) {
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final matches = fac.name.toLowerCase().contains(q) ||
                fac.address.toLowerCase().contains(q) ||
                fac.id.toLowerCase().contains(q);
            if (!matches) return false;
          }

          if (_selectedTypeFilter != 'ALL') {
            if (fac.type != _selectedTypeFilter) return false;
          }

          if (_selectedEmergencyFilter == 'EMERGENCY_ONLY') {
            if (!fac.hasEmergencyCapability) return false;
          } else if (_selectedEmergencyFilter == 'AMBULANCE_ONLY') {
            if (!fac.hasAmbulanceAvailable) return false;
          }

          return true;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header & Controls
              _buildHeader(totalFacilities, isHi, isMr),
              const SizedBox(height: 16),

              // 2. 4 High-Impact Facility KPI Cards
              _buildKpiCards(
                totalFacilities: totalFacilities,
                primaryUnits: primaryUnits,
                referralHospitals: referralHospitals,
                totalBeds: totalBeds,
                availableBeds: availableBeds,
                isHi: isHi,
                isMr: isMr,
              ),
              const SizedBox(height: 16),

              // 3. Search & Filter Bar
              _buildFilterBar(isHi, isMr),
              const SizedBox(height: 16),

              // 4. Facilities Directory (Cards or Table)
              if (_isTableView)
                _buildTableView(filteredFacilities, isHi, isMr)
              else
                _buildCardsView(filteredFacilities, isHi, isMr),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(int count, bool isHi, bool isMr) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isMr ? 'आरोग्य संस्था व्यवस्थापन' : (isHi ? 'स्वास्थ्य केंद्र प्रबंधन' : 'Healthcare Facility Management'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              isMr
                  ? 'एकूण $count आरोग्य संस्था क्लस्टर रजिस्ट्रीमध्ये सक्रिय'
                  : (isHi
                      ? 'कुल $count स्वास्थ्य केंद्र क्लस्टर रजिस्ट्री में सक्रिय'
                      : '$count health institutions registered in Rampur cluster'),
              style: const TextStyle(fontSize: 12, color: RuralCareColors.textSecondary),
            ),
          ],
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF005140),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _showRegisterFacilityModal,
          icon: const Icon(Icons.add_business_rounded, size: 16),
          label: Text(
            isMr ? '+ संस्था जोडा' : (isHi ? '+ केंद्र जोड़ें' : '+ Register Facility'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCards({
    required int totalFacilities,
    required int primaryUnits,
    required int referralHospitals,
    required int totalBeds,
    required int availableBeds,
    required bool isHi,
    required bool isMr,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 500 ? 2 : 1);
        final cardWidth = (constraints.maxWidth - (crossAxisCount - 1) * 12) / crossAxisCount;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _kpiItem(
                title: isMr ? 'एकूण संस्था' : (isHi ? 'कुल केंद्र' : 'Total Facilities'),
                value: '$totalFacilities',
                subtitle: isMr ? 'क्लस्टर नेटवर्क' : (isHi ? 'क्लस्टर नेटवर्क' : 'Active Cluster Network'),
                icon: Icons.domain_rounded,
                color: const Color(0xFF005140),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _kpiItem(
                title: isMr ? 'प्राथमिक संस्था (SC/PHC)' : (isHi ? 'प्राथमिक केंद्र (SC/PHC)' : 'Primary Care Units'),
                value: '$primaryUnits',
                subtitle: isMr ? 'तळागाळातील सेवा' : (isHi ? 'बुनियादी सेवाएं' : 'Grassroots Outreach'),
                icon: Icons.health_and_safety_rounded,
                color: const Color(0xFF33647B),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _kpiItem(
                title: isMr ? 'रेफरल रुग्णालये (CHC/DH)' : (isHi ? 'रेफरल अस्पताल (CHC/DH)' : 'Referral Hospitals'),
                value: '$referralHospitals',
                subtitle: isMr ? 'विशेषज्ञ सेवा सज्ज' : (isHi ? 'विशेषज्ञ सेवाएं' : 'Secondary & Tertiary'),
                icon: Icons.emergency_rounded,
                color: const Color(0xFFC05621),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _kpiItem(
                title: isMr ? 'उपलब्ध खाटा' : (isHi ? 'उपलब्ध बिस्तर' : 'Bed Availability'),
                value: '$availableBeds / $totalBeds',
                subtitle: isMr ? 'रिअल-टाइम क्षमता' : (isHi ? 'वास्तविक समय क्षमता' : 'Live Capacity Registry'),
                icon: Icons.hotel_rounded,
                color: const Color(0xFF15803D),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _kpiItem({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: RuralCareColors.textSecondary),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: RuralCareColors.textPrimary)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isHi, bool isMr) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 250,
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                isDense: true,
                hintText: isMr ? 'संस्था किंवा पत्ता शोधा...' : (isHi ? 'केंद्र या पता खोजें...' : 'Search facility or address...'),
                hintStyle: const TextStyle(fontSize: 12),
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          DropdownButton<String>(
            value: _selectedTypeFilter,
            underline: const SizedBox(),
            style: const TextStyle(fontSize: 12, color: RuralCareColors.textPrimary),
            items: const [
              DropdownMenuItem(value: 'ALL', child: Text('All Classifications')),
              DropdownMenuItem(value: 'SUB_CENTRE', child: Text('Sub-Centre')),
              DropdownMenuItem(value: 'CHC', child: Text('CHC')),
              DropdownMenuItem(value: 'SUB_DISTRICT_HOSPITAL', child: Text('SDH')),
              DropdownMenuItem(value: 'DISTRICT_HOSPITAL', child: Text('District Hospital')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedTypeFilter = val);
            },
          ),
          DropdownButton<String>(
            value: _selectedEmergencyFilter,
            underline: const SizedBox(),
            style: const TextStyle(fontSize: 12, color: RuralCareColors.textPrimary),
            items: const [
              DropdownMenuItem(value: 'ALL', child: Text('All Capabilities')),
              DropdownMenuItem(value: 'EMERGENCY_ONLY', child: Text('24x7 Emergency')),
              DropdownMenuItem(value: 'AMBULANCE_ONLY', child: Text('Ambulance Stationed')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedEmergencyFilter = val);
            },
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.grid_view_rounded,
                    size: 18,
                    color: !_isTableView ? const Color(0xFF005140) : RuralCareColors.textSecondary,
                  ),
                  tooltip: 'Cards View',
                  onPressed: () => setState(() => _isTableView = false),
                ),
                IconButton(
                  icon: Icon(
                    Icons.table_rows_rounded,
                    size: 18,
                    color: _isTableView ? const Color(0xFF005140) : RuralCareColors.textSecondary,
                  ),
                  tooltip: 'Table View',
                  onPressed: () => setState(() => _isTableView = true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsView(List<FacilityDto> facilities, bool isHi, bool isMr) {
    if (facilities.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: const Text('No facilities match the selected filters.'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth > 700 ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: facilities.map((fac) {
            final occupancyPercent = fac.totalBeds > 0 ? ((fac.totalBeds - fac.availableBeds) / fac.totalBeds) : 0.0;

            return SizedBox(
              width: cardWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF005140).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.local_hospital_rounded, color: Color(0xFF005140), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(fac.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text('${fac.typeDisplay} • ${fac.distanceKm} km from HQ', style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary)),
                            ],
                          ),
                        ),
                        if (fac.hasEmergencyCapability)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('24x7', style: TextStyle(fontSize: 10, color: Color(0xFFB91C1C), fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Bed Occupancy Progress Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isMr ? 'खाटांची स्थिती' : (isHi ? 'बिस्तर की स्थिति' : 'Bed Occupancy'),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.textSecondary),
                        ),
                        Text(
                          '${fac.availableBeds} of ${fac.totalBeds} available',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: fac.availableBeds > 0 ? const Color(0xFF15803D) : RuralCareColors.critical,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: occupancyPercent.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          occupancyPercent > 0.85 ? RuralCareColors.critical : const Color(0xFF005140),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Specialists tag list
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: fac.onDutySpecialists.take(3).map((spec) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(spec, style: const TextStyle(fontSize: 10, color: Color(0xFF334155))),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          fac.contactPhone,
                          style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => _showUpdateBedsDialog(fac),
                          icon: const Icon(Icons.edit_rounded, size: 12),
                          label: const Text('Adjust Beds', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTableView(List<FacilityDto> facilities, bool isHi, bool isMr) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F9FF)),
          columns: const [
            DataColumn(label: Text('Facility Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Distance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Available Beds', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Emergency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Ambulance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ],
          rows: facilities.map((fac) {
            return DataRow(
              cells: [
                DataCell(Text(fac.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                DataCell(Text(fac.typeDisplay, style: const TextStyle(fontSize: 11))),
                DataCell(Text('${fac.distanceKm} km', style: const TextStyle(fontSize: 11))),
                DataCell(Text('${fac.availableBeds}/${fac.totalBeds}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                DataCell(
                  Icon(
                    fac.hasEmergencyCapability ? Icons.check_circle_rounded : Icons.cancel_outlined,
                    size: 16,
                    color: fac.hasEmergencyCapability ? const Color(0xFF15803D) : RuralCareColors.textSecondary,
                  ),
                ),
                DataCell(
                  Icon(
                    fac.hasAmbulanceAvailable ? Icons.emergency_rounded : Icons.remove,
                    size: 16,
                    color: fac.hasAmbulanceAvailable ? const Color(0xFFC05621) : RuralCareColors.textSecondary,
                  ),
                ),
                DataCell(
                  TextButton(
                    onPressed: () => _showUpdateBedsDialog(fac),
                    child: const Text('Update', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
