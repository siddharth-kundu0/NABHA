import 'package:flutter/material.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/features/emergency/screens/emergency_tracking_screen.dart';

/// Screen 3: Language & Accessibility (V2 Modern)
/// Exactly reproducing Stitch Screen `3ece77d1b3cc40a2bc028993c49960d3`
class LanguageAccessibilityScreen extends StatefulWidget {
  const LanguageAccessibilityScreen({super.key});

  @override
  State<LanguageAccessibilityScreen> createState() => _LanguageAccessibilityScreenState();
}

class _LanguageAccessibilityScreenState extends State<LanguageAccessibilityScreen> {
  bool _showSavedToast = false;

  @override
  Widget build(BuildContext context) {
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(102),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Global Row
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: Color(0xFF104A7B),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'RuralCare',
                              style: TextStyle(
                                fontFamily: 'Noto Sans',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF104A7B),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Language Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: () => session.switchLanguage('en'),
                                    child: Text(
                                      'EN',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: session.isEnglish ? const Color(0xFF0A6B56) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  const Text(' | ', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                                  InkWell(
                                    onTap: () => session.switchLanguage('hi'),
                                    child: Text(
                                      'हि',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: session.isHindi ? const Color(0xFF0A6B56) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  const Text(' | ', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                                  InkWell(
                                    onTap: () => session.switchLanguage('mr'),
                                    child: Text(
                                      'म',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: session.isMarathi ? const Color(0xFF0A6B56) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Emergency Button
                            InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (ctx) => const EmergencyTrackingScreen()),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.emergency_rounded, color: Colors.white, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      session.isHindi
                                          ? 'आपातकालीन सहायता'
                                          : (session.isMarathi ? 'तातडीची मदत' : 'Emergency Help'),
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(color: Color(0xFFE2E8F0), height: 1),
                // Sub-header with Back button & Centered Title
                Container(
                  color: Colors.white,
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.arrow_back, size: 18, color: Color(0xFF475569)),
                              const SizedBox(width: 4),
                              Text(
                                session.isHindi ? 'वापस' : (session.isMarathi ? 'मागे' : 'Back'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            session.isHindi
                                ? 'भाषा एवं सुगमता'
                                : (session.isMarathi ? 'भाषा आणि सुलभता' : 'Language & Accessibility'),
                            style: const TextStyle(
                              fontFamily: 'Noto Sans',
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                      const Icon(Icons.tune_rounded, color: Color(0xFF64748B), size: 18),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFFE2E8F0), height: 1),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Language Selector Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.language_rounded, color: Color(0xFF0A6B56), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Choose Language / भाषा चुनें',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Text(
                        'Active: ${session.isHindi ? "हिन्दी" : (session.isMarathi ? "मराठी" : "English")}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0A6B56),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'Select your preferred language for clinic visits and records',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),

                // 3 Language Cards
                _buildLanguageCard(
                  code: 'EN',
                  title: 'English',
                  subtitle: 'Standard Clinical Terminology',
                  tag: 'Default',
                  isSelected: session.isEnglish,
                  onTap: () => session.switchLanguage('en'),
                ),
                const SizedBox(height: 10),
                _buildLanguageCard(
                  code: 'हि',
                  title: 'हिन्दी',
                  secondaryTitle: '(Hindi)',
                  subtitle: 'ग्रामीण स्वास्थ्य इंटरफ़ेस',
                  isSelected: session.isHindi,
                  onTap: () => session.switchLanguage('hi'),
                ),
                const SizedBox(height: 10),
                _buildLanguageCard(
                  code: 'म',
                  title: 'मराठी',
                  secondaryTitle: '(Marathi)',
                  subtitle: 'स्थानिक आरोग्य इंटरफेस',
                  isSelected: session.isMarathi,
                  onTap: () => session.switchLanguage('mr'),
                ),


                const SizedBox(height: 22),

                // 2. Display & Reading Preferences Section
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.visibility_outlined, color: Color(0xFF0A6B56), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Display & Reading Preferences',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    Text(
                      'सुगमता',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildToggleRow(
                        iconWidget: const Text('Aa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        title: 'Larger Text (बड़ा टेक्स्ट)',
                        subtitle: 'Make text easier to read.',
                        value: session.largerText,
                        onChanged: (v) => session.toggleLargerText(v),
                      ),
                      const Divider(color: Color(0xFFE2E8F0), height: 1),
                      _buildToggleRow(
                        iconWidget: const Icon(Icons.wb_sunny_outlined, size: 20, color: Color(0xFF475569)),
                        title: 'High Contrast (उच्च कंट्रास्ट)',
                        subtitle: 'Improve contrast for bright sunlight.',
                        value: session.highContrast,
                        onChanged: (v) => session.toggleHighContrast(v),
                      ),
                      const Divider(color: Color(0xFFE2E8F0), height: 1),
                      _buildToggleRow(
                        iconWidget: const Icon(Icons.motion_photos_off_outlined, size: 20, color: Color(0xFF475569)),
                        title: 'Reduce Motion (गति कम करें)',
                        subtitle: 'Minimize transitions and motion.',
                        value: session.reduceMotion,
                        onChanged: (v) => session.toggleReduceMotion(v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. Live Typography Sample
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LIVE TYPOGRAPHY SAMPLE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      'Real-time preview',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1B2A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A6B56).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF0A6B56)),
                        ),
                        child: const Icon(Icons.format_size_rounded, color: Color(0xFF34D399), size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Preview',
                              style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              session.isHindi
                                  ? 'परामर्श और पर्चा'
                                  : (session.isMarathi ? 'सल्ला व औषधोपचार' : 'Sample Heading'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: session.largerText ? 16 : 14.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              session.isHindi
                                  ? 'पठनीयता जांच के लिए उदाहरण पाठ।'
                                  : (session.isMarathi ? 'वाचन सुलभतेसाठी प्रात्यक्षिक मजकूर.' : 'Example text for display readability and size preview.'),
                              style: TextStyle(
                                color: const Color(0xFF94A3B8),
                                fontSize: session.largerText ? 12.5 : 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 4. Apply Settings CTA Button (Solid Teal #0A6B56)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A6B56),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      setState(() => _showSavedToast = true);
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) {
                          setState(() => _showSavedToast = false);
                        }
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Preferences saved and updated for all clinic records!'),
                          backgroundColor: Color(0xFF0A6B56),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Apply Settings / प्राथमिकताएं सहेजें',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showSavedToast) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF15803D), size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Preferences saved and updated for all clinic records!',
                            style: TextStyle(
                              color: Color(0xFF15803D),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageCard({
    required String code,
    required String title,
    String? secondaryTitle,
    required String subtitle,
    String? tag,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minHeight: 62),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF0A6B56) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0A6B56) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  code,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF334155),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                      if (secondaryTitle != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          secondaryTitle,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                      if (tag != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF0A6B56)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF0A6B56) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? const Color(0xFF0A6B56) : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required Widget iconWidget,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: iconWidget),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: const Color(0xFF0A6B56),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
