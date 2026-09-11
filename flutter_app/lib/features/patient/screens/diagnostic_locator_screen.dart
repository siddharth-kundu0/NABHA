import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/facility_repository.dart';

class DiagnosticLocatorScreen extends StatefulWidget {
  const DiagnosticLocatorScreen({super.key});

  @override
  State<DiagnosticLocatorScreen> createState() => _DiagnosticLocatorScreenState();
}

class _DiagnosticLocatorScreenState extends State<DiagnosticLocatorScreen> {
  String _selectedTest = 'All Tests';

  final List<String> _tests = [
    'All Tests',
    'Ultrasound (USG)',
    'CBC',
    'Blood Sugar',
    'ECG',
    'X-Ray',
    'Urine Albumin',
    'CT Scan',
  ];

  @override
  Widget build(BuildContext context) {
    final facRepo = FacilityRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic & Lab Services'),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _tests.map((test) {
                  final isSelected = _selectedTest == test;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(test, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.neutral800)),
                      selected: isSelected,
                      selectedColor: AppColors.slateNavy,
                      backgroundColor: AppColors.surfaceAntiGlare,
                      onSelected: (selected) {
                        setState(() {
                          _selectedTest = test;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListenableBuilder(
              listenable: facRepo,
              builder: (context, _) {
                final facilities = facRepo.facilities;
                final filter = _selectedTest == 'All Tests' ? '' : _selectedTest.toLowerCase();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: facilities.length,
                  itemBuilder: (context, idx) {
                    final fac = facilities[idx];
                    final diags = fac.availableDiagnostics;

                    final hasMatchingDiag = filter.isEmpty || diags.any((d) => d.toLowerCase().contains(filter));

                    if (!hasMatchingDiag) {
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
                                    color: AppColors.forestTeal.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('${fac.distanceKm} km', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.forestTealDark)),
                                ),
                              ],
                            ),
                            Text(fac.address, style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
                            const SizedBox(height: 10),
                            const Text('Available Diagnostics / चाचण्या:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: diags.map((d) {
                                final isHighlight = filter.isNotEmpty && d.toLowerCase().contains(filter);
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isHighlight ? AppColors.terracotta.withOpacity(0.12) : AppColors.surfaceAntiGlare,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: isHighlight ? AppColors.terracotta : AppColors.neutral300),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.biotech, size: 13, color: isHighlight ? AppColors.terracotta : AppColors.slateNavy),
                                      const SizedBox(width: 4),
                                      Text(
                                        d,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                                          color: isHighlight ? AppColors.terracotta : AppColors.neutral800,
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
                                Text('Timings: 08:00 AM - 04:00 PM', style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
                                ElevatedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Lab slot requested at ${fac.name}. Token sent to your SMS!')),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.slateNavy,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: const Size(80, 34),
                                  ),
                                  child: const Text('Book Test', style: TextStyle(fontSize: 11)),
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
