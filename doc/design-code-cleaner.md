# 代码清洗模块设计文档

## 1. 模块概述

### 1.1 核心职责
代码清洗模块在内存中对源代码进行非破坏性处理，去除注释和空行，确保**不修改任何源文件**。

### 1.2 设计原则
- **内存处理**: 所有操作在内存中完成
- **不可逆性**: 清洗后的代码只存在于程序变量中
- **语言适配**: 支持多种编程语言的注释语法
- **性能优化**: 流式处理，避免内存溢出

## 2. 类设计

### 2.1 核心类图
```
┌─────────────────┐
│  CodeCleaner    │
├─────────────────┤
│ - strategies: Map<String, CleanStrategy> │
├─────────────────┤
│ + clean(code: String, lang: String): String │
│ + cleanLines(lines: List<String>, lang: String): List<String> │
└─────────────────┘
         │
         └─── uses ───▶ ┌──────────────────┐
                        │ CleanStrategy    │ (interface)
                        ├──────────────────┤
                        │ + removeComments(code: String): String │
                        │ + removeEmptyLines(code: String): String │
                        └──────────────────┘
                               △
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│ CStyleStrategy│    │ PythonStrategy│    │  HTMLStrategy │
└───────────────┘    └───────────────┘    └───────────────┘
```

### 2.2 数据模型

#### CleanCode
```dart
class CleanCode {
  final String originalContent;      // 原始内容（内存中）
  final String cleanedContent;       // 清洗后内容
  final int originalLines;           // 原始行数
  final int cleanedLines;            // 清洗后行数
  final int removedComments;         // 移除的注释数量
  final int removedEmptyLines;       // 移除的空行数量
  
  CleanCode({
    required this.originalContent,
    required this.cleanedContent,
    required this.originalLines,
    required this.cleanedLines,
    required this.removedComments,
    required this.removedEmptyLines,
});

double get compressionRatio => 
  cleanedContent.length / originalContent.length;
}
```

> **注意**: 当前实现直接移除所有注释和空行，无需配置选项。`CleaningConfig` 类未实现，所有清洗参数为固定值：
> - `removeComments = true` - 移除所有注释
> - `removeEmptyLines = true` - 移除空行
> - `trimWhitespace = true` - 去除行尾空白

## 3. 清洗策略

### 3.1 语言映射
```dart
class LanguageMapper {
  static const Map<String, List<String>> extensionToLanguage = {
    // C-Style 语言
    '.dart': ['c-style'],
    '.java': ['c-style'],
    '.kt': ['c-style'],
    '.cpp': ['c-style'],
    '.c': ['c-style'],
    '.h': ['c-style'],
    '.cs': ['c-style'],
    '.swift': ['c-style'],
    '.go': ['c-style'],
    '.rs': ['c-style'],
    '.js': ['c-style'],
    '.ts': ['c-style'],
    '.jsx': ['c-style'],
    '.tsx': ['c-style'],
    
    // Python-Style
    '.py': ['python'],
    '.rb': ['python'],
    
    // Shell-Style
    '.sh': ['shell'],
    '.bash': ['shell'],
    
    // Markup
    '.html': ['html'],
    '.htm': ['html'],
    '.xml': ['html'],
    
    // CSS
    '.css': ['css'],
    '.scss': ['css'],
    '.less': ['css'],
    
    // SQL
    '.sql': ['sql'],
  };
```

