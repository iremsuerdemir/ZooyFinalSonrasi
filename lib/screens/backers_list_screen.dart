import 'package:flutter/material.dart';
import 'package:zoozy/services/favorite_service.dart';
import 'package:zoozy/services/user_service_api.dart';

// Gerekli component import'ları
// import 'package:zoozy/components/CaregiverCard.dart'; // Eğer CaregiverCardAsset kullanılmıyorsa silinebilir.
import 'package:zoozy/components/bottom_navigation_bar.dart';
import 'package:zoozy/components/caregivercardModern.dart'; // Fiyatsız yeni versiyonun burada olduğunu varsayıyoruz.

import 'package:zoozy/screens/caregiverProfilPage.dart';

// Tema Renkleri
const Color _primaryColor = Colors.deepPurple;
const Color _lightLilacBackground = Color(0xFFF3E5F5);
const Color _accentColor = Color(0xFFF06292); // Filtreler için pembe tonu

class BackersListScreen extends StatefulWidget {
  const BackersListScreen({super.key});

  @override
  State<BackersListScreen> createState() => _BackersListScreenState();
}

class _BackersListScreenState extends State<BackersListScreen> {
  Set<String> favoriIsimleri = {};
  List<Map<String, dynamic>> _backers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _favorileriYukle();
    await _loadBackers();
  }

  Future<void> _loadBackers() async {
    try {
      final api = UserServiceApi();
      final services = await api.getOtherUsersServices();

      List<Map<String, dynamic>> newBackers = [];

      for (var s in services) {
        String image = s['userPhotoUrl'] ?? 'assets/images/caregiver1.png';
        if (image.isEmpty) image = 'assets/images/caregiver1.png';

        String bio = s['description'] ?? "";
        if (bio.isEmpty) {
          bio = "Merhaba! Ben hayvanları çok seviyorum ve onların mutluluğu benim için her şeyden önemli. Profesyonel bakım hizmetimle dostunuz emin ellerde. İhtiyaçlarınıza özel çözümler sunmak için buradayım, benimle iletişime geçmekten çekinmeyin.";
        }

        newBackers.add({
            'name': s['userDisplayName'] ?? 'Kullanıcı',
            'imagePath': image,
            'suitability': s['serviceName'] ?? 'Hizmet',
            'isFavorite': false,
            'location': s['address'] ?? "İstanbul / Kadıköy",
            'bio': bio,
            'userId': s['userId'],
            'fullData': s,
        });
      }

      // Eğer API boş dönerse örnek verileri kullanmak isterseniz burayı uncomment yapabilirsiniz.
      // Şimdilik sadece backend verisi gösteriyoruz.
      if (services.isEmpty && _backers.isEmpty) {
          // Fallback demo data logic removed requested by user implication
          // But purely for robustness, if you want demo data:
          /*
          newBackers.addAll([
            {
              'name': 'Tanks Corner Gündüz Bakım',
              ...
            }
          ]);
          */
      }

      if (mounted) {
        setState(() {
          _backers = newBackers;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Backers yükleme hatası: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _favorileriYukle() async {
    try {
      final favoriteService = FavoriteService();
      // "explore" tipindeki favorileri çekiyoruz çünkü kartlarda tip="explore" kullanılıyor
      final favorites = await favoriteService.getUserFavorites(tip: "explore");
      final mevcutIsimler = favorites.map((f) => f.title).toSet();
      if (mounted) {
        setState(() {
          favoriIsimleri = mevcutIsimler;
        });
      }
    } catch (e) {
      debugPrint('Favori yükleme hatası: $e');
    }
  }

  /*
  // 🔹 Örnek Veri Listesi (Devre Dışı Bırakıldı - Backend'den Geliyor)
  final List<Map<String, dynamic>> _backers_old = [
    { ... }
  ];
  */

  // 🔹 Profil sayfasına navigasyon işlevi
  void _navigateToCaregiverProfile(int index) {
    final backer = _backers[index];

    // Örnek verilerin tamamı burada atanır
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CaregiverProfilpage(
          // DİNAMİK VERİLER
          caregiverId: backer['userId'] as int?,
          caregiverData: backer['fullData'] as Map<String, dynamic>?,
          displayName: backer['name'] as String,
          userName: backer['name']
              .toString()
              .toLowerCase()
              .replaceAll(RegExp(r'[^\w]+'), '_'),
          userPhoto: backer['imagePath'] as String,

          // ZORUNLU SABİT/ÖRNEK VERİLER
          location: backer['location']?.toString() ?? "İstanbul / Kadıköy",
          bio: backer['bio']?.toString() ??
              "7 yılı aşkın süredir evcil hayvan bakımı yapıyorum. Güvenli ve sevgi dolu bir ortam sağlarım.",
          userSkills: "Köpek Gezdirme, Kedi Pansiyonu",
          otherSkills: "İlk Yardım Sertifikası",
          followers: 125,
          following: 30,
          reviews: const [
            {
              'id': 'r1',
              'name': 'Örnek Kullanıcı',
              'comment': 'Harika bir deneyimdi!',
              'rating': 5,
              'timePosted': '2023-01-01T12:00:00Z',
              'photoUrl': 'assets/images/profile_placeholder.png'
            }
          ],
          moments: const [
            {
              'userName': '@tankscornermoments',
              'displayName': 'Anlar',
              'userPhoto': 'assets/images/caregiver3.jpg',
              'postImage': 'assets/images/caregiver3.jpg',
              'description': 'Güzel bir gün...',
              'likes': 10,
              'comments': 5,
              'timePosted': '2023-01-01T12:00:00Z'
            },
          ],
        ),
      ),
    );
  }

  // Favori değişince listeyi yenile
  void _onFavoriteChanged() {
    _favorileriYukle();
  }

  // Filtre Butonuna basıldığında BottomSheet açan fonksiyon (Aynı Kaldı)
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filtrele',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              const Divider(height: 20, thickness: 1),
              // Örnek Filtre Seçenekleri
              ListTile(
                leading: const Icon(Icons.pets, color: _primaryColor),
                title: const Text('Köpekler İçin'),
                onTap: () {
                  // Filtreleme işlemi buraya eklenebilir
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.pets, color: _primaryColor),
                title: const Text('Kediler İçin'),
                onTap: () {
                  // Filtreleme işlemi buraya eklenebilir
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on, color: _primaryColor),
                title: const Text('Yakınlığa Göre'),
                onTap: () {
                  // Filtreleme işlemi buraya eklenebilir
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ekran genişliği
    final double screenWidth = MediaQuery.of(context).size.width;
    // Padding'i dinamik olarak hesapla (Ekranın %5'i boşluk olarak bırakılabilir)
    final double horizontalPadding = screenWidth * 0.05;

    return Scaffold(
      backgroundColor: _lightLilacBackground,

      // --- 1. Uygulama Çubuğu (App Bar) ---
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _primaryColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Tüm Bakıcılar', // Başlık sadeleştirildi
          style: TextStyle(
            color: _primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Filtre butonu buraya taşındı
          IconButton(
            icon: const Icon(Icons.filter_list, color: _accentColor),
            onPressed: _showFilterBottomSheet,
            tooltip: 'Filtrele',
          ),
          IconButton(
            icon: const Icon(Icons.search, color: _primaryColor),
            onPressed: () {
              // Arama işlevi
            },
            tooltip: 'Ara',
          ),
          const SizedBox(width: 8),
        ],
      ),

      // --- 2. Sayfa İçeriği ---
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : _backers.isEmpty
              ? const Center(
                  child: Text(
                    "Henüz hizmet veren bakıcı bulunmamaktadır.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // 🔹 Bakıcı Listesi (Responsive GridView)
            Padding(
              // Üstten de biraz boşluk eklendi
              padding: EdgeInsets.fromLTRB(
                  horizontalPadding, 16.0, horizontalPadding, 0.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _backers.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 sütunlu düzen
                  crossAxisSpacing: 12.0, // Sütunlar arası boşluk
                  mainAxisSpacing: 12.0, // Satırlar arası boşluk
                  childAspectRatio: 0.7, // Kart yüksekliğini ayarla
                ),
                // YENİ KOD: GridView.builder içindeki itemBuilder
                itemBuilder: (context, index) {
                  final backer = _backers[index];
                  final isFav = favoriIsimleri.contains(backer['name']);

                  return CaregiverCardBalanced(
                    onTap: () => _navigateToCaregiverProfile(index),
                    name: backer['name'] as String,
                    imagePath: backer['imagePath'] as String,
                    suitability: backer['suitability'] as String,
                    isFavorite: isFav,
                    tip: "explore", // <-- Backend için ayrım
                    onFavoriteChanged: _onFavoriteChanged,
                  );
                },
              ),
            ),
            const SizedBox(height: 20), // Alt navigasyon çubuğu için boşluk
          ],
        ),
      ),
      // --- BOTTOM NAVIGATION BAR (Aynı Kaldı) ---
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        selectedColor: _primaryColor,
        unselectedColor: Colors.grey,
      ),
    );
  }
}
