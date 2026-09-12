import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
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
        final activeLang = session.activeLanguage;

        return Scaffold(
          backgroundColor: RuralCareColors.canvas,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(105),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Global Row
                Container(
                  color: RuralCareColors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              decoration: BoxDecoration(
                                color: RuralCareColors.primarySoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.local_hospital_rounded, color: RuralCareColors.primary, size: 18),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'RuralCare',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: RuralCareColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Language Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: RuralCareColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: RuralCareColors.border),
                              ),
                              child: Text(
                                activeLang == 'Hindi' ? 'हिन्दी' : (activeLang == 'Marathi' ? 'मराठी' : 'EN'),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.textPrimary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Compact Emergency Help
                            InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (ctx) => const EmergencyTrackingScreen()),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: RuralCareColors.critical,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.emergency_rounded, color: Colors.white, size: 13),
                                    SizedBox(width: 4),
                                    Text(
                                      'Emergency',
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
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
                const Divider(color: RuralCareColors.border, height: 1),
                // Sub-header title row with Back Button
                Container(
                  color: RuralCareColors.surface,
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: RuralCareColors.textPrimary, size: 20),
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'Language & Accessibility',
                          style: AppTypography.cardTitle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.tune_rounded, color: RuralCareColors.textSecondary, size: 20),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                const Divider(color: RuralCareColors.border, height: 1),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Language Selector Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.language_rounded, color: RuralCareColors.teal, size: 20),
                        SizedBox(width: 8),
                        Text('Choose Language / भाषा चुनें', style: AppTypography.cardTitle),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: AppDecorations.statusBadge(background: RuralCareColors.tealSoft),
                      child: Text(
                        'Active: $activeLang',
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: RuralCareColors.teal,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select your preferred language for clinic visits and records',
                  style: AppTypography.supporting,
                ),
                const SizedBox(height: 12),

                // 3 Language Cards
                _buildLanguageCard(
                  code: 'EN',
                  title: 'English',
                  subtitle: 'Standard Clinical Terminology',
                  tag: 'Default',
                  isSelected: activeLang == 'English',
                  onTap: () => session.switchLanguage('English'),
                ),
                const SizedBox(height: 10),
                _buildLanguageCard(
                  code: 'हि',
                  title: 'हिन्दी',
                  secondaryTitle: '(Hindi)',
                  subtitle: 'ग्रामीण स्वास्थ्य इंटरफ़ेस',
                  isSelected: activeLang == 'Hindi',
                  onTap: () => session.switchLanguage('Hindi'),
                ),
                const SizedBox(height: 10),
                _buildLanguageCard(
                  code: 'म',
                  title: 'मराठी',
                  secondaryTitle: '(Marathi)',
                  subtitle: 'स्थानिक आरोग्य इंटरफेस',
                  isSelected: activeLang == 'Marathi',
                  onTap: () => session.switchLanguage('Marathi'),
                ),

                const SizedBox(height: 24),

                // 2. Display & Reading Preferences Section
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.visibility_outlined, color: RuralCareColors.teal, size: 20),
                        SizedBox(width: 8),
                        Text('Display & Reading Preferences', style: AppTypography.cardTitle),
                      ],
                    ),
                    Text('सुगमता', style: AppTypography.supporting),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: AppDecorations.card(),
                  child: Column(
                    children: [
                      _buildToggleRow(
                        iconWidget: const Text('Aa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        title: 'Larger Text (बड़ा टेक्स्ट)',
                        subtitle: 'Make text easier to read throughout clinic records.',
                        value: session.largerText,
                        onChanged: (v) => session.toggleLargerText(v),
                      ),
                      const Divider(color: RuralCareColors.border, height: 1),
                      _buildToggleRow(
                        iconWidget: const Icon(Icons.wb_sunny_outlined, size: 20, color: RuralCareColors.textPrimary),
                        title: 'High Contrast (उच्च कंट्रास्ट)',
                        subtitle: 'Improve contrast for bright sunlight in outdoor fields.',
                        value: session.highContrast,
                        onChanged: (v) => session.toggleHighContrast(v),
                      ),
                      const Divider(color: RuralCareColors.border, height: 1),
                      _buildToggleRow(
                        iconWidget: const Icon(Icons.motion_photos_off_outlined, size: 20, color: RuralCareColors.textPrimary),
                        title: 'Reduce Motion (गति कम करें)',
                        subtitle: 'Minimize transitions and animations on slower screens.',
                        value: session.reduceMotion,
                        onChanged: (v) => session.toggleReduceMotion(v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Live Typography Sample
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('LIVE TYPOGRAPHY SAMPLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RuralCareColors.textSecondary)),
                    Text('Real-time preview', style: AppTypography.supporting),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: RuralCareColors.teal.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: RuralCareColors.teal.withOpacity(0.4)),
                        ),
                        child: const Icon(Icons.format_size_rounded, color: Color(0xFF34D399), size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Preview / पूर्वावलोकन',
                              style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              activeLang == 'Hindi'
                                  ? 'डॉक्टर परामर्श एवं पर्चा'
                                  : (activeLang == 'Marathi' ? 'डॉक्टर सल्ला व औषधोपचार' : 'Clinical Consultation & Prescription'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: session.largerText ? 16 : 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activeLang == 'Hindi'
                                  ? 'पठनीयता जांच के लिए उदाहरण पाठ'
                                  : (activeLang == 'Marathi' ? 'वाचन सुलभतेसाठी प्रात्यक्षिक मजकूर' : 'Example text for display readability and size preview.'),
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: session.largerText ? 13 : 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // 4. Apply Settings CTA Button (52px)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: AppDecorations.primaryButton(),
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
                          backgroundColor: RuralCareColors.teal,
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Apply Settings / प्राथमिकताएं सहेजें'),
                      ],
                    ),
                  ),
                ),

                if (_showSavedToast) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: RuralCareColors.successSoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: RuralCareColors.success.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: RuralCareColors.success, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Preferences saved and updated for all clinic records!',
                            style: TextStyle(
                              color: RuralCareColors.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),
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
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? RuralCareColors.primarySoft.withOpacity(0.4) : RuralCareColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? RuralCareColors.teal : RuralCareColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? RuralCareColors.teal : RuralCareColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  code,
                  style: TextStyle(
                    color: isSelected ? Colors.white : RuralCareColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: AppTypography.cardTitle),
                      if (secondaryTitle != null) ...[
                        const SizedBox(width: 4),
                        Text(secondaryTitle, style: AppTypography.supporting),
                      ],
                      if (tag != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: AppDecorations.statusBadge(background: RuralCareColors.tealSoft),
                          child: Text(
                            tag,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: RuralCareColors.teal),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.supporting),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? RuralCareColors.teal : Colors.transparent,
                border: Border.all(
                  color: isSelected ? RuralCareColors.teal : RuralCareColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: RuralCareColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: iconWidget),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.supporting),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: RuralCareColors.teal,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
