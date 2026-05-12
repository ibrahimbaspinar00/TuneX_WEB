import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_routes.dart';

class KredilerSayfasi extends StatefulWidget {
  const KredilerSayfasi({super.key});

  @override
  State<KredilerSayfasi> createState() => _KredilerSayfasiState();
}

class _KredilerSayfasiState extends State<KredilerSayfasi> {
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
          'Krediler %0 Faiz Fırsatı',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F0F0F),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 80 : 24,
          vertical: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF6A00),
                    const Color(0xFFFF8C42),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '%0 Faiz Fırsatı',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Taksitli alışveriş yapın',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Kredi seçenekleri
            Text(
              'Kredi Seçenekleri',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F0F0F),
              ),
            ),
            const SizedBox(height: 16),
            _buildCreditOption(
              title: 'Taksitli Alışveriş',
              description: '3-12 ay arası taksit seçenekleri',
              icon: Icons.credit_card,
              color: const Color(0xFF00D1FF),
              onTap: () {
                _showCreditInfoDialog(
                  title: 'Taksitli Alışveriş',
                  description: '3, 6, 9 ve 12 ay taksit seçenekleri ile alışveriş yapabilirsiniz. %0 faiz fırsatından yararlanın!',
                );
              },
            ),
            const SizedBox(height: 12),
            _buildCreditOption(
              title: 'Hızlı Kredi',
              description: 'Anında onay, hızlı çözüm',
              icon: Icons.flash_on,
              color: const Color(0xFF18C964),
              onTap: () {
                _showCreditInfoDialog(
                  title: 'Hızlı Kredi',
                  description: 'Anında onay alın ve alışverişe başlayın. Kredi limitiniz belirlenir ve hemen kullanmaya başlayabilirsiniz.',
                );
              },
            ),
            const SizedBox(height: 12),
            _buildCreditOption(
              title: 'Kredi Kartı Taksit',
              description: 'Kredi kartınızla taksit yapın',
              icon: Icons.payment,
              color: const Color(0xFF8B5CF6),
              onTap: () {
                _showCreditInfoDialog(
                  title: 'Kredi Kartı Taksit',
                  description: 'Kredi kartınızla 2-12 ay arası taksit yapabilirsiniz. %0 faiz avantajından yararlanın!',
                );
              },
            ),
            const SizedBox(height: 32),
            // Bilgilendirme
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
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: const Color(0xFF00D1FF),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Önemli Bilgiler',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F0F0F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoItem('Kredi başvurusu için kimlik doğrulaması gereklidir'),
                  const SizedBox(height: 8),
                  _buildInfoItem('Kredi limiti gelir durumunuza göre belirlenir'),
                  const SizedBox(height: 8),
                  _buildInfoItem('Taksit seçenekleri ürün fiyatına göre değişiklik gösterebilir'),
                  const SizedBox(height: 8),
                  _buildInfoItem('%0 faiz kampanyası belirli ürünlerde geçerlidir'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditOption({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF2A3340),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F0F0F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFFC7CDD6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFF00D1FF),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFFC7CDD6),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  void _showCreditInfoDialog({required String title, required String description}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F0F0F),
          ),
        ),
        content: Text(
          description,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFFC7CDD6),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Kapat',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFF6A00),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Kredi başvurusu sayfasına yönlendirilebilir
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6A00),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Başvur',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

