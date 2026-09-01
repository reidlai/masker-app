import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'ui/pages/login_page.dart';
import 'ui/pages/main_container_page.dart';

void main() {
  runApp(const DennisMaskerApp());
}

class DennisMaskerApp extends StatefulWidget {
  const DennisMaskerApp({super.key});

  @override
  State<DennisMaskerApp> createState() => _DennisMaskerAppState();
}

class _DennisMaskerAppState extends State<DennisMaskerApp> {
  bool _isLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sleep Apnea Detection App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _isLoggedIn
          ? const MainContainerPage()
          : LoginPage(
              onLoginSuccess: () {
                setState(() {
                  _isLoggedIn = true;
                });
              },
            ),
    );
  }
}
