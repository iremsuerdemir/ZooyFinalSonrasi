import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoozy/models/notification_model.dart';
import 'package:zoozy/screens/chat_conversation_screen.dart';
import 'package:zoozy/services/chat_service.dart';
import 'package:zoozy/services/notification_service.dart';
import 'package:zoozy/services/request_service.dart';

// NOT: Projenizde zaten ChatMessage modeli tanımlıysa onu kullanın.
// Bu örnek kod ChatMessage sınıfının fromJson metoduna dayanmaktadır.

/// ---------------------- InboxActionsBar (yoksa ekledim) ----------------------
class InboxActionsBar extends StatelessWidget {
  final int tabIndex;
  final bool isEditing;
  final VoidCallback onToggleEditMode;
  final VoidCallback onNotificationMarkAllRead;
  final VoidCallback? onPressed;

  const InboxActionsBar({
    super.key,
    required this.tabIndex,
    required this.isEditing,
    required this.onToggleEditMode,
    required this.onNotificationMarkAllRead,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Tab 0 -> Mesajlarım: Düzenle / Bitir butonu
    if (tabIndex == 0) {
      return IconButton(
        icon: Icon(
          isEditing ? Icons.check : Icons.edit_outlined,
          color: Colors.white,
          size: 28,
        ),
        onPressed: onToggleEditMode,
      );
    }
    // Tab 1 -> Bildirimler: Tümünü okundu yap (tik)
    else if (tabIndex == 1) {
      return IconButton(
        icon: const Icon(
          Icons.done_all,
          color: Colors.white,
          size: 28,
        ),
        onPressed: onNotificationMarkAllRead,
      );
    }
    // Diğer durumlar
    return const SizedBox(width: 28);
  }
}

/// ---------------------- BildirimlerEkrani ----------------------
class BildirimlerEkrani extends StatefulWidget {
  const BildirimlerEkrani({super.key});

  @override
  State<BildirimlerEkrani> createState() => _BildirimlerEkraniState();
}

class _BildirimlerEkraniState extends State<BildirimlerEkrani> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // Backend'den bildirimleri yükle
  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifications = await _notificationService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Bildirim yükleme hatası: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Bildirimi okundu olarak işaretler
  Future<void> _markAsRead(int index) async {
    final notification = _notifications[index];
    if (notification.isRead) return;

    final success = await _notificationService.markAsRead(notification.id);
    if (success && mounted) {
      setState(() {
        _notifications[index] = NotificationModel(
          id: notification.id,
          userId: notification.userId,
          type: notification.type,
          title: notification.title,
          relatedUserId: notification.relatedUserId,
          relatedJobId: notification.relatedJobId,
          createdAt: notification.createdAt,
          isRead: true,
          relatedUsername: notification.relatedUsername,
        );
      });
    }
  }

  // Tüm bildirimleri okundu yapar (InboxActionsBar'dan çağrılır)
  Future<void> _markAllAsRead() async {
    final unreadNotifications = _notifications.where((n) => !n.isRead).toList();

    for (var notification in unreadNotifications) {
      await _notificationService.markAsRead(notification.id);
    }

    if (mounted) {
      setState(() {
        _notifications = _notifications.map((n) {
          if (!n.isRead) {
            return NotificationModel(
              id: n.id,
              userId: n.userId,
              type: n.type,
              title: n.title,
              relatedUserId: n.relatedUserId,
              relatedJobId: n.relatedJobId,
              createdAt: n.createdAt,
              isRead: true,
              relatedUsername: n.relatedUsername,
            );
          }
          return n;
        }).toList();
      });

      // Bildirimler okundu olarak işaretlendi, parent widget'a bildir
      // Bu sayede chat icon'larındaki kırmızı nokta kalkacak
      // (IndexboxMessageScreen'deki _markAllNotificationsRead zaten bunu yapıyor)
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationCard(context, notification, index);
        },
      ),
    );
  }

  Widget _buildNotificationCard(
      BuildContext context, NotificationModel notification, int index) {
    // Okunmamış bildirimler için gri arka plan, okunmuş bildirimler için beyaz
    final Color backgroundColor =
        notification.isRead ? Colors.white : Colors.grey[100]!;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: backgroundColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          notification.type == 'job'
              ? 'Yeni bir iş ilanı yayınlandı'
              : 'Yeni bir mesaj aldınız',
          style: TextStyle(
            color: notification.isRead ? Colors.grey : Colors.black54,
          ),
        ),
        trailing: Text(
          '${notification.createdAt.toLocal().hour.toString().padLeft(2, '0')}:${notification.createdAt.toLocal().minute.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: 12,
            color: notification.isRead ? Colors.grey : Colors.black54,
          ),
        ),
        onTap: () => _markAsRead(index),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Henüz Bildirim Yok',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Yeni bildirimler geldiğinde burada göreceksiniz.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------- IndexboxMessageScreen (Ana Gelen Kutusu) ----------------------
