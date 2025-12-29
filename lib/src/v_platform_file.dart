// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:file_sizes/file_sizes.dart';
import 'package:mime_type/mime_type.dart';
import 'package:path/path.dart' as p;
import 'package:path/path.dart';

import 'enums.dart';

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

  /// SHA-256 hash of the file content, used as a unique identifier for cache or other purposes.
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
    if (networkUrl == null) return null;
    if (networkUrl!.startsWith("http")) return networkUrl;
    if (VPlatformFileUtils.baseMediaUrl == null) return networkUrl;
    return VPlatformFileUtils.baseMediaUrl! + networkUrl!;
  }

  /// Gets the MIME type based on the file name.
  String? get getMimeType => mime(name);

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

  /// Checks if the file source is not a URL (i.e., bytes or path).
  bool get isNotUrl => isFromBytes || isFromPath;

  /// Returns the file size in a human-readable string (e.g., KB, MB).
  String get readableSize => FileSize.getSize(fileSize);

  /// Returns a unique URL path used for caching.
  String get getCachedUrlKey {
    if (networkUrl == null) {
      return name;
    }
    final uri = Uri.parse(networkUrl!);
    return "${uri.scheme}://${uri.host}${uri.path}".hashCode.toString();
  }

  /// Returns the file content as bytes. If `bytes` is null, reads from `fileLocalPath`.
  List<int> get getBytes {
    if (bytes != null) {
      return bytes!;
    }
    if (fileLocalPath != null) {
      return File(fileLocalPath!).readAsBytesSync().toList();
    }
    return [];
  }

  /// Returns the file content as a `Uint8List`, which is helpful for image handling.
  Uint8List get uint8List {
    return Uint8List.fromList(getBytes);
  }

  /// Constructor for creating an instance from bytes. Computes the file hash and size.
  VPlatformFile.fromBytes({
    required this.name,
    required List<int> this.bytes,
  })  : fileSize = bytes.length,
        fileHash = sha256.convert(bytes).toString() {
    _initialize();
  }

  /// Constructor for creating an instance from a local file path. Computes the file hash and size.
  VPlatformFile.fromPath({
    required String this.fileLocalPath,
  })  : fileSize = File(fileLocalPath).lengthSync(),
        name = basename(fileLocalPath),
        fileHash = _generateFileHash(File(fileLocalPath)) {
    _initialize();
  }

  /// Helper function to generate a unique file hash based on file attributes.
  /// Combines file size, last modified date, and file extension to create a hash.
  static String _generateFileHash(File file) {
    final fileSize = file.lengthSync();
    final lastModified = file.lastModifiedSync().millisecondsSinceEpoch;
    final extension = file.path.split('.').last;
    return "$fileSize-$lastModified-$extension";
  }

  /// Constructor for creating an instance from a URL. Uses the URL to derive the file name and hash.
  VPlatformFile.fromUrl({
    this.fileSize = 0,
    required this.networkUrl,
  })  : name = basename(networkUrl!),
        fileHash = basenameWithoutExtension(networkUrl).replaceAll(" ", "-") {
    _initialize();
  }

  /// Constructor for creating an instance from an asset file path. Computes a default file hash.
  VPlatformFile.fromAssets({
    this.fileSize = 0,
    required String this.assetsPath,
  })  : name = basename(assetsPath),
        fileHash = basenameWithoutExtension(assetsPath).replaceAll(" ", "-") {
    _initialize();
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
    final name = map['name'] as String?;
    final filePath = map['filePath'] as String?;
    final assetsPath = map['assetsPath'] as String?;
    final bytesBase64 = map['bytes'] as String?;
    final bytes = bytesBase64 != null ? base64Decode(bytesBase64) : null;
    final networkUrl =
        (map['networkUrl'] as String?) ?? (map['url'] as String?);

    if (name == null) {
      throw ArgumentError('The "name" field is required in the map.');
    }

    if (filePath == null && bytes == null && networkUrl == null) {
      throw ArgumentError(
          "At least one of 'filePath', 'bytes', or 'networkUrl' must not be null. Map: $map");
    }

    final file = VPlatformFile._(
      name: name,
      fileLocalPath: filePath,
      networkUrl: networkUrl,
      assetsPath: assetsPath,
      bytes: bytes,
      mimeType: map['mimeType'] as String?,
      fileSize: map['fileSize'] as int? ?? 0,
      fileHash: (map['fileHash'] as String?) ??
          basenameWithoutExtension(name).replaceAll(" ", "-"),
    );

    file._initialize();

    return file;
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
    return 'VPlatformFile{name: $name, fileHash: $fileHash, assetsPath: $assetsPath, fileLocalPath: $fileLocalPath, bytes: ${bytes?.length}, mimeType: $mimeType, fileSize: $fileSize, networkUrl: $networkUrl, fullNetworkUrl: $fullNetworkUrl, getCachedUrlKey: $getCachedUrlKey, mediaType: $mediaType, isContentFile: $isContentFile, isContentVideo: $isContentVideo, isContentImage: $isContentImage}';
  }

  /// Determines the media type (file, image, video) based on MIME type.
  VSupportedFilesType get getMediaType {
    final mimeStr = mimeType;
    if (mimeStr == null) return VSupportedFilesType.file;
    final fileType = mimeStr.split('/').first;
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