### 3.2 C-Style 策略实现
```dart
class CStyleCleanStrategy implements CleanStrategy {
  @override
  String removeComments(String code) {
    final buffer = StringBuffer();
    var i = 0;
    
    while (i < code.length) {
      // 检测多行注释 /*
      if (i < code.length - 1 && code[i] == '/' && code[i + 1] == '*') {
        // 跳过直到找到 */
        i += 2;
        while (i < code.length - 1) {
          if (code[i] == '*' && code[i + 1] == '/') {
            i += 2;
            break;
          }
          i++;
        }
        continue;
      }
      
      // 检测单行注释 //
      if (i < code.length - 1 && code[i] == '/' && code[i + 1] == '/') {
        // 跳过直到行尾
        while (i < code.length && code[i] != '\n') {
          i++;
        }
        continue;
      }
      
      // 检测字符串字面量（避免误删字符串中的注释标记）
      if (code[i] == '"' || code[i] == "'" || code[i] == '`') {
        final quote = code[i];
        buffer.write(code[i]);
        i++;
        
        // 跳过字符串内容
        while (i < code.length && code[i] != quote) {
          if (code[i] == '\\') {
            buffer.write(code[i]);
            i++;
            if (i < code.length) {
              buffer.write(code[i]);
              i++;
            }
          } else {
            buffer.write(code[i]);
            i++;
          }
        }
        if (i < code.length) {
          buffer.write(code[i]);
          i++;
        }
        continue;
      }
      
      // 正常字符
      buffer.write(code[i]);
      i++;
    }
    
    return buffer.toString();
  }
  
  @override
  String removeEmptyLines(String code) {
    return code
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .join('\n');
  }
}
```

### 3.3 Python-Style 策略实现
```dart
class PythonCleanStrategy implements CleanStrategy {
  @override
  String removeComments(String code) {
    final buffer = StringBuffer();
    var i = 0;
    var inTripleQuotes = false;
    String? tripleQuoteType;
    
    while (i < code.length) {
      // 检测三引号字符串
      if (!inTripleQuotes && i < code.length - 2) {
        if ((code.substring(i, i + 3) == '"""' || 
             code.substring(i, i + 3) == "'''")) {
          tripleQuoteType = code.substring(i, i + 3);
          buffer.write(code.substring(i, i + 3));
          i += 3;
          inTripleQuotes = true;
          continue;
        }
      }
      
      // 在三引号字符串中
      if (inTripleQuotes && i < code.length - 2) {
        if (code.substring(i, i + 3) == tripleQuoteType) {
          buffer.write(code.substring(i, i + 3));
          i += 3;
          inTripleQuotes = false;
          tripleQuoteType = null;
          continue;
        }
        buffer.write(code[i]);
        i++;
        continue;
      }
      
      // 检测单行注释 #
      if (!inTripleQuotes && code[i] == '#') {
        while (i < code.length && code[i] != '\n') {
          i++;
        }
        continue;
      }
      
      // 检测字符串（单引号或双引号）
      if (!inTripleQuotes && (code[i] == '"' || code[i] == "'")) {
        final quote = code[i];
        buffer.write(code[i]);
        i++;
        
        while (i < code.length && code[i] != quote) {
          if (code[i] == '\\') {
            buffer.write(code[i]);
            i++;
            if (i < code.length) {
              buffer.write(code[i]);
              i++;
            }
          } else {
            buffer.write(code[i]);
            i++;
          }
        }
        if (i < code.length) {
          buffer.write(code[i]);
          i++;
        }
        continue;
      }
      
      buffer.write(code[i]);
      i++;
    }
    
    return buffer.toString();
  }
  
  @override
  String removeEmptyLines(String code) {
    return code
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .join('\n');
  }
}
```

### 3.4 HTML/XML 策略实现
```dart
class HTMLCleanStrategy implements CleanStrategy {
  @override
  String removeComments(String code) {
    final buffer = StringBuffer();
    var i = 0;
    
    while (i < code.length) {
      // 检测 HTML 注释 <!--
      if (i < code.length - 3 && 
          code[i] == '<' && 
          code[i + 1] == '!' && 
          code[i + 2] == '-' && 
          code[i + 3] == '-') {
        // 跳过直到 -->
        i += 4;
        while (i < code.length - 2) {
          if (code[i] == '-' && 
              code[i + 1] == '-' && 
              code[i + 2] == '>') {
            i += 3;
            break;
          }
          i++;
        }
        continue;
      }
      
      buffer.write(code[i]);
      i++;
    }
    
    return buffer.toString();
  }
  
