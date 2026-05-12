import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/no_overflow.dart';
import '../model/product.dart';
import '../services/firebase_data_service.dart';
import '../widgets/optimized_image.dart';
import '../utils/professional_animations.dart';
import '../utils/professional_error_handler.dart';
import '../config/app_routes.dart';
import '../theme/app_design_system.dart';

class SepetimSayfasi extends StatefulWidget {
  final List<Product> cartProducts;
  final Function(Product) onRemoveFromCart;
  final Function(Product, int) onUpdateQuantity;
  final Function() onPlaceOrder;
  final VoidCallback? onNavigateToMainPage;

  const SepetimSayfasi({
    super.key,
    required this.cartProducts,
    required this.onRemoveFromCart,
    required this.onUpdateQuantity,
    required this.onPlaceOrder,
    this.onNavigateToMainPage,
  });

  @override
  State<SepetimSayfasi> createState() => _SepetimSayfasiState();
}

class _SepetimSayfasiState extends State<SepetimSayfasi> {
  final TextEditingController _couponController = TextEditingController();
  String _appliedCoupon = '';
  double _couponDiscount = 0.0;
  bool _isCouponApplied = false;
  bool _isFreeShippingCoupon = false; // FREESHIP kuponu için
  double _shippingCost = 44.99; // Trendyol tarzı kargo ücreti
  String? _couponError; // Kupon hatası için

  // Services
  final FirebaseDataService _firebaseDataService = FirebaseDataService();

  // Ürün miktarı controller'ları için Map
  final Map<String, TextEditingController> _quantityControllers = {};

  @override
  void dispose() {
    _couponController.dispose();
    // Tüm quantity controller'ları temizle
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    _quantityControllers.clear();
    super.dispose();
  }

  TextEditingController _getQuantityController(Product product) {
    if (!_quantityControllers.containsKey(product.id)) {
      _quantityControllers[product.id] =
          TextEditingController(text: '${product.quantity}');
    } else {
      // Controller varsa ama değer farklıysa güncelle
      final controller = _quantityControllers[product.id]!;
      if (controller.text != '${product.quantity}') {
        controller.text = '${product.quantity}';
      }
    }
    return _quantityControllers[product.id]!;
  }

  double get _subtotal {
    return widget.cartProducts
        .fold(0.0, (sum, product) => sum + (product.price * product.quantity));
  }

  double get _couponDiscountAmount {
    return _subtotal * _couponDiscount;
  }

  double get _finalShippingCost {
    // 100 TL üzeri ücretsiz kargo veya FREESHIP kuponu ile ücretsiz kargo
    if (_subtotal >= 100 || _isFreeShippingCoupon) {
      return 0.0;
    }
    return _shippingCost;
  }

  double get _total {
    return _subtotal - _couponDiscountAmount + _finalShippingCost;
  }

  void _applyCoupon() {
    final couponCode = _couponController.text.trim();
    if (couponCode.isEmpty) {
      setState(() {
        _couponError = 'Lütfen bir kupon kodu girin';
      });
      return;
    }

    // Demo kupon kodları
    final upperCode = couponCode.toUpperCase();
    switch (upperCode) {
      case 'WELCOME10':
        setState(() {
          _couponDiscount = 0.10; // %10 indirim
          _appliedCoupon = upperCode;
          _isCouponApplied = true;
          _isFreeShippingCoupon = false;
          _couponError = null;
        });
        Navigator.pop(context);
        ProfessionalErrorHandler.showSuccess(
          context: context,
          title: 'Kupon Uygulandı!',
          message: '%10 indirim kazandınız!',
        );
        break;
      case 'SAVE20':
        setState(() {
          _couponDiscount = 0.20; // %20 indirim
          _appliedCoupon = upperCode;
          _isCouponApplied = true;
          _isFreeShippingCoupon = false;
          _couponError = null;
        });
        Navigator.pop(context);
        ProfessionalErrorHandler.showSuccess(
          context: context,
          title: 'Kupon Uygulandı!',
          message: '%20 indirim kazandınız!',
        );
        break;
      case 'FREESHIP':
        setState(() {
          _couponDiscount = 0.0; // İndirim yok, sadece ücretsiz kargo
          _appliedCoupon = upperCode;
          _isCouponApplied = true;
          _isFreeShippingCoupon = true; // Ücretsiz kargo kuponu
          _couponError = null;
        });
        Navigator.pop(context);
        ProfessionalErrorHandler.showSuccess(
          context: context,
          title: 'Kupon Uygulandı!',
          message: 'Ücretsiz kargo kazandınız!',
        );
        break;
      default:
        setState(() {
          _couponError = 'Geçersiz kupon kodu. Lütfen geçerli bir kod girin.';
        });
    }
  }

