import 'package:flutter/services.dart';

class FileDownloader {
  static Future<bool> downloadFile({
    required String content,
    required String filename,
    String mimeType = 'text/csv;charset=utf-8',
  }) async {
    try {
      await Clipboard.setData(ClipboardData(text: content));
      return true;
    } catch (_) {
      return false;
    }
  }
}