  @override
  String removeEmptyLines(String code) {
    return code
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .join('\n');
  }
}
```

## 4. 核心流程

### 4.1 CodeCleaner 实现
```dart
class CodeCleaner {
  final Map<String, CleanStrategy> _strategies;
  final CleaningConfig config;
  
  CodeCleaner({
    CleaningConfig? config,
    Map<String, CleanStrategy>? strategies,
  })  : config = config ?? CleaningConfig(),
        _strategies = strategies ?? _defaultStrategies();
  
  static Map<String, CleanStrategy> _defaultStrategies() {
    return {
      'c-style': CStyleCleanStrategy(),
      'python': PythonCleanStrategy(),
      'html': HTMLCleanStrategy(),
      'css': CSSCleanStrategy(),
      'shell': ShellCleanStrategy(),
      'sql': SQLCleanStrategy(),
    };
  }
  
  Future<CleanCode> clean(String content, String extension) async {
    final languages = LanguageMapper.getLanguages(extension);
    
    var cleanedContent = content;
    var currentContent = content;
    
    // 应用每种语言的清洗策略
    for (final language in languages) {
      final strategy = _strategies[language] ?? _strategies['c-style']!;
      
      if (config.removeComments) {
        currentContent = strategy.removeComments(currentContent);
      }
    }
    
    // 最后统一移除空行
    if (config.removeEmptyLines) {
      currentContent = _removeEmptyLines(currentContent);
    }
    
    // 去除行尾空白
    if (config.trimWhitespace) {
      currentContent = _trimWhitespace(currentContent);
    }
    
    cleanedContent = currentContent;
    
    return CleanCode(
      originalContent: content,
      cleanedContent: cleanedContent,
      originalLines: content.split('\n').length,
      cleanedLines: cleanedContent.split('\n').length,
      removedComments: _countRemovedComments(content, cleanedContent),
      removedEmptyLines: content.split('\n').length - 
                         cleanedContent.split('\n').length,
    );
  }
  
  String _removeEmptyLines(String content) {
    return content
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .join('\n');
  }
  
  String _trimWhitespace(String content) {
    return content
        .split('\n')
        .map((line) => line.trimRight())
        .join('\n');
  }
  
  int _countRemovedComments(String original, String cleaned) {
    // 简单估算，不精确
    return (original.length - cleaned.length) ~/ 10;
  }
}
```

### 4.2 流式处理
```dart
class StreamCodeCleaner {
  final CodeCleaner cleaner;
  
  StreamCodeCleaner(this.cleaner);
  
  Stream<CleanCode> cleanStream(Stream<String> contentStream, String extension) async* {
    await for (final content in contentStream) {
      yield await cleaner.clean(content, extension);
    }
  }
  
  Stream<String> cleanLargeFile(String filePath, String extension) async* {
    final file = File(filePath);
    final stream = file.openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    
    final buffer = <String>[];
    const batchSize = 1000;  // 每 1000 行处理一次
    
    await for (final line in stream) {
      buffer.add(line);
      
      if (buffer.length >= batchSize) {
        final batch = buffer.join('\n');
        final cleanCode = await cleaner.clean(batch, extension);
        yield cleanCode.cleanedContent;
        buffer.clear();
      }
    }
    
    // 处理剩余的行
    if (buffer.isNotEmpty) {
      final batch = buffer.join('\n');
      final cleanCode = await cleaner.clean(batch, extension);
      yield cleanCode.cleanedContent;
    }
  }
}
```

## 5. 性能优化

### 5.1 使用 Isolate

对于大文件（超过 100KB），自动使用 Isolate 在后台线程处理，避免阻塞 UI：

```dart
class CodeCleaner {
  static const int isolateThreshold = 100 * 1024; // 100KB

  Future<CleanCode> clean(String content, String fileName, String extension) async {
    if (content.length > isolateThreshold) {
      return await cleanInIsolate(content, fileName, extension);
    }
    return _cleanSync(content, fileName, extension);
  }

