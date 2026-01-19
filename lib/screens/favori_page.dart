import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:zoozy/models/favori_item.dart';
import 'package:zoozy/services/favorite_service.dart';
import 'explore_screen.dart';
import 'moments_screen.dart';
import '../components/bottom_navigation_bar.dart'; 
import 'backers_list_screen.dart';
import 'package:zoozy/components/caregivercardModern.dart';
import 'package:zoozy/components/moments_postCard.dart';


class FavoriPage extends StatefulWidget {
  final String favoriTipi; // "explore", "moments", "caregiver"
  final Widget previousScreen; // Geri dönülecek ekran

  const FavoriPage({
    super.key,
    required this.favoriTipi,
    required this.previousScreen,
  });

  @override
  State<FavoriPage> createState() => _FavoriPageState();
}

class _FavoriPageState extends State<FavoriPage> {
  List<FavoriteItem> favoriler = [];
  final FavoriteService _favoriteService = FavoriteService();
  bool _isLoading = true;
  String _currentUserName = "Kullanıcı";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadFavoriler();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentUserName = prefs.getString('username') ?? "Kullanıcı";
      });
    }
  }

  Future<void> _loadFavoriler() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final favorites =
          await _favoriteService.getUserFavorites(tip: widget.favoriTipi);
      setState(() {
        favoriler = favorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Favori yükleme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = "Favorilerim";
    if (widget.favoriTipi == "explore") title = "Favori İlanlar";
    if (widget.favoriTipi == "caregiver") title = "Favori Bakıcılar";
    if (widget.favoriTipi == "moments") title = "Favori Anlar";

    return Scaffold(
      body: Stack(
        children: [
          // Arka plan gradyanı
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFB39DDB), Color(0xFFF48FB1)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Üst bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => widget.previousScreen,
                            ),
                          );
                        },
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 48), // Dengelemek için boşluk
                    ],
                  ),
                ),

                // İçerik
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double maxContentWidth = math.min(
                        constraints.maxWidth * 0.9,
                        800,
                      );

                      return Center(
                        child: Container(
                          width: maxContentWidth,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : favoriler.isEmpty
                                  ? _bosDurum()
                                  : _favoriListesiOlustur(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16), // Alt boşluk
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(
        currentIndex: 0,
        selectedColor: Colors.deepPurple,
        unselectedColor: Colors.grey,
      ),
    );
  }

  Widget _favoriListesiOlustur() {
    // Moments için liste görünümü (Instagram tarzı akış)
    if (widget.favoriTipi == "moments") {
      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: favoriler.length,
        itemBuilder: (context, index) {
          final item = favoriler[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: MomentsPostCard(
              userName: item.title,
              displayName: item.title,
              userPhoto: item.profileImageUrl,
              postImage: item.imageUrl,
              description: item.subtitle,
              likes: 0,
              comments: 0,
              timePosted: DateTime.now(),
              currentUserName: _currentUserName,
            ),
          );
        },
      );
    }

    // Caregiver ve Explore için Grid görünümü (Kartların orantılı durması için)
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: favoriler.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // İki sütun
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 0.7, // Kartın boyu enine göre daha uzun
      ),
      itemBuilder: (context, index) {
        final item = favoriler[index];
        return CaregiverCardBalanced(
          name: item.title,
          imagePath: item.imageUrl,
          suitability: item.subtitle,
          isFavorite: true,
          tip: widget.favoriTipi,
          onFavoriteChanged: () {
            _loadFavoriler();
          },
        );
      },
    );
  }

  Widget _bosDurum() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purple.shade50,
              ),
              child: const Icon(Icons.pets, size: 60, color: Colors.purple),
            ),
            const SizedBox(height: 30),
            Text(
              "Henüz ${widget.favoriTipi == 'explore' ? 'ilan' : widget.favoriTipi == 'moments' ? 'anı' : 'bakıcı'} favoriniz yok.\nBeğendiğinizi kalp ikonuna dokunarak kaydedebilirsiniz.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                if (widget.favoriTipi == 'moments') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MomentsScreen(),
                    ),
                  );
                } else if (widget.favoriTipi == 'explore') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BackersListScreen(),
                    ),
                  );
                } else if (widget.favoriTipi == 'caregiver') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExploreScreen(),
                    ),
                  );
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.deepPurpleAccent],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.purpleAccent,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  widget.favoriTipi == 'explore'
                      ? 'İlanları Gör'
                      : widget.favoriTipi == 'moments'
                          ? 'Anları Gör'
                          : 'Bakıcıları Keşfet',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
