import 'package:flutter/material.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/data/models/triage_dto.dart';
import 'package:ruralcare/core/services/clinical_triage_engine.dart';
import 'package:ruralcare/data/repositories/emergency_repository.dart';
import 'package:ruralcare/features/emergency/screens/emergency_tracking_screen.dart';

class BodyDiagramSelection {
  final AnatomicalRegionDto region;
  final String activeZone;
  final List<String> selectedSymptoms;
  final bool isRedFlag;
  final String? redFlagWarning;
  final EmergencyProtocol? emergencyProtocol;

  const BodyDiagramSelection({
    required this.region,
    required this.activeZone,
    required this.selectedSymptoms,
    required this.isRedFlag,
    this.redFlagWarning,
    this.emergencyProtocol,
  });
}

class VisualBodyDiagramWidget extends StatefulWidget {
  final ValueChanged<BodyDiagramSelection>? onSelectionChanged;

  const VisualBodyDiagramWidget({
    super.key,
    this.onSelectionChanged,
  });

  @override
  State<VisualBodyDiagramWidget> createState() => _VisualBodyDiagramWidgetState();
}

class _VisualBodyDiagramWidgetState extends State<VisualBodyDiagramWidget>
    with SingleTickerProviderStateMixin {
  AnatomicalView _currentView = AnatomicalView.anterior;
  late AnatomicalRegionDto _selectedRegion;
  final Set<int> _selectedSymptomIndices = {0};
  Offset? _lastTapPosition;
  bool _isRedFlag = false;
  String? _redFlagWarning;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    final triageEngine = ClinicalTriageEngine();
    // Default to right forehead or first region
    _selectedRegion = triageEngine.getRegionById('forehead_right');
    _selectedSymptomIndices.clear();
    _selectedSymptomIndices.add(0);
    _checkRedFlagStatus();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Safe initial callback post frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _notifyParent();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _checkRedFlagStatus() {
    // Red flag if region is intrinsically high risk or user selected acute danger symptoms
    bool flag = _selectedRegion.isHighRisk;
    final session = SessionCoordinator();
    final isHi = session.isHindi;
    final isMr = session.isMarathi;
    String warning = _selectedRegion.emergencyProtocol.localizedWarning(isHi, isMr);

    _isRedFlag = flag;
    _redFlagWarning = warning;
  }

  void _notifyParent() {
    final session = SessionCoordinator();
    final isHi = session.isHindi;
    final isMr = session.isMarathi;
    final symptomsList = _selectedRegion.localizedSymptoms(isHi, isMr);
    final activeSymptoms = _selectedSymptomIndices
        .where((i) => i < symptomsList.length)
        .map((i) => symptomsList[i])
        .toList();

    widget.onSelectionChanged?.call(
      BodyDiagramSelection(
        region: _selectedRegion,
        activeZone: _selectedRegion.localizedName(isHi, isMr),
        selectedSymptoms: activeSymptoms.isNotEmpty ? activeSymptoms : (symptomsList.isNotEmpty ? [symptomsList.first] : []),
        isRedFlag: _isRedFlag,
        redFlagWarning: _selectedRegion.emergencyProtocol.localizedWarning(isHi, isMr),
        emergencyProtocol: _selectedRegion.emergencyProtocol,
      ),
    );
  }

  void _handleCanvasTap(Offset localPos, Size canvasSize) {
    final normX = (localPos.dx / canvasSize.width).clamp(0.0, 1.0);
    final normY = (localPos.dy / canvasSize.height).clamp(0.0, 1.0);

    final resolvedRegion = ClinicalTriageEngine().findRegionByCoordinate(normX, normY, _currentView);

    setState(() {
      _selectedRegion = resolvedRegion;
      _lastTapPosition = localPos;
      _selectedSymptomIndices.clear();
      if (resolvedRegion.commonSymptoms.isNotEmpty) {
        _selectedSymptomIndices.add(0);
      }
      _checkRedFlagStatus();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _notifyParent();
    });
  }

  void _selectRegionDirectly(AnatomicalRegionDto region) {
    setState(() {
      _selectedRegion = region;
      _currentView = region.view;
      _lastTapPosition = null; // Centered on region's normalized coordinate
      _selectedSymptomIndices.clear();
      if (region.commonSymptoms.isNotEmpty) {
        _selectedSymptomIndices.add(0);
      }
      _checkRedFlagStatus();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _notifyParent();
    });
  }

  void _toggleSymptomIndex(int index) {
    setState(() {
      if (_selectedSymptomIndices.contains(index)) {
        if (_selectedSymptomIndices.length > 1) {
          _selectedSymptomIndices.remove(index);
        }
      } else {
        _selectedSymptomIndices.add(index);
      }
      _checkRedFlagStatus();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _notifyParent();
    });
  }

  void _triggerEmergencySos() {
    final session = SessionCoordinator();
    final isHi = session.isHindi;
    final isMr = session.isMarathi;

    EmergencyRepository().triggerEmergency(
      patientId: 'P-101',
      patientName: 'Kavita Rajesh Devi',
      assignedFacilityName: _selectedRegion.emergencyProtocol.localizedTargetFacility(isHi, isMr),
    );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EmergencyTrackingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final isHi = session.isHindi;
        final isMr = session.isMarathi;

        const double canvasW = 280;
        const double canvasH = 420;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Main Anatomical Visualizer Container
            Container(
              decoration: BoxDecoration(
                color: RuralCareColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: RuralCareColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header with Title and View Switcher Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMr
                                  ? 'मानवी शरीर आकृती: अचूक भागावर टॅप करा'
                                  : (isHi
                                      ? 'मानव शरीर चित्र: सटीक अंग पर टैप करें'
                                      : 'High-Precision Anatomical Body Map'),
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: RuralCareColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isMr
                                  ? 'कोणत्याही भागावर क्लिक करून समस्या निवडा'
                                  : (isHi ? 'किसी भी अंग पर क्लिक करके परेशानी दर्ज करें' : 'Tap exact point of pain or symptom'),
                              style: const TextStyle(fontSize: 11, color: RuralCareColors.textSecondary),
                            ),
                          ],
                        ),
                      ),

                      // Anterior / Posterior Segmented View Switcher
                      Container(
                        decoration: BoxDecoration(
                          color: RuralCareColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: RuralCareColors.border),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _viewSwitchButton(
                              label: isMr ? 'पुढील भाग' : (isHi ? 'सामने' : 'Anterior'),
                              view: AnatomicalView.anterior,
                            ),
                            const SizedBox(width: 4),
                            _viewSwitchButton(
                              label: isMr ? 'मागील भाग' : (isHi ? 'पीछे' : 'Posterior'),
                              view: AnatomicalView.posterior,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Interactive Vector Canvas with Coordinate Hit-Testing
                  Center(
                    child: SizedBox(
                      width: canvasW,
                      height: canvasH,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final size = Size(constraints.maxWidth, constraints.maxHeight);

                          // Compute active marker pin coordinate
                          final markerX = _lastTapPosition?.dx ?? (_selectedRegion.normalizedX * size.width);
                          final markerY = _lastTapPosition?.dy ?? (_selectedRegion.normalizedY * size.height);

                          return GestureDetector(
                            onTapDown: (details) => _handleCanvasTap(details.localPosition, size),
                            child: Stack(
                              children: [
                                // 1. Vector Anatomy Custom Painter
                                CustomPaint(
                                  size: size,
                                  painter: _HighPrecisionHumanBodyPainter(
                                    view: _currentView,
                                    selectedRegion: _selectedRegion,
                                  ),
                                ),

                                // 2. Animated Pulsing Pin Marker on Active Tap
                                Positioned(
                                  left: markerX - 16,
                                  top: markerY - 16,
                                  child: AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _pulseAnimation.value,
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: (_selectedRegion.isHighRisk
                                                    ? RuralCareColors.critical
                                                    : RuralCareColors.primary)
                                                .withOpacity(0.25),
                                            border: Border.all(
                                              color: _selectedRegion.isHighRisk
                                                  ? RuralCareColors.critical
                                                  : RuralCareColors.primary,
                                              width: 2,
                                            ),
                                          ),
                                          child: Center(
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: _selectedRegion.isHighRisk
                                                    ? RuralCareColors.critical
                                                    : RuralCareColors.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                // 3. Floating Tap Indicator Tooltip
                                Positioned(
                                  bottom: 8,
                                  left: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.92),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: RuralCareColors.border),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.touch_app_rounded,
                                          size: 16,
                                          color: _selectedRegion.isHighRisk
                                              ? RuralCareColors.critical
                                              : RuralCareColors.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            isMr
                                                ? 'केंद्रीत करण्यासाठी शरीरावर कुठेही टॅप करा'
                                                : (isHi
                                                    ? 'केंद्रित करने के लिए शरीर पर कहीं भी टैप करें'
                                                    : 'Tap anywhere on the body to shift focus point'),
                                            style: const TextStyle(fontSize: 10, color: RuralCareColors.textSecondary),
                                            maxLines: 1,
                                          ),
                                        ),
                                        Text(
                                          _currentView == AnatomicalView.anterior
                                              ? (isMr ? 'पुढील भाग' : (isHi ? 'सामने' : 'FRONT'))
                                              : (isMr ? 'मागील भाग' : (isHi ? 'पीछे' : 'BACK')),
                                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: RuralCareColors.teal),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Identified Anatomical Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _selectedRegion.isHighRisk
                          ? const Color(0xFFFFF1F0)
                          : RuralCareColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedRegion.isHighRisk
                            ? RuralCareColors.critical
                            : RuralCareColors.primary.withOpacity(0.3),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _selectedRegion.isHighRisk
                                      ? Icons.warning_rounded
                                      : Icons.location_searching_rounded,
                                  size: 16,
                                  color: _selectedRegion.isHighRisk
                                      ? RuralCareColors.critical
                                      : RuralCareColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isMr ? 'अचूक निवडलेला भाग:' : (isHi ? 'सटीक चयनित अंग:' : 'Identified Issue Area:'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedRegion.isHighRisk
                                        ? RuralCareColors.critical
                                        : RuralCareColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _selectedRegion.localizedSystemType(isHi, isMr),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedRegion.isHighRisk
                                      ? RuralCareColors.critical
                                      : RuralCareColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _selectedRegion.localizedName(isHi, isMr),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: RuralCareColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Quick Region Chips Selector (Categorized)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isMr ? 'किंवा खालील अवयवांची यादी तपासा:' : (isHi ? 'या नीचे दिए गए अंगों में से चुनें:' : 'Or Select Specific Region from List:'),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RuralCareColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ClinicalTriageEngine()
                          .anatomicalRegions
                          .where((r) => r.view == _currentView)
                          .map((reg) {
                        final isSel = _selectedRegion.id == reg.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            elevation: 0,
                            backgroundColor: isSel
                                ? (reg.isHighRisk ? RuralCareColors.critical : RuralCareColors.primary)
                                : RuralCareColors.surfaceSubtle,
                            label: Text(
                              reg.localizedName(isHi, isMr),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                color: isSel ? Colors.white : RuralCareColors.textPrimary,
                              ),
                            ),
                            onPressed: () => _selectRegionDirectly(reg),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 2. Body-Part-Adaptive Emergency Red-Flag Banner (MoHFW Protocol)
            if (_isRedFlag && _redFlagWarning != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: RuralCareColors.criticalSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: RuralCareColors.critical, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.emergency_rounded, color: RuralCareColors.critical, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedRegion.emergencyProtocol.localizedDiagnosis(isHi, isMr).toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: RuralCareColors.critical,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedRegion.emergencyProtocol.localizedWarning(isHi, isMr),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: RuralCareColors.textPrimary,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: RuralCareColors.critical,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _triggerEmergencySos,
                            icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                            label: Text(
                              _selectedRegion.emergencyProtocol.localizedHospitalAction(isHi, isMr),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 3. Localized Symptoms Specific to Selected Region
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: RuralCareColors.border),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isMr
                            ? '${_selectedRegion.localizedName(isHi, isMr)} संबंधी लक्षणे:'
                            : (isHi
                                ? '${_selectedRegion.localizedName(isHi, isMr)} से जुड़े लक्षण:'
                                : 'Specific Symptoms for ${_selectedRegion.nameEn}:'),
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: RuralCareColors.textPrimary,
                        ),
                      ),
                      Text(
                        isMr ? 'लागू असणारे निवडा' : (isHi ? 'लागू लक्षण चुनें' : 'Select all that apply'),
                        style: const TextStyle(fontSize: 10, color: RuralCareColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final symptomsList = _selectedRegion.localizedSymptoms(isHi, isMr);
                      return Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: List.generate(symptomsList.length, (idx) {
                          final sym = symptomsList[idx];
                          final isChecked = _selectedSymptomIndices.contains(idx);
                          return FilterChip(
                            label: Text(sym),
                            selected: isChecked,
                            selectedColor: _selectedRegion.isHighRisk
                                ? RuralCareColors.criticalSoft
                                : RuralCareColors.primarySoft,
                            checkmarkColor: _selectedRegion.isHighRisk
                                ? RuralCareColors.critical
                                : RuralCareColors.primary,
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: isChecked ? FontWeight.bold : FontWeight.w500,
                              color: isChecked
                                  ? (_selectedRegion.isHighRisk ? RuralCareColors.critical : RuralCareColors.primary)
                                  : RuralCareColors.textPrimary,
                            ),
                            backgroundColor: RuralCareColors.surfaceSubtle,
                            side: BorderSide(
                              color: isChecked
                                  ? (_selectedRegion.isHighRisk ? RuralCareColors.critical : RuralCareColors.primary)
                                  : RuralCareColors.border,
                              width: isChecked ? 1.5 : 1,
                            ),
                            onSelected: (_) => _toggleSymptomIndex(idx),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _viewSwitchButton({
    required String label,
    required AnatomicalView view,
  }) {
    final isSel = _currentView == view;

    return InkWell(
      onTap: () {
        setState(() {
          _currentView = view;
          // Switch default region to one in the active view
          final available = ClinicalTriageEngine().anatomicalRegions.where((r) => r.view == view).toList();
          if (available.isNotEmpty) {
            _selectedRegion = available.first;
            _selectedSymptomIndices.clear();
            if (_selectedRegion.commonSymptoms.isNotEmpty) {
              _selectedSymptomIndices.add(0);
            }
            _checkRedFlagStatus();
          }
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _notifyParent();
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSel ? RuralCareColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
            color: isSel ? Colors.white : RuralCareColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// High-Precision Vector Anatomical Human Body Painter
/// Renders distinct anatomically segmented regions for Anterior and Posterior views
class _HighPrecisionHumanBodyPainter extends CustomPainter {
  final AnatomicalView view;
  final AnatomicalRegionDto selectedRegion;

  const _HighPrecisionHumanBodyPainter({
    required this.view,
    required this.selectedRegion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final baseOutlinePaint = Paint()
      ..color = const Color(0xFFCAD5E2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final baseFillPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.fill;

    final organBoundaryPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final highlightFill = Paint()
      ..color = selectedRegion.isHighRisk
          ? const Color(0xFFFFECEB)
          : const Color(0xFFE0ECFF)
      ..style = PaintingStyle.fill;

    final highlightStroke = Paint()
      ..color = selectedRegion.isHighRisk
          ? RuralCareColors.critical
          : RuralCareColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    final cx = size.width / 2;

    if (view == AnatomicalView.anterior) {
      _paintAnterior(canvas, size, cx, baseFillPaint, baseOutlinePaint, organBoundaryPaint, highlightFill, highlightStroke);
    } else {
      _paintPosterior(canvas, size, cx, baseFillPaint, baseOutlinePaint, organBoundaryPaint, highlightFill, highlightStroke);
    }
  }

  void _paintAnterior(
    Canvas canvas,
    Size size,
    double cx,
    Paint fill,
    Paint outline,
    Paint organStroke,
    Paint hiFill,
    Paint hiStroke,
  ) {
    // 1. Head & Cranium (Normalized Y: 0.04 to 0.18)
    final headRect = Rect.fromCenter(center: Offset(cx, 44), width: 56, height: 68);
    canvas.drawOval(headRect, fill);
    canvas.drawOval(headRect, outline);

    // Right Forehead segment (user's right = screen right from observer perspective)
    if (selectedRegion.id == 'forehead_right') {
      final rightForehead = Path()
        ..moveTo(cx, 16)
        ..arcToPoint(Offset(cx + 25, 42), radius: const Radius.circular(30))
        ..lineTo(cx, 42)
        ..close();
      canvas.drawPath(rightForehead, hiFill);
      canvas.drawPath(rightForehead, hiStroke);
    } else if (selectedRegion.id == 'forehead_left') {
      final leftForehead = Path()
        ..moveTo(cx, 16)
        ..arcToPoint(Offset(cx - 25, 42), radius: const Radius.circular(30), clockwise: false)
        ..lineTo(cx, 42)
        ..close();
      canvas.drawPath(leftForehead, hiFill);
      canvas.drawPath(leftForehead, hiStroke);
    }

    // Eyes & Nose indicators
    canvas.drawCircle(Offset(cx - 10, 42), 3, organStroke);
    canvas.drawCircle(Offset(cx + 10, 42), 3, organStroke);
    canvas.drawLine(Offset(cx, 44), Offset(cx, 54), organStroke);
    canvas.drawLine(Offset(cx - 8, 62), Offset(cx + 8, 62), organStroke);

    // 2. Neck & Throat (Y: 0.18 to 0.23)
    final neckRect = Rect.fromLTWH(cx - 12, 78, 24, 20);
    final isThroat = selectedRegion.id == 'throat_airway';
    canvas.drawRRect(RRect.fromRectAndRadius(neckRect, const Radius.circular(4)), isThroat ? hiFill : fill);
    canvas.drawRRect(RRect.fromRectAndRadius(neckRect, const Radius.circular(4)), isThroat ? hiStroke : outline);

    // 3. Shoulders & Torso Body Outline
    final torsoPath = Path()
      ..moveTo(cx - 52, 98) // Left Acromion
      ..lineTo(cx + 52, 98) // Right Acromion
      ..lineTo(cx + 42, 160) // Waist Right
      ..lineTo(cx + 38, 226) // Pelvis Right
      ..lineTo(cx - 38, 226) // Pelvis Left
      ..lineTo(cx - 42, 160) // Waist Left
      ..close();
    canvas.drawPath(torsoPath, fill);
    canvas.drawPath(torsoPath, outline);

    // Thorax / Chest segments
    // Precordium / Heart (Left Chest)
    final isHeart = selectedRegion.id == 'chest_precordium';
    final heartRect = Rect.fromLTWH(cx - 38, 102, 34, 46);
    canvas.drawRRect(RRect.fromRectAndRadius(heartRect, const Radius.circular(8)), isHeart ? hiFill : fill);
    canvas.drawRRect(RRect.fromRectAndRadius(heartRect, const Radius.circular(8)), isHeart ? hiStroke : organStroke);

    // Right Chest (Lung)
    final isRightLung = selectedRegion.id == 'chest_right_lung';
    final rightLungRect = Rect.fromLTWH(cx + 4, 102, 34, 46);
    canvas.drawRRect(RRect.fromRectAndRadius(rightLungRect, const Radius.circular(8)), isRightLung ? hiFill : fill);
    canvas.drawRRect(RRect.fromRectAndRadius(rightLungRect, const Radius.circular(8)), isRightLung ? hiStroke : organStroke);

    // Abdomen Segments
    // Epigastrium
    final isEpigastrium = selectedRegion.id == 'abdomen_epigastrium';
    final epiRect = Rect.fromLTWH(cx - 20, 150, 40, 24);
    canvas.drawRRect(RRect.fromRectAndRadius(epiRect, const Radius.circular(6)), isEpigastrium ? hiFill : fill);
    canvas.drawRRect(RRect.fromRectAndRadius(epiRect, const Radius.circular(6)), isEpigastrium ? hiStroke : organStroke);

    // RUQ & LUQ
    final isRuq = selectedRegion.id == 'abdomen_ruq';
    final ruqRect = Rect.fromLTWH(cx + 4, 150, 32, 24);
    canvas.drawRRect(RRect.fromRectAndRadius(ruqRect, const Radius.circular(6)), isRuq ? hiFill : fill);
    canvas.drawRRect(RRect.fromRectAndRadius(ruqRect, const Radius.circular(6)), isRuq ? hiStroke : organStroke);

    // Umbilicus
    final isUmbilicus = selectedRegion.id == 'abdomen_umbilicus';
    final umbRect = Rect.fromLTWH(cx - 18, 176, 36, 22);
    canvas.drawRRect(RRect.fromRectAndRadius(umbRect, const Radius.circular(6)), isUmbilicus ? hiFill : fill);
    canvas.drawRRect(RRect.fromRectAndRadius(umbRect, const Radius.circular(6)), isUmbilicus ? hiStroke : organStroke);

    // RLQ (Appendix)
    final isRlq = selectedRegion.id == 'abdomen_rlq';
    final rlqRect = Rect.fromLTWH(cx + 4, 198, 30, 24);
    canvas.drawRRect(RRect.fromRectAndRadius(rlqRect, const Radius.circular(6)), isRlq ? hiFill : fill);
    canvas.drawRRect(RRect.fromRectAndRadius(rlqRect, const Radius.circular(6)), isRlq ? hiStroke : organStroke);

    // LLQ
    final isLlq = selectedRegion.id == 'abdomen_llq';
    final llqRect = Rect.fromLTWH(cx - 34, 198, 30, 24);
    canvas.drawRRect(RRect.fromRectAndRadius(llqRect, const Radius.circular(6)), isLlq ? hiFill : fill);
    canvas.drawRRect(RRect.fromRectAndRadius(llqRect, const Radius.circular(6)), isLlq ? hiStroke : organStroke);

    // Pelvis / Suprapubic
    final isPelvis = selectedRegion.id == 'pelvis_suprapubic';
    final pelvisRect = Rect.fromLTWH(cx - 24, 218, 48, 20);
    canvas.drawRRect(RRect.fromRectAndRadius(pelvisRect, const Radius.circular(8)), isPelvis ? hiFill : fill);
    canvas.drawRRect(RRect.fromRectAndRadius(pelvisRect, const Radius.circular(8)), isPelvis ? hiStroke : organStroke);

    // 4. Upper Extremities (Arms)
    // Left Arm (Screen Left)
    final isLeftArm = selectedRegion.id == 'elbow_hand_left';
    final leftArm = Path()
      ..moveTo(cx - 52, 98)
      ..lineTo(cx - 72, 154)
      ..lineTo(cx - 68, 235)
      ..lineTo(cx - 56, 235)
      ..lineTo(cx - 58, 158)
      ..lineTo(cx - 44, 102)
      ..close();
    canvas.drawPath(leftArm, isLeftArm ? hiFill : fill);
    canvas.drawPath(leftArm, isLeftArm ? hiStroke : outline);

    // Right Arm (Screen Right)
    final isRightArm = selectedRegion.id == 'elbow_hand_right';
    final rightArm = Path()
      ..moveTo(cx + 52, 98)
      ..lineTo(cx + 72, 154)
      ..lineTo(cx + 68, 235)
      ..lineTo(cx + 56, 235)
      ..lineTo(cx + 58, 158)
      ..lineTo(cx + 44, 102)
      ..close();
    canvas.drawPath(rightArm, isRightArm ? hiFill : fill);
    canvas.drawPath(rightArm, isRightArm ? hiStroke : outline);

    // 5. Lower Extremities (Legs)
    // Left Leg (Screen Left)
    final isLeftThigh = selectedRegion.id == 'hip_thigh_left';
    final isLeftKnee = selectedRegion.id == 'knee_left';
    final isLeftCalf = selectedRegion.id == 'lower_leg_calf_left';
    final isLeftFoot = selectedRegion.id == 'ankle_foot_left';

    final leftLeg = Path()
      ..moveTo(cx - 36, 226)
      ..lineTo(cx - 40, 310) // Knee
      ..lineTo(cx - 38, 385) // Ankle
      ..lineTo(cx - 48, 405) // Foot
      ..lineTo(cx - 18, 405)
      ..lineTo(cx - 24, 385)
      ..lineTo(cx - 26, 310)
      ..lineTo(cx - 4, 230)
      ..close();
    canvas.drawPath(leftLeg, fill);
    canvas.drawPath(leftLeg, outline);

    if (isLeftThigh) {
      final thRect = Rect.fromLTWH(cx - 38, 230, 32, 75);
      canvas.drawRRect(RRect.fromRectAndRadius(thRect, const Radius.circular(10)), hiFill);
      canvas.drawRRect(RRect.fromRectAndRadius(thRect, const Radius.circular(10)), hiStroke);
    } else if (isLeftKnee) {
      canvas.drawCircle(Offset(cx - 33, 318), 14, hiFill);
      canvas.drawCircle(Offset(cx - 33, 318), 14, hiStroke);
    } else if (isLeftCalf) {
      final calfRect = Rect.fromLTWH(cx - 36, 334, 26, 48);
      canvas.drawRRect(RRect.fromRectAndRadius(calfRect, const Radius.circular(8)), hiFill);
      canvas.drawRRect(RRect.fromRectAndRadius(calfRect, const Radius.circular(8)), hiStroke);
    } else if (isLeftFoot) {
      final footRect = Rect.fromLTWH(cx - 48, 386, 34, 20);
      canvas.drawRRect(RRect.fromRectAndRadius(footRect, const Radius.circular(6)), hiFill);
      canvas.drawRRect(RRect.fromRectAndRadius(footRect, const Radius.circular(6)), hiStroke);
    }

    // Right Leg (Screen Right)
    final isRightThigh = selectedRegion.id == 'hip_thigh_right';
    final isRightKnee = selectedRegion.id == 'knee_right';
    final isRightCalf = selectedRegion.id == 'lower_leg_calf_right';
    final isRightFoot = selectedRegion.id == 'ankle_foot_right';

    final rightLeg = Path()
      ..moveTo(cx + 36, 226)
      ..lineTo(cx + 40, 310) // Knee
      ..lineTo(cx + 38, 385) // Ankle
      ..lineTo(cx + 48, 405) // Foot
      ..lineTo(cx + 18, 405)
      ..lineTo(cx + 24, 385)
      ..lineTo(cx + 26, 310)
      ..lineTo(cx + 4, 230)
      ..close();
    canvas.drawPath(rightLeg, fill);
    canvas.drawPath(rightLeg, outline);

    if (isRightThigh) {
      final thRect = Rect.fromLTWH(cx + 6, 230, 32, 75);
      canvas.drawRRect(RRect.fromRectAndRadius(thRect, const Radius.circular(10)), hiFill);
      canvas.drawRRect(RRect.fromRectAndRadius(thRect, const Radius.circular(10)), hiStroke);
    } else if (isRightKnee) {
      canvas.drawCircle(Offset(cx + 33, 318), 14, hiFill);
      canvas.drawCircle(Offset(cx + 33, 318), 14, hiStroke);
    } else if (isRightCalf) {
      final calfRect = Rect.fromLTWH(cx + 10, 334, 26, 48);
      canvas.drawRRect(RRect.fromRectAndRadius(calfRect, const Radius.circular(8)), hiFill);
      canvas.drawRRect(RRect.fromRectAndRadius(calfRect, const Radius.circular(8)), hiStroke);
    } else if (isRightFoot) {
      final footRect = Rect.fromLTWH(cx + 14, 386, 34, 20);
      canvas.drawRRect(RRect.fromRectAndRadius(footRect, const Radius.circular(6)), hiFill);
      canvas.drawRRect(RRect.fromRectAndRadius(footRect, const Radius.circular(6)), hiStroke);
    }
  }

  void _paintPosterior(
    Canvas canvas,
    Size size,
    double cx,
    Paint fill,
    Paint outline,
    Paint organStroke,
    Paint hiFill,
    Paint hiStroke,
  ) {
    // 1. Posterior Head & Nape
    final headRect = Rect.fromCenter(center: Offset(cx, 44), width: 56, height: 68);
    canvas.drawOval(headRect, fill);
    canvas.drawOval(headRect, outline);

    // 2. Cervical Spine
    final isCervical = selectedRegion.id == 'cervical_spine_back';
    final cervRect = Rect.fromLTWH(cx - 10, 78, 20, 24);
    canvas.drawRRect(RRect.fromRectAndRadius(cervRect, const Radius.circular(4)), isCervical ? hiFill : fill);
    canvas.drawRRect(RRect.fromRectAndRadius(cervRect, const Radius.circular(4)), isCervical ? hiStroke : organStroke);

    // 3. Posterior Torso with Vertebral Spine Axis
    final torsoPath = Path()
      ..moveTo(cx - 52, 98)
      ..lineTo(cx + 52, 98)
      ..lineTo(cx + 42, 160)
      ..lineTo(cx + 38, 226)
      ..lineTo(cx - 38, 226)
      ..lineTo(cx - 42, 160)
      ..close();
    canvas.drawPath(torsoPath, fill);
    canvas.drawPath(torsoPath, outline);

    // Thoracic Spine & Upper Back
    final isThoracic = selectedRegion.id == 'upper_back_thoracic';
    final thRect = Rect.fromLTWH(cx - 24, 104, 48, 56);
    canvas.drawRRect(RRect.fromRectAndRadius(thRect, const Radius.circular(8)), isThoracic ? hiFill : fill);
    canvas.drawRRect(RRect.fromRectAndRadius(thRect, const Radius.circular(8)), isThoracic ? hiStroke : organStroke);

    // Kidneys & Flanks (Left & Right Flanks)
    final isLeftFlank = selectedRegion.id == 'flank_kidney_left';
    final isRightFlank = selectedRegion.id == 'flank_kidney_right';

    final lfRect = Rect.fromLTWH(cx - 36, 164, 26, 36);
    canvas.drawRRect(RRect.fromRectAndRadius(lfRect, const Radius.circular(8)), isLeftFlank ? hiFill : fill);
    canvas.drawRRect(RRect.fromRectAndRadius(lfRect, const Radius.circular(8)), isLeftFlank ? hiStroke : organStroke);

    final rfRect = Rect.fromLTWH(cx + 10, 164, 26, 36);
    canvas.drawRRect(RRect.fromRectAndRadius(rfRect, const Radius.circular(8)), isRightFlank ? hiFill : fill);
    canvas.drawRRect(RRect.fromRectAndRadius(rfRect, const Radius.circular(8)), isRightFlank ? hiStroke : organStroke);

    // Lumbar Spine / Lower Back
    final isLumbar = selectedRegion.id == 'lumbar_spine_lower_back';
    final lumRect = Rect.fromLTWH(cx - 16, 172, 32, 48);
    canvas.drawRRect(RRect.fromRectAndRadius(lumRect, const Radius.circular(8)), isLumbar ? hiFill : fill);
    canvas.drawRRect(RRect.fromRectAndRadius(lumRect, const Radius.circular(8)), isLumbar ? hiStroke : organStroke);

    // Spinal Column Line Marker
    canvas.drawLine(Offset(cx, 80), Offset(cx, 220), organStroke);

    // 4. Posterior Legs (Hamstrings, Popliteal Fossa, Calves, Achilles)
    // Left Leg (Screen Left)
    final leftLeg = Path()
      ..moveTo(cx - 36, 226)
      ..lineTo(cx - 40, 310)
      ..lineTo(cx - 38, 385)
      ..lineTo(cx - 46, 405)
      ..lineTo(cx - 20, 405)
      ..lineTo(cx - 24, 385)
      ..lineTo(cx - 26, 310)
      ..lineTo(cx - 4, 230)
      ..close();
    canvas.drawPath(leftLeg, fill);
    canvas.drawPath(leftLeg, outline);

    // Right Leg (Screen Right)
    final rightLeg = Path()
      ..moveTo(cx + 36, 226)
      ..lineTo(cx + 40, 310)
      ..lineTo(cx + 38, 385)
      ..lineTo(cx + 46, 405)
      ..lineTo(cx + 20, 405)
      ..lineTo(cx + 24, 385)
      ..lineTo(cx + 26, 310)
      ..lineTo(cx + 4, 230)
      ..close();
    canvas.drawPath(rightLeg, fill);
    canvas.drawPath(rightLeg, outline);
  }

  @override
  bool shouldRepaint(covariant _HighPrecisionHumanBodyPainter oldDelegate) {
    return oldDelegate.view != view || oldDelegate.selectedRegion.id != selectedRegion.id;
  }
}
