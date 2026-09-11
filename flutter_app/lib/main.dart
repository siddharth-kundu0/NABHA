import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
