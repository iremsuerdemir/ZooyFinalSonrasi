import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

// Counter to generate unique IDs
int _counter = 0;

Widget platformImage(String url, {BoxFit fit = BoxFit.cover}) {
  final String viewId = 'image-element-${_counter++}';

  // Register the standard HTML img element
  // This bypasses CanvasKit/XHR CORS issues because the browser handles the <img> tag
  ui.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
    final element = web.HTMLImageElement();
    element.src = url;
    element.style.width = '100%';
    element.style.height = '100%';
    // Eğer resim yüklenemezse (404, vb.) konsola bas ve varsayılan resmi göster
    element.onError.listen((event) {
      print('Web Image Load Error: $url');
      // Varsayılan placeholder veya transparan
      // element.src = 'assets/assets/images/caregiver1.png'; // Yol karmaşası olabilir
      // En güvenlisi:
      element.src = 'https://placehold.co/400x400?text=Resim+Yok'; 
    });
    
    // Object-fit property handles the "BoxFit" logic in CSS
    String objectFit = 'cover';
    if (fit == BoxFit.contain) objectFit = 'contain';
    if (fit == BoxFit.fill) objectFit = 'fill';
    
    element.style.objectFit = objectFit;
    return element;
  });

  return HtmlElementView(viewType: viewId);
}
