class DocumentItem {
  const DocumentItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.sourceName,
    required this.downloadPath,
  });

  final int id;
  final String title;
  final String subtitle;
  final String status;
  final String sourceName;
  final String downloadPath;
}
