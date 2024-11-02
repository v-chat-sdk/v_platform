import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:v_platform/v_platform.dart';
import '../utils/file_picker_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<VPlatformFile> pickedFiles = [];

  void _pickFiles() async {
    List<VPlatformFile> files = await FilePickerHelper.pickFiles();
    if (files.isNotEmpty) {
      setState(() {
        pickedFiles.addAll(files);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Picker'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _pickFiles,
            child: const Text('Pick Files'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: pickedFiles.length,
              itemBuilder: (context, index) {
                final current = pickedFiles[index];
                return ListTile(
                  leading: (current.isContentImage && current.isFromBytes)
                      ? Image.memory(
                          current.uint8List,
                        )
                      : null,
                  title: Text(pickedFiles[index].name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text('name: ${pickedFiles[index].mediaType.name}'),
                      Text('extension: ${pickedFiles[index].extension}'),
                      Text(pickedFiles[index].toString()),
                    ],
                  ),
                  trailing: kIsWeb
                      ? InkWell(
                          onTap: () {
                            pickedFiles[index] =
                                VPlatformFile.fromMap(current.toMap());
                            setState(() {});
                          },
                          child: const Icon(Icons.swap_calls),
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
