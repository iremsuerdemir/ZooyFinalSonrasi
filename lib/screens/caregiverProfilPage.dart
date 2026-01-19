import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // Add this import for UserStats
import 'package:zoozy/config/api_config.dart'; // Add this for ApiConfig
import 'package:zoozy/helpers/web_image.dart'; // Web Image Helper eklendi
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
import 'package:zoozy/services/chat_service.dart'; // Chat Service Eklendi
import 'package:zoozy/services/auth_service.dart'; // Auth Service for user details

// Tema Renkleri
const Color primaryPurple = Colors.deepPurple; // Ana Mor
const Color _lightLilacBackground =
    Color.fromARGB(255, 244, 240, 245); // Sayfa Arka Planı (Hafif lila)
const Color accentRed = Colors.red; // Favori için
const Color statCardColor = Color(
    0xFFF0EFFF); // İstatistik kartı arka planı (Çok açık mor, daha yumuşak)
const Color skillChipColor = Color(0xFF7E57C2); // Yetenek çipi koyu mor tonu

class CaregiverProfilpage extends StatefulWidget {
  // ... existing constructor params ...
  final String displayName;
  final String userName; // Deprecated: legacy display name usage
  final String slug; // NEW: Stable ID for backend calls
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
  final String favoriteTip;

  const CaregiverProfilpage({
    Key? key,
    required this.displayName,
    required this.userName,
    String? slug, // Optional for backward compatibility, defaults to userName if null
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
    this.favoriteTip = "caregiver",
  }) : slug = slug ?? userName, super(key: key); // Init slug with fallback

  @override
  State<CaregiverProfilpage> createState() => _CaregiverProfilpageState();
}

class _CaregiverProfilpageState extends State<CaregiverProfilpage> {
  final CommentServiceHttp _commentService = CommentServiceHttp();
  final FavoriteService _favoriteService = FavoriteService();
  final ChatService _chatService = ChatService(); // Chat Service
  final AuthService _authService = AuthService(); // Auth Service for refreshing bio

  List<Comment> _comments = [];
  String? _currentUserName;
  bool _isFavorite = false;
  bool _isLoadingComments = false;
  bool _isFollowing = false;
  bool _isMessageLoading = false; // Mesaj yükleniyor durumu
  late int _followerCount;
  int _followingCount = 0; // State for following
  int _reviewCount = 0; // State for reviews
  int? _resolvedUserId; // Backend'den gelen veya widget'tan alınan ID
  
  // Dynamic fields that can be refreshed from backend
  late String _displayBio;
  late String _displayPhoto;
  late String _displayLocation;

  @override
  void initState() {
    super.initState();
    _followerCount = widget.followers;
    _followingCount = widget.following; // Init from widget
    _reviewCount = widget.reviews.length; // Init from widget
    _resolvedUserId = widget.caregiverId; // Başlangıçta widget'tan al
    
    // Initialize display fields
    _displayBio = widget.bio;
    _displayPhoto = widget.userPhoto;
    _displayLocation = widget.location;
    
    _loadCurrentUser();
    _loadComments();
    _checkIfFavorite();
    _checkIfFollowing();
    
    // Her zaman backend'den güncel istatistikleri çek (ID veya Slug ile)
    _loadUserStats(widget.caregiverId);
    
    // Backend'den profil detaylarını çek (Bio vs güncellemesi için)
    if (_resolvedUserId != null) {
      _loadUserDetails(_resolvedUserId!);
    }
  }

