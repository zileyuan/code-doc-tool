# Word 导出模块设计文档

## 1. 模块概述

### 1.1 核心职责
将清洗后的源代码按照指定格式导出为 Word 文档，符合软著申请的文档规范。

### 1.2 设计原则
- **标准格式**: 符合 OOXML 标准
- **精确排版**: 严格控制每页行数
- **美观易读**: 等宽字体、合理间距
- **兼容性好**: 支持 Word 2007+ 打开

## 2. 类设计

### 2.1 核心类图
```
┌─────────────────┐
│  WordExporter   │
├─────────────────┤
│ - config: ExportConfig │
│ - template: WordTemplate │
├─────────────────┤
│ + export(codes: List<CleanCode>): Future<void> │
│ - _createDocument(): Document │
│ - _addSection(code: CleanCode): void │
│ - _setHeader(doc: Document): void │
│ - _paginate(lines: List<String>): List<List<String>> │
└─────────────────┘
         │
         ├─── uses ───▶ ┌──────────────────┐
         │              │ ExportConfig     │
         │              ├──────────────────┤
         │              │ - softwareName: String │
         │              │ - version: String │
         │              │ - linesPerPage: int │
         │              │ - fontSize: int │
         │              └──────────────────┘
         │
         └─── uses ───▶ ┌──────────────────┐
                        │ PageLayout       │
                        ├──────────────────┤
                        │ - pageSize: PageSize │
                        │ - margins: Margins │
                        │ - lineSpacing: double │
                        └──────────────────┘
```

### 2.2 数据模型

#### ExportConfig
```dart
class ExportConfig {
  final String softwareName;        // 软件名称
  final String version;             // 版本号
  final int linesPerPage;           // 每页行数
  final int maxPages;               // 最大页数限制（默认60页）
  final String fontName;            // 字体名称
  final int fontSize;               // 字体大小（磅）
  final bool showLineNumber;        // 是否显示行号
  final bool showFileName;          // 是否显示文件名
  
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
  
  // 计算最大允许的总行数
  int get maxTotalLines => maxPages * linesPerPage;
}
```

#### PageLayout
```dart
class PageLayout {
  final double width;               // 页面宽度（磅）
  final double height;              // 页面高度（磅）
  final double marginTop;           // 上边距
  final double marginBottom;        // 下边距
  final double marginLeft;          // 左边距
  final double marginRight;         // 右边距
  final double lineSpacing;         // 行间距
  
  static PageLayout a4() {
    return PageLayout(
      width: 595.0,     // A4 宽度
      height: 842.0,    // A4 高度
      marginTop: 72.0,  // 1 英寸
      marginBottom: 72.0,
      marginLeft: 72.0,
      marginRight: 72.0,
      lineSpacing: 1.0,
    );
  }
}
```

## 3. Word 文档结构

### 3.1 文档结构树
```
Document
├── Sections[0]
│   ├── Header
│   │   ├── Paragraph (软件名称 + 版本)
│   │   └── Paragraph (页码)
│   ├── Body
│   │   ├── Paragraph (文件名标题)
│   │   ├── Paragraph (代码行 1)
│   │   ├── Paragraph (代码行 2)
│   │   └── ...
│   └── Footer
├── Sections[1]
│   ├── Header
│   └── Body
└── ...
```

### 3.2 页眉设计
```
┌──────────────────────────────────────────────────┐
│                                                  │
│          XXX软件 V1.0.0                  第1页   │
│──────────────────────────────────────────────────│
│                                                  │
│                  （正文内容）                     │
│                                                  │
└──────────────────────────────────────────────────┘
```

## 4. 核心实现

