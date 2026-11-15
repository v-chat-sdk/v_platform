// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:file_sizes/file_sizes.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import 'enums.dart';
import 'io/file_operations.dart' as file_io;

/// `VPlatformFile` is a class to handle various file sources such as local file path,
/// byte array, URL, and assets. It provides utility methods for accessing file information
/// like MIME type, media type, and size in human-readable format.
///
/// You can create an instance using one of the following constructors:
/// * `VPlatformFile.fromBytes` for files in bytes form.
/// * `VPlatformFile.fromPath` for files with a local path.
/// * `VPlatformFile.fromUrl` for files from a URL.
/// * `VPlatformFile.fromAssets` for asset files.
class VPlatformFile {
  /// The name of the file.
  String name;

  /// Stable identifier derived from the source's contents or location metadata.
  String fileHash;

  /// Path to the file if it’s an asset.
  String? assetsPath;

  /// Local file path if the file is stored locally.
  String? fileLocalPath;

  /// File content in byte array form, if provided as bytes.
  List<int>? bytes;

  /// MIME type of the file, used to identify the file type (e.g., image, video).
  String? mimeType;

  /// URL path of the file if it’s web-based.
  String? networkUrl;

  /// Size of the file in bytes.
  int fileSize;

  /// Type of media (e.g., file, image, video), derived from `mimeType`.
  late VSupportedFilesType mediaType;

  /// Flags to indicate if the file is a generic file, video, or image based on `mediaType`.
  late bool isContentFile;
  late bool isContentVideo;
  late bool isContentImage;

  /// Private constructor for internal use. It initializes all fields and sets default values.
  VPlatformFile._({
    required this.name,
    this.fileLocalPath,
    this.bytes,
    this.assetsPath,
    required this.fileHash,
    this.networkUrl,
    required this.fileSize,
    this.mimeType,
  }) {
    _initialize();
  }

  /// Returns the full URL if the file is web-based and a base URL is set.
  String? get fullNetworkUrl {
    final value = networkUrl;
    if (value == null) return null;

    final uri = Uri.tryParse(value);
    if (uri == null || uri.hasScheme) return value;

    final baseUrl = VPlatformFileUtils.baseMediaUrl;
    if (baseUrl == null || baseUrl.trim().isEmpty) return value;

    final baseUri = Uri.tryParse(baseUrl.trim());
    if (baseUri == null || !baseUri.hasScheme) return value;

    final normalizedBase = baseUri.path.endsWith('/')
        ? baseUri
        : baseUri.replace(path: '${baseUri.path}/');
    return normalizedBase.resolveUri(uri).toString();
  }

  /// Gets the MIME type based on the file name.
  String? get getMimeType => lookupMimeType(name, headerBytes: bytes);

  /// Checks if the file source is a local path.
  bool get isFromPath => fileLocalPath != null;

  /// Checks if the file source is an asset.
  bool get isFromAssets => assetsPath != null;

  /// Checks if the file source is provided as bytes.
  bool get isFromBytes => bytes != null;

  /// Gets the file extension (e.g., .jpg, .mp4) from the file name.
  String get extension {
    return p.extension(name);
  }

  num get sizeInMb => fileSize / 1024 / 1024;

  /// Checks if the file source is a URL.
  bool get isFromUrl => networkUrl != null;

  /// Checks if the file source is not a URL.
  bool get isNotUrl => !isFromUrl;

  /// Returns the file size in a human-readable string (e.g., KB, MB).
  String get readableSize => FileSize.getSize(fileSize);

  /// Returns a unique URL path used for caching.
  String get getCachedUrlKey {
    final url = fullNetworkUrl;
    return url == null ? name : _hashString(_canonicalUrl(url));
  }

  /// Returns the file content as bytes. If `bytes` is null, reads from `fileLocalPath`.
  List<int> get getBytes {
    if (bytes != null) {
      return bytes!;
    }
    if (fileLocalPath != null) {
      return file_io.readAsBytesSync(fileLocalPath!);
    }
    return [];
  }

  /// Returns the file content as a `Uint8List`, which is helpful for image handling.
  Uint8List get uint8List {
    return Uint8List.fromList(getBytes);
  }

  /// Constructor for creating an instance from bytes. Computes the file hash and size.
  factory VPlatformFile.fromBytes({
    required String name,
    required List<int> bytes,
  }) {
    _requireNotEmpty(name, 'name');
    final byteCopy = _validatedByteCopy(bytes);
    return VPlatformFile._(
      name: name,
      bytes: byteCopy,
      fileSize: byteCopy.length,
      fileHash: sha256.convert(byteCopy).toString(),
    );
  }

  /// Constructor for creating an instance from a local file path. Computes the file hash and size.
  factory VPlatformFile.fromPath({required String fileLocalPath}) {
    _requireNotEmpty(fileLocalPath, 'fileLocalPath');
    final fileSize = file_io.lengthSync(fileLocalPath);
    return VPlatformFile._(
      name: p.basename(fileLocalPath),
      fileLocalPath: fileLocalPath,
      fileSize: fileSize,
      fileHash: _generateFileHash(fileLocalPath, fileSize),
    );
  }

