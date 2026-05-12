import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';

/// Profesyonel resim yükleme widget'ı
/// Web ve mobil uyumlu
class ProfessionalImageUploader extends StatefulWidget {
  final String? currentImageUrl;
  final Function(String imageUrl) onImageSelected;
  final String? label;
  final double? width;
  final double? height;

  const ProfessionalImageUploader({
    super.key,
    this.currentImageUrl,
    required this.onImageSelected,
    this.label,
    this.width,
    this.height,
  });

  @override
  State<ProfessionalImageUploader> createState() => _ProfessionalImageUploaderState();
}

class _ProfessionalImageUploaderState extends State<ProfessionalImageUploader> {
  String? _imageUrl;
  bool _isUploading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.currentImageUrl;
  }

  @override
  void didUpdateWidget(ProfessionalImageUploader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentImageUrl != oldWidget.currentImageUrl) {
      _imageUrl = widget.currentImageUrl;
    }
  }

  Future<void> _pickImage() async {
    try {
      if (kIsWeb) {
        // Web için HTML file input
        final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
        uploadInput.accept = 'image/*';
        uploadInput.click();

        uploadInput.onChange.listen((e) {
          final files = uploadInput.files;
          if (files != null && files.isNotEmpty) {
            final file = files[0];
            final reader = html.FileReader();

            reader.onLoadEnd.listen((e) {
              if (reader.result != null) {
                final bytes = reader.result as Uint8List;
                _handleImageSelected(bytes, file.name);
              }
            });

            reader.readAsArrayBuffer(file);
          }
        });
      } else {
        // Mobil için image_picker kullanılabilir
        // Şimdilik web odaklı olduğu için bu kısım boş bırakıldı
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mobil platform desteği yakında eklenecek'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Resim seçme hatası: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Resim seçilirken bir hata oluştu';
        });
      }
    }
  }

  Future<void> _handleImageSelected(Uint8List bytes, String fileName) async {
    if (!mounted) return;

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final storageService = StorageService();
      final uploadedUrl = await storageService.uploadProductImage(bytes, fileName);

      if (!mounted) return;

      setState(() {
        _imageUrl = uploadedUrl;
        _isUploading = false;
      });

      widget.onImageSelected(uploadedUrl);
    } catch (e) {
      debugPrint('❌ Resim yükleme hatası: $e');
      if (!mounted) return;

      setState(() {
        _isUploading = false;
        _errorMessage = 'Resim yüklenirken bir hata oluştu: ${e.toString()}';
      });
    }
  }

  void _removeImage() {
    setState(() {
      _imageUrl = null;
      _errorMessage = null;
    });
    widget.onImageSelected('');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F0F0F),
            ),
          ),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: _isUploading ? null : _pickImage,
          child: Container(
            width: widget.width ?? double.infinity,
            height: widget.height ?? 200,
            decoration: BoxDecoration(
              color: _imageUrl != null ? Colors.transparent : const Color(0xFF0B0D10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _errorMessage != null
                    ? Colors.red
                    : _imageUrl != null
                        ? Colors.transparent
                        : const Color(0xFF2A3340),
                width: 2,
              ),
            ),
            child: _isUploading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _imageUrl != null && _imageUrl!.isNotEmpty
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              _imageUrl!,
                              width: widget.width ?? double.infinity,
                              height: widget.height ?? 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: widget.width ?? double.infinity,
                                  height: widget.height ?? 200,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: _removeImage,
                                tooltip: 'Resmi Kaldır',
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Yeni Resim Seç',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Resim Yükle',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFC7CDD6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tıklayarak resim seçin',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.red,
            ),
          ),
        ],
      ],
    );
  }
}

