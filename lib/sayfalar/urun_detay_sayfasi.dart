import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/product.dart';
import '../model/product_review.dart';
import '../services/review_service.dart';
import '../widgets/optimized_image.dart';
import '../widgets/star_rating.dart';
import '../widgets/review_form.dart';
import '../widgets/review_list.dart';
import '../theme/app_design_system.dart';
import '../config/app_routes.dart';

class UrunDetaySayfasi extends StatefulWidget {
  final Product product;
  final Future<void> Function(Product) onFavoriteToggle;
  final Future<void> Function(Product) onAddToCart;
  final Function(Product) onRemoveFromCart;
  final List<Product> favoriteProducts;
  final List<Product> cartProducts;
  final bool forceHasPurchased;

  const UrunDetaySayfasi({
    super.key,
    required this.product,
    required this.onFavoriteToggle,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.favoriteProducts,
    required this.cartProducts,
    this.forceHasPurchased = false,
  });

  @override
  State<UrunDetaySayfasi> createState() => _UrunDetaySayfasiState();
}

class _UrunDetaySayfasiState extends State<UrunDetaySayfasi> {
  List<ProductReview> _reviews = [];
  double _averageRating = 0.0;
  int _totalReviews = 0;
  bool _isLoading = true;
  bool _reviewsLoaded = false;
  bool _isRefreshingReviews = false;
  // _userReview kaldırıldı - kullanıcılar istediği kadar yorum yapabilir
  bool _hasPurchased = false;
  bool _isCheckingPurchase = true;
  ScaffoldMessengerState? _scaffoldMessenger;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _reviewsSectionKey = GlobalKey();
  String _reviewSortOption = 'Önerilen Sıralama';

  // Renk ve beden seçimi
  String? _selectedColor;
  String? _selectedSize;
  int _selectedImageIndex = 0;

  // Ürünün renk ve beden listelerini al
  List<String> get _availableColors => widget.product.colors ?? [];
  List<String> get _availableSizes => widget.product.sizes ?? [];

  // Görsel listesi (gerçek uygulamada ürünün birden fazla görseli olabilir)
  List<String> get _productImages {
    final imageUrl = widget.product.imageUrl.trim();
    // Eğer görsel URL'i boş veya geçersizse, boş liste döndür
    if (imageUrl.isEmpty ||
        (!imageUrl.startsWith('http://') &&
            !imageUrl.startsWith('https://') &&
            !imageUrl.startsWith('assets/'))) {
      return [];
    }
    return [
      imageUrl,
      // Gerçek uygulamada birden fazla görsel olabilir
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadReviews();

    // İlk renk ve bedeni seç (varsa)
    if (_availableColors.isNotEmpty) {
      _selectedColor = _availableColors.first;
    }
    if (_availableSizes.isNotEmpty) {
      _selectedSize = _availableSizes.first;
    }

    if (widget.forceHasPurchased) {
      _hasPurchased = true;
      _isCheckingPurchase = false;
    } else {
      _checkPurchaseStatus();
    }
  }

  @override
  void didUpdateWidget(UrunDetaySayfasi oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sepet veya favori ürünler değiştiğinde state'i güncelle
    final cartChanged = widget.cartProducts.length !=
            oldWidget.cartProducts.length ||
        widget.cartProducts
            .any((p) => !oldWidget.cartProducts.any((op) => op.id == p.id)) ||
        oldWidget.cartProducts
            .any((op) => !widget.cartProducts.any((p) => p.id == op.id));

    final favoriteChanged = widget.favoriteProducts.length !=
            oldWidget.favoriteProducts.length ||
        widget.favoriteProducts.any(
            (p) => !oldWidget.favoriteProducts.any((op) => op.id == p.id)) ||
        oldWidget.favoriteProducts
            .any((op) => !widget.favoriteProducts.any((p) => p.id == op.id));

    if (cartChanged || favoriteChanged) {
      setState(() {});
    }
  }

  Future<void> _checkPurchaseStatus() async {
    if (!mounted) return;
    setState(() => _isCheckingPurchase = true);
    try {
      final hasPurchased = await _checkIfUserPurchased();
      if (mounted) {
        setState(() {
          _hasPurchased = hasPurchased;
          _isCheckingPurchase = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasPurchased = false;
          _isCheckingPurchase = false;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToReviews() {
    final context = _reviewsSectionKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showSnackBar(SnackBar snackBar) {
    if (mounted && _scaffoldMessenger != null) {
      try {
        _scaffoldMessenger!.showSnackBar(snackBar);
      } catch (e) {
        debugPrint('Error showing snackbar: $e');
      }
    }
  }

  Future<void> _loadReviews() async {
    if (!mounted || _isRefreshingReviews) return;

    try {
      _isRefreshingReviews = true;
      if (mounted) setState(() => _isLoading = true);

      final reviews = await ReviewService.getProductReviews(widget.product.id);
      if (!mounted) return;

      if (!mounted) return;
      final calculatedAverageRating =
          ProductReview.calculateAverageRating(reviews);

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _averageRating = calculatedAverageRating;
          _totalReviews = reviews.length;
          _isLoading = false;
          _reviewsLoaded = true;
          _isRefreshingReviews = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading reviews: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshingReviews = false;
        });
        _showSnackBar(
            SnackBar(content: Text('Yorumlar yüklenirken hata oluştu: $e')));
      }
    }
  }

  Future<void> _onReviewAdded() async {
    if (!mounted || _isRefreshingReviews) return;
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted || _isRefreshingReviews) return;

    try {
      await _loadReviews();
    } catch (e) {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted && !_isRefreshingReviews) {
        await _loadReviews();
      }
    }

    // _userReview güncellemesi kaldırıldı - kullanıcılar istediği kadar yorum yapabilir
  }

  Future<bool> _checkIfUserPurchased() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      return await ReviewService.hasUserPurchasedProduct(
          widget.product.id, user.uid);
    } catch (e) {
      debugPrint('Purchase check error: $e');
      return false;
    }
  }

