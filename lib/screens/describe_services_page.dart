import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Veri setini buradan import ediyoruz
import 'package:zoozy/data/pet_breed.dart';
import 'package:zoozy/providers/service_provider.dart';
import 'package:zoozy/screens/add_location.dart';

class DescribeServicesPage extends StatefulWidget {
  const DescribeServicesPage({super.key});

  @override
  State<DescribeServicesPage> createState() => _DescribeServicesPageState();
}

class _DescribeServicesPageState extends State<DescribeServicesPage> {
  String _hizmetAdi = '';
  bool butonAktifMi = false;

  // Seçenek Listeleri
  final List<String> evDurumu = [
    'Apartman (Güvenlikli)',
    'Bahçeli Ev',
    'Müstakil / Verandalı'
  ];
  final List<String> tecrubeSeviyesi = [
    'İlk kez bakacağım',
    'Kendi evcil hayvanım var/oldu',
    'Profesyonel Bakıcı/Eğitmen'
  ];

  // Form Değişkenleri
  String? secilenTur;
  String? secilenCins;
  String? secilenKapasite;
  String? secilenEv;
  String? secilenTecrube;
  final TextEditingController _ozetController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('serviceName')) {
      _hizmetAdi = args['serviceName'] as String;
    }
    if (_hizmetAdi.isEmpty) _hizmetAdi = 'Gönüllü Destek';
  }

  void _kontrolButonDurumu() {
    setState(() {
      // Tüm zorunlu alanların dolu olup olmadığını kontrol ediyoruz
      butonAktifMi = secilenTur != null &&
          secilenCins != null &&
          secilenKapasite != null &&
          secilenEv != null &&
          secilenTecrube != null &&
          _ozetController.text.trim().length > 10;
    });
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
              _ustBar(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double maxWidth =
                        math.min(constraints.maxWidth * 0.9, 900);
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
                              _motivasyonMetni(anaMor),
                              const Divider(height: 30),

                              // 1. Hayvan Türü (petBreeds Map'inden anahtarları alıyoruz)
                              _olusturDropdown(
                                baslik: 'Hangi dostumuzu ağırlayabilirsin?',
                                elemanlar: petBreeds.keys.toList(),
                                seciliDeger: secilenTur,
                                onChanged: (val) {
                                  setState(() {
                                    secilenTur = val;
                                    secilenCins =
                                        null; // Tür değişince alt seçimi sıfırla
                                  });
                                  _kontrolButonDurumu();
                                },
                              ),

                              // 2. Hayvan Cinsi (Sadece tür seçildiyse Map'ten ilgili listeyi çekiyoruz)
                              if (secilenTur != null)
                                _olusturDropdown(
                                  baslik: '$secilenTur Cinsi Tercihin?',
                                  elemanlar: petBreeds[secilenTur]!,
                                  seciliDeger: secilenCins,
                                  onChanged: (val) {
                                    setState(() => secilenCins = val);
                                    _kontrolButonDurumu();
                                  },
                                ),

                              _olusturDropdown(
                                baslik: 'Aynı anda kaç misafir alabilirsin?',
                                elemanlar: const ['1', '2', '3+'],
                                seciliDeger: secilenKapasite,
                                onChanged: (val) {
                                  setState(() => secilenKapasite = val);
                                  _kontrolButonDurumu();
                                },
                              ),

                              _olusturDropdown(
                                baslik: 'Ev ve Bahçe Durumu',
                                elemanlar: evDurumu,
                                seciliDeger: secilenEv,
                                onChanged: (val) {
                                  setState(() => secilenEv = val);
                                  _kontrolButonDurumu();
                                },
                              ),

                              _olusturDropdown(
                                baslik: 'Tecrübe Seviyen',
                                elemanlar: tecrubeSeviyesi,
                                seciliDeger: secilenTecrube,
                                onChanged: (val) {
                                  setState(() => secilenTecrube = val);
                                  _kontrolButonDurumu();
                                },
                              ),

                              const SizedBox(height: 16),
                              _aciklamaAlani(),
                              const SizedBox(height: 30),
                              _devamEtButonu(),
                            ],
                          ),
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
      ),
    );
  }

  // --- Widget Parçaları ---

  Widget _ustBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Hizmetini Detaylandır',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _motivasyonMetni(Color anaMor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Daha Fazla Detay, Daha Fazla Güven! 🐾",
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: anaMor)),
        const SizedBox(height: 6),
        const Text(
          "Uzman olduğun türü belirtmen pati sahiplerinin sana daha çok güvenmesini sağlar.",
          style: TextStyle(
              fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _olusturDropdown({
    required String baslik,
    required List<String> elemanlar,
    required String? seciliDeger,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(baslik,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: seciliDeger,
            isExpanded: true,
            hint: const Text("Seçiniz", style: TextStyle(fontSize: 13)),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF9C27B0), width: 1.5)),
            ),
            items: elemanlar
                .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e, style: const TextStyle(fontSize: 14))))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _aciklamaAlani() {
    // Mevcut karakter sayısını hesaplıyoruz
    int mevcutUzunluk = _ozetController.text.trim().length;
    // Yazı yazılmış ama 10 karakterden az mı?
    bool yetersizMi = mevcutUzunluk > 0 && mevcutUzunluk < 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Sunduğun Ortam ve Kendinden Bahset",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _ozetController,
          maxLines: 3,
          style: const TextStyle(fontSize: 14),
          onChanged: (_) => _kontrolButonDurumu(),
          decoration: InputDecoration(
            hintText:
                "Örn: Evde kendi kedim var, ilaç verebilirim, yakında park var...",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),

            // --- Karakter Sayacı Ekledik ---
            counterText: "$mevcutUzunluk / En az 10 karakter",
            counterStyle: TextStyle(
              color: yetersizMi ? Colors.red : Colors.grey,
              fontSize: 11,
            ),

            // --- Dinamik Çerçeve Rengi ---
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: yetersizMi ? Colors.red.shade300 : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: yetersizMi ? Colors.red : const Color(0xFF9C27B0),
                width: 1.5,
              ),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        // --- Kullanıcıyı Bilgilendiren Hata Mesajı ---
        if (yetersizMi)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              "Devam etmek için en az 10 karakter yazmalısın.",
              style: TextStyle(color: Colors.red.shade700, fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _devamEtButonu() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: butonAktifMi
            ? const LinearGradient(
                colors: [Color(0xFF9C27B0), Colors.deepPurpleAccent])
            : null,
        color: !butonAktifMi ? Colors.grey.shade400 : null,
      ),
      child: ElevatedButton(
        onPressed: butonAktifMi ? _kaydetVeDevamEt : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text("ADRES BİLGİSİNE GEÇ",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
    );
  }

  void _kaydetVeDevamEt() {
    final serviceProvider =
        Provider.of<ServiceProvider>(context, listen: false);
    serviceProvider.setTempServiceDetails({
      'serviceName': _hizmetAdi,
      'mainType': secilenTur,
      'breed': secilenCins,
      'animalCount': secilenKapasite,
      'homeType': secilenEv,
      'experience': secilenTecrube,
      'description': _ozetController.text.trim(),
    });

    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const AddLocation()));
  }

  @override
  void dispose() {
    _ozetController.dispose();
    super.dispose();
  }
}