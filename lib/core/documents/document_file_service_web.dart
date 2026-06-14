import 'dart:html' as html;
import 'dart:typed_data';

class DocumentFileService {
  Future<StoredDocument> saveBytes({
    required List<int> bytes,
    required String fileName,
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^\w\.\-]+'), '_');
    final blob = html.Blob(
      [Uint8List.fromList(bytes)],
      'application/pdf',
    );
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = safeName
      ..style.display = 'none';

    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);

    return StoredDocument(
      fileName: safeName,
      savedPath: 'Browser download started',
    );
  }
}

class StoredDocument {
  const StoredDocument({required this.fileName, required this.savedPath});

  final String fileName;
  final String savedPath;
}
