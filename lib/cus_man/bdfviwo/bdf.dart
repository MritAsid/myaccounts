import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';

class PDFViewerScreen extends StatelessWidget {
  final String filePath;

  const PDFViewerScreen({Key? key, required this.filePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.cyan,
          title: const Text(
            'عرض كشف عميل',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22.0,
                color: Colors.white),
          ),
          leading: IconButton(
              // icon: const Icon(Icons.assignment_return_outlined,
              icon: const Icon(Icons.read_more_rounded,
                  size: 35, color: Colors.white),
              // icon: const Icon(Icons.returni , size: 35, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              }),
          actions: [
            IconButton(
              icon: const Icon(Icons.share, size: 30, color: Colors.white),
              onPressed: () async {
                // ignore: deprecated_member_use
                await Share.shareFiles([filePath], text: 'تقرير العمليات');
              },
            ),
            const SizedBox(width: 14),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(10.0),
          child: SfPdfViewer.file(
            File(filePath),
          ),
        ),
      ),
    );
  }
}
