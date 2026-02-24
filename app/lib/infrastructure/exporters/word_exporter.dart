import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import '../../domain/models/clean_code.dart';
import '../../domain/models/export_config.dart';
import '../../domain/models/export_result.dart';

class WordExporter {
  final ExportConfig config;

  WordExporter({required this.config});

  Future<ExportResult> export(List<CleanCode> codes, String outputPath) async {
    var currentLineCount = 0;
    final maxLines = config.maxTotalLines;
    final limitedCodes = <CleanCode>[];

    for (final code in codes) {
      if (currentLineCount >= maxLines) {
        break;
      }

      final codeLines = code.cleanedContent.split('\n');
      final remainingLines = maxLines - currentLineCount;
      final linesToAdd = codeLines.length <= remainingLines
          ? code.cleanedContent
          : codeLines.sublist(0, remainingLines).join('\n');

      if (linesToAdd.isEmpty) {
        continue;
      }

      limitedCodes.add(
        CleanCode(
          fileName: code.fileName,
          originalContent: code.originalContent,
          cleanedContent: linesToAdd,
          originalLines: code.originalLines,
          cleanedLines: linesToAdd.split('\n').length,
          removedComments: code.removedComments,
          removedEmptyLines: code.removedEmptyLines,
        ),
      );

      currentLineCount += linesToAdd.split('\n').length;
    }

    final docxBytes = _createDocument(limitedCodes);
    final file = File(outputPath);
    await file.writeAsBytes(docxBytes);

    final totalPages = (currentLineCount / config.linesPerPage).ceil();

    return ExportResult(
      totalPages: totalPages == 0 ? 1 : totalPages,
      totalLines: currentLineCount,
      isTruncated: currentLineCount >= maxLines,
      outputPath: outputPath,
    );
  }

  List<int> _createDocument(List<CleanCode> codes) {
    final archive = Archive();

    _addContentTypes(archive);
    _addRels(archive);
    _addDocumentRels(archive);
    _addSettings(archive);
    _addWebSettings(archive);
    _addHeader(archive);
    _addFooter(archive);
    _addDocument(archive, codes);
    _addStyles(archive);

    final encoder = ZipEncoder();
    return encoder.encode(archive);
  }

  void _addContentTypes(Archive archive) {
    final xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
<Override PartName="/word/header1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml"/>
<Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/>
<Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/>
<Override PartName="/word/webSettings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.webSettings+xml"/>
</Types>''';
    archive.addFile(
      ArchiveFile('[Content_Types].xml', xml.length, utf8.encode(xml)),
    );
  }

  void _addRels(Archive archive) {
    final xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';
    archive.addFile(ArchiveFile('_rels/.rels', xml.length, utf8.encode(xml)));
  }

  void _addDocumentRels(Archive archive) {
    final xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/header" Target="header1.xml"/>
<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer" Target="footer1.xml"/>
<Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/>
<Relationship Id="rId5" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/webSettings" Target="webSettings.xml"/>
</Relationships>''';
    archive.addFile(
      ArchiveFile('word/_rels/document.xml.rels', xml.length, utf8.encode(xml)),
    );
  }

  void _addSettings(Archive archive) {
    final xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:defaultTabStop w:val="720"/>
<w:compat/>
</w:settings>''';
    archive.addFile(
      ArchiveFile('word/settings.xml', xml.length, utf8.encode(xml)),
    );
  }

  void _addWebSettings(Archive archive) {
    final xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:webSettings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:optimizeForBrowser/>
</w:webSettings>''';
    archive.addFile(
      ArchiveFile('word/webSettings.xml', xml.length, utf8.encode(xml)),
    );
  }

