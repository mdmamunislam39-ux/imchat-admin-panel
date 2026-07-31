import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:math';

final Map<String, String> _registeredViews = {};

Widget buildWebImage(String url, double width, double height, BoxFit fit) {
  final key = '${url}_$fit';
  
  if (!_registeredViews.containsKey(key)) {
    final viewType = 'web-image-${url.hashCode}-${_registeredViews.length}';
    _registeredViews[key] = viewType;
    
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final img = html.ImageElement()
          ..src = url
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = fit == BoxFit.cover ? 'cover' : 'contain';
        return img;
      },
    );
  }

  return SizedBox(
    width: width,
    height: height,
    child: HtmlElementView(viewType: _registeredViews[key]!),
  );
}
