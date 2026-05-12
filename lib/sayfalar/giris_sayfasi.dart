import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/error_handler.dart';
import '../services/user_auth_service.dart';
import '../config/app_routes.dart';
import '../utils/security_manager.dart';
import '../utils/responsive_helper.dart';
import '../theme/app_design_system.dart';

class GirisSayfasi extends StatefulWidget {
  const GirisSayfasi({super.key});

  @override
  State<GirisSayfasi> createState() => _GirisSayfasiState();
}

class _GirisSayfasiState extends State<GirisSayfasi>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // Kayıt formu için controller'lar
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _userAuthService = UserAuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureRegisterPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isInitialized = false;
  bool _isLoginMode = true; // true = giriş, false = kayıt
  bool _acceptTerms = false;
  DateTime? _lastSignInAttempt;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    if (_isInitialized) return;

    // Pre-load critical data
    await _preloadData();

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _preloadData() async {
    // Pre-load user auth service - non-blocking
    // UI'ı bloklamamak için await kullanmadan başlat
    _userAuthService.initialize().catchError((e) {
      // Handle error silently
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    debugPrint('Giriş butonu tıklandı');

    // Form validasyonu
    if (!_formKey.currentState!.validate()) {
      debugPrint('Form validasyonu başarısız');
      if (mounted) {
        ErrorHandler.showError(
            context, 'Lütfen tüm alanları doğru şekilde doldurun.');
      }
      return;
    }

    // Prevent rapid successive attempts
    final now = DateTime.now();
    if (_lastSignInAttempt != null &&
        now.difference(_lastSignInAttempt!).inSeconds < 2) {
      debugPrint('Çok hızlı giriş denemesi - bekleme');
      return;
    }
    _lastSignInAttempt = now;

    // Prevent duplicate operations
    if (_isLoading) {
      debugPrint('Zaten bir giriş işlemi devam ediyor');
      return;
    }

    debugPrint('Giriş işlemi başlatılıyor...');

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Giriş işlemini timeout ile sınırla
      final username = _emailController.text.trim();
      final password = _passwordController.text;

      // Boş alan kontrolü
      if (username.isEmpty) {
        debugPrint('Kullanıcı adı boş!');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ErrorHandler.showError(context, 'Lütfen kullanıcı adınızı girin.');
        }
        return;
      }

      if (password.isEmpty) {
        debugPrint('Şifre boş!');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ErrorHandler.showError(context, 'Lütfen şifrenizi girin.');
        }
        return;
      }

      debugPrint(
          'Giriş denemesi başlatılıyor: kullanıcı adı = $username, şifre uzunluğu = ${password.length}');

      User? user;
      // Daha doğru e-posta formatı kontrolü - SecurityManager kullan
      final isEmail = SecurityManager.isValidEmail(username);

      // E-posta formatındaysa direkt e-posta ile giriş yap
      if (isEmail) {
        debugPrint(
            '📧 E-posta formatı tespit edildi, e-posta ile giriş yapılıyor: $username');
        try {
          user = await _userAuthService
              .signInWithEmail(
            username,
            password,
          )
              .timeout(const Duration(seconds: 15), onTimeout: () {
            debugPrint('⏱️ E-posta ile giriş zaman aşımına uğradı');
            throw FirebaseAuthException(
              code: 'network-request-failed',
              message:
                  'Giriş işlemi zaman aşımına uğradı. İnternet bağlantınızı kontrol edin.',
            );
          });
          debugPrint('✅ E-posta ile giriş başarılı: ${user?.uid ?? "null"}');
        } catch (e) {
          debugPrint('❌ E-posta ile giriş hatası: $e');
          rethrow;
        }
      } else {
        // Kullanıcı adı formatında, kullanıcı adı ile dene
        debugPrint(
            '👤 Kullanıcı adı formatı tespit edildi, kullanıcı adı ile giriş yapılıyor: $username');
        try {
          user = await _userAuthService
              .signInWithUsername(
            username,
            password,
          )
              .timeout(const Duration(seconds: 15), onTimeout: () {
            debugPrint('⏱️ Kullanıcı adı ile giriş zaman aşımına uğradı');
            throw FirebaseAuthException(
              code: 'network-request-failed',
              message:
                  'Giriş işlemi zaman aşımına uğradı. İnternet bağlantınızı kontrol edin.',
            );
          });
          debugPrint(
              '✅ Kullanıcı adı ile giriş başarılı: ${user?.uid ?? "null"}');
        } catch (e) {
          debugPrint('❌ Kullanıcı adı ile giriş hatası: $e');
          rethrow;
        }
      }

      if (user != null && mounted) {
        debugPrint(
            '✅ Giriş başarılı! Kullanıcı ID: ${user.uid}, Email: ${user.email}');

        // Loading durumunu kapat
        setState(() {
          _isLoading = false;
        });

        // Başarı mesajını göster ve direkt ana sayfaya yönlendir
        // Navigator'ı Future.microtask ile çağır - context'in hazır olmasını bekle
        Future.microtask(() {
          if (mounted) {
            ErrorHandler.showSuccess(context, 'Giriş başarılı! Hoş geldiniz!');
            Navigator.of(context).pushReplacementNamed(AppRoutes.main);
          }
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
        debugPrint('❌ Giriş başarısız: user null');
        ErrorHandler.showError(
            context, 'Giriş yapılamadı. Lütfen bilgilerinizi kontrol edin.');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');

      if (mounted) {
        // Önce loading'i kapat
        setState(() {
          _isLoading = false;
        });

        String errorMessage;
        // ÖNCE ağ hatalarını kontrol et
        if (e.code == 'network-request-failed' ||
            e.code == 'timeout' ||
            e.message?.toLowerCase().contains('network') == true ||
            e.message?.toLowerCase().contains('connection') == true ||
            e.message?.toLowerCase().contains('internet') == true ||
            e.message?.toLowerCase().contains('failed host lookup') == true) {
          errorMessage =
              'İnternet bağlantınızı kontrol edin. Bağlantı sorunu nedeniyle giriş yapılamadı.';
        } else {
          // Sonra diğer hataları kontrol et
          switch (e.code) {
            case 'user-not-found':
              errorMessage =
                  'Bu kullanıcı adı veya e-posta ile kayıtlı kullanıcı bulunamadı. Bilgilerinizi kontrol edin veya yeni hesap oluşturun.';
              break;
            case 'wrong-password':
              errorMessage = 'Hatalı şifre girdiniz. Şifrenizi kontrol edin.';
              break;
            case 'invalid-email':
              errorMessage =
                  'Geçersiz e-posta formatı. Lütfen geçerli bir e-posta adresi girin veya kullanıcı adınızı kontrol edin.';
              break;
            case 'user-disabled':
              errorMessage =
                  'Bu hesap devre dışı bırakılmış. Yönetici ile iletişime geçin.';
              break;
            case 'too-many-requests':
              errorMessage =
                  'Çok fazla başarısız giriş denemesi. Lütfen birkaç dakika sonra tekrar deneyin.';
              break;
            case 'invalid-credential':
              errorMessage =
                  'Kullanıcı adı/e-posta veya şifre hatalı. Bilgilerinizi kontrol edin.';
              break;
            default:
              // Eğer mesajda network/connection geçiyorsa, ağ hatası olarak göster
              final messageLower = (e.message ?? '').toLowerCase();
              if (messageLower.contains('network') ||
                  messageLower.contains('connection') ||
                  messageLower.contains('internet') ||
                  messageLower.contains('timeout') ||
                  messageLower.contains('failed host lookup')) {
                errorMessage =
                    'İnternet bağlantınızı kontrol edin. Bağlantı sorunu nedeniyle giriş yapılamadı.';
              } else {
                errorMessage =
                    'Giriş yapılırken hata oluştu. Lütfen bilgilerinizi kontrol edin ve tekrar deneyin.';
              }
          }
        }
        ErrorHandler.showError(context, errorMessage);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Giriş hatası: $e');
      debugPrint('📋 Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        String errorMessage;
        // Hata tipine göre mesaj belirle - ÖNCE ağ hatalarını kontrol et
        final errorString = e.toString().toLowerCase();

        if (errorString.contains('timeout') ||
            errorString.contains('zaman aşımı')) {
          errorMessage =
              'Giriş işlemi zaman aşımına uğradı. İnternet bağlantınızı kontrol edip tekrar deneyin.';
        } else if (errorString.contains('network') ||
            errorString.contains('connection') ||
            errorString.contains('internet') ||
            errorString.contains('failed host lookup') ||
            errorString.contains('socket') ||
            errorString.contains('unreachable')) {
          errorMessage =
              'İnternet bağlantınızı kontrol edin. Bağlantı sorunu nedeniyle giriş yapılamadı.';
        } else if (errorString.contains('user-not-found') &&
            !errorString.contains('network') &&
            !errorString.contains('connection') &&
            !errorString.contains('timeout')) {
          // Sadece gerçekten user-not-found ise göster, ağ hatası değilse
          errorMessage =
              'Bu kullanıcı adı veya e-posta ile kayıtlı kullanıcı bulunamadı. Bilgilerinizi kontrol edin.';
        } else if (errorString.contains('wrong-password') ||
            (errorString.contains('password') &&
                errorString.contains('wrong'))) {
          errorMessage = 'Hatalı şifre girdiniz. Şifrenizi kontrol edin.';
        } else if (errorString.contains('invalid-credential') ||
            errorString.contains('invalid credential')) {
          errorMessage =
              'Kullanıcı adı/e-posta veya şifre hatalı. Bilgilerinizi kontrol edin.';
        } else if (errorString.contains('invalid-email') &&
            !errorString.contains('network') &&
            !errorString.contains('connection')) {
          errorMessage =
              'Geçersiz e-posta formatı. Lütfen geçerli bir e-posta adresi girin.';
        } else if (errorString.contains('too-many-requests') ||
            errorString.contains('too many requests')) {
          errorMessage =
              'Çok fazla başarısız giriş denemesi. Lütfen birkaç dakika sonra tekrar deneyin.';
        } else if (errorString.contains('permission-denied') ||
            errorString.contains('permission denied')) {
          errorMessage =
              'Firestore erişim izni hatası. Lütfen yönetici ile iletişime geçin.';
        } else if (errorString.contains('unavailable') ||
            errorString.contains('service unavailable')) {
          errorMessage =
              'Servis şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.';
        } else {
          // Genel hata mesajı
          errorMessage =
              'Giriş yapılırken bir hata oluştu. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.';
        }

        debugPrint('📢 Kullanıcıya gösterilecek hata mesajı: $errorMessage');
        ErrorHandler.showError(context, errorMessage);
      }
    } finally {
      // Loading durumu zaten catch bloklarında kapatıldı, burada sadece emin ol
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ErrorHandler.showError(context, 'Kullanım şartlarını kabul etmelisiniz');
      return;
    }

    // Prevent duplicate operations
    if (_isLoading) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Network bağlantısı kontrolü kaldırıldı - Firebase kendi kontrolünü yapıyor
      // Bağlantı yoksa Firebase hata verecek, o zaman gösteririz

      debugPrint('📝 Kayıt işlemi başlatılıyor...');

      // Firebase ile kayıt ol - Firestore kaydı artık non-blocking, daha hızlı
      final user = await _userAuthService
          .signUpWithUsername(
        _fullNameController.text.trim(),
        _usernameController.text.trim(),
        _registerEmailController.text.trim(),
        _registerPasswordController.text,
      )
          .timeout(const Duration(seconds: 60), onTimeout: () {
        debugPrint('⏱️ Genel kayıt işlemi zaman aşımına uğradı');
        throw FirebaseAuthException(
          code: 'timeout',
          message:
              'Kayıt işlemi zaman aşımına uğradı. İnternet bağlantınızı kontrol edip tekrar deneyin.',
        );
      });

      if (user != null && mounted) {
        // Kayıt başarılı - kullanıcı zaten Firebase Auth'ta giriş yapmış durumda
        debugPrint(
            '✅ Kayıt başarılı! Kullanıcı ID: ${user.uid}, Email: ${user.email}');

        // Form alanlarını temizle
        _fullNameController.clear();
        _usernameController.clear();
        _registerEmailController.clear();
        _registerPasswordController.clear();
        _confirmPasswordController.clear();
        _acceptTerms = false;

        // Loading durumunu kapat
        setState(() {
          _isLoading = false;
        });

        // Başarı mesajını göster ve direkt ana sayfaya yönlendir
        // Navigator'ı Future.microtask ile çağır - context'in hazır olmasını bekle
        Future.microtask(() {
          if (mounted) {
            ErrorHandler.showSuccess(context, 'Kayıt başarılı! Hoş geldiniz!');
            Navigator.of(context).pushReplacementNamed(AppRoutes.main);
          }
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
        debugPrint('❌ Kayıt başarısız: user null');
        ErrorHandler.showError(
            context, 'Kayıt olunamadı. Lütfen tekrar deneyin.');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Kayıt FirebaseAuthException: ${e.code} - ${e.message}');
      if (mounted) {
        // Önce loading'i kapat
        setState(() {
          _isLoading = false;
        });

        String errorMessage;
        switch (e.code) {
          case 'weak-password':
            // Firebase minimum 6 karakter istiyor
            errorMessage = 'Şifre en az 6 karakter olmalıdır.';
            break;
          case 'email-already-in-use':
            errorMessage = 'Bu e-posta adresi zaten kullanımda.';
            break;
          case 'invalid-email':
            errorMessage = 'Geçersiz e-posta adresi.';
            break;
          case 'operation-not-allowed':
            errorMessage = 'E-posta/şifre hesapları devre dışı.';
            break;
          case 'username-already-in-use':
            errorMessage = 'Bu kullanıcı adı zaten kullanımda.';
            break;
          case 'timeout':
            errorMessage =
                'Kayıt işlemi zaman aşımına uğradı. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.';
            break;
          default:
            errorMessage = e.message ??
                'Kayıt olurken hata oluştu. Lütfen bilgilerinizi kontrol edin.';
        }
        ErrorHandler.showError(context, errorMessage);
      }
    } on TimeoutException catch (e) {
      debugPrint('⏱️ Kayıt TimeoutException: $e');
      if (mounted) {
        // Önce loading'i kapat
        setState(() {
          _isLoading = false;
        });
        ErrorHandler.showError(context,
            'Kayıt işlemi zaman aşımına uğradı. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Kayıt beklenmeyen hatası: $e');
      debugPrint('📋 Stack trace: $stackTrace');
      if (mounted) {
        // Önce loading'i kapat
        setState(() {
          _isLoading = false;
        });

        String errorMessage = 'Kayıt olurken bir hata oluştu.';
        if (e.toString().contains('network') ||
            e.toString().contains('connection')) {
          errorMessage = 'İnternet bağlantınızı kontrol edin.';
        }
        ErrorHandler.showError(context, errorMessage);
      }
    } finally {
      // Her durumda loading'i kapat
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ErrorHandler.showError(context, 'Lütfen kullanıcı adınızı girin');
      return;
    }

    try {
      await _userAuthService.resetPassword(_emailController.text.trim());
      if (mounted) {
        ErrorHandler.showSuccess(
            context, 'Şifre sıfırlama e-postası gönderildi!');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Şifre sıfırlama hatası: $e';
        if (e.toString().contains('network') ||
            e.toString().contains('connection')) {
          errorMessage = 'İnternet bağlantınızı kontrol edin.';
        }
        ErrorHandler.showError(context, errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin için gerekli

    // Show loading screen until initialized - sadece ortada yuvarlak
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: AppDesignSystem.background,
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppDesignSystem.primary,
            ),
          ),
        ),
      );
    }

    // Web için responsive layout
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    return Scaffold(
      backgroundColor: AppDesignSystem.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Split-screen layout for desktop, stacked for mobile
            if (isDesktop) {
              return _buildSplitScreenLayout(context);
            } else {
              return _buildMobileLayout(context, isTablet);
            }
          },
        ),
      ),
    );
  }

  // Modern split-screen layout for desktop
  Widget _buildSplitScreenLayout(BuildContext context) {
    return Row(
      children: [
        // Left side - Branding area
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppDesignSystem.textPrimary,
                  AppDesignSystem.surface,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Decorative elements
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppDesignSystem.primary.withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -150,
                  left: -150,
                  child: Container(
                    width: 500,
                    height: 500,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppDesignSystem.primary.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Content - Overflow önleme ile
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 60, vertical: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        SizedBox(
                          height: 138,
                          width: 620,
                          child: Image.asset(
                            'assets/images/tunex_banner.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Tagline
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppDesignSystem.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: AppDesignSystem.primary.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                color: AppDesignSystem.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Premium Tuning Çözümleri',
                                style: GoogleFonts.inter(
                                  color: AppDesignSystem.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Main heading
                        Text(
                          "TuneX'e\nHoş Geldiniz",
                          style: GoogleFonts.poppins(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Description
                        Text(
                          'Performans, stil ve kaliteyi bir araya getiren\nprofesyonel tuning çözümleri ile aracınızı\ntransform edin.',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.8),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Features - Kompakt
                        _buildFeatureItem(
                            Icons.speed_rounded, 'Yüksek Performans'),
                        const SizedBox(height: 12),
                        _buildFeatureItem(
                            Icons.auto_awesome_rounded, 'Premium Kalite'),
                        const SizedBox(height: 12),
                        _buildFeatureItem(
                            Icons.verified_rounded, 'Güvenilir Hizmet'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right side - Form area
        Expanded(
          flex: 6,
          child: Container(
            color: AppDesignSystem.background,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Welcome text
                  Text(
                    _isLoginMode ? 'Hoş Geldiniz' : 'Hesap Oluştur',
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppDesignSystem.textPrimary,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLoginMode
                        ? 'Hesabınıza giriş yaparak devam edin'
                        : 'Yeni hesap oluşturarak başlayın',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppDesignSystem.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Tab selector
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppDesignSystem.surfaceElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppDesignSystem.borderLight,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isLoginMode = true;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _isLoginMode
                                    ? AppDesignSystem.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Giriş Yap',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: _isLoginMode
                                      ? Colors.white
                                      : AppDesignSystem.textSecondary,
                                  fontWeight: _isLoginMode
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isLoginMode = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: !_isLoginMode
                                    ? AppDesignSystem.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Kayıt Ol',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: !_isLoginMode
                                      ? Colors.white
                                      : AppDesignSystem.textSecondary,
                                  fontWeight: !_isLoginMode
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Giriş formu alanları
                        if (_isLoginMode) ...[
                          // Kullanıcı adı alanı
                          TextFormField(
                            controller: _emailController,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              color: AppDesignSystem.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Kullanıcı Adı veya E-posta',
                              hintText:
                                  'Kullanıcı adınızı veya e-posta adresinizi girin',
                              labelStyle: GoogleFonts.inter(
                                fontSize: 16,
                                color: AppDesignSystem.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              hintStyle: GoogleFonts.inter(
                                fontSize: 17,
                                color: AppDesignSystem.textTertiary,
                              ),
                              prefixIcon: Icon(
                                Icons.person_outline_rounded,
                                color: AppDesignSystem.textSecondary,
                                size: 24,
                              ),
                              filled: true,
                              fillColor: AppDesignSystem.surfaceElevated,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 26,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Kullanıcı adı veya e-posta gerekli';
                              }
                              // E-posta formatındaysa geçerli e-posta kontrolü yap
                              if (SecurityManager.isValidEmail(value)) {
                                return null; // Geçerli e-posta
                              }
                              // Kullanıcı adı formatındaysa minimum uzunluk kontrolü
                              if (value.length < 2) {
                                return 'Kullanıcı adı en az 2 karakter olmalı';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          // Şifre alanı
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              color: AppDesignSystem.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Şifre',
                              hintText: 'Şifrenizi girin',
                              labelStyle: GoogleFonts.inter(
                                fontSize: 16,
                                color: AppDesignSystem.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              hintStyle: GoogleFonts.inter(
                                fontSize: 17,
                                color: AppDesignSystem.textTertiary,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline_rounded,
                                color: AppDesignSystem.textSecondary,
                                size: 24,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppDesignSystem.textSecondary,
                                  size: 24,
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
                                horizontal: 28,
                                vertical: 26,
                              ),
                            ),
                            validator: (value) {
                              // Şifre validasyonu kaldırıldı - sadece boş olmaması kontrol ediliyor
                              if (value == null || value.isEmpty) {
                                return 'Şifre gerekli';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          // Şifremi Unuttum
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _resetPassword,
                              child: Text(
                                'Şifremi Unuttum',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: AppDesignSystem.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Giriş butonu
                          SizedBox(
                            width: double.infinity,
                            height: 64,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppDesignSystem.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 28,
                                      width: 28,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Text(
                                      'Giriş Yap',
                                      style: GoogleFonts.inter(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                        // Kayıt formu alanları
                        if (!_isLoginMode) ...[
                          // Ad Soyad
                          TextFormField(
                            controller: _fullNameController,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              color: AppDesignSystem.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Ad Soyad',
                              hintText: 'Adınız ve soyadınız',
                              labelStyle: GoogleFonts.inter(
                                fontSize: 16,
                                color: AppDesignSystem.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              hintStyle: GoogleFonts.inter(
                                fontSize: 17,
                                color: AppDesignSystem.textTertiary,
                              ),
                              prefixIcon: Icon(
                                Icons.person_outline_rounded,
                                color: AppDesignSystem.textSecondary,
                                size: 24,
                              ),
                              filled: true,
                              fillColor: AppDesignSystem.surfaceElevated,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 18,
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
                          const SizedBox(height: 16),
                          // Kullanıcı Adı
                          TextFormField(
                            controller: _usernameController,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              color: AppDesignSystem.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Kullanıcı Adı',
                              hintText: 'Kullanıcı adınız',
                              labelStyle: GoogleFonts.inter(
                                fontSize: 16,
                                color: AppDesignSystem.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              hintStyle: GoogleFonts.inter(
                                fontSize: 17,
                                color: AppDesignSystem.textTertiary,
                              ),
                              prefixIcon: Icon(
                                Icons.alternate_email_rounded,
                                color: AppDesignSystem.textSecondary,
                                size: 24,
                              ),
                              filled: true,
                              fillColor: AppDesignSystem.surfaceElevated,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 18,
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
                          const SizedBox(height: 16),
                          // E-posta
                          TextFormField(
                            controller: _registerEmailController,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              color: AppDesignSystem.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: 'E-posta',
                              hintText: 'ornek@email.com',
                              labelStyle: GoogleFonts.inter(
                                fontSize: 16,
                                color: AppDesignSystem.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              hintStyle: GoogleFonts.inter(
                                fontSize: 17,
                                color: AppDesignSystem.textTertiary,
                              ),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: AppDesignSystem.textSecondary,
                                size: 24,
                              ),
                              filled: true,
                              fillColor: AppDesignSystem.surfaceElevated,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 18,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'E-posta adresi gerekli';
                              }
                              // SecurityManager ile email validasyonu
                              if (!SecurityManager.isValidEmail(value)) {
                                return 'Geçerli bir e-posta adresi girin';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          // Şifre
                          TextFormField(
                            controller: _registerPasswordController,
                            obscureText: _obscureRegisterPassword,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              color: AppDesignSystem.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Şifre',
                              hintText: 'Şifrenizi girin',
                              labelStyle: GoogleFonts.inter(
                                fontSize: 16,
                                color: AppDesignSystem.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              hintStyle: GoogleFonts.inter(
                                fontSize: 17,
                                color: AppDesignSystem.textTertiary,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline_rounded,
                                color: AppDesignSystem.textSecondary,
                                size: 24,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureRegisterPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppDesignSystem.textSecondary,
                                  size: 24,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureRegisterPassword =
                                        !_obscureRegisterPassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: AppDesignSystem.surfaceElevated,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 18,
                              ),
                            ),
                            validator: (value) {
                              // Şifre validasyonu kaldırıldı - sadece boş olmaması kontrol ediliyor
                              if (value == null || value.isEmpty) {
                                return 'Şifre gerekli';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Şifre Tekrar
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              color: AppDesignSystem.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Şifre Tekrar',
                              hintText: 'Şifrenizi tekrar girin',
                              labelStyle: GoogleFonts.inter(
                                fontSize: 16,
                                color: AppDesignSystem.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              hintStyle: GoogleFonts.inter(
                                fontSize: 17,
                                color: AppDesignSystem.textTertiary,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline_rounded,
                                color: AppDesignSystem.textSecondary,
                                size: 24,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppDesignSystem.textSecondary,
                                  size: 24,
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
                                horizontal: 24,
                                vertical: 18,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Şifre tekrarı gerekli';
                              }
                              if (value != _registerPasswordController.text) {
                                return 'Şifreler eşleşmiyor';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
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
                                activeColor: AppDesignSystem.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _acceptTerms = !_acceptTerms;
                                    });
                                  },
                                  child: Text(
                                    'Kullanım şartlarını ve gizlilik politikasını kabul ediyorum.',
                                    style: GoogleFonts.inter(
                                      color: AppDesignSystem.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Kayıt butonu
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppDesignSystem.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 28,
                                      width: 28,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Text(
                                      'Kayıt Ol',
                                      style: GoogleFonts.inter(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Mobile layout (stacked)
  Widget _buildMobileLayout(BuildContext context, bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 48 : 24,
        vertical: isTablet ? 36 : 24,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: isTablet ? 60 : 40),
          // Logo
          SizedBox(
            height: isTablet ? 124 : 104,
            width: isTablet ? 620 : 460,
            child: Image.asset(
              'assets/images/tunex_banner.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Text(
            _isLoginMode ? 'Hesabınıza giriş yapın' : 'Yeni hesap oluşturun',
            style: GoogleFonts.inter(
              fontSize: isTablet ? 20 : 18,
              color: AppDesignSystem.textSecondary,
            ),
          ),
          SizedBox(height: isTablet ? 48 : 40),
          // Tab selector
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppDesignSystem.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppDesignSystem.borderLight,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isLoginMode = true;
                      });
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: isTablet ? 18 : 16),
                      decoration: BoxDecoration(
                        color: _isLoginMode
                            ? AppDesignSystem.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Giriş Yap',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: _isLoginMode
                              ? Colors.white
                              : AppDesignSystem.textSecondary,
                          fontWeight:
                              _isLoginMode ? FontWeight.w700 : FontWeight.w500,
                          fontSize: isTablet ? 18 : 16,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isLoginMode = false;
                      });
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: isTablet ? 18 : 16),
                      decoration: BoxDecoration(
                        color: !_isLoginMode
                            ? AppDesignSystem.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Kayıt Ol',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: !_isLoginMode
                              ? Colors.white
                              : AppDesignSystem.textSecondary,
                          fontWeight:
                              !_isLoginMode ? FontWeight.w700 : FontWeight.w500,
                          fontSize: isTablet ? 18 : 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isTablet ? 40 : 32),
          // Form container
          Container(
            padding: EdgeInsets.all(isTablet ? 48 : 40),
            decoration: BoxDecoration(
              color: AppDesignSystem.surfaceElevated,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppDesignSystem.borderLight,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Use the same form fields as desktop but with mobile-optimized sizes
                  if (_isLoginMode) ...[
                    _buildMobileTextField(
                      controller: _emailController,
                      label: 'Kullanıcı Adı veya E-posta',
                      hint: 'Kullanıcı adınızı veya e-posta adresinizi girin',
                      icon: Icons.person_outline_rounded,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kullanıcı adı veya e-posta gerekli';
                        }
                        // E-posta formatındaysa geçerli e-posta kontrolü yap
                        if (SecurityManager.isValidEmail(value)) {
                          return null; // Geçerli e-posta
                        }
                        // Kullanıcı adı formatındaysa minimum uzunluk kontrolü
                        if (value.length < 2) {
                          return 'Kullanıcı adı en az 2 karakter olmalı';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildMobileTextField(
                      controller: _passwordController,
                      label: 'Şifre',
                      hint: 'Şifrenizi girin',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppDesignSystem.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Şifre gerekli';
                        }
                        // Şifre validasyonu kaldırıldı - sadece boş olmaması kontrol ediliyor
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _resetPassword,
                        child: Text(
                          'Şifremi Unuttum',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppDesignSystem.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppDesignSystem.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : Text(
                                'Giriş Yap',
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ] else ...[
                    // Register form fields for mobile
                    _buildMobileTextField(
                      controller: _fullNameController,
                      label: 'Ad Soyad',
                      hint: 'Adınız ve soyadınız',
                      icon: Icons.person_outline_rounded,
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
                    _buildMobileTextField(
                      controller: _usernameController,
                      label: 'Kullanıcı Adı',
                      hint: 'Kullanıcı adınız',
                      icon: Icons.alternate_email_rounded,
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
                    _buildMobileTextField(
                      controller: _registerEmailController,
                      label: 'E-posta',
                      hint: 'ornek@email.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
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
                    _buildMobileTextField(
                      controller: _registerPasswordController,
                      label: 'Şifre',
                      hint: 'Şifrenizi girin',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscureRegisterPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureRegisterPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppDesignSystem.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureRegisterPassword =
                                !_obscureRegisterPassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Şifre gerekli';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildMobileTextField(
                      controller: _confirmPasswordController,
                      label: 'Şifre Tekrar',
                      hint: 'Şifrenizi tekrar girin',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppDesignSystem.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Şifre tekrarı gerekli';
                        }
                        if (value != _registerPasswordController.text) {
                          return 'Şifreler eşleşmiyor';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged: (value) {
                            setState(() {
                              _acceptTerms = value ?? false;
                            });
                          },
                          activeColor: AppDesignSystem.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _acceptTerms = !_acceptTerms;
                              });
                            },
                            child: Text(
                              'Kullanım şartlarını ve gizlilik politikasını kabul ediyorum.',
                              style: GoogleFonts.inter(
                                color: AppDesignSystem.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppDesignSystem.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : Text(
                                'Kayıt Ol',
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Helper method for mobile text fields
  Widget _buildMobileTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(
        fontSize: 16,
        color: AppDesignSystem.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.inter(
          fontSize: 15,
          color: AppDesignSystem.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 16,
          color: AppDesignSystem.textTertiary,
        ),
        prefixIcon: Icon(
          icon,
          color: AppDesignSystem.textSecondary,
          size: 22,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppDesignSystem.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 22,
        ),
      ),
      validator: validator,
    );
  }

  // Helper method for feature items in split-screen - Kompakt versiyon
  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppDesignSystem.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppDesignSystem.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}