class IndexboxMessageScreen extends StatefulWidget {
  const IndexboxMessageScreen({super.key});

  @override
  State<IndexboxMessageScreen> createState() => _IndexboxMessageScreenState();
}

class _IndexboxMessageScreenState extends State<IndexboxMessageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isEditing = false;

  // BildirimlerEkrani state'ine erişmek için key
  final GlobalKey<_BildirimlerEkraniState> _notificationsKey =
      GlobalKey<_BildirimlerEkraniState>();

  @override
  void initState() {
    super.initState();
    // Bildirimler sekmesi ilk açılsın (index 1)
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_isEditing && _tabController.indexIsChanging) {
      setState(() {
        _isEditing = false;
      });
    }
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    if (_tabController.index == 0) {
      setState(() {
        _isEditing = !_isEditing;
      });
    }
  }

  void _markAllNotificationsRead() async {
    if (_tabController.index == 1) {
      await _notificationsKey.currentState?._markAllAsRead();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tüm Bildirimler Okundu Olarak İşaretlendi')),
      );
      // Bildirimler okundu olarak işaretlendi
      // Chat icon'larındaki kırmızı noktayı hemen kaldırmak için Navigator.pop ile true döndür
      // Bu sayede parent widget'lar kırmızı noktayı kaldırabilir
      if (mounted) {
        Navigator.pop(context, true); // true = tüm bildirimler okundu
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        _InboxTabBar(tabController: _tabController),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              TaleplerEkrani(
                                isEditing: _isEditing,
                                onToggleEditMode: _toggleEditMode,
                              ),
                              BildirimlerEkrani(key: _notificationsKey),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
          colors: [Color(0xFFB39DDB), Color(0xFFF48FB1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          const Text(
            'Gelen Kutusu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          InboxActionsBar(
            tabIndex: _tabController.index,
            isEditing: _isEditing,
            onToggleEditMode: _toggleEditMode,
            onNotificationMarkAllRead: _markAllNotificationsRead,
            onPressed: null,
          ),
        ],
      ),
    );
  }
}

/// ---------------------- TabBar widget ----------------------
class _InboxTabBar extends StatelessWidget {
  final TabController tabController;
  const _InboxTabBar({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TabBar(
          controller: tabController,
          labelColor: const Color(0xFF673AB7),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF673AB7),
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'Mesajlarım'),
            Tab(text: 'Bildirimler'),
          ],
        ),
      ),
    );
  }
}

/// ---------------------- TaleplerEkrani (Mesajlarım) ----------------------
class TaleplerEkrani extends StatefulWidget {
  final bool isEditing;
  final VoidCallback onToggleEditMode;

  const TaleplerEkrani({
    super.key,
    required this.isEditing,
    required this.onToggleEditMode,
  });

  @override
  State<TaleplerEkrani> createState() => _TaleplerEkraniState();
}

class _TaleplerEkraniState extends State<TaleplerEkrani> {
  final ChatService _chatService = ChatService();
  final RequestService _requestService = RequestService();
  List<_ChatPreview> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  // Backend'den conversation'ları yükle
  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // SharedPreferences'ı bir kez al
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getInt('userId');

      // Hem diğer kullanıcıların job'larını hem de kullanıcının kendi job'larını al
      // Böylece mesaj gönderildiğinde alıcı da conversation listesinde görebilir
      final otherJobs = await _requestService.getOtherUsersRequests();
      final myJobs = await _requestService.getAllJobs();

      // Kullanıcının kendi job'larını filtrele (userId'ye göre)
      final myFilteredJobs = myJobs.where((job) {
        final jobUserId = job['userId'] as int?;
        return jobUserId == currentUserId;
      }).toList();

      // Tüm job'ları birleştir
      final allJobs = [...otherJobs, ...myFilteredJobs];

      final List<_ChatPreview> conversations = [];

