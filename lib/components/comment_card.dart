import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:zoozy/models/comment.dart';

class CommentCard extends StatelessWidget {
  final Comment comment;
  final String? currentUserId; // Mevcut kullanıcının userId'si
  final VoidCallback? onDelete; // Silme callback'i
  final bool isLoggedIn; // Login olan kullanıcı mı?

  const CommentCard({
    Key? key,
    required this.comment,
    this.currentUserId,
    this.onDelete,
    this.isLoggedIn = false,
  }) : super(key: key);

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) return '${difference.inDays} gün önce';
    if (difference.inHours > 0) return '${difference.inHours} saat önce';
    if (difference.inMinutes > 0) return '${difference.inMinutes} dakika önce';
    return 'Az önce';
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? _resolveAvatar(String? avatar) {
      if (avatar == null || avatar.isEmpty) {
        return const AssetImage('assets/images/caregiver1.png');
      }

      try {
        // Base64 formatı: "data:image/png;base64,..." veya "data:image/jpeg;base64,..."
        if (avatar.startsWith('data:image/')) {
          // "data:image/png;base64," veya "data:image/jpeg;base64," kısmını atla
          final base64Index = avatar.indexOf('base64,');
          if (base64Index != -1) {
            final base64Str = avatar.substring(base64Index + 7); // "base64," = 7 karakter
            final bytes = base64Decode(base64Str);
            return MemoryImage(bytes);
          }
        }

        // Base64 formatı: "base64:..." (eski format)
        if (avatar.startsWith('base64:')) {
          final base64Str = avatar.substring(7);
          final bytes = base64Decode(base64Str);
          return MemoryImage(bytes);
        }

        // HTTP/HTTPS URL formatı
        if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
          return NetworkImage(avatar);
        }

        // Asset formatı: "asset:..." veya direkt path
        final assetPath =
            avatar.startsWith('asset:') ? avatar.substring(6) : avatar;
        return AssetImage(assetPath);
      } catch (e) {
        print('⚠️ Avatar yükleme hatası: $e, avatar: ${avatar.substring(0, avatar.length > 50 ? 50 : avatar.length)}');
        return const AssetImage('assets/images/caregiver1.png');
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: _resolveAvatar(comment.authorAvatar),
                  onBackgroundImageError: (exception, stackTrace) {
                    // Hata durumunda varsayılan resim göster
                  },
                  child: (comment.authorAvatar == null ||
                          comment.authorAvatar!.isEmpty)
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatDate(comment.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        index < comment.rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      );
                    }),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    comment.message,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                // Sil ikonu - Sadece login olan kullanıcı ve kendi yorumu için
                if (isLoggedIn &&
                    currentUserId != null && 
                    comment.userId != null && 
                    currentUserId == comment.userId &&
                    onDelete != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        // Silme onayı
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Yorumu Sil'),
                              content: const Text('Bu yorumu silmek istediğinize emin misiniz?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('İptal'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    onDelete?.call();
                                  },
                                  child: const Text('Sil', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.red[300],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
