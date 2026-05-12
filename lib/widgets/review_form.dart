import 'dart:typed_data';
import 'package:flutter/material.dart';
// Web için image_picker - web desteği var
import 'package:image_picker/image_picker.dart';
// dart:io web'de çalışmaz, artık kullanmıyoruz çünkü Image.memory kullanıyoruz
import '../services/review_service.dart';
import '../services/storage_service.dart';
import '../model/product_review.dart';
import 'star_rating.dart';
import '../theme/app_design_system.dart';

class ReviewForm extends StatefulWidget {
  final String productId;
  final VoidCallback onReviewAdded;
  final bool hasPurchased;
  final ProductReview? existingReview; // Düzenleme modu için

  const ReviewForm({
    super.key,
    required this.productId,
    required this.onReviewAdded,
    this.hasPurchased = false,
    this.existingReview, // null ise yeni yorum, dolu ise düzenleme
  });

  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  late TextEditingController _commentController;
  late int _selectedRating;
  bool _isSubmitting = false;
  List<XFile> _selectedImages = [];
  List<String> _existingImageUrls = []; // Düzenleme modunda mevcut resimler
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();
  Map<int, Uint8List> _imageBytesCache = {}; // XFile bytes cache

  @override
  void initState() {
    super.initState();
    // Düzenleme modunda mevcut verileri yükle
    if (widget.existingReview != null) {
      _commentController =
          TextEditingController(text: widget.existingReview!.comment);
      _selectedRating = widget.existingReview!.rating;
      _existingImageUrls = List.from(widget.existingReview!.imageUrls);
    } else {
      _commentController = TextEditingController();
      _selectedRating = 0;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _imageBytesCache.clear();
    super.dispose();
  }

  /// XFile'dan görüntü widget'ı oluştur (web ve mobil uyumlu)
  Widget _buildImageWidget(XFile imageFile, int index) {
    // Hem web hem mobil için Image.memory kullan (XFile'dan bytes oku)
    return FutureBuilder<Uint8List>(
      future: _getImageBytes(imageFile, index),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: 100,
            height: 100,
            color: AppDesignSystem.borderMedium,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          );
        }
        return Container(
          width: 100,
          height: 100,
          color: AppDesignSystem.borderMedium,
          child: const Icon(Icons.error),
        );
      },
    );
  }

  /// XFile'dan bytes al (cache'li)
  Future<Uint8List> _getImageBytes(XFile imageFile, int index) async {
    if (_imageBytesCache.containsKey(index)) {
      return _imageBytesCache[index]!;
    }
    final bytes = await imageFile.readAsBytes();
    _imageBytesCache[index] = bytes;
    return bytes;
  }

  Future<void> _submitReview() async {
    debugPrint('=== YORUM GÖNDERME BAŞLADI ===');
    debugPrint('hasPurchased: ${widget.hasPurchased}');
    debugPrint('selectedRating: $_selectedRating');
    debugPrint('comment length: ${_commentController.text.trim().length}');

    // Satın alma kontrolü - sadece sipariş verilen ürünlere yorum yapılabilir
    if (!widget.hasPurchased) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.shopping_cart,
                  color: AppDesignSystem.textOnPrimary, size: 20),
              SizedBox(width: 8),
              Expanded(
                child:
                    Text('Bu ürünü satın aldıktan sonra yorum yapabilirsiniz'),
              ),
            ],
          ),
          backgroundColor: AppDesignSystem.warning,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Anladım',
            textColor: AppDesignSystem.textOnPrimary,
            onPressed: () {},
          ),
        ),
      );
      return;
    }

    if (_selectedRating == 0) {
      debugPrint('✗ Puan seçilmedi');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen bir puan verin'),
          backgroundColor: AppDesignSystem.warning,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) {
      debugPrint('✗ Yorum boş');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen yorumunuzu yazın'),
          backgroundColor: AppDesignSystem.warning,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (commentText.length < 10) {
      debugPrint('✗ Yorum çok kısa: ${commentText.length} karakter');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Yorumunuz en az 10 karakter olmalı (şu anda ${commentText.length} karakter)'),
          backgroundColor: AppDesignSystem.warning,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    debugPrint('✓ Validasyonlar geçildi, yorum gönderiliyor...');

    if (!mounted) return;
    setState(() => _isSubmitting = true);

    try {
      debugPrint('Product ID: ${widget.productId}');
      debugPrint('Rating: $_selectedRating');
      debugPrint(
          'Comment: ${commentText.substring(0, commentText.length > 50 ? 50 : commentText.length)}...');

      if (!mounted) return;

      // Düzenleme modu veya yeni yorum modu
      if (widget.existingReview != null) {
        // DÜZENLEME MODU
        debugPrint('=== YORUM DÜZENLENİYOR ===');
        debugPrint('Review ID: ${widget.existingReview!.id}');

        // Yeni resimler yüklendi mi kontrol et
        List<String> allImageUrls = List<String>.from(_existingImageUrls);

        // Önce yeni fotoğrafları gerçek review ID ile yükle
        List<String> newImageUrls = [];
        if (_selectedImages.isNotEmpty) {
          try {
            debugPrint(
                'Düzenleme modu: Fotoğraf yükleniyor: ${_selectedImages.length} adet');
            newImageUrls = await _storageService.uploadReviewImages(
              _selectedImages,
              widget.existingReview!.id, // Gerçek review ID
            );
            if (newImageUrls.isNotEmpty) {
              allImageUrls.addAll(newImageUrls);
            }
          } catch (uploadError) {
            debugPrint(
                '✗ Düzenleme modu - Fotoğraf yükleme hatası: $uploadError');
            // Hata olsa bile devam et (sadece mevcut fotoğraflar)
          }
        }

        // Yorumu güncelle
        final success = await ReviewService.updateReview(
          reviewId: widget.existingReview!.id,
          rating: _selectedRating,
          comment: commentText,
          imageUrls: allImageUrls,
        );

        if (!success) {
          throw Exception('Yorum güncellenirken hata oluştu');
        }

        debugPrint('✓ Yorum başarıyla güncellendi!');

        if (!mounted) return;

        // Başarı mesajını göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle,
                    color: AppDesignSystem.textOnPrimary, size: 20),
                SizedBox(width: 8),
                Text('Yorumunuz başarıyla güncellendi!'),
              ],
            ),
            backgroundColor: AppDesignSystem.success,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // YENİ YORUM MODU
        debugPrint('ReviewService.addReview çağrılıyor (önce fotoğrafsız)...');
        String? reviewId;
        List<String> imageUrls = [];

        try {
          // ÖNCE: Yorumu fotoğrafsız oluştur (review ID almak için)
          reviewId = await ReviewService.addReview(
            productId: widget.productId,
            rating: _selectedRating,
            comment: commentText,
            imageUrls: [], // Önce boş, sonra fotoğrafları ekleyeceğiz
          );

          if (!mounted) return;

          if (reviewId == null || reviewId.isEmpty) {
            throw Exception('Yorum ID alınamadı');
          }

          debugPrint('✓ Yorum başarıyla eklendi! Review ID: $reviewId');
          debugPrint(
              'Seçili fotoğraf kontrolü: ${_selectedImages.length} adet');

          // SONRA: Fotoğrafları gerçek review ID ile yükle
          if (_selectedImages.isNotEmpty && reviewId.isNotEmpty) {
            debugPrint('=== FOTOĞRAF YÜKLEME BAŞLIYOR ===');
            debugPrint('Fotoğraf sayısı: ${_selectedImages.length}');
            debugPrint('Review ID: $reviewId');
            debugPrint('Mounted: $mounted');

            // Loading state göster (kullanıcıya bilgi ver)
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppDesignSystem.textOnPrimary),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('Fotoğraflar yükleniyor...'),
                      ),
                    ],
                  ),
                  duration: Duration(seconds: 30), // Uzun sürebilir
                  backgroundColor: AppDesignSystem.info,
                ),
              );
            }

            try {
              debugPrint('StorageService.uploadReviewImages çağrılıyor...');
              debugPrint(
                  'Gönderilecek dosya sayısı: ${_selectedImages.length}');

              // XFile listesini direkt gönder (storage_service artık XFile kabul ediyor)
              imageUrls = await _storageService.uploadReviewImages(
                _selectedImages,
                reviewId, // Gerçek review ID kullan
              );

              debugPrint('✓ uploadReviewImages tamamlandı');
              debugPrint('  Alınan URL sayısı: ${imageUrls.length}');

              // SnackBar'ı kapat
              if (mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              }

              if (!mounted) {
                debugPrint('⚠ Widget unmounted, fotoğraf güncelleme atlandı');
                return;
              }

              if (imageUrls.isEmpty) {
                debugPrint(
                    '⚠ UYARI: Fotoğraflar yüklendi ama URL listesi boş!');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.warning,
                              color: AppDesignSystem.textOnPrimary, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                                'Fotoğraflar yüklendi ancak URL alınamadı'),
                          ),
                        ],
                      ),
                      backgroundColor: AppDesignSystem.warning,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } else {
                debugPrint(
                    '✓ Fotoğraflar başarıyla yüklendi: ${imageUrls.length} adet');
                for (int i = 0; i < imageUrls.length; i++) {
                  debugPrint('  Fotoğraf ${i + 1}: ${imageUrls[i]}');
                }

                // Yorumu güncelle - fotoğraf URL'lerini ekle
                debugPrint(
                    'Yorum güncelleniyor - fotoğraf URL\'leri ekleniyor...');
                final updateSuccess = await ReviewService.updateReviewImages(
                  reviewId: reviewId,
                  imageUrls: imageUrls,
                );

                if (updateSuccess) {
                  debugPrint(
                      '✓ Yorum başarıyla güncellendi - fotoğraflar eklendi');
                } else {
                  debugPrint(
                      '⚠ UYARI: Yorum güncellenemedi ama fotoğraflar yüklendi');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.warning,
                                color: AppDesignSystem.textOnPrimary, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                  'Fotoğraflar yüklendi ancak yorum güncellenemedi'),
                            ),
                          ],
                        ),
                        backgroundColor: AppDesignSystem.warning,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                }
              }
            } catch (uploadError, stackTrace) {
              debugPrint('✗ Fotoğraf yükleme hatası: $uploadError');
              debugPrint('Stack trace: $stackTrace');

              // SnackBar'ı kapat
              if (mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              }

              if (!mounted) return;

              // Fotoğraf yükleme hatasını kullanıcıya göster ama yorum zaten oluşturuldu
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.warning,
                          color: AppDesignSystem.textOnPrimary, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Yorum paylaşıldı ancak fotoğraflar eklenemedi. ${uploadError.toString().length > 50 ? uploadError.toString().substring(0, 50) + "..." : uploadError.toString()}',
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppDesignSystem.warning,
                  duration: const Duration(seconds: 5),
                  action: SnackBarAction(
                    label: 'Detaylar',
                    textColor: AppDesignSystem.textOnPrimary,
                    onPressed: () {
                      debugPrint(
                          'Fotoğraf yükleme hatası detayları: $uploadError');
                      debugPrint('Stack trace: $stackTrace');
                    },
                  ),
                ),
              );
              // Yorum zaten oluşturuldu, sadece fotoğraflar eklenemedi
              // Devam et - yorum başarıyla oluşturuldu
            }
          } else {
            debugPrint(
                'Fotoğraf seçilmedi, yorum sadece metin olarak gönderilecek');
          }

          if (!mounted) return;

          // Formu temizle ve başarı mesajını göster
          _commentController.clear();
          if (mounted) {
            setState(() {
              _selectedRating = 0;
              _selectedImages.clear();
              _isSubmitting = false;
            });
          }

          // Başarı mesajını göster (fotoğraf durumunu belirt)
          if (mounted) {
            final hasImages = imageUrls.isNotEmpty;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: AppDesignSystem.textOnPrimary, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasImages
                            ? 'Yorumunuz ve fotoğraflar başarıyla paylaşıldı!'
                            : 'Yorumunuz başarıyla paylaşıldı!',
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppDesignSystem.success,
                duration: const Duration(seconds: 3),
              ),
            );
          }

          // Callback'i hemen çağır (optimistic update için)
          debugPrint('onReviewAdded callback çağrılıyor (hemen)...');
          if (mounted) {
            // Firestore'un güncellenmesi için kısa bir bekleme
            await Future.delayed(const Duration(milliseconds: 800));

            if (mounted) {
              // Hemen callback çağır - yorum listesini güncelle
              widget.onReviewAdded();
              debugPrint('✓ İlk callback çağrıldı');

              // Firestore'un propagate olması için bir kere daha güncelle
              await Future.delayed(const Duration(milliseconds: 1000));
              if (mounted) {
                widget.onReviewAdded();
                debugPrint('✓ Callback tekrar çağrıldı (güncelleme için)');
              }
            }
          }
        } catch (reviewError) {
          debugPrint('✗ Yorum ekleme hatası: $reviewError');
          // Form state'ini geri al
          if (mounted) {
            setState(() {
              _isSubmitting = false;
            });
          }
          rethrow; // Hata yukarı fırlatılsın
        }
      }
    } catch (e, stackTrace) {
      debugPrint('✗ YORUM GÖNDERME HATASI: $e');
      debugPrint('Stack trace: $stackTrace');

      if (!mounted) return;

      // Eğer sadece fotoğraf yükleme hatası ise, yorumu fotoğrafsız gönder
      final firstErrorStr = e.toString().toLowerCase();
      if (firstErrorStr.contains('fotoğraf') ||
          firstErrorStr.contains('image') ||
          firstErrorStr.contains('upload')) {
        debugPrint(
            'Fotoğraf yükleme hatası tespit edildi, yorum fotoğrafsız gönderiliyor...');

        // Yorumu fotoğrafsız gönder
        try {
          if (widget.existingReview != null) {
            // Düzenleme modu
            final success = await ReviewService.updateReview(
              reviewId: widget.existingReview!.id,
              rating: _selectedRating,
              comment: _commentController.text.trim(),
              imageUrls: _existingImageUrls, // Sadece mevcut fotoğraflar
            );
            if (!success) {
              throw Exception('Yorum güncellenirken hata oluştu');
            }
          } else {
            // Yeni yorum modu
            await ReviewService.addReview(
              productId: widget.productId,
              rating: _selectedRating,
              comment: _commentController.text.trim(),
              imageUrls: [], // Fotoğraf olmadan
            );
          }

          // Başarı mesajı
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle,
                      color: AppDesignSystem.textOnPrimary, size: 20),
                  SizedBox(width: 8),
                  Text('Yorumunuz paylaşıldı (fotoğrafsız)'),
                ],
              ),
              backgroundColor: AppDesignSystem.success,
              duration: Duration(seconds: 3),
            ),
          );

          // Formu temizle ve callback çağır
          _commentController.clear();
          if (mounted) {
            setState(() {
              _selectedRating = 0;
              _selectedImages.clear();
            });
          }

          await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted) {
            widget.onReviewAdded();
          }

          return; // Başarılı, çık
        } catch (retryError) {
          debugPrint('Fotoğrafsız gönderme hatası: $retryError');
          // Normal hata göster
        }
      }

      String errorMessage = 'Yorum eklenirken hata oluştu';
      IconData errorIcon = Icons.error_outline;

      final finalErrorStr = e.toString().toLowerCase();
      if (finalErrorStr.contains('kullanıcı giriş') ||
          finalErrorStr.contains('giriş yapmamış')) {
        errorMessage = 'Yorum yapmak için giriş yapmanız gerekiyor';
        errorIcon = Icons.login;
      } else if (finalErrorStr.contains('satın al')) {
        errorMessage = 'Bu ürünü satın aldıktan sonra yorum yapabilirsiniz';
        errorIcon = Icons.shopping_cart;
      } else if (finalErrorStr.contains('zaten yorum')) {
        errorMessage = 'Bu ürün için zaten yorum yaptınız';
        errorIcon = Icons.info_outline;
      } else if (finalErrorStr.contains('network') ||
          finalErrorStr.contains('internet')) {
        errorMessage = 'İnternet bağlantınızı kontrol edin';
        errorIcon = Icons.wifi_off;
      } else {
        errorMessage = 'Yorum eklenirken hata oluştu. Lütfen tekrar deneyin.';
        errorIcon = Icons.error_outline;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(errorIcon, color: AppDesignSystem.textOnPrimary, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(errorMessage)),
            ],
          ),
          backgroundColor: AppDesignSystem.error,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Tekrar Dene',
            textColor: AppDesignSystem.textOnPrimary,
            onPressed: () {
              if (mounted) {
                _submitReview();
              }
            },
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
      debugPrint('=== YORUM GÖNDERME TAMAMLANDI ===');
    }
  }

  Future<void> _pickImages() async {
    if (!mounted || _isSubmitting) return;

    try {
      // Kullanıcıya kamera veya galeri seçeneği sun
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kameradan Çek'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeriden Seç'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('İptal'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );

      if (source == null || !mounted) return;

      // Fotoğraf seç (tekli veya çoklu)
      if (source == ImageSource.camera) {
        // Kameradan tek fotoğraf
        final XFile? image = await _picker.pickImage(source: source);
        if (image != null && mounted) {
          if (_selectedImages.length < 5) {
            setState(() {
              _selectedImages.add(image);
            });
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Maksimum 5 fotoğraf ekleyebilirsiniz'),
                backgroundColor: AppDesignSystem.warning,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        // Galeriden çoklu fotoğraf
        final List<XFile> images = await _picker.pickMultiImage();
        if (images.isNotEmpty && mounted) {
          final remainingSlots = 5 - _selectedImages.length;
          if (remainingSlots <= 0) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Maksimum 5 fotoğraf ekleyebilirsiniz'),
                  backgroundColor: AppDesignSystem.warning,
                  duration: Duration(seconds: 2),
                ),
              );
            }
            return;
          }

          final imagesToAdd = images.take(remainingSlots).toList();
          if (mounted) {
            setState(() {
              _selectedImages.addAll(imagesToAdd);
            });
          }

          if (images.length > remainingSlots && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Sadece $remainingSlots fotoğraf eklendi (Maksimum: 5)'),
                backgroundColor: AppDesignSystem.warning,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline,
                    color: AppDesignSystem.textOnPrimary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                        'Fotoğraf seçilirken hata oluştu: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppDesignSystem.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    if (!mounted || index < 0 || index >= _selectedImages.length) return;

    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    // Satın alma kontrolü
    if (!widget.hasPurchased) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppDesignSystem.warningLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppDesignSystem.warning.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            Icon(Icons.shopping_cart, color: AppDesignSystem.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Bu ürünü satın aldıktan sonra yorum yapabilirsiniz',
                style: TextStyle(
                  color: AppDesignSystem.warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppDesignSystem.infoLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppDesignSystem.info.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit, color: AppDesignSystem.info, size: 20),
              const SizedBox(width: 8),
              Text(
                'Yorum Yap',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppDesignSystem.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Puan seçimi
          Text(
            'Puanınız:',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w500,
              color: AppDesignSystem.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          StarRating(
            rating: _selectedRating.toDouble(),
            size: isSmallScreen ? 24 : 28,
            onRatingChanged: (rating) {
              setState(() => _selectedRating = rating.round());
            },
          ),
          const SizedBox(height: 16),

          // Yorum metni
          Text(
            'Yorumunuz:',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w500,
              color: AppDesignSystem.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Ürün hakkında düşüncelerinizi paylaşın...',
              hintStyle: TextStyle(color: AppDesignSystem.textTertiary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppDesignSystem.borderMedium),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppDesignSystem.info),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),

          // Fotoğraf seçimi
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppDesignSystem.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppDesignSystem.borderMedium),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.photo_library,
                        size: 18, color: AppDesignSystem.info),
                    const SizedBox(width: 8),
                    Text(
                      'Fotoğraf Ekle',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: AppDesignSystem.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedImages.length > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppDesignSystem.infoLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_selectedImages.length}/5',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppDesignSystem.info,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            _selectedImages.length < 5 ? _pickImages : null,
                        icon: Icon(
                          Icons.add_photo_alternate,
                          size: 20,
                          color: _selectedImages.length < 5
                              ? AppDesignSystem.info
                              : AppDesignSystem.textTertiary,
                        ),
                        label: Text(
                          _selectedImages.length < 5
                              ? 'Fotoğraf Seç'
                              : 'Maksimum 5 fotoğraf',
                          style: TextStyle(
                            color: _selectedImages.length < 5
                                ? AppDesignSystem.info
                                : AppDesignSystem.textTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: _selectedImages.length < 5
                                ? AppDesignSystem.info.withValues(alpha: 0.45)
                                : AppDesignSystem.borderMedium,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_selectedImages.length > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Fotoğraflarınızı ekleyerek yorumunuzu daha etkili hale getirin',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppDesignSystem.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Mevcut fotoğraflar (düzenleme modunda)
          if (_existingImageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Mevcut Fotoğraflar:',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.w500,
                color: AppDesignSystem.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _existingImageUrls.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _existingImageUrls[index],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => Container(
                              width: 80,
                              height: 80,
                              color: AppDesignSystem.borderLight,
                              child: Icon(Icons.error,
                                  color: AppDesignSystem.textTertiary),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _existingImageUrls.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppDesignSystem.error,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: AppDesignSystem.textOnPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],

          // Seçilen fotoğraflar
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Seçilen Fotoğraflar:',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.w500,
                color: AppDesignSystem.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child:
                              _buildImageWidget(_selectedImages[index], index),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppDesignSystem.error,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: AppDesignSystem.textOnPrimary,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Gönder butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitReview,
              icon: _isSubmitting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppDesignSystem.textOnPrimary,
                        ),
                      ),
                    )
                  : const Icon(Icons.send, size: 18),
              label: Text(
                _isSubmitting ? 'Gönderiliyor...' : 'Yorumu Gönder',
                style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppDesignSystem.info,
                foregroundColor: AppDesignSystem.textOnPrimary,
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 12 : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Bilgi metni
          Text(
            'Yorumunuz başarıyla paylaşıldı.',
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              color: AppDesignSystem.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
