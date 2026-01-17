import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoozy/components/bottom_navigation_bar.dart';
import 'package:zoozy/components/comment_card.dart';
import 'package:zoozy/components/comment_dialog.dart';
import 'package:zoozy/components/moments_postCard.dart';
import 'package:zoozy/screens/chat_conversation_screen.dart';
import 'package:zoozy/screens/profile_screen.dart';
import 'package:zoozy/screens/reguests_screen.dart';
import 'package:zoozy/screens/favori_page.dart';
import 'package:zoozy/models/favori_item.dart';
import 'package:zoozy/models/comment.dart';
import 'package:zoozy/services/comment_service_http.dart';
import 'package:zoozy/services/favorite_service.dart';
import 'package:zoozy/services/guest_access_service.dart';

// Tema Renkleri
const Color primaryPurple = Colors.deepPurple; // Ana Mor
const Color _lightLilacBackground =
    Color.fromARGB(255, 244, 240, 245); // Sayfa Arka Planı (Hafif lila)
const Color accentRed = Colors.red; // Favori için
const Color statCardColor = Color(
    0xFFF0EFFF); // İstatistik kartı arka planı (Çok açık mor, daha yumuşak)
const Color skillChipColor = Color(0xFF7E57C2); // Yetenek çipi koyu mor tonu

class CaregiverProfilpage extends StatefulWidget {
  final String displayName;
  final String userName;
  final String location;
  final String bio;
  final String userPhoto;
  final String userSkills;
  final String otherSkills;
  final List<Map<String, dynamic>> moments;
  final List<Map<String, dynamic>> reviews;
  final int followers;
  final int following;
  
  // Yeni eklenen parametreler
  final int? caregiverId;
  final Map<String, dynamic>? caregiverData;

  const CaregiverProfilpage({
    Key? key,
    required this.displayName,
    required this.userName,
    required this.location,
    required this.bio,
    required this.userPhoto,
    this.userSkills = "",
    this.otherSkills = "",
    this.moments = const [],
    this.reviews = const [],
    this.followers = 0,
    this.following = 0,
    this.caregiverId,
    this.caregiverData,
  }) : super(key: key);

  @override
  State<CaregiverProfilpage> createState() => _CaregiverProfilpageState();
}

class _CaregiverProfilpageState extends State<CaregiverProfilpage> {
  final CommentServiceHttp _commentService = CommentServiceHttp();
  final FavoriteService _favoriteService = FavoriteService();
  List<Comment> _comments = [];
  String? _currentUserName;
  bool _isFavorite = false;
  bool _isLoadingComments = false;
  bool _isFollowing = false;
  late int _followerCount;

