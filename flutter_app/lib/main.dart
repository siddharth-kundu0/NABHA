import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ruralcare/firebase_options.dart';
import 'package:ruralcare/core/theme/app_theme.dart';
import 'package:ruralcare/app/app.dart';

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
    return MaterialApp(
      title: 'NABHA RuralCare - Rural Healthcare Access & Coordination',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const RuralCareAppShell(),
    );
  }
}
