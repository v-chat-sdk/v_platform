// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'enums.dart';
import 'v_platform_file.dart';

/// Cross-platform operating-system checks and multipart upload helpers.
abstract class VPlatforms {
  static bool isWeb = kIsWeb;
  static bool isWasm = kIsWasm;

  static bool get isMobile => !isWeb && (isAndroid || isIOS);

  static bool get isAndroid =>
      !isWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get isIOS =>
      !isWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isMacOs =>
      !isWeb && defaultTargetPlatform == TargetPlatform.macOS;

  static bool get isDarwin => !isWeb && (isMacOs || isIOS);

  static String get currentPlatform {
    return currentOs.name;
  }

  static VOs get currentOs {
    if (isWasm) {
      return VOs.wasm;
    }
    if (isWeb) {
      return VOs.web;
    }
    return _osForTargetPlatform(defaultTargetPlatform);
  }

  /// Returns the browser host OS when running on web.
  static VOs get osInWeb {
    if (!isWeb) {
      return currentOs;
    }
    return _osForTargetPlatform(defaultTargetPlatform);
  }

  static bool get isWindows =>
      !isWeb && defaultTargetPlatform == TargetPlatform.windows;

  /// Whether the current native target is a desktop operating system.
  static bool get isDesktop => isWindows || isLinux || isMacOs;

  /// Deprecated misspelling retained for source compatibility.
  @Deprecated('Use isDesktop instead.')
  static bool get isDeskTop => isDesktop;

  static bool get isLinux =>
      !isWeb && defaultTargetPlatform == TargetPlatform.linux;

  /// Whether a web build is running on an Android or iOS host.
  static bool get isWebRunOnMobile {
    if (!isWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static VOs _osForTargetPlatform(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.android => VOs.android,
      TargetPlatform.iOS => VOs.ios,
      TargetPlatform.linux => VOs.linux,
      TargetPlatform.macOS => VOs.macOs,
      TargetPlatform.windows => VOs.windows,
      TargetPlatform.fuchsia => VOs.fuchsia,
    };
  }

  /// Converts an in-memory or local-path source to an HTTP multipart file.
  static Future<http.MultipartFile> getMultipartFile({
    required VPlatformFile source,
    String fieldName = 'file',
  }) async {
    if (fieldName.trim().isEmpty) {
      throw ArgumentError.value(fieldName, 'fieldName', 'Must not be empty.');
    }

    final mimeType = source.mimeType;
    final fileLocalPath = source.fileLocalPath;
    final bytes = source.bytes;

    final contentType = mimeType != null ? MediaType.parse(mimeType) : null;
    if (bytes != null) {
      return http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: source.name,
        contentType: contentType,
      );
    }
    if (fileLocalPath != null && fileLocalPath.isNotEmpty) {
      return http.MultipartFile.fromPath(
        fieldName,
        fileLocalPath,
        filename: source.name,
        contentType: contentType,
      );
    }
    throw ArgumentError.value(
      source,
      'source',
      'Multipart uploads require bytes or a local file path.',
    );
  }
}
