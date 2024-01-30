import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:fllama/fllama.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? modelPath;
  String latestResult = '';
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 14);
    const spacerSmall = SizedBox(height: 10);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('fllama'),
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton.icon(
                  onPressed: _openGgufPressed,
                  icon: const Icon(Icons.file_open),
                  label: const Text('Open .gguf'),
                ),
                if (modelPath != null)
                  SelectableText(
                    'Model path: $modelPath',
                    style: textStyle,
                  ),
                spacerSmall,
                if (modelPath != null)
                  TextField(
                    controller: _controller,
                  ),
                const SizedBox(
                  height: 8,
                ),
                ElevatedButton(
                  onPressed: () async {
                    final request = OpenAiRequest(
                      maxTokens: 256,
                      messages: [
                        Message(Role.user, _controller.text),
                      ],
                      numGpuLayers: 99,
                      modelPath: modelPath!,
          
                    );
                    fllamaChatCompletionAsync(request, (String result, bool done) {
                      setState(() {
                        latestResult = result;
                      });
                    });
                  },
                  child: const Text('Run inference'),
                ),
                SelectableText(
                  latestResult,
                  style: textStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openGgufPressed() async {
    XTypeGroup ggufTypeGroup = const XTypeGroup(
      label: '.gguf',
      extensions: ['gguf'],
      // UTIs are required for iOS, which does not support local LLMs.
      uniformTypeIdentifiers: [],
    );
    if (!kIsWeb && Platform.isAndroid) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      final file = result?.files.first;
      if (file == null) {
        return;
      }
      final filePath = file.path;
      setState(() {
        modelPath = filePath;
      });
    } else {
    final file = await openFile(acceptedTypeGroups: <XTypeGroup>[
      if (!Platform.isIOS) ggufTypeGroup,
    ]);


    if (file == null) {
      return;
    }
    final filePath = file.path;
    setState(() {
      modelPath = filePath;
    });
    }

  }
}