      // Her job için mesajları kontrol et
      for (var job in allJobs) {
        final jobId = job['id'] as int?;
        if (jobId == null) continue;

        final messages = await _chatService.getMessages(jobId);
        if (messages.isEmpty) continue; // Mesaj yoksa gösterilmez

        // Son mesajı al
        final lastMessage = messages.last;

        // Mesajı atan kişinin bilgilerini belirle
        // Eğer mesajı ben attıysam (senderId == currentUserId), alıcının bilgilerini göster
        // Eğer mesajı başkası attıysa (receiverId == currentUserId), gönderenin bilgilerini göster
        String contactName;
        String contactUsername;
        String? contactPhotoUrl;
        int? contactUserId;

        if (lastMessage.senderId == currentUserId) {
          // Mesajı ben attım, alıcının bilgilerini göster
          contactName = lastMessage.receiverUsername ?? 'Kullanıcı';
          contactUsername = contactName.replaceAll(' ', '_');
          contactPhotoUrl = lastMessage.receiverPhotoUrl;
          contactUserId = lastMessage.receiverId;
        } else {
          // Mesajı başkası attı, gönderenin bilgilerini göster
          contactName = lastMessage.senderUsername ?? 'Kullanıcı';
          contactUsername = contactName.replaceAll(' ', '_');
          contactPhotoUrl = lastMessage.senderPhotoUrl;
          contactUserId = lastMessage.senderId;
        }

        // Silinmiş conversation kontrolü (backend modu için)
        final deletedKey = 'chat_deleted_job_${jobId}_user_$contactUserId';
        final isDeleted = prefs.getBool(deletedKey) ?? false;
        if (isDeleted) continue; // Silinmiş conversation'ı atla

        // ChatMessage formatına dönüştür
        final chatMessages = messages.map((msg) {
          final isMe = msg.senderId == currentUserId;
          return ChatMessage(
            text: msg.messageText,
            isMe: isMe,
            timestamp: msg.createdAt,
          );
        }).toList();

        conversations.add(_ChatPreview(
          contactName: contactName,
          contactUsername: contactUsername,
          avatar: contactPhotoUrl ?? '',
          phoneNumber: '', // Backend'den telefon numarası gelmiyor, boş bırak
          lastMessagePreview: lastMessage.messageText,
          messages: chatMessages,
          jobId: jobId,
          jobUserId: contactUserId, // Mesajı atan kişinin userId'si
        ));
      }

      // Aynı kişiden gelen mesajları grupla (contactUserId'ye göre)
      // Her kişi için en son mesajı içeren tek bir kart göster
      final Map<int?, _ChatPreview> groupedConversations = {};

      for (var conversation in conversations) {
        final contactUserId = conversation.jobUserId;

        // Eğer bu kişi için daha önce bir conversation varsa
        if (groupedConversations.containsKey(contactUserId)) {
          final existing = groupedConversations[contactUserId]!;
          // En son mesajı karşılaştır, daha yeni olanı al
          if (conversation.messages.isNotEmpty &&
              existing.messages.isNotEmpty) {
            final newLastMessage = conversation.messages.last;
            final existingLastMessage = existing.messages.last;

            if (newLastMessage.timestamp
                .isAfter(existingLastMessage.timestamp)) {
              // Yeni mesaj daha yeni, onu kullan
              groupedConversations[contactUserId] = conversation;
            }
          }
        } else {
          // İlk kez görülen kişi, direkt ekle
          groupedConversations[contactUserId] = conversation;
        }
      }

      // Gruplanmış conversation'ları listeye çevir
      final groupedList = groupedConversations.values.toList();

      // Tarihe göre sırala (en yeni mesaj üstte)
      groupedList.sort((a, b) {
        if (a.messages.isEmpty || b.messages.isEmpty) return 0;
        return b.messages.last.timestamp.compareTo(a.messages.last.timestamp);
      });

      if (mounted) {
        setState(() {
          _chats = groupedList;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Conversation yükleme hatası: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markChatAsDeleted(
      String username, int? jobId, int? contactUserId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('chat_deleted_$username', true);
    await prefs.remove('chat_history_$username');
    // Backend modu için jobId ve contactUserId ile de işaretle
    if (jobId != null && contactUserId != null) {
      await prefs.setBool(
          'chat_deleted_job_${jobId}_user_$contactUserId', true);
    }
  }

  Future<void> _clearMessagesOnly(String username) async {
    final prefs = await SharedPreferences.getInstance();
    // history'yi silip cleared flag'i set et.
    // Bu sayede loadStoredChat "isCleared"i görüp boş liste döner.
    await prefs.remove('chat_history_$username');
    await prefs.setBool('chat_cleared_$username', true);
  }

  void _deleteChat(BuildContext context, _ChatPreview chat) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seçenekler'),
        content: Text('${chat.contactName} için işlem seçiniz:'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _performClearMessages(chat);
            },
            child: const Text('Mesajları Temizle'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _performDeleteChat(chat);
            },
            child:
                const Text('Sohbeti Sil', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _performClearMessages(_ChatPreview chat) async {
    // BACKEND CLEAR (Kalıcı Silme)
    if (chat.jobId != null) {
      final success = await _chatService.clearChat(chat.jobId!, deleteConversation: false);
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mesajlar silinemedi (Backend Hatası)')),
          );
        }
        return;
      }
    }

    // YEREL UI GÜNCELLEME
    await _clearMessagesOnly(chat.contactUsername);
    if (mounted) {
      // Listeyi yeniden yükle ki UI güncellensin (Message check yapıldığı için listeden düşer)
      _loadConversations();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mesajlar kalıcı olarak silindi'), duration: Duration(seconds: 1)),
      );
    }
  }

