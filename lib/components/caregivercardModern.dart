import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kIsWeb için
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zoozy/models/favori_item.dart';
import 'package:zoozy/helpers/web_image.dart'; // Web platform image helper
import 'package:zoozy/services/guest_access_service.dart';
import 'package:zoozy/services/favorite_service.dart';

// Tema Renkleri
const Color _primaryColor = Colors.deepPurple;
const Color _accentColor = Color(0xFFF06292); // Pembe tonu
const Color _backgroundColor = Color(0xFFF3E5F5); // Açık lila arka plan

class CaregiverCardBalanced extends StatefulWidget {
  final String name;
  final String imagePath;
  final String suitability;
  final bool isFavorite;
  final VoidCallback? onFavoriteChanged;
  final String tip; // "caregiver" veya "explore"
  final VoidCallback? onTap; // Kart tıklama eventi

  const CaregiverCardBalanced({
    super.key,
    required this.name,
    required this.imagePath,
    required this.suitability,
    this.isFavorite = false,
    this.onFavoriteChanged,
    this.tip = "caregiver", // Varsayılan değer
    this.onTap,
  });

  @override
  State<CaregiverCardBalanced> createState() => _CaregiverCardBalancedState();
}

class _CaregiverCardBalancedState extends State<CaregiverCardBalanced> {
  final FavoriteService _favoriteService = FavoriteService();
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
  }

  @override
  void didUpdateWidget(CaregiverCardBalanced oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorite != oldWidget.isFavorite) {
      _isFavorite = widget.isFavorite;
    }
  }

  ImageProvider _getImageProvider(String path) {
    if (path.isEmpty || path == 'null') { // Boşsa veya string olarak null gelirse placeholder dön
       return const AssetImage('assets/images/caregiver1.png');
    }

    if (path.startsWith('http')) {
      return NetworkImage(path);
    } else if (path.startsWith('assets/')) { // Zaten asset ise direkt döndür
      return AssetImage(path);
    } // Eğer bir dosya yolu ise (C:\.... veya /data/...) ve local dosya ise
      else if (path.contains('/') || path.contains('\\')) {
       // Web'de dosya sistemi çalışmaz ancak mobil için FileImage kullanılabilir.
       // Güvenli olması adına base64 kontrolünü sona saklayıp,
       // Eğer path çok uzunsa (muhtemelen base64) base64 dene, değilse dosya san
       if (path.length > 255 && !path.contains('\n')) {
          try {
            return MemoryImage(base64Decode(path));
          } catch (_) {
             return const AssetImage('assets/images/caregiver1.png');
          }
       }
       // Eğer dosya yolu ise (local path), File class'ı gerekir.
       // Şimdilik asset fallback'i veriyoruz çünkü File import'u yoksa hata alabiliriz.
       // Ancak gelişmiş kullanımda 'dart:io' import edilip File(path) kullanılmalıdır.
       // Projenizdeki resim yolları lokal disk yolu gösterdiği için (C:\Users...)
       // bu resimler emülatör/cihaz içinden erişilemez (sadece o bilgisayarda var).
       // Bu yüzden varsayılan bir görsel göstermek en doğrusu olacaktır.
       return const AssetImage('assets/images/caregiver1.png'); 
    } else {
      try {
        // Base64 decoding
        return MemoryImage(base64Decode(path));
      } catch (_) {
        return const AssetImage('assets/images/caregiver1.png');
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (!await GuestAccessService.ensureLoggedIn(context)) {
      return;
    }

    final item = FavoriteItem(
      title: widget.name,
      subtitle: widget.suitability,
      imageUrl: widget.imagePath,
      profileImageUrl: "assets/images/caregiver1.png",
      tip: widget.tip, 
    );

    // Optimistik güncelleme: UI'ı hemen değiştir
    final bool previousState = _isFavorite;
    setState(() {
      _isFavorite = !_isFavorite;
    });

    bool success;
    String message;

    // Önceki duruma göre işlem yap (true ise çıkar, false ise ekle)
    if (previousState) {
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
      // Hata durumunda UI'ı eski haline getir
      if (!success) {
        setState(() {
          _isFavorite = previousState;
        });
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }

    if (success) {
      widget.onFavoriteChanged?.call();
    }
  }

  Widget _buildImage() {
    final String cleanPath = widget.imagePath.trim();
    if (cleanPath.startsWith('http')) {
      // WEB PLATFORMU İÇİN (HTML ELEMENT)
      if (kIsWeb) {
        // Flutter Web'de (özellikle CanvasKit) Google resimleri CORS/429 hatası verebilir.
        // Bu yüzden tarayıcının yerel <img> etiketini kullanan PlatformView çözümünü kullanıyoruz.
        return WebPlatformImage(
          imageUrl: cleanPath,
          fit: BoxFit.cover,
        );
      }

      // MOBİL (Android/iOS) İÇİN CACHED NETWORK IMAGE
      return CachedNetworkImage(
        imageUrl: cleanPath,
        // Mobilde User-Agent bazen işe yarar ama Web'de hata sebebidir. 
        // Burada siliyoruz veya sadece mobil için eklenebilir.
        // httpHeaders: const { 'User-Agent': '...' }, // Riskli, kaldırıldı.
        
        imageBuilder: (context, imageProvider) => Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
        placeholder: (context, url) => Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _primaryColor.withOpacity(0.5),
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          debugPrint('⚠️ Cache hatası ($url): $error');
          return Container(
             decoration: const BoxDecoration(
               image: DecorationImage(
                 image: NetworkImage('https://avatars.mds.yandex.net/i?id=352630c4f79bc376f3c88c1d532872f80e30cdc6-5363089-images-thumbs&n=13'),
                 fit: BoxFit.cover,
                 alignment: Alignment.topCenter,
               ),
             ),
          );
        },
      );
    }
    
    // For Assets, Base64 or local files
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: _getImageProvider(widget.imagePath),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: widget.onTap,
          child: SizedBox( // Column'ı belirli bir boyutlandırma içine alıyoruz
            height: 250, // Sabit bir yükseklik veya başka bir kısıtlama
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // IMAGE AREA
                Expanded(
                  flex: 3,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _buildImage(),
                    ),
                    // Gradient overlay

                    // Gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.25),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // FAVORITE BUTTON (Glassmorphism effect)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: _toggleFavorite,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.25),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.favorite,
                            size: 22,
                            color: _isFavorite
                                ? _accentColor
                                : Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // INFO AREA
              Expanded(
                flex: 2,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        widget.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.black87,
                          letterSpacing: 0.2,
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _primaryColor.withValues(alpha: 0.12),
                              _primaryColor.withValues(alpha: 0.06),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _primaryColor.withValues(alpha: 0.2),
                            width: 0.7,
                          ),
                        ),
                        child: Text(
                          widget.suitability,
                          style: TextStyle(
                            color: _primaryColor.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