  /// Helper function to generate a unique file hash based on file attributes.
  /// Combines path, size, and last-modified time without reading the entire file.
  static String _generateFileHash(String path, int fileSize) {
    final lastModified = file_io.lastModifiedMillisecondsSync(path);
    return _hashString('$path|$fileSize|$lastModified');
  }

  /// Constructor for creating an instance from a URL. Uses the URL to derive the file name and hash.
  factory VPlatformFile.fromUrl({
    int fileSize = 0,
    required String? networkUrl,
  }) {
    if (networkUrl == null) {
      throw ArgumentError.value(null, 'networkUrl', 'Must not be null.');
    }
    _requireNotEmpty(networkUrl, 'networkUrl');
    if (fileSize < 0) {
      throw ArgumentError.value(fileSize, 'fileSize', 'Must not be negative.');
    }
    final normalizedUrl = networkUrl.trim();
    return VPlatformFile._(
      name: _fileNameFromUrl(normalizedUrl),
      networkUrl: normalizedUrl,
      fileSize: fileSize,
      fileHash: _hashString(_canonicalUrl(normalizedUrl)),
    );
  }

  /// Constructor for creating an instance from an asset file path. Computes a default file hash.
  factory VPlatformFile.fromAssets({
    int fileSize = 0,
    required String assetsPath,
  }) {
    _requireNotEmpty(assetsPath, 'assetsPath');
    if (fileSize < 0) {
      throw ArgumentError.value(fileSize, 'fileSize', 'Must not be negative.');
    }
    return VPlatformFile._(
      name: p.basename(assetsPath),
      assetsPath: assetsPath,
      fileSize: fileSize,
      fileHash: _hashString(assetsPath),
    );
  }

