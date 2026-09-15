import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;


final Map<String, String> _registeredViews = {};

Widget buildWebImage(String url, double width, double height, BoxFit fit) {
  if (url.trim().isEmpty || url == 'null') {
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        color: Colors.grey[800],
        child: const Icon(Icons.person, color: Colors.white),
      ),
    );
  }

  final key = '${url}_$fit';
  
  if (!_registeredViews.containsKey(key)) {
    final viewType = 'web-image-${url.hashCode}-${_registeredViews.length}';
    _registeredViews[key] = viewType;
    
    try {
      ui_web.platformViewRegistry.registerViewFactory(
        viewType,
        (int viewId) {
          final img = html.ImageElement()
            ..src = url
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.maxWidth = '${width}px'
            ..style.maxHeight = '${height}px'
            ..style.objectFit = fit == BoxFit.cover ? 'cover' : 'contain';
          return img;
        },
      );
    } catch (_) {}
  }

  final viewType = _registeredViews[key];
  if (viewType == null || viewType.isEmpty) {
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        color: Colors.grey[800],
        child: const Icon(Icons.person, color: Colors.white),
      ),
    );
  }

  return SizedBox(
    width: width,
    height: height,
    child: HtmlElementView(viewType: viewType),
  );
}
