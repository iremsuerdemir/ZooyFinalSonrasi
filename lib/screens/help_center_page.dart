import 'package:flutter/material.dart';
import 'package:zoozy/components/bottom_navigation_bar.dart';
import 'package:zoozy/screens/faq_page.dart';
import 'package:zoozy/screens/privacy_policy_page.dart';
import 'package:zoozy/screens/support_request.page.dart';
import 'package:zoozy/screens/terms_of_service_page.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
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
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          size: 28,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Yardım & Destek',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Size nasıl yardımcı olabiliriz?",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              "Destek kanallarımızdan size uygun olanı seçin.",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const _SectionTitle(title: "Destek"),
                      _helpRow(
                        context,
                        icon: Icons.support_agent_rounded,
                        title: "Destek Talebi Oluştur",
                        subtitle: "Bizimle doğrudan iletişime geçin",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SupportRequestPage(),
                            ),
                          );
                        },
                      ),
                      _helpRow(
                        context,
                        icon: Icons.help_outline_rounded,
                        title: "Sıkça Sorulan Sorular",
                        subtitle: "Hızlı cevaplara göz atın",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FaqPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(title: "Yasal"),
                      _helpRow(
                        context,
                        icon: Icons.privacy_tip_outlined,
                        title: "Gizlilik Politikası",
                        subtitle: "Veri kullanım detayları",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const PrivacyPolicyPage(isModal: false),
                            ),
                          );
                        },
                      ),
                      _helpRow(
                        context,
                        icon: Icons.article_outlined,
                        title: "Kullanım Koşulları",
                        subtitle: "Hizmet şartları ve kurallar",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TermsOfServicePage(
                                  showBackButton: true),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 4,
        selectedColor: const Color(0xFF7A4FAD),
        unselectedColor: Colors.grey,
        onTap: (index) {
          if (index == 0) Navigator.pushNamed(context, '/explore');
          if (index == 1) Navigator.pushNamed(context, '/requests');
          if (index == 2) Navigator.pushNamed(context, '/moments');
          if (index == 3) Navigator.pushNamed(context, '/jobs');
        },
      ),
    );
  }

  Widget _helpRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF7A4FAD).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF7A4FAD)),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.trim(), // Başındaki ve sonundaki boşlukları temizler
        textAlign: TextAlign.left,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