  /// Converts the `VPlatformFile` instance to a map for serialization.
  /// It encodes `bytes` to Base64 if they are available.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'networkUrl': networkUrl,
      'filePath': fileLocalPath,
      'assetsPath': assetsPath,
      'bytes': bytes != null ? base64Encode(bytes!) : null,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'fileHash': fileHash,
    };
  }

  /// Factory constructor to create a `VPlatformFile` from a map.
  /// It decodes Base64 `bytes` if provided in the map.
  factory VPlatformFile.fromMap(Map<String, dynamic> map) {
    final name = _optionalString(map, 'name');
    final filePath = _nonEmptyString(map, 'filePath');
    final assetsPath = _nonEmptyString(map, 'assetsPath');
    final bytes = _decodeBytes(map['bytes']);
    final networkUrl = _firstNonEmptyString(map, const <String>[
      'preSignedUrl',
      'networkUrl',
      'url',
    ], trim: true);

    if (name == null || name.trim().isEmpty) {
      throw ArgumentError('The "name" field is required in the map.');
    }

    if (filePath == null &&
        assetsPath == null &&
        bytes == null &&
        networkUrl == null) {
      throw ArgumentError(
        "At least one of 'filePath', 'assetsPath', 'bytes', or "
        "'networkUrl' must not be null.",
      );
    }

    final rawFileSize = map['fileSize'];
    if (rawFileSize != null && rawFileSize is! num) {
      throw ArgumentError.value(rawFileSize, 'fileSize', 'Must be a number.');
    }
    if (rawFileSize is num && (!rawFileSize.isFinite || rawFileSize % 1 != 0)) {
      throw ArgumentError.value(
        rawFileSize,
        'fileSize',
        'Must be a whole number.',
      );
    }
    final fileSize = (rawFileSize as num?)?.toInt() ?? bytes?.length ?? 0;
    if (fileSize < 0) {
      throw ArgumentError.value(fileSize, 'fileSize', 'Must not be negative.');
    }

    if (networkUrl != null) {
      _parseUriReference(networkUrl, 'networkUrl');
    }

    final rawMimeType = _optionalString(map, 'mimeType');
    final mimeType = rawMimeType == null || rawMimeType.trim().isEmpty
        ? null
        : rawMimeType.trim();

    return VPlatformFile._(
      name: name,
      fileLocalPath: filePath,
      networkUrl: networkUrl,
      assetsPath: assetsPath,
      bytes: bytes,
      mimeType: mimeType,
      fileSize: fileSize,
      fileHash: _mapFileHash(
        _optionalString(map, 'fileHash'),
        name: name,
        filePath: filePath,
        assetsPath: assetsPath,
        bytes: bytes,
        networkUrl: networkUrl,
      ),
    );
  }

  static List<int>? _decodeBytes(Object? value) {
    if (value == null) return null;
    if (value is String) return base64Decode(value);
    if (value is List) {
      return _validatedByteCopy(value);
    }
    throw ArgumentError.value(
      value,
      'bytes',
      'Must be a Base64 string or a list of byte values.',
    );
  }

  static List<int> _validatedByteCopy(Iterable<Object?> values) {
    return values
        .map((byte) {
          if (byte is! num ||
              !byte.isFinite ||
              byte < 0 ||
              byte > 255 ||
              byte % 1 != 0) {
            throw ArgumentError.value(
              byte,
              'bytes',
              'Each value must be a whole number between 0 and 255.',
            );
          }
          return byte.toInt();
        })
        .toList(growable: false);
  }

  static String? _optionalString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return null;
    if (value is String) return value;
    throw ArgumentError.value(value, key, 'Must be a string.');
  }

  static String? _nonEmptyString(Map<String, dynamic> map, String key) {
    final value = _optionalString(map, key);
    return value == null || value.trim().isEmpty ? null : value;
  }

  static String? _firstNonEmptyString(
    Map<String, dynamic> map,
    List<String> keys, {
    bool trim = false,
  }) {
    for (final key in keys) {
      final value = _optionalString(map, key);
      if (value == null || value.trim().isEmpty) continue;
      return trim ? value.trim() : value;
    }
    return null;
  }

  static String _mapFileHash(
    String? value, {
    required String name,
    String? filePath,
    String? assetsPath,
    List<int>? bytes,
    String? networkUrl,
  }) {
    if (value != null && value.trim().isNotEmpty) return value;
    if (bytes != null) return sha256.convert(bytes).toString();
    if (networkUrl != null) return _hashString(_canonicalUrl(networkUrl));
    return _hashString(filePath ?? assetsPath ?? name);
  }

  static String _fileNameFromUrl(String value) {
    final uri = _parseUriReference(value, 'networkUrl');
    final segments = uri.pathSegments.where((segment) => segment.isNotEmpty);
    if (segments.isNotEmpty) return segments.last;
    if (uri.host.isNotEmpty) return uri.host;
    throw ArgumentError.value(
      value,
      'networkUrl',
      'Must include a file name or host.',
    );
  }

  static Uri _parseUriReference(String value, String name) {
    if (RegExp(r'%(?![0-9a-fA-F]{2})').hasMatch(value)) {
      throw ArgumentError.value(value, name, 'Must be a valid URI.');
    }
    final uri = Uri.tryParse(value);
    if (uri == null) {
      throw ArgumentError.value(value, name, 'Must be a valid URI.');
    }
    return uri;
  }

  static String _canonicalUrl(String value) {
    final trimmed = value.trim();
    return trimmed.split('#').first.split('?').first;
  }

  static String _hashString(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }

  static String _urlForLogging(String value) {
    final canonical = _canonicalUrl(value);
    final uri = Uri.tryParse(canonical);
    if (uri == null || uri.userInfo.isEmpty) return canonical;
    return uri.replace(userInfo: '***').toString();
  }

  static String _pathForLogging(String value) {
    return p.posix.basename(value.replaceAll(r'\', '/'));
  }

  static void _requireNotEmpty(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'Must not be empty.');
    }
  }

  /// Initializes properties based on MIME type, URL path, and media type.
  /// This method is called within each constructor.
  void _initialize() {
    mimeType ??= getMimeType;
    mediaType = getMediaType;
    isContentFile = mediaType == VSupportedFilesType.file;
    isContentVideo = mediaType == VSupportedFilesType.video;
    isContentImage = mediaType == VSupportedFilesType.image;
  }

  /// Returns a string representation of the file object with key attributes.
  @override
  String toString() {
    final resolvedUrl = fullNetworkUrl;
    final safeLocalPath = fileLocalPath == null
        ? null
        : _pathForLogging(fileLocalPath!);
    final safeNetworkUrl = networkUrl == null
        ? null
        : _urlForLogging(networkUrl!);
    final safeFullNetworkUrl = resolvedUrl == null
        ? null
        : _urlForLogging(resolvedUrl);
    return 'VPlatformFile{name: $name, fileHash: $fileHash, assetsPath: $assetsPath, fileLocalPath: $safeLocalPath, bytes: ${bytes?.length}, mimeType: $mimeType, fileSize: $fileSize, networkUrl: $safeNetworkUrl, fullNetworkUrl: $safeFullNetworkUrl, getCachedUrlKey: $getCachedUrlKey, mediaType: $mediaType, isContentFile: $isContentFile, isContentVideo: $isContentVideo, isContentImage: $isContentImage}';
  }

  /// Determines the media type (file, image, video) based on MIME type.
  VSupportedFilesType get getMediaType {
    final mimeStr = mimeType;
    if (mimeStr == null) return VSupportedFilesType.file;
    final fileType = mimeStr.split('/').first.trim().toLowerCase();
    switch (fileType) {
      case 'video':
        return VSupportedFilesType.video;
      case 'image':
        return VSupportedFilesType.image;
      default:
        return VSupportedFilesType.file;
    }
  }
}

/// Abstract class to set a global base URL for media files.
/// This can be accessed and set throughout the application.
abstract class VPlatformFileUtils {
  /// Global base media URL used for all files with a URL source.
  static String? baseMediaUrl;
}