### 4.1 WordExporter 实现
```dart
class WordExporter {
  final ExportConfig config;
  final PageLayout layout;
  
  WordExporter({
    required this.config,
    PageLayout? layout,
  }) : layout = layout ?? PageLayout.a4();
  
  Future<ExportResult> export(
    List<CleanCode> codes,
    String outputPath,
  ) async {
    final doc = await _createDocument();
    var currentPageCount = 0;
    var currentLineCount = 0;
    final maxLines = config.maxTotalLines;
    
    for (final code in codes) {
      final codeLines = code.cleanedContent.split('\n');
      
      // 检查是否已达到最大行数限制
      if (currentLineCount >= maxLines) {
        break;
      }
      
      // 计算当前文件可添加的行数
      final remainingLines = maxLines - currentLineCount;
      final linesToAdd = codeLines.length <= remainingLines 
          ? codeLines 
          : codeLines.sublist(0, remainingLines);
      
      if (linesToAdd.isEmpty) {
        continue;
      }
      
      await _addCodeSection(doc, code, linesToAdd);
      currentLineCount += linesToAdd.length;
    }
    
    await _saveDocument(doc, outputPath);
    
    return ExportResult(
      totalPages: (currentLineCount / config.linesPerPage).ceil(),
      totalLines: currentLineCount,
      isTruncated: currentLineCount >= maxLines,
    );
  }
  
  Future<Document> _createDocument() async {
    final doc = Document();
    
    // 设置页面属性
    doc.sections.first.page = Page(
      width: layout.width,
      height: layout.height,
      margin: Margin(
        top: layout.marginTop,
        bottom: layout.marginBottom,
        left: layout.marginLeft,
        right: layout.marginRight,
      ),
    );
    
    // 设置页眉
    _setupHeader(doc);
    
    return doc;
  }
  
  void _setupHeader(Document doc) {
    final header = doc.sections.first.header;
    
    // 软件名称和版本（居中）
    final titleParagraph = header.addParagraph();
    titleParagraph.alignment = Alignment.center;
    titleParagraph.addText(
      '${config.softwareName} V${config.version}',
      style: TextStyle(
        fontName: '宋体',
        fontSize: 12,
        bold: true,
      ),
    );
    
    // 页码（右对齐）
    final pageParagraph = header.addParagraph();
    pageParagraph.alignment = Alignment.right;
    pageParagraph.addText(
      '第 PAGE 页',  // Word 会自动替换
      style: TextStyle(
        fontName: '宋体',
        fontSize: 10,
      ),
    );
  }
  
  Future<void> _addCodeSection(
    Document doc, 
    CleanCode code,
    List<String> linesToAdd,
  ) async {
    // 添加文件名标题
    if (config.showFileName) {
      final titleParagraph = doc.addParagraph();
      titleParagraph.addText(
        '文件: ${code.fileName}',
        style: TextStyle(
          fontName: '宋体',
          fontSize: 11,
          bold: true,
        ),
      );
      titleParagraph.paragraphFormat.spaceAfter = 12.0;
    }
    
    // 分页并添加代码
    final pages = _paginate(linesToAdd);
    
    for (var i = 0; i < pages.length; i++) {
      if (i > 0) {
        // 插入分页符
        doc.addPageBreak();
      }
      
      // 添加代码行
      for (final line in pages[i]) {
        _addCodeLine(doc, line);
      }
    }
  }
  
  void _addCodeLine(Document doc, String line) {
    final paragraph = doc.addParagraph();
    
    // 添加行号（可选）
    if (config.showLineNumber) {
      paragraph.addText(
        '${_lineNumber++}  ',
        style: TextStyle(
          fontName: config.fontName,
          fontSize: config.fontSize,
          color: '808080',
        ),
      );
    }
    
    // 添加代码内容
    paragraph.addText(
      line,
      style: TextStyle(
        fontName: config.fontName,
        fontSize: config.fontSize,
      ),
    );
    
    // 设置行间距
    paragraph.paragraphFormat.lineSpacing = layout.lineSpacing;
    paragraph.paragraphFormat.spaceAfter = 0.0;
    paragraph.paragraphFormat.spaceBefore = 0.0;
  }
  
  List<List<String>> _paginate(List<String> lines) {
    final pages = <List<String>>[];
    
    for (var i = 0; i < lines.length; i += config.linesPerPage) {
      final end = min(i + config.linesPerPage, lines.length);
      pages.add(lines.sublist(i, end));
    }
    
    return pages;
  }
  
  Future<void> _saveDocument(Document doc, String path) async {
    final bytes = await doc.save();
    final file = File(path);
    await file.writeAsBytes(bytes);
  }
}

// 导出结果
class ExportResult {
  final int totalPages;      // 实际生成的总页数
  final int totalLines;      // 实际生成的总行数
  final bool isTruncated;    // 是否因达到最大页数而截断
  
  ExportResult({
    required this.totalPages,
    required this.totalLines,
    required this.isTruncated,
  });
}
```

