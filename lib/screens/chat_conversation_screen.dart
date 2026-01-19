import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zoozy/screens/edit_profile.dart';
import 'package:zoozy/services/chat_service.dart';

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final String? imagePath;
  final Uint8List? imageBytes;

  const ChatMessage({
    required this.text,
    required this.timestamp,
    this.isMe = false,
    this.imagePath,
    this.imageBytes,
  });

  bool get hasImage => imagePath != null || imageBytes != null;

  Map<String, dynamic> toJson() => {
    'text': text,
    'isMe': isMe,
    'timestamp': timestamp.toIso8601String(),
    'imagePath': imagePath,
    'imageBytes': imageBytes != null ? base64Encode(imageBytes!) : null,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    Uint8List? bytes;
    final imageBytesString = json['imageBytes'] as String?;
    if (imageBytesString != null && imageBytesString.isNotEmpty) {
      try {
        bytes = base64Decode(imageBytesString);
      } catch (_) {
        bytes = null;
      }
    }
    return ChatMessage(
      text: json['text'] as String? ?? '',
      isMe: json['isMe'] as bool? ?? false,
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      imagePath: json['imagePath'] as String?,
      imageBytes: bytes,
    );
  }
}

class ChatConversationScreen extends StatefulWidget {
  // Eski parametreler (mevcut yapıyı korumak için)
  final String? contactName;
  final String? contactUsername;
  final String? contactAvatar;
  final String? phoneNumber;
  final String quoteAmount;
  final String statusMessage;
  final List<ChatMessage> messages;

  // Yeni parametreler (backend tabanlı chat için)
  final int? jobId;
  final int? jobUserId;
  final String? jobUsername;
  final String? jobUserPhotoUrl;

