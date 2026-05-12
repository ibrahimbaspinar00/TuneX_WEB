import 'package:flutter/material.dart';
import '../config/app_routes.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/order.dart';
import '../model/product.dart';
import '../services/order_service.dart';
import 'siparis_detay_sayfasi.dart';
import '../widgets/optimized_image.dart';
import '../theme/app_design_system.dart';
import '../utils/responsive_helper.dart';

class SiparislerSayfasi extends StatefulWidget {
  final List<Order> orders;
  final Function(List<Product>)? onOrderPlaced;

  const SiparislerSayfasi({
    super.key,
    this.orders = const [],
    this.onOrderPlaced,
  });

  @override
  State<SiparislerSayfasi> createState() => _SiparislerSayfasiState();
}

class _SiparislerSayfasiState extends State<SiparislerSayfasi> {
  String _selectedTab = 'Tümü'; // Trendyol tarzı tab
  String _searchQuery = '';
  String _selectedDateFilter = 'Tüm tarihler';
  List<Order> _orders = [];
  bool _isLoading = true;
  DateTime? _lastLoadTime;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sayfa her görünür olduğunda siparişleri yeniden yükle
    // Ancak çok sık yüklemeyi önlemek için son yüklemeden 2 saniye geçmiş olmalı
    final now = DateTime.now();
    if (!_isLoading &&
        (_lastLoadTime == null ||
            now.difference(_lastLoadTime!).inSeconds > 2)) {
      _loadOrders();
    }
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final orderService = OrderService();
      final userOrders = await orderService.getUserOrders();

