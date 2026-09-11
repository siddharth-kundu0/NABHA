import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/facility_repository.dart';

class MedicineAvailabilityScreen extends StatefulWidget {
  const MedicineAvailabilityScreen({super.key});

  @override
  State<MedicineAvailabilityScreen> createState() => _MedicineAvailabilityScreenState();
}

class _MedicineAvailabilityScreenState extends State<MedicineAvailabilityScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedMedicine = 'All';

  final List<String> _popularMedicines = [
    'All',
    'Labetalol',
    'Iron & Folic Acid',
    'Metformin',
    'Amoxicillin',
    'Insulin',
    'Oxytocin',
    'Paracetamol',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final facRepo = FacilityRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Medicine Availability'),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: AppColors.forestTeal),
                    hintText: 'Search medicine name, generic salt...',
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceAntiGlare,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _popularMedicines.map((med) {
                      final isSelected = _selectedMedicine == med;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(med, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.neutral800)),
                          selected: isSelected,
                          selectedColor: AppColors.forestTeal,
                          backgroundColor: AppColors.surfaceAntiGlare,
                          onSelected: (selected) {
                            setState(() {
                              _selectedMedicine = selected ? med : 'All';
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListenableBuilder(
              listenable: facRepo,
              builder: (context, _) {
                final query = _searchController.text.trim().toLowerCase();
                final filter = _selectedMedicine == 'All' ? '' : _selectedMedicine.toLowerCase();

                final facilities = facRepo.facilities;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: facilities.length,
                  itemBuilder: (context, idx) {
                    final fac = facilities[idx];
                    final meds = fac.availableMedicines;

                    final matchesSearch = query.isEmpty ||
                        fac.name.toLowerCase().contains(query) ||
                        meds.any((m) => m.toLowerCase().contains(query));

                    final matchesFilter = filter.isEmpty || meds.any((m) => m.toLowerCase().contains(filter));

                    if (!matchesSearch || !matchesFilter) {
                      return const SizedBox.shrink();
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    fac.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.slateNavy.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('${fac.distanceKm} km', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slateNavy)),
                                ),
                              ],
                            ),
                            Text(fac.address, style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
                            const SizedBox(height: 10),
                            const Text('Available Stock / उपलब्ध औषधे:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: meds.map((m) {
                                final isHighlight = (query.isNotEmpty && m.toLowerCase().contains(query)) ||
                                    (filter.isNotEmpty && m.toLowerCase().contains(filter));
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isHighlight ? AppColors.forestTeal.withOpacity(0.15) : AppColors.surfaceAntiGlare,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: isHighlight ? AppColors.forestTeal : AppColors.neutral300),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, size: 12, color: isHighlight ? AppColors.forestTealDark : Colors.green),
                                      const SizedBox(width: 4),
                                      Text(
                                        m,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                                          color: isHighlight ? AppColors.forestTealDark : AppColors.neutral800,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Contact: ${fac.contactPhone}', style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
                                TextButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Reservation request sent to ${fac.name} pharmacy!')),
                                    );
                                  },
                                  icon: const Icon(Icons.bookmark_add, size: 16),
                                  label: const Text('Reserve for Pickup', style: TextStyle(fontSize: 11)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
