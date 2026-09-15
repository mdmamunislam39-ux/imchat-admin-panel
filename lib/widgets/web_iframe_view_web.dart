// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

final Set<String> _registeredViews = {};

Widget buildWebIframe({required String viewId, required String url}) {
  if (!_registeredViews.contains(viewId)) {
    _registeredViews.add(viewId);
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
      final iframe = html.IFrameElement()
        ..src = url
        ..id = 'iframe_$viewId'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.overflow = 'hidden'
        ..allow = 'autoplay; fullscreen';
      return iframe;
    });
  } else {
    // If already registered, update iframe src dynamically if needed
    final elem = html.document.getElementById('iframe_$viewId') as html.IFrameElement?;
    if (elem != null && elem.src != url) {
      elem.src = url;
    }
  }

  return HtmlElementView(viewType: viewId);
}

void openWebPopup(String url, {int width = 450, int height = 750}) {
  final screenW = html.window.screen?.width ?? 1200;
  final screenH = html.window.screen?.height ?? 800;
  final left = (screenW - width) ~/ 2;
  final top = (screenH - height) ~/ 2;
  html.window.open(
    url,
    'KingQueenSlotPopup',
    'width=$width,height=$height,left=$left,top=$top,menubar=no,status=no,toolbar=no,resizable=yes',
  );
}
