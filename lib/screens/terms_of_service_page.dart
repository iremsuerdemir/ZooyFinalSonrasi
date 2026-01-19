import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:zoozy/screens/privacy_policy_page.dart';

class TermsOfServicePage extends StatefulWidget {
  /// Eğer zorunlu bir akışsa (login sonrası), geri butonu gösterilmez.
  final bool showBackButton;

  const TermsOfServicePage({super.key, this.showBackButton = true});

  @override
  State<TermsOfServicePage> createState() => _TermsOfServicePageState();
}

class _TermsOfServicePageState extends State<TermsOfServicePage> {
  // Bu ekranda onay kutusu veya devam etme butonu akışa göre çalışacak.
  // Zorunlu akışta kullanıcı "Devam" diyerek PrivacyPolicyPage'e gider.
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient arka plan
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFB39DDB), // Açık mor
                  Color(0xFFF48FB1), // Açık pembe
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Geri butonu kontrolü
                      if (widget.showBackButton)
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        )
                      else
                        const SizedBox(width: 48), // Yer tutucu

                      const Text(
                        'Hizmet Şartları',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Responsive içerik alanı
                Expanded(
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
                              // Scrollable metin
                              Expanded(
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: RichText(
                                    textAlign: TextAlign.justify,
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: fontSize,
                                        color: Colors.black87,
                                        height: 1.6,
                                        letterSpacing: 0.2,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: "1. Hizmetin Tanımı\n",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const TextSpan(
                                          text:
                                              "Zoozy, evcil hayvan sahiplerini ve hizmet sağlayıcıları bir araya getiren bir platformdur. "
                                              "Sağlanan hizmetler, Zoozy tarafından doğrudan verilmez, üçüncü taraf sağlayıcılar tarafından sunulur.\n\n",
                                        ),
                                        TextSpan(
                                          text: "2. Kullanıcı Yükümlülükleri\n",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const TextSpan(
                                          text:
                                              "Kullanıcılar, sağladıkları bilgilerin doğru ve güncel olduğunu beyan eder. "
                                              "Platformun kötüye kullanılması durumunda, hesap kalıcı olarak askıya alınabilir.\n\n",
                                        ),
                                   
                                        TextSpan(
                                          text: "4. Sorumluluk Reddi\n",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const TextSpan(
                                          text:
                                              "Zoozy, hizmet sağlayıcıların eylemlerinden veya sunulan hizmetlerin kalitesinden sorumlu değildir.\n\n",
                                        ),
                                        TextSpan(
                                          text: "5. Gizlilik\n",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const TextSpan(
                                          text:
                                              "Kullanıcı bilgileri, Gizlilik Politikası çerçevesinde korunur ve üçüncü taraflarla yalnızca gerekli durumlarda paylaşılır.\n",
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Sadece onay akışı aktifse (yani geri butonu kapalıysa) devam butonu gösterelim
                              if (!widget.showBackButton) ...[
                                const SizedBox(height: 20),
                                
                                const Text(
                                  "Devam ederek Hizmet Şartlarını okuduğunuzu onaylamış olursunuz.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () {
                                    // Terms akışı bitti, şimdi Privacy'e geçiyoruz.
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const PrivacyPolicyPage(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Colors.purple,
                                          Colors.deepPurpleAccent,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.purpleAccent,
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text(
                                        "Devam Et",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
