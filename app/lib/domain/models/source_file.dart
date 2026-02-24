class SourceFile {
  final String path;
  final String relativePath;
  final String name;
  final String extension;
  final int size;
  final String encoding;
  final DateTime lastModified;

  SourceFile({
    required this.path,
    required this.relativePath,
    required this.name,
    required this.extension,
    required this.size,
    required this.encoding,
    required this.lastModified,
  });

  String get displaySize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