## 5. 排版控制

### 5.1 行高计算
```dart
class LineHeightCalculator {
  final int fontSize;         // 字体大小（磅）
  final double lineSpacing;   // 行间距倍数
  
  LineHeightCalculator({
    required this.fontSize,
    this.lineSpacing = 1.0,
  });
  
  double calculate() {
    // 标准行高 = 字体大小 * 1.2
    final standardLineHeight = fontSize * 1.2;
    return standardLineHeight * lineSpacing;
  }
  
  double calculateLinesPerPage(double pageHeight, double marginTop, double marginBottom) {
    final availableHeight = pageHeight - marginTop - marginBottom;
    final lineHeight = calculate();
    return (availableHeight / lineHeight).floor();
  }
}
```

### 5.2 精确分页算法
```dart
class PrecisePaginator {
  final int targetLinesPerPage;
  final double pageHeight;
  final double marginTop;
  final double marginBottom;
  final double headerHeight;
  
  PrecisePaginator({
    required this.targetLinesPerPage,
    required this.pageHeight,
    required this.marginTop,
    required this.marginBottom,
    this.headerHeight = 36.0,
  });
  
  List<List<String>> paginate(List<String> lines) {
    final pages = <List<String>>[];
    final availableHeight = pageHeight - marginTop - marginBottom - headerHeight;
    
    // 根据目标行数计算实际可容纳的行数
    final actualLinesPerPage = _calculateActualLinesPerPage(availableHeight);
    
    for (var i = 0; i < lines.length; i += actualLinesPerPage) {
      final end = min(i + actualLinesPerPage, lines.length);
      pages.add(lines.sublist(i, end));
    }
    
    return pages;
  }
  
  int _calculateActualLinesPerPage(double availableHeight) {
    // 根据实际测量调整
    // 这里需要根据字体和行距精确计算
    return targetLinesPerPage;
  }
}
```

### 5.3 页数限制实现
```dart
class PageLimiter {
  final int maxPages;
  final int linesPerPage;
  
  PageLimiter({
    required this.maxPages,
    required this.linesPerPage,
  });
  
  // 计算最大允许的总行数
  int get maxTotalLines => maxPages * linesPerPage;
  
  // 限制代码行数
  LimitedCode limitCodeLines(List<CleanCode> codes) {
    final limitedCodes = <CleanCode>[];
    var currentLineCount = 0;
    var isTruncated = false;
    
    for (final code in codes) {
      final codeLines = code.cleanedContent.split('\n');
      
      // 检查是否已达到最大行数限制
      if (currentLineCount >= maxTotalLines) {
        isTruncated = true;
        break;
      }
      
      // 计算当前文件可添加的行数
      final remainingLines = maxTotalLines - currentLineCount;
      
      if (codeLines.length <= remainingLines) {
        // 可以添加整个文件
        limitedCodes.add(code);
        currentLineCount += codeLines.length;
      } else {
        // 只能添加部分行
        final truncatedContent = codeLines
            .sublist(0, remainingLines)
            .join('\n');
        
        limitedCodes.add(CleanCode(
          fileName: code.fileName,
          originalContent: code.originalContent,
          cleanedContent: truncatedContent,
          originalLines: code.originalLines,
          cleanedLines: remainingLines,
          removedComments: code.removedComments,
          removedEmptyLines: code.removedEmptyLines,
        ));
        
        currentLineCount = maxTotalLines;
        isTruncated = true;
        break;
      }
    }
    
    return LimitedCode(
      codes: limitedCodes,
      totalLines: currentLineCount,
      totalPages: (currentLineCount / linesPerPage).ceil(),
      isTruncated: isTruncated,
    );
  }
  
  // 预估导出页数（不实际导出）
  int estimatePages(List<CleanCode> codes) {
    var totalLines = 0;
    
    for (final code in codes) {
      totalLines += code.cleanedContent.split('\n').length;
    }
    
    // 返回实际页数和最大页数中的较小值
    final actualPages = (totalLines / linesPerPage).ceil();
    return min(actualPages, maxPages);
  }
}

// 限制后的代码结果
class LimitedCode {
  final List<CleanCode> codes;
  final int totalLines;
  final int totalPages;
  final bool isTruncated;
  
  LimitedCode({
    required this.codes,
    required this.totalLines,
    required this.totalPages,
    required this.isTruncated,
  });
}
```

