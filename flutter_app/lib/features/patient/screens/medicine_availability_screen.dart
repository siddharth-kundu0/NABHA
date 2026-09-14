import 'package:flutter/material.dart';
import 'package:ruralcare/app/routes.dart';
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
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final isHi = session.isHindi;
        final isMr = session.isMarathi;

        final pageTitle = isHi ? 'दवा उपलब्धता' : (isMr ? 'औषध उपलब्धता' : 'Medicines');
        final searchHint = isHi
            ? 'दवा का नाम या सॉल्ट खोजें...'
            : (isMr ? 'औषधाचे नाव शोधा...' : 'Search medicine name, generic salt...');
        final emptyText = isHi
            ? 'कोई मेल खाती दवा नहीं मिली।'
            : (isMr ? 'कोणतेही औषध आढळले नाही.' : 'No matching medicines found.');

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
                        hintText: searchHint,
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
                          String label = filter;
                          if (filter == 'All') {
                            label = isHi ? 'सभी' : (isMr ? 'सर्व' : 'All');
                          }

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(label),
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
                        'facility': isHi ? 'बारामती उप-जिला अस्पताल' : (isMr ? 'बारामती उपजिल्हा रुग्णालय' : 'Baramati Sub-District Hospital'),
                        'status': 'Available',
                        'updated': isHi ? '2 घंटे पहले अपडेट किया गया' : (isMr ? '२ तासांपूर्वी अपडेट केले' : 'Updated 2 hours ago'),
                      },
                      {
                        'name': 'Iron & Folic Acid (IFA) Tablets',
                        'facility': isHi ? 'काष्टी प्राथमिक स्वास्थ्य केंद्र' : (isMr ? 'काष्टी प्राथमिक आरोग्य केंद्र' : 'Kashti Primary Health Centre'),
                        'status': 'Available',
                        'updated': isHi ? 'आज सुबह 09:00 बजे अपडेट किया गया' : (isMr ? 'आज सकाळी ०९:०० वाजता अपडेट केले' : 'Updated today, 09:00 AM'),
                      },
                      {
                        'name': 'Amoxicillin 500mg Capsules',
                        'facility': isHi ? 'रामपूर उप-केंद्र' : (isMr ? 'रामपूर उप-केंद्र' : 'Rampur Sub-Centre'),
                        'status': 'Unavailable',
                        'updated': isHi ? 'स्टॉक समाप्त • पुनरावृत्ति लंबित' : (isMr ? 'स्टॉक संपला • पुनर्रचना प्रलंबित' : 'Stock exhausted • Reorder pending'),
                      },
                      {
                        'name': 'Metformin Hydrochloride 500mg',
                        'facility': isHi ? 'बारामती उप-जिला अस्पताल' : (isMr ? 'बारामती उपजिल्हा रुग्णालय' : 'Baramati Sub-District Hospital'),
                        'status': 'Available',
                        'updated': isHi ? '4 घंटे पहले अपडेट किया गया' : (isMr ? '४ तासांपूर्वी अपडेट केले' : 'Updated 4 hours ago'),
                      },
                      {
                        'name': 'Paracetamol 500mg Tablets',
                        'facility': isHi ? 'दौंड सामुदायिक स्वास्थ्य केंद्र' : (isMr ? 'दौंड समुदाय आरोग्य केंद्र' : 'Daund Community Health Centre'),
                        'status': 'Available',
                        'updated': isHi ? 'कल अपडेट किया गया' : (isMr ? 'काल अपडेट केले' : 'Updated yesterday'),
                      },
                      {
                        'name': 'Oxytocin Injection 10 IU',
                        'facility': isHi ? 'काष्टी उप-केंद्र' : (isMr ? 'काष्टी उप-केंद्र' : 'Kashti Sub-Centre'),
                        'status': 'Information unavailable',
                        'updated': isHi ? 'सिंक लंबित' : (isMr ? 'सिंक प्रलंबित' : 'Facility sync pending'),
                      },
                    ].where((m) {
                      final name = (m['name'] ?? '').toLowerCase();
                      final fac = (m['facility'] ?? '').toLowerCase();
                      final matchesQuery = query.isEmpty || name.contains(query) || fac.contains(query);
                      final matchesFilter = filter.isEmpty || name.contains(filter);
                      return matchesQuery && matchesFilter;
                    }).toList();

                    if (medicines.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(emptyText, style: AppTypography.body),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      itemCount: medicines.length,
                      separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                      itemBuilder: (ctx, idx) {
                        final item = medicines[idx];
                        final rawStatus = item['status'] as String;
                        final isAvailable = rawStatus == 'Available';
                        final isUnavailable = rawStatus == 'Unavailable';

                        String statusLabel = rawStatus;
                        if (isAvailable) {
                          statusLabel = isHi ? 'उपलब्ध' : (isMr ? 'उपलब्ध' : 'Available');
                        } else if (isUnavailable) {
                          statusLabel = isHi ? 'स्टॉक समाप्त' : (isMr ? 'स्टॉक संपला' : 'Unavailable');
                        } else {
                          statusLabel = isHi ? 'जानकारी अनुपलब्ध' : (isMr ? 'माहिती उपलब्ध नाही' : 'Information unavailable');
                        }

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
                                      statusLabel,
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
      },
    );
  }
}
