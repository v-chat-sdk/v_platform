import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v_platform/v_platform.dart';

void main() {
  test('web byte, asset, URL, and multipart APIs remain usable', () async {
    if (!kIsWeb) return;

    final bytes = VPlatformFile.fromBytes(
      name: 'photo.png',
      bytes: <int>[1, 2, 3],
    );
    final asset = VPlatformFile.fromAssets(assetsPath: 'assets/photo.png');
    final network = VPlatformFile.fromUrl(
      networkUrl: 'https://example.com/photo.png',
    );
    final multipart = await VPlatforms.getMultipartFile(source: bytes);

    expect(VPlatforms.isWeb, isTrue);
    expect(VPlatforms.isWasm, kIsWasm);
    expect(VPlatforms.currentOs, kIsWasm ? VOs.wasm : VOs.web);
    expect(bytes.getBytes, <int>[1, 2, 3]);
    expect(asset.isFromAssets, isTrue);
    expect(network.fullNetworkUrl, 'https://example.com/photo.png');
    expect(multipart.length, 3);
  });

  test('web local-path APIs fail with a clear unsupported error', () {
    if (!kIsWeb) return;

    expect(
      () => VPlatformFile.fromPath(fileLocalPath: '/tmp/file.txt'),
      throwsA(
        isA<UnsupportedError>().having(
          (error) => error.message,
          'message',
          contains('Local file paths are not available'),
        ),
      ),
    );

    final restored = VPlatformFile.fromMap(<String, dynamic>{
      'name': 'file.txt',
      'filePath': '/tmp/file.txt',
    });
    expect(() => restored.getBytes, throwsA(isA<UnsupportedError>()));
  });
}
