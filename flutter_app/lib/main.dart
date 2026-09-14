import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ruralcare/firebase_options.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/app/app.dart';
import 'package:ruralcare/app/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }
  runApp(const RuralCareApp());
}

class RuralCareApp extends StatelessWidget {
  const RuralCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionCoordinator();

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        return MaterialApp(
          title: 'NABHA RuralCare - Rural Healthcare Access & Coordination',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themeData,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: session.largerText
                    ? const TextScaler.linear(1.22)
                    : const TextScaler.linear(1.0),
              ),
              child: child!,
            );
          },
          home: const RuralCareAppShell(),
        );
      },
    );
  }
}
