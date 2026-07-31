import 'package:flutter/material.dart';

Widget buildWebImage(String url, double width, double height, BoxFit fit) {
  return SizedBox(
    width: width,
    height: height,
    child: const Center(
      child: Icon(Icons.image_not_supported, color: Colors.grey),
    ),
  );
}
