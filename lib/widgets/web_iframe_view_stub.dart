import 'package:flutter/material.dart';

Widget buildWebIframe({required String viewId, required String url}) {
  return Container(
    color: Colors.black87,
    alignment: Alignment.center,
    padding: const EdgeInsets.all(20),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.open_in_browser, color: Colors.amber, size: 48),
        const SizedBox(height: 12),
        const Text(
          'Live Web Preview',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          url,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
        ),
      ],
    ),
  );
}

void openWebPopup(String url, {int width = 450, int height = 750}) {}
