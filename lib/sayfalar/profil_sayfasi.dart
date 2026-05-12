import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../model/product.dart';
import '../model/order.dart';
import '../providers/theme_provider.dart';
import '../services/firebase_data_service.dart';
import '../services/order_service.dart';
import '../services/external_image_upload_service.dart';
import '../config/external_image_storage_config.dart';
import '../theme/app_design_system.dart';
import '../widgets/image_cropper_widget.dart';
import 'adres_yonetimi_sayfasi.dart';
import 'odeme_yontemleri_sayfasi.dart';
import 'bildirim_ayarlari_sayfasi.dart';
import '../config/app_routes.dart';
import 'siparisler_sayfasi.dart';
import 'favoriler_sayfasi.dart';
import 'sepetim_sayfasi.dart';
import 'profil_duzenleme_sayfasi.dart';

class ProfilSayfasi extends StatefulWidget {
  final List<Product> favoriteProducts;
  final List<Product> cartProducts;
  final List<Order> orders;
  final Function(Product, {bool showMessage})? onFavoriteToggle;
  final Function(Product, {bool showMessage})? onAddToCart;
  final Function(Product)? onRemoveFromCart;
  final Function(Product, int)? onUpdateQuantity;
  final Function(List<Product>)? onPlaceOrder;
  final Function(List<Product>)? onOrderPlaced;

  const ProfilSayfasi({
    super.key,
    required this.favoriteProducts,
    required this.cartProducts,
    required this.orders,
    this.onFavoriteToggle,
    this.onAddToCart,
    this.onRemoveFromCart,
    this.onUpdateQuantity,
    this.onPlaceOrder,
    this.onOrderPlaced,
  });

  @override
  State<ProfilSayfasi> createState() => _ProfilSayfasiState();
}

