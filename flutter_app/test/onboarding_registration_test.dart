import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruralcare/app/app.dart';
import 'package:ruralcare/app/routes.dart';
import 'package:ruralcare/features/auth/screens/onboarding_screen.dart';
import 'package:ruralcare/features/auth/screens/patient_registration_screen.dart';
import 'package:ruralcare/features/auth/utils/registration_strings.dart';

void main() {
  group('Onboarding & Patient Registration UX & Multilingual Tests', () {
    late SessionCoordinator session;

    setUp(() {
      session = SessionCoordinator();
      session.switchLanguage('en');
      session.switchRole(AppRole.patient);
    });

    test('RegistrationStrings returns correct localized strings across all languages', () {
      final en = RegistrationStrings('en');
      expect(en.btnContinue, equals('Continue'));
      expect(en.alreadyRegisteredSignIn, contains('Already registered?'));

      final hi = RegistrationStrings('hi');
      expect(hi.btnContinue, equals('आगे बढ़ें'));
      expect(hi.welcomeTitle, equals('रूरलकेयर में आपका स्वागत है'));
      expect(hi.mobileHeader, equals('मोबाइल नंबर दर्ज करें'));

      final mr = RegistrationStrings('mr');
      expect(mr.btnContinue, equals('पुढे जा'));
      expect(mr.welcomeTitle, equals('रूरलकेअर मध्ये आपले स्वागत आहे'));
      expect(mr.mobileHeader, equals('मोबाइल नंबर प्रविष्ट करा'));
    });

    testWidgets('OnboardingScreen has single Sign In button and no duplicate in AppBar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Top AppBar should have NO action buttons (no duplicate Sign In)
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.actions, isEmpty);

      // Bottom has single "Already registered? Sign In" button
      expect(find.textContaining('Already registered? Sign In'), findsOneWidget);
    });

    testWidgets('Selecting Hindi on Onboarding Step 1 translates Step 2 into Hindi', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Step 0 -> Click Continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 1: Language selection -> Tap Hindi
      await tester.tap(find.text('हिन्दी'));
      await tester.pumpAndSettle();
      expect(session.isHindi, isTrue);

      // Tap Continue in Hindi
      await tester.tap(find.text('आगे बढ़ें'));
      await tester.pumpAndSettle();

      // Step 2: Role selection should now be in Hindi
      expect(find.text('अपनी भूमिका चुनें'), findsOneWidget);
      expect(find.text('मरीज़ / परिवार (नागरिक)'), findsOneWidget);
      expect(find.text('चयनित भूमिका के साथ आगे बढ़ें'), findsOneWidget);
    });

    testWidgets('PatientRegistrationScreen form inputs start completely empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PatientRegistrationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Mobile text field should be empty
      final mobileField = tester.widget<TextField>(find.byType(TextField));
      expect(mobileField.controller?.text, isEmpty);
    });

    testWidgets('PatientRegistrationScreen validates mobile number and shows OTP with SMS helper', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PatientRegistrationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Send OTP without entering number -> shows validation error
      await tester.tap(find.text('Send Verification Code (OTP)'));
      await tester.pumpAndSettle();
      expect(find.text('Invalid entry: Mobile number must be exactly 10 digits.'), findsOneWidget);

      // Enter 10-digit number
      await tester.enterText(find.byType(TextField), '9876543210');
      await tester.tap(find.text('Send Verification Code (OTP)'));
      await tester.pumpAndSettle();

      // Should be on Step 1 (OTP)
      expect(find.text('Enter 6-Digit OTP'), findsOneWidget);

      // OTP text field should start empty!
      final otpField = tester.widget<TextField>(find.byType(TextField));
      expect(otpField.controller?.text, isEmpty);

      // Simulated SMS banner displays code 482910 with auto-fill button
      expect(find.textContaining('Your verification code is 482910'), findsOneWidget);

      // Tap auto-fill
      await tester.tap(find.text('Auto-fill'));
      await tester.pumpAndSettle();
      expect(otpField.controller?.text, equals('482910'));

      // Test incorrect OTP error
      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.text('Verify & Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Invalid OTP: The entered OTP does not match the received verification code.'), findsOneWidget);

      // Re-enter correct OTP
      await tester.enterText(find.byType(TextField), '482910');
      await tester.tap(find.text('Verify & Continue'));
      await tester.pumpAndSettle();

      // Should be on Step 2 (Demographics)
      expect(find.text('Beneficiary Profile'), findsOneWidget);
    });

    testWidgets('PatientRegistrationScreen allows language switching directly from AppBar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PatientRegistrationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Initial English
      expect(find.text('Mobile Verification (Step 1/5)'), findsOneWidget);
      expect(find.text('Enter Mobile Number'), findsOneWidget);

      // Tap Hindi in AppBar
      await tester.tap(find.text('हि'));
      await tester.pumpAndSettle();

      // Should now display Hindi title and labels
      expect(find.text('मोबाइल सत्यापन (चरण 1/5)'), findsOneWidget);
      expect(find.text('मोबाइल नंबर दर्ज करें'), findsOneWidget);

      // Switch back to English
      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();
      expect(find.text('Mobile Verification (Step 1/5)'), findsOneWidget);
    });

    testWidgets('PatientRegistrationScreen Demographics has empty name and Date of Birth selector', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PatientRegistrationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter mobile and OTP to reach Step 2
      await tester.enterText(find.byType(TextField), '9876543210');
      await tester.tap(find.text('Send Verification Code (OTP)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Auto-fill'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verify & Continue'));
      await tester.pumpAndSettle();

      // Name field starts empty
      final nameField = tester.widget<TextField>(find.byType(TextField));
      expect(nameField.controller?.text, isEmpty);

      // Date of Birth field is present (no raw age textfield)
      expect(find.text('Date of Birth (DOB)'), findsOneWidget);
      expect(find.text('Select DD / MM / YYYY'), findsOneWidget);
    });

    testWidgets('PatientRegistrationScreen Step 3 has neutral placeholders and does not autofill address', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PatientRegistrationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Fast forward to step 3 by entering details
      await tester.enterText(find.byType(TextField), '9876543210');
      await tester.tap(find.text('Send Verification Code (OTP)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Auto-fill'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verify & Continue'));
      await tester.pumpAndSettle();

      // Enter Name
      await tester.enterText(find.byType(TextField), 'Radha Mohan Patil');

      // Select Gender
      await tester.tap(find.text('Select Gender'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Female').last);
      await tester.pumpAndSettle();

      // Tap Date of Birth to trigger date picker
      await tester.tap(find.text('Select DD / MM / YYYY'));
      await tester.pumpAndSettle();
      // Confirm date picker
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Proceed to Location & Area
      await tester.tap(find.text('Proceed to Location & Area'));
      await tester.pumpAndSettle();

      // Step 3 (Location) should show Sub-Centre dropdown
      expect(find.text('Nearest Sub-Centre (Health Centre)'), findsOneWidget);
      expect(find.text('Select your Sub-Centre'), findsOneWidget);

      // Open dropdown and pick a sub-centre
      await tester.tap(find.text('Select your Sub-Centre'), warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Kashti Sub-Centre').last);
      await tester.pumpAndSettle();

      // Verify neutral placeholder hints are present and fields are NOT auto-filled
      expect(find.text('Enter village name'), findsOneWidget);
      expect(find.text('Enter block / taluka'), findsOneWidget);
      expect(find.text('Enter district name'), findsOneWidget);
      expect(find.text('Enter 6-digit pincode'), findsOneWidget);
    });

    testWidgets('RuralCareAppShell initial launch defaults to OnboardingScreen', (tester) async {
      final freshSession = SessionCoordinator();
      freshSession.resetToOnboarding();

      await tester.pumpWidget(
        MaterialApp(
          home: AnimatedBuilder(
            animation: freshSession,
            builder: (context, _) => const RuralCareAppShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Must start on OnboardingScreen
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Welcome to RuralCare'), findsOneWidget);
    });
  });
}
