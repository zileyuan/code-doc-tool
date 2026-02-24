class ExportResult {
  final int totalPages;
  final int totalLines;
  final bool isTruncated;
  final String? outputPath;

  ExportResult({
    required this.totalPages,
    required this.totalLines,
    required this.isTruncated,
    this.outputPath,
  });

  String get summary {
    if (isTruncated) {
      return '文档已达到最大页数限制，生成 $totalPages 页（$totalLines 行）';
    } else {
      return '文档生成成功，共 $totalPages 页（$totalLines 行）';
    }
  }
}
