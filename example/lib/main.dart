import 'package:example/ui/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:v_platform/v_platform.dart';

void main() {
  VPlatformFileUtils.baseMediaUrl = "xxx";
  final x = VPlatformFile.fromUrl(
    networkUrl: "https://dl.espressif.com/dl/audio/ff-16b-2c-44100hz.mp3",
  );
  print(x.fullNetworkUrl!);

  runApp(const MediaPickerApp());
}

class MediaPickerApp extends StatelessWidget {
  const MediaPickerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Picker App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}
