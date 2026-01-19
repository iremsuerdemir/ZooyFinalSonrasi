import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // import for kIsWeb
import 'dart:convert';
import 'package:zoozy/models/favori_item.dart';
import 'package:zoozy/services/guest_access_service.dart';
import 'package:zoozy/services/favorite_service.dart';
import '../helpers/web_image.dart'; // import for WebPlatformImage

class CaregiverCardAsset extends StatefulWidget {
  final String name;
  final String imagePath;
  final String suitability;
  final bool isFavorite; // Dışarıdan favori durumunu al
  final VoidCallback? onFavoriteChanged; // Favori durumu değiştiğinde callback

  const CaregiverCardAsset({
    super.key,
    required this.name,
    required this.imagePath,
    required this.suitability,
    this.isFavorite = false,
    this.onFavoriteChanged,
  });

  @override
  State<CaregiverCardAsset> createState() => _CaregiverCardAssetState();
}

class _CaregiverCardAssetState extends State<CaregiverCardAsset> {
  final FavoriteService _favoriteService = FavoriteService();

  Future<void> _toggleFavorite() async {
    if (!await GuestAccessService.ensureLoggedIn(context)) {
      return;
    }

    final item = FavoriteItem(
      title: widget.name,
      subtitle: widget.suitability,
      imageUrl: widget.imagePath,
      profileImageUrl: "assets/images/caregiver1.png",
      tip: "caregiver",
    );

    bool isFavorite = await _favoriteService.isFavorite(
      title: item.title,
      tip: item.tip,
      imageUrl: item.imageUrl,
    );

    bool success;
    String message;

    if (isFavorite) {
      success = await _favoriteService.removeFavorite(
        title: item.title,
        tip: item.tip,
        imageUrl: item.imageUrl,
      );
      message = success
          ? "Favorilerden çıkarıldı."
          : "Favoriden çıkarılırken bir hata oluştu.";
    } else {
      success = await _favoriteService.addFavorite(item);
      message = success
          ? "Favorilere eklendi!"
          : "Favori eklenirken bir hata oluştu.";
    }

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }

    if (success && widget.onFavoriteChanged != null) {
      widget.onFavoriteChanged!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    // Kart yüksekliği responsive olarak ekran genişliğine göre ayarlanır.
    final double dynamicCardHeight = screenWidth * 0.60;

    // Hem asset hem de network görselleri, ayrıca Base64 destekle
    ImageProvider imageProvider;
    if (widget.imagePath.startsWith('http')) {
      imageProvider = NetworkImage(widget.imagePath);
    } else if (widget.imagePath.startsWith('data:image')) {
      try {
        // Base64 verisini çöz
        final base64String = widget.imagePath.contains(',')
            ? widget.imagePath.split(',').last
            : widget.imagePath;
        imageProvider = MemoryImage(base64Decode(base64String));
      } catch (e) {
        debugPrint('Base64 decode hatası: $e');
        imageProvider = const AssetImage('assets/images/caregiver1.png');
      }
    } else {
      imageProvider = AssetImage(widget.imagePath);
    }

    return Container(
      height: dynamicCardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: (kIsWeb && widget.imagePath.startsWith('http'))
                  ? WebPlatformImage(
                      imageUrl: widget.imagePath,
                      fit: BoxFit.cover,
                    )
                  : Image(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
            ),
            
            // Gölge ve Gradient
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
            // Yüksekliği dinamik yüksekliğin bir oranına (örneğin %35'i) ayarlayalım
            height: dynamicCardHeight * 0.35,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color.fromARGB(255, 67, 30, 100).withValues(alpha: 0.7),
                    const Color.fromARGB(255, 51, 27, 90).withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Favori Butonu İçin Konumlandırılmış Widget
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () async {
                await _toggleFavorite();
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.favorite,
                  color: widget.isFavorite ? Colors.redAccent : Colors.white,
                  size: 20, // Sabit boyut
                  shadows: const [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 2,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // İsim ve Detaylar İçin Konumlandırılmış Widget
          Positioned(
            left: 12,
            bottom: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    shadows: [
                      Shadow(
                        blurRadius: 3,
                        color: Colors.black45,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Yetenek Çipi (Fiyat çipi kaldırıldı, sadece bu kaldı)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.suitability,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    // SizedBox(width: 8), // Fiyat çipi kaldırıldığı için aradaki boşluk da kaldırıldı
                    // Fiyat Çipi kısmı tamamen kaldırıldı
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
     ),
    );
  }
}
