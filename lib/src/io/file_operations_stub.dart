Never _unsupported() {
  throw UnsupportedError(
    'Local file paths are not available on this platform.',
  );
}

int lengthSync(String path) => _unsupported();

int lastModifiedMillisecondsSync(String path) => _unsupported();

List<int> readAsBytesSync(String path) => _unsupported();
