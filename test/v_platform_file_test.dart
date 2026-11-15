import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v_platform/v_platform.dart';

void main() {
  tearDown(() {
    VPlatformFileUtils.baseMediaUrl = null;
  });

  group('VPlatformFile', () {
    test('creates a detached byte source with stable metadata', () {
      final sourceBytes = <int>[1, 2, 3, 4];
      final file = VPlatformFile.fromBytes(
        name: 'photo.png',
        bytes: sourceBytes,
      );

      sourceBytes[0] = 9;

      expect(file.bytes, <int>[1, 2, 3, 4]);
      expect(file.fileSize, 4);
      expect(file.fileHash, sha256.convert(<int>[1, 2, 3, 4]).toString());
      expect(file.mimeType, 'image/png');
      expect(file.isContentImage, isTrue);
      expect(file.uint8List, <int>[1, 2, 3, 4]);
    });

    test('reads local file metadata and bytes', () {
      final directory = Directory.systemTemp.createTempSync('v_platform_test_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final localFile = File('${directory.path}/sample.txt')
        ..writeAsStringSync('hello');

      final file = VPlatformFile.fromPath(fileLocalPath: localFile.path);

      expect(file.name, 'sample.txt');
      expect(file.fileSize, 5);
      expect(file.getBytes, localFile.readAsBytesSync());
      expect(file.fileHash, hasLength(64));
      expect(file.mimeType, 'text/plain');
    });

    test('normalizes URL names and resolves a base URL', () {
      VPlatformFileUtils.baseMediaUrl = 'https://cdn.example.com/media';
      final file = VPlatformFile.fromUrl(
        networkUrl: 'images/My%20Photo.jpg?token=one#preview',
      );
      final sameResource = VPlatformFile.fromUrl(
        networkUrl: 'images/My%20Photo.jpg?token=two',
      );

      expect(file.name, 'My Photo.jpg');
      expect(
        file.fullNetworkUrl,
        'https://cdn.example.com/media/images/My%20Photo.jpg?token=one#preview',
      );
      expect(file.getCachedUrlKey, sameResource.getCachedUrlKey);
      expect(file.getCachedUrlKey, hasLength(64));
      expect(file.isContentImage, isTrue);
    });

    test('keeps absolute URLs unchanged', () {
      VPlatformFileUtils.baseMediaUrl = 'https://cdn.example.com/media/';
      const url = 'https://files.example.com/video.mp4?token=abc';

      expect(VPlatformFile.fromUrl(networkUrl: url).fullNetworkUrl, url);
    });

    test('round-trips every supported serialized source', () {
      final sources = <VPlatformFile>[
        VPlatformFile.fromBytes(name: 'bytes.bin', bytes: <int>[4, 5, 6]),
        VPlatformFile.fromAssets(
          assetsPath: 'assets/images/avatar.png',
          fileSize: 12,
        ),
        VPlatformFile.fromUrl(
          networkUrl: 'https://example.com/report.pdf',
          fileSize: 42,
        ),
      ];

      for (final source in sources) {
        final restored = VPlatformFile.fromMap(source.toMap());
        expect(restored.name, source.name);
        expect(restored.fileHash, source.fileHash);
        expect(restored.fileSize, source.fileSize);
        expect(restored.bytes, source.bytes);
        expect(restored.assetsPath, source.assetsPath);
        expect(restored.networkUrl, source.networkUrl);
      }

      expect(sources[1].isNotUrl, isTrue);
    });

    test('accepts legacy map fields and numeric sizes', () {
      final file = VPlatformFile.fromMap(<String, dynamic>{
        'name': 'legacy.bin',
        'url': '/legacy.bin',
        'bytes': <int>[0, 127, 255],
        'fileSize': 3.0,
      });

      expect(file.networkUrl, '/legacy.bin');
      expect(file.bytes, <int>[0, 127, 255]);
      expect(file.fileSize, 3);
      expect(file.fileHash, hasLength(64));
    });

    test('rejects invalid constructor and map values', () {
      expect(
        () => VPlatformFile.fromUrl(networkUrl: null),
        throwsArgumentError,
      );
      expect(
        () => VPlatformFile.fromUrl(networkUrl: '   '),
        throwsArgumentError,
      );
      expect(
        () => VPlatformFile.fromAssets(assetsPath: 'asset.png', fileSize: -1),
        throwsArgumentError,
      );
      expect(
        () => VPlatformFile.fromMap(<String, dynamic>{'name': 'missing.bin'}),
        throwsArgumentError,
      );
      expect(
        () => VPlatformFile.fromMap(<String, dynamic>{
          'name': 'bad.bin',
          'bytes': <int>[256],
        }),
        throwsArgumentError,
      );
      expect(
        () => VPlatformFile.fromMap(<String, dynamic>{
          'name': 'bad.bin',
          'bytes': <int>[1],
          'fileSize': 1.5,
        }),
        throwsArgumentError,
      );
    });
  });
}