**实现说明**：

1. **最大页数默认值**: 60页
2. **计算逻辑**: 
   - 最大总行数 = 最大页数 × 每页行数
   - 逐个文件累加代码行数，直到达到最大总行数
   - 如果最后一个文件超出限制，则截断该文件

3. **特殊情况处理**:
   - 如果代码总行数不足，则按实际页数生成
   - 如果某个文件会超出限制，只截取该文件的部分内容
   - 记录是否发生截断，供UI提示用户

4. **用户提示**:
```dart
// 在导出完成后提示用户
if (result.isTruncated) {
  showWarningDialog(
    '文档已达到最大页数限制（${config.maxPages}页），'
    '部分代码未被包含在文档中。'
  );
} else {
  showSuccessDialog(
    '文档生成成功，共 ${result.totalPages} 页。'
  );
}
```



## 6. 页眉页脚实现

### 6.1 动态页眉
```dart
class DynamicHeader {
  final String softwareName;
  final String version;
  
  DynamicHeader({
    required this.softwareName,
    required this.version,
  });
  
  void addToDocument(Document doc) {
    final section = doc.sections.first;
    final header = section.header;
    
    // 创建表格实现左右布局
    final table = header.addTable(1, 2);
    table.rows[0].cells[0].addParagraph()
      ..addText('$softwareName V$version')
      ..alignment = Alignment.center;
    
    table.rows[0].cells[1].addParagraph()
      ..addText('第 PAGE 页')
      ..alignment = Alignment.right;
    
    // 设置表格宽度为 100%
    table.width = double.infinity;
    
    // 添加下边框线
    final paragraph = header.addParagraph();
    paragraph.paragraphFormat.spaceAfter = 6.0;
  }
}
```

### 6.2 页码实现
```dart
class PageNumberHandler {
  void addPageNumber(Section section) {
    final footer = section.footer;
    final paragraph = footer.addParagraph();
    
    paragraph.alignment = Alignment.center;
    
    // 添加页码字段
    final field = paragraph.addField('PAGE');
    field.format = 'Arabic';
    
    paragraph.addText(' / ');
    
    // 添加总页数字段
    final totalPagesField = paragraph.addField('NUMPAGES');
    totalPagesField.format = 'Arabic';
  }
}
```

## 7. 字体配置

### 7.1 等宽字体选择
```dart
class FontSelector {
  static const Map<String, String> monospaceFonts = {
    'windows': 'Consolas',
    'macos': 'Monaco',
    'linux': 'DejaVu Sans Mono',
    'fallback': 'Courier New',
  };
  
  static String selectMonospaceFont() {
    if (Platform.isWindows) {
      return monospaceFonts['windows']!;
    } else if (Platform.isMacOS) {
      return monospaceFonts['macos']!;
    } else if (Platform.isLinux) {
      return monospaceFonts['linux']!;
    }
    return monospaceFonts['fallback']!;
  }
}
```

