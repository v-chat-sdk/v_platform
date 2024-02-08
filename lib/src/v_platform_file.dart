// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:file_sizes/file_sizes.dart';
import 'package:meta/meta.dart';
import 'package:mime_type/mime_type.dart';
import 'package:path/path.dart';
import 'package:path/path.dart' as p;

import 'enums.dart';

/// `VPlatformFileSource` is a class that helps to handle files in different ways.
///
/// It accepts a file from different sources, such as a user URL, a file path, or bytes,
/// and provides various utility methods for handling these files.
///
/// This class requires some fields to be initialized:
/// * [name]: Name of the file
/// * [fileSize]: Size of the file
///
/// Optional fields include:
/// * [userUrl]: URL for the file if it comes from a web source
/// * [filePath]: Path for the file if it is stored locally
/// * [bytes]: Byte data for the file if it comes as byte array
/// * [baseUrl]: Base URL if the file is from a web source that requires a base URL
/// * [mimeType]: Mime type of the file
///
/// You can use one of the following constructors based on the source of the file:
/// * [VPlatformFileSource.fromBytes]: If you have a file in the form of bytes
/// * [VPlatformFileSource.fromPath]: If you have a file path
/// * [VPlatformFileSource.fromUrl]: If you have a file URL
/// * [VPlatformFileSource.fromAssets]: If you have a file in assets
///
/// This class also provides utility getters and methods like:
/// * [getMimeType]: To get the mime type of the file
/// * [isFromPath]: To check if the file comes from a path
/// * [isFromAssets]: To check if the file comes from assets
/// * [isFromBytes]: To check if the file comes from bytes
/// * [isFromUrl]: To check if the file comes from a URL
/// * [isNotUrl]: To check if the file does not come from a URL
/// * [readableSize]: To get the file size in a human-readable string
/// * [getBytes]: To get the bytes of the file
/// * [uint8List]: To get the Uint8List of the file bytes
/// * [toMap]: To get the map representation of the file
/// * [toString]: To get the string representation of the file

class VPlatformFile {
  String name;
  String fileHash;
  String? assetsPath;
  String? fileLocalPath;
  List<int>? bytes;
  String? mimeType;
  int fileSize;
  @internal
  String? baseUrl;
  String? urlPath;
  late VSupportedFilesType mediaType;
  late bool isContentFile;
  late bool isContentVideo;
  late bool isContentImage;

  VPlatformFile._({
    required this.name,
    this.fileLocalPath,
    this.bytes,
    required this.fileHash,
    this.baseUrl,
    required this.fileSize,
    this.mimeType,
  }) {
    urlPath = getUrlPath;
    mediaType = getMediaType;
    isContentFile = mediaType == VSupportedFilesType.file;
    isContentVideo = mediaType == VSupportedFilesType.video;
    isContentImage = mediaType == VSupportedFilesType.image;
  }

  String? get url {
    if (baseUrl == null) return null;
    if (VPlatformFileUtils.baseMediaUrl == null) return baseUrl;
    return VPlatformFileUtils.baseMediaUrl! + baseUrl!;
  }

  String? get getMimeType => mime(name);

  bool get isFromPath => fileLocalPath != null;

  bool get isFromAssets => assetsPath != null;

  bool get isFromBytes => bytes != null;

  String get extension {
    return p.extension(name);
  }

  bool get isFromUrl => url != null;

  bool get isNotUrl => isFromBytes || isFromPath;

  String get readableSize => FileSize.getSize(fileSize);

  ///this used for cache key
  String get getUrlPath {
    if (url == null) {
      return name;
    }
    final uri = Uri.parse(url!);
    return "${uri.scheme}://${uri.host}${uri.path}";
  }

  List<int> get getBytes {
    if (bytes != null) {
      return bytes!;
    }
    if (fileLocalPath != null) {
      return File(fileLocalPath!).readAsBytesSync().toList();
    }
    return [];
  }

  Uint8List get uint8List {
    return Uint8List.fromList(getBytes);
  }

  VPlatformFile.fromBytes({
    required this.name,
    required List<int> this.bytes,
  })  : fileSize = bytes.length,
        fileHash = sha256.convert(bytes).toString() {
    _initialize();
  }

  VPlatformFile.fromPath({
    required String this.fileLocalPath,
  })  : fileSize = File(fileLocalPath).lengthSync(),
        name = basename(fileLocalPath),
        fileHash =
            sha256.convert(File(fileLocalPath).readAsBytesSync()).toString() {
    _initialize();
  }

  VPlatformFile.fromUrl({
    this.fileSize = 0,
    required String url,
    this.baseUrl,
  })  : name = basename(url),
        fileHash = basenameWithoutExtension(url).replaceAll(" ", "-") {
    baseUrl = url;
    _initialize();
  }

  VPlatformFile.fromAssets({
    this.fileSize = 0,
    required String this.assetsPath,
  })  : name = basename(assetsPath),
        fileHash = basenameWithoutExtension(assetsPath).replaceAll(" ", "-") {
    _initialize();
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'url': baseUrl,
      'filePath': fileLocalPath,
      'assetsPath': assetsPath,
      'bytes': bytes,
      'mimeType': getMimeType,
      'fileSize': fileSize,
      'fileHash': fileHash,
    };
  }

  @override
  String toString() {
    return 'PlatformFileSource{name: $name, url:$url _baseUrl:$baseUrl filePath: $fileLocalPath, mimeType: $mimeType, assetsPath: $assetsPath, size: $fileSize bytes ${bytes?.length}';
  }

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

  factory VPlatformFile.fromMap(Map<String, dynamic> map) {
    final filePath = map['filePath'] as String?;
    final bytes = map['bytes'] as List?;
    final url = map['url'] as String?;

    if (filePath == null && bytes == null && url == null) {
      throw ArgumentError(
          "PlatformFileSource.fromMap: at least filePath or bytes or url must not be null. Map: $map");
    }

    return VPlatformFile._(
      name: map['name'],
      fileLocalPath: filePath,
      baseUrl: url,
      bytes: bytes?.map((e) => int.parse(e.toString(),radix: 10)).toList(),
      mimeType: map['mimeType'],
      fileSize: map['fileSize'] ?? 0,
      fileHash: (map['fileHash'] as String?) ??
          basenameWithoutExtension(map['name'] as String).replaceAll(" ", "-"),
    );
  }

  void _initialize() {
    mimeType = getMimeType;
    urlPath = getUrlPath;
    mediaType = getMediaType;
    isContentFile = mediaType == VSupportedFilesType.file;
    isContentVideo = mediaType == VSupportedFilesType.video;
    isContentImage = mediaType == VSupportedFilesType.image;
  }
}

///used to set global base url to all [url]
abstract class VPlatformFileUtils {
  ///the shared value you can set it any where
  static String? baseMediaUrl;
}
