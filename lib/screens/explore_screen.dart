import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoozy/components/caregivercardModern.dart'; // Modern fiyatsız kart
import 'package:zoozy/components/SimplePetCard.dart';
import 'package:zoozy/components/bottom_navigation_bar.dart';
import 'package:zoozy/screens/backers_list_screen.dart';
import 'package:zoozy/screens/broadcast_page.dart';
import 'package:zoozy/screens/caregiverProfilPage.dart';
import 'package:zoozy/screens/favori_page.dart';
import 'package:zoozy/services/favorite_service.dart';
import 'package:zoozy/components/explore_slider.dart';
import 'package:zoozy/services/user_service_api.dart'; // Backend Servisi

// BackersNearbyScreen'in dışarıdan import edildiği varsayılmıştır
import 'package:zoozy/screens/login_page.dart';

// Tema Renkleri
const Color _primaryColor = Colors.deepPurple;
const Color _secondaryColor = Color(0xFFF3E5F5); // Hafif leylak/mor arka plan
const Color _accentColor = Colors.purple; // Kategori ikonları için

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  int selectedCategoryIndex = -1;
  Set<String> favoriIsimleri = {};
  List<Map<String, dynamic>> _caregivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await _favorileriYukle();
    await _loadCaregivers();
  }

  Future<void> _loadCaregivers() async {
    try {
      final api = UserServiceApi();
      final services = await api.getOtherUsersServices();

      List<Map<String, dynamic>> newCaregivers = [];
      for (var s in services) {
        String image = s['userPhotoUrl'] ?? 'assets/images/caregiver1.png';
        if (image.isEmpty) image = 'assets/images/user_placeholder.png';

        String bio = s['description'] ?? "";
        if (bio.isEmpty) {
          bio = "Merhaba! Ben hayvanları çok seviyorum ve onların mutluluğu benim için her şeyden önemli. Profesyonel bakım hizmetimle dostunuz emin ellerde. İhtiyaçlarınıza özel çözümler sunmak için buradayım, benimle iletişime geçmekten çekinmeyin.";
        }

        newCaregivers.add({
          "name": s['userDisplayName'] ?? 'Kullanıcı',
          "slug": s['userSlug'], // Backend slug
          "image": image,
          "suitability": s['serviceName'] ?? 'Hizmet',
          "location": s['address'] ?? "İstanbul / Kadıköy",
          "bio": bio,
          "followers": 100, // Örnek veri
          "following": 25,  // Örnek veri
          "reviews": [],    // Örnek veri
          "moments": [],    // Örnek veri
          "userId": s['userId'], // ID eklendi
          "fullData": s,
        });
      }

      if (mounted) {
        setState(() {
          _caregivers = newCaregivers;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Caregivers backend hata: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Oturum bilgilerini temizler

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  // Caregiver Profil Sayfasına yönlendirme işlevi
  void _navigateToCaregiverProfile(int index) {
    // Backend verisi
    final data = _caregivers[index];
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CaregiverProfilpage(
          caregiverId: data["userId"] as int?,
          caregiverData: data["fullData"] as Map<String, dynamic>?,
          displayName: data["name"],
          userName: data["name"], // Legacy
          slug: data["slug"] ?? (data["name"] as String).toLowerCase().replaceAll(RegExp(r'[^\w]+'), '_'), // Use slug, fallback to transform
          location: data["location"] ?? "İstanbul/Kadıköy",
          bio: data["bio"] ?? "...",
          userPhoto: data["image"],
          userSkills: data["suitability"],
          otherSkills: "İlk Yardım, Temel Eğitim",
          followers: data["followers"] as int? ?? 50,
          following: data["following"] as int? ?? 20,
          moments: const [],
          reviews: const [], // Şimdilik boş liste
          favoriteTip: "explore",
        ),
      ),
    ).then((_) {
      _favorileriYukle();
    });
  }

  /// Backend'den favori bakıcı isimlerini yükler.
  Future<void> _favorileriYukle() async {
    try {
      final favoriteService = FavoriteService();
      final favorites =
          await favoriteService.getUserFavorites(tip: "explore");
      final mevcutIsimler = favorites.map((f) => f.title).toSet();
      setState(() {
        favoriIsimleri = mevcutIsimler;
      });
    } catch (e) {
      print('Favori yükleme hatası: $e');
      // Hata durumunda boş set kullan
      setState(() {
        favoriIsimleri = <String>{};
      });
    }
  }

  // Kategoriye tıklandığında BackersNearbyScreen'e yönlendirir.
  // Seçilen hizmet adını (serviceName) parametre olarak gönderir.
  void _navigateToCategoryScreen(String serviceName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BackersNearbyScreen(serviceName: serviceName),
      ),
    ).then((_) {
      _favorileriYukle();
    });
  }


  @override
  Widget build(BuildContext context) {
    // Ekran genişliğini alarak orantılı tasarıma yardımcı oluyoruz
    final double screenWidth = MediaQuery.of(context).size.width;
    // Dinamik kenar boşluğu
    final double horizontalListPadding = screenWidth * 0.04;

    // Hizmet isimleri services.dart (22-59) ile uyumlu olacak şekilde güncellendi
    final categories = [
      {"icon": Icons.house, "label": "Evcil Hayvan Pansiyonu"},
      {"icon": Icons.wb_sunny, "label": "Günlük Bakım"},
      {"icon": Icons.chair_alt, "label": "Evcil Hayvan Bakımı"},
      {"icon": Icons.directions_walk, "label": "Köpek Gezdirme"},
      {"icon": Icons.local_taxi, "label": "Evcil Hayvan Taksi"},
      {"icon": Icons.cut, "label": "Evcil Hayvan Tımarı"},
      {"icon": Icons.school, "label": "Evcil Hayvan Eğitimi"},
      {"icon": Icons.camera_alt, "label": "Evcil Hayvan Fotoğrafçılığı"},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Icon(Icons.pets, color: _primaryColor, size: 28),
        ),
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "ZOOZY",
            style: TextStyle(
              color: _primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 1.5,
            ),
          ),
        ),
        actions: [
          // ❤️ Favoriler
          IconButton(
            icon:
                const Icon(Icons.favorite_border, color: Colors.red, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FavoriPage(
                    favoriTipi: "explore",
                    previousScreen: const ExploreScreen(),
                  ),
                ),
              ).then((_) {
                _favorileriYukle();
              });
            },
          ),

          // 🚪 Çıkış
          IconButton(
            icon: const Icon(Icons.logout, color: _primaryColor, size: 26),
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 10.0),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.logout, color: Color(0xFF9C27B0), size: 50),
                      SizedBox(height: 12),
                      Text(
                        'Oturumu kapatmak istediğine emin misin?',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Giriş ekranına yönlendirileceksin.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          _logout();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'Çıkış Yap',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        // Padding değeri dışarıdaki kenar boşlukları ayarlar
        padding: EdgeInsets.symmetric(
            horizontal: horizontalListPadding, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- KATEGORİLER ---
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              // Kategori düğmeleri için responsive grid ayarları
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: screenWidth * 0.05, // Dikey aralık
                crossAxisSpacing: screenWidth * 0.02, // Yatay aralık
                childAspectRatio: 0.85, // Orantıyı daha iyi ayarla
              ),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = index == selectedCategoryIndex;
                return InkWell(
                  borderRadius: BorderRadius.circular(40),
                  onTap: () {
                    final selectedService = cat["label"] as String;
                    _navigateToCategoryScreen(selectedService);
                    setState(() {
                      selectedCategoryIndex = isSelected ? -1 : index;
                    });
                  },
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: screenWidth *
                            0.07, // Ekran genişliğine göre boyutlandır
                        // 🛠️ DÜZELTME: Tıklanmadığında arka plan rengi (_secondaryColor)
                        backgroundColor:
                            isSelected ? _primaryColor : _secondaryColor,
                        child: Icon(
                          cat["icon"] as IconData,
                          // 🛠️ DÜZELTME: Tıklanmadığında ikon rengi (_accentColor)
                          color: isSelected ? Colors.white : _accentColor,
                          size: screenWidth * 0.06, // İkon boyutunu da orantıla
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat["label"] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize:
                              screenWidth * 0.032, // Font boyutunu orantıla
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? _primaryColor : Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 30),

            // --- CAREGIVER BAŞLIK ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Bakıcılar",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _primaryColor),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const BackersListScreen()),
                    ).then((_) {
                      _favorileriYukle();
                    });
                  },
                  child: const Text(
                    "Daha Fazla >",
                    style: TextStyle(
                        color: _accentColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // --- CAREGIVER KARTLARI (Yatay Kaydırma) ---
            SizedBox(
              height:
                  screenWidth * 0.62, // Yüksekliği biraz artırdık
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : _caregivers.isEmpty 
                  ? const Center(child: Text("Yakınınızda hizmet veren bulunamadı.")) 
                  : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _caregivers.length,
                itemBuilder: (context, index) {
                  final c = _caregivers[index];
                  final isFav = favoriIsimleri.contains(c["name"]);
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: screenWidth * 0.45, // Kart genişliğini ayarla
                      child: CaregiverCardBalanced(
                        onTap: () => _navigateToCaregiverProfile(index),
                        name: c["name"] as String,
                        imagePath: c["image"] as String,
                        suitability: c["suitability"] as String,
                        isFavorite: isFav,
                          tip: "explore", // Explore sayfası için özel tip
                          onFavoriteChanged: () {
                            _favorileriYukle();
                          },
                        ),
                      ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
// --- TOPLULUK SLIDER ---
const Text(
  "Zoozy Hakkında",
  style: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 18,
    color: _primaryColor,
  ),
),
const SizedBox(height: 12),

const ExploreInfoSlider(),

const SizedBox(height: 24),

      
            
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        selectedColor: _primaryColor,
        unselectedColor: Colors.grey,
      ),
    );
  }
}