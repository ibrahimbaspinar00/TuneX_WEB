import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/firebase_data_service.dart';
import '../services/order_service.dart';
import '../services/wallet_service.dart';
import '../providers/app_state_provider.dart';
import '../utils/professional_error_handler.dart';
import '../config/app_routes.dart';
import 'siparisler_sayfasi.dart';
import 'adres_yonetimi_sayfasi.dart';
import 'odeme_yontemleri_sayfasi.dart';
import 'bildirim_ayarlari_sayfasi.dart';
import 'para_yukleme_sayfasi.dart';
import 'profil_duzenleme_sayfasi.dart';
import 'degerlendirmelerim_sayfasi.dart';
import 'satici_mesajlarim_sayfasi.dart';
import 'krediler_sayfasi.dart';
import 'indirim_kuponlarim_sayfasi.dart';
import '../theme/app_design_system.dart';

class HesabimSayfasi extends StatefulWidget {
  const HesabimSayfasi({super.key});

  @override
  State<HesabimSayfasi> createState() => _HesabimSayfasiState();
}

class _HesabimSayfasiState extends State<HesabimSayfasi>
    with WidgetsBindingObserver {
  String _userName = 'Kullanıcı';
  String _userEmail = 'kullanici@example.com';
  String? _profileImageUrl;
  double _walletBalance = 0.0;
  int _orderCount = 0;
  int _favoriteCount = 0;

  // Services
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDataService _firebaseDataService = FirebaseDataService();
  final OrderService _orderService = OrderService();
  final WalletService _walletService = WalletService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot>? _ordersSub;
  StreamSubscription<QuerySnapshot>? _favoritesSub;
  StreamSubscription<DocumentSnapshot>? _walletSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeWallet();
    _loadUserData();
    _attachRealtimeListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Uygulama tekrar görünür olduğunda bakiyeyi güncelle
      _refreshWalletBalance();
    }
  }

  Future<void> _initializeWallet() async {
    try {
      await _walletService.initialize();
      if (mounted) {
        setState(() {
          _walletBalance = _walletService.currentBalance;
        });
      }
    } catch (e) {
      debugPrint('Error initializing wallet: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      // Kullanıcı giriş yapmış mı kontrol et
      final user = _auth.currentUser;
      if (user == null) {
        // Kullanıcı giriş yapmamış - varsayılan değerlerle devam et
        if (mounted) {
          setState(() {
            _userName = 'Misafir Kullanıcı';
            _userEmail = 'Giriş yapmak için tıklayın';
            // Oturum yoksa, favori sayısını uygulama state'inden al (kalıcılık için fallback)
            _favoriteCount =
                context.read<AppStateProvider>().favoriteProducts.length;
            _orderCount = 0;
          });
        }
        return;
      }

      // Firebase'den kullanıcı bilgilerini yükle (timeout ile)
      try {
        final userProfile = await _firebaseDataService
            .getUserProfile()
            .timeout(const Duration(seconds: 5));
        final userStats = await _firebaseDataService
            .getUserStats()
            .timeout(const Duration(seconds: 5));

        if (mounted) {
          // Ad Soyad: Önce Firestore'dan, yoksa FirebaseAuth displayName'den, o da yoksa email'den
          String fullName = '';
          if (userProfile != null && userProfile['fullName'] != null) {
            fullName = userProfile['fullName'].toString().trim();
          }
          if (fullName.isEmpty && user.displayName != null) {
            fullName = user.displayName!.trim();
          }
          if (fullName.isEmpty && user.email != null) {
            // Email'den kullanıcı adı oluştur (örn: test@example.com -> test)
            fullName = user.email!.split('@')[0];
          }
          if (fullName.isEmpty) {
            fullName = 'Kullanıcı';
          }

          // Email: Önce Firestore'dan, yoksa FirebaseAuth'tan
          String email = '';
          if (userProfile != null && userProfile['email'] != null) {
            email = userProfile['email'].toString().trim();
          }
          if (email.isEmpty && user.email != null) {
            email = user.email!.trim();
          }
          if (email.isEmpty) {
            email = 'kullanici@example.com';
          }

          // Profil fotoğrafı URL'i
          String? profileImageUrl;
          if (userProfile != null && userProfile['profileImageUrl'] != null) {
            profileImageUrl = userProfile['profileImageUrl'].toString().trim();
            if (profileImageUrl.isEmpty) profileImageUrl = null;
          }

          setState(() {
            _userName = fullName;
            _userEmail = email;
            _profileImageUrl = profileImageUrl;
            _orderCount = userStats['totalOrders'] ?? 0;
            _favoriteCount = userStats['favoriteCount'] ?? 0;
          });
        }
      } catch (e) {
        debugPrint('Error loading user data from Firebase: $e');
        // Hata durumunda FirebaseAuth'tan bilgileri al
        if (mounted) {
          setState(() {
            _userName = user.displayName ??
                (user.email != null ? user.email!.split('@')[0] : 'Kullanıcı');
            _userEmail = user.email ?? 'kullanici@example.com';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  void _attachRealtimeListeners() {
    final user = _auth.currentUser;
    if (user == null) return;

    // Firebase'in initialize edilip edilmediğini kontrol et
    try {
      Firebase.app();
    } catch (e) {
      debugPrint('Firebase not initialized, skipping real-time listeners: $e');
      return;
    }

    // Realtime orders count
    _ordersSub?.cancel();
    _ordersSub = _firestore
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted) return;
        int totalOrders = snapshot.docs.length;
        setState(() {
          _orderCount = totalOrders;
        });
      },
      onError: (error) {
        debugPrint('Error in orders real-time listener: $error');
      },
    );

    // Realtime favorites count
    _favoritesSub?.cancel();
    _favoritesSub = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted) return;
        setState(() {
          _favoriteCount = snapshot.docs.length;
        });
      },
      onError: (error) {
        debugPrint('Error in favorites real-time listener: $error');
      },
    );

    // Realtime wallet balance
    _walletSub?.cancel();
    _walletSub = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('wallet')
        .doc('balance')
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted) return;
        if (snapshot.exists && snapshot.data() != null) {
          final balance =
              (snapshot.data()!['balance'] as num?)?.toDouble() ?? 0.0;
          setState(() {
            _walletBalance = balance;
          });
          // WalletService'in static değişkenini güncelle (initialize çağrısı yapmadan)
          // initialize() çağrısı Firestore'dan tekrar okuma yapar ve quota hatasına neden olabilir
        }
      },
      onError: (error) {
        debugPrint('Error in wallet real-time listener: $error');
        // Quota hatası veya diğer hatalar durumunda listener'ı durdur
        if (error.toString().contains('RESOURCE_EXHAUSTED') ||
            error.toString().contains('Quota exceeded')) {
          debugPrint('Firestore quota exceeded, stopping wallet listener');
          _walletSub?.cancel();
        }
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Stream subscription'ları iptal et ve null yap
    _ordersSub?.cancel();
    _ordersSub = null;
    _favoritesSub?.cancel();
    _favoritesSub = null;
    _walletSub?.cancel();
    _walletSub = null;
    super.dispose();
  }

  // Cüzdan bakiyesini manuel olarak güncelle
  Future<void> _refreshWalletBalance() async {
    final user = _auth.currentUser;
    if (user == null || !mounted) return;

    try {
      // Önce WalletService'ten al (en hızlı ve güvenilir)
      await _walletService.initialize();
      if (mounted) {
        setState(() {
          _walletBalance = _walletService.currentBalance;
        });
      }

      // Firebase initialize edilmişse Firestore'dan da doğrula (non-blocking)
      try {
        Firebase.app();
        // Offline durumunda cache'den okur
        final walletDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('wallet')
            .doc('balance')
            .get()
            .timeout(const Duration(seconds: 3), onTimeout: () {
          // Timeout durumunda mevcut değeri kullan
          throw Exception('Timeout - using current balance');
        });

        if (walletDoc.exists && walletDoc.data() != null && mounted) {
          final balance = (walletDoc.data()!['balance'] as num?)?.toDouble() ??
              _walletBalance;
          setState(() {
            _walletBalance = balance;
          });
        }
      } catch (e) {
        // Firebase hatası - WalletService'ten alınan değer zaten set edildi
        // Offline durumunda hata gösterme, sadece logla
        final errorString = e.toString().toLowerCase();
        if (!errorString.contains('offline') &&
            !errorString.contains('unavailable') &&
            !errorString.contains('timeout')) {
          debugPrint('Firebase error in refreshWalletBalance: $e');
        }
      }
    } catch (e) {
      debugPrint('Error refreshing wallet balance: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        // Başlangıç sayfasına (LandingPage) yönlendir
        AppRoutes.navigateToLanding(context);
      }
    } catch (e) {
      ProfessionalErrorHandler.showError(
        context: context,
        title: 'Çıkış Hatası',
        message: 'Çıkış yapılırken hata oluştu: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 80 : 24,
            vertical: 16,
          ),
          child: Row(
            children: [
              Text(
                'Hesabım',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F0F0F),
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            await _refreshWalletBalance().timeout(const Duration(seconds: 3));
          } catch (e) {
            debugPrint('Wallet refresh error: $e');
          }
          try {
            await _loadUserData().timeout(const Duration(seconds: 3));
          } catch (e) {
            debugPrint('User data load error: $e');
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profil kartı - Trendyol tarzı
              _buildTrendyolProfileCard(),

              const SizedBox(height: 16),

              // Cüzdan kartı
              _buildWalletCard(),

              const SizedBox(height: 16),

              // İstatistikler
              _buildStatsCard(),

              const SizedBox(height: 16),

              // Menü seçenekleri - Trendyol tarzı (içinde çıkış yap da var)
              _buildTrendyolMenuOptions(),
            ],
          ),
        ),
      ),
    );
  }

  // Trendyol tarzı profil kartı
  Widget _buildTrendyolProfileCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : 24,
        vertical: 16,
      ),
      padding: const EdgeInsets.all(24),
      decoration: AppDesignSystem.cardDecoration(
        borderRadius: AppDesignSystem.radiusM,
        shadows: AppDesignSystem.shadowS,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfilDuzenlemeSayfasi(),
                ),
              );
              if (result == true && mounted) {
                await Future.delayed(const Duration(milliseconds: 500));
                await _loadUserData();
              }
            },
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppDesignSystem.primaryContainer,
                  backgroundImage:
                      (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                          ? NetworkImage(_profileImageUrl!)
                          : null,
                  child: _profileImageUrl == null
                      ? Text(
                          _userName.isNotEmpty
                              ? _userName[0].toUpperCase()
                              : 'K',
                          style: AppDesignSystem.heading3.copyWith(
                            color: AppDesignSystem.primary,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppDesignSystem.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDesignSystem.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _userName,
                  style: AppDesignSystem.heading3,
                ),
                const SizedBox(height: AppDesignSystem.spacingXS),
                Text(
                  _userEmail,
                  style: AppDesignSystem.bodyMedium.copyWith(
                    color: AppDesignSystem.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDesignSystem.spacingS),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.spacingS,
                    vertical: AppDesignSystem.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppDesignSystem.successLight,
                    borderRadius:
                        BorderRadius.circular(AppDesignSystem.radiusXS),
                  ),
                  child: Text(
                    'Aktif Üye',
                    style: AppDesignSystem.labelSmall.copyWith(
                      color: AppDesignSystem.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfilDuzenlemeSayfasi(),
                ),
              );
              if (result == true && mounted) {
                // Hemen setState ile güncelle
                setState(() {});
                // Sonra verileri yeniden yükle
                await Future.delayed(const Duration(milliseconds: 300));
                await _loadUserData();
                // Tekrar setState ile güncelle
                if (mounted) {
                  setState(() {});
                }
              }
            },
            icon: Icon(Icons.edit, color: AppDesignSystem.textSecondary),
            tooltip: 'Profili Düzenle',
          ),
        ],
      ),
    );
  }

  // Trendyol tarzı cüzdan kartı
  Widget _buildWalletCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : 24,
      ),
      padding: const EdgeInsets.all(20),
      decoration: AppDesignSystem.cardDecoration(
        borderRadius: AppDesignSystem.radiusM,
        shadows: AppDesignSystem.shadowS,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppDesignSystem.successLight,
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
            ),
            child: Icon(
              Icons.account_balance_wallet,
              color: AppDesignSystem.success,
              size: 24,
            ),
          ),
          const SizedBox(width: AppDesignSystem.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cüzdan Bakiyesi',
                  style: AppDesignSystem.bodyMedium.copyWith(
                    color: AppDesignSystem.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDesignSystem.spacingXS),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    '${_walletBalance.toStringAsFixed(2)} ₺',
                    key: ValueKey(_walletBalance),
                    style: AppDesignSystem.heading3.copyWith(
                      color: AppDesignSystem.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ParaYuklemeSayfasi(),
                ),
              );
              if (result == true && mounted) {
                await _refreshWalletBalance();
              }
            },
            style: AppDesignSystem.primaryButtonStyle(
              padding: AppDesignSystem.spacingM,
              borderRadius: AppDesignSystem.radiusS,
            ),
            child: Text(
              'Para Yükle',
              style: AppDesignSystem.buttonSmall,
            ),
          ),
        ],
      ),
    );
  }

  // Trendyol tarzı istatistikler kartı
  Widget _buildStatsCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : 24,
      ),
      padding: const EdgeInsets.all(20),
      decoration: AppDesignSystem.cardDecoration(
        borderRadius: AppDesignSystem.radiusM,
        shadows: AppDesignSystem.shadowS,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Siparişler',
              '$_orderCount',
              Icons.shopping_bag,
              const Color(0xFF00D1FF),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppDesignSystem.borderLight,
          ),
          Expanded(
            child: _buildStatItem(
              'Favoriler',
              '$_favoriteCount',
              Icons.favorite,
              const Color(0xFFEF4444),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppDesignSystem.borderLight,
          ),
          Expanded(
            child: _buildStatItem(
              'Puan',
              '4.8',
              Icons.star,
              const Color(0xFFFF6A00),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppDesignSystem.heading3.copyWith(
            color: AppDesignSystem.textPrimary,
          ),
        ),
        const SizedBox(height: AppDesignSystem.spacingXS),
        Text(
          label,
          style: AppDesignSystem.bodySmall.copyWith(
            color: AppDesignSystem.textSecondary,
          ),
        ),
      ],
    );
  }

  // Trendyol tarzı menü seçenekleri
  Widget _buildTrendyolMenuOptions() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;

    final menuItems = [
      _MenuItem(
        title: 'Tüm Siparişlerim',
        subtitle: '',
        icon: Icons.shopping_bag,
        color: const Color(0xFF0F0F0F),
        onTap: () async {
          final orders = await _orderService.getUserOrders();
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SiparislerSayfasi(orders: orders),
            ),
          );
        },
      ),
      _MenuItem(
        title: 'Değerlendirmelerim',
        subtitle: '',
        icon: Icons.rate_review,
        color: const Color(0xFF0F0F0F),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DegerlendirmelerimSayfasi(),
            ),
          );
        },
      ),
      _MenuItem(
        title: 'Satıcı Mesajlarım',
        subtitle: '',
        icon: Icons.mail_outline,
        color: const Color(0xFF0F0F0F),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SaticiMesajlarimSayfasi(),
            ),
          );
        },
      ),
      _MenuItem(
        title: 'Krediler %0 Faiz Fırsatı',
        subtitle: '',
        icon: Icons.account_balance_wallet,
        color: const Color(0xFF0F0F0F),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const KredilerSayfasi(),
            ),
          );
        },
      ),
      _MenuItem(
        title: 'İndirim Kuponlarım',
        subtitle: '',
        icon: Icons.local_offer,
        color: const Color(0xFF0F0F0F),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const IndirimKuponlarimSayfasi(),
            ),
          );
        },
      ),
      _MenuItem(
        title: 'Kullanıcı Bilgilerim',
        subtitle: '',
        icon: Icons.person_outline,
        color: const Color(0xFF0F0F0F),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfilDuzenlemeSayfasi(),
            ),
          );
        },
      ),
      _MenuItem(
        title: 'Adres Yönetimi',
        subtitle: '',
        icon: Icons.location_on_outlined,
        color: const Color(0xFF0F0F0F),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdresYonetimiSayfasi(),
            ),
          );
        },
      ),
      _MenuItem(
        title: 'Ödeme Yöntemleri',
        subtitle: '',
        icon: Icons.credit_card_outlined,
        color: const Color(0xFF0F0F0F),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OdemeYontemleriSayfasi(),
            ),
          );
        },
      ),
      _MenuItem(
        title: 'Bildirim Ayarları',
        subtitle: '',
        icon: Icons.notifications_outlined,
        color: const Color(0xFF0F0F0F),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BildirimAyarlariSayfasi(),
            ),
          );
        },
      ),
      _MenuItem(
        title: 'Çıkış Yap',
        subtitle: '',
        icon: Icons.exit_to_app,
        color: const Color(0xFFEF4444),
        onTap: _signOut,
      ),
    ];

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : 24,
      ),
      decoration: AppDesignSystem.cardDecoration(
        borderRadius: AppDesignSystem.radiusM,
        shadows: AppDesignSystem.shadowS,
      ),
      child: Column(
        children: menuItems.map((item) {
          final isLast = item == menuItems.last;
          return Column(
            children: [
              ListTile(
                leading: Icon(item.icon, color: item.color, size: 22),
                title: Text(
                  item.title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: item.color,
                  ),
                ),
                trailing: item.title == 'Çıkış Yap'
                    ? null
                    : const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Color(0xFF8E98A8),
                      ),
                onTap: item.onTap,
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: const Color(0xFF2A3340),
                  indent: 60,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // Ayarlar dialog'u kaldırıldı
}

class _MenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _MenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