  void _addHeader(Archive archive) {
    final title = '${config.softwareName} ${config.version}';
    final xml =
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
<w:p>
<w:pPr>
<w:pStyle w:val="Header"/>
<w:pBdr>
<w:bottom w:val="single" w:sz="6" w:space="1" w:color="000000"/>
</w:pBdr>
<w:tabs>
<w:tab w:val="center" w:pos="4653"/>
<w:tab w:val="right" w:pos="9306"/>
</w:tabs>
</w:pPr>
<w:r>
<w:tab/>
</w:r>
<w:r>
<w:rPr>
<w:b/>
<w:sz w:val="24"/>
</w:rPr>
<w:t>$title</w:t>
</w:r>
<w:r>
<w:tab/>
</w:r>
<w:r>
<w:fldChar w:fldCharType="begin"/>
</w:r>
<w:r>
<w:instrText>PAGE</w:instrText>
</w:r>
<w:r>
<w:fldChar w:fldCharType="separate"/>
</w:r>
<w:r>
<w:t>1</w:t>
</w:r>
<w:r>
<w:fldChar w:fldCharType="end"/>
</w:r>
</w:p>
</w:hdr>''';
    final bytes = utf8.encode(xml);
    archive.addFile(ArchiveFile('word/header1.xml', bytes.length, bytes));
  }

  void _addFooter(Archive archive) {
    final xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:p/>
</w:ftr>''';
    archive.addFile(
      ArchiveFile('word/footer1.xml', xml.length, utf8.encode(xml)),
    );
  }

  void _addDocument(Archive archive, List<CleanCode> codes) {
    final sb = StringBuffer();
    sb.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    sb.writeln(
      '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">',
    );
    sb.writeln('<w:body>');

    for (final code in codes) {
      for (final line in code.cleanedContent.split('\n')) {
        sb.writeln(_makeParagraph(line));
      }
    }

    sb.writeln('<w:sectPr>');
    sb.writeln('<w:pgSz w:w="11906" w:h="16838"/>');
    sb.writeln(
      '<w:pgMar w:top="1440" w:right="1134" w:bottom="1440" w:left="1134" w:header="720" w:footer="720"/>',
    );
    sb.writeln('<w:headerReference w:type="default" r:id="rId2"/>');
    sb.writeln('<w:footerReference w:type="default" r:id="rId3"/>');
    sb.writeln('</w:sectPr>');

    sb.writeln('</w:body>');
    sb.writeln('</w:document>');

    archive.addFile(
      ArchiveFile(
        'word/document.xml',
        utf8.encode(sb.toString()).length,
        utf8.encode(sb.toString()),
      ),
    );
  }

  String _makeParagraph(String text) {
    final processed = text.replaceAll('\t', '  ');
    final esc = processed
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    // 行距288 twips = 14400/50 = 50行/页
    return '<w:p><w:pPr><w:spacing w:line="276" w:lineRule="exact"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii="${config.fontName}" w:hAnsi="${config.fontName}"/><w:sz w:val="20"/></w:rPr><w:t xml:space="preserve">$esc</w:t></w:r></w:p>';
  }

  void _addStyles(Archive archive) {
    final xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:docDefaults>
<w:rPrDefault>
<w:rPr>
<w:rFonts w:ascii="Consolas" w:hAnsi="Consolas"/>
</w:rPr>
</w:rPrDefault>
</w:docDefaults>
<w:style w:type="paragraph" w:styleId="Header">
<w:name w:val="header"/>
<w:basedOn w:val="Normal"/>
<w:pPr>
<w:tabs>
<w:tab w:val="center" w:pos="4680"/>
<w:tab w:val="right" w:pos="9360"/>
</w:tabs>
</w:pPr>
</w:style>
<w:style w:type="paragraph" w:styleId="Normal">
<w:name w:val="Normal"/>
<w:pPr>
<w:spacing w:line="288" w:lineRule="exact"/>
</w:pPr>
</w:style>
</w:styles>''';
    archive.addFile(
      ArchiveFile('word/styles.xml', xml.length, utf8.encode(xml)),
    );
  }
}