class _ProfilSayfasiState extends State<ProfilSayfasi> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  final FirebaseDataService _dataService = FirebaseDataService();

  String? _profileImageUrl;
  String? _fullName;
  String? _username;
  String? _email;
  String? _phone;
  String? _address;

  // İstatistik verileri
  Map<String, dynamic> _userStats = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _dataService.getUserProfile();
      final userStats = await _dataService.getUserStats();

      if (mounted) {
        setState(() {
          if (userData != null) {
            _fullName = userData['fullName'] ?? '';
            _username = userData['username'] ?? '';
            _email = userData['email'] ?? '';
            _phone = userData['phone'] ?? '';
            _address = userData['address'] ?? '';
            _profileImageUrl = userData['profileImageUrl'];
          }
          _userStats = userStats;
        });
      }
    } catch (e) {
      // Kullanıcı bilgileri yüklenirken hata
    }
  }

  Future<void> _pickProfileImage() async {
    // Cloudinary ayarları kontrolü - erken çıkış
    if (!ExternalImageStorageConfig.enabled ||
        ExternalImageStorageConfig.cloudinaryCloudName == 'YOUR_CLOUD_NAME' ||
        ExternalImageStorageConfig.cloudinaryCloudName.isEmpty ||
        ExternalImageStorageConfig.cloudinaryUnsignedUploadPreset ==
            'YOUR_UPLOAD_PRESET' ||
        ExternalImageStorageConfig.cloudinaryUnsignedUploadPreset.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Profil fotoğrafı yükleme özelliği şu anda kullanılamıyor. Cloudinary ayarları yapılandırılmalıdır.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    try {
      // Web için özel kontrol
      if (kIsWeb) {
        // Web'de image picker kullan
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );

        if (image != null) {
          // Önce crop ekranını göster
          final imageBytes = await image.readAsBytes();
          await _showCropDialog(imageBytes);
        }
      } else {
        // Mobil platformlar için
        ImageSource? source;

        // Kullanıcıya seçenek sun (sadece mobilde)
        if (!kIsWeb) {
          source = await showModalBottomSheet<ImageSource>(
            context: context,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Galeriden Seç'),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                  if (!kIsWeb)
                    ListTile(
                      leading: const Icon(Icons.camera_alt),
                      title: const Text('Kamera ile Çek'),
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                    ),
                ],
              ),
            ),
          );
        } else {
          source = ImageSource.gallery;
        }

        if (source != null) {
          final XFile? image = await _picker.pickImage(
            source: source,
            maxWidth: 800,
            maxHeight: 800,
            imageQuality: 85,
          );

          if (image != null) {
            // Önce crop ekranını göster
            final imageBytes = await image.readAsBytes();
            await _showCropDialog(imageBytes);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        // Hata mesajını daha kullanıcı dostu yap
        String errorMessage = 'Profil fotoğrafı yüklenirken bir hata oluştu.';
        if (e.toString().contains('Cloudinary')) {
          errorMessage =
              'Cloudinary ayarları eksik. Lütfen yöneticiye başvurun.';
        } else if (e.toString().contains('boyutu')) {
          errorMessage = e.toString();
        } else {
          errorMessage = 'Bir hata oluştu. Lütfen tekrar deneyin.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Crop dialog'unu göster
  Future<void> _showCropDialog(Uint8List imageBytes) async {
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageCropperWidget(
          imageData: imageBytes,
          onCropComplete: (croppedData) async {
            // Crop edilmiş fotoğrafı yükle
            await _processAndUploadCroppedImage(croppedData);
          },
        ),
      ),
    );
  }

  /// Crop edilmiş fotoğrafı yükle
  Future<void> _processAndUploadCroppedImage(Uint8List croppedBytes) async {
    try {
      // Yükleme başladı mesajı
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Profil fotoğrafı yükleniyor...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Cloudinary (external) upload
      final String? downloadUrl = await _uploadProfileImageBytes(croppedBytes);

      if (downloadUrl != null) {
        // Kullanıcı profilini güncelle
        await _dataService.saveUserProfile(
          fullName: _fullName ?? '',
          username: _username ?? '',
          email: _email ?? '',
          phone: _phone,
          address: _address,
          profileImageUrl: downloadUrl,
        );

        if (mounted) {
          // Hemen setState ile güncelle (hemen görünsün)
          setState(() {
            _profileImageUrl = downloadUrl;
          });

          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Profil fotoğrafı başarıyla güncellendi!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Profil fotoğrafı yüklenemedi. Lütfen tekrar deneyin.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Hata mesajını daha kullanıcı dostu yap
        String errorMessage = 'Profil fotoğrafı yüklenirken bir hata oluştu.';
        if (e.toString().contains('Cloudinary')) {
          errorMessage =
              'Cloudinary ayarları eksik. Lütfen yöneticiye başvurun.';
        } else if (e.toString().contains('boyutu')) {
          errorMessage = e.toString().replaceAll('Exception: ', '');
        } else {
          errorMessage = 'Bir hata oluştu. Lütfen tekrar deneyin.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Bytes'tan direkt yükleme (crop edilmiş fotoğraf için)
  Future<String?> _uploadProfileImageBytes(Uint8List bytes) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      if (bytes.isEmpty) return null;

      // Basic size guard (3MB)
      const maxSize = 3 * 1024 * 1024;
      if (bytes.length > maxSize) {
        throw Exception('Dosya boyutu çok büyük. Maksimum 3MB olmalıdır.');
      }

      // Cloudinary ayarları kontrolü
      if (!ExternalImageStorageConfig.enabled) {
        throw Exception(
            'Profil fotoğrafı yükleme özelliği şu anda devre dışı. Cloudinary ayarları yapılandırılmalıdır.');
      }

      if (ExternalImageStorageConfig.cloudinaryCloudName == 'YOUR_CLOUD_NAME' ||
          ExternalImageStorageConfig.cloudinaryCloudName.isEmpty) {
        throw Exception(
            'Cloudinary ayarları eksik. Lütfen https://console.cloudinary.com/ adresinden ücretsiz hesap oluşturup cloud name alın ve `lib/config/external_image_storage_config.dart` dosyasına ekleyin.');
      }

      if (ExternalImageStorageConfig.cloudinaryUnsignedUploadPreset ==
              'YOUR_UPLOAD_PRESET' ||
          ExternalImageStorageConfig.cloudinaryUnsignedUploadPreset.isEmpty) {
        throw Exception(
            'Cloudinary upload preset ayarlı değil. Cloudinary dashboard\'da Settings > Upload > Upload presets bölümünden unsigned preset oluşturun ve `lib/config/external_image_storage_config.dart` dosyasına ekleyin.');
      }

      // Cloudinary'ye yükle
      final external = ExternalImageUploadService();
      final url = await external.uploadImageBytes(
        bytes: bytes,
        fileName:
            'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        folder: ExternalImageStorageConfig.cloudinaryProfileFolder,
      );

      return url;
    } catch (e) {
      debugPrint('Profil fotoğrafı upload hatası: $e');
      rethrow; // Hata mesajını yukarı fırlat
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          resizeToAvoidBottomInset: false, // Klavye performansı için
          body: Container(
            decoration: BoxDecoration(
              gradient: context.appTheme.pageGradient,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Dil değiştirme özelliği kaldırıldı
                    // Üst profil kartı
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(24),
                      decoration: _sectionDecoration(),
                      child: Column(
                        children: [
                          // Profil fotoğrafı
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple[400]!,
                                  Colors.blue[400]!
                                ],
                              ),
                            ),
                            child: Stack(
                              children: [
                                GestureDetector(
                                  onTap: (ExternalImageStorageConfig.enabled &&
                                          ExternalImageStorageConfig
                                              .cloudinaryCloudName.isNotEmpty &&
                                          ExternalImageStorageConfig
                                                  .cloudinaryCloudName !=
                                              'YOUR_CLOUD_NAME' &&
                                          ExternalImageStorageConfig
                                              .cloudinaryUnsignedUploadPreset
                                              .isNotEmpty &&
                                          ExternalImageStorageConfig
                                                  .cloudinaryUnsignedUploadPreset !=
                                              'YOUR_UPLOAD_PRESET')
                                      ? _pickProfileImage
                                      : null,
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.grey[100],
                                    backgroundImage:
                                        (_profileImageUrl != null &&
                                                _profileImageUrl!.isNotEmpty)
                                            ? NetworkImage(_profileImageUrl!)
                                            : null,
                                    child: _profileImageUrl == null
                                        ? Icon(
                                            Icons.person,
                                            size: 50,
                                            color: Colors.grey[400],
                                          )
                                        : null,
                                  ),
                                ),
                                // Kamera ikonu overlay (sadece Cloudinary ayarlıysa tıklanabilir)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: (ExternalImageStorageConfig
                                                .enabled &&
                                            ExternalImageStorageConfig
                                                .cloudinaryCloudName
                                                .isNotEmpty &&
                                            ExternalImageStorageConfig
                                                    .cloudinaryCloudName !=
                                                'YOUR_CLOUD_NAME' &&
                                            ExternalImageStorageConfig
                                                .cloudinaryUnsignedUploadPreset
                                                .isNotEmpty &&
                                            ExternalImageStorageConfig
                                                    .cloudinaryUnsignedUploadPreset !=
                                                'YOUR_UPLOAD_PRESET')
                                        ? _pickProfileImage
                                        : null,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: (ExternalImageStorageConfig
                                                    .enabled &&
                                                ExternalImageStorageConfig
                                                    .cloudinaryCloudName
                                                    .isNotEmpty &&
                                                ExternalImageStorageConfig
                                                        .cloudinaryCloudName !=
                                                    'YOUR_CLOUD_NAME' &&
                                                ExternalImageStorageConfig
                                                    .cloudinaryUnsignedUploadPreset
                                                    .isNotEmpty &&
                                                ExternalImageStorageConfig
                                                        .cloudinaryUnsignedUploadPreset !=
                                                    'YOUR_UPLOAD_PRESET')
                                            ? Colors.blue[600]
                                            : Colors.grey[400],
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _fullName?.isNotEmpty == true
                                ? _fullName!
                                : 'Misafir Kullanıcı',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: context.appTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _email?.isNotEmpty == true
                                ? _email!
                                : 'Giriş yapılmadı',
                            style: TextStyle(
                              fontSize: 16,
                              color: context.appTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_username?.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text(
                              '@$_username',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.purple[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (_phone?.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text(
                              '📞 $_phone',
                              style: TextStyle(
                                fontSize: 14,
                                color: context.appTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (_address?.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text(
                              '📍 $_address',
                              style: TextStyle(
                                fontSize: 14,
                                color: context.appTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          // Giriş/Kayıt butonları veya Çıkış butonu
                          if (_auth.currentUser == null) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.purple[600]!,
                                          Colors.blue[600]!
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.purple.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Kayıt sayfasına yönlendiriliyor...')),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      icon: const Icon(Icons.person_add,
                                          color: Colors.white),
                                      label: Text(
                                        'Kayıt Ol',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.purple[600]!, width: 2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: _auth.currentUser == null
                                          ? () async {
                                              await AppRoutes.navigateToLogin(
                                                  context);
                                              // Giriş sayfasından döndükten sonra kullanıcı bilgilerini yeniden yükle
                                              if (mounted) {
                                                await _loadUserData();
                                              }
                                            }
                                          : () async {
                                              await _auth.signOut();
                                              if (mounted) {
                                                // Başlangıç sayfasına (LandingPage) yönlendir
                                                AppRoutes.navigateToLanding(
                                                    context);
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      icon: Icon(Icons.login,
                                          color: Colors.purple[600]),
                                      label: Text(
                                        _auth.currentUser == null
                                            ? 'Giriş Yap'
                                            : 'Çıkış Yap',
                                        style: TextStyle(
                                          color: Colors.purple[600],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Kullanıcı İstatistikleri
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(24),
                      decoration: _sectionDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hesap İstatistikleri',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: context.appTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.favorite,
                                  title: 'Favori Ürün',
                                  value: '${_userStats['favoriteCount'] ?? 0}',
                                  color: Colors.red,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FavorilerSayfasi(
                                          favoriteProducts:
                                              widget.favoriteProducts,
                                          onFavoriteToggle: widget
                                                  .onFavoriteToggle ??
                                              (product,
                                                  {bool showMessage = true}) {},
                                          onAddToCart: widget.onAddToCart,
                                          cartProducts: widget.cartProducts,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.shopping_cart,
                                  title: 'Sepet Tutarı',
                                  value:
                                      '${(_userStats['cartTotal'] ?? 0.0).toStringAsFixed(2)} TL',
                                  color: Colors.green,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SepetimSayfasi(
                                          cartProducts: widget.cartProducts,
                                          onRemoveFromCart:
                                              widget.onRemoveFromCart!,
                                          onUpdateQuantity:
                                              widget.onUpdateQuantity!,
                                          onPlaceOrder: () =>
                                              widget.onPlaceOrder!(
                                                  widget.cartProducts),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.star,
                                  title: 'Toplam Harcama',
                                  value:
                                      '${(_userStats['totalSpent'] ?? 0.0).toStringAsFixed(2)} TL',
                                  color: Colors.orange,
                                  onTap: () {
                                    _openOrdersPage();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Hesap Yönetimi
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(24),
                      decoration: _sectionDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hesap Yönetimi',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: context.appTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildAccountTile(
                            icon: Icons.receipt_long,
                            title: 'Siparişlerim',
                            subtitle: 'Tüm geçmiş ve aktif siparişler',
                            onTap: _openOrdersPage,
                          ),
                          _buildAccountTile(
                            icon: Icons.person,
                            title: 'Profil Bilgileri',
                            subtitle: 'Ad, soyad, e-posta düzenle',
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ProfilDuzenlemeSayfasi(),
                                ),
                              );
                              // Profil güncellendiyse verileri yeniden yükle
                              if (result == true) {
                                _loadUserData();
                              }
                            },
                          ),
                          _buildAccountTile(
                            icon: Icons.location_on,
                            title: 'Adreslerim',
                            subtitle: 'Teslimat adreslerini yönet',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AdresYonetimiSayfasi(),
                                ),
                              );
                            },
                          ),
                          _buildAccountTile(
                            icon: Icons.credit_card,
                            title: 'Ödeme Yöntemleri',
                            subtitle: 'Kart ve ödeme bilgileri',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const OdemeYontemleriSayfasi(),
                                ),
                              );
                            },
                          ),
                          if (_auth.currentUser != null)
                            _buildAccountTile(
                              icon: Icons.logout,
                              title: 'Çıkış Yap',
                              subtitle: 'Hesabından çıkış yap',
                              onTap: () {
                                _showLogoutDialog();
                              },
                              isDestructive: true,
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Sosyal Medya ve İletişim
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(24),
                      decoration: _sectionDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sosyal Medya & İletişim',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: context.appTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSocialButton(
                                  icon: Icons.facebook,
                                  label: 'Facebook',
                                  color: Colors.blue[600]!,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Facebook sayfasına yönlendiriliyor...')),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSocialButton(
                                  icon: Icons.camera_alt,
                                  label: 'Instagram',
                                  color: Colors.pink[600]!,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Instagram sayfasına yönlendiriliyor...')),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSocialButton(
                                  icon: Icons.alternate_email,
                                  label: 'Twitter',
                                  color: Colors.blue[400]!,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Twitter sayfasına yönlendiriliyor...')),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSocialButton(
                                  icon: Icons.phone,
                                  label: 'İletişim',
                                  color: Colors.green[600]!,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'İletişim bilgileri gösteriliyor...')),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Ayarlar kartı
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(24),
                      decoration: _sectionDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ayarlar',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: context.appTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildThemeTile(themeProvider),
                          const SizedBox(height: 12),
                          _buildSettingTile(
                            icon: Icons.notifications,
                            title: 'Bildirim Ayarları',
                            subtitle: 'Bildirimleri yönet',
                            themeProvider: themeProvider,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const BildirimAyarlariSayfasi(),
                                ),
                              );
                            },
                          ),
                          _buildSettingTile(
                            icon: Icons.lock,
                            title: 'Gizlilik Ayarları',
                            subtitle: 'Hesap güvenliği',
                            themeProvider: themeProvider,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Gizlilik ayarları tıklandı')),
                              );
                            },
                          ),
                          _buildSettingTile(
                            icon: Icons.info,
                            title: 'Uygulama Hakkında',
                            subtitle: 'Versiyon ve bilgiler',
                            themeProvider: themeProvider,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Uygulama hakkında tıklandı')),
                              );
                            },
                          ),
                          _buildSettingTile(
                            icon: Icons.help,
                            title: 'Yardım & Destek',
                            subtitle: 'Sorularınız için',
                            themeProvider: themeProvider,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Yardım & Destek tıklandı')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    final colors = context.appTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: colors.isDark ? 0.16 : 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeTile(ThemeProvider themeProvider) {
    final colors = context.appTheme;
    final themeIcon = switch (themeProvider.themeMode) {
      ThemeMode.dark => Icons.dark_mode,
      ThemeMode.system => Icons.brightness_auto,
      ThemeMode.light => Icons.light_mode,
    };
    final themeSubtitle = switch (themeProvider.themeMode) {
      ThemeMode.dark => 'Koyu premium görünüm aktif',
      ThemeMode.system =>
        'Sistem ayarı izleniyor${themeProvider.isDarkMode ? ' • koyu görünüm uygulanıyor' : ' • açık görünüm uygulanıyor'}',
      ThemeMode.light => 'Açık sade görünüm aktif',
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        gradient: colors.isDark
            ? LinearGradient(
                colors: [
                  colors.surfaceInteractive,
                  colors.surfaceElevated,
                ],
              )
            : LinearGradient(
                colors: [
                  colors.surfaceElevated,
                  colors.accentSoft,
                ],
              ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: colors.softShadow,
      ),
      child: ListTile(
        onTap: () {
          _showThemeModeSheet(themeProvider);
        },
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: colors.accentGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            themeIcon,
            color: colors.textInverse,
            size: 20,
          ),
        ),
        title: Text(
          'Tema Modu',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        subtitle: Text(
          themeSubtitle,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing: Switch.adaptive(
          value: themeProvider.themeMode == ThemeMode.dark,
          onChanged: (value) {
            themeProvider.setThemeMode(
              value ? ThemeMode.dark : ThemeMode.light,
            );
          },
        ),
      ),
    );
  }

  Future<void> _showThemeModeSheet(ThemeProvider themeProvider) async {
    final colors = context.appTheme;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.modalSurface,
      showDragHandle: true,
      builder: (sheetContext) {
        final sheetColors = sheetContext.appTheme;

        Widget optionTile({
          required ThemeMode mode,
          required String title,
          required String subtitle,
          required IconData icon,
        }) {
          final selected = themeProvider.themeMode == mode;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: selected
                  ? sheetColors.accentSoft
                  : sheetColors.surfaceInteractive,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? sheetColors.accent : sheetColors.borderSubtle,
              ),
            ),
            child: ListTile(
              leading: Icon(
                icon,
                color:
                    selected ? sheetColors.accent : sheetColors.textSecondary,
              ),
              title: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: sheetColors.textPrimary,
                ),
              ),
              subtitle: Text(
                subtitle,
                style: TextStyle(
                  color: sheetColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              trailing: Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? sheetColors.accent : sheetColors.textMuted,
              ),
              onTap: () async {
                await themeProvider.setThemeMode(mode);
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
              },
            ),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tema Seçimi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: sheetColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Mevcut düzen korunur, yalnızca renk paleti değiştirilir.',
                  style: TextStyle(
                    fontSize: 13,
                    color: sheetColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                optionTile(
                  mode: ThemeMode.light,
                  title: 'Açık Tema',
                  subtitle: 'Temiz, ferah ve beyaz ağırlıklı görünüm',
                  icon: Icons.light_mode,
                ),
                optionTile(
                  mode: ThemeMode.dark,
                  title: 'Koyu Tema',
                  subtitle: 'Grafit tabanlı premium dark mode görünümü',
                  icon: Icons.dark_mode,
                ),
                optionTile(
                  mode: ThemeMode.system,
                  title: 'Sistem',
                  subtitle: 'Cihaz temasını otomatik takip eder',
                  icon: Icons.brightness_auto,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _sectionDecoration() {
    final colors = context.appTheme;
    return AppDesignSystem.cardDecoration(
      context: context,
      borderRadius: 24,
      shadows: colors.mediumShadow,
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeProvider themeProvider,
  }) {
    final colors = context.appTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surfaceInteractive,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.accentSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: colors.accent, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: colors.textMuted,
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _openOrdersPage() async {
    try {
      final orders = await OrderService().getUserOrders();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SiparislerSayfasi(
            orders: orders,
            onOrderPlaced: widget.onOrderPlaced,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SiparislerSayfasi(
            orders: widget.orders,
            onOrderPlaced: widget.onOrderPlaced,
          ),
        ),
      );
    }
  }

  Widget _buildAccountTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool isAdmin = false,
  }) {
    final colors = context.appTheme;
    final tileColor = isDestructive
        ? colors.error.withValues(alpha: colors.isDark ? 0.16 : 0.08)
        : isAdmin
            ? colors.accent.withValues(alpha: colors.isDark ? 0.14 : 0.08)
            : colors.surfaceInteractive;
    final borderColor = isDestructive
        ? colors.error.withValues(alpha: 0.28)
        : isAdmin
            ? colors.accent.withValues(alpha: 0.24)
            : colors.borderSubtle;
    final iconColor = isDestructive
        ? colors.error
        : isAdmin
            ? colors.accent
            : colors.accentSecondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDestructive ? colors.error : colors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDestructive ? colors.error : colors.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDestructive ? colors.error : colors.textMuted,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog() {
    final parentContext = context;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Çıkış Yap'),
          content: const Text(
              'Hesabınızdan çıkış yapmak istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await _auth.signOut();
                } catch (_) {}
                if (mounted) {
                  // Başlangıç sayfasına (LandingPage) yönlendir
                  AppRoutes.navigateToLanding(parentContext);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Çıkış Yap'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colors = context.appTheme;
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: color.withValues(alpha: colors.isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
