import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/data/repositories/facility_repository.dart';

/// Diagnostic Locator Screen conforming strictly to DESIGN.md Section 6:
/// Search first, simple results with facility availability and last-updated info.
/// Clear separation between test info, availability, and facility capabilities.
class DiagnosticLocatorScreen extends StatefulWidget {
  const DiagnosticLocatorScreen({super.key});

  @override
  State<DiagnosticLocatorScreen> createState() => _DiagnosticLocatorScreenState();
}

class _DiagnosticLocatorScreenState extends State<DiagnosticLocatorScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedTest = 'All';

  final List<String> _tests = [
    'All',
    'Ultrasound (USG)',
    'CBC / Hb',
    'Blood Sugar',
    'ECG',
    'X-Ray',
    'Urine Albumin',
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
        title: const Text('Diagnostics', style: AppTypography.pageTitle),
        backgroundColor: RuralCareColors.surface,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: RuralCareColors.border, height: 1),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: RuralCareColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: RuralCareColors.textSecondary, size: 22),
                    hintText: 'Search diagnostic test, lab name...',
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
                    children: _tests.map((test) {
                      final isSelected = _selectedTest == test;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(test),
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
                            setState(() => _selectedTest = selected ? test : 'All');
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

          // Facility & Test Availability List
          Expanded(
            child: ListenableBuilder(
              listenable: facRepo,
              builder: (context, _) {
                final facilities = facRepo.facilities;
                final query = _searchController.text.trim().toLowerCase();
                final filter = _selectedTest == 'All' ? '' : _selectedTest.toLowerCase();

                final filtered = facilities.where((f) {
                  final matchesQuery = query.isEmpty ||
                      f.name.toLowerCase().contains(query) ||
                      f.availableDiagnostics.any((d) => d.toLowerCase().contains(query));
                  final matchesFilter = filter.isEmpty ||
                      f.availableDiagnostics.any((d) => d.toLowerCase().contains(filter));
                  return matchesQuery && matchesFilter;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No diagnostic centers match your criteria.', style: AppTypography.body),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  itemCount: filtered.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(height: 14),
                  itemBuilder: (ctx, idx) {
                    final fac = filtered[idx];

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
                                child: Text(fac.name, style: AppTypography.cardTitle),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: AppDecorations.statusBadge(background: RuralCareColors.surfaceSubtle),
                                child: Text(
                                  '${fac.distanceKm} km',
                                  style: const TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: RuralCareColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(fac.typeDisplay, style: AppTypography.supporting),
                          const SizedBox(height: 12),
                          const Text('Available diagnostic services:', style: AppTypography.supporting),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: fac.availableDiagnostics.map((diag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: AppDecorations.statusBadge(
                                  background: RuralCareColors.tealSoft,
                                ),
                                child: Text(
                                  diag,
                                  style: const TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: RuralCareColors.teal,
                                  ),
                                ),
                              );
                            }).toList(),
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
