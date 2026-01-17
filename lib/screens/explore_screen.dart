import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoozy/components/CaregiverCard.dart';
import 'package:zoozy/components/SimplePetCard.dart';
import 'package:zoozy/components/bottom_navigation_bar.dart';
import 'package:zoozy/screens/backers_list_screen.dart';
import 'package:zoozy/screens/broadcast_page.dart';
import 'package:zoozy/screens/caregiverProfilPage.dart';
import 'package:zoozy/screens/favori_page.dart';
import 'package:zoozy/services/favorite_service.dart';
import 'package:zoozy/components/explore_slider.dart';

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
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Oturum bilgilerini temizler

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  final caregivers = [
    {
      "name": "İstanbul, Juliet Wan",
      "image": "assets/images/caregiver1.png",
      "suitability": "Gezdirme",
      "price": 315.0
    },
    {
      "name": "Emy Pansiyon",
      "image": "assets/images/caregiver2.jpeg",
      "suitability": "Pansiyon",
      "price": 1600.0
    },
    {
      "name": "Animal Care Pro",
      "image": "assets/images/caregiver3.jpg",
      "suitability": "Gündüz Bakımı",
      "price": 1175.0
    },
  ];

  final pets = [
    {"image": "assets/images/pet1.jpeg", "name": "Buddy", "owner": "Alice"},
    {"image": "assets/images/pet2.jpeg", "name": "Charlie", "owner": "Bob"},
    {"image": "assets/images/pet3.jpg", "name": "Max", "owner": "Carol"},
  ];

  @override
  void initState() {
    super.initState();
    _favorileriYukle();
  }

  /// Backend'den favori bakıcı isimlerini yükler.
  Future<void> _favorileriYukle() async {
    try {
      final favoriteService = FavoriteService();
      final favorites =
          await favoriteService.getUserFavorites(tip: "caregiver");
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
    );
  }

  // Caregiver Profil Sayfasına göndermek için örnek veri üretir.
  Map<String, dynamic> _fetchCaregiverData(int index) {
    final caregiver = caregivers[index];
    final String name = caregiver["name"] as String;
    final String imagePath = caregiver["image"] as String;

    return {
      "displayName": name,
      "userName": name.toLowerCase().replaceAll(RegExp(r'[^\w]+'), '_'),
      "location": "İstanbul/Kadıköy",
      "bio": "Hayvan dostlarımıza sevgiyle bakıyoruz!",
      "userPhoto": imagePath,
      "userSkills": caregiver["suitability"],
      "otherSkills": "Oyun Zamanı, İlk Yardım",
      "moments": List<Map<String, dynamic>>.empty(),
      "reviews": List<Map<String, dynamic>>.empty(),
      "followers": 50 + index * 10,
      "following": 20,
    };
  }

  // Caregiver Profil Sayfasına yönlendirme işlevi
  void _navigateToCaregiverProfile(int index) {
    final data = _fetchCaregiverData(index);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CaregiverProfilpage(
          displayName: data["displayName"],
          userName: data["userName"],
          location: data["location"],
          bio: data["bio"],
          userPhoto: data["userPhoto"],
          userSkills: data["userSkills"],
          otherSkills: data["otherSkills"],
          moments: data["moments"] as List<Map<String, dynamic>>,
          reviews: data["reviews"] as List<Map<String, dynamic>>,
          followers: data["followers"] as int,
          following: data["following"] as int,
        ),
      ),
    );
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
                builder: (context) => AlertDialog(
                  title: const Text("Çıkış Yap"),
                  content:
                      const Text("Hesabınızdan çıkış yapmak istiyor musunuz?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("İptal"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _logout();
                      },
                      child: const Text(
                        "Çıkış Yap",
                        style: TextStyle(color: Colors.red),
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
                  "Yakınınızdaki Bakıcılar",
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
                    );
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
                  screenWidth * 0.6, // Yüksekliği ekran genişliğine göre ayarla
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: caregivers.length,
                itemBuilder: (context, index) {
                  final c = caregivers[index];
                  final isFav = favoriIsimleri.contains(c["name"]);
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: screenWidth * 0.45, // Kart genişliğini ayarla
                      child: GestureDetector(
                        onTap: () => _navigateToCaregiverProfile(index),
                        behavior: HitTestBehavior.opaque,
                        child: CaregiverCardAsset(
                          name: c["name"] as String,
                          imagePath: c["image"] as String,
                          suitability: c["suitability"] as String,
                          price: c["price"] as double,
                          isFavorite: isFav,
                          onFavoriteChanged: () {
                            _favorileriYukle();
                          },
                        ),
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