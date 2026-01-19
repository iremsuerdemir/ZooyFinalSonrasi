import 'package:flutter/material.dart';

Widget platformImage(String url, {BoxFit fit = BoxFit.cover}) {
  // Mobile fallback
  return Image.network(
    url,
    fit: fit,
    errorBuilder: (context, error, stackTrace) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.error, color: Colors.grey),
      );
    },
  );
}
