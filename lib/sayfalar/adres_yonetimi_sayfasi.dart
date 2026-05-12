import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/responsive_helper.dart';
import '../config/app_routes.dart';

class Adres {
  final String id;
  final String title;
  final String fullName;
  final String phone;
  final String address;
  final String city;
  final String district;
  final String postalCode;
  final bool isDefault;

  Adres({
    required this.id,
    required this.title,
    required this.fullName,
    required this.phone,
    required this.address,
    required this.city,
    required this.district,
    required this.postalCode,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'fullName': fullName,
      'phone': phone,
      'address': address,
      'city': city,
      'district': district,
      'postalCode': postalCode,
      'isDefault': isDefault,
    };
  }

  factory Adres.fromMap(Map<String, dynamic> map) {
    return Adres(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      fullName: map['fullName'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      district: map['district'] ?? '',
      postalCode: map['postalCode'] ?? '',
      isDefault: map['isDefault'] ?? false,
    );
  }
}

class AdresYonetimiSayfasi extends StatefulWidget {
  final bool selectMode; // true ise bir adres seçip geri döndürür
  const AdresYonetimiSayfasi({super.key, this.selectMode = false});

  @override
  State<AdresYonetimiSayfasi> createState() => _AdresYonetimiSayfasiState();
}

class _AdresYonetimiSayfasiState extends State<AdresYonetimiSayfasi> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Adres> addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // Source.server ile güncel adresleri al
        final querySnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('addresses')
            .orderBy('createdAt', descending: true)
            .get();

        setState(() {
          addresses = querySnapshot.docs
              .map((doc) => Adres.fromMap(doc.data()))
              .toList();
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        // Error logged: Adresler yüklenirken hata: $e
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF0B0D10),
      appBar: AppBar(
        title: Text(
          'Adreslerim',
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
          child: Column(
            children: [
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (addresses.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz adres eklenmemiş',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'İlk adresinizi ekleyerek başlayın',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: addresses.length,
                    itemBuilder: (context, index) {
                      final address = addresses[index];
                      return InkWell(
                        onTap: widget.selectMode
                            ? () => Navigator.pop(context, address)
                            : null,
                        child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                          child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: address.isDefault 
                                          ? Colors.green[100] 
                                          : Colors.blue[100],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      address.isDefault ? 'Varsayılan' : address.title,
                                      style: TextStyle(
                                        color: address.isDefault 
                                            ? Colors.green[700] 
                                            : Colors.blue[700],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: ResponsiveHelper.responsiveSpacing(context, mobile: 8.0, desktop: 12.0)),
                                  if (widget.selectMode)
                                    ElevatedButton.icon(
                                      onPressed: () => Navigator.pop(context, address),
                                      icon: const Icon(Icons.check, size: 16),
                                      label: const Text('Seç'),
                                    ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _editAddress(address);
                                      } else if (value == 'delete') {
                                        _deleteAddress(address);
                                      } else if (value == 'default') {
                                        _setAsDefault(address);
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
                                        value: 'default',
                                        child: Row(
                                          children: [
                                            Icon(Icons.star, size: 16),
                                            SizedBox(width: 8),
                                            Text('Varsayılan Yap'),
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
                                    child: Icon(
                                      Icons.more_vert,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                address.fullName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                address.phone,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                address.address,
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${address.district}, ${address.city} ${address.postalCode}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewAddress,
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Adres'),
      ),
    );
  }

  void _addNewAddress() {
    _showAddressDialog();
  }

  void _editAddress(Adres address) {
    _showAddressDialog(address: address);
  }

  void _deleteAddress(Adres address) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Adresi Sil'),
          content: const Text('Bu adresi silmek istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _deleteAddressFromFirebase(address);
                if (mounted) {
                  setState(() {
                    addresses.removeWhere((a) => a.id == address.id);
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Adres silindi'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  void _setAsDefault(Adres address) {
    setState(() {
      for (var addr in addresses) {
        addr = Adres(
          id: addr.id,
          title: addr.title,
          fullName: addr.fullName,
          phone: addr.phone,
          address: addr.address,
          city: addr.city,
          district: addr.district,
          postalCode: addr.postalCode,
          isDefault: addr.id == address.id,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Varsayılan adres güncellendi'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showAddressDialog({Adres? address}) async {
    final titleController = TextEditingController(text: address?.title ?? '');
    final fullNameController = TextEditingController(text: address?.fullName ?? '');
    final phoneController = TextEditingController(text: address?.phone ?? '');
    final addressController = TextEditingController(text: address?.address ?? '');
    final cityController = TextEditingController(text: address?.city ?? '');
    final districtController = TextEditingController(text: address?.district ?? '');
    final postalCodeController = TextEditingController(text: address?.postalCode ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(address == null ? 'Yeni Adres' : 'Adresi Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Adres Başlığı (Ev, İş, vb.)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: fullNameController,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  textCapitalization: TextCapitalization.none,
                  decoration: const InputDecoration(
                    labelText: 'Telefon',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Adres',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: cityController,
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Şehir',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: districtController,
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'İlçe',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: postalCodeController,
                  keyboardType: TextInputType.number,
                  textCapitalization: TextCapitalization.none,
                  decoration: const InputDecoration(
                    labelText: 'Posta Kodu',
                    border: OutlineInputBorder(),
                  ),
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
                if (titleController.text.isNotEmpty &&
                    fullNameController.text.isNotEmpty &&
                    phoneController.text.isNotEmpty &&
                    addressController.text.isNotEmpty) {
                  
                  final newAddress = Adres(
                    id: address?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    fullName: fullNameController.text,
                    phone: phoneController.text,
                    address: addressController.text,
                    city: cityController.text,
                    district: districtController.text,
                    postalCode: postalCodeController.text,
                    isDefault: address?.isDefault ?? addresses.isEmpty,
                  );

                  // Firebase'e kaydet
                  await _saveAddressToFirebase(newAddress, address != null);
                  
                  setState(() {
                    if (address != null) {
                      final index = addresses.indexWhere((a) => a.id == address.id);
                      if (index != -1) {
                        addresses[index] = newAddress;
                      }
                    } else {
                      addresses.add(newAddress);
                    }
                  });

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(address == null ? 'Adres eklendi' : 'Adres güncellendi'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lütfen tüm alanları doldurun'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(address == null ? 'Ekle' : 'Güncelle'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveAddressToFirebase(Adres address, bool isUpdate) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final addressData = address.toMap();
        addressData['createdAt'] = FieldValue.serverTimestamp();
        addressData['updatedAt'] = FieldValue.serverTimestamp();

        if (isUpdate) {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('addresses')
              .doc(address.id)
              .update(addressData);
        } else {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('addresses')
              .doc(address.id)
              .set(addressData);
        }
      } catch (e) {
        // Error logged: Adres Firebase'e kaydedilemedi: $e
      }
    }
  }

  Future<void> _deleteAddressFromFirebase(Adres address) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('addresses')
            .doc(address.id)
            .delete();
      } catch (e) {
        // Error logged: Adres Firebase'den silinemedi: $e
      }
    }
  }
}
