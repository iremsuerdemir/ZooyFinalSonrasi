import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:zoozy/services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  final bool shouldReturnToChat;
  
  const EditProfileScreen({Key? key, this.shouldReturnToChat = false}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  File? _image;
  Uint8List? _webImage;
  final ImagePicker _picker = ImagePicker();
  final UserService _userService = UserService();

  Color _emailFieldColor = Colors.grey[100]!;
  Color _phoneFieldColor = Colors.grey[100]!;
  String? _completePhoneNumber; // Ülke kodu dahil tam telefon numarası

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();

    final String loadedUsername =
        prefs.getString('username') ?? 'İrem Su Erdemir';
    final String loadedEmail = prefs.getString('email') ?? '7692003@gmail.com';
    final String loadedPhone = prefs.getString('phone') ?? '';

    Uint8List? loadedWebImage;
    File? loadedImage;

    final imageString = prefs.getString('profileImagePath');
    if (imageString != null && imageString.isNotEmpty) {
      try {
        final bytes = base64Decode(imageString);
        if (kIsWeb) {
          loadedWebImage = bytes;
        } else {
          final appDir = await getApplicationDocumentsDirectory();
          final file = File(p.join(appDir.path, 'profile_image.png'));
          await file.writeAsBytes(bytes);
          loadedImage = file;
        }
      } catch (e) {
        print('Resim yüklenirken hata oluştu: $e');
      }
    }

    setState(() {
      _usernameController.text = loadedUsername;
      _emailController.text = loadedEmail;
      // Telefon numarasını yükle - eğer ülke kodu yoksa sadece numarayı göster
      // IntlPhoneField ülke kodunu otomatik ekleyecek
      _phoneController.text = loadedPhone;
      _webImage = loadedWebImage;
      _image = loadedImage;
    });
  }

  Future<void> _saveProfileData() async {
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    bool isEmailValid = RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    ).hasMatch(email);

    // IntlPhoneField kullanıldığı için telefon numarasını doğru şekilde kontrol et
    // _completePhoneNumber varsa onu kullan (ülke kodu dahil), yoksa controller'dan al
    String phoneToSave;
    if (_completePhoneNumber != null && _completePhoneNumber!.isNotEmpty) {
      // Ülke kodu dahil tam numarayı kullan (+ işaretini kaldır, sadece rakamlar)
      phoneToSave = _completePhoneNumber!.replaceAll(RegExp(r'[^\d]'), '');
      // Eğer + ile başlıyorsa, + işaretini kaldır (zaten rakamlar alındı)
      // WhatsApp için ülke kodu dahil tam numara gerekiyor (örn: 905306403286)
    } else {
      // Fallback: controller'dan al ve sadece rakamları temizle
      // Eğer ülke kodu yoksa, Türkiye için 90 ekle
      phoneToSave = phone.replaceAll(RegExp(r'[^\d]'), '');
      // Eğer numara 10 haneli ve 5 ile başlıyorsa (Türkiye cep telefonu), 90 ekle
      if (phoneToSave.length == 10 && phoneToSave.startsWith('5')) {
        phoneToSave = '90$phoneToSave';
      }
    }
    
    // WhatsApp için en az 11-12 haneli olmalı (ülke kodu dahil)
    bool isPhoneValid = phoneToSave.length >= 11;

    setState(() {
      _emailFieldColor = isEmailValid ? Colors.grey[100]! : Colors.red[100]!;
      _phoneFieldColor = isPhoneValid ? Colors.grey[100]! : Colors.red[100]!;
    });

    if (!isEmailValid || !isPhoneValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen geçerli e-posta ve telefon girin!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', _usernameController.text);
    await prefs.setString('displayName', _usernameController.text);
    await prefs.setString('email', email);
    await prefs.setString('phone', phoneToSave);

    Uint8List? imageBytes;

    if (_image != null && !kIsWeb) {
      imageBytes = await _image!.readAsBytes();
    } else if (_webImage != null && kIsWeb) {
      imageBytes = _webImage!;
    }

    if (imageBytes != null) {
      final imageString = base64Encode(imageBytes);
      await prefs.setString('profileImagePath', imageString);

      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        final file = File(p.join(appDir.path, 'profile_image.png'));
        await file.writeAsBytes(imageBytes);
        _image = file;
      }

      // Backend'e profil resmini kaydet
      final userId = prefs.getInt('userId');
      if (userId != null) {
        // Base64 formatında backend'e gönder (data:image/png;base64,... formatı)
        // Sadece imageString boş değilse gönder
        if (imageString.isNotEmpty) {
          final photoUrl = 'data:image/png;base64,$imageString';
          print(
              '📤 Profil resmi backend\'e gönderiliyor (uzunluk: ${photoUrl.length})');

          final success = await _userService.updateUserProfile(
            userId: userId,
            displayName: _usernameController.text.trim(),
            photoUrl: photoUrl,
          );

          if (success) {
            // Backend'deki PhotoUrl'i SharedPreferences'a da kaydet
            await prefs.setString('photoUrl', photoUrl);
            print('✅ Profil resmi backend\'e kaydedildi');
          } else {
            print('⚠️ Profil resmi backend\'e kaydedilemedi');
          }
        } else {
          print('⚠️ Profil resmi boş, backend\'e gönderilmiyor');
        }
      }
    } else {
      // Sadece isim güncellendi, resim yok
      final userId = prefs.getInt('userId');
      if (userId != null) {
        await _userService.updateUserProfile(
          userId: userId,
          displayName: _usernameController.text.trim(),
        );
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Başarı ile kaydedildi'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    setState(() {});

    // Eğer chat ekranından gelindiyse, kaydetme sonrası otomatik olarak chat ekranına dön
    if (widget.shouldReturnToChat) {
      // Snackbar mesajının gösterilmesi için kısa bir gecikme
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context, true); // true = telefon numarası kaydedildi
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        if (kIsWeb) {
          _webImage = await pickedFile.readAsBytes();
          _image = null;
        } else {
          _image = File(pickedFile.path);
          _webImage = null;
        }
        setState(() {});
      }
    } catch (e) {
      print('Hata: $e');
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.purple),
                  title: const Text('Kamera'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: Colors.purple,
                  ),
                  title: const Text('Galeri'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  ImageProvider? _getProfileImage() {
    if (kIsWeb) {
      return _webImage != null ? MemoryImage(_webImage!) : null;
    } else {
      return _image != null ? FileImage(_image!) : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB39DDB), Color(0xFFF48FB1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const Text(
                        'Profili Düzenle',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => _showImageSourceActionSheet(context),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _getProfileImage(),
                          child: (_webImage == null && _image == null)
                              ? Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey[600],
                                )
                              : null,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Fotoğrafı Değiştir',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildInputField(
                    controller: _usernameController,
                    labelText: 'Kullanıcı Adı',
                    initialValue: 'İrem Su Erdemir',
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: _emailController,
                    labelText: 'E-posta',
                    initialValue: '7692003@gmail.com',
                  ),
                  const SizedBox(height: 16),
                  IntlPhoneField(
                    controller: _phoneController,
                    initialCountryCode: 'TR',
                    keyboardType: TextInputType.phone,
                    // ⚠️ maskFormatter kaldırıldı (IntlPhoneField kendi formatına sahip)
                    decoration: InputDecoration(
                      labelText: 'Telefon',
                      filled: true,
                      fillColor: _phoneFieldColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (phone) {
                      // Ülke kodu dahil tam telefon numarasını kaydet
                      _completePhoneNumber = phone.completeNumber;
                      setState(() {}); // karakter sayacını güncelle
                    },
                    onCountryChanged: (country) {
                      print(
                        'Seçilen ülke: ${country.name}, kod: ${country.dialCode}',
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildListTile(title: 'Hakkımda', onTap: () {}),
                  const SizedBox(height: 8),
                  _buildListTile(title: 'Rozetlerim', onTap: () {}),
                  const SizedBox(height: 8),
                  _buildListTile(
                    title: 'Hizmet Konumu ve Fotoğraflar',
                    onTap: () {},
                  ),
                  const SizedBox(height: 8),
                  _buildListTile(title: 'İletişim Uygulamaları', onTap: () {}),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveProfileData,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.purple,
                        shadowColor: Colors.deepPurpleAccent,
                        elevation: 6,
                      ),
                      child: const Text(
                        'Kaydet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    String? initialValue,
  }) {
    if (initialValue != null && controller.text.isEmpty) {
      controller.text = initialValue;
    }

    Color bgColor = Colors.white.withOpacity(0.9);
    if (labelText == 'E-posta') bgColor = _emailFieldColor.withOpacity(1.0);
    if (labelText == 'Telefon') bgColor = _phoneFieldColor.withOpacity(1.0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: labelText,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: InputBorder.none,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        style: const TextStyle(color: Colors.black87),
      ),
    );
  }

  Widget _buildListTile({required String title, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.black87)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
