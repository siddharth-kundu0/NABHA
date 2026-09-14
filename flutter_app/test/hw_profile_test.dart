import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/features/health_worker/screens/health_worker_dashboard_screen.dart';

void main() {
  testWidgets('Test Health Worker Profile buttons and tabs', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final session = SessionCoordinator();
    session.switchRole(AppRole.healthWorker);

    await tester.pumpWidget(
      const MaterialApp(
        home: HealthWorkerDashboardScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Find Profile tab on bottom navigation bar
    final profileTab = find.text('Profile');
    expect(profileTab, findsOneWidget);
    await tester.tap(profileTab);
    await tester.pumpAndSettle();

    // 2. We should be on HealthWorkerProfileScreen
    expect(find.text('Edit Details'), findsOneWidget);

    // 3. Tap Edit Details
    await tester.tap(find.text('Edit Details'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Health Worker Details'), findsOneWidget);
    // Close modal
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // 4. Tap Local Records
    final localRecords = find.textContaining('Cached');
    expect(localRecords, findsOneWidget);
    await tester.tap(localRecords);
    await tester.pumpAndSettle();
    expect(find.text('OK'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // 5. Tap View Villages & Supervisor Contact
    final catchmentBtn = find.text('View Villages & Supervisor Contact');
    expect(catchmentBtn, findsOneWidget);
    await tester.tap(catchmentBtn);
    await tester.pumpAndSettle();
    expect(find.text('Catchment & Supervisor Details'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    // 6. Tap Sync Now
    final syncBtn = find.textContaining('Sync Now');
    expect(syncBtn, findsOneWidget);
    await tester.tap(syncBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // 7. Tap Call 108 Ambulance Dispatcher
    final emergencyBtn = find.text('Call 108 Ambulance Dispatcher');
    expect(emergencyBtn, findsOneWidget);
    await tester.tap(emergencyBtn);
    await tester.pumpAndSettle();
    expect(find.text('Emergency Escalation Desk'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // 8. Tap Sign Out
    final signOutBtn = find.text('Sign Out');
    expect(signOutBtn, findsOneWidget);
    await tester.tap(signOutBtn);
    await tester.pumpAndSettle();
    expect(find.text('Sign Out?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // 9. Test Language Switches
    await tester.tap(find.textContaining('मराठी'));
    await tester.pumpAndSettle();
    expect(session.activeLanguage, 'मराठी');

    await tester.tap(find.textContaining('हिन्दी'));
    await tester.pumpAndSettle();
    expect(session.activeLanguage, 'हिन्दी');

    await tester.tap(find.textContaining('English'));
    await tester.pumpAndSettle();
    expect(session.activeLanguage, 'English');

    // 10. Test Accessibility Switches
    final switches = find.byType(Switch);
    expect(switches, findsNWidgets(2));
    await tester.tap(switches.first);
    await tester.pumpAndSettle();
    expect(session.largerText, true);

    await tester.tap(switches.last);
    await tester.pumpAndSettle();
    expect(session.highContrast, true);

    // 11. Test Edit Details Save Flow
    await tester.tap(find.text('Edit Details'));
    await tester.pumpAndSettle();
    final nameField = find.widgetWithText(TextField, 'Name');
    expect(nameField, findsOneWidget);
    await tester.enterText(nameField, 'Pooja Patil');
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    expect(find.text('Pooja Patil'), findsOneWidget);
    expect(find.text('PP'), findsOneWidget); // Squircle avatar initials updated!

    // 12. Test Emergency Actions
    final emergBtn = find.text('Call 108 Ambulance Dispatcher');
    await tester.ensureVisible(emergBtn);
    await tester.pumpAndSettle();
    await tester.tap(emergBtn);
    await tester.pumpAndSettle();
    final callMoBtn = find.textContaining('Call PHC MO');
    expect(callMoBtn, findsOneWidget);
    await tester.tap(callMoBtn);
    await tester.pumpAndSettle();
  });
}
