import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_routes.dart';

class SaticiMesajlarimSayfasi extends StatefulWidget {
  const SaticiMesajlarimSayfasi({super.key});

  @override
  State<SaticiMesajlarimSayfasi> createState() => _SaticiMesajlarimSayfasiState();
}

class _SaticiMesajlarimSayfasiState extends State<SaticiMesajlarimSayfasi> {
  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: Colors.white,
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
          'Satıcı Mesajlarım',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F0F0F),
          ),
        ),
      ),
      body: _buildEmptyState(),
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
                Icons.mail_outline,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz mesajınız yok',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F0F0F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Satıcılarla mesajlaşmak için sipariş verdiğiniz ürünlerden birini seçin',
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