  void _performDeleteChat(_ChatPreview chat) async {
    // BACKEND CLEAR (Sohbeti silmek için de mesajları siliyoruz çünkü listeleme mantığı mesaj varlığına bağlı)
    if (chat.jobId != null) {
      final success = await _chatService.clearChat(chat.jobId!, deleteConversation: true);
      if (!success) {
         // Silinemezse kullanıcıya bildir
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sohbet silinemedi (Backend Hatası)')),
            );
         }
         return;
      }
    }

    // Silme işaretini kaydet (Yine de yerel flag tutalım)
    await _markChatAsDeleted(chat.contactUsername, chat.jobId, chat.jobUserId);

    // UI'dan kaldır
    if (mounted) {
      setState(() {
        _chats.removeWhere((c) {
          return (c.contactUsername == chat.contactUsername &&
                  c.jobId == chat.jobId &&
                  c.jobUserId == chat.jobUserId) ||
              (c.jobUserId == chat.jobUserId && chat.jobId == null);
        });
      });
      if (_chats.isEmpty) {
        widget.onToggleEditMode();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sohbet kalıcı olarak silindi')),
      );
    }
  }

  void _showIlanYayiniModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const IlanYayiniIcerigi(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_chats.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Son Mesajlar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          ..._chats
              .map((chat) => _buildChatTile(context, chat, widget.isEditing)),
        ],
      ),
    );
  }

  Widget _buildChatTile(
      BuildContext context, _ChatPreview chat, bool isEditing) {
    final avatar = _resolveAvatar(chat.avatar);

    return FutureBuilder<_StoredChatData>(
      future: _loadStoredChat(chat),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const SizedBox(
              height: 88,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        }

        final data = snapshot.data ??
            _StoredChatData(messages: chat.messages, isDeleted: false);

        if (data.isDeleted && data.messages.isEmpty) {
          return const SizedBox.shrink();
        }

        final messages = data.messages;
        // Son mesajın içeriğini göster
        String previewText;
        if (data.isLocal) {
          // Yerel değişiklik varsa (temizleme dahil), yerel mesajları kullan
          previewText = messages.isNotEmpty
              ? messages.last.text.replaceAll('\n', ' ')
              : ''; // Temizlendi veya boş
        } else {
          // Yoksa backend verisini kullan
          previewText = chat.lastMessagePreview.isNotEmpty
              ? chat.lastMessagePreview.replaceAll('\n', ' ')
              : (messages.isNotEmpty
                  ? messages.last.text.replaceAll('\n', ' ')
                  : '');
        }

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Stack(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: _buildRobustAvatar(chat.avatar, chat.contactName),
                title: Text(chat.contactName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(previewText,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                ),
                onTap: isEditing
                    ? null
                    : () {
                        // Backend modunda jobId ve jobUserId ile aç
                        if (chat.jobId != null && chat.jobUserId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatConversationScreen(
                                jobId: chat.jobId,
                                jobUserId: chat.jobUserId,
                                jobUsername: chat.contactName,
                                jobUserPhotoUrl: chat.avatar,
                              ),
                            ),
                          ).then((_) {
                            if (mounted) {
                              _loadConversations(); // Mesajlar güncellendi, tekrar yükle
                            }
                          });
                        } else {
                          // Eski mod: contact bilgileri ile aç
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatConversationScreen(
                                contactName: chat.contactName,
                                contactUsername: chat.contactUsername,
                                contactAvatar: chat.avatar,
                                phoneNumber: chat.phoneNumber,
                                messages: messages,
                              ),
                            ),
                          ).then((_) {
                            if (mounted) setState(() {});
                          });
                        }
                      },
              ),
              if (isEditing)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 28),
                    onPressed: () => _deleteChat(context, chat),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Henüz Mesaj Yok',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Bakıcılar taleplerinize cevap verdiğinde, mesajlarını burada göreceksiniz.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<_StoredChatData> _loadStoredChat(_ChatPreview chat) async {
    final prefs = await SharedPreferences.getInstance();
    final historyKey = 'chat_history_${chat.contactUsername}';
    final deletedKey = 'chat_deleted_${chat.contactUsername}';
    final clearedKey = 'chat_cleared_${chat.contactUsername}';

    final rawHistory = prefs.getString(historyKey);
    final isDeleted = prefs.getBool(deletedKey) ?? false;
    final isCleared = prefs.getBool(clearedKey) ?? false;

    // 1. Durum: Sohbet tamamen silinmiş
    if (isDeleted) {
      return const _StoredChatData(messages: [], isDeleted: true);
    }

    // 2. Durum: Yerel geçmiş var (Cleared'dan daha öncelikli, çünkü yeni mesaj gelmiş olabilir)
    if (rawHistory != null) {
      // Boş liste kontrolü
      if (rawHistory == '[]') {
        return _StoredChatData(
            messages: [], isDeleted: false, isLocal: true);
      }
      try {
        final List<dynamic> decoded = jsonDecode(rawHistory) as List<dynamic>;
        final messages = decoded
            .map((e) => ChatMessage.fromJson(
                Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
            .toList();
        return _StoredChatData(
            messages: messages, isDeleted: false, isLocal: true);
      } catch (_) {
        // Parse hatası olursa aşağı devam et
      }
    }

    // 3. Durum: Sohbet temizlenmiş (Yerel geçmiş yok ama temizle flag'i var)
    if (isCleared) {
      // Backend verisini ezmek için isLocal=true ve boş mesaj dönüyoruz
      return const _StoredChatData(messages: [], isDeleted: false, isLocal: true);
    }

    // 4. Durum: Hiçbir yerel kayıt yok, backend verisini kullan
    return _StoredChatData(messages: chat.messages, isDeleted: false);
  }

  Widget _buildRobustAvatar(String avatar, String name, {double radius = 26}) {
    if (avatar.startsWith('http')) {
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
              child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            );
          },
        ),
      );
    }

    // Non-http avatar (assets/bytes)
    final imageProvider = _resolveAvatar(avatar);
    return CircleAvatar(
      radius: radius,
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white))
          : null,
    );
  }

  static ImageProvider? _resolveAvatar(String avatar) {
    if (avatar.startsWith('http')) return NetworkImage(avatar);
    if (avatar.startsWith('assets/')) return AssetImage(avatar);
    if (avatar.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(avatar));
      } catch (_) {}
    }
    return null;
  }
}