  void _removeCoupon() {
    setState(() {
      _couponDiscount = 0.0;
      _appliedCoupon = '';
      _isCouponApplied = false;
      _isFreeShippingCoupon = false;
      _couponController.clear();
      _couponError = null;
    });
  }

  void _updateProductQuantity(Product product, int newQuantity) {
    // Stok kontrolü
    if (newQuantity > product.stock) {
      ProfessionalErrorHandler.showWarning(
        context: context,
        title: 'Yeterli Stok Yok',
        message:
            'Mevcut stok: ${product.stock} adet. Daha fazla ekleyemezsiniz.',
      );
      // Controller'ı güncelle
      if (_quantityControllers.containsKey(product.id)) {
        _quantityControllers[product.id]!.text = '${product.quantity}';
      }
      return;
    }

    if (newQuantity <= 0) {
      widget.onRemoveFromCart(product);
      // Controller'ı temizle
      _quantityControllers.remove(product.id)?.dispose();
    } else {
      widget.onUpdateQuantity(product, newQuantity);
      // Controller'ı güncelle
      if (_quantityControllers.containsKey(product.id)) {
        _quantityControllers[product.id]!.text = '$newQuantity';
      }
    }
  }

  void _updateProductQuantityFromText(Product product, String value) {
    if (value.isEmpty) {
      // Boşsa eski değere geri dön
      if (_quantityControllers.containsKey(product.id)) {
        _quantityControllers[product.id]!.text = '${product.quantity}';
      }
      return;
    }

    final newQuantity = int.tryParse(value);
    if (newQuantity == null || newQuantity < 1) {
      ProfessionalErrorHandler.showWarning(
        context: context,
        title: 'Geçersiz Miktar',
        message: 'Lütfen geçerli bir sayı girin (minimum 1).',
      );
      // Controller'ı eski değere geri dön
      if (_quantityControllers.containsKey(product.id)) {
        _quantityControllers[product.id]!.text = '${product.quantity}';
      }
      return;
    }

    _updateProductQuantity(product, newQuantity);
  }

