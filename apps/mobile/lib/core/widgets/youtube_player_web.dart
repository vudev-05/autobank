// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

final Set<String> _registeredYouTubeViews = {};

Widget buildYouTubeIFrame(String videoUrl) {
  String videoId = 'kYJqD9bZ_fQ';
  try {
    if (videoUrl.contains('v=')) {
      videoId = videoUrl.split('v=')[1].split('&')[0];
    } else if (videoUrl.contains('youtu.be/')) {
      videoId = videoUrl.split('youtu.be/')[1].split('?')[0];
    } else if (videoUrl.contains('embed/')) {
      videoId = videoUrl.split('embed/')[1].split('?')[0];
    }
  } catch (_) {}

  final viewType = 'youtube-iframe-$videoId';
  if (!_registeredYouTubeViews.contains(viewType)) {
    _registeredYouTubeViews.add(viewType);
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = 'https://www.youtube.com/embed/$videoId?autoplay=1&rel=0'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow = 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture'
          ..allowFullscreen = true;
        return iframe;
      },
    );
  }

  return HtmlElementView(viewType: viewType);
}
