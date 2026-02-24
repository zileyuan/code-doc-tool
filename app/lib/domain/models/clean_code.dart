class CleanCode {
  final String fileName;
  final String originalContent;
  final String cleanedContent;
  final int originalLines;
  final int cleanedLines;
  final int removedComments;
  final int removedEmptyLines;

  CleanCode({
    required this.fileName,
    required this.originalContent,
    required this.cleanedContent,
    required this.originalLines,
    required this.cleanedLines,
    required this.removedComments,
    required this.removedEmptyLines,
  });

  double get compressionRatio => cleanedContent.length / originalContent.length;

  int get savedLines => originalLines - cleanedLines;
}
