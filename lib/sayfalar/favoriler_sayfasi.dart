import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/product.dart';
import '../model/collection.dart';
import '../widgets/optimized_image.dart';
import '../widgets/error_handler.dart';
import '../utils/debounce.dart';
import '../utils/professional_animations.dart';
import '../services/collection_service.dart';
import '../services/product_service.dart';
import 'urun_detay_sayfasi.dart';
import 'koleksiyon_detay_sayfasi.dart';
import '../theme/app_design_system.dart';
import '../utils/responsive_helper.dart';

class FavorilerSayfasi extends StatefulWidget {
  final List<Product> favoriteProducts;
  final Function(Product, {bool showMessage}) onFavoriteToggle;
  final Function(Product, {bool showMessage})? onAddToCart;
  final List<Product>? cartProducts;
  final VoidCallback? onNavigateToMainPage;
  final bool Function(String)? isAddingToCart;

  const FavorilerSayfasi({
    super.key,
    required this.favoriteProducts,
    required this.onFavoriteToggle,
    this.onAddToCart,
    this.cartProducts,
    this.onNavigateToMainPage,
    this.isAddingToCart,
  });

  @override
  State<FavorilerSayfasi> createState() => _FavorilerSayfasiState();
}

class _FavorilerSayfasiState extends State<FavorilerSayfasi> with TickerProviderStateMixin {
  String _searchQuery = '';
  String _sortBy = 'name';
  late Debounce _searchDebounce;
  late TabController _tabController;
  String _collectionSearchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _selectedFilter = 'Tümü'; // Trendyol tarzı filtre
  
  final CollectionService _collectionService = CollectionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Collection> _collections = [];
  bool _isLoadingCollections = false;

