import 'dart:convert';
import 'dart:html' as html;

class FileDownloader {
  static Future<bool> downloadFile({
    required String content,
    required String filename,
    String mimeType = 'text/csv;charset=utf-8',
  }) async {
    try {
      // Thêm BOM \uFEFF để Microsoft Excel mở UTF-8 không lỗi font tiếng Việt
      final bytes = utf8.encode('\uFEFF$content');
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
      return true;
    } catch (_) {
      return false;
    }
  }
}
