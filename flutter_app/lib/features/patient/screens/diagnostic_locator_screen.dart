import 'package:flutter/material.dart';
import 'package:ruralcare/app/routes.dart';
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

  void _showBookTestModal(String testName, String facilityName) {
    String selectedSlot = 'Morning (09:00 - 11:30 AM)';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.biotech_rounded, color: Color(0xFF005140)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Book $testName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Location: $facilityName', style: const TextStyle(fontSize: 12, color: RuralCareColors.textSecondary)),
                const SizedBox(height: 14),
                const Text('Select Time Slot:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedSlot,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'Morning (09:00 - 11:30 AM)', child: Text('Morning (09:00 - 11:30 AM)')),
                    DropdownMenuItem(value: 'Afternoon (12:30 - 02:30 PM)', child: Text('Afternoon (12:30 - 02:30 PM)')),
                    DropdownMenuItem(value: 'Evening (04:00 - 06:00 PM)', child: Text('Evening (04:00 - 06:00 PM)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedSlot = val);
                  },
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Color(0xFF1D4ED8)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Fasting Required: 8 hours overnight for blood sugar and lipid panels.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF1D4ED8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF005140), foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showTokenPassDialog(testName, facilityName, selectedSlot);
                },
                child: const Text('Confirm Appointment'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showTokenPassDialog(String testName, String facilityName, String slot) {
    final token = 'LAB-TK-${DateTime.now().millisecondsSinceEpoch % 10000}';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF15803D)),
            SizedBox(width: 8),
            Text('Lab Token Generated', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_2_rounded, size: 90, color: Color(0xFF005140)),
                  const SizedBox(height: 8),
                  Text(token, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2, fontFamily: 'monospace')),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('$testName at $facilityName', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.center),
            Text('Slot: $slot', style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary)),
            const SizedBox(height: 8),
            const Text('Present this QR token at the phlebotomy desk upon arrival.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B)), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF005140), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
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

        final pageTitle = isHi ? 'निदान जांच केंद्र' : (isMr ? 'निदान चाचणी केंद्र' : 'Diagnostics');
        final searchHint = isHi
            ? 'जांच या लैब खोजें...'
            : (isMr ? 'चाचणी किंवा लॅब शोधा...' : 'Search diagnostic test, lab name...');
        final emptyText = isHi
            ? 'कोई निदान केंद्र नहीं मिला।'
            : (isMr ? 'कोणतेही निदान केंद्र आढळले नाही.' : 'No diagnostic centers match your criteria.');
        final availableServicesLabel = isHi
            ? 'उपलब्ध जांच सेवाएं:'
            : (isMr ? 'उपलब्ध चाचणी सेवा:' : 'Available diagnostic services:');

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
                        children: _tests.map((test) {
                          final isSelected = _selectedTest == test;
                          String label = test;
                          if (test == 'All') {
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
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(emptyText, style: AppTypography.body),
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
                              Text(availableServicesLabel, style: AppTypography.supporting),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: fac.availableDiagnostics.map((diag) {
                                  return InkWell(
                                    onTap: () => _showBookTestModal(diag, fac.name),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: AppDecorations.statusBadge(
                                        background: RuralCareColors.tealSoft,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            diag,
                                            style: const TextStyle(
                                              fontFamily: AppTypography.fontFamily,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: RuralCareColors.teal,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.add_circle_outline, size: 12, color: RuralCareColors.teal),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    fac.contactPhone,
                                    style: AppTypography.supporting,
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF005140),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () {
                                      final test = fac.availableDiagnostics.isNotEmpty ? fac.availableDiagnostics.first : 'Diagnostic Evaluation';
                                      _showBookTestModal(test, fac.name);
                                    },
                                    icon: const Icon(Icons.calendar_today_rounded, size: 12),
                                    label: const Text('Book Test Slot', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
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
