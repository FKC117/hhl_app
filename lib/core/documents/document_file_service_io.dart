import 'dart:io';

import 'package:path_provider/path_provider.dart';

class DocumentFileService {
  Future<StoredDocument> saveBytes({
    required List<int> bytes,
    required String fileName,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final safeName = fileName.replaceAll(RegExp(r'[^\w\.\-]+'), '_');
    final file = File('${directory.path}\\$safeName');
    await file.writeAsBytes(bytes, flush: true);
    return StoredDocument(fileName: safeName, savedPath: file.path);
  }
}

class StoredDocument {
  const StoredDocument({required this.fileName, required this.savedPath});

  final String fileName;
  final String savedPath;
}