  @override
  void initState() {
    super.initState();
    _searchDebounce = Debounce(delay: const Duration(milliseconds: 500));
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      setState(() {
        _searchQuery = '';
        _collectionSearchQuery = '';
        _searchController.clear();
      });
      if (_tabController.index == 1) {
        _loadCollections();
      }
    });
    _loadCollections();
    
    // Klavye performansı için TextField'ı önceden hazırla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // FocusNode'u önceden hazırla - klavye açılışını hızlandırır
        _searchFocusNode.canRequestFocus;
      }
    });
  }

  Future<void> _loadCollections() async {
    if (_auth.currentUser == null) {
      setState(() => _collections = []);
      return;
    }

    setState(() => _isLoadingCollections = true);
    try {
      final collections = await _collectionService.getUserCollections();
      setState(() {
        _collections = collections;
        _isLoadingCollections = false;
      });
    } catch (e) {
      setState(() => _isLoadingCollections = false);
      if (mounted) {
        ErrorHandler.showError(context, 'Koleksiyonlar yüklenirken hata oluştu: $e');
      }
    }
  }

  @override
  void didUpdateWidget(FavorilerSayfasi oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Favori ürünler değiştiğinde UI'ı güncelle
    if (widget.favoriteProducts.length != oldWidget.favoriteProducts.length ||
        widget.favoriteProducts != oldWidget.favoriteProducts) {
      setState(() {});
    }
  }


  @override
  void dispose() {
    _searchDebounce.dispose();
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  List<Product> get _filteredProducts {
    var products = widget.favoriteProducts;
    
    // Trendyol tarzı filtre
    switch (_selectedFilter) {
      case 'Kuponlu Ürünler':
        products = products.where((p) => p.discountPercentage > 0).toList();
        break;
      case 'Fiyatı Düşenler':
        // Demo: İndirimli ürünler
        products = products.where((p) => p.discountPercentage > 0).toList();
        products.sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
        break;
      case 'Avantajlı Ürünler':
        // Demo: Yüksek indirimli ürünler
        products = products.where((p) => p.discountPercentage >= 20).toList();
        break;
      case 'Tümü':
      default:
        // Tüm ürünler
        break;
    }
    
    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      products = products.where((product) =>
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Sıralama
    switch (_sortBy) {
      case 'name':
        products.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'price_asc':
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'date':
        // Tarih sıralaması için demo
        products = products.reversed.toList();
        break;
    }
    
    return products;
  }

  List<Collection> get _filteredCollections {
    var filtered = _collections;
    
    if (_collectionSearchQuery.isNotEmpty) {
      filtered = _collections.where((collection) =>
          collection.name.toLowerCase().contains(_collectionSearchQuery.toLowerCase()) ||
          collection.description.toLowerCase().contains(_collectionSearchQuery.toLowerCase())
      ).toList();
    }
    
    return filtered;
  }

  Color _getCollectionColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }

  IconData _getCollectionIcon(int index) {
    final icons = [
      Icons.collections,
      Icons.favorite,
      Icons.star,
      Icons.bookmark,
      Icons.inventory_2,
      Icons.category,
      Icons.shopping_bag,
      Icons.local_offer,
    ];
    return icons[index % icons.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.background,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: AppDesignSystem.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: AppDesignSystem.borderLight,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Sol tarafta küçük tab'lar - Fotoğraftaki gibi (küçültülmüş ve sola sabitlenmiş)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Favorilerim tab
                  GestureDetector(
                    onTap: () {
                      _tabController.animateTo(0);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _tabController.index == 0 
                                ? AppDesignSystem.primary
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite,
                            color: _tabController.index == 0 
                                ? AppDesignSystem.primary
                                : AppDesignSystem.textTertiary,
                            size: 16,
                          ),
                          const SizedBox(width: AppDesignSystem.spacingXS),
                          Text(
                            'Favorilerim',
                            style: AppDesignSystem.labelMedium.copyWith(
                              color: _tabController.index == 0 
                                  ? AppDesignSystem.primary
                                  : AppDesignSystem.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Koleksiyonlarım tab
                  GestureDetector(
                    onTap: () {
                      _tabController.animateTo(1);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _tabController.index == 1 
                                ? const Color(0xFFFF6A00) 
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.collections,
                            color: _tabController.index == 1 
                                ? const Color(0xFFFF6A00) 
                                : const Color(0xFF8E98A8),
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Koleksiyonlarım',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _tabController.index == 1 
                                  ? const Color(0xFFFF6A00) 
                                  : const Color(0xFF8E98A8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: ResponsiveHelper.responsiveSpacing(context, mobile: 8.0, desktop: 16.0)),
              // Sağ tarafta arama çubuğu - Fotoğraftaki gibi
              Expanded(
                flex: 2,
                child: Container(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (value) {
                      _searchDebounce(() {
                        setState(() {
                          if (_tabController.index == 0) {
                            _searchQuery = value;
                          } else {
                            _collectionSearchQuery = value;
                          }
                        });
                      });
                    },
                    textInputAction: TextInputAction.search,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF0F0F0F),
                    ),
                    decoration: InputDecoration(
                      hintText: _tabController.index == 0 
                          ? 'Favorilerimde Ara' 
                          : 'Koleksiyonlarımda Ara',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF8E98A8),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFFC7CDD6),
                        size: 20,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0B0D10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: const Color(0xFF2A3340),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: const Color(0xFF2A3340),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: const Color(0xFFFF6A00),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      suffixIcon: (_tabController.index == 0 && _searchQuery.isNotEmpty) ||
                                  (_tabController.index == 1 && _collectionSearchQuery.isNotEmpty)
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                if (_tabController.index == 0) {
                                  _performSearch('');
                                } else {
                                  setState(() {
                                    _collectionSearchQuery = '';
                                  });
                                }
                              },
                              icon: const Icon(Icons.clear, color: Color(0xFFC7CDD6), size: 18),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: TabBarView(
            controller: _tabController,
            children: [
              // Favorilerim sekmesi
              _buildFavoritesTab(),
              // Koleksiyonlarım sekmesi
              _buildCollectionsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1200;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Trendyol tarzı filtre butonları
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 80 : 24,
              vertical: 12,
            ),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterButton('Tümü', const Color(0xFFFF6A00)),
                  const SizedBox(width: 8),
                  _buildFilterButton('Kuponlu Ürünler', const Color(0xFFEC4899)),
                  const SizedBox(width: 8),
                  _buildFilterButton('Fiyatı Düşenler', const Color(0xFFEF4444)),
                  const SizedBox(width: 8),
                  _buildFilterButton('Avantajlı Ürünler', const Color(0xFF00D1FF)),
                ],
              ),
            ),
          ),
          
          // Ürün listesi - Grid yapısı (kaydırılabilir değil)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 80 : isTablet ? 40 : 24,
              vertical: 16,
            ),
            child: _filteredProducts.isEmpty
                ? Container(
                    height: 400,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Arama kriterlerinize uygun ürün bulunamadı'
                                : 'Henüz favori ürününüz yok',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : _buildProductsGrid(),
          ),
        ],
      ),
    );
  }

  // Ürünler grid yapısı
  Widget _buildProductsGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final crossAxisCount = isDesktop ? 4 : isTablet ? 3 : 2;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.65, // Daha düşük oran - overflow'u önlemek için
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildProductCard(product, false, isTablet);
      },
    );
  }

  // Trendyol tarzı ürün kartı
  Widget _buildProductCard(Product product, bool isSmallScreen, bool isTablet) {
    final isFavorite = widget.favoriteProducts.any((p) => p.id == product.id);
    final favoriteCount = (product.salesCount * 0.1).round(); // Demo favori sayısı

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          ProfessionalAnimations.createScaleRoute(
            UrunDetaySayfasi(
              product: product,
              favoriteProducts: widget.favoriteProducts,
              onFavoriteToggle: (p) => widget.onFavoriteToggle(p, showMessage: true),
              onAddToCart: (p) => widget.onAddToCart?.call(p, showMessage: true) ?? (_) {},
              onRemoveFromCart: (p) {},
              cartProducts: widget.cartProducts ?? [],
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF2A3340),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ürün resmi - Trendyol tarzı
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0D10),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: OptimizedImage(
                        imageUrl: product.imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  // Badge'ler - Görüntüdeki gibi
                  if (product.discountPercentage > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18C964),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'AVANTAJLI ÜRÜN',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  // Ekstra badge (görüntüde pembe badge var)
                  if (product.salesCount > 100)
                    Positioned(
                      top: 8,
                      left: product.discountPercentage > 0 ? 110 : 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEC4899),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Doğru seçim için BEDEN TABLOSUNA BAKIN',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 8,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  // Favori butonu
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        widget.onFavoriteToggle(product);
                        setState(() {}); // State'i güncelle
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? const Color(0xFFEF4444) : const Color(0xFFC7CDD6),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  // Taksit badge
                  if (product.discountPercentage > 0)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D1FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'PEŞİN FİYATINA 3 TAKSİT FIRSATI',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 9,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Ürün bilgileri - Overflow koruması ile
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ürün adı - Sabit yükseklik
                    SizedBox(
                      height: 36,
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0F0F0F),
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Favori sayısı ve Rating - Tek satır
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          size: 12,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            favoriteCount > 1000 
                                ? '${(favoriteCount / 1000).toStringAsFixed(1)}k'
                                : '$favoriteCount',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xFFC7CDD6),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.averageRating > 0) ...[
                          Icon(
                            Icons.star,
                            size: 12,
                            color: const Color(0xFFFF6A00),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            product.averageRating.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xFFC7CDD6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Fiyat
                    Text(
                      '${product.price.toStringAsFixed(2)} ₺',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F0F0F),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionsTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header - Sadece başlık (buton kaldırıldı)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 80 : 24,
              vertical: 16,
            ),
            color: Colors.white,
            child: Row(
              children: [
                Text(
                  'Koleksiyonlarım',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${_collections.length})',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          
          // Koleksiyonlar grid
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 80 : isTablet ? 40 : 24,
              vertical: 16,
            ),
            child: _buildCollectionsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionsGrid() {
    final collections = _filteredCollections;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final crossAxisCount = isDesktop ? 4 : isTablet ? 3 : 2;

    if (_isLoadingCollections) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_auth.currentUser == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.collections_bookmark_outlined, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Koleksiyonları görmek için giriş yapın',
                style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (collections.isEmpty && _collectionSearchQuery.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDesignSystem.spacingL),
                decoration: BoxDecoration(
                  color: AppDesignSystem.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.collections_bookmark_outlined,
                  size: 64,
                  color: AppDesignSystem.textTertiary,
                ),
              ),
              const SizedBox(height: AppDesignSystem.spacingM),
              Text(
                'Henüz koleksiyonunuz yok',
                style: AppDesignSystem.heading4,
              ),
              const SizedBox(height: AppDesignSystem.spacingS),
              Text(
                'Yeni koleksiyon oluşturarak başlayın',
                style: AppDesignSystem.bodyMedium.copyWith(
                  color: AppDesignSystem.textSecondary,
                ),
              ),
              const SizedBox(height: AppDesignSystem.spacingL),
              ElevatedButton.icon(
                onPressed: _createNewCollection,
                icon: const Icon(Icons.add, size: 20),
                label: Text(
                  'Koleksiyon Oluştur',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6A00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (collections.isEmpty && _collectionSearchQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 60,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Arama kriterlerinize uygun koleksiyon bulunamadı',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Farklı anahtar kelimeler deneyin',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: collections.length,
      itemBuilder: (context, index) {
        final collection = collections[index];
        final color = _getCollectionColor(index);
        final icon = _getCollectionIcon(index);
        final productCount = collection.productIds.length;

        return _buildCollectionCard(collection, color, icon, productCount);
      },
    );
  }

  Widget _buildCollectionCard(Collection collection, Color color, IconData icon, int productCount) {
    // İlk birkaç ürünün görsellerini al (performans için)
    final productIds = collection.productIds.take(6).toList();
    final viewCount = (productCount * 1.6).round(); // Demo görüntülenme sayısı
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => KoleksiyonDetaySayfasi(collection: collection),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst kısım - Başlık ve butonlar
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      collection.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Paylaş butonu
                  IconButton(
                    icon: const Icon(Icons.share, size: 18, color: Colors.grey),
                    onPressed: () {
                      // Paylaş işlemi
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  // Menü butonu
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (value) {
                      if (value == 'delete') {
                        // Silme işlemi
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Sil'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Ürün sayısı ve görüntülenme
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(
                    '$productCount Ürün',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.remove_red_eye, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '$viewCount',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Yatay scrollable ürün görselleri
            if (productIds.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: productIds.length,
                  itemBuilder: (context, index) {
                    return FutureBuilder<String?>(
                      future: _getProductImageUrl(productIds[index]),
                      builder: (context, snapshot) {
                        return Container(
                          width: 80,
                          height: 80,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty
                                ? OptimizedImage(
                                    imageUrl: snapshot.data!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    borderRadius: BorderRadius.circular(3),
                                    errorWidget: Container(
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey[400],
                                        size: 16,
                                      ),
                                    ),
                                    placeholder: Container(
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.image,
                                        color: Colors.grey[400],
                                        size: 16,
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: Icon(Icons.image, color: Colors.grey[400], size: 16),
                                  ),
                          ),
                        );
                      },
                    );
                  },
                ),
              )
            else
              Container(
                height: 80,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    'Henüz ürün yok',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<String?> _getProductImageUrl(String productId) async {
    try {
      final productService = ProductService();
      final product = await productService.getProductById(productId);
      return product?.imageUrl;
    } catch (e) {
      return null;
    }
  }


  void _createNewCollection() {
    final nameController = TextEditingController();
    
    // Önerilen koleksiyon adları - Araç temalı
    final suggestedNames = [
      {'name': 'Motor Parçaları', 'emoji': '🔧'},
      {'name': 'Egzoz Sistemleri', 'emoji': '💨'},
      {'name': 'Jant & Lastik', 'emoji': '⚙️'},
      {'name': 'Body Kit', 'emoji': '🚗'},
      {'name': 'Elektronik & ECU', 'emoji': '📱'},
      {'name': 'Fren Sistemleri', 'emoji': '🛑'},
    ];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width > 600 ? 420 : double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header - İkon ve başlık
              Stack(
                children: [
                  // İkon - üstte ortada (küçültülmüş)
                  Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6A00).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bookmark,
                        color: Color(0xFFFF6A00),
                        size: 24,
                      ),
                    ),
                  ),
                  // Kapatma butonu - sağ üst
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Başlık (küçültülmüş)
              Text(
                'Koleksiyon Adı Oluştur',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // Koleksiyon Adı Input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Koleksiyon Adı*',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Koleksiyon Adı Girin',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFFF6A00), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              
              // Önerilen Koleksiyon Adları
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Önerilen Koleksiyon Adları',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: suggestedNames.map((suggestion) {
                      return InkWell(
                        onTap: () {
                          nameController.text = suggestion['name'] as String;
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                suggestion['emoji'] as String,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                suggestion['name'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              
              // Değişiklikleri Kaydet Butonu (daha küçük)
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ErrorHandler.showError(context, 'Koleksiyon adı boş olamaz');
                      return;
                    }

                    Navigator.pop(context);

                    try {
                      final user = _auth.currentUser;
                      if (user == null) {
                        ErrorHandler.showError(context, 'Koleksiyon oluşturmak için giriş yapmalısınız');
                        return;
                      }

                      final collection = Collection(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: name,
                        description: '',
                        userId: user.uid,
                        productIds: [],
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );

                      await _collectionService.createCollection(collection);
                      await _loadCollections();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"$name" koleksiyonu oluşturuldu!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ErrorHandler.showError(context, 'Koleksiyon oluşturulurken hata oluştu: $e');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6A00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: Text(
                    'Değişiklikleri Kaydet',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }




  // Trendyol tarzı filtre butonu - İkinci fotoğraftaki gibi ikonlu ve renkli
  Widget _buildFilterButton(String label, Color color) {
    final isSelected = _selectedFilter == label;
    
    // İkon ve renkler
    IconData icon;
    Color iconColor;
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    
    if (label == 'Tümü') {
      icon = Icons.favorite;
      iconColor = const Color(0xFFFF6A00);
      backgroundColor = isSelected 
          ? const Color(0xFFFFF4E6) // Açık turuncu
          : const Color(0xFFFFF4E6);
      borderColor = isSelected 
          ? const Color(0xFFFF6A00) // Turuncu border
          : const Color(0xFFFF6A00);
      textColor = const Color(0xFFFF6A00);
    } else if (label == 'Kuponlu Ürünler') {
      icon = Icons.local_offer;
      iconColor = const Color(0xFFEC4899);
      backgroundColor = isSelected 
          ? const Color(0xFFFDF2F8).withOpacity(0.8) // Seçiliyse biraz daha koyu
          : const Color(0xFFFDF2F8); // Açık pembe
      borderColor = isSelected 
          ? const Color(0xFFEC4899) // Seçiliyse pembe border
          : Colors.transparent;
      textColor = isSelected 
          ? const Color(0xFFEC4899) // Seçiliyse pembe text
          : const Color(0xFF0F0F0F);
    } else if (label == 'Fiyatı Düşenler') {
      icon = Icons.trending_down;
      iconColor = const Color(0xFFEF4444);
      backgroundColor = isSelected 
          ? const Color(0xFFFEF2F2).withOpacity(0.8) // Seçiliyse biraz daha koyu
          : const Color(0xFFFEF2F2); // Açık kırmızı
      borderColor = isSelected 
          ? const Color(0xFFEF4444) // Seçiliyse kırmızı border
          : Colors.transparent;
      textColor = isSelected 
          ? const Color(0xFFEF4444) // Seçiliyse kırmızı text
          : const Color(0xFF0F0F0F);
    } else if (label == 'Avantajlı Ürünler') {
      icon = Icons.star;
      iconColor = const Color(0xFF00D1FF);
      backgroundColor = isSelected 
          ? const Color(0xFFEFF6FF).withOpacity(0.8) // Seçiliyse biraz daha koyu
          : const Color(0xFFEFF6FF); // Açık mavi
      borderColor = isSelected 
          ? const Color(0xFF00D1FF) // Seçiliyse mavi border
          : Colors.transparent;
      textColor = isSelected 
          ? const Color(0xFF00D1FF) // Seçiliyse mavi text
          : const Color(0xFF0F0F0F);
    } else {
      icon = Icons.filter_list;
      iconColor = const Color(0xFFC7CDD6);
      backgroundColor = Colors.white;
      borderColor = const Color(0xFF2A3340);
      textColor = const Color(0xFF0F0F0F);
    }
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact(); // Haptic feedback ekle
        setState(() {
          _selectedFilter = label;
        });
      },
      behavior: HitTestBehavior.opaque, // Tıklama alanını genişlet
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.5 : 0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

}