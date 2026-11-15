import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:v_platform/v_platform.dart';

class FilePickerHelper {
  static Future<List<VPlatformFile>> pickFiles() async {
    final files = await FilePicker.pickFiles();
    if (files.isEmpty) return const <VPlatformFile>[];

    return Future.wait(
      files.map((file) async {
        final path = file.path;
        if (!kIsWeb && path != null) {
          return VPlatformFile.fromPath(fileLocalPath: path);
        }
        return VPlatformFile.fromBytes(
          name: file.name,
          bytes: await file.readAsBytes(),
        );
      }),
    );
  }
}
