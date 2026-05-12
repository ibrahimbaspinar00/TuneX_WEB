import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/notification_settings_service.dart';
import '../config/app_routes.dart';

class BildirimAyarlariSayfasi extends StatefulWidget {
  const BildirimAyarlariSayfasi({super.key});

  @override
  State<BildirimAyarlariSayfasi> createState() => _BildirimAyarlariSayfasiState();
}

class _BildirimAyarlariSayfasiState extends State<BildirimAyarlariSayfasi> {
  final NotificationSettingsService _settingsService = NotificationSettingsService();
  
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _orderUpdates = true;
  bool _promotionalOffers = false;
  bool _priceAlerts = true;
  bool _newProductAlerts = true;
  bool _securityAlerts = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsService.getNotificationSettings();
      setState(() {
        _pushNotifications = settings['pushNotifications'] ?? true;
        _emailNotifications = settings['emailNotifications'] ?? true;
        _smsNotifications = settings['smsNotifications'] ?? false;
        _orderUpdates = settings['orderUpdates'] ?? true;
        _promotionalOffers = settings['promotionalOffers'] ?? false;
        _priceAlerts = settings['priceAlerts'] ?? true;
        _newProductAlerts = settings['newProductAlerts'] ?? true;
        _securityAlerts = settings['securityAlerts'] ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ayarlar yüklenemedi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFF0B0D10),
        appBar: AppBar(
          title: Text(
            'Ayarlar',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          shadowColor: Colors.black.withOpacity(0.05),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF0B0D10),
      appBar: AppBar(
        title: Text(
          'Bildirim Ayarları',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.05),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () {
            // Ana sayfaya yönlendir
            AppRoutes.navigateToMain(context);
          },
        ),
      ),
      body: Container(
        color: const Color(0xFF0B0D10),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Genel Bildirimler
                _buildNotificationSection(
                  title: 'Genel Bildirimler',
                  icon: Icons.notifications,
                  children: [
                    _buildSwitchTile(
                      title: 'Push Bildirimleri',
                      subtitle: 'Uygulama içi bildirimler',
                      value: _pushNotifications,
                      onChanged: (value) {
                        setState(() {
                          _pushNotifications = value;
                        });
                      },
                    ),
                    _buildSwitchTile(
                      title: 'E-posta Bildirimleri',
                      subtitle: 'E-posta ile bildirim al',
                      value: _emailNotifications,
                      onChanged: (value) {
                        setState(() {
                          _emailNotifications = value;
                        });
                      },
                    ),
                    _buildSwitchTile(
                      title: 'SMS Bildirimleri',
                      subtitle: 'SMS ile bildirim al',
                      value: _smsNotifications,
                      onChanged: (value) {
                        setState(() {
                          _smsNotifications = value;
                        });
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Sipariş Bildirimleri
                _buildNotificationSection(
                  title: 'Sipariş Bildirimleri',
                  icon: Icons.shopping_cart,
                  children: [
                    _buildSwitchTile(
                      title: 'Sipariş Güncellemeleri',
                      subtitle: 'Sipariş durumu değişiklikleri',
                      value: _orderUpdates,
                      onChanged: (value) {
                        setState(() {
                          _orderUpdates = value;
                        });
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Promosyon Bildirimleri
                _buildNotificationSection(
                  title: 'Promosyon Bildirimleri',
                  icon: Icons.local_offer,
                  children: [
                    _buildSwitchTile(
                      title: 'Promosyon Teklifleri',
                      subtitle: 'Özel indirim ve kampanyalar',
                      value: _promotionalOffers,
                      onChanged: (value) {
                        setState(() {
                          _promotionalOffers = value;
                        });
                      },
                    ),
                    _buildSwitchTile(
                      title: 'Fiyat Uyarıları',
                      subtitle: 'Favori ürünlerde fiyat değişiklikleri',
                      value: _priceAlerts,
                      onChanged: (value) {
                        setState(() {
                          _priceAlerts = value;
                        });
                      },
                    ),
                    _buildSwitchTile(
                      title: 'Yeni Ürün Uyarıları',
                      subtitle: 'Yeni ürün eklemeleri',
                      value: _newProductAlerts,
                      onChanged: (value) {
                        setState(() {
                          _newProductAlerts = value;
                        });
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Güvenlik Bildirimleri
                _buildNotificationSection(
                  title: 'Güvenlik Bildirimleri',
                  icon: Icons.security,
                  children: [
                    _buildSwitchTile(
                      title: 'Güvenlik Uyarıları',
                      subtitle: 'Hesap güvenliği ile ilgili bildirimler',
                      value: _securityAlerts,
                      onChanged: (value) {
                        setState(() {
                          _securityAlerts = value;
                        });
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
                
                // Kaydet Butonu
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange[600]!, Colors.orange[700]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Ayarları Kaydet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildNotificationSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.orange[600], size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.orange[600]!;
              }
              return Colors.grey[400]!;
            }),
            trackColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.orange[200]!;
              }
              return Colors.grey[200]!;
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    try {
      final settings = {
        'pushNotifications': _pushNotifications,
        'emailNotifications': _emailNotifications,
        'smsNotifications': _smsNotifications,
        'orderUpdates': _orderUpdates,
        'promotionalOffers': _promotionalOffers,
        'priceAlerts': _priceAlerts,
        'newProductAlerts': _newProductAlerts,
        'securityAlerts': _securityAlerts,
      };

      await _settingsService.saveNotificationSettings(settings);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Başarılı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ayarlar kaydedilemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}