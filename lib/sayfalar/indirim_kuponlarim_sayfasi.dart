import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_routes.dart';

class IndirimKuponlarimSayfasi extends StatefulWidget {
  const IndirimKuponlarimSayfasi({super.key});

  @override
  State<IndirimKuponlarimSayfasi> createState() => _IndirimKuponlarimSayfasiState();
}

class _IndirimKuponlarimSayfasiState extends State<IndirimKuponlarimSayfasi> {
  // Demo kuponlar
  final List<Map<String, dynamic>> _coupons = [
    {
      'code': 'WELCOME10',
      'title': 'Hoş Geldin İndirimi',
      'description': '%10 indirim kazanın',
      'discount': 10,
      'type': 'percentage',
      'expiryDate': DateTime.now().add(const Duration(days: 30)),
      'isUsed': false,
      'minPurchase': 100.0,
    },
    {
      'code': 'SAVE20',
      'title': 'Büyük İndirim',
      'description': '%20 indirim kazanın',
      'discount': 20,
      'type': 'percentage',
      'expiryDate': DateTime.now().add(const Duration(days: 15)),
      'isUsed': false,
      'minPurchase': 200.0,
    },
    {
      'code': 'FREESHIP',
      'title': 'Ücretsiz Kargo',
      'description': 'Tüm siparişlerde ücretsiz kargo',
      'discount': 0,
      'type': 'shipping',
      'expiryDate': DateTime.now().add(const Duration(days: 7)),
      'isUsed': true,
      'minPurchase': 0.0,
    },
    {
      'code': 'DISCOUNT15',
      'title': 'Özel İndirim',
      'description': '%15 indirim kazanın',
      'discount': 15,
      'type': 'percentage',
      'expiryDate': DateTime.now().add(const Duration(days: 5)),
      'isUsed': false,
      'minPurchase': 150.0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D10),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F0F0F)),
          onPressed: () {
            // Ana sayfaya yönlendir
            AppRoutes.navigateToMain(context);
          },
        ),
        title: Text(
          'İndirim Kuponlarım',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F0F0F),
          ),
        ),
      ),
      body: _coupons.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 80 : 24,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kupon ekleme alanı
                  Container(
                    padding: const EdgeInsets.all(20),
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
                      children: [
                        Text(
                          'Kupon Kodu Ekle',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F0F0F),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Kupon kodunu girin',
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: const Color(0xFF8E98A8),
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
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                // Kupon ekleme işlemi
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6A00),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Ekle',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Aktif kuponlar
                  Text(
                    'Aktif Kuponlarım',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F0F0F),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._coupons.map((coupon) => _buildCouponCard(coupon)),
                ],
              ),
            ),
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> coupon) {
    final isUsed = coupon['isUsed'] as bool;
    final isExpired = (coupon['expiryDate'] as DateTime).isBefore(DateTime.now());
    final daysLeft = (coupon['expiryDate'] as DateTime).difference(DateTime.now()).inDays;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUsed || isExpired
              ? const Color(0xFF2A3340)
              : const Color(0xFFFF6A00),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Kupon içeriği
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isUsed || isExpired
                  ? Colors.grey[50]
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // Sol taraf - İndirim bilgisi
                Container(
                  width: 100,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUsed || isExpired
                        ? Colors.grey[200]
                        : const Color(0xFFFF6A00).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (coupon['type'] == 'percentage')
                        Text(
                          '%${coupon['discount']}',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: isUsed || isExpired
                                ? Colors.grey[600]
                                : const Color(0xFFFF6A00),
                          ),
                        )
                      else
                        Icon(
                          Icons.local_shipping,
                          size: 32,
                          color: isUsed || isExpired
                              ? Colors.grey[600]
                              : const Color(0xFFFF6A00),
                        ),
                      if (coupon['type'] == 'shipping')
                        Text(
                          'Ücretsiz',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isUsed || isExpired
                                ? Colors.grey[600]
                                : const Color(0xFFFF6A00),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Sağ taraf - Kupon detayları
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon['title'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isUsed || isExpired
                              ? Colors.grey[600]
                              : const Color(0xFF0F0F0F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        coupon['description'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFFC7CDD6),
                        ),
                      ),
                      if (coupon['minPurchase'] > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Min. ${coupon['minPurchase']}₺ alışveriş',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF8E98A8),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: isExpired
                                ? Colors.red[400]
                                : const Color(0xFFC7CDD6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isExpired
                                ? 'Süresi doldu'
                                : daysLeft > 0
                                    ? '$daysLeft gün kaldı'
                                    : 'Bugün son gün',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isExpired
                                  ? Colors.red[400]
                                  : const Color(0xFFC7CDD6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Kupon kodu
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isUsed || isExpired
                        ? Colors.grey[200]
                        : const Color(0xFFFF6A00).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'KOD',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isUsed || isExpired
                              ? Colors.grey[600]
                              : const Color(0xFFFF6A00),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        coupon['code'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isUsed || isExpired
                              ? Colors.grey[600]
                              : const Color(0xFFFF6A00),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Kullanıldı etiketi
          if (isUsed)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Kullanıldı',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_offer_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz kuponunuz yok',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F0F0F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kampanyalardan haberdar olmak için bildirimleri açın',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFFC7CDD6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

