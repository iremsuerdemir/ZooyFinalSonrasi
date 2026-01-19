import 'package:flutter/material.dart';
// import 'package:zoozy/components/caregiver_card.dart'; // Eğer CaregiverCardAsset kullanılmıyorsa silinebilir.
import 'package:zoozy/components/bottom_navigation_bar.dart';
import 'package:zoozy/components/caregivercardModern.dart'; // Fiyatsız yeni versiyonun burada olduğunu varsayıyoruz.
import 'package:zoozy/screens/caregiverProfilPage.dart';
import 'package:zoozy/services/favorite_service.dart';
import 'package:zoozy/services/user_service_api.dart';

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
  String _selectedService = 'Tümü';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  final List<String> services = [
    'Tümü',
    'Evcil Hayvan Pansiyonu',
    'Günlük Bakım',
    'Evcil Hayvan Bakımı',
    'Köpek Gezdirme',
    'Evcil Hayvan Taksi',
    'Evcil Hayvan Tımarı',
    'Evcil Hayvan Eğitimi',
    'Evcil Hayvan Fotoğrafçılığı',
  ];
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          bio =
              "Merhaba! Ben hayvanları çok seviyorum ve onların mutluluğu benim için her şeyden önemli. Profesyonel bakım hizmetimle dostunuz emin ellerde. İhtiyaçlarınıza özel çözümler sunmak için buradayım, benimle iletişime geçmekten çekinmeyin.";
        }

        newBackers.add({
          'name': s['userDisplayName'] ?? 'Kullanıcı',
          'slug': s['userSlug'],
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

  
  // 🔹 Profil sayfasına navigasyon işlevi
  void _navigateToCaregiverProfile(Map<String, dynamic> backer) {
    // Örnek verilerin tamamı burada atanır
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CaregiverProfilpage(
          // DİNAMİK VERİLER
          caregiverId: backer['userId'] as int?,
          caregiverData: backer['fullData'] as Map<String, dynamic>?,
          displayName: backer['name'] as String,
          userName: backer['name'], // Legacy
          slug: backer['slug'] as String? ?? backer['name'].toString().toLowerCase().replaceAll(RegExp(r'[^\w]+'), '_'),
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
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
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
                  ...services.map((service) {
                    return RadioListTile<String>(
                      value: service,
                      groupValue: _selectedService,
                      activeColor: _accentColor,
                      title: Text(service),
                      onChanged: (value) {
                        setState(() {
                          _selectedService = value!;
                        });
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
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

    // Filtreleme mantığı
    final filteredBackers = _backers.where((b) {
      final matchesService =
          _selectedService == 'Tümü' || b['suitability'] == _selectedService;
      final matchesSearch = _searchQuery.isEmpty ||
          (b['name'] as String)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      return matchesService && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: _lightLilacBackground,

      // --- 1. Uygulama Çubuğu (App Bar) ---
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _primaryColor),
          onPressed: () {
            if (_isSearching) {
              setState(() {
                _isSearching = false;
                _searchQuery = "";
                _searchController.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'İsim ile ara...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.black),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : const Text(
                'Tüm Bakıcılar',
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
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.filter_list, color: _accentColor),
              onPressed: _showFilterBottomSheet,
              tooltip: 'Filtrele',
            ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search,
                color: _primaryColor),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = "";
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
            tooltip: _isSearching ? 'Kapat' : 'Ara',
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
              : filteredBackers.isEmpty
                  ? const Center(
                      child: Text(
                        "Arama sonucunda bakıcı bulunamadı.",
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
                            padding: EdgeInsets.fromLTRB(horizontalPadding,
                                16.0, horizontalPadding, 0.0),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredBackers.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, // 2 sütunlu düzen
                                crossAxisSpacing: 12.0, // Sütunlar arası boşluk
                                mainAxisSpacing: 12.0, // Satırlar arası boşluk
                                childAspectRatio:
                                    0.7, // Kart yüksekliğini ayarla
                              ),
                              // YENİ KOD: GridView.builder içindeki itemBuilder
                              itemBuilder: (context, index) {
                                final backer = filteredBackers[index];
                                final isFav =
                                    favoriIsimleri.contains(backer['name']);

                                return CaregiverCardBalanced(
                                  onTap: () =>
                                      _navigateToCaregiverProfile(backer),
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
                          const SizedBox(
                              height: 20), // Alt navigasyon çubuğu için boşluk
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
