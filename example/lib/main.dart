import 'package:example/ui/home_screen.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MediaPickerApp());

class MediaPickerApp extends StatelessWidget {
  const MediaPickerApp({super.key, this.home = const HomeScreen()});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Picker App',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: home,
    );
  }
}