### 7.2 字体嵌入（可选）
```dart
class FontEmbedder {
  Future<void> embedFont(Document doc, String fontPath) async {
    // 读取字体文件
    final fontFile = File(fontPath);
    final fontBytes = await fontFile.readAsBytes();
    
    // 添加到文档的字体表
    doc.fonts.add(
      FontEntry(
        name: 'CustomMonospace',
        data: fontBytes,
      ),
    );
  }
}
```

## 8. 性能优化

### 8.1 批量写入
```dart
class BatchWordExporter {
  final int batchSize;
  final WordExporter exporter;
  
  BatchWordExporter({
    required this.exporter,
    this.batchSize = 100,
  });
  
  Future<void> exportLarge(
    Stream<CleanCode> codeStream,
    String outputPath,
    ProgressCallback onProgress,
  ) async {
    final doc = await exporter._createDocument();
    var count = 0;
    
    await for (final code in codeStream) {
      await exporter._addCodeSection(doc, code);
      count++;
      
      if (count % batchSize == 0) {
        onProgress(count);
      }
    }
    
    await exporter._saveDocument(doc, outputPath);
  }
}
```

### 8.2 内存优化
```dart
class MemoryEfficientExporter {
  Future<void> exportWithLowMemory(
    List<SourceFile> files,
    String outputPath,
  ) async {
    // 使用临时文件策略
    final tempDir = await getTemporaryDirectory();
    final tempFiles = <String>[];
    
    try {
      // 1. 分别导出每个文件
      for (var i = 0; i < files.length; i++) {
        final tempPath = '${tempDir.path}/temp_$i.docx';
        await _exportSingleFile(files[i], tempPath);
        tempFiles.add(tempPath);
      }
      
      // 2. 合并文档
      await _mergeDocuments(tempFiles, outputPath);
      
    } finally {
      // 清理临时文件
      for (final tempFile in tempFiles) {
        await File(tempFile).delete();
      }
    }
  }
  
  Future<void> _mergeDocuments(List<String> docs, String output) async {
    // 使用 docx_template 或其他库合并文档
  }
}
```

## 9. 测试用例

