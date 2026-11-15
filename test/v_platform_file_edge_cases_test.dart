import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v_platform/v_platform.dart';

void main() {
  setUp(() {
    VPlatformFileUtils.baseMediaUrl = null;
  });

  tearDown(() {
    VPlatformFileUtils.baseMediaUrl = null;
  });

  group('VPlatformFile source constructors', () {
    test('handles empty and substantial byte payloads deterministically', () {
      final empty = VPlatformFile.fromBytes(name: 'empty.bin', bytes: <int>[]);
      final sourceBytes = List<int>.generate(64 * 1024, (index) => index % 256);
      final file = VPlatformFile.fromBytes(
        name: 'archive.payload.bin',
        bytes: sourceBytes,
      );

      sourceBytes.fillRange(0, sourceBytes.length, 0);

      expect(empty.fileSize, 0);
      expect(empty.getBytes, isEmpty);
      expect(empty.uint8List, isEmpty);
      expect(file.fileSize, 64 * 1024);
      expect(file.bytes, isNot(equals(sourceBytes)));
      expect(file.fileHash, sha256.convert(file.bytes!).toString());
      expect(file.isFromBytes, isTrue);
      expect(file.isFromPath, isFalse);
      expect(file.isFromAssets, isFalse);
      expect(file.isFromUrl, isFalse);
      expect(file.isNotUrl, isTrue);
      expect(file.extension, '.bin');
      expect(file.readableSize, isNotEmpty);
    });

    test('rejects blank names and out-of-range byte values', () {
      expect(
        () => VPlatformFile.fromBytes(name: ' ', bytes: <int>[]),
        throwsArgumentError,
      );
      expect(
        () => VPlatformFile.fromBytes(name: 'bad.bin', bytes: <int>[-1]),
        throwsArgumentError,
      );
      expect(
        () => VPlatformFile.fromBytes(name: 'bad.bin', bytes: <int>[256]),
        throwsArgumentError,
      );
    });

    test('reads path metadata and changes its hash when the file changes', () {
      final directory = Directory.systemTemp.createTempSync('v_platform_edge_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final localFile = File('${directory.path}/résumé.final.txt')
        ..writeAsStringSync('first');
      localFile.setLastModifiedSync(DateTime.utc(2025, 1, 1));

      final first = VPlatformFile.fromPath(fileLocalPath: localFile.path);
      final expectedHash = sha256
          .convert(
            utf8.encode(
              '${localFile.path}|${localFile.lengthSync()}|'
              '${localFile.lastModifiedSync().millisecondsSinceEpoch}',
            ),
          )
          .toString();

      expect(first.name, 'résumé.final.txt');
      expect(first.extension, '.txt');
      expect(first.fileHash, expectedHash);
      expect(first.getBytes, utf8.encode('first'));
      expect(first.isFromPath, isTrue);
      expect(first.isFromBytes, isFalse);
      expect(first.getCachedUrlKey, first.name);

      localFile
        ..writeAsStringSync('second version')
        ..setLastModifiedSync(DateTime.utc(2025, 1, 2));
      final second = VPlatformFile.fromPath(fileLocalPath: localFile.path);

      expect(second.fileHash, isNot(first.fileHash));
      expect(second.fileSize, localFile.lengthSync());
    });

    test('reports invalid and missing local paths', () {
      expect(
        () => VPlatformFile.fromPath(fileLocalPath: '  '),
        throwsArgumentError,
      );
      expect(
        () => VPlatformFile.fromPath(
          fileLocalPath: '${Directory.systemTemp.path}/missing-v-platform-file',
        ),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('exposes asset metadata without attempting local file access', () {
      final file = VPlatformFile.fromAssets(
        assetsPath: 'assets/images/icon.png',
        fileSize: 1024 * 1024,
      );

      expect(file.name, 'icon.png');
      expect(file.extension, '.png');
      expect(file.sizeInMb, 1);
      expect(file.getBytes, isEmpty);
      expect(file.uint8List, isEmpty);
      expect(file.isFromAssets, isTrue);
      expect(file.isFromBytes, isFalse);
      expect(file.isNotUrl, isTrue);
      expect(file.getCachedUrlKey, 'icon.png');
      expect(file.fileHash, hasLength(64));
    });

    test('rejects invalid asset metadata', () {
      expect(
        () => VPlatformFile.fromAssets(assetsPath: ''),
        throwsArgumentError,
      );
      expect(
        () => VPlatformFile.fromAssets(assetsPath: 'asset.png', fileSize: -1),
        throwsArgumentError,
      );
    });
  });

  group('VPlatformFile URL handling', () {
    test(
      'resolves relative, root-relative, parent, and scheme-relative URLs',
      () {
        VPlatformFileUtils.baseMediaUrl = ' https://cdn.example.com/root/api ';
        final cases = <String, String>{
          'images/a.jpg': 'https://cdn.example.com/root/api/images/a.jpg',
          '/images/a.jpg': 'https://cdn.example.com/images/a.jpg',
          '../a.jpg': 'https://cdn.example.com/root/a.jpg',
          '//static.example.com/a.jpg': 'https://static.example.com/a.jpg',
          'https://files.example.com/a.jpg': 'https://files.example.com/a.jpg',
        };

        for (final entry in cases.entries) {
          expect(
            VPlatformFile.fromUrl(networkUrl: entry.key).fullNetworkUrl,
            entry.value,
            reason: entry.key,
          );
        }
      },
    );

    test('leaves relative URLs alone when the base is absent or invalid', () {
      for (final base in <String?>[null, '', ' ', 'cdn.example.com/media']) {
        VPlatformFileUtils.baseMediaUrl = base;
        expect(
          VPlatformFile.fromUrl(networkUrl: 'images/a.jpg').fullNetworkUrl,
          'images/a.jpg',
          reason: 'base=$base',
        );
      }
    });

    test('decodes names and handles host-only and trailing-slash URLs', () {
      expect(
        VPlatformFile.fromUrl(
          networkUrl: 'https://example.com/%E2%9C%93%20file.pdf?token=1',
        ).name,
        '✓ file.pdf',
      );
      expect(
        VPlatformFile.fromUrl(networkUrl: 'https://example.com').name,
        'example.com',
      );
      expect(
        VPlatformFile.fromUrl(networkUrl: 'https://example.com/folder/').name,
        'folder',
      );
    });

    test('uses stable cache identifiers without credentials or fragments', () {
      VPlatformFileUtils.baseMediaUrl = 'https://cdn.example.com/media/';
      final first = VPlatformFile.fromUrl(
        networkUrl: 'photo.jpg?token=first#preview',
      );
      final second = VPlatformFile.fromUrl(
        networkUrl: 'photo.jpg?token=second#other',
      );
      final different = VPlatformFile.fromUrl(networkUrl: 'other.jpg');

      expect(first.fileHash, second.fileHash);
      expect(first.getCachedUrlKey, second.getCachedUrlKey);
      expect(first.getCachedUrlKey, hasLength(64));
      expect(first.getCachedUrlKey, isNot(different.getCachedUrlKey));
    });

    test('validates URL values and sizes', () {
      expect(
        () => VPlatformFile.fromUrl(networkUrl: null),
        throwsArgumentError,
      );
      expect(
        () => VPlatformFile.fromUrl(networkUrl: '  '),
        throwsArgumentError,
      );
      expect(() => VPlatformFile.fromUrl(networkUrl: '%'), throwsArgumentError);
      expect(
        () => VPlatformFile.fromUrl(networkUrl: 'https://[::1/file.txt'),
        throwsArgumentError,
      );
      expect(() => VPlatformFile.fromUrl(networkUrl: '/'), throwsArgumentError);
      expect(
        () => VPlatformFile.fromUrl(networkUrl: 'file.txt', fileSize: -1),
        throwsArgumentError,
      );
    });
  });

  group('VPlatformFile map serialization', () {
    test('round-trips deterministic random byte payloads', () {
      final random = Random(20260816);
      final lengths = <int>[
        0,
        1,
        255,
        4096,
        ...List<int>.generate(32, (_) => random.nextInt(8192)),
      ];

      for (final length in lengths) {
        final bytes = List<int>.generate(
          length,
          (_) => random.nextInt(256),
          growable: false,
        );
        final original = VPlatformFile.fromBytes(
          name: 'ملف_$length.bin',
          bytes: bytes,
        );
        final map = original.toMap();
        final decoded = jsonDecode(jsonEncode(map)) as Map<String, dynamic>;
        final restored = VPlatformFile.fromMap(decoded);

        expect(base64Decode(map['bytes']! as String), bytes);
        expect(restored.name, original.name);
        expect(restored.bytes, bytes);
        expect(restored.fileSize, length);
        expect(restored.fileHash, original.fileHash);
        expect(restored.mimeType, original.mimeType);
      }
    });

    test('accepts integral numeric bytes and file sizes', () {
      final file = VPlatformFile.fromMap(<String, dynamic>{
        'name': 'numbers.bin',
        'bytes': <num>[0.0, 127, 255.0],
        'fileSize': 3.0,
      });

      expect(file.bytes, <int>[0, 127, 255]);
      expect(file.fileSize, 3);
      expect(file.fileHash, sha256.convert(<int>[0, 127, 255]).toString());
    });

    test('allows an empty Base64 payload as a valid source', () {
      final file = VPlatformFile.fromMap(<String, dynamic>{
        'name': 'empty.bin',
        'bytes': '',
      });

      expect(file.bytes, isEmpty);
      expect(file.fileSize, 0);
      expect(file.isFromBytes, isTrue);
    });

    test('prefers signed, current, then legacy URL fields', () {
      const signed = 'https://signed.example.com/private/file.pdf?token=one';
      const current = '/private/file.pdf';
      const legacy = '/legacy/file.pdf';

      final signedFile = VPlatformFile.fromMap(<String, dynamic>{
        'name': 'file.pdf',
        'preSignedUrl': signed,
        'networkUrl': current,
        'url': legacy,
      });
      final currentFile = VPlatformFile.fromMap(<String, dynamic>{
        'name': 'file.pdf',
        'preSignedUrl': ' ',
        'networkUrl': current,
        'url': legacy,
      });
      final legacyFile = VPlatformFile.fromMap(<String, dynamic>{
        'name': 'file.pdf',
        'networkUrl': '',
        'url': legacy,
      });

      expect(signedFile.networkUrl, signed);
      expect(currentFile.networkUrl, current);
      expect(legacyFile.networkUrl, legacy);
    });

    test('computes source-specific fallback hashes', () {
      final bytes = VPlatformFile.fromMap(<String, dynamic>{
        'name': 'file.bin',
        'bytes': <int>[1, 2],
        'fileHash': '   ',
      });
      final network = VPlatformFile.fromMap(<String, dynamic>{
        'name': 'file.bin',
        'networkUrl': '/file.bin?token=secret',
      });
      final path = VPlatformFile.fromMap(<String, dynamic>{
        'name': 'file.bin',
        'filePath': '/tmp/file.bin',
      });
      final asset = VPlatformFile.fromMap(<String, dynamic>{
        'name': 'file.bin',
        'assetsPath': 'assets/file.bin',
      });

      expect(bytes.fileHash, sha256.convert(<int>[1, 2]).toString());
      expect(network.fileHash, hasLength(64));
      expect(path.fileHash, hasLength(64));
      expect(asset.fileHash, hasLength(64));
      expect(<String>{
        network.fileHash,
        path.fileHash,
        asset.fileHash,
      }, hasLength(3));
    });

    test('preserves valid explicit metadata and infers blank MIME types', () {
      final explicit = VPlatformFile.fromMap(<String, dynamic>{
        'name': 'photo.custom',
        'assetsPath': 'assets/photo.custom',
        'fileHash': 'server-id',
        'mimeType': 'IMAGE/PNG',
        'fileSize': 99,
      });
      final inferred = VPlatformFile.fromMap(<String, dynamic>{
        'name': 'photo.png',
        'assetsPath': 'assets/photo.png',
        'mimeType': ' ',
      });

      expect(explicit.fileHash, 'server-id');
      expect(explicit.fileSize, 99);
      expect(explicit.mediaType, VSupportedFilesType.image);
      expect(inferred.mimeType, 'image/png');
      expect(inferred.isContentImage, isTrue);
    });

    test('rejects missing, blank, and incorrectly typed fields', () {
      final invalidMaps = <Map<String, dynamic>>[
        <String, dynamic>{
          'bytes': <int>[1],
        },
        <String, dynamic>{
          'name': ' ',
          'bytes': <int>[1],
        },
        <String, dynamic>{
          'name': 7,
          'bytes': <int>[1],
        },
        <String, dynamic>{'name': 'file.bin'},
        <String, dynamic>{'name': 'file.bin', 'filePath': ' '},
        <String, dynamic>{'name': 'file.bin', 'assetsPath': ''},
        <String, dynamic>{'name': 'file.bin', 'networkUrl': ' '},
        <String, dynamic>{
          'name': 'file.bin',
          'bytes': <int>[1],
          'fileSize': '1',
        },
        <String, dynamic>{
          'name': 'file.bin',
          'bytes': <int>[1],
          'fileSize': -1,
        },
        <String, dynamic>{
          'name': 'file.bin',
          'bytes': <int>[1],
          'fileSize': 1.5,
        },
        <String, dynamic>{
          'name': 'file.bin',
          'bytes': <int>[1],
          'fileSize': double.nan,
        },
        <String, dynamic>{
          'name': 'file.bin',
          'bytes': <int>[1],
          'fileSize': double.infinity,
        },
        <String, dynamic>{'name': 'file.bin', 'bytes': Object()},
        <String, dynamic>{
          'name': 'file.bin',
          'bytes': <int>[-1],
        },
        <String, dynamic>{
          'name': 'file.bin',
          'bytes': <int>[256],
        },
        <String, dynamic>{
          'name': 'file.bin',
          'bytes': <num>[1.5],
        },
        <String, dynamic>{
          'name': 'file.bin',
          'bytes': <Object>['1'],
        },
        <String, dynamic>{
          'name': 'file.bin',
          'bytes': <int>[1],
          'fileHash': 7,
        },
        <String, dynamic>{
          'name': 'file.bin',
          'bytes': <int>[1],
          'mimeType': 7,
        },
        <String, dynamic>{'name': 'file.bin', 'filePath': 7},
        <String, dynamic>{'name': 'file.bin', 'preSignedUrl': 7},
      ];

      for (final map in invalidMaps) {
        expect(
          () => VPlatformFile.fromMap(map),
          throwsArgumentError,
          reason: map.toString(),
        );
      }
      expect(
        () => VPlatformFile.fromMap(<String, dynamic>{
          'name': 'file.bin',
          'bytes': 'not-base64!',
        }),
        throwsFormatException,
      );
    });
  });

  group('VPlatformFile MIME and diagnostics', () {
    test(
      'detects MIME types from signatures and classifies common families',
      () {
        final signature = VPlatformFile.fromBytes(
          name: 'upload.bin',
          bytes: <int>[137, 80, 78, 71, 13, 10, 26, 10],
        );
        final video = VPlatformFile.fromMap(<String, dynamic>{
          'name': 'movie.custom',
          'assetsPath': 'assets/movie.custom',
          'mimeType': ' Video/MP4; codecs=h264 ',
        });
        final audio = VPlatformFile.fromMap(<String, dynamic>{
          'name': 'sound.custom',
          'assetsPath': 'assets/sound.custom',
          'mimeType': 'audio/mpeg',
        });

        expect(signature.mimeType, 'image/png');
        expect(signature.mediaType, VSupportedFilesType.image);
        expect(video.mediaType, VSupportedFilesType.video);
        expect(video.isContentVideo, isTrue);
        expect(audio.mediaType, VSupportedFilesType.file);
        expect(audio.isContentFile, isTrue);
      },
    );

    test('does not expose signed credentials or full local paths in toString', () {
      final network = VPlatformFile.fromMap(<String, dynamic>{
        'name': 'private.pdf',
        'networkUrl':
            'https://user:password@example.com/private.pdf?signature=secret#x',
      });
      final local = VPlatformFile.fromMap(<String, dynamic>{
        'name': 'private.txt',
        'filePath': '/Users/person/private/private.txt',
      });
      final windowsLocal = VPlatformFile.fromMap(<String, dynamic>{
        'name': 'private.txt',
        'filePath': r'C:\Users\person\private\private.txt',
      });

      final networkText = network.toString();
      final localText = local.toString();

      expect(networkText, contains('private.pdf'));
      expect(networkText, isNot(contains('password')));
      expect(networkText, isNot(contains('signature')));
      expect(networkText, isNot(contains('secret')));
      expect(networkText, isNot(contains('#x')));
      expect(localText, isNot(contains('/Users/person/private')));
      expect(windowsLocal.toString(), isNot(contains(r'C:\Users\person')));
    });

    test('diagnostics remain safe after public URL fields are mutated', () {
      final file = VPlatformFile.fromUrl(
        networkUrl: 'https://example.com/file.pdf',
      )..networkUrl = 'https://[::1';
      final diagnostics = file.toString();

      expect(diagnostics, contains('networkUrl: https://[::1'));
      expect(diagnostics, contains('name: file.pdf'));
    });
  });
}