/// ---------------------- Yardımcı sınıflar ----------------------
class _ChatPreview {
  final String contactName;
  final String contactUsername;
  final String avatar;
  final String phoneNumber;

  final String lastMessagePreview;
  final List<ChatMessage> messages;

  // Backend modu için
  final int? jobId;
  final int? jobUserId;

  const _ChatPreview({
    required this.contactName,
    required this.contactUsername,
    required this.avatar,
    required this.phoneNumber,
    required this.lastMessagePreview,
    required this.messages,
    this.jobId,
    this.jobUserId,
  });
}

class _StoredChatData {
  final List<ChatMessage> messages;
  final bool isDeleted;
  final bool isLocal;

  const _StoredChatData({
    required this.messages,
    required this.isDeleted,
    this.isLocal = false,
  });
}

/// ---------------------- IlanYayiniIcerigi (Modal) ----------------------
class IlanYayiniIcerigi extends StatelessWidget {
  const IlanYayiniIcerigi({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text("İlan Yayını",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 8),
            const Text(
              "Yakınınızdaki destekçilere evcil hayvanlarınızla ilgili yardıma ihtiyacınız olduğunu bildirmek için ilan yayınlayın.",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildServiceCard(Icons.house_outlined, "Pansiyon"),
                _buildServiceCard(Icons.wb_sunny_outlined, "Gündüz Bakımı"),
                _buildServiceCard(Icons.chair_outlined, "Evde Bakım"),
                _buildServiceCard(Icons.directions_walk, "Gezdirme"),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                _buildServiceCard(Icons.local_taxi_outlined, "Taksi"),
                _buildServiceCard(Icons.cut_outlined, "Bakım"),
                _buildServiceCard(Icons.school_outlined, "Eğitim"),
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _buildServiceCard(IconData icon, String title) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Icon(icon, size: 30, color: const Color(0xFF673AB7)),
            ),
            const SizedBox(height: 8),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
