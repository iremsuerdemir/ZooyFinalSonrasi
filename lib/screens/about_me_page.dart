import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:zoozy/screens/describe_services_page.dart';

class AboutMePage extends StatefulWidget {
  const AboutMePage({super.key});

  @override
  State<AboutMePage> createState() => _AboutMePageState();
}

class _AboutMePageState extends State<AboutMePage> {
  String? _secilenYetenek;
  final TextEditingController _kendiniController = TextEditingController();
  final TextEditingController _deneyimController = TextEditingController();
  final TextEditingController _ozelController = TextEditingController();

  String _hizmetAdi = '';

  // Daha profesyonel ve kapsayıcı yetkinlik listesi
  final List<String> _yetenekler = [
    'Temel Eğitim ve İtaat Tecrübesi',
    'Davranışsal Rehabilitasyon Desteği',
    'İleri Derece Gözlem ve Analiz Yetkinliği',
    'Medikal Bakım ve İlaç Uygulama Bilgisi',
    'Veteriner Teknikerlik / Klinik Deneyimi',
    'Türlere Özel Profesyonel Bakım Deneyimi',
    'Sertifikalı Temel Bakım (Grooming) Uzmanlığı',
  ];

  bool get _formDolu =>
      _kendiniController.text.isNotEmpty &&
      _deneyimController.text.isNotEmpty &&
      _ozelController.text.isNotEmpty &&
      _secilenYetenek != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('serviceName')) {
      _hizmetAdi = args['serviceName'] as String;
    }
  }

  @override
  void dispose() {
    _kendiniController.dispose();
    _deneyimController.dispose();
    _ozelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color anaMor = Color(0xFF9C27B0);
    const Color gradientStart = Color(0xFFB39DDB);
    const Color gradientEnd = Color(0xFFF48FB1);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientStart, gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Üst bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Yetkinlik Profili',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double maxWidth = math.min(
                      constraints.maxWidth * 0.9,
                      900,
                    );
                    return Center(
                      child: Container(
                        width: maxWidth,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),

                              // 1. SORU: MOTİVASYON
                              const Text(
                                'Gönüllü hizmet motivasyonunuzu ve yaklaşımınızı özetleyiniz.',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _OzellesmisTextField(
                                controller: _kendiniController,
                                hintText:
                                    "Hayvan refahına bakış açınız ve bu süreçte neden yer almak istediğinizden bahsediniz...",
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 20),

                              // 2. SORU: TEKNİK TECRÜBE
                              const Text(
                                'Geçmişteki bakım tecrübeleriniz ve etkileşimde olduğunuz türler nelerdir?',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _OzellesmisTextField(
                                controller: _deneyimController,
                                hintText:
                                    "Daha önce sorumluluğunu üstlendiğiniz canlılar ve elde ettiğiniz kazanımları belirtiniz...",
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 20),

                              // 3. DROPDOWN: TEMEL YETKİNLİK
                              _yetenekDropdown(anaMor),
                              const SizedBox(height: 20),

                              // 4. SORU: EK BİLGİLER
                              const Text(
                                'Belirtmek istediğiniz ek uzmanlık alanları veya teknik detaylar mevcut mu?',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _OzellesmisTextField(
                                controller: _ozelController,
                                hintText:
                                    "Sertifika bilgileri, ilk yardım eğitimi veya bakım alanınızın fiziksel koşulları hakkında ek bilgi verebilirsiniz.",
                                minLines: 4,
                                maxLines: 4,
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 25),

                              // Kaydet Butonu
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: _formDolu
                                      ? const LinearGradient(
                                          colors: [
                                            anaMor,
                                            Colors.deepPurpleAccent
                                          ],
                                        )
                                      : null,
                                  color:
                                      !_formDolu ? Colors.grey.shade400 : null,
                                ),
                                child: ElevatedButton(
                                  onPressed: _formDolu
                                      ? () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              backgroundColor: Colors.green,
                                              content: Text(
                                                  "Profil verileri başarıyla güncellendi."),
                                            ),
                                          );

                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const DescribeServicesPage(),
                                              settings: RouteSettings(
                                                arguments: {
                                                  'serviceName': _hizmetAdi
                                                },
                                              ),
                                            ),
                                          );
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    minimumSize: const Size.fromHeight(50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    "Profili Onayla",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _yetenekDropdown(Color anaRenk) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Öne çıkan temel yetkinliğiniz nedir?',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: anaRenk, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          value: _secilenYetenek,
          hint: const Text('Lütfen bir alan seçiniz',
              style: TextStyle(fontSize: 14)),
          isExpanded: true,
          items: _yetenekler.map((String yetenek) {
            return DropdownMenuItem<String>(
              value: yetenek,
              child: Text(yetenek, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (String? yeniDeger) {
            setState(() {
              _secilenYetenek = yeniDeger;
            });
          },
        ),
      ],
    );
  }
}

class _OzellesmisTextField extends StatelessWidget {
  final String hintText;
  final int minLines;
  final int maxLines;
  final TextEditingController? controller;
  final Function(String)? onChanged;

  const _OzellesmisTextField({
    required this.hintText,
    this.minLines = 4,
    this.maxLines = 4,
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.black87, fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontStyle: FontStyle.italic,
          fontSize: 13,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