  Future<void> _loadUserDetails(int userId) async {
    try {
      final user = await _authService.getUserById(userId);
      if (user != null && mounted) {
        setState(() {
          if (user.bio != null && user.bio!.isNotEmpty) {
             _displayBio = user.bio!;
          }
           if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
             _displayPhoto = user.photoUrl!;
          }
          //DisplayName, Location vs de güncellenebilir eğer gerekirse
        });
      }
    } catch (e) {
      print("User details refresh error code: $e");
    }
  }


  Future<void> _loadUserStats(int? userId) async {
    try {
      final Uri url;
      // 1. ID varsa ID ile çek (En güvenilir)
      if (userId != null) {
        url = Uri.parse("${ApiConfig.usersUrl}/$userId/stats");
      } 
      // 2. Slug varsa Slug ile çek (Yeni Endpoint)
      else if (widget.slug.isNotEmpty) {
        url = Uri.parse("${ApiConfig.usersUrl}/slug/${widget.slug}/stats");
      } 
      // 3. Fallback: Veri yok, çık
      else {
        return;
      }

      print("📊 İstatistikler çekiliyor: $url");
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ İstatistikler geldi: $data");
        
        if (mounted) {
          setState(() {
            _followerCount = data['followers'] ?? 0;
            _followingCount = data['following'] ?? 0;
            // Review count can be updated here or keep using listed comments length
             _reviewCount = data['reviews'] ?? _comments.length;
            
            // Eğer response içinde 'statsId' dönerse ve bizde ID yoksa güncelleyelim
            if (_resolvedUserId == null && data['statsId'] != null) {
               _resolvedUserId = data['statsId'];
               // ID bulunduktan sonra favori durumunu tekrar netleştirmek faydalı olabilir
               _checkIfFavorite();
               _checkIfFollowing();
            }
          });
        }
      } else {
        print("❌ İstatistik hatası: ${response.statusCode}");
      }
    } catch (e) {
      print("Error loading user stats: $e");
    }
  }


  Future<void> _checkIfFavorite() async {
    final exists = await _favoriteService.isFavorite(
      title: widget.displayName,
      tip: widget.favoriteTip,
    );
    if (mounted) {
      setState(() {
        _isFavorite = exists;
      });
    }
  }

  Future<void> _checkIfFollowing() async {
    // Takip durumu için "takip" tipindeki favorileri kontrol et
    try {
      final favorites = await _favoriteService.getUserFavorites(tip: "takip");
      final isFollowing = favorites.any((f) {
        // ID varsa ID'ye göre kontrol et (Tercih edilen)
        if (_resolvedUserId != null && f.targetUserId != null) {
          return f.targetUserId == _resolvedUserId;
        }
        // ID yoksa isme göre kontrol et (Fallback)
        return f.title == widget.displayName;
      });

      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
        });
      }
    } catch (e) {
      print("Check follow error: $e");
    }
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoadingComments = true;
    });

    try {
      // Use slug for comments
      final comments = await _commentService.getCommentsForCard(widget.slug);
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

    final success = await _commentService.addComment(widget.slug, comment);
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

  int? _currentUserId; // To store logged-in user ID

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserName = prefs.getString('username') ?? 'Bilinmeyen Kullanıcı';
      _currentUserId = prefs.getInt('userId');
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
      tip: widget.favoriteTip,
      targetUserId: _resolvedUserId, // Hedef kullanıcı ID'si (Resolved)
    );

    bool success;
    String message;

    if (_isFavorite) {
      success = await _favoriteService.removeFavorite(
        title: item.title,
        tip: item.tip,
        imageUrl: item.imageUrl,
        targetUserId: item.targetUserId,
      );
      message = success ? "Favorilerden çıkarıldı." : "Favoriden çıkarılırken bir hata oluştu.";
    } else {
      success = await _favoriteService.addFavorite(item);
      message = success ? "Favorilere eklendi!" : "Favori eklenirken bir hata oluştu.";
    }

    if (success) {
      await _checkIfFavorite();
      // Favori değişince takibi de güncelle ve istatistikleri yenile
      await _loadUserStats(_resolvedUserId);
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

    final item = FavoriteItem(
      title: widget.displayName,
      subtitle: "Bakıcı - ${widget.userName}",
      imageUrl: widget.userPhoto,
      profileImageUrl: widget.userPhoto,
      tip: "takip", // Takip için özel tip
      targetUserId: _resolvedUserId, 
    );

    bool success;
    String message;

    if (_isFollowing) {
      success = await _favoriteService.removeFavorite(
        title: item.title,
        tip: item.tip,
        imageUrl: item.imageUrl,
        targetUserId: item.targetUserId,
      );
      message = success ? "Takipten çıkıldı." : "Takipten çıkılırken hata oluştu.";
    } else {
      success = await _favoriteService.addFavorite(item);
      message = success ? "Takip ediliyor!" : "Takip edilirken hata oluştu.";
    }
    
    if (success) {
      await _checkIfFollowing();
      await _loadUserStats(_resolvedUserId); 
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Widget _buildProfileImage(double radius) {
    String path = _displayPhoto;
    if (path.isEmpty || path == 'null') {
      return CircleAvatar(
        radius: radius,
        backgroundImage: const AssetImage('assets/images/caregiver1.png'),
      );
    }
    
    if (path.startsWith('http')) {
      return ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: WebPlatformImage(
            imageUrl: path,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    
    // Asset, Base64 veya Dosya yolu
    ImageProvider provider;
    if (path.startsWith('assets/')) {
       provider = AssetImage(path);
    } else if (path.length > 255 && !path.contains('\n')) {
       try {
         provider = MemoryImage(base64Decode(path));
       } catch (_) {
         provider = const AssetImage('assets/images/caregiver1.png');
       }
    } else {
       provider = const AssetImage('assets/images/caregiver1.png');
    }

    return CircleAvatar(
      radius: radius,
      backgroundImage: provider,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ekran genişliğini alarak orantılı tasarıma yardımcı oluyoruz
    final double screenWidth = MediaQuery.of(context).size.width;
    // Profil fotoğrafı için dinamik yarıçap (Örn: Ekran genişliğinin %10'u)
    final double avatarRadius = screenWidth * 0.10;

    // Use current bio if available from state
    String displayBio = _displayBio;

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
                _buildProfileImage(avatarRadius),
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
                              _displayLocation,
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
            // Sadece başkasının profili ise göster
            if (_currentUserId != null && widget.caregiverId != null && _currentUserId != widget.caregiverId)
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
                    onPressed: _isMessageLoading ? null : () async {
                      if (!await GuestAccessService.ensureLoggedIn(context)) {
                        return;
                      }
                      
                      final targetUserId = _resolvedUserId ?? widget.caregiverId ?? widget.caregiverData?['id'];
                      if (targetUserId == null) {
                         if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Kullanıcı bilgisi eksik.')),
                            );
                         }
                         return;
                      }

                      setState(() => _isMessageLoading = true);
                      
                      try {
                        final jobId = await _chatService.startConversation(targetUserId);
                        
                        if (!mounted) return;
                        
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatConversationScreen(
                              contactName: widget.displayName,
                              contactUsername: widget.userName,
                              contactAvatar: widget.userPhoto,
                              jobId: jobId,
                              jobUserId: targetUserId,
                              jobUsername: widget.userName,
                              jobUserPhotoUrl: widget.userPhoto,
                            ),
                          ),
                        );
                      } catch (e) {
                        print("Error starting chat: $e");
                      } finally {
                        if (mounted) setState(() => _isMessageLoading = false);
                      }
                    },
                    icon: _isMessageLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primaryPurple)) 
                        : const Icon(Icons.message, color: primaryPurple),
                    label: Text(_isMessageLoading ? "..." : "Mesaj",
                        style: const TextStyle(
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
            Text(
              // Görüntüleme: Eğer parametreden gelen displayBio boşsa veya çok kısa/tekrarlı ise placeholder göster
              (displayBio.length < 10 || RegExp(r'(.)\1{4,}').hasMatch(displayBio))
                  ? "Merhaba! Ben hayvanları çok seviyorum ve onların mutluluğu benim için her şeyden önemli. Profesyonel bakım hizmetimle dostunuz emin ellerde. İhtiyaçlarınıza özel çözümler sunmak için buradayım, benimle iletişime geçmekten çekinmeyin."
                  : displayBio,
              style: TextStyle(color: Colors.grey.shade800, fontSize: 15),
            ),

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

                // Yorum Ekle Butonu - Sadece başkası ise
                if (_currentUserId != null && widget.caregiverId != null && _currentUserId != widget.caregiverId)
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
              child: _buildStatItem(_followingCount.toString(), "Takip")),
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