      if (mounted) {
        setState(() {
          _orders = userOrders;
          _isLoading = false;
          _lastLoadTime = DateTime.now();
        });
        debugPrint('Loaded ${_orders.length} orders from Firebase');
      }
    } catch (e) {
      debugPrint('Error loading orders: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _lastLoadTime = DateTime.now();
        });
      }
    }
  }

  List<Order> get _filteredOrders {
    // Önce widget.orders'ı kullan, eğer boşsa _orders'ı kullan
    var orders = widget.orders.isNotEmpty ? widget.orders : _orders;

    // Tab filtresi
    switch (_selectedTab) {
      case 'Devam Eden':
        orders = orders.where((o) {
          final status = o.status.toLowerCase();
          return status != 'delivered' &&
              status != 'teslim edildi' &&
              status != 'cancelled' &&
              status != 'iptal edildi' &&
              status != 'returned' &&
              status != 'iade edildi';
        }).toList();
        break;
      case 'İptal Edilen':
        orders = orders.where((o) {
          final status = o.status.toLowerCase();
          return status == 'cancelled' || status == 'iptal edildi';
        }).toList();
        break;
      case 'İade Edilen':
        orders = orders.where((o) {
          final status = o.status.toLowerCase();
          return status == 'returned' || status == 'iade edildi';
        }).toList();
        break;
      case 'Tümü':
      default:
        // Tüm siparişler
        break;
    }

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      orders = orders.where((order) {
        return order.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            order.customerName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Tarih sıralaması (en yeni önce) - Web'de güvenli
    try {
      orders.sort((a, b) {
        try {
          return b.orderDate.compareTo(a.orderDate);
        } catch (e) {
          // Sıralama hatası durumunda orijinal sırayı koru
          return 0;
        }
      });
    } catch (e) {
      debugPrint('Sıralama hatası (görmezden geliniyor): $e');
      // Sıralama başarısız olsa bile siparişleri döndür
    }

    return orders;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppDesignSystem.background,
      appBar: AppBar(
        backgroundColor: AppDesignSystem.surface,
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppDesignSystem.textPrimary,
          ),
          onPressed: () {
            // Ana sayfaya yönlendir
            AppRoutes.navigateToMain(context);
          },
        ),
        flexibleSpace: Container(
          padding: ResponsiveHelper.responsiveHorizontalPadding(
            context,
            mobile: 16.0,
            tablet: 24.0,
            desktop: 80.0,
          ).copyWith(
            top: 16,
            bottom: 16,
          ),
          child: Row(
            children: [
              // Sol tarafta başlık
              Flexible(
                child: Text(
                  'Siparişlerim',
                  style: AppDesignSystem.heading2.copyWith(
                    fontSize: ResponsiveHelper.responsiveFontSize(
                      context,
                      mobile: 18.0,
                      tablet: 20.0,
                      desktop: 24.0,
                    ),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isMobile) ...[
                if (!ResponsiveHelper.isMobile(context)) const Spacer(),
                // Sağ tarafta arama ve tarih filtresi
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Arama çubuğu
                    SizedBox(
                      width: ResponsiveHelper.responsiveValue(
                        context,
                        mobile: 150.0,
                        tablet: 180.0,
                        desktop: 200.0,
                      ),
                      height: 40,
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
                          hint: 'Sipariş ara',
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppDesignSystem.textSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                        width: ResponsiveHelper.responsiveSpacing(context,
                            mobile: 8.0, desktop: 12.0)),
                    // Tarih filtresi
                    Container(
                      height: 40,
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveHelper.responsiveSpacing(context,
                            mobile: 8.0, desktop: 12.0),
                      ),
                      decoration: BoxDecoration(
                        color: AppDesignSystem.surfaceVariant,
                        borderRadius:
                            BorderRadius.circular(AppDesignSystem.radiusS),
                        border: Border.all(
                          color: AppDesignSystem.borderLight,
                          width: 1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDateFilter,
                          style: AppDesignSystem.bodyMedium.copyWith(
                            fontSize: ResponsiveHelper.responsiveFontSize(
                              context,
                              mobile: 12.0,
                              desktop: 14.0,
                            ),
                          ),
                          items: [
                            'Tüm tarihler',
                            'Son 7 gün',
                            'Son 30 gün',
                            'Son 3 ay'
                          ].map((option) {
                            return DropdownMenuItem(
                              value: option,
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.responsiveFontSize(
                                    context,
                                    mobile: 12.0,
                                    desktop: 14.0,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedDateFilter = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Trendyol tarzı tab'lar
            Container(
              padding: ResponsiveHelper.responsiveHorizontalPadding(
                context,
                mobile: 16.0,
                tablet: 24.0,
                desktop: 80.0,
              ).copyWith(
                top: 12,
                bottom: 12,
              ),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTabButton('Tümü'),
                    SizedBox(
                        width: ResponsiveHelper.responsiveSpacing(context,
                            mobile: 6.0, desktop: 8.0)),
                    _buildTabButton('Devam Eden'),
                    SizedBox(
                        width: ResponsiveHelper.responsiveSpacing(context,
                            mobile: 6.0, desktop: 8.0)),
                    _buildTabButton('İptal Edilen'),
                    SizedBox(
                        width: ResponsiveHelper.responsiveSpacing(context,
                            mobile: 6.0, desktop: 8.0)),
                    _buildTabButton('İade Edilen'),
                  ],
                ),
              ),
            ),
            // Sipariş listesi
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppDesignSystem.primary,
                      ),
                    )
                  : _filteredOrders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(
                                    AppDesignSystem.spacingL),
                                decoration: BoxDecoration(
                                  color: AppDesignSystem.surfaceVariant,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: AppDesignSystem.textTertiary,
                                ),
                              ),
                              const SizedBox(height: AppDesignSystem.spacingM),
                              Text(
                                (widget.orders.isEmpty && _orders.isEmpty)
                                    ? 'Henüz siparişiniz yok'
                                    : 'Bu kategoride sipariş bulunamadı',
                                style: AppDesignSystem.heading4,
                              ),
                              if (widget.orders.isEmpty && _orders.isEmpty) ...[
                                const SizedBox(
                                    height: AppDesignSystem.spacingS),
                                Text(
                                  'Ürünleri sepete ekleyip sipariş verin',
                                  style: AppDesignSystem.bodyMedium.copyWith(
                                    color: AppDesignSystem.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadOrders,
                          color: AppDesignSystem.primary,
                          child: ListView.builder(
                            padding:
                                ResponsiveHelper.responsiveHorizontalPadding(
                              context,
                              mobile: 16.0,
                              tablet: 24.0,
                              desktop: 80.0,
                            ).copyWith(
                              top: 16,
                              bottom: 16,
                            ),
                            itemCount: _filteredOrders.length,
                            itemBuilder: (context, index) {
                              final order = _filteredOrders[index];
                              return _buildTrendyolOrderCard(order);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // Trendyol tarzı tab butonu
  Widget _buildTabButton(String label) {
    final isSelected = _selectedTab == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = label;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.responsiveSpacing(context,
              mobile: 12.0, desktop: 20.0),
          vertical: ResponsiveHelper.responsiveSpacing(context,
              mobile: 8.0, desktop: 10.0),
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppDesignSystem.primary : AppDesignSystem.surface,
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusRound),
          border: Border.all(
            color: isSelected
                ? AppDesignSystem.primary
                : AppDesignSystem.borderLight,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppDesignSystem.labelMedium.copyWith(
            fontSize: ResponsiveHelper.responsiveFontSize(
              context,
              mobile: 12.0,
              desktop: 14.0,
            ),
            color: isSelected
                ? AppDesignSystem.textOnPrimary
                : AppDesignSystem.textPrimary,
          ),
        ),
      ),
    );
  }

  // Trendyol tarzı sipariş kartı
  Widget _buildTrendyolOrderCard(Order order) {
    final deliveryCount = 1; // Demo: 1 teslimat
    // Toplam ürün miktarını hesapla (her ürünün quantity'sini topla)
    final totalProductQuantity =
        order.products.fold(0, (sum, product) => sum + product.quantity);
    final isDelivered = order.status.toLowerCase() == 'delivered' ||
        order.status.toLowerCase() == 'teslim edildi';
    final isCreated = order.status.toLowerCase() == 'pending' ||
        order.status.toLowerCase() == 'beklemede';
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      margin: EdgeInsets.only(
        bottom: ResponsiveHelper.responsiveSpacing(context,
            mobile: 12.0, desktop: 16.0),
      ),
      decoration: AppDesignSystem.cardDecoration(
        borderRadius: AppDesignSystem.radiusM,
        shadows: AppDesignSystem.shadowS,
      ),
      child: Padding(
        padding: ResponsiveHelper.responsivePadding(
          context,
          mobile: 12.0,
          tablet: 14.0,
          desktop: 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Üst kısım: Tarih, özet, alıcı
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Sipariş tarihi
                      Text(
                        _formatOrderDate(order.orderDate),
                        style: AppDesignSystem.bodyMedium.copyWith(
                          fontSize: ResponsiveHelper.responsiveFontSize(
                            context,
                            mobile: 13.0,
                            desktop: 14.0,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(
                          height: ResponsiveHelper.responsiveSpacing(context,
                              mobile: 4.0, desktop: 8.0)),
                      // Sipariş özeti
                      Text(
                        '$deliveryCount Teslimat, $totalProductQuantity Ürün',
                        style: AppDesignSystem.bodySmall.copyWith(
                          fontSize: ResponsiveHelper.responsiveFontSize(
                            context,
                            mobile: 11.0,
                            desktop: 12.0,
                          ),
                          color: AppDesignSystem.textSecondary,
                        ),
                      ),
                      SizedBox(
                          height: ResponsiveHelper.responsiveSpacing(context,
                              mobile: 2.0, desktop: 4.0)),
                      // Alıcı
                      Text(
                        'Alıcı: ${order.customerName}',
                        style: AppDesignSystem.bodySmall.copyWith(
                          fontSize: ResponsiveHelper.responsiveFontSize(
                            context,
                            mobile: 11.0,
                            desktop: 12.0,
                          ),
                          color: AppDesignSystem.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (order.totalAmount > 0) ...[
                        SizedBox(
                            height: ResponsiveHelper.responsiveSpacing(context,
                                mobile: 2.0, desktop: 4.0)),
                        Text(
                          'Toplam: ${order.totalAmount.toStringAsFixed(2)} TL',
                          style: GoogleFonts.inter(
                            fontSize: ResponsiveHelper.responsiveFontSize(
                              context,
                              mobile: 12.0,
                              desktop: 14.0,
                            ),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F0F0F),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Sağ tarafta ürün görselleri
                if (!isMobile)
                  SizedBox(
                    width: ResponsiveHelper.responsiveValue(
                      context,
                      mobile: 80.0,
                      tablet: 100.0,
                      desktop: 120.0,
                    ),
                    height: ResponsiveHelper.responsiveValue(
                      context,
                      mobile: 60.0,
                      tablet: 70.0,
                      desktop: 80.0,
                    ),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          order.products.length > 4 ? 4 : order.products.length,
                      itemBuilder: (context, index) {
                        final product = order.products[index];
                        return Container(
                          width: ResponsiveHelper.responsiveValue(
                            context,
                            mobile: 50.0,
                            tablet: 55.0,
                            desktop: 60.0,
                          ),
                          height: ResponsiveHelper.responsiveValue(
                            context,
                            mobile: 50.0,
                            tablet: 55.0,
                            desktop: 60.0,
                          ),
                          margin: EdgeInsets.only(
                            right: ResponsiveHelper.responsiveSpacing(context,
                                mobile: 4.0, desktop: 8.0),
                          ),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AppDesignSystem.radiusS),
                            border: Border.all(
                              color: AppDesignSystem.borderLight,
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                                AppDesignSystem.radiusS - 1),
                            child: OptimizedImage(
                              imageUrl: product.imageUrl,
                              width: ResponsiveHelper.responsiveValue(
                                context,
                                mobile: 50.0,
                                tablet: 55.0,
                                desktop: 60.0,
                              ),
                              height: ResponsiveHelper.responsiveValue(
                                context,
                                mobile: 50.0,
                                tablet: 55.0,
                                desktop: 60.0,
                              ),
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(
                                  AppDesignSystem.radiusS - 1),
                              placeholder: Container(
                                color: AppDesignSystem.surfaceVariant,
                                child: Icon(
                                  Icons.image,
                                  color: AppDesignSystem.textTertiary,
                                  size: ResponsiveHelper.responsiveIconSize(
                                      context,
                                      mobile: 16.0,
                                      desktop: 20.0),
                                ),
                              ),
                              errorWidget: Container(
                                color: AppDesignSystem.surfaceVariant,
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: AppDesignSystem.textTertiary,
                                  size: ResponsiveHelper.responsiveIconSize(
                                      context,
                                      mobile: 16.0,
                                      desktop: 20.0),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
            SizedBox(
                height: ResponsiveHelper.responsiveSpacing(context,
                    mobile: 12.0, desktop: 16.0)),
            // Durum ve detaylar butonu
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Durum kutusu
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveHelper.responsiveSpacing(
                              context,
                              mobile: 10.0,
                              desktop: 16.0),
                          vertical: ResponsiveHelper.responsiveSpacing(context,
                              mobile: 6.0, desktop: 8.0),
                        ),
                        decoration: BoxDecoration(
                          color: isDelivered
                              ? AppDesignSystem.successLight
                              : AppDesignSystem.infoLight,
                          borderRadius:
                              BorderRadius.circular(AppDesignSystem.radiusS),
                          border: Border.all(
                            color: isDelivered
                                ? AppDesignSystem.success
                                : AppDesignSystem.info,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isDelivered ? Icons.check_circle : Icons.thumb_up,
                              size: ResponsiveHelper.responsiveIconSize(context,
                                  mobile: 14.0, desktop: 16.0),
                              color: isDelivered
                                  ? AppDesignSystem.success
                                  : AppDesignSystem.info,
                            ),
                            SizedBox(
                                width: ResponsiveHelper.responsiveSpacing(
                                    context,
                                    mobile: 4.0,
                                    desktop: 8.0)),
                            Flexible(
                              child: Text(
                                isDelivered
                                    ? 'Teslim edildi'
                                    : isCreated
                                        ? 'Sipariş oluşturuldu'
                                        : order.statusText,
                                style: AppDesignSystem.bodySmall.copyWith(
                                  fontSize: ResponsiveHelper.responsiveFontSize(
                                    context,
                                    mobile: 11.0,
                                    desktop: 12.0,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  color: isDelivered
                                      ? AppDesignSystem.success
                                      : AppDesignSystem.info,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                          height: ResponsiveHelper.responsiveSpacing(context,
                              mobile: 8.0, desktop: 12.0)),
                      // Detaylar butonu
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SiparisDetaySayfasi(order: order),
                              ),
                            );
                          },
                          style: AppDesignSystem.primaryButtonStyle(
                            padding: ResponsiveHelper.responsiveSpacing(context,
                                mobile: 10.0, desktop: 16.0),
                            borderRadius: AppDesignSystem.radiusS,
                          ),
                          child: Text(
                            'Detaylar',
                            style: AppDesignSystem.buttonSmall.copyWith(
                              fontSize: ResponsiveHelper.responsiveFontSize(
                                context,
                                mobile: 12.0,
                                desktop: 14.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      // Durum kutusu
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveHelper.responsiveSpacing(
                                context,
                                mobile: 10.0,
                                desktop: 16.0),
                            vertical: ResponsiveHelper.responsiveSpacing(
                                context,
                                mobile: 6.0,
                                desktop: 8.0),
                          ),
                          decoration: BoxDecoration(
                            color: isDelivered
                                ? AppDesignSystem.successLight
                                : AppDesignSystem.infoLight,
                            borderRadius:
                                BorderRadius.circular(AppDesignSystem.radiusS),
                            border: Border.all(
                              color: isDelivered
                                  ? AppDesignSystem.success
                                  : AppDesignSystem.info,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isDelivered
                                    ? Icons.check_circle
                                    : Icons.thumb_up,
                                size: ResponsiveHelper.responsiveIconSize(
                                    context,
                                    mobile: 14.0,
                                    desktop: 16.0),
                                color: isDelivered
                                    ? AppDesignSystem.success
                                    : AppDesignSystem.info,
                              ),
                              SizedBox(
                                  width: ResponsiveHelper.responsiveSpacing(
                                      context,
                                      mobile: 4.0,
                                      desktop: 8.0)),
                              Flexible(
                                child: Text(
                                  isDelivered
                                      ? 'Teslim edildi'
                                      : isCreated
                                          ? 'Sipariş oluşturuldu'
                                          : order.statusText,
                                  style: AppDesignSystem.bodySmall.copyWith(
                                    fontSize:
                                        ResponsiveHelper.responsiveFontSize(
                                      context,
                                      mobile: 11.0,
                                      desktop: 12.0,
                                    ),
                                    fontWeight: FontWeight.w600,
                                    color: isDelivered
                                        ? AppDesignSystem.success
                                        : AppDesignSystem.info,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                          width: ResponsiveHelper.responsiveSpacing(context,
                              mobile: 4.0, desktop: 8.0)),
                      if (!isMobile)
                        Flexible(
                          child: Text(
                            isDelivered
                                ? '$totalProductQuantity ürün teslim edildi'
                                : isCreated
                                    ? '$totalProductQuantity ürün için sipariş oluşturuldu'
                                    : '',
                            style: AppDesignSystem.bodySmall.copyWith(
                              fontSize: ResponsiveHelper.responsiveFontSize(
                                context,
                                mobile: 11.0,
                                desktop: 12.0,
                              ),
                              color: AppDesignSystem.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      SizedBox(
                          width: ResponsiveHelper.responsiveSpacing(context,
                              mobile: 4.0, desktop: 8.0)),
                      // Detaylar butonu
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SiparisDetaySayfasi(order: order),
                            ),
                          );
                        },
                        style: AppDesignSystem.primaryButtonStyle(
                          padding: ResponsiveHelper.responsiveSpacing(context,
                              mobile: 10.0, desktop: 16.0),
                          borderRadius: AppDesignSystem.radiusS,
                        ),
                        child: Text(
                          'Detaylar',
                          style: AppDesignSystem.buttonSmall.copyWith(
                            fontSize: ResponsiveHelper.responsiveFontSize(
                              context,
                              mobile: 12.0,
                              desktop: 14.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  String _formatOrderDate(DateTime date) {
    final months = [
      '',
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }
}
