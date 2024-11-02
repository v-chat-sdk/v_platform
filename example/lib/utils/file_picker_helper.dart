import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:v_platform/v_platform.dart';

class FilePickerHelper {
  static Future<List<VPlatformFile>> pickFiles() async {
    List<VPlatformFile> pickedFilesPaths = [];
    try {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null) {
        if (kIsWeb) {
          // On web, use bytes since paths are not supported

          pickedFilesPaths = result.files
              .map((file) =>
                  VPlatformFile.fromBytes(name: file.name, bytes: file.bytes!))
              .toList();
        } else {
          pickedFilesPaths = result.files
              .map((file) =>
                  VPlatformFile.fromPath(fileLocalPath: file.xFile.path))
              .toList();
        }
      }
    } catch (e) {
      // Handle any error that might occur during file picking
      print('Error picking files: $e');
    }
    return pickedFilesPaths;
  }
}