  Future<void> _proceedToCheckout() async {
    if (widget.cartProducts.isEmpty) {
      ProfessionalErrorHandler.showWarning(
        context: context,
        title: 'Sepet Boş',
        message: 'Sepetinizde ürün bulunmuyor.',
      );
      return;
    }

    try {
      // Sadece ödeme sayfasına yönlendir - sipariş oluşturma işlemi ödeme sayfasında yapılacak
      // Bu şekilde tek bir sipariş oluşturulur ve sepet doğru şekilde temizlenir
      if (mounted) {
        // Ödeme sayfasına yönlendir
        AppRoutes.navigateToPayment(
          context,
          widget.cartProducts,
          appliedCoupon: _appliedCoupon,
          couponDiscount: _couponDiscount,
          isCouponApplied: _isCouponApplied,
        );
      }
    } catch (e) {
      if (mounted) {
        ProfessionalErrorHandler.showError(
          context: context,
          title: 'Sipariş Hatası',
          message: 'Sipariş oluşturulurken hata oluştu: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppDesignSystem.background,
      appBar: AppBar(
        title: Text(
          'Sepetim',
          style: AppDesignSystem.heading3,
        ),
        backgroundColor: AppDesignSystem.surface,
        foregroundColor: AppDesignSystem.textPrimary,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.05),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppDesignSystem.textPrimary),
          onPressed: () {
            // Ana sayfaya yönlendir
            AppRoutes.navigateToMain(context);
          },
        ),
        actions: [
          if (widget.cartProducts.isNotEmpty)
            TextButton(
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                _showClearCartDialog();
              },
              child: Text(
                'Temizle',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppDesignSystem.error,
                ),
              ),
            ),
        ],
      ),
      body: widget.cartProducts.isEmpty
          ? RefreshIndicator(
              onRefresh: () async {
                // Sepet boşsa sadece state'i güncelle
                setState(() {});
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: NoOverflow(
                  child: _buildEmptyCart(),
                ),
              ),
            )
          : SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final isDesktop = screenWidth >= 1024;

                  if (isDesktop) {
                    // Desktop: Sol ürün listesi, sağ sidebar özet
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sol taraf - Ürün listesi
                        Expanded(
                          flex: 3,
                          child: RefreshIndicator(
                            onRefresh: () async {
                              setState(() {});
                            },
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(24),
                              child: _buildProductList(),
                            ),
                          ),
                        ),
                        // Sağ taraf - Sepet Özeti (Sabit sidebar)
                        Container(
                          width: 400,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              left: BorderSide(
                                color: const Color(0xFF2A3340),
                                width: 1,
                              ),
                            ),
                          ),
                          child: _buildOrderSummary(isDesktop: true),
                        ),
                      ],
                    );
                  } else {
                    // Mobil/Tablet: Üst ürün listesi, alt özet
                    return Column(
                      children: [
                        // Ürün listesi - Scrollable olmalı
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async {
                              setState(() {});
                            },
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildProductList(),
                            ),
                          ),
                        ),
                        // Özet ve ödeme - Sabit kalmalı
                        _buildOrderSummary(isDesktop: false),
                      ],
                    );
                  }
                },
              ),
            ),
    );
  }

  Widget _buildEmptyCart() {
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
                Icons.shopping_cart_outlined,
                size: 64,
                color: AppDesignSystem.textTertiary,
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacingL),
            Text(
              'Sepetiniz Boş',
              style: AppDesignSystem.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDesignSystem.spacingS),
            Text(
              'Alışverişe başlamak için ürün ekleyin.',
              style: AppDesignSystem.bodyMedium.copyWith(
                color: AppDesignSystem.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDesignSystem.spacingXL),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: AppDesignSystem.primaryButtonStyle(),
                child: Text(
                  'Alışverişe Başla',
                  style: AppDesignSystem.buttonMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return ProfessionalAnimations.createStaggeredList(
      children: widget.cartProducts.map((product) {
        return _buildProductCard(product);
      }).toList(),
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: AppDesignSystem.cardDecoration(
        borderRadius: AppDesignSystem.radiusM,
        shadows: AppDesignSystem.shadowS,
      ),
      child: Row(
        children: [
          // Ürün resmi
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
            child: OptimizedImage(
              imageUrl: product.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(width: AppDesignSystem.spacingM),

          // Ürün bilgileri
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  style: AppDesignSystem.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: AppDesignSystem.spacingS),

                Text(
                  '${product.price.toStringAsFixed(2)} ₺',
                  style: AppDesignSystem.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppDesignSystem.accent,
                  ),
                ),

                const SizedBox(height: AppDesignSystem.spacingXS),

                // Miktar kontrolü ve stok bilgisi
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppDesignSystem.surfaceVariant,
                            borderRadius:
                                BorderRadius.circular(AppDesignSystem.radiusS),
                          ),
                          child: IconButton(
                            onPressed: () => _updateProductQuantity(
                                product, product.quantity - 1),
                            icon: const Icon(Icons.remove, size: 18),
                            color: AppDesignSystem.textPrimary,
                            padding:
                                const EdgeInsets.all(AppDesignSystem.spacingS),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: AppDesignSystem.spacingS),
                          width: 60,
                          child: TextField(
                            controller: _getQuantityController(product),
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: AppDesignSystem.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppDesignSystem.spacingS,
                                vertical: AppDesignSystem.spacingS,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDesignSystem.radiusS),
                                borderSide: BorderSide(
                                    color: AppDesignSystem.borderLight),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDesignSystem.radiusS),
                                borderSide: BorderSide(
                                    color: AppDesignSystem.borderLight),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDesignSystem.radiusS),
                                borderSide: BorderSide(
                                    color: AppDesignSystem.accent, width: 2),
                              ),
                              isDense: true,
                            ),
                            onSubmitted: (value) {
                              _updateProductQuantityFromText(product, value);
                            },
                            onTap: () {
                              // Tıklanınca tüm metni seç
                              final controller =
                                  _getQuantityController(product);
                              controller.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: controller.text.length,
                              );
                            },
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: AppDesignSystem.surfaceVariant,
                            borderRadius:
                                BorderRadius.circular(AppDesignSystem.radiusS),
                          ),
                          child: IconButton(
                            onPressed: () => _updateProductQuantity(
                                product, product.quantity + 1),
                            icon: const Icon(Icons.add, size: 18),
                            color: AppDesignSystem.textPrimary,
                            padding:
                                const EdgeInsets.all(AppDesignSystem.spacingS),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDesignSystem.spacingXS),
                    // Stok bilgisi
                    Text(
                      'Stok: ${product.stock} adet',
                      style: AppDesignSystem.bodySmall.copyWith(
                        color: product.stock > 0
                            ? (product.stock < 10
                                ? const Color(0xFFFFB020)
                                : const Color(0xFF18C964))
                            : const Color(0xFFEF4444),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Toplam fiyat ve sil butonu
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(product.price * product.quantity).toStringAsFixed(2)} ₺',
                style: AppDesignSystem.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppDesignSystem.accent,
                ),
              ),
              const SizedBox(height: AppDesignSystem.spacingS),
              IconButton(
                onPressed: () => widget.onRemoveFromCart(product),
                icon: Icon(Icons.delete_outline,
                    color: AppDesignSystem.error, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary({required bool isDesktop}) {
    final hasFreeShipping = _subtotal >= 100 || _finalShippingCost == 0;
    final totalSavings = _couponDiscountAmount;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: isDesktop
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                  spreadRadius: 0,
                ),
              ],
        border: isDesktop
            ? null
            : Border(
                top: BorderSide(
                  color: const Color(0xFF2A3340),
                  width: 1,
                ),
              ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Text(
              'Sepet Özeti',
              style: GoogleFonts.inter(
                fontSize: isDesktop ? 20 : 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F0F0F),
              ),
            ),

            const SizedBox(height: 20),

            // Ara Toplam
            _buildSummaryRow('Ara Toplam', _subtotal.toStringAsFixed(2)),

            // Kupon İndirimi (eğer varsa)
            if (_isCouponApplied && _couponDiscount > 0) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.local_offer,
                        size: 16,
                        color: const Color(0xFF18C964),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'İndirim Kuponu (${_appliedCoupon})',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFC7CDD6),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '-${_couponDiscountAmount.toStringAsFixed(2)} ₺',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF18C964),
                    ),
                  ),
                ],
              ),
            ],

            // Ücretsiz Kargo Kuponu (FREESHIP)
            if (_isCouponApplied && _isFreeShippingCoupon) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.local_offer,
                        size: 16,
                        color: const Color(0xFF18C964),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Kupon: $_appliedCoupon',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFC7CDD6),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18C964),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Ücretsiz Kargo',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Kargo Tutarı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kargo Tutarı',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFC7CDD6),
                  ),
                ),
                Row(
                  children: [
                    if (hasFreeShipping) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18C964),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Bedava',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ] else ...[
                      Text(
                        '${_finalShippingCost.toStringAsFixed(2)} ₺',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            // Toplam Kazanç (sadece indirim kuponu varsa göster)
            if (_isCouponApplied &&
                _couponDiscount > 0 &&
                totalSavings > 0) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Toplam Kazancın',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF18C964),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_downward,
                        size: 16,
                        color: const Color(0xFF18C964),
                      ),
                    ],
                  ),
                  Text(
                    '-${totalSavings.toStringAsFixed(2)} ₺',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF18C964),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFF2A3340)),
            const SizedBox(height: 16),

            // Toplam
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Toplam',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F0F0F),
                  ),
                ),
                Text(
                  '${_total.toStringAsFixed(2)} ₺',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F0F0F),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // İndirim Kodu butonu veya uygulanmış kupon bilgisi
            if (_isCouponApplied) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF18C964).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF18C964).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF18C964),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kupon Uygulandı',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF18C964),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isFreeShippingCoupon
                                ? 'Ücretsiz Kargo: $_appliedCoupon'
                                : '%${(_couponDiscount * 100).toStringAsFixed(0)} İndirim: $_appliedCoupon',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF18C964),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _removeCoupon();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Kaldır',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showCouponDialog();
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(
                    'İndirim Kodu Gir',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F0F0F),
                    side: const BorderSide(color: Color(0xFF2A3340)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Sepeti Onayla butonu
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _proceedToCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6A00),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Sepeti Onayla',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Gel Al noktası önerisi
            _buildPickupPointSuggestion(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFC7CDD6),
          ),
        ),
        Text(
          '$value ₺',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildPickupPointSuggestion() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0D10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF2A3340),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.location_on,
              color: const Color(0xFFFF6A00),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'En yakın gel al noktasını seç',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F0F0F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Siparişini sana uygun zamanda güvenle teslim al',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFFC7CDD6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Teslimat noktasını ödeme adımında seçebilirsin',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF8E98A8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCouponDialog() {
    _couponError = null; // Dialog açılırken hatayı temizle
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6A00).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_offer,
                        color: Color(0xFFFF6A00),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'İndirim Kodu',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F0F0F),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                      color: const Color(0xFFC7CDD6),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Kupon kodu input
                TextField(
                  controller: _couponController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0F0F0F),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Kupon kodunuzu girin',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 16,
                      color: const Color(0xFF8E98A8),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0B0D10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _couponError != null
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF2A3340),
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _couponError != null
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF2A3340),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFFF6A00),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFEF4444),
                        width: 1.5,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFEF4444),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  onChanged: (value) {
                    if (_couponError != null) {
                      setDialogState(() {
                        _couponError = null;
                      });
                    }
                  },
                ),

                // Hata mesajı
                if (_couponError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _couponError!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFFEF4444),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Uygulanmış kupon bilgisi
                if (_isCouponApplied) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18C964).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF18C964).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF18C964),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kupon Uygulandı',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF18C964),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Kod: $_appliedCoupon',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF18C964),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Butonlar
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(
                            color: Color(0xFF2A3340),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          'İptal',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFC7CDD6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_isCouponApplied) {
                            _removeCoupon();
                            Navigator.pop(context);
                          } else {
                            _applyCoupon();
                            setDialogState(() {}); // State'i güncelle
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6A00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isCouponApplied ? 'Kaldır' : 'Uygula',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showClearCartDialog() async {
    ProfessionalErrorHandler.showWarning(
      context: context,
      title: 'Sepeti Temizle',
      message: 'Sepetinizdeki tüm ürünler silinecek. Emin misiniz?',
      actionText: 'Temizle',
      onAction: () async {
        try {
          // Firebase'den tüm sepeti temizle
          await _firebaseDataService.clearCart();

          // Local listeyi de temizle - tüm ürünleri kaldır
          final productsToRemove = List<Product>.from(widget.cartProducts);
          for (final product in productsToRemove) {
            widget.onRemoveFromCart(product);
          }

          if (mounted) {
            Navigator.pop(context);
            ProfessionalErrorHandler.showSuccess(
              context: context,
              title: 'Sepet Temizlendi',
              message: 'Sepetinizdeki tüm ürünler kaldırıldı.',
            );
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context);
            ProfessionalErrorHandler.showError(
              context: context,
              title: 'Hata',
              message: 'Sepet temizlenirken hata oluştu: $e',
            );
          }
        }
      },
    );
  }
}
