class ExportConfig {
  final String softwareName;
  final String version;
  final int linesPerPage;
  final int maxPages;
  final String fontName;
  final int fontSize;
  final bool showLineNumber;
  final bool showFileName;

  ExportConfig({
    required this.softwareName,
    required this.version,
    this.linesPerPage = 50,
    this.maxPages = 60,
    this.fontName = 'Consolas',
    this.fontSize = 10,
    this.showLineNumber = false,
    this.showFileName = true,
  });

  int get maxTotalLines => maxPages * linesPerPage;

  ExportConfig copyWith({
    String? softwareName,
    String? version,
    int? linesPerPage,
    int? maxPages,
    String? fontName,
    int? fontSize,
    bool? showLineNumber,
    bool? showFileName,
  }) {
    return ExportConfig(
      softwareName: softwareName ?? this.softwareName,
      version: version ?? this.version,
      linesPerPage: linesPerPage ?? this.linesPerPage,
      maxPages: maxPages ?? this.maxPages,
      fontName: fontName ?? this.fontName,
      fontSize: fontSize ?? this.fontSize,
      showLineNumber: showLineNumber ?? this.showLineNumber,
      showFileName: showFileName ?? this.showFileName,
    );
  }
}
