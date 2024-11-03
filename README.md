# VPlatformFile

`VPlatformFile` is a flexible Dart package that helps manage files from various sources, including local paths, byte arrays, URLs, and asset files. This package provides utility methods for handling file metadata, MIME types, media types, and file size information in a straightforward and efficient way.

## Features

- **File Handling from Multiple Sources**: Supports files from local paths, URLs, assets, and byte arrays.
- **File Metadata Access**: Easily retrieve file properties such as name, MIME type, file size, and extension.
- **Hash Generation**: Unique hash generation based on file attributes to help with caching and unique identification.
- **Media Type Detection**: Automatically detects if a file is an image, video, or other file type.
- **Human-Readable File Size**: Provides file size in a human-readable format (e.g., KB, MB).
- **Serialization Support**: Convert files to and from `Map` objects for easy storage and transfer.

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  v_platform_file: ^1.0.0
```

Then, install the package by running:

```bash
flutter pub get
```

## Usage

### Importing the Package

```dart
import 'package:v_platform_file/v_platform_file.dart';
```

### Creating a `VPlatformFile` Instance

You can create a `VPlatformFile` instance using one of the following constructors based on your file source:

#### From Local Path

Create a file instance from a local path. This constructor automatically reads the file size and computes a unique hash.

```dart
final file = VPlatformFile.fromPath(fileLocalPath: '/path/to/your/file.jpg');
print(file.name); // Output: file.jpg
print(file.fileSize); // Output: size in bytes
```

#### From URL

Create a file instance from a URL. The file name and hash are derived from the URL.

```dart
final file = VPlatformFile.fromUrl(networkUrl: 'https://example.com/file.jpg');
print(file.name); // Output: file.jpg
print(file.networkUrl);  // Output: Full URL
```

#### From Byte Array

Create a file instance from a byte array. The file size and hash are generated based on the byte content.

```dart
final file = VPlatformFile.fromBytes(name: 'myfile.png', bytes: [/* file bytes */]);
print(file.name); // Output: myfile.png
print(file.fileSize); // Output: byte array size
```

#### From Assets

Create a file instance from an asset file.

```dart
final file = VPlatformFile.fromAssets(assetsPath: 'assets/myfile.png');
print(file.name); // Output: myfile.png
print(file.isFromAssets); // Output: true
```

### Accessing File Properties

The `VPlatformFile` class provides several useful properties:

- **File Name**: `file.name`
- **File Size**: `file.fileSize` (in bytes)
- **MIME Type**: `file.mimeType`
- **File Extension**: `file.extension`
- **Is From Path**: `file.isFromPath`
- **Is From Bytes**: `file.isFromBytes`
- **Is From URL**: `file.isFromUrl`
- **Readable File Size**: `file.readableSize` (e.g., "10 MB")
- **File Hash**: `file.fileHash`

### Checking Media Type

The `mediaType` property allows you to identify if the file is an image, video, or a generic file type:

```dart
if (file.isContentImage) {
  print("This file is an image.");
} else if (file.isContentVideo) {
  print("This file is a video.");
} else {
  print("This is a general file.");
}
```

### Converting to and from Map

`VPlatformFile` supports conversion to and from a `Map` for easy serialization, making it suitable for caching or database storage.

#### Convert to Map

```dart
final fileMap = file.toMap();
print(fileMap);
```

#### Convert from Map

```dart
final fileFromMap = VPlatformFile.fromMap(fileMap);
print(fileFromMap.name);
```

### Example

Here’s a complete example that demonstrates creating a `VPlatformFile` instance from a local path, accessing its properties, and converting it to and from a `Map`.

```dart
import 'package:v_platform_file/v_platform_file.dart';

void main() {
  // Create a VPlatformFile from a local path
  final file = VPlatformFile.fromPath(fileLocalPath: '/path/to/file.jpg');
  
  // Access properties
  print("File Name: \${file.name}");
  print("File Size: \${file.readableSize}");
  print("MIME Type: \${file.mimeType}");
  
  // Check if it is an image or video
  if (file.isContentImage) {
    print("This is an image file.");
  }
  
  // Convert to Map
  final fileMap = file.toMap();
  print("File as Map: \$fileMap");
  
  // Convert back from Map
  final fileFromMap = VPlatformFile.fromMap(fileMap);
  print("File Name from Map: \${fileFromMap.name}");
}
```

## Setting Global Base URL

You can set a global base URL for all files with a URL source using `VPlatformFileUtils.baseMediaUrl`. This is helpful when you need a common URL prefix.

```dart
VPlatformFileUtils.baseMediaUrl = "https://yourmediaurl.com/";
```

## Contributing

Contributions are welcome! If you have suggestions or find any issues, please feel free to open an issue or submit a pull request on GitHub.

## License

This package is released under the MIT License. See the [LICENSE](./LICENSE) file for details.