### 9.1 单元测试
```dart
group('WordExporter', () {
  test('应该创建有效的 Word 文档', () async {
    final exporter = WordExporter(
      config: ExportConfig(
        softwareName: '测试软件',
        version: '1.0.0',
      ),
    );
    
    final codes = [
      CleanCode(
        fileName: 'test.dart',
        cleanedContent: 'void main() {\n  print("Hello");\n}',
        originalLines: 3,
        cleanedLines: 3,
        removedComments: 0,
        removedEmptyLines: 0,
      ),
    ];
    
    final tempPath = '${Directory.systemTemp.path}/test.docx';
    final result = await exporter.export(codes, tempPath);
    
    expect(await File(tempPath).exists(), isTrue);
    expect(result.totalPages, equals(1));
    expect(result.isTruncated, isFalse);
    
    // 清理
    await File(tempPath).delete();
  });
  
  test('应该正确分页', () {
    final paginator = PrecisePaginator(
      targetLinesPerPage: 50,
      pageHeight: 842.0,
      marginTop: 72.0,
      marginBottom: 72.0,
    );
    
    final lines = List.generate(120, (i) => 'Line $i');
    final pages = paginator.paginate(lines);
    
    expect(pages.length, equals(3));
    expect(pages[0].length, equals(50));
    expect(pages[1].length, equals(50));
    expect(pages[2].length, equals(20));
  });
  
  test('应该限制最大页数', () async {
    final exporter = WordExporter(
      config: ExportConfig(
        softwareName: '测试软件',
        version: '1.0.0',
        maxPages: 2,  // 最多2页
        linesPerPage: 50,  // 每页50行
      ),
    );
    
    // 创建总行数为150的代码（应该被截断到100行）
    final codes = [
      CleanCode(
        fileName: 'test.dart',
        cleanedContent: List.generate(150, (i) => 'line $i').join('\n'),
        originalLines: 150,
        cleanedLines: 150,
        removedComments: 0,
        removedEmptyLines: 0,
      ),
    ];
    
    final tempPath = '${Directory.systemTemp.path}/test_limited.docx';
    final result = await exporter.export(codes, tempPath);
    
    expect(result.totalPages, equals(2));
    expect(result.totalLines, equals(100));  // 2页 × 50行/页
    expect(result.isTruncated, isTrue);
    
    // 清理
    await File(tempPath).delete();
  });
  
  test('代码不足时应该按实际页数生成', () async {
    final exporter = WordExporter(
      config: ExportConfig(
        softwareName: '测试软件',
        version: '1.0.0',
        maxPages: 60,  // 最多60页
        linesPerPage: 50,
      ),
    );
    
    // 创建总行数仅为75的代码（应该生成2页）
    final codes = [
      CleanCode(
        fileName: 'test.dart',
        cleanedContent: List.generate(75, (i) => 'line $i').join('\n'),
        originalLines: 75,
        cleanedLines: 75,
        removedComments: 0,
        removedEmptyLines: 0,
      ),
    ];
    
    final tempPath = '${Directory.systemTemp.path}/test_under_limit.docx';
    final result = await exporter.export(codes, tempPath);
    
    expect(result.totalPages, equals(2));
    expect(result.totalLines, equals(75));
    expect(result.isTruncated, isFalse);
    
    // 清理
    await File(tempPath).delete();
  });
});

group('PageLimiter', () {
  test('应该正确计算最大总行数', () {
    final limiter = PageLimiter(
      maxPages: 60,
      linesPerPage: 50,
    );
    
    expect(limiter.maxTotalLines, equals(3000));
  });
  
  test('应该正确预估页数', () {
    final limiter = PageLimiter(
      maxPages: 60,
      linesPerPage: 50,
    );
    
    final codes = [
      CleanCode(
        fileName: 'test1.dart',
        cleanedContent: List.generate(100, (i) => 'line $i').join('\n'),
        originalLines: 100,
        cleanedLines: 100,
        removedComments: 0,
        removedEmptyLines: 0,
      ),
      CleanCode(
        fileName: 'test2.dart',
        cleanedContent: List.generate(200, (i) => 'line $i').join('\n'),
        originalLines: 200,
        cleanedLines: 200,
        removedComments: 0,
        removedEmptyLines: 0,
      ),
    ];
    
    final estimatedPages = limiter.estimatePages(codes);
    expect(estimatedPages, equals(6));  // 300行 ÷ 50行/页 = 6页
  });
});
```

## 10. 异常处理

```dart
class ExportException implements Exception {
  final String message;
  final dynamic originalError;
  
  ExportException(this.message, {this.originalError});
  
  @override
  String toString() => 'ExportException: $message';
}

class WordExporter {
  Future<void> export(
    List<CleanCode> codes,
    String outputPath,
  ) async {
    try {
      // 验证输出路径
      if (!outputPath.endsWith('.docx')) {
        throw ExportException('输出文件必须是 .docx 格式');
      }
      
      // 验证输出目录是否存在
      final outputDir = path.dirname(outputPath);
      if (!await Directory(outputDir).exists()) {
        throw ExportException('输出目录不存在: $outputDir');
      }
      
      // 导出逻辑
      final doc = await _createDocument();
      
      for (final code in codes) {
        if (code.cleanedContent.isEmpty) {
          continue;  // 跳过空文件
        }
        
        await _addCodeSection(doc, code);
      }
      
      await _saveDocument(doc, outputPath);
      
    } catch (e) {
      if (e is ExportException) {
        rethrow;
      }
      throw ExportException('导出失败: ${e.toString()}', originalError: e);
    }
  }
}
```
