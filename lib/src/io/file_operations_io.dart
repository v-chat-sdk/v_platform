import 'dart:io';

int lengthSync(String path) => File(path).lengthSync();

int lastModifiedMillisecondsSync(String path) =>
    File(path).lastModifiedSync().millisecondsSinceEpoch;

List<int> readAsBytesSync(String path) => File(path).readAsBytesSync();
