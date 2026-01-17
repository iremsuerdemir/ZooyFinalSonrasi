import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoozy/models/favori_item.dart';
import 'package:zoozy/models/comment.dart';
import 'package:zoozy/services/comment_service_http.dart';
import 'package:zoozy/services/favorite_service.dart';
import 'package:zoozy/components/comment_card.dart';
import 'package:zoozy/components/comment_dialog.dart';
import 'package:zoozy/services/guest_access_service.dart';

class MomentsPostCard extends StatefulWidget {
  final String userName;
  final String displayName;
  final String userPhoto;
  final String postImage;
  final String description;
  final int likes;
  final int comments;
  final DateTime timePosted;
  final currentUserName;
  // 👇 YENİ: Profil fotoğrafına tıklama olayını yakalamak için geri çağırım
  final VoidCallback? onProfileTap;

  const MomentsPostCard({
    Key? key,
    required this.userName,
    required this.displayName,
    required this.userPhoto,
    required this.postImage,
    required this.description,
    required this.likes,
    required this.comments,
    required this.timePosted,
    required this.currentUserName,
    this.onProfileTap, // Parametreyi ekledik
  }) : super(key: key);

  @override
  State<MomentsPostCard> createState() => _MomentsPostCardState();
}

class _MomentsPostCardState extends State<MomentsPostCard> {
  bool isFavorite = false;
  int likeCount = 0;
  final CommentServiceHttp _commentService = CommentServiceHttp();
  final FavoriteService _favoriteService = FavoriteService();
  List<Comment> _comments = [];
  bool _showComments = false;
  int? _currentUserId; // Mevcut kullanıcının userId'si
  bool _isLoggedIn = false; // Login olan kullanıcı mı?

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _checkIfFavorite();
    _loadLikeCount();
    _loadComments();
    // DEBUG: Tüm yorumları kontrol et
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _commentService.debugGetAllComments();
      if (mounted) {
        setState(() {
          _showComments = true;
        });
      }
    });
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final isGuest = await GuestAccessService.isGuest();
    if (mounted) {
      setState(() {
        _currentUserId = userId;
        _isLoggedIn = userId != null && !isGuest;
      });
    }
  }

  Future<void> _loadComments() async {
    // Moment kartı için unique cardId kullanıyoruz
    // TÜM KULLANICILARIN yorumlarını backend'den çekiyoruz
    final cardId =
        "moment_${widget.userName}_${widget.timePosted.millisecondsSinceEpoch}";

    try {
      print(
          'Yorumlar yükleniyor, cardId: $cardId, userName: ${widget.userName}');
      // userName parametresini de gönder (cardId bulunamazsa userName ile filtreleme için)
      final comments = await _commentService.getCommentsForCard(cardId,
          userName: widget.userName);
      print('Yüklenen yorum sayısı: ${comments.length}');
      if (mounted) {
        setState(() {
          _comments = comments;
        });
      }
    } catch (e) {
      print('Yorum yükleme hatası: $e');
      // Hata durumunda da mounted kontrolü yap
      if (mounted) {
        setState(() {
          _comments = [];
        });
      }
    }
  }

  Future<void> _onCommentAdded(Comment comment) async {
    final cardId =
        "moment_${widget.userName}_${widget.timePosted.millisecondsSinceEpoch}";

    print('📝 Yorum ekleniyor, cardId: $cardId');
    final success = await _commentService.addComment(cardId, comment);

    if (success) {
      print('✅ Yorum başarıyla eklendi, yorumlar yeniden yükleniyor...');

      // Yorumları anında göster
      if (mounted) {
        setState(() {
          _showComments = true;
        });
      }

      // Yorum eklendikten sonra TÜM KULLANICILARIN yorumlarını yeniden yükle
      // Kısa bir gecikme ekle (backend'in kaydetmesi için)
      await Future.delayed(const Duration(milliseconds: 300));
      await _loadComments();

      if (mounted) {
        print(
            '✅ Yorumlar gösteriliyor, toplam yorum sayısı: ${_comments.length}');
      }
    } else {
      print('❌ Yorum eklenemedi!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yorum eklenirken bir hata oluştu.')),
        );
      }
    }
  }

  void _toggleComments() {
    if (mounted) {
      setState(() {
        _showComments = !_showComments;
      });
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    try {
      final commentId = int.tryParse(comment.id);
      if (commentId == null) {
        print('❌ Geçersiz yorum ID: ${comment.id}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yorum silinirken bir hata oluştu.')),
          );
        }
        return;
      }

      print('🗑️ Yorum siliniyor: $commentId');
      final success = await _commentService.deleteComment(commentId);

      if (success) {
        print('✅ Yorum başarıyla silindi, yorumlar yeniden yükleniyor...');
        // Yorum silindikten sonra yorumları yeniden yükle
        await _loadComments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yorum başarıyla silindi.')),
          );
        }
      } else {
        print('❌ Yorum silinemedi!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yorum silinirken bir hata oluştu.')),
          );
        }
      }
    } catch (e) {
      print('❌ Yorum silme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yorum silinirken bir hata oluştu.')),
        );
      }
    }
  }

  @override
  void dispose() {
    // Widget dispose edildiğinde async işlemlerin setState çağırmasını önle
    super.dispose();
  }

  Future<void> _checkIfFavorite() async {
    final exists = await _favoriteService.isFavorite(
      title: widget.displayName,
      tip: "moments",
      imageUrl: widget.postImage,
    );

    if (mounted) {
      setState(() {
        isFavorite = exists;
      });
    }
  }

  Future<void> _loadLikeCount() async {
    try {
      final count = await _favoriteService.getFavoriteCount(
        title: widget.displayName,
        tip: "moments",
        imageUrl: widget.postImage,
      );
      if (mounted) {
        setState(() {
          likeCount = count;
        });
      }
    } catch (e) {
      print('Beğeni sayısı yükleme hatası: $e');
    }
  }

  Future<void> _showFavoriteUsers() async {
    try {
      // TÜM KULLANICILARIN favorilerini backend'den çek
      // Bu liste hem kendi hem de başkalarının favorilerini içerir
      final users = await _favoriteService.getFavoriteUsers(
        title: widget.displayName,
        tip: "moments",
        imageUrl: widget.postImage,
      );

      if (!mounted) return;

      if (users.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Henüz kimse beğenmemiş.')),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Beğenenler',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${users.length} kişi',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final String? avatar = user['photoUrl'] as String?;

                    ImageProvider<Object>? _resolveAvatar(String? avatar) {
                      if (avatar == null || avatar.isEmpty) return null;
                      try {
                        // Base64: data:image/...;base64,XXXX
                        if (avatar.startsWith('data:image/')) {
                          final base64Index = avatar.indexOf('base64,');
                          if (base64Index != -1) {
                            final base64Str = avatar.substring(base64Index + 7);
                            final bytes = base64Decode(base64Str);
                            return MemoryImage(bytes);
                          }
                        }
                        // Eski base64: base64:XXXX
                        if (avatar.startsWith('base64:')) {
                          final base64Str = avatar.substring(7);
                          final bytes = base64Decode(base64Str);
                          return MemoryImage(bytes);
                        }
                        // URL
                        if (avatar.startsWith('http://') ||
                            avatar.startsWith('https://')) {
                          return NetworkImage(avatar);
                        }
                        // Asset
                        final assetPath = avatar.startsWith('asset:')
                            ? avatar.substring(6)
                            : avatar;
                        return AssetImage(assetPath);
                      } catch (e) {
                        print(
                            '⚠️ Beğenenler avatar yükleme hatası: $e, avatar: ${avatar.length > 50 ? avatar.substring(0, 50) : avatar}');
                        return null;
                      }
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: _resolveAvatar(avatar),
                        child: (avatar == null || avatar.isEmpty)
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(user['displayName'] as String),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Beğenen kullanıcıları gösterme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Kullanıcılar yüklenirken bir hata oluştu.')),
        );
      }
    }
  }

  void toggleFavorite() async {
    if (!await GuestAccessService.ensureLoggedIn(context)) {
      return;
    }

    // Önce UI'ı güncelle
    if (mounted) {
      setState(() {
        isFavorite = !isFavorite;
      });
    }

    if (isFavorite) {
      await _favoriyeEkle();
    } else {
      await _favoridenSil();
    }

    // Favori durumunu ve beğeni sayısını backend'den yeniden yükle
    // Böylece hem kendi durumunu hem de toplam sayıyı doğru gösterir
    await _checkIfFavorite();
    await _loadLikeCount();
  }

  Future<void> _favoriyeEkle() async {
    final favItem = FavoriteItem(
      title: widget.displayName,
      subtitle: widget.description,
      imageUrl: widget.postImage,
      profileImageUrl: widget.userPhoto,
      tip: "moments",
    );

    final success = await _favoriteService.addFavorite(favItem);
    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Favorilere eklendi!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Favori eklenirken bir hata oluştu.")));
    }
  }

  Future<void> _favoridenSil() async {
    final success = await _favoriteService.removeFavorite(
      title: widget.displayName,
      tip: "moments",
      imageUrl: widget.postImage,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Favorilerden kaldırıldı!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Favoriden kaldırılırken bir hata oluştu.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            // 👇 Profil resmine tıklama ekleme
            leading: GestureDetector(
              onTap: widget.onProfileTap,
              child: CircleAvatar(
                backgroundImage: AssetImage(widget.userPhoto),
                radius: 24,
              ),
            ),
            // 👇 DisplayName'e tıklama ekleme (isteğe bağlı, ListTile'ın onTap'i yerine)
            title: GestureDetector(
              onTap: widget.onProfileTap,
              child: Text(widget.displayName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            subtitle: Text('@${widget.userName}',
                style: const TextStyle(color: Colors.blueAccent)),
            trailing: Text(
              timeAgo(widget.timePosted),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              widget.postImage,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: toggleFavorite,
                  onLongPress: _showFavoriteUsers,
                  child: IconButton(
                    iconSize: 28,
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey[600],
                    ),
                    onPressed: toggleFavorite,
                  ),
                ),
                Text('$likeCount',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 20),
                IconButton(
                  iconSize: 26,
                  icon: const Icon(Icons.mode_comment_outlined,
                      color: Colors.grey),
                  onPressed: () async {
                    if (!await GuestAccessService.ensureLoggedIn(context)) {
                      return;
                    }
                    showDialog(
                      context: context,
                      builder: (context) => CommentDialog(
                        currentUserName: widget.currentUserName,
                        cardId:
                            "moment_${widget.userName}_${widget.timePosted.millisecondsSinceEpoch}",
                        onCommentAdded: _onCommentAdded,
                      ),
                    );
                  },
                ),
                Text('${_comments.length}',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (_showComments)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _comments.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Henüz yorum yok',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : Column(
                      children: _comments
                          .map((comment) => CommentCard(
                                comment: comment,
                                currentUserId: _currentUserId?.toString(),
                                onDelete: () => _deleteComment(comment),
                                isLoggedIn: _isLoggedIn,
                              ))
                          .toList(),
                    ),
            ),
          TextButton(
            onPressed: () {
              _toggleComments();
              // Yorumları gösterirken yeniden yükle
              if (!_showComments) {
                _loadComments();
              }
            },
            child: Text(_showComments
                ? 'Yorumları Gizle'
                : 'Yorumları Göster (${_comments.length})'),
          ),
        ],
      ),
    );
  }

  String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays >= 1) return '${difference.inDays} gün önce';
    if (difference.inHours >= 1) return '${difference.inHours} saat önce';
    if (difference.inMinutes >= 1) return '${difference.inMinutes} dakika önce';
    return 'Az önce';
  }
}
