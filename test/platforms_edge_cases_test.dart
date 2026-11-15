import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v_platform/v_platform.dart';

void main() {
  setUp(() {
    VPlatforms.isWeb = false;
    VPlatforms.isWasm = false;
    debugDefaultTargetPlatformOverride = null;
  });

  tearDown(() {
    VPlatforms.isWeb = kIsWeb;
    VPlatforms.isWasm = kIsWasm;
    debugDefaultTargetPlatformOverride = null;
  });

  group('VPlatforms native targets', () {
    test('maps every target and its derived capabilities', () {
      final cases =
          <
            ({
              TargetPlatform target,
              VOs os,
              bool mobile,
              bool desktop,
              bool darwin,
            })
          >[
            (
              target: TargetPlatform.android,
              os: VOs.android,
              mobile: true,
              desktop: false,
              darwin: false,
            ),
            (
              target: TargetPlatform.iOS,
              os: VOs.ios,
              mobile: true,
              desktop: false,
              darwin: true,
            ),
            (
              target: TargetPlatform.macOS,
              os: VOs.macOs,
              mobile: false,
              desktop: true,
              darwin: true,
            ),
            (
              target: TargetPlatform.windows,
              os: VOs.windows,
              mobile: false,
              desktop: true,
              darwin: false,
            ),
            (
              target: TargetPlatform.linux,
              os: VOs.linux,
              mobile: false,
              desktop: true,
              darwin: false,
            ),
            (
              target: TargetPlatform.fuchsia,
              os: VOs.fuchsia,
              mobile: false,
              desktop: false,
              darwin: false,
            ),
          ];

      for (final current in cases) {
        debugDefaultTargetPlatformOverride = current.target;

        expect(VPlatforms.currentOs, current.os, reason: '${current.target}');
        expect(VPlatforms.currentPlatform, current.os.name);
        expect(VPlatforms.osInWeb, current.os);
        expect(VPlatforms.isMobile, current.mobile);
        expect(VPlatforms.isDesktop, current.desktop);
        // ignore: deprecated_member_use
        expect(VPlatforms.isDeskTop, current.desktop);
        expect(VPlatforms.isDarwin, current.darwin);
        expect(VPlatforms.isAndroid, current.target == TargetPlatform.android);
        expect(VPlatforms.isIOS, current.target == TargetPlatform.iOS);
        expect(VPlatforms.isMacOs, current.target == TargetPlatform.macOS);
        expect(VPlatforms.isWindows, current.target == TargetPlatform.windows);
        expect(VPlatforms.isLinux, current.target == TargetPlatform.linux);
        expect(VPlatforms.isWebRunOnMobile, isFalse);
      }
    });

    test('reports WASM before web and native target values', () {
      VPlatforms.isWasm = true;
      VPlatforms.isWeb = true;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      expect(VPlatforms.currentOs, VOs.wasm);
      expect(VPlatforms.currentPlatform, 'wasm');
    });
  });

  group('VPlatforms web host targets', () {
    test('maps every browser host without exposing native flags', () {
      VPlatforms.isWeb = true;
      final cases = <TargetPlatform, VOs>{
        TargetPlatform.android: VOs.android,
        TargetPlatform.iOS: VOs.ios,
        TargetPlatform.macOS: VOs.macOs,
        TargetPlatform.windows: VOs.windows,
        TargetPlatform.linux: VOs.linux,
        TargetPlatform.fuchsia: VOs.fuchsia,
      };

      for (final entry in cases.entries) {
        debugDefaultTargetPlatformOverride = entry.key;

        expect(VPlatforms.currentOs, VOs.web);
        expect(VPlatforms.osInWeb, entry.value);
        expect(
          VPlatforms.isWebRunOnMobile,
          entry.key == TargetPlatform.android ||
              entry.key == TargetPlatform.iOS,
        );
        expect(VPlatforms.isMobile, isFalse);
        expect(VPlatforms.isDesktop, isFalse);
        expect(VPlatforms.isDarwin, isFalse);
        expect(VPlatforms.isAndroid, isFalse);
        expect(VPlatforms.isIOS, isFalse);
        expect(VPlatforms.isMacOs, isFalse);
        expect(VPlatforms.isWindows, isFalse);
        expect(VPlatforms.isLinux, isFalse);
      }
    });
  });

  group('VPlatforms multipart conversion', () {
    test(
      'creates an empty multipart body with the default field name',
      () async {
        final multipart = await VPlatforms.getMultipartFile(
          source: VPlatformFile.fromBytes(name: 'empty.bin', bytes: <int>[]),
        );

        expect(multipart.field, 'file');
        expect(multipart.filename, 'empty.bin');
        expect(multipart.length, 0);
        expect(
          await multipart.finalize().fold<List<int>>(
            <int>[],
            (result, chunk) => result..addAll(chunk),
          ),
          isEmpty,
        );
      },
    );

    test('streams a local file with its inferred content type', () async {
      final directory = Directory.systemTemp.createTempSync('v_platform_part_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final localFile = File('${directory.path}/note.txt')
        ..writeAsStringSync('multipart content');
      final multipart = await VPlatforms.getMultipartFile(
        source: VPlatformFile.fromPath(fileLocalPath: localFile.path),
        fieldName: 'attachment',
      );

      expect(multipart.field, 'attachment');
      expect(multipart.filename, 'note.txt');
      expect(multipart.contentType.toString(), 'text/plain');
      expect(multipart.length, localFile.lengthSync());
      expect(
        await multipart.finalize().fold<List<int>>(
          <int>[],
          (result, chunk) => result..addAll(chunk),
        ),
        localFile.readAsBytesSync(),
      );
    });

    test('prefers bytes when a deserialized source also has a path', () async {
      final source = VPlatformFile.fromMap(<String, dynamic>{
        'name': 'mixed.bin',
        'filePath': '/path/that/must/not/be/read',
        'bytes': <int>[4, 5, 6],
      });

      final multipart = await VPlatforms.getMultipartFile(source: source);

      expect(multipart.length, 3);
      expect(
        await multipart.finalize().fold<List<int>>(
          <int>[],
          (result, chunk) => result..addAll(chunk),
        ),
        <int>[4, 5, 6],
      );
    });

    test('reports missing local files asynchronously', () async {
      final source = VPlatformFile.fromMap(<String, dynamic>{
        'name': 'missing.txt',
        'filePath': '${Directory.systemTemp.path}/missing-v-platform-part',
      });

      await expectLater(
        VPlatforms.getMultipartFile(source: source),
        throwsA(isA<FileSystemException>()),
      );
    });

    test(
      'rejects empty fields, invalid MIME, and unsupported sources',
      () async {
        final bytes = VPlatformFile.fromBytes(
          name: 'file.bin',
          bytes: <int>[1],
        );
        final invalidMime = VPlatformFile.fromBytes(
          name: 'file.bin',
          bytes: <int>[1],
        )..mimeType = 'not a valid mime';

        for (final fieldName in <String>['', ' ', '\t\n']) {
          await expectLater(
            VPlatforms.getMultipartFile(source: bytes, fieldName: fieldName),
            throwsArgumentError,
          );
        }
        await expectLater(
          VPlatforms.getMultipartFile(source: invalidMime),
          throwsFormatException,
        );
        for (final source in <VPlatformFile>[
          VPlatformFile.fromAssets(assetsPath: 'assets/file.bin'),
          VPlatformFile.fromUrl(networkUrl: 'https://example.com/file.bin'),
        ]) {
          await expectLater(
            VPlatforms.getMultipartFile(source: source),
            throwsArgumentError,
          );
        }
      },
    );
  });
}
