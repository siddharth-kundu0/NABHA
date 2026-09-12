import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';

/// Medicine Availability Screen conforming strictly to DESIGN.md Section 6:
/// Search first, simple results with facility availability and last-updated info.
/// Distinguishes between "Available", "Unavailable", and "Information unavailable".
class MedicineAvailabilityScreen extends StatefulWidget {
  const MedicineAvailabilityScreen({super.key});

  @override
  State<MedicineAvailabilityScreen> createState() => _MedicineAvailabilityScreenState();
}

class _MedicineAvailabilityScreenState extends State<MedicineAvailabilityScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Labetalol',
    'Iron & Folic Acid',
    'Amoxicillin',
    'Metformin',
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
      backgroundColor: RuralCareColors.canvas,
      appBar: AppBar(
        title: const Text('Medicines', style: AppTypography.pageTitle),
        backgroundColor: RuralCareColors.surface,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: RuralCareColors.border, height: 1),
        ),
      ),
      body: Column(
        children: [
          // Search Header Area
          Container(
            color: RuralCareColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: RuralCareColors.textSecondary, size: 22),
                    hintText: 'Search medicine name, generic salt...',
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          selectedColor: RuralCareColors.primarySoft,
                          backgroundColor: RuralCareColors.surface,
                          labelStyle: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? RuralCareColors.primary : RuralCareColors.textSecondary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? RuralCareColors.primary : RuralCareColors.border,
                            ),
                          ),
                          onSelected: (selected) {
                            setState(() => _selectedFilter = selected ? filter : 'All');
                          },
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: RuralCareColors.border, height: 1),

          // Results List
          Expanded(
            child: ListenableBuilder(
              listenable: facRepo,
              builder: (context, _) {
                final query = _searchController.text.trim().toLowerCase();
                final filter = _selectedFilter == 'All' ? '' : _selectedFilter.toLowerCase();

                final medicines = [
                  {
                    'name': 'Labetalol Hydrochloride 100mg',
                    'facility': 'Baramati Sub-District Hospital',
                    'status': 'Available',
                    'updated': 'Updated 2 hours ago',
                  },
                  {
                    'name': 'Iron & Folic Acid (IFA) Tablets',
                    'facility': 'Kashti Primary Health Centre',
                    'status': 'Available',
                    'updated': 'Updated today, 09:00 AM',
                  },
                  {
                    'name': 'Amoxicillin 500mg Capsules',
                    'facility': 'Rampur Sub-Centre',
                    'status': 'Unavailable',
                    'updated': 'Stock exhausted • Reorder pending',
                  },
                  {
                    'name': 'Metformin Hydrochloride 500mg',
                    'facility': 'Baramati Sub-District Hospital',
                    'status': 'Available',
                    'updated': 'Updated 4 hours ago',
                  },
                  {
                    'name': 'Paracetamol 500mg Tablets',
                    'facility': 'Daund Community Health Centre',
                    'status': 'Available',
                    'updated': 'Updated yesterday',
                  },
                  {
                    'name': 'Oxytocin Injection 10 IU',
                    'facility': 'Kashti Sub-Centre',
                    'status': 'Information unavailable',
                    'updated': 'Facility sync pending',
                  },
                ].where((m) {
                  final name = (m['name'] ?? '').toLowerCase();
                  final fac = (m['facility'] ?? '').toLowerCase();
                  final matchesQuery = query.isEmpty || name.contains(query) || fac.contains(query);
                  final matchesFilter = filter.isEmpty || name.contains(filter);
                  return matchesQuery && matchesFilter;
                }).toList();

                if (medicines.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No matching medicines found.', style: AppTypography.body),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  itemCount: medicines.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final item = medicines[idx];
                    final status = item['status'] as String;
                    final isAvailable = status == 'Available';
                    final isUnavailable = status == 'Unavailable';

                    return Container(
                      decoration: AppDecorations.card(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(item['name']!, style: AppTypography.cardTitle),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: AppDecorations.statusBadge(
                                  background: isAvailable
                                      ? RuralCareColors.successSoft
                                      : (isUnavailable ? RuralCareColors.criticalSoft : RuralCareColors.surfaceSubtle),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isAvailable
                                        ? RuralCareColors.success
                                        : (isUnavailable ? RuralCareColors.critical : RuralCareColors.textSecondary),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(item['facility']!, style: AppTypography.supporting),
                          const SizedBox(height: 6),
                          Text(
                            item['updated']!,
                            style: AppTypography.supporting.copyWith(
                              fontSize: 12,
                              color: RuralCareColors.textSecondary.withOpacity(0.8),
                            ),
                          ),
                        ],
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
