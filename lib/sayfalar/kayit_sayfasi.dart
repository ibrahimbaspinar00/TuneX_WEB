import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/error_handler.dart';
import '../services/user_auth_service.dart';
import '../config/app_routes.dart';
import '../theme/app_design_system.dart';

class KayitSayfasi extends StatefulWidget {
  const KayitSayfasi({super.key});

  @override
  State<KayitSayfasi> createState() => _KayitSayfasiState();
}

class _KayitSayfasiState extends State<KayitSayfasi> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController(); // Ad Soyad
  final _usernameController = TextEditingController(); // Kullanıcı Adı
  final _emailController = TextEditingController(); // E-posta (Firebase için)
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _userAuthService = UserAuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ErrorHandler.showError(context, 'Kullanım şartlarını kabul etmelisiniz');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _userAuthService.signUpWithUsername(
        _fullNameController.text.trim(), // Ad Soyad
        _usernameController.text.trim(), // Kullanıcı Adı
        _emailController.text.trim(), // E-posta
        _passwordController.text,
      );

      if (user != null && mounted) {
        // Firestore kaydı signUpWithUsername içinde yapılıyor
        // Ekstra kayıt işlemi gerekmiyor - çift yazma ve email normalize sorunlarına neden olabilir
        debugPrint('✅ Kayıt başarılı! User ID: ${user.uid}');
        debugPrint('✅ Firestore kaydı signUpWithUsername içinde yapıldı');

        // Form alanlarını temizle
        _fullNameController.clear();
        _usernameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        _acceptTerms = false;

        // Loading durumunu kapat
        setState(() {
          _isLoading = false;
        });

        // Kısa bir gecikme ile ana sayfaya yönlendir - Firebase Auth state'in güncellenmesi için
        await Future.delayed(const Duration(milliseconds: 500));

        // Başarı mesajını göster ve ana sayfaya yönlendir
        if (mounted) {
          ErrorHandler.showSuccess(context, 'Kayıt başarılı! Hoş geldiniz!');
          Navigator.of(context).pushReplacementNamed(AppRoutes.main);
        }
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ErrorHandler.showError(
            context, 'Kayıt olunamadı. Lütfen tekrar deneyin.');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        String errorMessage;
        if (e.code == 'firestore-write-failed') {
          errorMessage =
              'Kayıt işlemi tamamlandı ancak veriler kaydedilemedi. Lütfen tekrar giriş yapmayı deneyin veya destek ekibiyle iletişime geçin.';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'Bu e-posta adresi zaten kullanımda.';
        } else if (e.code == 'username-already-in-use') {
          errorMessage = 'Bu kullanıcı adı zaten kullanımda.';
        } else if (e.code == 'weak-password') {
          errorMessage = 'Şifre çok zayıf. Lütfen daha güçlü bir şifre seçin.';
        } else if (e.code == 'network-request-failed' || e.code == 'timeout') {
          errorMessage =
              'İnternet bağlantınızı kontrol edin. Bağlantı sorunu nedeniyle kayıt yapılamadı.';
        } else {
          errorMessage = e.message ??
              'Kayıt olunurken bir hata oluştu. Lütfen tekrar deneyin.';
        }

        ErrorHandler.showError(context, errorMessage);
      }
    } catch (e) {
      debugPrint('Kayıt hatası: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ErrorHandler.showError(
            context, 'Kayıt olunurken beklenmeyen bir hata oluştu: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo
              SizedBox(
                height: 110,
                width: 520,
                child: Image.asset(
                  'assets/images/tunex_banner.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Yeni hesap oluşturun',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppDesignSystem.textSecondary,
                ),
              ),
              const SizedBox(height: 40),

              // Kayıt formu
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppDesignSystem.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppDesignSystem.borderLight,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),

                      // Ad Soyad alanı
                      TextFormField(
                        controller: _fullNameController,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppDesignSystem.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Ad Soyad',
                          hintText: 'Adınız ve soyadınız',
                          labelStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppDesignSystem.textSecondary,
                          ),
                          hintStyle: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppDesignSystem.textTertiary,
                          ),
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: Color(0xFFC7CDD6),
                            size: 20,
                          ),
                          filled: true,
                          fillColor: AppDesignSystem.surfaceElevated,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF2A3340),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF6A00),
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF2A3340),
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ad soyad gerekli';
                          }
                          if (value.trim().split(' ').length < 2) {
                            return 'Ad ve soyad girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Kullanıcı adı alanı
                      TextFormField(
                        controller: _usernameController,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppDesignSystem.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Kullanıcı Adı',
                          hintText: 'Kullanıcı adınız',
                          labelStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppDesignSystem.textSecondary,
                          ),
                          hintStyle: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppDesignSystem.textTertiary,
                          ),
                          prefixIcon: const Icon(
                            Icons.alternate_email_outlined,
                            color: Color(0xFFC7CDD6),
                            size: 20,
                          ),
                          filled: true,
                          fillColor: AppDesignSystem.surfaceElevated,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF2A3340),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF6A00),
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF2A3340),
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Kullanıcı adı gerekli';
                          }
                          if (value.length < 3) {
                            return 'Kullanıcı adı en az 3 karakter olmalı';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                            return 'Kullanıcı adı sadece harf, rakam ve _ içerebilir';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // E-posta alanı (gizli - Firebase için gerekli)
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppDesignSystem.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'E-posta',
                          hintText: 'ornek@email.com',
                          labelStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppDesignSystem.textSecondary,
                          ),
                          hintStyle: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppDesignSystem.textTertiary,
                          ),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: Color(0xFFC7CDD6),
                            size: 20,
                          ),
                          filled: true,
                          fillColor: AppDesignSystem.surfaceElevated,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF2A3340),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF6A00),
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF2A3340),
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'E-posta adresi gerekli';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Geçerli bir e-posta adresi girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Şifre alanı
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppDesignSystem.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          hintText: 'Şifrenizi girin',
                          labelStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppDesignSystem.textSecondary,
                          ),
                          hintStyle: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppDesignSystem.textTertiary,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFFC7CDD6),
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppDesignSystem.textSecondary,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: AppDesignSystem.surfaceElevated,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF2A3340),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF6A00),
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF2A3340),
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Şifre gerekli';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Şifre tekrar alanı
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppDesignSystem.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Şifre Tekrar',
                          hintText: 'Şifrenizi tekrar girin',
                          labelStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppDesignSystem.textSecondary,
                          ),
                          hintStyle: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppDesignSystem.textTertiary,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFFC7CDD6),
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppDesignSystem.textSecondary,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: AppDesignSystem.surfaceElevated,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF2A3340),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF6A00),
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF2A3340),
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Şifre tekrarı gerekli';
                          }
                          if (value != _passwordController.text) {
                            return 'Şifreler eşleşmiyor';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Kullanım şartları
                      Row(
                        children: [
                          Checkbox(
                            value: _acceptTerms,
                            onChanged: (value) {
                              setState(() {
                                _acceptTerms = value ?? false;
                              });
                            },
                            activeColor: Colors.purple[600],
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _acceptTerms = !_acceptTerms;
                                });
                              },
                              child: Text.rich(
                                TextSpan(
                                  text:
                                      'Kullanım şartlarını ve gizlilik politikasını kabul ediyorum.',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Kayıt butonu
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.purple[600]!, Colors.blue[600]!],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Kayıt Ol',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Giriş yap linki
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Zaten hesabınız var mı? ',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                    },
                    child: Text(
                      'Giriş Yap',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
