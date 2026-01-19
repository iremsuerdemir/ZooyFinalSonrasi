import 'dart:async';

import 'package:flutter/material.dart';

class ExploreInfoSlider extends StatefulWidget {
  const ExploreInfoSlider({super.key});

  @override
  State<ExploreInfoSlider> createState() => _ExploreInfoSliderState();
}

class _ExploreInfoSliderState extends State<ExploreInfoSlider> {
  final PageController _controller = PageController(viewportFraction: 0.85);
  int _activePage = 0;
  Timer? _timer;

  final List<Map<String, String>> _slides = [
    {
      'image': 'assets/images/slider_images/image1.png',
      'title': 'Hizmetleri Keşfet',
      'description':
          'Pansiyon, bakım ve gezdirme gibi hizmetlere kolayca ulaşın.',
    },
    {
      'image': 'assets/images/slider_images/image2.png',
      'title': 'Bakıcıları Bul',
      'description': 'Yakınınızdaki güvenilir ve puanlı bakıcıları inceleyin.',
    },
    {
      'image': 'assets/images/slider_images/image3.png',
      'title': 'Hızlı Talep Oluştur',
      'description':
          'İhtiyacınız olan hizmet için saniyeler içinde talep oluşturun.',
    },
    {
      'image': 'assets/images/slider_images/image4.png',
      'title': 'İş Fırsatları',
      'description': 'Bakıcı olarak iş ilanlarını takip edin ve başvurun.',
    },
    {
      'image': 'assets/images/slider_images/image5.png',
      'title': 'Taleplerini Yönet',
      'description':
          'Aktif taleplerinizi ve rezervasyon durumlarını kontrol edin.',
    },
    {
      'image': 'assets/images/slider_images/image6.png',
      'title': 'Kolay İletişim',
      'description':
          'Bakıcılarla uygulama üzerinden güvenli bir şekilde mesajlaşın.',
    },
    {
      'image': 'assets/images/slider_images/image7.png',
      'title': 'Gelen Kutusu',
      'description':
          'Tüm mesajlaşmalarınızı ve bildirimlerinizi tek yerden yönetin.',
    },
    {
      'image': 'assets/images/slider_images/image8.png',
      'title': 'Çeşitli Hizmetler',
      'description': 'Veterinerden eğitime kadar geniş hizmet yelpazesi.',
    },
    {
      'image': 'assets/images/slider_images/image9.png',
      'title': 'Konum Bazlı Hizmet',
      'description':
          'Size en yakın hizmetleri bulmak için konumunuzu belirleyin.',
    },
    {
      'image': 'assets/images/slider_images/image10.png',
      'title': '7/24 Destek',
      'description':
          'Yardım merkezi ve destek talepleriyle her an yanınızdayız.',
    },
    {
      'image': 'assets/images/slider_images/image11.png',
      'title': 'Bize Ulaşın',
      'description':
          'Sorularınız ve önerileriniz için destek formunu kullanın.',
    },
    {
      'image': 'assets/images/slider_images/image12.png',
      'title': 'Kullanıcı Profili',
      'description':
          'Profilinizi kişiselleştirin, rozetlerinizi ve favorilerinizi görün.',
    },
    {
      'image': 'assets/images/slider_images/image13.png',
      'title': 'Bilgilerini Güncelle',
      'description': 'İletişim ve kişisel bilgilerinizi güncel tutun.',
    },
    {
      'image': 'assets/images/slider_images/image14.png',
      'title': 'Tüm Dostlar İçin',
      'description':
          'Kedi, köpek, kuş ve daha fazlası için hizmet seçenekleri.',
    },
    {
      'image': 'assets/images/slider_images/image15.png',
      'title': 'Özelleştirilmiş Bakım',
      'description':
          'Evcil hayvanınızın özelliklerine göre en uygun bakımı bulun.',
    },
    {
      'image': 'assets/images/slider_images/image16.png',
      'title': 'Yürüyüş Arkadaşı',
      'description': 'Yürüyüşlerinizi planlayın ve takip edin.',
    },
    {
      'image': 'assets/images/slider_images/image17.png',
      'title': 'Anları Paylaş',
      'description': 'Zoozy topluluğu ile en güzel anılarınızı paylaşın.',
    },
    {
      'image': 'assets/images/slider_images/image18.png',
      'title': 'Canlı Takip',
      'description': 'Yürüyüş rotasını ve süresini harita üzerinden izleyin.',
    },
  ];

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _activePage = (_activePage + 1) % _slides.length;
      _controller.animateToPage(
        _activePage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Widget _dot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _activePage == index ? 20 : 8,
      decoration: BoxDecoration(
        color: _activePage == index
            ? const Color(0xFF7A4FAD)
            : Colors.grey.withOpacity(0.4),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Column(
      children: [
        SizedBox(
          height: width * 0.75,
          child: PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _activePage = i),
            itemBuilder: (context, index) {
              final item = _slides[index];
              return AnimatedScale(
                scale: _activePage == index ? 1 : 0.92,
                duration: const Duration(milliseconds: 300),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Image.asset(
                            item['image']!,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item['title']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['description']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, _dot),
        ),
      ],
    );
  }
}
