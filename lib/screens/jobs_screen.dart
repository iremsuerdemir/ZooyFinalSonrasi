import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:zoozy/components/bottom_navigation_bar.dart';
import 'package:zoozy/screens/agreement_screen.dart';
import 'package:zoozy/screens/indexbox_message.dart';
import 'package:zoozy/screens/minimal_calendar_page.dart';
import 'package:zoozy/screens/profile_screen.dart';
import 'package:zoozy/screens/help_center_page.dart';
import 'package:zoozy/services/guest_access_service.dart';
import 'package:zoozy/services/request_service.dart';
import 'package:zoozy/screens/pet_walk_page.dart';
import 'package:zoozy/screens/chat_conversation_screen.dart';
import 'package:zoozy/services/notification_service.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> with WidgetsBindingObserver {
  // Seçilen ikon index'i
  int selectedIndex = 0;

  // Backend'den gelen job'lar
  List<Map<String, dynamic>> _jobsList = [];
  final RequestService _requestService = RequestService();
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = true;
  bool _hasUnreadNotifications = false;

  // Renk paleti
  static const Color primaryPurple = Color.fromARGB(255, 111, 79, 172);
  static const Color softPink = Color(0xFFF48FB1);
  static const Color cardIconBgColor = Color(0xFFF3E5F5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadJobs();
    _checkNotifications();
    // Periyodik olarak bildirimleri kontrol et (her 10 saniyede bir)
    _startNotificationPolling();
  }

  void _startNotificationPolling() {
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _checkNotifications();
        _startNotificationPolling(); // Tekrar başlat
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Uygulama foreground'a geldiğinde job'ları yenile
    if (state == AppLifecycleState.resumed) {
      _loadJobs();
      _checkNotifications();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Build tamamlandıktan sonra yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadJobs();
      _checkNotifications();
    });
  }

  /// Bildirimleri kontrol et
  Future<void> _checkNotifications() async {
    try {
      final isGuest = await GuestAccessService.isGuest();
      if (isGuest) {
        if (mounted) {
          setState(() {
            _hasUnreadNotifications = false;
          });
        }
        return;
      }

      final notifications = await _notificationService.getNotifications();
      final hasUnread = notifications.any((n) => !n.isRead);
      if (mounted) {
        setState(() {
          _hasUnreadNotifications = hasUnread;
        });
      }
    } catch (e) {
      print('Bildirim kontrol hatası: $e');
    }
  }

  /// Tüm bildirimleri okundu yap
  Future<void> _markAllNotificationsAsRead() async {
    try {
      final notifications = await _notificationService.getNotifications();
      final unreadNotifications =
          notifications.where((n) => !n.isRead).toList();

      for (var notification in unreadNotifications) {
        await _notificationService.markAsRead(notification.id);
      }

      // Bildirimleri tekrar kontrol et
      await _checkNotifications();
    } catch (e) {
      print('Bildirim okundu işaretleme hatası: $e');
    }
  }

  /// Backend'den tüm kullanıcıların job'larını yükle (global feed)
  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final jobs = await _requestService.getOtherUsersRequests();
      setState(() {
        _jobsList = jobs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Job\'lar yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Hizmet ikonunu belirle
  IconData _getServiceIcon(String serviceName) {
    final lower = serviceName.toLowerCase();
    if (lower.contains("gezdirme") || lower.contains("gezdir"))
      return Icons.directions_walk;
    if (lower.contains("pansiyonu") || lower.contains("otel"))
      return Icons.home_filled;
    if (lower.contains("günlük bakım") || lower.contains("bakım"))
      return Icons.light_mode;
    if (lower.contains("taksi")) return Icons.local_taxi;
    if (lower.contains("tımar")) return Icons.cut;
    if (lower.contains("eğitim")) return Icons.school;
    if (lower.contains("fotoğraf")) return Icons.photo_camera;
    if (lower.contains("veteriner")) return Icons.health_and_safety;
    return Icons.miscellaneous_services;
  }

  Widget _buildIconTextCard(IconData icon, String text) {
    bool isSelected = _getIndexFromText(text) == selectedIndex;

    return GestureDetector(
      onTap: () async {
        if (text == "Köpek Gezdir" || text == "Yardım") {
          final allowed = await GuestAccessService.ensureLoggedIn(context);
          if (allowed) {
            if (text == "Köpek Gezdir") {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PetWalkPage()),
              );
            } else if (text == "Yardım") {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpCenterPage()),
              );
            }
          }
        } else if (text == "Takvim") {
          // Takvim ikonuna basıldığında yönlendirme
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MinimalCalendarPage(),
            ),
          );
        } else {
          setState(() {
            selectedIndex = _getIndexFromText(text);
          });
        }
      },
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isSelected ? primaryPurple : cardIconBgColor,
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : primaryPurple,
              size: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.black87 : Colors.black54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  int _getIndexFromText(String text) {
    switch (text) {
      case "İş Listeleri":
        return 0;
      case "Takvim":
        return 1;
      case "Köpek Gezdir":
        return 2;
      case "Yardım":
        return 3;
      default:
        return 0;
    }
  }

  /// Job kartı widget'ı
  Widget _buildJobCard(Map<String, dynamic> job) {
    final serviceName = job['serviceName'] ?? '';
    final petName = job['petName'] ?? '';
    final location = job['location'] ?? '';
    final note = job['note'] ?? '';
    final startDateStr = job['startDate'];
    final endDateStr = job['endDate'];

    String? dateRangeText;
    if (startDateStr != null && endDateStr != null) {
      try {
        final startDate = DateTime.parse(startDateStr);
        final endDate = DateTime.parse(endDateStr);
        dateRangeText =
            '${startDate.day}.${startDate.month}.${startDate.year} - ${endDate.day}.${endDate.month}.${endDate.year}';
      } catch (_) {
        dateRangeText = null;
      }
    }

    // Job'u oluşturan kullanıcının bilgilerini kullan
    final userDisplayName = job['createdByName'] as String? ?? job['userDisplayName'] as String? ?? 'Kullanıcı';
    final userPhotoUrl = job['userPhotoUrl'];

    ImageProvider<Object>? _resolveUserAvatar(String? avatar) {
      if (avatar == null || avatar.isEmpty) {
        return null;
      }

      try {
        // Base64 formatı: "data:image/png;base64,..." veya "data:image/jpeg;base64,..."
        if (avatar.startsWith('data:image/')) {
          final base64Index = avatar.indexOf('base64,');
          if (base64Index != -1) {
            final base64Str =
                avatar.substring(base64Index + 7); // "base64," = 7 karakter
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
        print('⚠️ JobsScreen avatar yükleme hatası: $e');
        return null;
      }
    }

    return GestureDetector(
      onTap: () async {
        // Login kontrolü
        final allowed = await GuestAccessService.ensureLoggedIn(context);
        if (!allowed) {
          return;
        }

        // Job bilgilerini al
        final jobId = job['id'] as int?;
        // Job'u oluşturan kullanıcının bilgilerini kullan
        final jobUserId = job['createdByUserId'] as int? ?? job['userId'] as int?;
        final jobUsername = job['createdByName'] as String? ?? job['userDisplayName'] as String? ?? 'Kullanıcı';
        final jobUserPhotoUrl = job['userPhotoUrl'] as String? ?? '';

        if (jobId == null || jobUserId == null) {
          return;
        }

        // ChatConversationScreen'e yönlendir
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatConversationScreen(
              jobId: jobId,
              jobUserId: jobUserId,
              jobUsername: jobUsername,
              jobUserPhotoUrl: jobUserPhotoUrl,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kullanıcı bilgisi
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: primaryPurple.withOpacity(0.2),
                  backgroundImage: _resolveUserAvatar(userPhotoUrl),
                  child: (userPhotoUrl == null || userPhotoUrl.isEmpty)
                      ? const Icon(Icons.person, color: primaryPurple)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userDisplayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        serviceName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Hizmet detayları
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardIconBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getServiceIcon(serviceName),
                    color: primaryPurple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (petName.isNotEmpty)
                        Text(
                          'Evcil Hayvan: $petName',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryPurple,
                          ),
                        ),
                      const SizedBox(height: 4),
                      if (dateRangeText != null) ...[
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              dateRangeText,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (location.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                note,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 50,
        title: const Row(
          children: [
            Icon(Icons.pets, color: primaryPurple, size: 28),
            SizedBox(width: 8),
            Text(
              "Zoozy",
              style: TextStyle(
                color: primaryPurple,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: primaryPurple,
                  size: 24,
                ),
                onPressed: () async {
                  final allowed =
                      await GuestAccessService.ensureLoggedIn(context);
                  if (allowed) {
                    // Bildirimleri okundu yap (kırmızı nokta gitsin)
                    await _markAllNotificationsAsRead();
                    // State'i hemen güncelle (kırmızı nokta anında kaybolsun)
                    if (mounted) {
                      setState(() {
                        _hasUnreadNotifications = false;
                      });
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => IndexboxMessageScreen(),
                      ),
                    ).then((notificationsRead) {
                      // Eğer tike basıldıysa (notificationsRead == true), kırmızı noktayı hemen kaldır
                      if (notificationsRead == true) {
                        if (mounted) {
                          setState(() {
                            _hasUnreadNotifications = false;
                          });
                        }
                      } else {
                        // Normal şekilde sayfadan dönüldüyse, bildirimleri tekrar kontrol et
                        _checkNotifications();
                      }
                    });
                  }
                },
              ),
              if (_hasUnreadNotifications)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadJobs,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: screenHeight * 0.35,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryPurple, softPink],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Positioned(
                  left: screenWidth / 2 - 80,
                  top: 20,
                  child: Transform.scale(
                    scale: 1.3,
                    child: Image.asset(
                      'assets/images/jobs.png',
                      height: 160,
                      width: 160,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  top: screenHeight * 0.25,
                  left: screenWidth * 0.06,
                  right: screenWidth * 0.06,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildIconTextCard(Icons.list_alt, "İş Listeleri"),
                        _buildIconTextCard(Icons.calendar_month, "Takvim"),
                        _buildIconTextCard(Icons.pets, "Köpek Gezdir"),
                        _buildIconTextCard(Icons.help_outline, "Yardım"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 100),

            // Loading durumu
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(
                    color: primaryPurple,
                  ),
                ),
              )
            // Job kartları
            else if (_jobsList.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mevcut İş İlanları',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._jobsList.map((job) => _buildJobCard(job)),
                  ],
                ),
              )
            // Boş durum
            else
              Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: primaryPurple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.pets, size: 60, color: primaryPurple),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "Henüz iş ilanı yok.\nYeni ilanlar burada görünecek.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryPurple,
                      side: const BorderSide(color: primaryPurple, width: 1.5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      if (!await GuestAccessService.ensureLoggedIn(context)) {
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AgreementScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "HİZMET SUN",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 3,
        selectedColor: primaryPurple,
        unselectedColor: Colors.grey[700]!,
        onTap: (index) {
          if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const JobsScreen()),
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
}
