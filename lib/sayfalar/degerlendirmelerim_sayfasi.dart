import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/product_review.dart';
import '../model/product.dart';
import '../services/review_service.dart';
import '../services/product_service.dart';
import '../widgets/optimized_image.dart';
import 'urun_detay_sayfasi.dart';
import '../theme/app_design_system.dart';
import '../config/app_routes.dart';

class DegerlendirmelerimSayfasi extends StatefulWidget {
  const DegerlendirmelerimSayfasi({super.key});

  @override
  State<DegerlendirmelerimSayfasi> createState() =>
      _DegerlendirmelerimSayfasiState();
}

class _DegerlendirmelerimSayfasiState extends State<DegerlendirmelerimSayfasi> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ProductService _productService = ProductService();

  List<ProductReview> _reviews = [];
  Map<String, Product> _products = {}; // productId -> Product mapping
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _reviews = [];
          _isLoading = false;
        });
        return;
      }

      // Kullanıcının yorumlarını getir (Firebase'den direkt çek)
      debugPrint('Loading reviews for user: ${user.uid}');
      final reviews = await ReviewService.getUserReviews(user.uid);
      debugPrint('Loaded ${reviews.length} reviews from Firebase');

      // Ürün bilgilerini getir (ürün bulunamasa bile yorumlar gösterilecek)
      final products = <String, Product>{};
      for (final review in reviews) {
        // Ürün zaten yüklenmişse tekrar yükleme
        if (products.containsKey(review.productId)) continue;

        try {
          final product =
              await _productService.getProductById(review.productId);
          if (product != null) {
            products[review.productId] = product;
          }
        } catch (e) {
          debugPrint('Error loading product ${review.productId}: $e');
          // Ürün bulunamasa bile devam et
        }
      }

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading reviews: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<ProductReview> get _filteredReviews {
    if (_searchQuery.isEmpty) return _reviews;

    return _reviews.where((review) {
      final product = _products[review.productId];
      final productName = product?.name ?? 'Ürün bulunamadı';

      return productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          review.comment.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
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
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppDesignSystem.textPrimary),
          onPressed: () {
            // Ana sayfaya yönlendir
            AppRoutes.navigateToMain(context);
          },
        ),
        title: Text(
          'Değerlendirmelerim',
          style: AppDesignSystem.heading2,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 80 : 24,
              vertical: 8,
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF0F0F0F),
              ),
              decoration: AppDesignSystem.inputDecoration(
                label: '',
                hint: 'Ürün veya yorum ara',
                prefixIcon: Icon(
                  Icons.search,
                  color: AppDesignSystem.textSecondary,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredReviews.isEmpty
              ? _buildEmptyState()
              : _buildReviewsList(isDesktop),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
                Icons.rate_review_outlined,
                size: 64,
                color: AppDesignSystem.textTertiary,
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacingL),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Arama kriterlerinize uygun değerlendirme bulunamadı'
                  : 'Henüz değerlendirme yapmadınız',
              style: AppDesignSystem.heading4,
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: AppDesignSystem.spacingS),
              Text(
                'Ürünlere yorum yaparak başlayın',
                style: AppDesignSystem.bodyMedium.copyWith(
                  color: AppDesignSystem.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsList(bool isDesktop) {
    return RefreshIndicator(
      onRefresh: _loadReviews,
      color: const Color(0xFFFF6A00),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 80 : 24,
          vertical: 16,
        ),
        itemCount: _filteredReviews.length,
        itemBuilder: (context, index) {
          final review = _filteredReviews[index];
          final product = _products[review.productId];

          // Ürün bulunamasa bile yorumu göster
          return _buildReviewCard(review, product);
        },
      ),
    );
  }

  Widget _buildReviewCard(ProductReview review, Product? product) {
    final hasProduct = product != null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDesignSystem.spacingM),
      decoration: AppDesignSystem.cardDecoration(
        borderRadius: AppDesignSystem.radiusM,
        shadows: AppDesignSystem.shadowS,
      ),
      child: InkWell(
        onTap: hasProduct
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UrunDetaySayfasi(
                      product: product,
                      favoriteProducts: const [],
                      onFavoriteToggle: (_) async {
                        return;
                      },
                      onAddToCart: (_) async {
                        return;
                      },
                      onRemoveFromCart: (_) {},
                      cartProducts: const [],
                    ),
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDesignSystem.spacingM),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ürün resmi
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
                child: hasProduct
                    ? OptimizedImage(
                        imageUrl: product.imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 100,
                        height: 100,
                        color: AppDesignSystem.surfaceVariant,
                        child: Icon(
                          Icons.image_not_supported,
                          color: AppDesignSystem.textTertiary,
                          size: 32,
                        ),
                      ),
              ),
              const SizedBox(width: AppDesignSystem.spacingM),
              // Ürün bilgileri ve yorum
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ürün adı veya bilgi
                    Text(
                      hasProduct ? product.name : 'Ürün bulunamadı',
                      style: AppDesignSystem.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: hasProduct
                            ? AppDesignSystem.textPrimary
                            : AppDesignSystem.textTertiary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Onay durumu
                    if (!review.isApproved) ...[
                      const SizedBox(height: AppDesignSystem.spacingXS),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDesignSystem.spacingS,
                          vertical: AppDesignSystem.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: AppDesignSystem.warningLight,
                          borderRadius:
                              BorderRadius.circular(AppDesignSystem.radiusXS),
                          border: Border.all(
                            color: AppDesignSystem.warning.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Onay bekliyor',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Rating
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            size: 18,
                            color: index < review.rating
                                ? const Color(0xFFFF6A00)
                                : Colors.grey[300],
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          '${review.rating}.0',
                          style: AppDesignSystem.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDesignSystem.spacingS),
                    // Yorum metni
                    if (review.comment.isNotEmpty)
                      Text(
                        review.comment,
                        style: AppDesignSystem.bodyMedium.copyWith(
                          color: AppDesignSystem.textSecondary,
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: AppDesignSystem.spacingS),
                    // Yorum görselleri
                    if (review.imageUrls.isNotEmpty)
                      SizedBox(
                        height: 60,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: review.imageUrls.length > 3
                              ? 3
                              : review.imageUrls.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 60,
                              height: 60,
                              margin: const EdgeInsets.only(
                                  right: AppDesignSystem.spacingS),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    AppDesignSystem.radiusS),
                                border: Border.all(
                                    color: AppDesignSystem.borderLight),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    AppDesignSystem.radiusS - 1),
                                child: Image.network(
                                  review.imageUrls[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) =>
                                      Container(
                                    color: AppDesignSystem.surfaceVariant,
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: AppDesignSystem.textTertiary,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: AppDesignSystem.spacingS),
                    // Tarih
                    Text(
                      _formatDate(review.createdAt),
                      style: AppDesignSystem.bodySmall.copyWith(
                        color: AppDesignSystem.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              // Sağ tarafta ok ikonu
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppDesignSystem.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} dakika önce';
      }
      return '${difference.inHours} saat önce';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks hafta önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
