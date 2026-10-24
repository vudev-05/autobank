// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;

class ImagePickerService {
  static Future<String?> pickImageAsBase64() async {
    final completer = Completer<String?>();
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();

    input.onChange.listen((event) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        completer.complete(null);
        return;
      }
      final reader = html.FileReader();
      reader.onLoadEnd.listen((e) {
        final result = reader.result as String?;
        completer.complete(result);
      });
      reader.onError.listen((e) {
        completer.complete(null);
      });
      reader.readAsDataUrl(files[0]);
    });

    return completer.future;
  }
}
