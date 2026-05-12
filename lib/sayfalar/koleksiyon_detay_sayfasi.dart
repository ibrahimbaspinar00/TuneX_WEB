import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/collection.dart';
import '../model/product.dart';
import '../services/collection_service.dart';
import '../services/product_service.dart';
import '../widgets/error_handler.dart';
import '../widgets/optimized_image.dart';
import '../config/app_routes.dart';
import '../utils/responsive_helper.dart';

class KoleksiyonDetaySayfasi extends StatefulWidget {
  final Collection collection;

  const KoleksiyonDetaySayfasi({
    super.key,
    required this.collection,
  });

  @override
  State<KoleksiyonDetaySayfasi> createState() => _KoleksiyonDetaySayfasiState();
}

class _KoleksiyonDetaySayfasiState extends State<KoleksiyonDetaySayfasi> {
  final CollectionService _collectionService = CollectionService();
  final ProductService _productService = ProductService();
  
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadCollectionProducts();
  }

  Future<void> _loadCollectionProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _collectionService.getCollectionProducts(widget.collection.id);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ErrorHandler.showError(context, 'Ürünler yüklenirken hata oluştu: $e');
      }
    }
  }

  Future<void> _deleteCollection() async {
    if (_isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık
              Text(
                'Koleksiyonu Sil',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 16),
              // Mesaj
              Text(
                '${widget.collection.name} koleksiyonunu silmek istediğinize emin misiniz?',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Butonlar
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'İptal',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Sil',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
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

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await _collectionService.deleteCollection(widget.collection.id);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Koleksiyon silindi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isDeleting = false);
      if (mounted) {
        ErrorHandler.showError(context, 'Koleksiyon silinirken hata oluştu: $e');
      }
    }
  }

  Future<void> _editCollection() async {
    final nameController = TextEditingController(text: widget.collection.name);
    final descriptionController = TextEditingController(text: widget.collection.description);

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Koleksiyonu Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Koleksiyon Adı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'name': nameController.text.trim(),
                'description': descriptionController.text.trim(),
              });
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final updatedCollection = Collection(
          id: widget.collection.id,
          name: result['name'] ?? '',
          description: result['description'] ?? '',
          userId: widget.collection.userId,
          productIds: widget.collection.productIds,
          createdAt: widget.collection.createdAt,
          updatedAt: DateTime.now(),
          coverImageUrl: widget.collection.coverImageUrl,
        );

        await _collectionService.updateCollection(updatedCollection);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Koleksiyon güncellendi'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.showError(context, 'Koleksiyon güncellenirken hata oluştu: $e');
        }
      }
    }
  }

  Future<void> _removeProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ürünü Çıkar'),
        content: Text('${product.name} ürününü koleksiyondan çıkarmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Çıkar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _collectionService.removeProductFromCollection(
        widget.collection.id,
        product.id,
      );
      await _loadCollectionProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} koleksiyondan çıkarıldı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Ürün çıkarılırken hata oluştu: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D10),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.collection.name,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            if (_products.isNotEmpty)
              Text(
                '${_products.length} Ürün',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            // Ana sayfaya yönlendir
            AppRoutes.navigateToMain(context);
          },
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, size: 20),
            onPressed: () {
              // Paylaş işlemi
            },
            tooltip: 'Paylaş',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (value) {
              if (value == 'edit') {
                _editCollection();
              } else if (value == 'delete') {
                _deleteCollection();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16),
                    SizedBox(width: 8),
                    Text('Düzenle'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Sil', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? _buildEmptyState()
              : _buildProductsList(isSmallScreen),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Büyük ikon
            Icon(
              Icons.collections_bookmark_outlined,
              size: 100,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            // Başlık
            Text(
              'Bu koleksiyon boş',
              style: GoogleFonts.inter(
                fontSize: 20,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // Açıklama
            Text(
              'Ürünleri bu koleksiyona eklemek için\nürün detay sayfasından ekleyebilirsiniz',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // Ürün Ekle butonu
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: _showAddProductsDialog,
                icon: const Icon(Icons.add, size: 22, color: Colors.white),
                label: Text(
                  'Ürün Ekle',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D1FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList(bool isSmallScreen) {
    final viewCount = (_products.length * 1.6).round(); // Demo görüntülenme sayısı
    
    return RefreshIndicator(
      onRefresh: _loadCollectionProducts,
      child: Column(
        children: [
          // Header - Ürün sayısı, görüntülenme, arama ve ürün ekle butonu
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      '${_products.length} Ürün',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.remove_red_eye, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '$viewCount',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.responsiveSpacing(context, mobile: 8.0, desktop: 16.0)),
                    // Arama çubuğu
                    SizedBox(
                      width: 200,
                      height: 36,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Koleksiyonda Ara',
                          hintStyle: GoogleFonts.inter(fontSize: 12),
                          prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Ürün Ekle butonu
                    ElevatedButton(
                      onPressed: _showAddProductsDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6A00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Ürün Ekle',
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
          // Ürünler listesi
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isSmallScreen ? 2 : 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.7,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return _buildProductCard(product, isSmallScreen);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () {
          AppRoutes.navigateToProductDetail(
            context,
            product,
            favoriteProducts: const [],
            cartProducts: const [],
            onFavoriteToggle: (_) async {
              return;
            },
            onAddToCart: (_) async {
              return;
            },
            onRemoveFromCart: (_) {},
          );
        },
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ürün görseli
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: OptimizedImage(
                            imageUrl: product.imageUrl,
                          fit: BoxFit.cover,
                            borderRadius: BorderRadius.zero,
                            placeholder: Container(
                              color: Colors.grey[200],
                              child: Icon(Icons.image, color: Colors.grey[400]),
                            ),
                            errorWidget: Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                            ),
                          ),
                        ),
                        // Rating badge
                        if (product.averageRating > 0)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star, size: 12, color: Colors.orange),
                                  const SizedBox(width: 2),
                                  Text(
                                    product.averageRating.toStringAsFixed(1),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (product.reviewCount > 0) ...[
                                    Text(
                                      ' (${product.reviewCount})',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Ürün bilgileri
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${product.price.toStringAsFixed(2)} ₺',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFF27A1A),
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.responsiveSpacing(context, mobile: 4.0, desktop: 6.0)),
                        // Sepete ekle butonu - Responsive
                        SizedBox(
                          width: double.infinity,
                          height: ResponsiveHelper.responsiveValue(
                            context,
                            mobile: 26.0,
                            tablet: 28.0,
                            desktop: 30.0,
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              // Sepete ekle
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF27A1A),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveHelper.responsiveSpacing(context, mobile: 4.0, desktop: 8.0),
                                vertical: ResponsiveHelper.responsiveSpacing(context, mobile: 3.0, desktop: 5.0),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              elevation: 0,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Sepete Ekle',
                              style: GoogleFonts.inter(
                                fontSize: ResponsiveHelper.responsiveFontSize(
                                  context,
                                  mobile: 10.0,
                                  desktop: 12.0,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Çıkar butonu (X)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeProduct(product),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddProductsDialog() async {
    String searchQuery = '';
    List<Product> allProducts = [];
    List<Product> filteredProducts = [];
    bool isLoading = true;
    Set<String> selectedProductIds = {};
    final existingProductIds = widget.collection.productIds.toSet();

    // Ürünleri yükle
    try {
      allProducts = await _productService.getAllProducts();
      // Zaten koleksiyonda olan ürünleri filtrele
      filteredProducts = allProducts.where((p) => !existingProductIds.contains(p.id)).toList();
      isLoading = false;
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Ürünler yüklenirken hata oluştu: $e');
      }
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void updateFilter() {
            setDialogState(() {
              if (searchQuery.isEmpty) {
                filteredProducts = allProducts.where((p) => !existingProductIds.contains(p.id)).toList();
              } else {
                filteredProducts = allProducts.where((p) =>
                  !existingProductIds.contains(p.id) &&
                  (p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                   p.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
                   p.category.toLowerCase().contains(searchQuery.toLowerCase()))
                ).toList();
              }
            });
          }

          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Header - Trendyol benzeri
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6A00), // Trendyol turuncusu
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.shopping_bag, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Favorilerinden Ürün Seç',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 24),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  // Arama
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        textInputAction: TextInputAction.search,
                        keyboardType: TextInputType.text,
                        enableInteractiveSelection: true,
                        textCapitalization: TextCapitalization.none,
                        maxLines: 1,
                        style: GoogleFonts.inter(),
                        decoration: InputDecoration(
                          hintText: 'Koleksiyonda Ara',
                          hintStyle: GoogleFonts.inter(color: Colors.grey[600]),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) {
                          searchQuery = value;
                          updateFilter();
                        },
                      ),
                    ),
                  ),
                  // Ürün grid
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filteredProducts.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                                    const SizedBox(height: 16),
                                    Text(
                                      searchQuery.isEmpty
                                          ? 'Eklenebilecek ürün yok'
                                          : 'Arama sonucu bulunamadı',
                                      style: GoogleFonts.inter(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.all(12),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: MediaQuery.of(context).size.width > 1200 
                                      ? 5 
                                      : MediaQuery.of(context).size.width > 800 
                                          ? 4 
                                          : MediaQuery.of(context).size.width > 600 
                                              ? 3 
                                              : 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 0.85,
                                ),
                                itemCount: filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = filteredProducts[index];
                                  final isSelected = selectedProductIds.contains(product.id);

                                  return GestureDetector(
                                    onTap: () {
                                      setDialogState(() {
                                        if (isSelected) {
                                          selectedProductIds.remove(product.id);
                                        } else {
                                          selectedProductIds.add(product.id);
                                        }
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected 
                                              ? const Color(0xFFFF6A00) 
                                              : Colors.grey[300]!,
                                          width: isSelected ? 2 : 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Ürün görseli
                                              Expanded(
                                                flex: 2,
                                                child: ClipRRect(
                                                  borderRadius: const BorderRadius.vertical(
                                                    top: Radius.circular(12),
                                                  ),
                                                  child: Stack(
                                                    children: [
                                                      Positioned.fill(
                                                        child: OptimizedImage(
                                                          imageUrl: product.imageUrl,
                                                        fit: BoxFit.cover,
                                                          borderRadius: BorderRadius.zero,
                                                          placeholder: Container(
                                                            color: Colors.grey[200],
                                                            child: Icon(
                                                              Icons.image,
                                                              color: Colors.grey[400],
                                                              size: 40,
                                                            ),
                                                          ),
                                                          errorWidget: Container(
                                                          color: Colors.grey[200],
                                                          child: Icon(
                                                            Icons.image_not_supported,
                                                            color: Colors.grey[400],
                                                            size: 40,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      // Stok durumu badge
                                                      if (product.stock <= 0)
                                                        Positioned(
                                                          bottom: 0,
                                                          left: 0,
                                                          right: 0,
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: Colors.black.withOpacity(0.7),
                                                            ),
                                                            child: Text(
                                                              'Tükendi',
                                                              style: GoogleFonts.inter(
                                                                color: Colors.white,
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                              textAlign: TextAlign.center,
                                                            ),
                                                          ),
                                                        ),
                                                      if (product.stock > 0 && product.stock < 10)
                                                        Positioned(
                                                          bottom: 0,
                                                          left: 0,
                                                          right: 0,
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: Colors.red[600]!.withOpacity(0.9),
                                                            ),
                                                            child: Text(
                                                              'Tükeniyor',
                                                              style: GoogleFonts.inter(
                                                                color: Colors.white,
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                              textAlign: TextAlign.center,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              // Ürün bilgileri
                                              Expanded(
                                                flex: 1,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(6),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      // Fiyat
                                                      Text(
                                                        '${product.price.toStringAsFixed(2)} ₺',
                                                        style: GoogleFonts.inter(
                                                          color: Colors.grey[900],
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      // Ürün adı (kısa)
                                                      Flexible(
                                                        child: Text(
                                                          product.name,
                                                          style: GoogleFonts.inter(
                                                            color: Colors.grey[700],
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          // Checkbox - sol üst köşe
                                          Positioned(
                                            top: 6,
                                            left: 6,
                                            child: Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: isSelected 
                                                    ? const Color(0xFFFF6A00) 
                                                    : Colors.white,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isSelected 
                                                      ? const Color(0xFFFF6A00) 
                                                      : Colors.grey[400]!,
                                                  width: 1.5,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.1),
                                                    blurRadius: 3,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: isSelected
                                                  ? const Icon(
                                                      Icons.check,
                                                      color: Colors.white,
                                                      size: 14,
                                                    )
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                  // Footer - Trendyol benzeri
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey[200]!),
                      ),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        // Seçili ürün sayısı
                        Text(
                          '${selectedProductIds.length} ürün seçildi',
                          style: GoogleFonts.inter(
                            color: Colors.grey[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.responsiveSpacing(context, mobile: 4.0, desktop: 6.0)),
                        // Koleksiyona Ekle butonu
                        ElevatedButton(
                          onPressed: selectedProductIds.isEmpty
                              ? null
                              : () async {
                                  Navigator.pop(context);
                                  await _addProductsToCollection(selectedProductIds.toList());
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedProductIds.isEmpty 
                                ? Colors.grey[300] 
                                : const Color(0xFFFF6A00),
                            foregroundColor: selectedProductIds.isEmpty 
                                ? Colors.grey[600] 
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: selectedProductIds.isEmpty ? 0 : 2,
                          ),
                          child: Text(
                            'Koleksiyona Ekle',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _addProductsToCollection(List<String> productIds) async {
    if (productIds.isEmpty) return;

    try {
      int successCount = 0;
      int failCount = 0;

      for (final productId in productIds) {
        try {
          // Ürün bilgilerini al
          final product = await _productService.getProductById(productId);
          if (product != null) {
            await _collectionService.addProductToCollection(
              widget.collection.id,
              productId,
              productImageUrl: product.imageUrl,
            );
            successCount++;
          } else {
            failCount++;
          }
        } catch (e) {
          failCount++;
          debugPrint('Error adding product $productId: $e');
        }
      }

      await _loadCollectionProducts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              successCount > 0
                  ? '$successCount ürün koleksiyona eklendi${failCount > 0 ? " ($failCount hata)" : ""}'
                  : 'Ürünler eklenirken hata oluştu',
            ),
            backgroundColor: successCount > 0 ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Ürünler eklenirken hata oluştu: $e');
      }
    }
  }

}