  @override
  void initState() {
    super.initState();
    _followerCount = widget.followers;
    _loadCurrentUser();
    _loadComments();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final exists = await _favoriteService.isFavorite(
      title: widget.displayName,
      tip: "caregiver",
    );
    setState(() {
      _isFavorite = exists;
    });
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoadingComments = true;
    });

    try {
      final comments = await _commentService.getCommentsForCard(widget.userName);
      setState(() {
        _comments = comments;
        _isLoadingComments = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingComments = false;
      });
      print('Yorum yükleme hatası: $e');
    }
  }

  Future<void> _onCommentAdded(Comment comment) async {
    if (!await GuestAccessService.ensureLoggedIn(context)) {
      return;
    }

    final success = await _commentService.addComment(widget.userName, comment);
    if (success) {
      await _loadComments();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yorum eklenirken bir hata oluştu.')),
        );
      }
    }
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserName = prefs.getString('username') ?? 'Bilinmeyen Kullanıcı';
    });
  }

  Future<void> _toggleFavorite(BuildContext context) async {
    if (!await GuestAccessService.ensureLoggedIn(context)) {
      return;
    }

    final item = FavoriteItem(
      title: widget.displayName,
      subtitle: "Bakıcı - ${widget.userName}",
      imageUrl: widget.userPhoto,
      profileImageUrl: widget.userPhoto,
      tip: "caregiver",
    );

    bool success;
    String message;

    if (_isFavorite) {
      success = await _favoriteService.removeFavorite(
        title: item.title,
        tip: item.tip,
        imageUrl: item.imageUrl,
      );
      message = success ? "Favorilerden çıkarıldı." : "Favoriden çıkarılırken bir hata oluştu.";
    } else {
      success = await _favoriteService.addFavorite(item);
      message = success ? "Favorilere eklendi!" : "Favori eklenirken bir hata oluştu.";
    }

    if (success) {
      await _checkIfFavorite();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _toggleFollow() async {
    if (!await GuestAccessService.ensureLoggedIn(context)) {
      return;
    }

    setState(() {
      _isFollowing = !_isFollowing;
      if (_isFollowing) {
        _followerCount++;
      } else {
        _followerCount--;
      }
    });
  }

  ImageProvider _getImageProvider(String path) {
    if (path.isEmpty || path == 'null') {
      return const AssetImage('assets/images/caregiver1.png');
    }

    if (path.startsWith('http')) {
      return NetworkImage(path);
    } else if (path.startsWith('assets/')) {
      return AssetImage(path);
    } else if (path.length > 255 && !path.contains('\n')) {
      try {
        return MemoryImage(base64Decode(path));
      } catch (_) {
        return const AssetImage('assets/images/caregiver1.png');
      }
    } else {
      return const AssetImage('assets/images/caregiver1.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ekran genişliğini alarak orantılı tasarıma yardımcı oluyoruz
    final double screenWidth = MediaQuery.of(context).size.width;
    // Profil fotoğrafı için dinamik yarıçap (Örn: Ekran genişliğinin %10'u)
    final double avatarRadius = screenWidth * 0.10;

    return Scaffold(
      // Sayfa arka planı
      backgroundColor: _lightLilacBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryPurple, size: 28),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Zoozy",
          style: TextStyle(
            color: primaryPurple,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              await _toggleFavorite(context);
            },
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? accentRed : primaryPurple,
              size: 28,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. PROFIL ÜST KISMI (Fotoğraf, İsim, Lokasyon) ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: avatarRadius, // ORANTILI YARIÇAP
                  backgroundImage: _getImageProvider(widget.userPhoto),
                ),
                const SizedBox(width: 16),
                Expanded(
                  // Kalan alanı kapla ve metin taşmasını önle
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.displayName,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primaryPurple),
                        maxLines: 1, // Taşma kontrolü
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '@${widget.userName}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 14),
                        maxLines: 1, // Taşma kontrolü
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              color: primaryPurple, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            // Konum metninin genişliğini sınırlamak için
                            child: Text(
                              widget.location,
                              style: TextStyle(color: Colors.grey.shade700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- 2. HAREKETE GEÇİRİCİ BUTONLAR ---
            Row(
              children: [
                // Follow Butonu (Alanının yarısını kaplar)
                Expanded(
                  child: ElevatedButton(
                    onPressed: _toggleFollow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFollowing ? Colors.white : primaryPurple,
                      foregroundColor: _isFollowing ? primaryPurple : Colors.white,
                      side: _isFollowing ? const BorderSide(color: primaryPurple, width: 1.5) : null,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(_isFollowing ? "Takibi Bırak" : "Takip Et",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                // Message Butonu (Alanının yarısını kaplar)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      if (!await GuestAccessService.ensureLoggedIn(context)) {
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatConversationScreen(
                            contactName: widget.displayName,
                            contactUsername: widget.userName,
                            contactAvatar: widget.userPhoto,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.message, color: primaryPurple),
                    label: const Text("Mesaj",
                        style: TextStyle(
                            color: primaryPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      side: const BorderSide(
                          color: primaryPurple,
                          width: 1.5), // Tema moru çizgisi
                      elevation: 0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- 3. İSTATİSTİKLER (Row içinde eşit dağılım) ---
            _buildStatsRow(),

            const SizedBox(height: 24),

            // --- 4. HAKKINDA ---
            _buildSectionTitle('Hakkımda 📚'),
            const SizedBox(height: 8),
            Text(widget.bio,
                style: TextStyle(color: Colors.grey.shade800, fontSize: 15)),

            const SizedBox(height: 24),

            // --- 5. SKILLS & QUALIFICATIONS (Wrap ile orantılı yerleşim) ---
            if (widget.userSkills.isNotEmpty || widget.otherSkills.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Yetenekler & Nitelikler 🏅'),
                  const SizedBox(height: 10),
                  Wrap(
                    // Yatay taşmayı otomatik olarak alt satıra geçerek çözer
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      ...widget.userSkills
                          .split(',')
                          .where((s) => s.trim().isNotEmpty)
                          .map((skill) => _buildSkillChip(skill.trim())),
                      ...widget.otherSkills
                          .split(',')
                          .where((s) => s.trim().isNotEmpty)
                          .map((skill) => _buildSkillChip(skill.trim())),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),

            // --- 6. MOMENTS ---
            // Removed as per request


            // --- 7. REVIEWS ve Yorumlar ---
            _buildSectionTitle('Değerlendirmeler ⭐'),
            const SizedBox(height: 12),

            Column(
              children: [
                ...widget.reviews.map((review) => CommentCard(
                      comment: Comment(
                        id: review['id'] ?? '',
                        message: review['comment'] ?? '',
                        rating: review['rating']?.toInt() ?? 0,
                        createdAt: review['timePosted'] != null
                            ? (review['timePosted'] is String
                                ? DateTime.parse(review['timePosted'])
                                : review['timePosted'] as DateTime)
                            : DateTime.now(),
                        authorName: review['name'] ?? '',
                        authorAvatar: review['photoUrl'] ?? '',
                      ),
                    )),
                ..._comments.map((comment) => CommentCard(comment: comment)),
                const SizedBox(height: 20),

                // Yorum Ekle Butonu
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (!await GuestAccessService.ensureLoggedIn(context)) {
                        return;
                      }
                      showDialog(
                        context: context,
                        builder: (context) => CommentDialog(
                          cardId: widget.userName,
                          onCommentAdded: _onCommentAdded,
                          currentUserName:
                              _currentUserName ?? 'Bilinmeyen Kullanıcı',
                        ),
                      );
                    },
                    icon: const Icon(Icons.rate_review, size: 20),
                    label: Text(
                        "Yorum Ekle (${_comments.length})"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple, // Tema rengi
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      // Boyutlandırma Center ve padding ile ayarlanır
                      minimumSize: Size(screenWidth * 0.5, 48),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      // --- BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 4,
        selectedColor: primaryPurple,
        unselectedColor: Colors.grey[700]!,
        onTap: (index) {
          if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const RequestsScreen()),
            );
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          }
        },
      ),
    );
  }

  // --- YARDIMCI WIDGETLAR ---

  // İstatistik Kutusu (Tema rengi ve yuvarlak kenarlık kullanıldı)
  Widget _buildStatsRow() {
    return Container(
      decoration: BoxDecoration(
          color: statCardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryPurple.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: primaryPurple.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      // Row içinde tüm öğeler eşit aralıklarla dağıtılır
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Expanded kullanılarak küçük ekranlarda metinlerin daha iyi sığması sağlanır
          Expanded(
              child: _buildStatItem(_followerCount.toString(), "Takipçi")),
          Container(
              height: 40, width: 1.5, color: primaryPurple.withOpacity(0.3)),
          Expanded(
              child: _buildStatItem(widget.following.toString(), "Takip")),
          Container(
              height: 40, width: 1.5, color: primaryPurple.withOpacity(0.3)),
          Expanded(
              child:
                  _buildStatItem(_comments.length.toString(), "Yorum")),
        ],
      ),
    );
  }

  // İstatistik Öğesi (Metin tema rengi)
  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
              fontWeight: FontWeight.w900, fontSize: 18, color: primaryPurple),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }

  // Başlık Stili (Metin tema rengi ve emoji)
  Widget _buildSectionTitle(String title) {
    // Başlık metinlerinin taşma riski olmadığı için Expanded gerekli değildir
    return Text(
      title,
      style: const TextStyle(
          fontSize: 19, fontWeight: FontWeight.bold, color: primaryPurple),
    );
  }

  // Skill Chip (Koyu mor zemin, Beyaz yazı)
  Widget _buildSkillChip(String label) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: skillChipColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13)),
    );
  }
}
