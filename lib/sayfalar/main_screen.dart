import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_links/app_links.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'ana_sayfa.dart';
import 'favoriler_sayfasi.dart';
import 'sepetim_sayfasi.dart';
import 'hesabim_sayfasi.dart';
import 'kategoriler_sayfasi.dart';
import '../config/app_routes.dart';
import '../model/product.dart';
import '../model/order.dart';
import '../widgets/error_handler.dart';
import '../utils/memory_manager.dart';
import '../utils/network_manager.dart';
import '../services/firebase_data_service.dart';
import '../services/product_service.dart';
import '../services/order_service.dart';
import '../services/admin_service.dart';
import '../model/admin_product.dart';
import '../widgets/ai_chat_widget.dart';
import '../theme/app_design_system.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  int _selectedIndex = 0;
  String? _selectedCategoryForNavigation; // Kategori navigasyonu için
  String? _headerSearchQuery; // Header'daki arama sorgusu

  final List<Product> favoriteProducts = [];
  final List<Product> cartProducts = [];
  final List<Order> orders = [];

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  // Sepete ekleme için loading state
  final Set<String> _addingToCartProducts = {};

  // Header arama controller
  final TextEditingController _headerSearchController = TextEditingController();

  // Network durumu
  bool _isOnline = true;

  // Profil fotoğrafı
  String? _profileImageUrl;

  // Admin kategorileri için service
  final AdminService _adminService = AdminService();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeNetworkListener();
    _listenToDeepLinks();

    // Data loading'i lazy yap - UI render'dan sonra
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // UI render olduktan sonra yükle - performans için
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _initializeApp();
            _loadProfileImage();
          }
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Profil düzenleme sayfasından dönüşte profil fotoğrafını yeniden yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadProfileImage();
      }
    });
  }

  /// Profil fotoğrafını hemen güncelle (callback ile)
  void updateProfileImage(String? imageUrl) {
    if (mounted) {
      setState(() {
        _profileImageUrl = imageUrl;
      });
    }
  }

  void _initializeNetworkListener() {
    // Network durumunu kontrol et ve dinle
    NetworkManager.instance.addCallback((isOnline, connection) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
    });
    // İlk durumu al
    _isOnline = NetworkManager.instance.isOnline;
  }

  /// Deep link'leri dinle (uygulama açıkken)
  void _listenToDeepLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('Deep link error: $err');
    });
  }

  /// Deep link'i işle
  void _handleDeepLink(Uri uri) {
    String? productId;

    // HTTPS formatında deep link (https://tuning-app-789e.web.app/product/{productId})
    if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        (uri.host == 'tuning-app-789e.web.app' ||
            uri.host.contains('tuning-app'))) {
      if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'product') {
        if (uri.pathSegments.length > 1) {
          productId = uri.pathSegments[1];
        }
      }
    }
    // Custom scheme formatında deep link (tunex://product/{productId})
    else if (uri.scheme == 'tunex' && uri.host == 'product') {
      // Önce pathSegments'i kontrol et (en güvenilir)
      if (uri.pathSegments.isNotEmpty) {
        productId = uri.pathSegments.first;
      }
      // Path'ten al (tunex://product/123 formatı için)
      else if (uri.path.isNotEmpty && uri.path != '/') {
        productId = uri.path.replaceFirst('/', '').replaceAll('/', '').trim();
      }
      // Query parametrelerinden al (tunex://product?id=123 formatı için)
      else if (uri.queryParameters.containsKey('id')) {
        productId = uri.queryParameters['id']!;
      }
      // Authority'den al (product:productId formatında ise)
      else if (uri.authority.contains(':')) {
        productId = uri.authority.split(':').last;
      }
    }

    // ProductId bulunduysa yönlendir
    if (productId != null &&
        productId.isNotEmpty &&
        productId != 'product' &&
        productId != '/' &&
        mounted) {
      final finalProductId = productId;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && finalProductId.isNotEmpty) {
          try {
            AppRoutes.navigateToProductDetailById(context, finalProductId);
          } catch (e) {
            // Hata durumunda sessizce devam et
          }
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        // App resumed - optimize memory
        MemoryManager.optimizeMemory();
        break;
      case AppLifecycleState.paused:
        // App paused - clear caches
        MemoryManager.clearAllCaches();
        break;
      case AppLifecycleState.detached:
        // App detached - full cleanup
        _fullCleanup();
        break;
      default:
        break;
    }
  }

  Future<void> _initializeApp() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        debugPrint('User logged in: ${user.email}');
        // Firebase'den favorileri, sepeti ve siparişleri PARALEL yükle - performans için
        // UI'ı bloklamamak için await kullanmadan başlat
        Future.wait([
          _loadFavoritesFromFirebase(),
          _loadCartFromFirebase(),
          _loadOrdersFromFirebase(),
        ]).catchError((e) {
          debugPrint('Data loading error: $e');
          return <void>[];
        });
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
      debugPrint('Initialize app error: $e');
    }
  }

  /// Profil fotoğrafını yükle
  Future<void> _loadProfileImage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final dataService = FirebaseDataService();
      final userProfile = await dataService.getUserProfile();

      if (mounted &&
          userProfile != null &&
          userProfile['profileImageUrl'] != null) {
        final imageUrl = userProfile['profileImageUrl'].toString().trim();
        if (imageUrl.isNotEmpty && imageUrl != _profileImageUrl) {
          // Sadece farklıysa güncelle (gereksiz rebuild'leri önle)
          setState(() {
            _profileImageUrl = imageUrl;
          });
        }
      } else if (mounted &&
          (userProfile == null || userProfile['profileImageUrl'] == null)) {
        // Profil fotoğrafı yoksa temizle
        if (_profileImageUrl != null) {
          setState(() {
            _profileImageUrl = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading profile image: $e');
    }
  }

  /// Firebase'den siparişleri yükle
  Future<void> _loadOrdersFromFirebase() async {
    if (!mounted) return;

    try {
      final orderService = OrderService();
      final userOrders = await orderService.getUserOrders();

      orders.clear();
      orders.addAll(userOrders);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  /// Firebase'den favorileri yükle
  Future<void> _loadFavoritesFromFirebase() async {
    if (!mounted) return;

    try {
      final dataService = FirebaseDataService();
      final productService = ProductService();

      // Firebase'den favori ürün ID'lerini al
      final favoriteIds = await dataService.getFavoriteProductIds();

      if (favoriteIds.isEmpty) {
        return;
      }

      // Her ürün ID'si için ürün bilgisini al ve ekle - PARALEL yükleme
      favoriteProducts.clear();
      final productFutures = favoriteIds
          .map((productId) =>
              productService.getProductById(productId).catchError((e) => null))
          .toList();

      final products = await Future.wait(productFutures);
      favoriteProducts.addAll(products.whereType<Product>());

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  /// Firebase'den sepeti yükle
  Future<void> _loadCartFromFirebase() async {
    if (!mounted) return;

    try {
      final dataService = FirebaseDataService();
      final productService = ProductService();

      // Firebase'den sepet öğelerini al
      final cartItems = await dataService.getCartItems();

      if (cartItems.isEmpty) {
        return;
      }

      // Sepet öğelerini ürünlere dönüştür - PARALEL yükleme
      cartProducts.clear();
      final cartProductFutures = cartItems.map((item) async {
        try {
          final productId =
              item['productId'] as String? ?? item['id'] as String;
          final quantity = item['quantity'] as int? ?? 1;
          final product = await productService.getProductById(productId);
          if (product != null) {
            return product.copyWith(quantity: quantity);
          }
        } catch (e) {
          // Hata durumunda sessizce devam et
        }
        return null;
      }).toList();

      final cartProductsList = await Future.wait(cartProductFutures);
      cartProducts.addAll(cartProductsList.whereType<Product>());

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  void _fullCleanup() {
    MemoryManager.optimizeMemory();
  }

  // _performMemoryCleanup kaldırıldı - performans için timer kullanılmıyor
  // void _performMemoryCleanup() {
  //   if (!mounted) return;
  //   try {
  //     MemoryManager.optimizeMemory();
  //   } catch (e) {
  //     debugPrint('Memory cleanup error: $e');
  //   }
  // }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    _headerSearchController.dispose();
    _fullCleanup();
    super.dispose();
  }

  List<Widget> _getPages() {
    return [
      // 0 - Ana Sayfa
      AnaSayfa(
        key: ValueKey(
            'ana_sayfa_${_headerSearchQuery ?? ''}'), // Arama sorgusu değiştiğinde rebuild et
        favoriteProducts: favoriteProducts,
        cartProducts: cartProducts,
        onFavoriteToggle: (product) =>
            _toggleFavorite(product, showMessage: true),
        onAddToCart: _addToCart,
        onRemoveFromCart: _removeFromCart,
        isAddingToCart: isAddingToCart,
        initialSearchQuery: _headerSearchQuery,
        onNavigateToCategory: _navigateToCategory,
        onNavigateToCart: () {
          setState(() {
            _selectedIndex = 2; // Sepet sayfasına git
          });
        },
      ),
      // 1 - Listelerim (FavorilerSayfasi ile aynı özellikler)
      FavorilerSayfasi(
        favoriteProducts: favoriteProducts,
        cartProducts: cartProducts,
        onFavoriteToggle: _toggleFavorite,
        onAddToCart: _addToCart,
        isAddingToCart: isAddingToCart,
      ),
      // 2 - Sepetim
      SepetimSayfasi(
        cartProducts: cartProducts,
        onRemoveFromCart: _removeFromCart,
        onUpdateQuantity: _updateQuantity,
        onPlaceOrder: _placeOrder,
      ),
      // 3 - Hesabım
      const HesabimSayfasi(),
      // 4 - Kategoriler - Key ile yeniden oluşturulmasını sağla
      KategorilerSayfasi(
        key: ValueKey('categories_${_selectedCategoryForNavigation ?? 'all'}'),
        favoriteProducts: favoriteProducts,
        cartProducts: cartProducts,
        onFavoriteToggle: (product) =>
            _toggleFavorite(product, showMessage: true),
        onAddToCart: _addToCart,
        onRemoveFromCart: _removeFromCart,
        initialCategory: _selectedCategoryForNavigation,
      ),
    ];
  }

  Future<void> _toggleFavorite(Product product,
      {bool showMessage = true}) async {
    if (!mounted) return;

    try {
      final dataService = FirebaseDataService();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (showMessage && mounted) {
          ErrorHandler.showError(
              context, 'Favori eklemek için giriş yapmalısınız');
        }
        return;
      }

      final existingIndex =
          favoriteProducts.indexWhere((p) => p.id == product.id);
      if (existingIndex != -1) {
        // Favorilerden çıkar
        favoriteProducts.removeAt(existingIndex);
        // Firebase'den de kaldır
        try {
          await dataService.removeFromFavorites(product.id);
        } catch (e) {
          // Hata durumunda sessizce devam et
        }

        if (mounted) {
          setState(() {});
          if (showMessage) {
            ErrorHandler.showSilentInfo(
                context, '${product.name} favorilerden çıkarıldı');
          }
        }
      } else {
        // Favorilere ekle
        favoriteProducts.add(product);
        // Firebase'e de ekle
        try {
          await dataService.addToFavorites(product.id);
        } catch (e) {
          // Hata durumunda sessizce devam et
        }

        if (mounted) {
          setState(() {});
          if (showMessage) {
            ErrorHandler.showSilentSuccess(
                context, '${product.name} favorilere eklendi');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(
            context, 'Favori işlemi sırasında hata oluştu: $e');
      }
    }
  }

  /// Profesyonel sepete ekleme metodu
  /// - Loading state yönetimi
  /// - Optimistic updates (hemen UI güncellemesi)
  /// - Gelişmiş hata yönetimi
  /// - Retry mekanizması
  Future<void> _addToCart(Product product,
      {bool showMessage = true, int retryCount = 0}) async {
    if (!mounted) return;

    // Zaten ekleniyorsa tekrar ekleme
    if (_addingToCartProducts.contains(product.id)) {
      return;
    }

    try {
      final dataService = FirebaseDataService();
      final user = FirebaseAuth.instance.currentUser;

      // Kullanıcı kontrolü
      if (user == null) {
        if (showMessage && mounted) {
          ErrorHandler.showError(
            context,
            'Sepete eklemek için giriş yapmalısınız',
          );
        }
        return;
      }

      // Loading state başlat
      setState(() {
        _addingToCartProducts.add(product.id);
      });

      final existingIndex = cartProducts.indexWhere((p) => p.id == product.id);
      final requestedQuantity =
          existingIndex != -1 ? cartProducts[existingIndex].quantity + 1 : 1;

      // Stok kontrolü
      if (requestedQuantity > product.stock) {
        setState(() {
          _addingToCartProducts.remove(product.id);
        });
        if (mounted && showMessage) {
          ErrorHandler.showError(
            context,
            'Yeterli stok yok. Mevcut stok: ${product.stock}',
          );
        }
        return;
      }

      // Optimistic update - Hemen UI'ı güncelle
      Product? previousProduct;
      int? previousQuantity;

      if (existingIndex != -1) {
        previousProduct = cartProducts[existingIndex].copyWith();
        previousQuantity = cartProducts[existingIndex].quantity;
        cartProducts[existingIndex].quantity++;
      } else {
        final newProduct = product.copyWith(quantity: 1);
        cartProducts.add(newProduct);
      }

      // UI'ı hemen güncelle
      if (mounted) {
        setState(() {});
      }

      // Firebase işlemleri (arka planda)
      try {
        if (existingIndex != -1) {
          await dataService.updateCartQuantity(
              product.id, cartProducts[existingIndex].quantity);
        } else {
          await dataService.addToCart(product.id, 1);
        }

        // Başarılı - Loading state'i kaldır
        if (mounted) {
          setState(() {
            _addingToCartProducts.remove(product.id);
          });

          if (showMessage) {
            if (existingIndex != -1) {
              ErrorHandler.showSilentSuccess(
                context,
                '${product.name} miktarı artırıldı',
              );
            } else {
              ErrorHandler.showCartSuccess(
                context,
                '${product.name} sepete eklendi',
                onViewCart: () {
                  _selectedIndex = 2;
                  setState(() {});
                },
              );
            }
          }
        }
      } catch (e) {
        // Hata durumunda optimistic update'i geri al
        if (mounted) {
          if (existingIndex != -1 &&
              previousProduct != null &&
              previousQuantity != null) {
            cartProducts[existingIndex] = previousProduct;
            cartProducts[existingIndex].quantity = previousQuantity;
          } else {
            cartProducts.removeWhere((p) => p.id == product.id);
          }

          setState(() {
            _addingToCartProducts.remove(product.id);
          });

          // Retry mekanizması (max 2 deneme)
          if (retryCount < 2) {
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              await _addToCart(product,
                  showMessage: showMessage, retryCount: retryCount + 1);
            }
          } else {
            // Son deneme de başarısız oldu
            if (showMessage) {
              ErrorHandler.showError(
                context,
                'Sepete ekleme başarısız oldu. Lütfen tekrar deneyin.',
              );
            }
            // Hata durumunda sessizce devam et
            // Exception fırlat ki çağıran kod hata durumunu anlasın
            rethrow;
          }
        }
      }
    } catch (e) {
      // Beklenmeyen hata
      if (mounted) {
        setState(() {
          _addingToCartProducts.remove(product.id);
        });

        if (showMessage) {
          ErrorHandler.showError(
            context,
            'Sepet işlemi sırasında hata oluştu. Lütfen tekrar deneyin.',
          );
        }
        // Hata durumunda sessizce devam et
      }
    }
  }

  /// Ürün sepete ekleniyor mu kontrol et
  bool isAddingToCart(String productId) {
    return _addingToCartProducts.contains(productId);
  }

  void _removeFromCart(Product product) async {
    if (!mounted) return;

    try {
      final dataService = FirebaseDataService();
      final index = cartProducts.indexWhere((p) => p.id == product.id);

      if (index != -1) {
        cartProducts.removeAt(index);
        // Firebase'den de kaldır
        try {
          await dataService.removeFromCart(product.id);
        } catch (e) {
          // Hata durumunda sessizce devam et
        }

        if (mounted) {
          setState(() {});
          ErrorHandler.showSilentInfo(
              context, '${product.name} sepetten çıkarıldı');
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(
            context, 'Sepet işlemi sırasında hata oluştu: $e');
      }
    }
  }

  Future<void> _updateQuantity(Product product, int newQuantity) async {
    if (!mounted) return;

    try {
      final dataService = FirebaseDataService();
      final index = cartProducts.indexWhere((p) => p.id == product.id);

      if (index != -1) {
        if (newQuantity <= 0) {
          cartProducts.removeAt(index);
          // Firebase'den de kaldır
          try {
            await dataService.removeFromCart(product.id);
          } catch (e) {
            debugPrint('Error removing from cart in Firebase: $e');
          }

          if (mounted) {
            setState(() {});
            ErrorHandler.showSilentInfo(
                context, '${product.name} sepetten çıkarıldı');
          }
        } else {
          // Stok kontrolü yap (miktar artırma durumunda)
          if (newQuantity > product.quantity) {
            // Stok kontrolü - product.stock kullanılıyor
            if (newQuantity > product.stock) {
              if (mounted) {
                ErrorHandler.showError(
                    context, 'Yeterli stok yok. Mevcut stok: ${product.stock}');
              }
              return;
            }
          }

          // Yeni Product objesi oluştur
          cartProducts[index] = product.copyWith(quantity: newQuantity);
          // Firebase'de güncelle
          try {
            await dataService.updateCartQuantity(product.id, newQuantity);
          } catch (e) {
            // Hata durumunda sessizce devam et
          }

          if (mounted) {
            setState(() {});
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(
            context, 'Miktar güncelleme sırasında hata oluştu: $e');
      }
    }
  }

  Future<void> _placeOrder() async {
    if (!mounted || cartProducts.isEmpty) return;

    try {
      final dataService = FirebaseDataService();
      final order = Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        products: List.from(cartProducts),
        totalAmount: cartProducts.fold(
            0.0, (sum, product) => sum + (product.price * product.quantity)),
        orderDate: DateTime.now(),
        status: 'Beklemede',
        customerName: 'Müşteri',
        customerEmail: 'musteri@example.com',
        customerPhone: '555-0123',
        shippingAddress: 'Adres bilgisi',
      );

      orders.add(order);

      // Sepeti temizle (hem local hem Firebase)
      cartProducts.clear();
      try {
        await dataService.clearCart();
      } catch (e) {
        // Hata durumunda sessizce devam et
      }

      if (mounted) {
        setState(() {});
        ErrorHandler.showSilentSuccess(
            context, 'Sipariş başarıyla oluşturuldu!');
        AppRoutes.navigateToPayment(context, cartProducts);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(
            context, 'Sipariş oluşturma sırasında hata oluştu: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppDesignSystem.background,
      body: Stack(
        children: [
          Column(
            children: [
              // Trendyol tarzı header
              _buildTrendyolHeader(context),
              // Ana içerik
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children:
                      _getPages(), // Her seferinde yeniden oluştur (kategori değişiklikleri için)
                ),
              ),
            ],
          ),
          // AI Chat Widget (sağ alt köşe)
          const AIChatWidget(),
        ],
      ),
    );
  }

  // Trendyol tarzı header - Web ve Mobil için ayrı tasarımlar
  Widget _buildTrendyolHeader(BuildContext context) {
    // Web ve mobil için tamamen farklı AppBar tasarımları
    if (kIsWeb) {
      return _buildWebHeader(context);
    } else {
      return _buildMobileHeader(context);
    }
  }

  // Web için AppBar - Geniş, detaylı tasarım
  Widget _buildWebHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    final headerHeight = isDesktop ? 88.0 : 86.0;
    final logoHeight = isDesktop ? 64.0 : 56.0;
    final logoWidth = isDesktop ? 270.0 : 238.0;

    return Container(
      color: AppDesignSystem.surface,
      child: Column(
        children: [
          // Offline durumu banner'ı
          if (!_isOnline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppDesignSystem.primary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'İnternet bağlantınız yok. Bazı özellikler çalışmayabilir.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          // Ana header - Web için geniş tasarım
          Container(
            height: headerHeight,
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 80 : 40),
            decoration: BoxDecoration(
              color: AppDesignSystem.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Sol taraf - Logo (web için geniş)
                SizedBox(
                  width: logoWidth,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = 0;
                      });
                    },
                    child: Image.asset(
                      'assets/images/tunex_banner.png',
                      width: logoWidth,
                      height: logoHeight,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                // Arama çubuğu - Web için tam genişlikte
                Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 24),
                    child: Container(
                      height: isDesktop ? 50 : 48,
                      decoration: BoxDecoration(
                        color: AppDesignSystem.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppDesignSystem.borderLight,
                          width: 1,
                        ),
                      ),
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _headerSearchController,
                        builder: (context, value, child) {
                          return TextField(
                            controller: _headerSearchController,
                            onChanged: (value) {
                              final query = value.trim();
                              setState(() {
                                _headerSearchQuery =
                                    query.isEmpty ? null : query;
                                if (_selectedIndex != 0) {
                                  _selectedIndex = 0;
                                }
                              });
                            },
                            onSubmitted: (value) {
                              final query = value.trim();
                              setState(() {
                                _headerSearchQuery =
                                    query.isEmpty ? null : query;
                                _selectedIndex = 0;
                              });
                            },
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText:
                                  'Aradığınız ürün, kategori veya markayı yazınız',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppDesignSystem.textSecondary,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: AppDesignSystem.textSecondary,
                                size: 22,
                              ),
                              suffixIcon: value.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear,
                                          size: 18,
                                          color: AppDesignSystem.textSecondary),
                                      onPressed: () {
                                        setState(() {
                                          _headerSearchController.clear();
                                          _headerSearchQuery = null;
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: isDesktop ? 14 : 13,
                              ),
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppDesignSystem.textPrimary,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // Sağ taraf - İkonlar (web için label'ları göster)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeaderIcon(
                      icon: Icons.favorite_outline_rounded,
                      label: 'Favorilerim',
                      onTap: () {
                        setState(() {
                          _selectedIndex = 1;
                        });
                      },
                      showLabel: true,
                    ),
                    SizedBox(width: isDesktop ? 20 : 16),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildHeaderIcon(
                          icon: Icons.shopping_cart_outlined,
                          label: 'Sepetim',
                          onTap: () {
                            setState(() {
                              _selectedIndex = 2;
                            });
                          },
                          showLabel: true,
                        ),
                        if (cartProducts.isNotEmpty)
                          Positioned(
                            right: 6,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Center(
                                child: Text(
                                  cartProducts.length > 99
                                      ? '99+'
                                      : '${cartProducts.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(width: isDesktop ? 20 : 16),
                    _buildProfileIcon(
                      profileImageUrl: _profileImageUrl,
                      onTap: () {
                        setState(() {
                          _selectedIndex = 3;
                        });
                      },
                      showLabel: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Kategoriler bar - Web için
          Container(
            height: 48,
            color: AppDesignSystem.background,
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 80 : 40),
            child: Row(
              children: [
                _AllCategoriesButton(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedCategoryForNavigation = null;
                      _selectedIndex = 4;
                    });
                  },
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: StreamBuilder<List<ProductCategory>>(
                    stream: _adminService.getCategories(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ));
                      }

                      final categories = snapshot.data ?? [];
                      // Maksimum 8 kategori göster, rasgele sırala
                      final displayCategories = categories.take(8).toList()
                        ..shuffle();

                      if (displayCategories.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: displayCategories.map((category) {
                            return _buildCategoryLink(
                              category.name,
                              () => _navigateToCategory(category.name),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Mobil için AppBar - Kompakt, minimal tasarım
  Widget _buildMobileHeader(BuildContext context) {
    final headerHeight = 70.0;
    final logoHeight = 48.0;
    final logoWidth = 180.0;

    return Container(
      color: AppDesignSystem.surface,
      child: Column(
        children: [
          // Offline durumu banner'ı
          if (!_isOnline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: AppDesignSystem.primary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'İnternet bağlantınız yok.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          // Ana header - Mobil için kompakt tasarım
          Container(
            height: headerHeight,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppDesignSystem.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Sol taraf - Logo (mobil için küçük)
                SizedBox(
                  width: logoWidth,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = 0;
                      });
                    },
                    child: Image.asset(
                      'assets/images/tunex_banner.png',
                      width: logoWidth,
                      height: logoHeight,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                // Arama çubuğu - Mobil için kompakt
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppDesignSystem.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppDesignSystem.borderLight,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _headerSearchController,
                        onChanged: (value) {
                          final query = value.trim();
                          setState(() {
                            _headerSearchQuery = query.isEmpty ? null : query;
                            if (_selectedIndex != 0) {
                              _selectedIndex = 0;
                            }
                          });
                        },
                        onSubmitted: (value) {
                          final query = value.trim();
                          setState(() {
                            _headerSearchQuery = query.isEmpty ? null : query;
                            _selectedIndex = 0;
                          });
                        },
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Ara...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppDesignSystem.textSecondary,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppDesignSystem.textSecondary,
                            size: 18,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppDesignSystem.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                // Sağ taraf - İkonlar (mobil için sadece ikonlar, label yok)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeaderIcon(
                      icon: Icons.favorite_outline_rounded,
                      label: 'Favorilerim',
                      onTap: () {
                        setState(() {
                          _selectedIndex = 1;
                        });
                      },
                      showLabel: false,
                    ),
                    const SizedBox(width: 8),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildHeaderIcon(
                          icon: Icons.shopping_cart_outlined,
                          label: 'Sepetim',
                          onTap: () {
                            setState(() {
                              _selectedIndex = 2;
                            });
                          },
                          showLabel: false,
                        ),
                        if (cartProducts.isNotEmpty)
                          Positioned(
                            right: 0,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 14,
                                minHeight: 14,
                              ),
                              child: Center(
                                child: Text(
                                  cartProducts.length > 99
                                      ? '99+'
                                      : '${cartProducts.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    _buildProfileIcon(
                      profileImageUrl: _profileImageUrl,
                      onTap: () {
                        setState(() {
                          _selectedIndex = 3;
                        });
                      },
                      showLabel: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Kategoriler bar - Mobil için (scrollable)
          Container(
            height: 40,
            color: AppDesignSystem.background,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _AllCategoriesButton(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => KategorilerSayfasi(
                          favoriteProducts: favoriteProducts,
                          cartProducts: cartProducts,
                          onFavoriteToggle: _toggleFavorite,
                          onAddToCart: _addToCart,
                          onRemoveFromCart: _removeFromCart,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StreamBuilder<List<ProductCategory>>(
                    stream: _adminService.getCategories(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ));
                      }

                      final categories = snapshot.data ?? [];
                      // Maksimum 8 kategori göster, rasgele sırala
                      final displayCategories = categories.take(8).toList()
                        ..shuffle();

                      if (displayCategories.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: displayCategories.map((category) {
                            return _buildCategoryLink(
                              category.name,
                              () => _navigateToCategory(category.name),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool showLabel = true,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    final iconWidget = GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppDesignSystem.textPrimary,
            size: isMobile ? 22 : 24, // Mobilde ikon biraz daha küçük
          ),
          if (showLabel) ...[
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: isMobile ? 9 : 10, // Mobilde font daha küçük
                color: AppDesignSystem.textSecondary,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );

    // Mobilde tooltip ekle (label yoksa)
    if (!showLabel) {
      return Tooltip(
        message: label,
        child: iconWidget,
      );
    }

    return iconWidget;
  }

  /// Profil ikonu - Profil fotoğrafı varsa göster, yoksa ikon göster
  Widget _buildProfileIcon({
    String? profileImageUrl,
    required VoidCallback onTap,
    bool showLabel = true,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final iconSize = isMobile ? 22.0 : 24.0;

    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'K';
    final firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : 'K';

    Widget avatarWidget;

    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      // Profil fotoğrafı varsa göster
      avatarWidget = ClipOval(
        child: Image.network(
          profileImageUrl,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Hata durumunda harf göster
            return Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: AppDesignSystem.borderLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  firstLetter,
                  style: GoogleFonts.inter(
                    fontSize: iconSize * 0.5,
                    fontWeight: FontWeight.w600,
                    color: AppDesignSystem.textSecondary,
                  ),
                ),
              ),
            );
          },
        ),
      );
    } else {
      // Profil fotoğrafı yoksa ikon göster
      avatarWidget = Icon(
        Icons.person_outline_rounded,
        color: AppDesignSystem.textPrimary,
        size: iconSize,
      );
    }

    final profileWidget = GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppDesignSystem.borderLight,
                width: 1,
              ),
            ),
            child: avatarWidget,
          ),
          if (showLabel) ...[
            const SizedBox(height: 3),
            Text(
              'Hesabım',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 9 : 10,
                color: AppDesignSystem.textSecondary,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );

    // Mobilde tooltip ekle (label yoksa)
    if (!showLabel) {
      return Tooltip(
        message: 'Hesabım',
        child: profileWidget,
      );
    }

    return profileWidget;
  }

  /// Kategoriye yönlendirme
  void _navigateToCategory(String categoryName) {
    setState(() {
      _selectedCategoryForNavigation = categoryName;
      _selectedIndex = 4; // Kategoriler sayfasına git
    });
  }

  Widget _buildCategoryLink(String text, VoidCallback onTap,
      {bool isNew = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: _CategoryLinkWidget(
        text: text,
        onTap: onTap,
        isNew: isNew,
      ),
    );
  }
}

// Kategori link widget'ı - hover state için ayrı widget
class _CategoryLinkWidget extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final bool isNew;

  const _CategoryLinkWidget({
    required this.text,
    required this.onTap,
    this.isNew = false,
  });

  @override
  State<_CategoryLinkWidget> createState() => _CategoryLinkWidgetState();
}

class _CategoryLinkWidgetState extends State<_CategoryLinkWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppDesignSystem.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: _isHovered
                ? Border.all(
                    color: AppDesignSystem.primary.withOpacity(0.3), width: 1)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: _isHovered
                      ? AppDesignSystem.primary
                      : AppDesignSystem.textPrimary,
                  fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(widget.text),
              ),
              if (widget.isNew) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Yeni',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Tüm Kategoriler butonu - Profesyonel ve modern tasarım
class _AllCategoriesButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AllCategoriesButton({required this.onTap});

  @override
  State<_AllCategoriesButton> createState() => _AllCategoriesButtonState();
}

class _AllCategoriesButtonState extends State<_AllCategoriesButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: AppDesignSystem.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovered
                  ? AppDesignSystem.primary
                  : AppDesignSystem.borderLight,
              width: _isHovered ? 2 : 1.5,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppDesignSystem.primary.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.28),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppDesignSystem.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.grid_view_rounded,
                  color: AppDesignSystem.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Kategoriler',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _isHovered
                      ? AppDesignSystem.primary
                      : AppDesignSystem.textPrimary,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: _isHovered
                    ? AppDesignSystem.primary
                    : AppDesignSystem.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
