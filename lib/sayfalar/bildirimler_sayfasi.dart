import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../model/notification.dart';
import '../services/notification_service.dart';
import '../widgets/error_handler.dart';
import '../config/app_routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/responsive_helper.dart';

class BildirimlerSayfasi extends StatefulWidget {
  const BildirimlerSayfasi({super.key});

  @override
  State<BildirimlerSayfasi> createState() => _BildirimlerSayfasiState();
}

class _BildirimlerSayfasiState extends State<BildirimlerSayfasi>
    with TickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'all'; // 'all', 'order', 'promotion', 'payment', 'shipping'
  bool _showUnreadOnly = false;
  List<AppNotification> _allNotifications = [];
  String? _searchQuery;
  late AnimationController _filterAnimationController;

  @override
  void initState() {
    super.initState();
    _filterAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _filterAnimationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D10),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_auth.currentUser == null) ...[
            SliverFillRemaining(
              child: _buildGuestView(),
            ),
          ] else ...[
            _buildFilterSection(),
            _buildNotificationsList(),
          ],
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.05),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
        onPressed: () {
          // Ana sayfaya yönlendir
          AppRoutes.navigateToMain(context);
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Bildirimler',
          style: GoogleFonts.inter(
            color: const Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        IconButton(
          onPressed: _toggleUnreadFilter,
          icon: Icon(
            _showUnreadOnly ? Icons.filter_list : Icons.filter_list_off,
            color: Colors.white,
          ),
          tooltip: _showUnreadOnly ? 'Tümünü Göster' : 'Sadece Okunmamışlar',
        ),
        IconButton(
          onPressed: _markAllAsRead,
          icon: const Icon(Icons.done_all, color: Colors.white),
          tooltip: 'Tümünü Okundu İşaretle',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case 'settings':
                Navigator.pushNamed(context, AppRoutes.notificationSettings);
                break;
              case 'clear_all':
                _showClearAllDialog();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 20),
                  SizedBox(width: 8),
                  Text('Bildirim Ayarları'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear_all',
              child: Row(
                children: [
                  Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Tümünü Temizle', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGuestView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Bildirimleri görmek için giriş yapın',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              AppRoutes.navigateToLogin(context);
            },
            icon: const Icon(Icons.login),
            label: const Text('Giriş Yap'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final filters = [
      {'id': 'all', 'label': 'Tümü', 'icon': Icons.all_inclusive},
      {'id': 'order', 'label': 'Siparişler', 'icon': Icons.shopping_bag},
      {'id': 'promotion', 'label': 'Promosyonlar', 'icon': Icons.local_offer},
      {'id': 'payment', 'label': 'Ödeme', 'icon': Icons.payment},
      {'id': 'shipping', 'label': 'Kargo', 'icon': Icons.local_shipping},
    ];

    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Arama barı
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Bildirimlerde ara...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery != null && _searchQuery!.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = null;
                            });
                            _applyFilters();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.isEmpty ? null : value;
                  });
                  _applyFilters();
                },
              ),
            ),
            const SizedBox(height: 12),
            // Filtre butonları
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: filters.length,
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final isSelected = _selectedFilter == filter['id'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            filter['icon'] as IconData,
                            size: 16,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            filter['label'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? Colors.white : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter['id'] as String;
                        });
                        _applyFilters();
                      },
                      backgroundColor: Colors.grey[100],
                      selectedColor: Colors.blue[600],
                      checkmarkColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return StreamBuilder<List<AppNotification>>(
      stream: _notificationService.getUserNotifications(),
      builder: (context, snapshot) {
        // Debug: Stream durumunu logla
        debugPrint('📊 StreamBuilder durumu: connectionState=${snapshot.connectionState}, hasData=${snapshot.hasData}, hasError=${snapshot.hasError}, dataLength=${snapshot.data?.length ?? 0}');

        // İlk yükleme durumu - sadece hiç veri yoksa ve hala waiting durumundaysa
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData && !snapshot.hasError) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // Hata durumu
        if (snapshot.hasError) {
          debugPrint('❌ StreamBuilder hatası: ${snapshot.error}');
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Bildirimler yüklenirken hata oluştu',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
          );
        }

        // Veri yoksa boş liste kabul et (hasData false olsa bile)
        final allNotifications = snapshot.data ?? [];
        debugPrint('📋 Bildirim sayısı: ${allNotifications.length}');
        
        // Build sonrasında state'i güncelle
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final currentNotifications = _allNotifications;
              // Listeleri karşılaştır
              if (currentNotifications.length != allNotifications.length ||
                  !_areListsEqual(currentNotifications, allNotifications)) {
                setState(() {
                  _allNotifications = allNotifications;
                });
                _applyFilters();
              }
            }
          });
        }

        // Filtreleme yap (setState olmadan)
        final filteredNotifications = _getFilteredNotifications(allNotifications);

        // Boş durum kontrolü
        if (allNotifications.isEmpty && _searchQuery == null && _selectedFilter == 'all') {
          return SliverFillRemaining(
            child: _buildEmptyState(),
          );
        }

        // Filtre sonucu boş
        if (filteredNotifications.isEmpty) {
          return SliverFillRemaining(
            child: _buildNoResultsState(),
          );
        }

        // Bildirimleri göster
        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final notification = filteredNotifications[index];
                return _buildNotificationCard(notification, index);
              },
              childCount: filteredNotifications.length,
            ),
          ),
        );
      },
    );
  }

  bool _areListsEqual(List<AppNotification> list1, List<AppNotification> list2) {
    if (list1.length != list2.length) return false;
    if (list1.isEmpty) return true; // Boş listeler eşittir
    for (int i = 0; i < list1.length; i++) {
      if (i >= list2.length || list1[i].id != list2[i].id) return false;
    }
    return true;
  }

  List<AppNotification> _getFilteredNotifications(List<AppNotification> notifications) {
    final filtered = notifications.where((notification) {
      // Filtre kontrolü
      if (_selectedFilter != 'all' && notification.type != _selectedFilter) {
        return false;
      }

      // Okunmamış filtresi
      if (_showUnreadOnly && notification.isRead) {
        return false;
      }

      // Arama sorgusu
      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        final query = _searchQuery!.toLowerCase();
        if (!notification.title.toLowerCase().contains(query) &&
            !notification.body.toLowerCase().contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Tarihe göre sırala (en yeni önce)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return filtered;
  }

  void _applyFilters() {
    // StreamBuilder otomatik olarak yeniden build olacak
    // Sadece widget'ı yeniden build etmek için setState çağırıyoruz
    setState(() {});
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            'Henüz bildiriminiz yok',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kampanyalar, sipariş güncellemeleri ve\nözel teklifler burada görünecek',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Sonuç bulunamadı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Farklı bir arama terimi veya filtre deneyin',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red[400],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete, color: Colors.white, size: 28),
        ),
        confirmDismiss: (direction) async {
          return await _showDeleteDialog(notification);
        },
        onDismissed: (direction) {
          _deleteNotification(notification.id);
        },
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: notification.isRead ? 1 : 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () => _onNotificationTap(notification),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: notification.isRead
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue[50]!,
                          Colors.white,
                        ],
                      ),
                border: notification.isRead
                    ? null
                    : Border.all(color: Colors.blue[200]!, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // İkon
                      Hero(
                        tag: 'notification_icon_${notification.id}',
                        child: _buildNotificationIcon(notification),
                      ),
                      const SizedBox(width: 12),
                      // İçerik
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: notification.isRead
                                          ? FontWeight.w500
                                          : FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!notification.isRead)
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              notification.body,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            // Alt bilgiler ve aksiyonlar
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDateTime(notification.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                SizedBox(width: ResponsiveHelper.responsiveSpacing(context, mobile: 8.0, desktop: 12.0)),
                                _buildTypeChip(notification.type),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Özel içerik (kupon, sipariş bilgisi, vb.)
                  if (notification.data != null) ...[
                    const SizedBox(height: 12),
                    _buildNotificationContent(notification),
                  ],
                  // Aksiyon butonları
                  if (_hasActionButtons(notification)) ...[
                    const SizedBox(height: 12),
                    _buildActionButtons(notification),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(AppNotification notification) {
    IconData iconData;
    Color iconColor;
    Color backgroundColor;

    switch (notification.type) {
      case 'order':
        iconData = Icons.shopping_bag;
        iconColor = Colors.green[700]!;
        backgroundColor = Colors.green[100]!;
        break;
      case 'promotion':
        iconData = Icons.local_offer;
        iconColor = Colors.orange[700]!;
        backgroundColor = Colors.orange[100]!;
        break;
      case 'payment':
        iconData = Icons.payment;
        iconColor = Colors.blue[700]!;
        backgroundColor = Colors.blue[100]!;
        break;
      case 'shipping':
        iconData = Icons.local_shipping;
        iconColor = Colors.purple[700]!;
        backgroundColor = Colors.purple[100]!;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey[700]!;
        backgroundColor = Colors.grey[100]!;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  Widget _buildTypeChip(String type) {
    String label;
    Color color;

    switch (type) {
      case 'order':
        label = 'Sipariş';
        color = Colors.green;
        break;
      case 'promotion':
        label = 'Promosyon';
        color = Colors.orange;
        break;
      case 'payment':
        label = 'Ödeme';
        color = Colors.blue;
        break;
      case 'shipping':
        label = 'Kargo';
        color = Colors.purple;
        break;
      default:
        label = 'Sistem';
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildNotificationContent(AppNotification notification) {
    final data = notification.data ?? {};
    final couponCode = data['coupon_code'];
    final discount = data['discount'];
    final orderId = data['order_id'];
    final orderNumber = data['order_number'];
    final productId = data['product_id'];
    final productName = data['product_name'];
    final productImage = data['product_image'];
    final trackingNumber = data['tracking_number'];
    final amount = data['amount'];

    if (couponCode != null || discount != null) {
      return _buildCouponCard(couponCode, discount);
    }

    if (orderId != null || orderNumber != null) {
      return _buildOrderInfoCard(orderId, orderNumber, amount);
    }

    if (productId != null) {
      return _buildProductInfoCard(productId, productName, productImage);
    }

    if (trackingNumber != null) {
      return _buildTrackingCard(trackingNumber);
    }

    return const SizedBox.shrink();
  }

  Widget _buildCouponCard(String? couponCode, dynamic discount) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[100]!, Colors.red[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[300]!, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange[700],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_offer, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (couponCode != null) ...[
                  Text(
                    'Kupon Kodu',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    couponCode,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[900],
                      letterSpacing: 1.2,
                    ),
                  ),
                ] else if (discount != null) ...[
                  Text(
                    '%$discount İndirim',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[900],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Belirtilen kategoride geçerli',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (couponCode != null)
            IconButton(
              onPressed: () => _copyCouponCode(couponCode),
              icon: Icon(Icons.copy, color: Colors.orange[700], size: 20),
              tooltip: 'Kodu Kopyala',
            ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoCard(String? orderId, String? orderNumber, dynamic amount) {
    final String displayText;
    final String copyText;
    
    if (orderNumber != null) {
      displayText = 'Sipariş No: $orderNumber';
      copyText = orderNumber;
    } else if (orderId != null) {
      displayText = 'Sipariş ID: ${orderId.length > 8 ? orderId.substring(0, 8) : orderId}...';
      copyText = orderId;
    } else {
      return const SizedBox.shrink();
    }
    
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: copyText));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Sipariş numarası kopyalandı!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long, color: Colors.green[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[900],
                    ),
                  ),
                      ),
                      Icon(Icons.copy, size: 16, color: Colors.green[700]),
                ],
                  ),
                if (amount != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Tutar: ${amount.toStringAsFixed(2)} ₺',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildProductInfoCard(String? productId, String? productName, String? productImage) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Row(
        children: [
          if (productImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                productImage,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[300],
                  child: Icon(Icons.image, color: Colors.grey[500]),
                ),
              ),
            )
          else
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.shopping_bag, color: Colors.grey[500]),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName ?? 'Ürün',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[900],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingCard(String trackingNumber) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.local_shipping, color: Colors.purple[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Takip Numarası',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.purple[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  trackingNumber,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[900],
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasActionButtons(AppNotification notification) {
    final data = notification.data ?? {};
    final action = data['action'];
    final orderId = data['order_id'];
    final productId = data['product_id'];
    final couponCode = data['coupon_code'];
    
    return action != null || notification.actionUrl != null || 
           orderId != null || productId != null || couponCode != null;
  }

  Widget _buildActionButtons(AppNotification notification) {
    final data = notification.data ?? {};
    final action = data['action'];
    final orderId = data['order_id'];
    final productId = data['product_id'];
    final couponCode = data['coupon_code'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (action == 'view_order' || orderId != null)
          ElevatedButton.icon(
            onPressed: () => _handleViewOrder(orderId ?? data['order_number']),
            icon: const Icon(Icons.receipt_long, size: 16),
            label: const Text('Siparişi Gör'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        if (action == 'view_product' || productId != null)
          ElevatedButton.icon(
            onPressed: () => _handleViewProduct(productId),
            icon: const Icon(Icons.shopping_bag, size: 16),
            label: const Text('Ürünü Gör'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        if (couponCode != null)
          ElevatedButton.icon(
            onPressed: () => _handleUseCoupon(couponCode),
            icon: const Icon(Icons.shopping_cart, size: 16),
            label: const Text('Sepete Git'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  void _onNotificationTap(AppNotification notification) async {
    // Bildirimi okundu olarak işaretle
    if (!notification.isRead) {
      await _notificationService.markAsRead(notification.id);
    }

    // Detay modalı göster
    _showNotificationDetail(notification);
  }

  void _showNotificationDetail(AppNotification notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildNotificationIcon(notification),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDateTime(notification.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[800],
                          height: 1.6,
                        ),
                      ),
                      if (notification.data != null) ...[
                        const SizedBox(height: 16),
                        _buildNotificationContent(notification),
                      ],
                      if (_hasActionButtons(notification)) ...[
                        const SizedBox(height: 24),
                        _buildActionButtons(notification),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleViewOrder(String? orderId) async {
    if (orderId == null) return;

    Navigator.pop(context); // Modal'ı kapat

    try {
      // Firestore'dan siparişi bul
      final firestore = FirebaseFirestore.instance;
      final user = _auth.currentUser;
      if (user == null) return;

      // Önce order_number ile ara
      QuerySnapshot? orderSnapshot;
      try {
        orderSnapshot = await firestore
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .where('orderNumber', isEqualTo: orderId)
            .limit(1)
            .get();
      } catch (e) {
        // order_number yoksa id ile ara
        try {
          final orderDoc = await firestore
              .collection('orders')
              .doc(orderId)
              .get();
          
          if (orderDoc.exists) {
            final orderData = orderDoc.data()!;
            if (orderData['userId'] == user.uid) {
              // Order modelini oluştur ve navigate et
              // Bu kısım order modeline göre düzenlenebilir
              Navigator.pushNamed(context, AppRoutes.orders);
              return;
            }
          }
        } catch (e2) {
          debugPrint('Order not found: $e2');
        }
      }

      if (orderSnapshot != null && orderSnapshot.docs.isNotEmpty) {
        // Siparişler sayfasına git
        Navigator.pushNamed(context, AppRoutes.orders);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sipariş bulunamadı'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error navigating to order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleViewProduct(String? productId) async {
    if (productId == null) return;

    Navigator.pop(context); // Modal'ı kapat

    try {
      await AppRoutes.navigateToProductDetailById(context, productId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ürün açılamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleUseCoupon(String couponCode) async {
    Navigator.pop(context); // Modal'ı kapat
    await _copyCouponCode(couponCode);
    // Ana sayfaya git (sepet orada olacak)
    Navigator.pushNamed(context, AppRoutes.main);
  }

  void _toggleUnreadFilter() {
    setState(() {
      _showUnreadOnly = !_showUnreadOnly;
    });
    _applyFilters();
  }

  void _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tüm bildirimler okundu olarak işaretlendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Bildirimler işaretlenemedi: $e');
      }
    }
  }

  Future<bool?> _showDeleteDialog(AppNotification notification) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bildirimi Sil'),
        content: Text('Bu bildirimi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _deleteNotification(String notificationId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('notifications').doc(notificationId).delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bildirim silindi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Bildirim silinemedi: $e');
      }
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm Bildirimleri Temizle'),
        content: const Text(
          'Tüm bildirimleri silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllNotifications();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Tümünü Sil'),
          ),
        ],
      ),
    );
  }

  void _clearAllNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      final notifications = await firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tüm bildirimler temizlendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Bildirimler temizlenemedi: $e');
      }
    }
  }

  Future<void> _copyCouponCode(String couponCode) async {
    await Clipboard.setData(ClipboardData(text: couponCode));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kupon kodu kopyalandı: $couponCode'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Sepete Git',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.main);
            },
          ),
        ),
      );
    }
  }
}
