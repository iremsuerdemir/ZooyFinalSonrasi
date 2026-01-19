import 'package:flutter/material.dart';

import 'package:zoozy/components/caregiver_card.dart';
import 'package:zoozy/components/bottom_navigation_bar.dart';

import 'package:zoozy/screens/CaregiverProfilpage.dart';
import 'package:zoozy/screens/backers_list_screen.dart';
import 'package:zoozy/screens/favori_page.dart';
import 'package:zoozy/services/user_service_api.dart';

// Tema Renkleri
const Color _primaryColor = Colors.deepPurple;
const Color _broadcastButtonColor = Color(0xFF9C7EB9);
const Color _lightLilacBackground = Color(0xFFF3E5F5);
const Color _accentColor = Color(0xFFF06292); // Filtreler için pembe tonu

class BackersNearbyScreen extends StatefulWidget {
  /// Seçilen hizmet adı (örneğin: "Evcil Hayvan Eğitimi")
  final String serviceName;

  const BackersNearbyScreen({super.key, required this.serviceName});

  @override
  State<BackersNearbyScreen> createState() => _BackersNearbyScreenState();
}

class _BackersNearbyScreenState extends State<BackersNearbyScreen> {
  final UserServiceApi _userServiceApi = UserServiceApi();

  /// Backend'den gelen ve seçilen hizmet adına göre filtrelenmiş backer listesi
  List<Map<String, dynamic>> _backers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBackersForService();
  }

  Future<void> _loadBackersForService() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final services = await _userServiceApi.getOtherUsersServices();
      final selectedLower = widget.serviceName.toLowerCase();

      // Seçilen hizmet adına göre filtrele
      final filtered = services.where((s) {
        final name = (s['serviceName'] ?? '').toString().toLowerCase();
        return name.contains(selectedLower);
      }).toList();

      setState(() {
        _backers = filtered.map((s) {
          final displayName = (s['userDisplayName'] ?? '') as String;
          final photoUrl = (s['userPhotoUrl'] ?? '') as String;

          return {
            'name': displayName.isNotEmpty ? displayName : 'İsimsiz Kullanıcı',
            // Network veya asset olarak CaregiverCard içinde handle edilecek
            'imagePath':
                photoUrl.isNotEmpty ? photoUrl : 'assets/images/caregiver1.png',
            'suitability': s['serviceName'] ?? '',
            'price': 0.0,
            'isFavorite': false,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Backers yüklenirken hata: $e');
      setState(() {
        _backers = [];
        _isLoading = false;
      });
    }
  }

  // 🔹 Profil sayfasına navigasyon işlevi
  void _navigateToCaregiverProfile(int index) {
    final backer = _backers[index];

    // Örnek verilerin tamamı burada atanır
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CaregiverProfilpage(
          // DİNAMİK VERİLER
          displayName: backer['name'] as String,
          userName: backer['name']
              .toString()
              .toLowerCase()
              .replaceAll(RegExp(r'[^\w]+'), '_'),
          userPhoto: backer['imagePath'] as String,

          // ZORUNLU SABİT/ÖRNEK VERİLER
          location: "İstanbul / Kadıköy",
          bio:
              "7 yılı aşkın süredir evcil hayvan bakımı yapıyorum. Güvenli ve sevgi dolu bir ortam sağlarım.",
          userSkills: "Köpek Gezdirme, Kedi Pansiyonu",
          otherSkills: "İlk Yardım Sertifikası",
          followers: 125,
          following: 30,
          reviews: const [],
          moments: const [],
        ),
      ),
    );
  }

  // Favori durumu değiştiğinde _backers listesini güncelleyen fonksiyon.
  void _updateFavoriteStatus(int index) {
    setState(() {
      _backers[index]['isFavorite'] = !_backers[index]['isFavorite'];
    });
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
        title: Text(
          'Yakındaki Bakıcılar - ${widget.serviceName}',
          style: TextStyle(
            color: _primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: _primaryColor),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.red),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context)=>FavoriPage(favoriTipi: "caregivers", previousScreen: const BackersListScreen())));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      // --- 2. Sayfa İçeriği ---
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
      
            // --- Filtre Butonu ---
            Padding(
              padding: EdgeInsets.only(
                  left: horizontalPadding, top: 16.0, bottom: 8.0),
              child: OutlinedButton.icon(
                onPressed: () {},
               
                label: const Text(
                  'Filtrele',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                  side: const BorderSide(color: _accentColor, width: 1.5),
                  foregroundColor: _accentColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),

            // Başlık
            Padding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 16.0, 16.0, 8.0),
              child: const Text(
                "Popüler Bakıcılar",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ),

            // 🔹 Bakıcı Listesi (Responsive GridView)
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_backers.isEmpty)
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: horizontalPadding + 8),
                child: const Text(
                  'Bu hizmet için henüz uygun bakıcı bulunamadı.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              )
            else
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _backers.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 sütunlu düzen
                    crossAxisSpacing: 12.0, // Sütunlar arası boşluk
                    mainAxisSpacing: 12.0, // Satırlar arası boşluk
                    childAspectRatio: 0.7, // Kart yüksekliğini ayarla
                  ),
                  itemBuilder: (context, index) {
                    final backer = _backers[index];

                    return GestureDetector(
                      onTap: () => _navigateToCaregiverProfile(index),
                      behavior: HitTestBehavior.opaque,
                      child: CaregiverCardAsset(
                        name: backer['name'] as String,
                        imagePath: backer['imagePath'] as String,
                        suitability: backer['suitability'] as String,
                        //price: backer['price'] as double,
                        isFavorite: backer['isFavorite'] as bool,
                        onFavoriteChanged: () => _updateFavoriteStatus(index),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      // --- BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        selectedColor: _primaryColor,
        unselectedColor: Colors.grey,
      ),
    );
  }

  }