  Future<CleanCode> cleanInIsolate(String content, String fileName, String extension) async {
    return await Isolate.run(() {
      return _cleanInIsolate(_IsolateParams(
        content: content,
        fileName: fileName,
        extension: extension,
      ));
    });
  }
}
```

### 5.2 批量处理
```dart
class BatchCodeCleaner {
  final CodeCleaner cleaner;
  final int batchSize;
  
  BatchCodeCleaner({
    required this.cleaner,
    this.batchSize = 100,
  });
  
  Future<List<CleanCode>> cleanBatch(List<SourceFile> files) async {
    final results = <CleanCode>[];
    
    for (var i = 0; i < files.length; i += batchSize) {
      final batch = files.skip(i).take(batchSize);
      
      final cleanResults = await Future.wait(
        batch.map((file) => _cleanFile(file)),
      );
      
      results.addAll(cleanResults);
    }
    
    return results;
  }
  
  Future<CleanCode> _cleanFile(SourceFile file) async {
    final content = await File(file.path).readAsString();
    return await cleaner.clean(content, file.extension);
  }
}
```

## 6. 正则表达式方案（备选）

### 6.1 正则表达式库
```dart
class RegexCommentRemover {
  static final Map<String, List<RegExp>> _commentPatterns = {
    'c-style': [
      RegExp(r'//.*?$', multiLine: true),      // 单行注释
      RegExp(r'/\*.*?\*/', dotAll: true),      // 多行注释
    ],
    'python': [
      RegExp(r'#.*$', multiLine: true),        // 单行注释
    ],
    'html': [
      RegExp(r'<!--.*?-->', dotAll: true),     // HTML 注释
    ],
  };
  
  static String removeComments(String code, String language) {
    var result = code;
    final patterns = _commentPatterns[language] ?? _commentPatterns['c-style']!;
    
    for (final pattern in patterns) {
      result = result.replaceAll(pattern, '');
    }
    
    return result;
  }
}
```

### 6.2 优缺点对比

| 方案 | 优点 | 缺点 |
|------|------|------|
| 状态机（推荐） | 精确、不误删、性能好 | 代码复杂 |
| 正则表达式 | 简单、代码少 | 可能误删、嵌套注释难处理 |

## 7. 测试用例

### 7.1 单元测试
```dart
group('CStyleCleanStrategy', () {
  test('应该移除单行注释', () {
    final strategy = CStyleCleanStrategy();
    final code = '''
int x = 10; // 这是注释
int y = 20;
''';
    final result = strategy.removeComments(code);
    expect(result.contains('//'), isFalse);
    expect(result.contains('int x = 10'), isTrue);
  });
  
  test('应该移除多行注释', () {
    final strategy = CStyleCleanStrategy();
    final code = '''
/* 
 * 多行注释
 */
int x = 10;
''';
    final result = strategy.removeComments(code);
    expect(result.contains('/*'), isFalse);
    expect(result.contains('多行注释'), isFalse);
  });
  
  test('不应该删除字符串中的注释标记', () {
    final strategy = CStyleCleanStrategy();
    final code = '''String s = "http://example.com";''';
    final result = strategy.removeComments(code);
    expect(result.contains('http://example.com'), isTrue);
  });
});

group('CodeCleaner', () {
  test('应该正确统计清洗结果', () async {
    final cleaner = CodeCleaner();
    final content = '''
// 注释
int x = 10;

// 另一个注释
int y = 20;
''';
    final result = await cleaner.clean(content, '.dart');
    
    expect(result.originalLines, equals(6));
    expect(result.cleanedLines, equals(2));
    expect(result.removedComments, greaterThan(0));
  });
});
```

## 8. 异常处理

```dart
class CleanerException implements Exception {
  final String message;
  final String? code;
  
  CleanerException(this.message, {this.code});
  
  @override
  String toString() => 'CleanerException: $message';
}

class CodeCleaner {
  Future<CleanCode> clean(String content, String extension) async {
    try {
      // 清洗逻辑
    } catch (e) {
      throw CleanerException(
        '代码清洗失败: ${e.toString()}',
        code: content.substring(0, min(100, content.length)),
      );
    }
  }
}
```
