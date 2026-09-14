import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/models/facility_dto.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';
import 'package:ruralcare/app/routes.dart';

/// Dedicated Citizen Screen: Find Hospitals & Beds (Read-only clinical directory)
/// Replaces internal FacilityOperationsScreen for patient profile
class FindFacilityScreen extends StatefulWidget {
  const FindFacilityScreen({super.key});

  @override
  State<FindFacilityScreen> createState() => _FindFacilityScreenState();
}

class _FindFacilityScreenState extends State<FindFacilityScreen> {
  final FacilityRepository _facRepo = FacilityRepository();
  final SessionCoordinator _session = SessionCoordinator();

  String _searchQuery = '';
  String _selectedFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_facRepo, _session]),
      builder: (context, _) {
        final isMr = _session.isMr;
        final isHi = _session.isHi;
        final allFacilities = _facRepo.facilities;

        final filtered = allFacilities.where((fac) {
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final matches = fac.name.toLowerCase().contains(q) ||
                fac.address.toLowerCase().contains(q) ||
                fac.typeDisplay.toLowerCase().contains(q);
            if (!matches) return false;
          }

          if (_selectedFilter == 'EMERGENCY' && !fac.hasEmergencyCapability) return false;
          if (_selectedFilter == 'AMBULANCE' && !fac.hasAmbulanceAvailable) return false;
          if (_selectedFilter == 'AVAILABLE_BEDS' && fac.availableBeds <= 0) return false;

          return true;
        }).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              isMr ? 'रुग्णालये व खाटांची उपलब्धता' : (isHi ? 'अस्पताल व बिस्तर उपलब्धता' : 'Find Hospitals & Beds'),
              style: const TextStyle(
                fontFamily: 'Noto Sans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(color: Color(0xFFE2E8F0), height: 1),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live Transparency Notice
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF005140).withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: Color(0xFF005140), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isMr
                              ? 'सर्व खाटांची माहिती थेट शासकीय आरोग्य नेटवर्कशी सिंक आहे.'
                              : (isHi
                                  ? 'सभी बिस्तरों की जानकारी सरकारी स्वास्थ्य नेटवर्क से लाइव सिंक है।'
                                  : 'Live bed occupancy synchronized directly with Rampur District Health Network.'),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF005140), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Search Box
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: isMr ? 'रुग्णालय किंवा ठिकाण शोधा...' : (isHi ? 'अस्पताल या स्थान खोजें...' : 'Search hospital, block, or village...'),
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF005140)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('ALL', isMr ? 'सर्व संस्था' : (isHi ? 'सभी केंद्र' : 'All Facilities')),
                      const SizedBox(width: 8),
                      _filterChip('EMERGENCY', isMr ? '२४x७ आपत्कालीन' : (isHi ? '24x7 इमरजेंसी' : '24x7 Emergency')),
                      const SizedBox(width: 8),
                      _filterChip('AMBULANCE', isMr ? 'रुग्णवाहिका उपलब्ध' : (isHi ? 'एम्बुलेंस उपलब्ध' : 'Ambulance Stationed')),
                      const SizedBox(width: 8),
                      _filterChip('AVAILABLE_BEDS', isMr ? 'खाटा शिल्लक' : (isHi ? 'बिस्तर उपलब्ध' : 'Beds Available')),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Facility Cards List
                if (filtered.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    alignment: Alignment.center,
                    child: const Column(
                      children: [
                        Icon(Icons.search_off_rounded, size: 40, color: RuralCareColors.textSecondary),
                        SizedBox(height: 8),
                        Text('No facilities match your search criteria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                    itemBuilder: (ctx, i) {
                      final fac = filtered[i];
                      return _buildCitizenFacilityCard(fac, isHi, isMr);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _filterChip(String code, String label) {
    final isSelected = _selectedFilter == code;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF005140),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : const Color(0xFF475569),
      ),
      onSelected: (_) => setState(() => _selectedFilter = code),
    );
  }

  Widget _buildCitizenFacilityCard(FacilityDto fac, bool isHi, bool isMr) {
    final occupancyPercent = fac.totalBeds > 0 ? ((fac.totalBeds - fac.availableBeds) / fac.totalBeds) : 0.0;
    final hasBeds = fac.availableBeds > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF005140).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_hospital_rounded, color: Color(0xFF005140), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fac.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text('${fac.typeDisplay} • ${fac.distanceKm} km away', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              if (fac.hasEmergencyCapability)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('24x7 ICU', style: TextStyle(fontSize: 10, color: Color(0xFFB91C1C), fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Read-only Bed Availability Display
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isMr ? 'खाटांची सद्यस्थिती:' : (isHi ? 'बिस्तर की स्थिति:' : 'Live Bed Status:'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                    Text(
                      '${fac.availableBeds} Available (Total: ${fac.totalBeds})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: hasBeds ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
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
                      occupancyPercent > 0.85 ? const Color(0xFFB91C1C) : const Color(0xFF005140),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Specialists on duty
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: fac.onDutySpecialists.map((spec) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(spec, style: const TextStyle(fontSize: 11, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w500)),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Calling ${fac.name} at ${fac.contactPhone}...')),
                    );
                  },
                  icon: const Icon(Icons.phone_rounded, size: 16),
                  label: Text(
                    isMr ? 'संपर्क करा' : (isHi ? 'संपर्क करें' : 'Call Hospital'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (fac.hasAmbulanceAvailable) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005140),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Connecting to 108 Emergency Dispatch for ${fac.name}...'),
                          backgroundColor: const Color(0xFF005140),
                        ),
                      );
                    },
                    icon: const Icon(Icons.emergency_rounded, size: 16),
                    label: const Text('108 Dispatch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
