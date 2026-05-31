import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class FullScreenImageViewer extends StatelessWidget {
  final File file;
  final String title;

  const FullScreenImageViewer({
    super.key,
    required this.file,
    this.title = '',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              Share.shareXFiles([XFile(file.path)], text: title);
            },
            tooltip: 'Share or Save',
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 5.0,
          child: Image.file(
            file,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
}
