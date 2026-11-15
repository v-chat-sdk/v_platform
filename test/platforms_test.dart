import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v_platform/v_platform.dart';

void main() {
  setUp(() {
    VPlatforms.isWeb = false;
    VPlatforms.isWasm = false;
  });

  tearDown(() {
    VPlatforms.isWeb = kIsWeb;
    VPlatforms.isWasm = kIsWasm;
    debugDefaultTargetPlatformOverride = null;
  });

  group('VPlatforms', () {
    test('reports WASM before generic web', () {
      VPlatforms.isWeb = true;
      VPlatforms.isWasm = true;

      expect(VPlatforms.currentOs, VOs.wasm);
      expect(VPlatforms.currentPlatform, 'wasm');
    });

    test('maps the browser host without user-agent parsing', () {
      VPlatforms.isWeb = true;
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      expect(VPlatforms.currentOs, VOs.web);
      expect(VPlatforms.osInWeb, VOs.ios);
      expect(VPlatforms.isWebRunOnMobile, isTrue);
      expect(VPlatforms.isIOS, isFalse);
    });

    test('maps native desktop targets', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      expect(VPlatforms.currentOs, VOs.windows);
      expect(VPlatforms.isWindows, isTrue);
      expect(VPlatforms.isDesktop, isTrue);
    });

    test('creates a multipart file from bytes', () async {
      final multipart = await VPlatforms.getMultipartFile(
        source: VPlatformFile.fromBytes(
          name: 'photo.png',
          bytes: <int>[1, 2, 3],
        ),
        fieldName: 'upload',
      );

      expect(multipart.field, 'upload');
      expect(multipart.filename, 'photo.png');
      expect(multipart.contentType.toString(), 'image/png');
      expect(multipart.length, 3);
      expect(
        await multipart.finalize().fold<List<int>>(
          <int>[],
          (bytes, chunk) => bytes..addAll(chunk),
        ),
        <int>[1, 2, 3],
      );
    });

    test('rejects unsupported multipart sources', () async {
      final source = VPlatformFile.fromAssets(assetsPath: 'assets/photo.png');

      await expectLater(
        VPlatforms.getMultipartFile(source: source),
        throwsArgumentError,
      );
      await expectLater(
        VPlatforms.getMultipartFile(source: source, fieldName: ' '),
        throwsArgumentError,
      );
    });
  });
}
