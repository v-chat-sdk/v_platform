import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:v_platform/v_platform.dart';

import '../utils/file_picker_helper.dart';

typedef PickFiles = Future<List<VPlatformFile>> Function();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.pickFiles = FilePickerHelper.pickFiles});

  final PickFiles pickFiles;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<VPlatformFile> _pickedFiles = <VPlatformFile>[];
  bool _isPicking = false;
  String? _errorMessage;

  Future<void> _pickFiles() async {
    setState(() {
      _isPicking = true;
      _errorMessage = null;
    });

    try {
      final files = await widget.pickFiles();
      if (!mounted) return;
      setState(() {
        _pickedFiles.addAll(files);
        _isPicking = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not pick files: $error';
        _isPicking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Media Picker')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: _isPicking ? null : _pickFiles,
              icon: _isPicking
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.attach_file),
              label: Text(_isPicking ? 'Picking…' : 'Pick files'),
            ),
          ),
          if (_errorMessage case final error?)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: _pickedFiles.isEmpty
                ? const Center(child: Text('No files selected.'))
                : ListView.builder(
                    itemCount: _pickedFiles.length,
                    itemBuilder: (context, index) {
                      final current = _pickedFiles[index];
                      return ListTile(
                        leading: current.isContentImage && current.isFromBytes
                            ? Image.memory(
                                current.uint8List,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image_outlined),
                              )
                            : const Icon(Icons.insert_drive_file_outlined),
                        title: Text(current.name),
                        subtitle: Text(
                          '${current.mediaType.name} • '
                          '${current.extension.isEmpty ? 'no extension' : current.extension} '
                          '• ${current.readableSize}',
                        ),
                        trailing: kIsWeb
                            ? IconButton(
                                tooltip: 'Test serialization',
                                onPressed: () {
                                  setState(() {
                                    _pickedFiles[index] = VPlatformFile.fromMap(
                                      current.toMap(),
                                    );
                                  });
                                },
                                icon: const Icon(Icons.swap_calls),
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
