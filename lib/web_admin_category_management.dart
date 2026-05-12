import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../model/admin_product.dart';
import '../services/admin_service.dart';
import '../theme/app_design_system.dart';
import '../widgets/professional_image_uploader.dart';
import '../widgets/professional_components.dart';
import '../utils/responsive_helper.dart';

/// Kategori yönetimi sayfası
class WebAdminCategoryManagement extends StatefulWidget {
  const WebAdminCategoryManagement({super.key});

  @override
  State<WebAdminCategoryManagement> createState() =>
      _WebAdminCategoryManagementState();
}

class _WebAdminCategoryManagementState
    extends State<WebAdminCategoryManagement> {
  final AdminService _adminService = AdminService();
  int _refreshKey = 0;
  final TextEditingController _categoryNameController = TextEditingController();
  final TextEditingController _categoryDescriptionController =
      TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();
  final TextEditingController _productStockController = TextEditingController();
  final TextEditingController _productDescriptionController =
      TextEditingController();
  final _productFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _categoryNameController.dispose();
    _categoryDescriptionController.dispose();
    _productNameController.dispose();
    _productPriceController.dispose();
    _productStockController.dispose();
    _productDescriptionController.dispose();
    super.dispose();
  }

  void _refreshCategories() {
    setState(() {
      _refreshKey++;
    });
  }

  // ==================== KATEGORİ İŞLEMLERİ ====================

  Future<void> _showAddCategoryDialog() async {
    _categoryNameController.clear();
    _categoryDescriptionController.clear();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Yeni Kategori',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _categoryNameController,
                decoration: InputDecoration(
                  labelText: 'Kategori Adı *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _categoryDescriptionController,
                decoration: InputDecoration(
                  labelText: 'Açıklama (Opsiyonel)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_categoryNameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kategori adı zorunludur')),
                );
                return;
              }

              try {
                final category = ProductCategory(
                  id: '', // ID otomatik oluşturulacak
                  name: _categoryNameController.text.trim(),
                  description:
                      _categoryDescriptionController.text.trim().isEmpty
                          ? null
                          : _categoryDescriptionController.text.trim(),
                  isActive: true,
                );

                await _adminService.addCategory(category);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Kategori başarıyla eklendi'),
                      backgroundColor: AppDesignSystem.success,
                    ),
                  );
                  _refreshCategories();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hata: $e'),
                      backgroundColor: AppDesignSystem.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppDesignSystem.accent,
              foregroundColor: AppDesignSystem.textOnPrimary,
            ),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditCategoryDialog(ProductCategory category) async {
    _categoryNameController.text = category.name;
    _categoryDescriptionController.text = category.description ?? '';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Kategori Düzenle',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _categoryNameController,
                decoration: InputDecoration(
                  labelText: 'Kategori Adı *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _categoryDescriptionController,
                decoration: InputDecoration(
                  labelText: 'Açıklama (Opsiyonel)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_categoryNameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kategori adı zorunludur')),
                );
                return;
              }

              try {
                final updatedCategory = category.copyWith(
                  name: _categoryNameController.text.trim(),
                  description:
                      _categoryDescriptionController.text.trim().isEmpty
                          ? null
                          : _categoryDescriptionController.text.trim(),
                );

                await _adminService.updateCategory(updatedCategory);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Kategori başarıyla güncellendi'),
                      backgroundColor: AppDesignSystem.success,
                    ),
                  );
                  _refreshCategories();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hata: $e'),
                      backgroundColor: AppDesignSystem.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppDesignSystem.accent,
              foregroundColor: AppDesignSystem.textOnPrimary,
            ),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteCategoryDialog(ProductCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategoriyi Sil'),
        content: Text(
            '${category.name} kategorisini silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppDesignSystem.error,
              foregroundColor: AppDesignSystem.textOnPrimary,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.deleteCategory(category.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kategori başarıyla silindi'),
              backgroundColor: AppDesignSystem.success,
            ),
          );
          _refreshCategories();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: $e'),
              backgroundColor: AppDesignSystem.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleCategoryStatus(ProductCategory category) async {
    try {
      final updatedCategory = category.copyWith(isActive: !category.isActive);
      await _adminService.updateCategory(updatedCategory);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedCategory.isActive
                  ? 'Kategori aktif yapıldı'
                  : 'Kategori pasif yapıldı',
            ),
            backgroundColor: AppDesignSystem.success,
          ),
        );
        _refreshCategories();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppDesignSystem.error,
          ),
        );
      }
    }
  }

  // ==================== ÜRÜN İŞLEMLERİ ====================

  Future<void> _showCategoryProductsDialog(ProductCategory category) async {
    final products = await _adminService.getProductsByCategory(category.name);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${category.name} Kategorisindeki Ürünler',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Toplam ${products.length} ürün',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppDesignSystem.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showAddProductToCategoryDialog(
                          category, setDialogState),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Kategoriye Ürün Ekle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppDesignSystem.accent,
                        foregroundColor: AppDesignSystem.textOnPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: products.isEmpty
                      ? Center(
                          child: Text(
                            'Bu kategoride ürün bulunmuyor',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: AppDesignSystem.textSecondary,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return _buildProductListItem(
                                product, category, setDialogState);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductListItem(
    AdminProduct product,
    ProductCategory category,
    StateSetter setDialogState,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: product.imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: AppDesignSystem.borderLight,
                      child: const Icon(Icons.image),
                    );
                  },
                ),
              )
            : Container(
                width: 60,
                height: 60,
                color: AppDesignSystem.borderLight,
                child: const Icon(Icons.image),
              ),
        title: Text(
          product.name,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fiyat: ${product.price.toStringAsFixed(2)} ₺'),
            Text('Stok: ${product.stock}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Kategori dropdown
            FutureBuilder<List<ProductCategory>>(
              future: _adminService.getAllCategories().first,
              builder: (context, snapshot) {
                final categories = snapshot.data ?? [];
                final categoryNames = categories.map((c) => c.name).toList();
                final currentCategory = product.category;

                // Güvenli dropdown value
                String? dropdownValue;
                if (categoryNames.contains(currentCategory)) {
                  dropdownValue = currentCategory;
                }

                return DropdownButton<String>(
                  value: dropdownValue,
                  items: categoryNames.map((name) {
                    return DropdownMenuItem(
                      value: name,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (newCategory) async {
                    if (newCategory == null || newCategory == currentCategory)
                      return;

                    try {
                      await _adminService.updateProductFields(
                        product.id,
                        {'category': newCategory},
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Ürün kategorisi güncellendi'),
                            backgroundColor: AppDesignSystem.success,
                          ),
                        );
                        // Dialog'u kapat ve yeniden aç
                        Navigator.pop(context);
                        _showCategoryProductsDialog(category);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Hata: $e'),
                            backgroundColor: AppDesignSystem.error,
                          ),
                        );
                      }
                    }
                  },
                  hint: const Text('Kategori'),
                );
              },
            ),
            const SizedBox(width: 8),
            // Düzenle butonu
            IconButton(
              icon: Icon(Icons.edit, color: AppDesignSystem.accent),
              onPressed: () => _showEditProductDialog(product, category),
              tooltip: 'Düzenle',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditProductDialog(
      AdminProduct product, ProductCategory category) async {
    _productNameController.text = product.name;
    _productPriceController.text = product.price.toStringAsFixed(2);
    _productStockController.text = product.stock.toString();
    _productDescriptionController.text = product.description;
    String? selectedCategory = product.category;
    String? selectedImageUrl = product.imageUrl;

    final categories = await _adminService.getAllCategories().first;
    final categoryNames = categories.map((c) => c.name).toList();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            constraints: const BoxConstraints(maxHeight: 800),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _productFormKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ürün Düzenle',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ProfessionalImageUploader(
                      currentImageUrl: selectedImageUrl,
                      onImageSelected: (url) {
                        setDialogState(() {
                          selectedImageUrl = url;
                        });
                      },
                      label: 'Ürün Resmi',
                      height: 200,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _productNameController,
                      decoration: InputDecoration(
                        labelText: 'Ürün Adı *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ürün adı zorunludur';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _productPriceController,
                            decoration: InputDecoration(
                              labelText: 'Fiyat *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Fiyat zorunludur';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Geçerli bir fiyat girin';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _productStockController,
                            decoration: InputDecoration(
                              labelText: 'Stok *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Stok zorunludur';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Geçerli bir stok girin';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: categoryNames.contains(selectedCategory)
                          ? selectedCategory
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Kategori *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: categoryNames.map((name) {
                        return DropdownMenuItem(
                          value: name,
                          child: Text(name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCategory = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kategori seçiniz';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _productDescriptionController,
                      decoration: InputDecoration(
                        labelText: 'Açıklama',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('İptal'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            if (!_productFormKey.currentState!.validate())
                              return;
                            if (selectedCategory == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Kategori seçiniz')),
                              );
                              return;
                            }

                            try {
                              final updatedProduct = product.copyWith(
                                name: _productNameController.text.trim(),
                                price:
                                    double.parse(_productPriceController.text),
                                stock: int.parse(_productStockController.text),
                                description:
                                    _productDescriptionController.text.trim(),
                                category: selectedCategory!,
                                imageUrl: selectedImageUrl ?? '',
                              );

                              await _adminService.updateProduct(
                                  product.id, updatedProduct);
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Ürün başarıyla güncellendi'),
                                    backgroundColor: AppDesignSystem.success,
                                  ),
                                );
                                // Kategori ürünleri dialog'unu yenile
                                Navigator.pop(context);
                                _showCategoryProductsDialog(category);
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Hata: $e'),
                                    backgroundColor: AppDesignSystem.error,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppDesignSystem.accent,
                            foregroundColor: AppDesignSystem.textOnPrimary,
                          ),
                          child: const Text('Kaydet'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddProductToCategoryDialog(
    ProductCategory category,
    StateSetter setDialogState,
  ) async {
    final allProducts = await _adminService.getProductsFromServer();
    final categoryProducts =
        allProducts.where((p) => p.category == category.name).toList();
    final availableProducts =
        allProducts.where((p) => p.category != category.name).toList();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setAddDialogState) => Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kategoriye Ürün Ekle',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // İstatistikler
                Row(
                  children: [
                    _buildStatCard(
                        'Toplam', allProducts.length, AppColors.brandCyan),
                    const SizedBox(width: 12),
                    _buildStatCard('Bu Kategoride', categoryProducts.length,
                        AppColors.warning),
                    const SizedBox(width: 12),
                    _buildStatCard('Eklenebilir', availableProducts.length,
                        AppColors.success),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: availableProducts.isEmpty
                      ? Center(
                          child: Text(
                            'Eklenebilecek ürün bulunmuyor',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: AppDesignSystem.textSecondary,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: allProducts.length,
                          itemBuilder: (context, index) {
                            final product = allProducts[index];
                            final isInCategory =
                                product.category == category.name;
                            final currentCategory = product.category;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: isInCategory
                                  ? AppDesignSystem.warningLight
                                  : AppDesignSystem.infoLight,
                              child: ListTile(
                                leading: product.imageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          product.imageUrl,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              width: 60,
                                              height: 60,
                                              color:
                                                  AppDesignSystem.borderLight,
                                              child: const Icon(Icons.image),
                                            );
                                          },
                                        ),
                                      )
                                    : Container(
                                        width: 60,
                                        height: 60,
                                        color: AppDesignSystem.borderLight,
                                        child: const Icon(Icons.image),
                                      ),
                                title: Text(
                                  product.name,
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Fiyat: ${product.price.toStringAsFixed(2)} ₺'),
                                    Text(
                                      isInCategory
                                          ? 'Bu ürün bu kategoride zaten ekli'
                                          : 'Mevcut Kategori: $currentCategory',
                                      style: TextStyle(
                                        color: isInCategory
                                            ? AppDesignSystem.warning
                                            : AppDesignSystem.info,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: isInCategory
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppDesignSystem.borderMedium,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Zaten Ekli',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppDesignSystem.textPrimary,
                                          ),
                                        ),
                                      )
                                    : ElevatedButton(
                                        onPressed: () async {
                                          try {
                                            await _adminService
                                                .updateProductFields(
                                              product.id,
                                              {'category': category.name},
                                            );
                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Ürün kategoriye eklendi'),
                                                  backgroundColor:
                                                      AppDesignSystem.success,
                                                ),
                                              );
                                              // Dialog'u kapat ve yeniden aç
                                              Navigator.pop(context);
                                              _showAddProductToCategoryDialog(
                                                  category, setDialogState);
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text('Hata: $e'),
                                                  backgroundColor:
                                                      AppDesignSystem.error,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppDesignSystem.success,
                                          foregroundColor:
                                              AppDesignSystem.textOnPrimary,
                                        ),
                                        child: const Text('Ekle'),
                                      ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    final themeColors = context.appTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: themeColors.isDark ? 0.18 : 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: themeColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== İSTATİSTİKLER ====================

  Widget _buildStatisticsCards(
      List<ProductCategory> categories, List<AdminProduct> allProducts) {
    final activeCategories = categories.where((c) => c.isActive).length;
    final passiveCategories = categories.where((c) => !c.isActive).length;

    // Ürünlerden gelen kategoriler (Firestore'da olmayan)
    final productCategories = allProducts.map((p) => p.category).toSet();
    final firestoreCategories = categories.map((c) => c.name).toSet();
    final productOnlyCategories =
        productCategories.difference(firestoreCategories).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Toplam Kategori',
              categories.length + productOnlyCategories, AppColors.brandCyan),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
              'Aktif Kategori', activeCategories, AppColors.success),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
              'Pasif Kategori', passiveCategories, AppColors.error),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
              'Ürünlerden Gelen', productOnlyCategories, AppColors.warning),
        ),
      ],
    );
  }

  // ==================== KATEGORİ KARTI ====================

  Widget _buildCategoryCard(ProductCategory category, int productCount) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: category.isActive
              ? AppDesignSystem.success
              : AppDesignSystem.textTertiary,
          width: 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: category.isActive
              ? AppDesignSystem.successLight
              : AppDesignSystem.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: category.isActive
                    ? AppDesignSystem.successLight
                    : AppDesignSystem.borderLight,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      category.name,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.appTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: category.isActive
                          ? AppDesignSystem.success
                          : AppDesignSystem.textTertiary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category.isActive ? 'Aktif' : 'Pasif',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.appTheme.textInverse,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // İçerik
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (category.description != null &&
                      category.description!.isNotEmpty)
                    Text(
                      category.description!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: context.appTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      'Açıklama yok',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: context.appTheme.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    '$productCount ürün',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: context.appTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Footer - Aksiyon butonları
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: context.appTheme.borderSubtle),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Ürünleri Görüntüle
                  _buildActionButton(
                    icon: Icons.visibility,
                    color: AppDesignSystem.accent,
                    tooltip: 'Ürünleri Görüntüle',
                    onPressed: () => _showCategoryProductsDialog(category),
                  ),
                  // Düzenle
                  _buildActionButton(
                    icon: Icons.edit,
                    color: AppDesignSystem.accent,
                    tooltip: 'Düzenle',
                    onPressed: () => _showEditCategoryDialog(category),
                  ),
                  // Aktif/Pasif Yap
                  _buildActionButton(
                    icon: category.isActive
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AppDesignSystem.warning,
                    tooltip: category.isActive ? 'Pasif Yap' : 'Aktif Yap',
                    onPressed: () => _toggleCategoryStatus(category),
                  ),
                  // Sil
                  _buildActionButton(
                    icon: Icons.delete,
                    color: AppDesignSystem.error,
                    tooltip: 'Sil',
                    onPressed: () => _showDeleteCategoryDialog(category),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed,
        iconSize: 20,
      ),
    );
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'Kategori Yönetimi',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: colors.navSurface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCategories,
            tooltip: 'Yenile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategoryDialog,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Kategori'),
        backgroundColor: colors.accent,
        foregroundColor: colors.textInverse,
      ),
      body: StreamBuilder<List<ProductCategory>>(
        key: ValueKey(_refreshKey),
        stream: _adminService.getAllCategories(),
        builder: (context, categorySnapshot) {
          if (categorySnapshot.connectionState == ConnectionState.waiting) {
            return ProfessionalComponents.createLoadingIndicator(
              message: 'Kategoriler yükleniyor...',
            );
          }

          if (categorySnapshot.hasError) {
            return ProfessionalComponents.createEmptyState(
              title: 'Hata',
              message:
                  'Kategoriler yüklenirken bir hata oluştu: ${categorySnapshot.error}',
              icon: Icons.error_outline,
            );
          }

          final categories = categorySnapshot.data ?? [];

          return FutureBuilder<List<AdminProduct>>(
            future: _adminService.getProductsFromServer(),
            builder: (context, productSnapshot) {
              final allProducts = productSnapshot.data ?? [];

              // Kategori başına ürün sayısını hesapla
              final categoryProductCounts = <String, int>{};
              for (final product in allProducts) {
                categoryProductCounts[product.category] =
                    (categoryProductCounts[product.category] ?? 0) + 1;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // İstatistik kartları
                    _buildStatisticsCards(categories, allProducts),
                    const SizedBox(height: 24),
                    // Kategori listesi
                    Text(
                      'Kategoriler',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: context.appTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (categories.isEmpty)
                      ProfessionalComponents.createEmptyState(
                        title: 'Kategori Bulunamadı',
                        message:
                            'Henüz kategori eklenmemiş. Yeni kategori eklemek için sağ alttaki butona tıklayın.',
                        icon: Icons.category_outlined,
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: ResponsiveHelper.responsiveValue(
                            context,
                            mobile: 1,
                            tablet: 2,
                            desktop: 3,
                            largeScreen: 4,
                          ),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final productCount =
                              categoryProductCounts[category.name] ?? 0;
                          return _buildCategoryCard(category, productCount);
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