  const ChatConversationScreen({
    super.key,
    // Eski parametreler
    this.contactName,
    this.contactUsername,
    this.contactAvatar,
    this.phoneNumber,
    this.quoteAmount = '',
    this.statusMessage = '',
    this.messages = const [],
    // Yeni parametreler
    this.jobId,
    this.jobUserId,
    this.jobUsername,
    this.jobUserPhotoUrl,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _listController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  String _currentUserName = '';
  int? _currentUserId;
  ImageProvider? _currentUserAvatar;
  List<ChatMessage> _messages = [];
  SharedPreferences? _prefs;
  final ChatService _chatService = ChatService();
  bool _isLoadingMessages = false;
  bool _isBackendMode = false; // Backend tabanlı mod mu?
  bool _isConversationCleared = false;

  String get _historyKey =>
      'chat_history_${(widget.contactUsername ?? widget.jobUsername ?? "unknown").replaceAll(' ', '_')}';
  String get _deletedKey =>
      'chat_deleted_${(widget.contactUsername ?? widget.jobUsername ?? "unknown").replaceAll(' ', '_')}';
  String get _clearedKey =>
      'chat_cleared_${(widget.contactUsername ?? widget.jobUsername ?? "unknown").replaceAll(' ', '_')}';

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCurrentUser(_prefs!);

    _isConversationCleared = _prefs?.getBool(_clearedKey) ?? false;

    // Backend modunu kontrol et
    _isBackendMode = widget.jobId != null && widget.jobUserId != null;

    if (_isBackendMode) {
      // Backend'den mesajları yükle
      await _loadMessagesFromBackend();
    } else {
      // Eski yapı: SharedPreferences'tan yükle
      final loaded = await _loadMessagesFromStorage();
      if (mounted) {
        setState(() {
          _messages = loaded;
        });
      }
    }
  }

  Future<void> _loadMessagesFromBackend() async {
    if (widget.jobId == null) return;

    final isCleared = _prefs?.getBool(_clearedKey) ?? false;
    if (isCleared) {
      if (mounted) {
        setState(() {
          _messages = [];
          _isLoadingMessages = false;
        });
      }
      return;
    }

    setState(() {
      _isLoadingMessages = true;
    });

    try {
      final messages = await _chatService.getMessages(widget.jobId!);

      // Backend'den gelen mesajları ChatMessage formatına dönüştür
      final backendMessages = messages
          .where((msg) => msg.messageText.isNotEmpty) // Placeholder (boş) mesajları filtrele
          .map((msg) {
        final isMe = msg.senderId == _currentUserId;
        return ChatMessage(
          text: msg.messageText,
          isMe: isMe,
          timestamp: msg.createdAt,
        );
      }).toList();

      // Merge Logic: Backend ve Yerel Veriyi Birleştir
      final prefs = _prefs ??= await SharedPreferences.getInstance();

      // 1. Silinme kontrolü
      final isDeletedLocal = prefs.getBool(_deletedKey) ?? false;
      final backendDeletedKey =
          'chat_deleted_job_${widget.jobId}_user_${widget.jobUserId}';
      final isBackendDeleted = prefs.getBool(backendDeletedKey) ?? false;

      if (isDeletedLocal || isBackendDeleted) {
        if (mounted) {
          setState(() {
            _messages = [];
            _isLoadingMessages = false;
          });
        }
        return;
      }

      // 2. Geçmiş kontrolü ve birleştirme
      final rawHistory = prefs.getString(_historyKey);
      List<ChatMessage> finalMessages = backendMessages;

      if (rawHistory != null && rawHistory != '[]') {
        try {
          final List<dynamic> decoded = jsonDecode(rawHistory) as List<dynamic>;
          final localMessages = decoded
              .map(
                (e) => ChatMessage.fromJson(
                  Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
                ),
              )
              .toList();

          if (localMessages.isNotEmpty) {
            // Son yerel mesajın zamanına bak
            final lastLocalTimestamp = localMessages.last.timestamp;

            // Backend'den sadece bu zamandan SONRA gelen yeni mesajları al
            final newBackendMessages = backendMessages
                .where((bm) => bm.timestamp.isAfter(lastLocalTimestamp))
                .toList();

            // Local (içeriği temizlenmiş olabilir) + Yeni Backend Mesajları
            finalMessages = [...localMessages, ...newBackendMessages];

            // Güncel hali tekrar kaydet
            await _saveMessages(finalMessages, markAsActive: true);
          }
        } catch (e) {
          print('Local history parse hatası: $e');
        }
      } else if (rawHistory == null) {
        // İlk kez yükleniyor veya history silinmiş -> Local'e kaydet
        await _saveMessages(finalMessages, markAsActive: true);
      }
      // rawHistory == '[]' ise backend verisi kullanılsın (veya boş kalsın tercihe göre, şimdilik backend)

      if (mounted) {
        setState(() {
          _messages = finalMessages;
          _isLoadingMessages = false;
        });
      }
    } catch (e) {
      print('Backend mesaj yükleme hatası: $e');
      if (mounted) {
        setState(() {
          _isLoadingMessages = false;
        });
      }
    }
  }

  Future<void> _loadCurrentUser(SharedPreferences prefs) async {
    final username = prefs.getString('username') ?? 'Kullanıcı';
    final userId = prefs.getInt('userId');
    final imageString = prefs.getString('profileImagePath');
    ImageProvider? avatar;

    if (imageString != null && imageString.isNotEmpty) {
      try {
        avatar = MemoryImage(base64Decode(imageString));
      } catch (_) {
        avatar = null;
      }
    }

    if (mounted) {
      setState(() {
        _currentUserName = username;
        _currentUserId = userId;
        _currentUserAvatar = avatar;
      });
    }
  }

  Widget _buildRobustAvatar(String? avatar, String name, {double radius = 26}) {
    if (avatar != null && avatar.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          avatar,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: radius * 2,
              height: radius * 2,
              color: Colors.grey,
              alignment: Alignment.center,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(color: Colors.white, fontSize: radius * 0.7),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: radius * 2,
              height: radius * 2,
              color: Colors.grey[200],
              child: Center(
                  child: SizedBox(
                width: radius,
                height: radius,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )),
            );
          },
        ),
      );
    }

    final imageProvider = _buildContactAvatar();
    return CircleAvatar(
      radius: radius,
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(color: Colors.white, fontSize: radius * 0.7),
            )
          : null,
    );
  }

  ImageProvider? _buildContactAvatar() {
    final avatar = _isBackendMode
        ? widget.jobUserPhotoUrl
        : widget.contactAvatar;
    if (avatar == null || avatar.isEmpty) return null;

    if (avatar.startsWith('http')) {
      return NetworkImage(avatar);
    }
    if (avatar.startsWith('assets/')) {
      return AssetImage(avatar);
    }
    if (avatar.startsWith('data:image/')) {
      try {
        final base64Index = avatar.indexOf('base64,');
        if (base64Index != -1) {
          final base64Str = avatar.substring(base64Index + 7);
          final bytes = base64Decode(base64Str);
          return MemoryImage(bytes);
        }
      } catch (_) {}
    }
    if (avatar.startsWith('base64:')) {
      try {
        final base64Str = avatar.substring(7);
        final bytes = base64Decode(base64Str);
        return MemoryImage(bytes);
      } catch (_) {}
    }
    if (avatar.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(avatar));
      } catch (_) {}
    }
    return null;
  }

  String get _contactUsername {
    return _isBackendMode
        ? (widget.jobUsername ?? 'Kullanıcı')
        : (widget.contactUsername ?? 'Kullanıcı');
  }

  String get _contactName {
    return _isBackendMode
        ? (widget.jobUsername ?? 'Kullanıcı')
        : (widget.contactName ?? 'Kullanıcı');
  }

  Future<List<ChatMessage>> _loadMessagesFromStorage() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final rawHistory = prefs.getString(_historyKey);
    final isDeleted = prefs.getBool(_deletedKey) ?? false;

    if (rawHistory != null) {
      try {
        final List<dynamic> decoded = jsonDecode(rawHistory) as List<dynamic>;
        return decoded
            .map(
              (e) => ChatMessage.fromJson(
                Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
              ),
            )
            .toList();
      } catch (_) {
        return List.of(widget.messages);
      }
    }

    if (isDeleted) {
      return [];
    }

    final initialMessages = List.of(widget.messages);
    await _saveMessages(initialMessages, markAsActive: true);
    return initialMessages;
  }

  Future<void> _saveMessages(
    List<ChatMessage> messages, {
    bool markAsActive = true,
  }) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      messages.map((message) => message.toJson()).toList(),
    );
    await prefs.setString(_historyKey, encoded);
    if (markAsActive) {
      await prefs.setBool(_deletedKey, false);
    }
  }

  Future<void> _openWhatsApp({bool isVideo = false}) async {
    // Telefon numarasını SharedPreferences'tan al
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    String? phoneNumber = widget.phoneNumber;

    // Eğer widget'tan telefon numarası yoksa, SharedPreferences'tan al
    if (phoneNumber == null || phoneNumber.isEmpty) {
      phoneNumber = prefs.getString('phone');
    }

    if (phoneNumber == null || phoneNumber.isEmpty) {
      // Telefon numarası yoksa profil ekranına yönlendir
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Telefon Numarası Bulunamadı'),
            content: const Text(
              'Kayıtlı telefon bulunamadı. Profil ekranına yönlendiriliyorsunuz, lütfen buraya numaranızı giriniz.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const EditProfileScreen(shouldReturnToChat: true),
                    ),
                  ).then((phoneSaved) {
                    // Profil ekranından dönünce telefon numarasını tekrar kontrol et
                    if (phoneSaved == true) {
                      // Telefon numarası kaydedildi, 5-6 saniye bekle sonra WhatsApp'ı aç
                      Future.delayed(const Duration(seconds: 5), () {
                        if (mounted) {
                          _openWhatsApp(isVideo: isVideo);
                        }
                      });
                    }
                  });
                },
                child: const Text('Profili Düzenle'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Telefon numarasını temizle ve WhatsApp formatına çevir
    // Eğer + ile başlıyorsa kaldır, sadece rakamları al
    String sanitized = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Eğer + ile başlıyorsa kaldır
    if (sanitized.startsWith('+')) {
      sanitized = sanitized.substring(1);
    }

    // Eğer numara 10 haneli ve 5 ile başlıyorsa (Türkiye cep telefonu), 90 ekle
    if (sanitized.length == 10 && sanitized.startsWith('5')) {
      sanitized = '90$sanitized';
    }

    if (sanitized.isEmpty) {
      // Telefon numarası geçersizse profil ekranına yönlendir
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Telefon Numarası Bulunamadı'),
            content: const Text(
              'Kayıtlı telefon bulunamadı. Profil ekranına yönlendiriliyorsunuz, lütfen buraya numaranızı giriniz.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const EditProfileScreen(shouldReturnToChat: true),
                    ),
                  ).then((phoneSaved) {
                    // Profil ekranından dönünce telefon numarasını tekrar kontrol et
                    if (phoneSaved == true) {
                      // Telefon numarası kaydedildi, 5-6 saniye bekle sonra WhatsApp'ı aç
                      Future.delayed(const Duration(seconds: 5), () {
                        if (mounted) {
                          _openWhatsApp(isVideo: isVideo);
                        }
                      });
                    }
                  });
                },
                child: const Text('Profili Düzenle'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // WhatsApp açılırken "Lütfen bekleyiniz" mesajı göster
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bekleyiniz...'),
          duration: Duration(seconds: 3),
        ),
      );
    }

    final encodedMessage = Uri.encodeComponent(
      isVideo
          ? 'Merhaba $_contactName, WhatsApp üzerinden görüntülü görüşme başlatıyorum.'
          : 'Merhaba $_contactName, Zoozy üzerinden yazıyorum.',
    );
    final uri = Uri.parse('https://wa.me/$sanitized?text=$encodedMessage');

    // Kısa bir gecikme ekle (kullanıcı mesajı görebilsin)
    await Future.delayed(const Duration(milliseconds: 500));

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('WhatsApp açılamadı.')));
      }
    } else {
      // WhatsApp başarıyla açıldı, snackbar'ı kapat
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    if (_isBackendMode) {
      // Backend'e mesaj gönder
      if (widget.jobId != null &&
          widget.jobUserId != null &&
          _currentUserId != null) {
        final message = await _chatService.sendMessage(
          receiverId: widget.jobUserId!,
          jobId: widget.jobId!,
          messageText: text,
        );

        if (message != null) {
          // Mesaj başarıyla gönderildi, UI'ı güncelle
          final chatMessage = ChatMessage(
            text: text,
            isMe: true,
            timestamp: DateTime.now(),
          );
          _addMessage(chatMessage);

          // Backend'den tüm mesajları yeniden yükle (güncel durum için)
          await _loadMessagesFromBackend();
        } else {
          // Hata durumunda kullanıcıya bilgi ver
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mesaj gönderilemedi. Lütfen tekrar deneyin.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } else {
      // Eski yapı: Local storage'a kaydet
      _addMessage(
        ChatMessage(text: text, isMe: true, timestamp: DateTime.now()),
      );
    }
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages = [..._messages, message];
    });
    _saveMessages(_messages);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_listController.hasClients) return;
      _listController.animateTo(
        _listController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildPageHeader(),
                const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildConversationCard(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB39DDB), Color(0xFFF48FB1)],
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          ),
          Text(
            _contactUsername,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildConversationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildContactInfoSection(),
          const Divider(height: 1),
          Expanded(child: _buildMessagesSection()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildContactInfoSection() {
    final avatarStr =
        _isBackendMode ? widget.jobUserPhotoUrl : widget.contactAvatar;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildRobustAvatar(avatarStr, _contactName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _contactUsername,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _contactName,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    if (widget.statusMessage.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.statusMessage,
                        style: const TextStyle(
                          color: Colors.deepPurple,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.quoteAmount.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xFFF5F5F5),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.quoteAmount,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Text(
                        'Teklif',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildActionButton(
                icon: Icons.phone,
                label: 'Ara',
                onTap: () => _openWhatsApp(isVideo: false),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.videocam,
                label: 'Görüntülü',
                onTap: () => _openWhatsApp(isVideo: true),
              ),
              const SizedBox(width: 8),
           
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEDE7F6),
          foregroundColor: Colors.deepPurple,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildMessagesSection() {
    if (_isLoadingMessages) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_messages.isEmpty) {
      return _isConversationCleared ? _buildClearedState() : _buildEmptyState();
    }

    return ListView.builder(
      controller: _listController,
      shrinkWrap: false,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemCount: _messages.length,
      itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
    );
  }

  Widget _buildClearedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.delete_outline, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'Sohbet temizlendi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'Henüz mesaj yok.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'İlk mesajı siz göndererek iletişimi başlatabilirsiniz.',
            style: TextStyle(color: Colors.black45),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.isMe;
    final avatar = isMe ? _currentUserAvatar : _buildContactAvatar();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            _buildRobustAvatar(
                _isBackendMode ? widget.jobUserPhotoUrl : widget.contactAvatar,
                _contactName,
                radius: 18),
          ],
          if (!isMe) const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFEDE7F6) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      _contactName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  if (!isMe) const SizedBox(height: 6),
                  if (message.hasImage)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: message.text.isNotEmpty ? 8 : 0,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _buildMessageImage(message),
                      ),
                    ),
                  if (message.text.isNotEmpty)
                    Text(
                      message.text,
                      style: const TextStyle(fontSize: 15, height: 1.4),
                    ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 10),
          if (isMe)
            CircleAvatar(
              radius: 18,
              backgroundImage: _currentUserAvatar,
              child: _currentUserAvatar == null
                  ? Text(
                      _currentUserName.isNotEmpty
                          ? (_currentUserName.isNotEmpty
                                ? _currentUserName[0]
                                : '?')
                          : 'S',
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
            ),
        ],
      ),
    );
  }

  Future<void> _showAttachmentSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Kamera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source != null) {
      await _pickImage(source);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1080,
      );
      if (picked == null) return;

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        _addMessage(
          ChatMessage(
            text: '',
            isMe: true,
            timestamp: DateTime.now(),
            imageBytes: bytes,
          ),
        );
      } else {
        _addMessage(
          ChatMessage(
            text: '',
            isMe: true,
            timestamp: DateTime.now(),
            imagePath: picked.path,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Görsel gönderilemedi: $e')));
    }
  }

  Future<void> _handleMenuSelection(_ChatMenuAction action) async {
    switch (action) {
      case _ChatMenuAction.clearMessages:
        // BACKEND
        if (_isBackendMode && widget.jobId != null) {
          final success = await _chatService.clearChat(widget.jobId!);

          if (success && mounted) {
            final prefs = _prefs ??= await SharedPreferences.getInstance();
            await prefs.setBool(_clearedKey, true);

            setState(() {
              _messages.clear();
              _isConversationCleared = true;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mesajlar temizlendi')),
            );
          }
          return;
        }

        // LOCAL
        final prefs = _prefs ??= await SharedPreferences.getInstance();
        await prefs.setBool(_clearedKey, true);

        setState(() {
          _messages.clear();
          _isConversationCleared = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mesajlar temizlendi')),
        );
        break;
      case _ChatMenuAction.deleteConversation:
        _confirmAndDeleteConversation();
        break;
    }
  }

  Future<void> _confirmAndDeleteConversation() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 10.0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.delete_forever, color: Color(0xFF9C27B0), size: 50),
            SizedBox(height: 12),
            Text(
              'Sohbeti silmek istediğine emin misin?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Bu işlem geri alınamaz.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // İPTAL BUTONU
                GestureDetector(
                  onTap: () => Navigator.pop(context, false),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'İptal',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // SİL BUTONU (GRADIENT)
                GestureDetector(
                  onTap: () => Navigator.pop(context, true),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'Sil',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      setState(() => _messages = []);
      final prefs = _prefs ??= await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      await prefs.setBool(_deletedKey, true);
      await prefs.remove(_clearedKey);

      // Backend modu için jobId ve contactUserId ile de işaretle
      if (_isBackendMode && widget.jobId != null && widget.jobUserId != null) {
        await prefs.setBool(
          'chat_deleted_job_${widget.jobId}_user_${widget.jobUserId}',
          true,
        );
      }

      if (mounted) {
        Navigator.pop(
          context,
          true,
        ); // true = conversation silindi, parent'a bildir
      }
    }
  }

  Widget _buildMessageImage(ChatMessage message) {
    if (message.imageBytes != null) {
      return Image.memory(message.imageBytes!, width: 220, fit: BoxFit.cover);
    }

    if (message.imagePath != null && message.imagePath!.isNotEmpty) {
      return Image.file(
        File(message.imagePath!),
        width: 220,
        fit: BoxFit.cover,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Mesajınızı yazın...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _showAttachmentSheet,
            icon: const Icon(Icons.photo_camera, color: Colors.purple),
          ),
          ElevatedButton(
            onPressed: _sendMessage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(14),
            ),
            child: const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}

enum _ChatMenuAction { clearMessages, deleteConversation }
