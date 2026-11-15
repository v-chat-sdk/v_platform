# v_platform

`v_platform` provides one serializable model for files that come from local
paths, browser bytes, Flutter assets, or network URLs. It also includes MIME
classification, stable cache identifiers, platform detection, and multipart
upload helpers.

## Requirements

- Dart 3.13 or newer
- Flutter 3.47 or newer
- Android, iOS, Linux, macOS, web/WASM, and Windows

## Installation

```yaml
dependencies:
  v_platform: ^3.0.0
```

```dart
import 'package:v_platform/v_platform.dart';
```

## Create files

Use the constructor that matches the source available on the current platform:

```dart
final local = VPlatformFile.fromPath(
  fileLocalPath: '/tmp/avatar.png',
);

final browserFile = VPlatformFile.fromBytes(
  name: 'avatar.png',
  bytes: uploadedBytes,
);

final asset = VPlatformFile.fromAssets(
  assetsPath: 'assets/avatar.png',
  fileSize: 2048,
);

final remote = VPlatformFile.fromUrl(
  networkUrl: '/media/avatar.png?token=temporary',
);
```

Local paths are available only on platforms with `dart:io`. For web and WASM,
pass the bytes returned by the browser or file-picker API.

Every instance exposes `name`, `fileSize`, `readableSize`, `mimeType`,
`extension`, `fileHash`, and source flags such as `isFromBytes`. MIME-derived
flags include `isContentImage`, `isContentVideo`, and `isContentFile`.

## Resolve relative media URLs

Configure a base once, then read `fullNetworkUrl`:

```dart
VPlatformFileUtils.baseMediaUrl = 'https://cdn.example.com/media';

final file = VPlatformFile.fromUrl(networkUrl: 'images/photo.jpg');
print(file.fullNetworkUrl);
// https://cdn.example.com/media/images/photo.jpg
```

Absolute URLs remain unchanged. `getCachedUrlKey` is a deterministic SHA-256
identifier that omits query strings and fragments, so temporary access tokens
do not create duplicate cache entries.

## Serialize and upload

`toMap()` preserves all supported sources. `fromMap()` prefers `preSignedUrl`
over `networkUrl`, accepts the legacy `url` key, and accepts byte lists in
addition to Base64 strings.

```dart
final stored = file.toMap();
final restored = VPlatformFile.fromMap(stored);

final multipart = await VPlatforms.getMultipartFile(
  source: browserFile,
  fieldName: 'attachment',
);
```

Multipart conversion requires in-memory bytes or a local path. Resolve network
and asset sources to bytes before uploading them.

## Platform helpers

`VPlatforms.currentOs` distinguishes native targets, web, and WASM.
`VPlatforms.osInWeb` reports the browser host platform, while
`VPlatforms.isWebRunOnMobile` identifies Android and iOS browsers.

Run the interactive sample with:

```bash
cd example
flutter run -d chrome
```

The example app targets iOS 14 and macOS 10.15 or newer, matching the current
`file_picker` Darwin implementation.
