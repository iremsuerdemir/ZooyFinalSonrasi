import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoozy/screens/explore_screen.dart';
import 'package:zoozy/screens/login_page.dart';
import 'package:zoozy/screens/owner_Login_Page.dart';
import 'package:zoozy/services/auth_service.dart';

class PrivacyPolicyPage extends StatefulWidget {
  /// Yeni parametre: Sayfanın bir "onay" akışının parçası olup olmadığına karar verir.
  /// Varsayılan true, ancak Terms'den gelen zorunlu akışta bu parametre önemli olabilir.
  /// İsteğe bağlı olarak bu sayfada da geri butonu kaldırılabilir ama istekte:
  /// "Bu ekranda geri ok her zaman görünecek." dendiği için back button'a dokunmuyoruz.
  final bool isModal;

  const PrivacyPolicyPage({super.key, this.isModal = true});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  // Checkbox durumu
  bool isChecked = false;

  /// Gerçek Fonksiyon: Kullanıcının onaylarını kaydeder.
  Future<void> saveUserAgreement({required bool terms, required bool privacy}) async {
    final authService = AuthService();
    final user = await authService.getCurrentUser();
    
    if (user != null) {
      await authService.updateAgreements(user.id);
    } else {
      // Kullanıcı giriş yapmamışsa local/guest olarak işaretlenebilir 
      // veya ignore edilebilir. Şimdilik sadece log (veya guest service)
      print("Kullanıcı bulunamadı, sözleşme onayı sunucuya gönderilemedi.");
    }
  }

  // 1️⃣ Arka Plan Gradient
  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFB39DDB),
            Color(0xFFF48FB1),
          ],
        ),
      ),
    );
  }

  // 2️⃣ Başlık ve Geri Butonu
  Widget _buildHeader(BuildContext context) {
    // isModal false ise veya showBackButton true ise geri butonu gösterilir.
    // Ancak bu sayfada her zaman geri butonu olacak dendiği için:
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            "Gizlilik Politikası",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // 3️⃣ Politika Metni
  Widget _buildPolicyText(double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("1. Toplanan Veriler", fontSize),
        _buildSectionText(
          "Uygulamayı kullanırken adınız, e-posta adresiniz ve cihaz bilgileriniz toplanabilir. Bu veriler hizmet kalitesini artırmak için kullanılır.",
          fontSize,
        ),
        const SizedBox(height: 16),
        _buildSectionTitle("2. Veri Kullanımı", fontSize),
        _buildSectionText(
          "Toplanan veriler, yalnızca uygulama deneyimini iyileştirmek ve güvenliği sağlamak amacıyla işlenir. Üçüncü taraflarla izniniz olmadan paylaşılmaz.",
          fontSize,
        ),
        const SizedBox(height: 16),
        _buildSectionTitle("3. Güvenlik", fontSize),
        _buildSectionText(
          "Verileriniz endüstri standardı güvenlik önlemleriyle korunmaktadır. Ancak internet üzerinden yapılan hiçbir iletim %100 güvenli değildir.",
          fontSize,
        ),
        const SizedBox(height: 16),
        _buildSectionTitle("4. İletişim", fontSize),
        _buildSectionText(
          "Gizlilik politikamızla ilgili sorularınız için bizimle iletişime geçebilirsiniz: support@zoozy.app",
          fontSize,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, double fontSize) {
    return Text(
      title,
      style: TextStyle(
        fontSize: fontSize + 2,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSectionText(String text, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        text,
        textAlign: TextAlign.justify,
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.black54,
          height: 1.5,
        ),
      ),
    );
  }

  // 4️⃣ Onay Kutusu Satırı
  Widget _buildAcceptanceRow() {
    if (!widget.isModal) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        setState(() {
          isChecked = !isChecked;
        });
      },
      child: Row(
        children: [
          Transform.scale(
            scale: 1.2,
            child: Checkbox(
              value: isChecked,
              activeColor: const Color(0xFF7A4FAD),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: (val) {
                setState(() {
                  isChecked = val ?? false;
                });
              },
            ),
          ),
          const Expanded(
            child: Text(
              "Gizlilik Politikasını okudum ve kabul ediyorum.",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5️⃣ Devam Et / Tamamla butonu
  Widget _buildContinueButton(BuildContext context) {
    // isModal false ise (sadece okuma modu) buton göstermeyebiliriz veya sadece "Kapat" diyebiliriz.
    // Ancak login akışında isModal=true varsayıyoruz.
    if (!widget.isModal) return const SizedBox.shrink();

    return GestureDetector(
      onTap: isChecked
          ? () async {
              // Onay kaydetme işlemini çağır
              await saveUserAgreement(terms: true, privacy: true);

              if (mounted) {
                // Kullanıcı adını al
                final prefs = await SharedPreferences.getInstance();
                final username = prefs.getString('username') ?? 'Kullanıcı';

                // Mesajı Göster
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.green,
                    content: Text(
                      "Giriş başarılı! $username. Yönlendiriliyorsunuz...",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
                
                // Kısa bir bekleme (kullanıcı mesajı okusun)
                await Future.delayed(const Duration(seconds: 2));

                // Akışı bitir ve ExploreScreen'e git.
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const ExploreScreen()),
                  (route) => false,
                );
              }
            }
          : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isChecked
                ? [Colors.purple, Colors.deepPurpleAccent]
                : [Colors.grey.shade400, Colors.grey.shade300],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            if (isChecked)
              const BoxShadow(
                color: Colors.purpleAccent,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
          ],
        ),
        child: Center(
          child: Text(
            "Onaylıyorum",
            style: TextStyle(
              color: isChecked ? Colors.white : Colors.black54,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // 6️⃣ İçerik kartı (responsive)
  Widget _buildContentBody() {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double maxContentWidth = math.min(
            constraints.maxWidth * 0.9,
            900,
          );
          final double fontSize = constraints.maxWidth > 1000
              ? 18
              : (constraints.maxWidth < 360 ? 14 : 16);

          return Center(
            child: Container(
              width: maxContentWidth,
              padding: const EdgeInsets.all(20),
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
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _buildPolicyText(fontSize),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildAcceptanceRow(),
                  const SizedBox(height: 12),
                  _buildContinueButton(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 7️⃣ Ana yapı
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                _buildContentBody(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
