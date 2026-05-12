import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/order.dart';
import '../model/product_review.dart';
import '../model/product.dart';
import '../services/review_service.dart';
import '../widgets/optimized_image.dart';
import '../config/app_routes.dart';
import '../theme/app_design_system.dart';
import '../utils/responsive_helper.dart';

class SiparisDetaySayfasi extends StatefulWidget {
  final Order order;

  const SiparisDetaySayfasi({super.key, required this.order});

  @override
  State<SiparisDetaySayfasi> createState() => _SiparisDetaySayfasiState();
}

class _SiparisDetaySayfasiState extends State<SiparisDetaySayfasi> {
  Map<String, ProductReview?> _productReviews = {};
  Map<String, bool> _isLoadingReviews = {};
  bool _canReview = false;

  @override
  void initState() {
    super.initState();
    _checkCanReview();
    _loadProductReviews();
  }

  void _checkCanReview() {
    // Sadece teslim edilmiş veya onaylanmış siparişlerde yorum yapılabilir
    // Ayrıca ürün listesi boş olmamalı
    final status = widget.order.status.toLowerCase();
    setState(() {
      _canReview = widget.order.products.isNotEmpty &&
          (status == 'delivered' ||
              status == 'teslim edildi' ||
              status == 'confirmed' ||
              status == 'onaylandı');
    });
  }

  Future<void> _loadProductReviews() async {
    if (!_canReview) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Products listesi boş olabilir kontrol et
    if (widget.order.products.isEmpty) {
      debugPrint('Siparişte ürün bulunamadı, yorum kontrolü yapılamıyor');
      return;
    }

    for (var product in widget.order.products) {
      try {
        setState(() {
          _isLoadingReviews[product.id] = true;
        });

        final review =
            await ReviewService.getUserReviewForProduct(product.id, user.uid);

        if (mounted) {
          setState(() {
            _productReviews[product.id] = review;
            _isLoadingReviews[product.id] = false;
          });
        }
      } catch (e) {
        debugPrint('Yorum yüklenirken hata (${product.id}): $e');
        if (mounted) {
          setState(() {
            _isLoadingReviews[product.id] = false;
          });
        }
      }
    }
  }

  Future<void> _navigateToReviewPage(Product product) async {
    if (!mounted) return;

    // Ürün detay sayfasına git - forceHasPurchased = true ile
    // Böylece direkt yorum yapma formu görünecek
    try {
      await AppRoutes.navigateToProductDetailById(
        context,
        product.id,
        forceHasPurchased: true, // Siparişlerden gelindiği için direkt true
      );
      debugPrint('✓ Ürün detay sayfasına gidildi (forceHasPurchased=true)');
    } catch (e) {
      debugPrint('✗ Ürün detay sayfasına gidilemedi: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ürün detay sayfası açılamadı'),
            backgroundColor: context.appTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'Sipariş #${widget.order.id}',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        backgroundColor: colors.navSurface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        shadowColor:
            colors.shadow.withValues(alpha: colors.isDark ? 0.28 : 0.05),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () {
            // Ana sayfaya yönlendir
            AppRoutes.navigateToMain(context);
          },
        ),
      ),
      body: SafeArea(
        child: Container(
          color: colors.background,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sipariş durumu kartı
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          colors.surfaceElevated,
                          AppDesignSystem.warningLight
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Sipariş Durumu',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(widget.order.status),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.order.statusText,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Sipariş Tarihi: ${_formatDate(widget.order.orderDate)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () async {
                            await Clipboard.setData(
                                ClipboardData(text: widget.order.id));
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: AppColors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text('Sipariş numarası kopyalandı!'),
                                    ],
                                  ),
                                  backgroundColor: colors.success,
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Sipariş No: #${widget.order.id}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.copy,
                                  size: 16, color: colors.textSecondary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Müşteri bilgileri
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          colors.surfaceElevated,
                          AppDesignSystem.infoLight
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Müşteri Bilgileri',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Ad Soyad', widget.order.customerName),
                        _buildInfoRow('E-posta', widget.order.customerEmail),
                        _buildInfoRow(
                            'Teslimat Adresi', widget.order.shippingAddress),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Ürünler listesi
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          colors.surfaceElevated,
                          AppDesignSystem.successLight
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sipariş Detayları',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (widget.order.products.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                'Bu siparişte ürün bulunamadı',
                                style: TextStyle(color: colors.textSecondary),
                              ),
                            ),
                          )
                        else
                          ...widget.order.products
                              .map((product) => _buildProductItem(product)),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Toplam Ürün:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
                              ),
                            ),
                            Text(
                              '${widget.order.totalItems} adet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Toplam Tutar:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              '${widget.order.totalAmount.toStringAsFixed(2)} TL',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: colors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final colors = context.appTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    final colors = context.appTheme;
    final hasReview = _productReviews[product.id] != null;
    final isLoading = _isLoadingReviews[product.id] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceInteractive,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: [
              OptimizedImage(
                imageUrl: product.imageUrl,
                width: 60,
                height: 60,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.price.toStringAsFixed(2)} TL',
                      style: TextStyle(
                        color: colors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Miktar: ${product.quantity}',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${product.totalPrice.toStringAsFixed(2)} TL',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: colors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Yorum yapma butonu (sadece teslim edilmiş/onaylanmış siparişlerde)
          if (_canReview) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            if (isLoading)
              const SizedBox(
                height: 32,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (hasReview)
              Row(
                children: [
                  Icon(Icons.check_circle, color: colors.success, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Yorumunuz paylaşıldı',
                    style: TextStyle(
                      color: colors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(
                      width: ResponsiveHelper.responsiveSpacing(context,
                          mobile: 8.0, desktop: 12.0)),
                  TextButton.icon(
                    onPressed: () => _navigateToReviewPage(product),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Yorumunu Gör'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToReviewPage(product),
                  icon: const Icon(Icons.rate_review, size: 16),
                  label: const Text('Yorum Yap'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.textInverse,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    final colors = context.appTheme;
    switch (status.toLowerCase()) {
      case 'pending':
        return colors.warning;
      case 'confirmed':
        return colors.accent;
      case 'shipped':
        return colors.accentSecondary;
      case 'delivered':
        return colors.success;
      case 'cancelled':
        return colors.error;
      default:
        return colors.textMuted;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
