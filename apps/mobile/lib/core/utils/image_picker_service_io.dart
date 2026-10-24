import 'dart:convert';
import 'package:image_picker/image_picker.dart';

abstract class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickImageAsBase64() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (file == null) return null;
      final bytes = await file.readAsBytes();
      final base64Str = base64Encode(bytes);
      return 'data:image/png;base64,$base64Str';
    } catch (e) {
      return null;
    }
  }
}