  Future<void> _shareProduct() async {
    try {
      final productId = widget.product.id;
      final httpLink = 'https://tuning-app-789e.web.app/product/$productId';
      final shareText = httpLink;

      try {
        await Share.share(shareText, subject: widget.product.name);
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Paylaşma hatası: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ));
        rethrow;
      }
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  // Breadcrumb navigasyon
  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              // Ana sayfaya yönlendir
              AppRoutes.navigateToMain(context);
            },
            child: Text(
              'Anasayfa',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFFC7CDD6),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '>',
            style:
                GoogleFonts.inter(fontSize: 12, color: const Color(0xFFC7CDD6)),
          ),
          const SizedBox(width: 4),
          Text(
            widget.product.category,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFFC7CDD6),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '>',
            style:
                GoogleFonts.inter(fontSize: 12, color: const Color(0xFFC7CDD6)),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              widget.product.name,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF0F0F0F),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Sol tarafta ürün görseli
  Widget _buildProductImage() {
    return Container(
      width: double.infinity,
      height: 600,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Ana görsel
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _productImages.isNotEmpty &&
                      _selectedImageIndex < _productImages.length
                  ? OptimizedImage(
                      imageUrl: _productImages[_selectedImageIndex],
                      fit: BoxFit.contain,
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),
          ),
          // Sol ok
          if (_selectedImageIndex > 0)
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedImageIndex--),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.chevron_left,
                        color: Color(0xFF0F0F0F)),
                  ),
                ),
              ),
            ),
          // Sağ ok
          if (_selectedImageIndex < _productImages.length - 1)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedImageIndex++),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.chevron_right,
                        color: Color(0xFF0F0F0F)),
                  ),
                ),
              ),
            ),
          // KARGO BEDAVA etiketi
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'KARGO BEDAVA',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // PEŞİN FİYATINA 3 TAKSİT FIRSATI rozeti
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0066CC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.credit_card, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'PEŞİN FİYATINA 3 TAKSİT FIRSATI',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Beğenme butonu (sağ üst köşe)
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () async {
                await widget.onFavoriteToggle(widget.product);
                if (mounted) {
                  setState(() {}); // State'i güncelle
                }
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  widget.favoriteProducts
                          .any((p) => p.name == widget.product.name)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: widget.favoriteProducts
                          .any((p) => p.name == widget.product.name)
                      ? Colors.red
                      : const Color(0xFF0F0F0F),
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sağ tarafta ürün bilgileri
  Widget _buildProductInfo() {
    final isFavorite =
        widget.favoriteProducts.any((p) => p.id == widget.product.id);
    final inCart = widget.cartProducts.any((p) => p.id == widget.product.id);
    final originalPrice = widget.product.price * 1.11; // %11 indirim varsayımı
    final discountedPrice = widget.product.price;
    final installmentAmount = discountedPrice / 3;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ürün adı
          Text(
            widget.product.name,
            style: AppDesignSystem.heading2.copyWith(height: 1.3),
          ),
          const SizedBox(height: AppDesignSystem.spacingM),

          // Değerlendirme (tıklanabilir)
          GestureDetector(
            onTap: _scrollToReviews,
            child: Row(
              children: [
                StarRating(
                  rating: _reviewsLoaded
                      ? _averageRating
                      : widget.product.averageRating,
                  size: 18,
                ),
                const SizedBox(width: AppDesignSystem.spacingS),
                Text(
                  _reviewsLoaded
                      ? '${_averageRating.toStringAsFixed(1)}'
                      : '${widget.product.averageRating.toStringAsFixed(1)}',
                  style: AppDesignSystem.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppDesignSystem.spacingXS),
                Text(
                  _reviewsLoaded
                      ? '(${_totalReviews} Değerlendirme)'
                      : '(${widget.product.reviewCount} Değerlendirme)',
                  style: AppDesignSystem.bodyMedium.copyWith(
                    color: AppDesignSystem.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Popülerlik bilgisi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up,
                    size: 16, color: const Color(0xFFFF6A00)),
                const SizedBox(width: 8),
                Text(
                  'Popüler ürün! Son 24 saatte ${804 + widget.product.salesCount} kişi görüntüledi!',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFFFF6A00),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Fiyat bilgisi
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Özel Fiyat',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF6A00),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sepette ${discountedPrice.toStringAsFixed(2)} TL',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFF1493),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${originalPrice.toStringAsFixed(2)} TL',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: const Color(0xFFC7CDD6),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '%${((originalPrice - discountedPrice) / originalPrice * 100).toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Peşin Fiyatına 3 Taksit • 3x ${installmentAmount.toStringAsFixed(0)} TL',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFFC7CDD6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Renk seçenekleri (sadece admin panelinden eklenmişse göster)
          if (_availableColors.isNotEmpty) ...[
            Text(
              'Renk: ${_selectedColor ?? ""}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F0F0F),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: _availableColors.map((color) {
                final isSelected = color == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getColorValue(color),
                      borderRadius:
                          BorderRadius.circular(AppDesignSystem.radiusS),
                      border: Border.all(
                        color: isSelected
                            ? AppDesignSystem.primary
                            : AppDesignSystem.borderLight,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: isSelected
                        ? const Center(
                            child: Icon(Icons.check,
                                color: Colors.white, size: 24),
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Beden seçenekleri (sadece admin panelinden eklenmişse göster)
          if (_availableSizes.isNotEmpty) ...[
            Text(
              'Beden: ${_selectedSize ?? ""}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F0F0F),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: _availableSizes.map((size) {
                final isSelected = size == _selectedSize;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSize = size),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppDesignSystem.primary
                          : AppDesignSystem.surface,
                      borderRadius:
                          BorderRadius.circular(AppDesignSystem.radiusS),
                      border: Border.all(
                        color: isSelected
                            ? AppDesignSystem.primary
                            : AppDesignSystem.borderLight,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      size,
                      style: AppDesignSystem.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppDesignSystem.textOnPrimary
                            : AppDesignSystem.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              'Kullanıcıların çoğu kendi bedeninizi almanızı öneriyor.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFFC7CDD6),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Butonlar
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    // Şimdi Al - önce sepete ekle, sonra ödeme sayfasına git
                    widget.onAddToCart(widget.product);

                    // Kısa bir gecikme sonrası ödeme sayfasına yönlendir
                    await Future.delayed(const Duration(milliseconds: 300));

                    if (mounted) {
                      // Sepetteki ürünleri al (yeni eklenen ürün dahil)
                      final updatedCartProducts =
                          List<Product>.from(widget.cartProducts);
                      if (!updatedCartProducts
                          .any((p) => p.id == widget.product.id)) {
                        updatedCartProducts.add(widget.product);
                      }

                      AppRoutes.navigateToPayment(
                        context,
                        updatedCartProducts,
                      );
                    }
                  },
                  style: AppDesignSystem.secondaryButtonStyle(
                    padding: AppDesignSystem.spacingM,
                    borderRadius: AppDesignSystem.radiusS,
                  ),
                  child: Text(
                    'Şimdi Al',
                    style: AppDesignSystem.buttonMedium.copyWith(
                      color: AppDesignSystem.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDesignSystem.spacingM),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (inCart) {
                      // Ürün zaten sepette, sepetten çıkar
                      widget.onRemoveFromCart(widget.product);
                      setState(() {});
                    } else {
                      // Sepete ekle - _addToCart kendi mesajını gösterir
                      await widget.onAddToCart(widget.product);

                      // State'i güncelle
                      if (mounted) {
                        setState(() {});
                      }

                      // Kısa bir gecikme sonrası tekrar state güncelle (parent widget'tan gelen güncellemeler için)
                      await Future.delayed(const Duration(milliseconds: 300));
                      if (mounted) {
                        setState(() {});
                      }
                    }
                  },
                  style: AppDesignSystem.primaryButtonStyle(
                    padding: AppDesignSystem.spacingM,
                    borderRadius: AppDesignSystem.radiusS,
                  ).copyWith(
                    backgroundColor: MaterialStateProperty.all(
                      inCart ? Colors.green : AppDesignSystem.primary,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (inCart) ...[
                        const Icon(Icons.check, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        inCart ? 'Sepette' : 'Sepete Ekle',
                        style: AppDesignSystem.buttonMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Favori butonu (sağ alt)
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () async {
                await widget.onFavoriteToggle(widget.product);
                if (mounted) {
                  setState(() {});
                }
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppDesignSystem.surface,
                  shape: BoxShape.circle,
                  boxShadow: AppDesignSystem.shadowM,
                ),
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite
                      ? AppDesignSystem.favorite
                      : AppDesignSystem.textSecondary,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorValue(String colorName) {
    switch (colorName) {
      case 'Kahverengi':
        return const Color(0xFF8B4513);
      case 'Siyah':
        return const Color(0xFF000000);
      case 'Lacivert':
        return const Color(0xFF000080);
      case 'Bej':
        return const Color(0xFFF5F5DC);
      case 'Yeşil':
        return const Color(0xFF228B22);
      default:
        return const Color(0xFF2A3340);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;

    return Scaffold(
      backgroundColor: AppDesignSystem.background,
      appBar: AppBar(
        backgroundColor: AppDesignSystem.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppDesignSystem.textPrimary),
          onPressed: () {
            // Ana sayfaya yönlendir
            AppRoutes.navigateToMain(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: AppDesignSystem.textPrimary),
            onPressed: _shareProduct,
          ),
        ],
      ),
      body: Column(
        children: [
          // Breadcrumb
          _buildBreadcrumb(),

          // Ana içerik
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  // Ürün görseli ve bilgileri
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 80 : 24,
                      vertical: 24,
                    ),
                    child: isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sol: Görsel
                              Expanded(
                                flex: 1,
                                child: _buildProductImage(),
                              ),
                              const SizedBox(width: 24),
                              // Sağ: Bilgiler
                              Expanded(
                                flex: 1,
                                child: _buildProductInfo(),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildProductImage(),
                              const SizedBox(height: 24),
                              _buildProductInfo(),
                            ],
                          ),
                  ),

                  const SizedBox(height: 24),

                  // Yorumlar bölümü
                  Container(
                    key: _reviewsSectionKey,
                    margin:
                        EdgeInsets.symmetric(horizontal: isDesktop ? 80 : 24),
                    padding: const EdgeInsets.all(24),
                    decoration: AppDesignSystem.cardDecoration(
                      borderRadius: AppDesignSystem.radiusS,
                      shadows: AppDesignSystem.shadowS,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Başlık: Tüm Değerlendirmeler
                        Text(
                          'Tüm Değerlendirmeler',
                          style: AppDesignSystem.heading3,
                        ),
                        const SizedBox(height: 16),

                        // Genel puan ve yorum sayısı
                        Row(
                          children: [
                            StarRating(
                              rating: _reviewsLoaded
                                  ? _averageRating
                                  : widget.product.averageRating,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _reviewsLoaded
                                  ? '${_averageRating.toStringAsFixed(1)}'
                                  : '${widget.product.averageRating.toStringAsFixed(1)}',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F0F0F),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _reviewsLoaded
                                  ? '$_totalReviews Değerlendirme ${_reviews.where((r) => r.comment.isNotEmpty).length} Yorum'
                                  : '${widget.product.reviewCount} Değerlendirme ${widget.product.reviewCount} Yorum',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFFC7CDD6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Arama çubuğu ve sıralama
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0B0D10),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFF2A3340)),
                                ),
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Değerlendirmelerde Ara',
                                    hintStyle: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: const Color(0xFF8E98A8),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      size: 20,
                                      color: Color(0xFFC7CDD6),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                  ),
                                  style: GoogleFonts.inter(fontSize: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              height: 40,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B0D10),
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: const Color(0xFF2A3340)),
                              ),
                              child: DropdownButton<String>(
                                value: _reviewSortOption,
                                underline: const SizedBox(),
                                icon:
                                    const Icon(Icons.arrow_drop_down, size: 20),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF0F0F0F),
                                ),
                                items: [
                                  'Önerilen Sıralama',
                                  'En Yeni',
                                  'En Eski',
                                  'En Yüksek Puan',
                                  'En Düşük Puan',
                                ].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _reviewSortOption = newValue;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Fotoğraflı değerlendirmeler (varsa)
                        if (_reviews.any((r) => r.imageUrls.isNotEmpty)) ...[
                          Text(
                            'Fotoğraflı Değerlendirmeler',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F0F0F),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _reviews
                                  .where((r) => r.imageUrls.isNotEmpty)
                                  .length,
                              itemBuilder: (context, index) {
                                final reviewWithImage = _reviews
                                    .where((r) => r.imageUrls.isNotEmpty)
                                    .toList()[index];
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: const Color(0xFF2A3340)),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: OptimizedImage(
                                      imageUrl: reviewWithImage.imageUrls.first,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      borderRadius: BorderRadius.circular(8),
                                      errorWidget: Container(
                                        color: Colors.grey[200],
                                        child: const Icon(
                                            Icons.image_not_supported),
                                      ),
                                      placeholder: Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        if (FirebaseAuth.instance.currentUser != null)
                          if (_isCheckingPurchase)
                            const Center(child: CircularProgressIndicator())
                          else
                            ReviewForm(
                              productId: widget.product.id,
                              onReviewAdded: _onReviewAdded,
                              hasPurchased: _hasPurchased,
                            )
                        else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue[600]),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Yorum yapmak için giriş yapın',
                                    style: GoogleFonts.inter(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 20),

                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_reviews.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.comment_outlined,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  'Henüz yorum yok',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'İlk yorumu siz yapın!',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ReviewList(
                            key: ValueKey(
                                'reviews_${widget.product.id}_${_totalReviews}'),
                            productId: widget.product.id,
                            reviews: _reviews,
                            onReviewUpdated: () {
                              if (!_isRefreshingReviews && mounted) {
                                Future.delayed(
                                    const Duration(milliseconds: 500), () {
                                  if (mounted && !_isRefreshingReviews) {
                                    _loadReviews();
                                  }
                                });
                              }
                            },
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
