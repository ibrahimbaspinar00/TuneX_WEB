import 'package:flutter/material.dart';
import '../main.dart'; // LandingPage için

/// Basit Auth Wrapper - Firebase olmadan
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Basit initialization
    Future.microtask(() {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // İlk yükleme sırasında loading göster
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(
              const Color(0xFFFF6A00),
            ),
          ),
        ),
      );
    }

    // Şimdilik direkt LandingPage göster
    // Gelecekte başka bir auth sistemi eklenebilir
    return const LandingPage();
  }
}
