import 'package:flutter/material.dart';

import 'web_image_stub.dart'
    if (dart.library.html) 'web_image_web.dart'; 

class WebPlatformImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;

  const WebPlatformImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return platformImage(imageUrl, fit: fit);
  }
}
