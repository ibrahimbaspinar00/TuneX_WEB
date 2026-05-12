import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_data_service.dart';
import '../widgets/error_handler.dart';
import '../utils/responsive_helper.dart';
import '../config/app_routes.dart';

class OdemeYontemi {
  final String id;
  final String type; // 'card', 'bank', 'digital'
  final String name;
  final String number;
  final String expiryDate;
  final bool isDefault;

  OdemeYontemi({
    required this.id,
    required this.type,
    required this.name,
    required this.number,
    required this.expiryDate,
    this.isDefault = false,
  });
}

class OdemeYontemleriSayfasi extends StatefulWidget {
  final bool selectMode; // true ise bir yöntem seçip geri döndürür
  const OdemeYontemleriSayfasi({super.key, this.selectMode = false});

  @override
  State<OdemeYontemleriSayfasi> createState() => _OdemeYontemleriSayfasiState();
}

class _OdemeYontemleriSayfasiState extends State<OdemeYontemleriSayfasi> {
  final FirebaseDataService _firebaseDataService = FirebaseDataService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<OdemeYontemi> paymentMethods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() => _isLoading = true);
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          paymentMethods = [];
          _isLoading = false;
        });
        return;
      }

      final methodsData = await _firebaseDataService.getPaymentMethods();
      
      final methods = methodsData.map((data) {
        // Kart numarasını maskele
        final cardNumber = data['cardNumber']?.toString() ?? '';
        final maskedNumber = cardNumber.length > 4
            ? '**** ${cardNumber.substring(cardNumber.length - 4)}'
            : '**** ****';
        
        return OdemeYontemi(
          id: data['id']?.toString() ?? '',
          type: 'card', // Varsayılan olarak kart
          name: data['name']?.toString() ?? 'Kart',
          number: maskedNumber,
          expiryDate: data['expiryDate']?.toString() ?? '',
          isDefault: data['isDefault'] == true,
        );
      }).toList();

      if (mounted) {
        setState(() {
          paymentMethods = methods;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Ödeme yöntemleri yüklenirken hata: $e');
      if (mounted) {
        setState(() {
          paymentMethods = [];
          _isLoading = false;
        });
        ErrorHandler.showError(context, 'Ödeme yöntemleri yüklenirken hata oluştu');
      }
    }
  }

  String _getCardBrand(String cardNumber) {
    // Kart numarasının son 4 hanesinden marka tahmin et
    // Gerçek uygulamada kart numarasının ilk hanelerine bakılır
    if (cardNumber.isEmpty) return 'VISA';
    final lastDigit = cardNumber.length > 0 ? int.tryParse(cardNumber[cardNumber.length - 1]) ?? 0 : 0;
    if (lastDigit % 3 == 0) return 'VISA';
    if (lastDigit % 3 == 1) return 'Mastercard';
    return 'troy';
  }

  String _getCardBrandName(String cardNumber) {
    final brand = _getCardBrand(cardNumber);
    switch (brand) {
      case 'VISA':
        return 'VISA';
      case 'Mastercard':
        return 'Mastercard';
      case 'troy':
        return 'troy';
      default:
        return 'VISA';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Kayıtlı Kartlarım',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            // Ana sayfaya yönlendir
            AppRoutes.navigateToMain(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFF27A1A)),
            onPressed: _showAddCardDialog,
            tooltip: 'Yeni Kart Ekle',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık ve alt başlık
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kayıtlı Kartlarım',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kredi/Banka Kartlarım (${paymentMethods.length})',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 1),
                  
                  // Güvenlik banner'ı
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF18C964).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock, color: const Color(0xFF18C964), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Kayıtlı Kartlarınız Burada Güvende',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFFF6A00),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Kartlar listesi
                  if (paymentMethods.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.credit_card_off,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Henüz kart eklenmemiş',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Kart eklemek için sepet sayfasından ödeme yaparken kartınızı kaydedebilirsiniz.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: paymentMethods.length,
                        itemBuilder: (context, index) {
                          final method = paymentMethods[index];
                          final cardNumber = method.number.replaceAll('*', '').replaceAll(' ', '');
                          final last4Digits = cardNumber.length >= 4 
                              ? cardNumber.substring(cardNumber.length - 4)
                              : '';
                          final cardBrand = _getCardBrandName(cardNumber);
                          
                          return InkWell(
                            onTap: widget.selectMode
                                ? () => Navigator.pop(context, method)
                                : null,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Kart adı ve düzenle linki
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            method.name,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (!widget.selectMode)
                                          TextButton(
                                            onPressed: () => _editPaymentMethod(method),
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: const Size(0, 0),
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: Text(
                                              'Düzenle',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: const Color(0xFFF27A1A),
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(width: ResponsiveHelper.responsiveSpacing(context, mobile: 8.0, desktop: 12.0)),
                                    
                                    // Banka/kart logosu (basit gösterim)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        method.name.length > 10 
                                            ? method.name.substring(0, 10) 
                                            : method.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Maskelenmiş kart numarası
                                    Text(
                                      '**** $last4Digits ile biten kart',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Kart markası (VISA, Mastercard, troy)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            cardBrand,
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                        ),
                                        if (method.isDefault && !widget.selectMode)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.red[50],
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                            child: Text(
                                              'Trendyol Plus için geçerli kart',
                                              style: GoogleFonts.inter(
                                                fontSize: 8,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.red[700],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Güvenlik bilgisi kutusu
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF18C964).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kayıtlı Kartlarınız Burada Güvende',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF6A00),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Kartınızı kaydederken kullanmış olduğunuz telefon numarasından, aşağıdaki durumlarda SMS onayı istiyoruz.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildSecurityBulletPoint(
                          'Kartınızı kaydederken kullanmış olduğunuz adres dışında başka bir adres seçtiğinizde',
                        ),
                        const SizedBox(height: 8),
                        _buildSecurityBulletPoint(
                          'Kartınızı kaydederken kullanmış olduğunuz adres, e-posta veya telefon numarasında bir değişiklik yaptığınızda',
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSecurityBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6, right: 8),
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: Color(0xFFFF6A00),
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  void _editPaymentMethod(OdemeYontemi method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kartı Düzenle'),
        content: const Text('Kart düzenleme özelliği yakında eklenecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showAddCardDialog() {
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Kart Ekle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Kart Üzerindeki İsim',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: numberController,
                decoration: const InputDecoration(
                  labelText: 'Kart Numarası',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textCapitalization: TextCapitalization.none,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: expiryController,
                      decoration: const InputDecoration(
                        labelText: 'Son Kullanma (MM/YY)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      textCapitalization: TextCapitalization.none,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: cvvController,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      textCapitalization: TextCapitalization.none,
                      obscureText: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Kart bilgilerini kaydet
              if (nameController.text.isNotEmpty && 
                  numberController.text.isNotEmpty && 
                  expiryController.text.isNotEmpty && 
                  cvvController.text.isNotEmpty) {
                
                // Firestore'a kaydet
                try {
                  await _firebaseDataService.savePaymentMethod(
                    name: nameController.text.trim(),
                    cardNumber: numberController.text.trim(),
                    expiryDate: expiryController.text.trim(),
                    cvv: cvvController.text.trim(),
                    isDefault: paymentMethods.isEmpty, // İlk kart varsayılan olsun
                  );
                  
                  Navigator.of(context).pop();
                  
                  // Başarı mesajı göster
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Kart başarıyla kaydedildi!'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                  
                  // Kartları yeniden yükle
                  await _loadPaymentMethods();
                } catch (e) {
                  Navigator.of(context).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Kart kaydedilirken hata oluştu: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lütfen tüm alanları doldurun'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF27A1A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}
