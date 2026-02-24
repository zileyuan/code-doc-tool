# 编码处理模块设计文档

## 1. 模块概述

### 1.1 核心职责
自动检测源代码文件编码，将不同编码的文件内容统一转换为 Unicode，确保 Word 文档导出时中文不乱码。

### 1.2 设计原则
- **自动检测**: 使用多种算法自动识别编码
- **内存转码**: 只在内存中转换，不修改源文件
- **容错处理**: 检测失败时提供合理的默认值
- **性能优化**: 采样检测，避免读取整个文件

## 2. 类设计

### 2.1 核心类图
```
┌──────────────────┐
│ EncodingDetector │
├──────────────────┤
│ - strategies: List<DetectStrategy> │
├──────────────────┤
│ + detect(bytes: Uint8List): Future<String> │
│ + detectFromFile(file: File): Future<String> │
└──────────────────┘
         │
         └─── uses ───▶ ┌─────────────────┐
                        │ DetectStrategy  │ (interface)
                        ├─────────────────┤
                        │ + detect(bytes): String? │
                        └─────────────────┘
                               △
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│ BOMDetector   │    │CharsetDetector│    │UTF8Validator │
└───────────────┘    └───────────────┘    └───────────────┘
```

### 2.2 数据模型

#### EncodingResult
```dart
class EncodingResult {
  final String encoding;        // 编码名称
  final double confidence;      // 置信度 0.0-1.0
  final bool hasBOM;           // 是否有 BOM
  
  EncodingResult({
    required this.encoding,
    required this.confidence,
    this.hasBOM = false,
  });
  
  bool get isHighConfidence => confidence > 0.8;
}
```

#### EncodingInfo
```dart
class EncodingInfo {
  final String name;           // 编码名称
  final String displayName;    // 显示名称
  final List<String> aliases;  // 别名列表
  final bool hasBOM;          // 是否支持 BOM
  
  static const Map<String, EncodingInfo> encodings = {
    'UTF-8': EncodingInfo(
      name: 'UTF-8',
      displayName: 'UTF-8',
      aliases: ['utf8', 'UTF8'],
      hasBOM: true,
    ),
    'GBK': EncodingInfo(
      name: 'GBK',
      displayName: 'GBK (简体中文)',
      aliases: ['gb2312', 'GB2312', 'gbk', 'cp936'],
      hasBOM: false,
    ),
    'BIG5': EncodingInfo(
      name: 'BIG5',
      displayName: 'BIG5 (繁体中文)',
      aliases: ['big5', 'Big5'],
      hasBOM: false,
    ),
  };
}
```

## 3. 编码检测策略

### 3.1 BOM 检测
```dart
class BOMDetector implements DetectStrategy {
  static const Map<List<int>, String> _bomMap = {
    [0xEF, 0xBB, 0xBF]: 'UTF-8',
    [0xFF, 0xFE]: 'UTF-16LE',
    [0xFE, 0xFF]: 'UTF-16BE',
    [0x00, 0x00, 0xFE, 0xFF]: 'UTF-32BE',
    [0xFF, 0xFE, 0x00, 0x00]: 'UTF-32LE',
  };
  
  @override
  String? detect(Uint8List bytes) {
    for (final entry in _bomMap.entries) {
      if (_matchesBOM(bytes, entry.key)) {
        return entry.value;
      }
    }
    return null;
  }
  
  bool _matchesBOM(Uint8List bytes, List<int> bom) {
    if (bytes.length < bom.length) return false;
    
    for (var i = 0; i < bom.length; i++) {
      if (bytes[i] != bom[i]) return false;
    }
    return true;
  }
}
```

### 3.2 UTF-8 验证
```dart
class UTF8Validator implements DetectStrategy {
  @override
  String? detect(Uint8List bytes) {
    try {
      utf8.decode(bytes);
      
      // 额外检查：UTF-8 编码规则
      if (_isValidUTF8(bytes)) {
        return 'UTF-8';
      }
    } catch (e) {
      // 不是有效的 UTF-8
    }
    return null;
  }
  
  bool _isValidUTF8(Uint8List bytes) {
    var i = 0;
    while (i < bytes.length) {
      final byte = bytes[i];
      
      if (byte <= 0x7F) {
        // ASCII 字符
        i++;
      } else if ((byte & 0xE0) == 0xC0) {
        // 2 字节序列
        if (i + 1 >= bytes.length) return false;
        if ((bytes[i + 1] & 0xC0) != 0x80) return false;
        i += 2;
      } else if ((byte & 0xF0) == 0xE0) {
        // 3 字节序列
        if (i + 2 >= bytes.length) return false;
        if ((bytes[i + 1] & 0xC0) != 0x80) return false;
        if ((bytes[i + 2] & 0xC0) != 0x80) return false;
        i += 3;
      } else if ((byte & 0xF8) == 0xF0) {
        // 4 字节序列
        if (i + 3 >= bytes.length) return false;
        if ((bytes[i + 1] & 0xC0) != 0x80) return false;
        if ((bytes[i + 2] & 0xC0) != 0x80) return false;
        if ((bytes[i + 3] & 0xC0) != 0x80) return false;
        i += 4;
      } else {
        return false;
      }
    }
    return true;
  }
}
```

### 3.3 统计检测（基于字符频率）
```dart
class StatisticalDetector implements DetectStrategy {
  @override
  String? detect(Uint8List bytes) {
    // 计算字节分布
    final stats = _calculateByteStats(bytes);
    
    // 检查是否像 GBK
    if (_looksLikeGBK(stats, bytes)) {
      return 'GBK';
    }
    
    // 检查是否像 BIG5
    if (_looksLikeBIG5(stats, bytes)) {
      return 'BIG5';
    }
    
    return null;
  }
  
  ByteStats _calculateByteStats(Uint8List bytes) {
    var highBytes = 0;
    var lowBytes = 0;
    var controlChars = 0;
    
    for (final byte in bytes) {
      if (byte >= 0x80) {
        highBytes++;
      } else {
        lowBytes++;
      }
      
      if (byte < 0x20 && byte != 0x09 && byte != 0x0A && byte != 0x0D) {
        controlChars++;
      }
    }
    
    return ByteStats(
      highBytes: highBytes,
      lowBytes: lowBytes,
      controlChars: controlChars,
      total: bytes.length,
    );
  }
  
  bool _looksLikeGBK(ByteStats stats, Uint8List bytes) {
    // GBK 编码规则：
    // 第一字节：0x81-0xFE
    // 第二字节：0x40-0xFE（不含 0x7F）
    
    if (stats.highBytesRatio < 0.1) return false;
    
    var validGBKPairs = 0;
    var i = 0;
    
    while (i < bytes.length - 1) {
      final first = bytes[i];
      final second = bytes[i + 1];
      
      if (first >= 0x81 && first <= 0xFE) {
        if ((second >= 0x40 && second <= 0xFE) && second != 0x7F) {
          validGBKPairs++;
          i += 2;
          continue;
        }
      }
      i++;
    }
    
    return validGBKPairs > stats.total * 0.05;
  }
  
  bool _looksLikeBIG5(ByteStats stats, Uint8List bytes) {
    // BIG5 编码规则类似 GBK，但范围不同
    // 简化实现
    return false;
  }
}

class ByteStats {
  final int highBytes;
  final int lowBytes;
  final int controlChars;
  final int total;
  
  ByteStats({
    required this.highBytes,
    required this.lowBytes,
    required this.controlChars,
    required this.total,
  });
  
  double get highBytesRatio => highBytes / total;
}
```

## 4. 编码转换

### 4.1 EncodingConverter 实现
```dart
class EncodingConverter {
  final Map<String, Codec<String, List<int>>> _codecs = {};
  
  EncodingConverter() {
    _registerCodecs();
  }
  
  void _registerCodecs() {
    _codecs['UTF-8'] = utf8;
    _codecs['GBK'] = gbk_codec.GbkCodec();
    _codecs['BIG5'] = big5_codec.Big5Codec();
  }
  
  Future<String> convertToUnicode(
    Uint8List bytes,
    String sourceEncoding,
  ) async {
    final codec = _codecs[sourceEncoding.toUpperCase()];
    
    if (codec == null) {
      throw EncodingException('不支持的编码: $sourceEncoding');
    }
    
    try {
      return codec.decode(bytes);
    } catch (e) {
      throw EncodingException(
        '编码转换失败: ${e.toString()}',
        encoding: sourceEncoding,
      );
    }
  }
  
  Future<String> convertFileToUnicode(
    File file,
    String encoding,
  ) async {
    final bytes = await file.readAsBytes();
    return await convertToUnicode(bytes, encoding);
  }
}
```

### 4.2 智能转换器
```dart
class SmartEncodingConverter {
  final EncodingDetector detector;
  final EncodingConverter converter;
  
  SmartEncodingConverter({
    EncodingDetector? detector,
    EncodingConverter? converter,
  })  : detector = detector ?? EncodingDetector(),
        converter = converter ?? EncodingConverter();
  
  Future<String> convertWithAutoDetection(
    Uint8List bytes, {
    String? hintEncoding,
  }) async {
    String encoding;
    
    if (hintEncoding != null) {
      encoding = hintEncoding;
    } else {
      final result = await detector.detect(bytes);
      encoding = result.encoding;
    }
    
    return await converter.convertToUnicode(bytes, encoding);
  }
  
  Future<String> convertFileWithAutoDetection(
    File file, {
    String? hintEncoding,
  }) async {
    final bytes = await file.readAsBytes();
    return await convertWithAutoDetection(bytes, hintEncoding: hintEncoding);
  }
}
```

## 5. 核心流程

### 5.1 EncodingDetector 实现
```dart
class EncodingDetector {
  final List<DetectStrategy> _strategies;
  final int sampleSize;
  
  EncodingDetector({
    List<DetectStrategy>? strategies,
    this.sampleSize = 4096,
  }) : _strategies = strategies ?? _defaultStrategies();
  
  static List<DetectStrategy> _defaultStrategies() {
    return [
      BOMDetector(),
      UTF8Validator(),
      StatisticalDetector(),
    ];
  }
  
  Future<EncodingResult> detect(Uint8List bytes) async {
    // 采样（如果文件太大）
    final sample = bytes.length > sampleSize
        ? Uint8List.sublistView(bytes, 0, sampleSize)
        : bytes;
    
    // 依次应用检测策略
    for (final strategy in _strategies) {
      final result = strategy.detect(sample);
      if (result != null) {
        return EncodingResult(
          encoding: result,
          confidence: 1.0,
          hasBOM: _hasBOM(sample),
        );
      }
    }
    
    // 默认返回 GBK（对中文环境友好）
    return EncodingResult(
      encoding: 'GBK',
      confidence: 0.5,
    );
  }
  
  Future<EncodingResult> detectFromFile(File file) async {
    final bytes = await _readSample(file);
    return await detect(bytes);
  }
  
  Future<Uint8List> _readSample(File file) async {
    final length = await file.length();
    final readLength = min(length, sampleSize);
    
    final randomAccessFile = await file.open(mode: FileMode.read);
    try {
      return await randomAccessFile.read(readLength);
    } finally {
      await randomAccessFile.close();
    }
  }
  
  bool _hasBOM(Uint8List bytes) {
    return BOMDetector().detect(bytes) != null;
  }
}
```

## 6. 常见编码支持

### 6.1 编码映射表
```dart
class EncodingRegistry {
  static const Map<String, EncodingInfo> supportedEncodings = {
    'UTF-8': EncodingInfo(
      name: 'UTF-8',
      displayName: 'UTF-8',
      aliases: ['utf8', 'UTF8', 'utf-8'],
      hasBOM: true,
    ),
    'GBK': EncodingInfo(
      name: 'GBK',
      displayName: 'GBK (简体中文)',
      aliases: ['gb2312', 'GB2312', 'gbk', 'cp936', 'MS936'],
      hasBOM: false,
    ),
    'BIG5': EncodingInfo(
      name: 'BIG5',
      displayName: 'BIG5 (繁体中文)',
      aliases: ['big5', 'Big5', 'big-5'],
      hasBOM: false,
    ),
    'ISO-8859-1': EncodingInfo(
      name: 'ISO-8859-1',
      displayName: 'ISO-8859-1 (Latin-1)',
      aliases: ['latin1', 'latin-1', 'iso8859-1'],
      hasBOM: false,
    ),
    'Windows-1252': EncodingInfo(
      name: 'Windows-1252',
      displayName: 'Windows-1252',
      aliases: ['cp1252', 'windows1252'],
      hasBOM: false,
    ),
    'Shift_JIS': EncodingInfo(
      name: 'Shift_JIS',
      displayName: 'Shift_JIS (日文)',
      aliases: ['shiftjis', 'sjis', 'MS_Kanji'],
      hasBOM: false,
    ),
    'EUC-JP': EncodingInfo(
      name: 'EUC-JP',
      displayName: 'EUC-JP (日文)',
      aliases: ['eucjp', 'euc-jp'],
      hasBOM: false,
    ),
    'EUC-KR': EncodingInfo(
      name: 'EUC-KR',
      displayName: 'EUC-KR (韩文)',
      aliases: ['euckr', 'euc-kr'],
      hasBOM: false,
    ),
  };
  
  static String normalizeEncoding(String encoding) {
    final upper = encoding.toUpperCase();
    
    // 直接匹配
    if (supportedEncodings.containsKey(upper)) {
      return upper;
    }
    
    // 别名匹配
    for (final entry in supportedEncodings.entries) {
      if (entry.value.aliases.contains(encoding)) {
        return entry.key;
      }
    }
    
    // 默认返回原值
    return encoding;
  }
}
```

## 7. 异常处理

### 7.1 异常定义
```dart
class EncodingException implements Exception {
  final String message;
  final String? encoding;
  final dynamic originalError;
  
  EncodingException(
    this.message, {
    this.encoding,
    this.originalError,
  });
  
  @override
  String toString() {
    final buffer = StringBuffer('EncodingException: $message');
    if (encoding != null) {
      buffer.write(' (encoding: $encoding)');
    }
    return buffer.toString();
  }
}
```

### 7.2 错误处理策略
```dart
class EncodingErrorHandler {
  Future<String> handleConversionError(
    Uint8List bytes,
    String encoding,
    dynamic error,
  ) async {
    // 策略 1: 尝试其他可能的编码
    final alternativeEncodings = _getAlternativeEncodings(encoding);
    
    for (final altEncoding in alternativeEncodings) {
      try {
        final converter = EncodingConverter();
        return await converter.convertToUnicode(bytes, altEncoding);
      } catch (e) {
        // 继续尝试下一个
      }
    }
    
    // 策略 2: 使用容错解码
    return _decodeWithErrorReplacement(bytes, encoding);
  }
  
  List<String> _getAlternativeEncodings(String encoding) {
    final alternatives = <String>[];
    
    if (encoding == 'GBK') {
      alternatives.addAll(['GB18030', 'GB2312']);
    } else if (encoding == 'UTF-8') {
      alternatives.addAll(['GBK', 'ISO-8859-1']);
    }
    
    return alternatives;
  }
  
  String _decodeWithErrorReplacement(Uint8List bytes, String encoding) {
    // 使用替换字符代替无法解码的字节
    final buffer = StringBuffer();
    
    for (final byte in bytes) {
      if (byte < 0x80) {
        buffer.writeCharCode(byte);
      } else {
        buffer.write('�');  // Unicode 替换字符
      }
    }
    
    return buffer.toString();
  }
}
```

## 8. 性能优化

### 8.1 缓存机制
```dart
class EncodingCache {
  final Map<String, EncodingResult> _cache = {};
  final Duration expiry;
  
  EncodingCache({this.expiry = const Duration(minutes: 30)});
  
  EncodingResult? get(String filePath) {
    final cached = _cache[filePath];
    if (cached == null) return null;
    
    return cached;
  }
  
  void put(String filePath, EncodingResult result) {
    _cache[filePath] = result;
  }
  
  void clear() {
    _cache.clear();
  }
}
```

### 8.2 批量检测
```dart
class BatchEncodingDetector {
  final EncodingDetector detector;
  final int concurrency;
  
  BatchEncodingDetector({
    required this.detector,
    this.concurrency = 4,
  });
  
  Future<Map<String, EncodingResult>> detectBatch(
    List<File> files,
  ) async {
    final results = <String, EncodingResult>{};
    
    // 使用 StreamController 控制并发
    final controller = StreamController<File>();
    
    // 创建多个工作流
    final workers = List.generate(concurrency, (_) => _worker(controller.stream));
    
    // 启动所有工作流
    final allResults = await Future.wait(workers);
    
    // 合并结果
    for (final resultMap in allResults) {
      results.addAll(resultMap);
    }
    
    // 添加文件到队列
    for (final file in files) {
      controller.add(file);
    }
    await controller.close();
    
    return results;
  }
  
  Future<Map<String, EncodingResult>> _worker(Stream<File> fileStream) async {
    final results = <String, EncodingResult>{};
    
    await for (final file in fileStream) {
      final result = await detector.detectFromFile(file);
      results[file.path] = result;
    }
    
    return results;
  }
}
```

## 9. 测试用例

### 9.1 单元测试
```dart
group('EncodingDetector', () {
  test('应该检测 UTF-8 BOM', () async {
    final detector = EncodingDetector();
    final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, 0x48, 0x65, 0x6C, 0x6C, 0x6F]);
    
    final result = await detector.detect(bytes);
    
    expect(result.encoding, equals('UTF-8'));
    expect(result.hasBOM, isTrue);
    expect(result.confidence, equals(1.0));
  });
  
  test('应该检测纯 UTF-8', () async {
    final detector = EncodingDetector();
    final bytes = Uint8List.fromList(utf8.encode('Hello 你好'));
    
    final result = await detector.detect(bytes);
    
    expect(result.encoding, equals('UTF-8'));
  });
  
  test('应该检测 GBK 编码', () async {
    final detector = EncodingDetector();
    final bytes = Uint8List.fromList([0xC4, 0xE3, 0xBA, 0xC3]);  // "你好" in GBK
    
    final result = await detector.detect(bytes);
    
    expect(result.encoding, equals('GBK'));
  });
});

group('EncodingConverter', () {
  test('应该正确转换 UTF-8 到 Unicode', () async {
    final converter = EncodingConverter();
    final bytes = Uint8List.fromList(utf8.encode('Hello 你好'));
    
    final result = await converter.convertToUnicode(bytes, 'UTF-8');
    
    expect(result, equals('Hello 你好'));
  });
  
  test('应该正确转换 GBK 到 Unicode', () async {
    final converter = EncodingConverter();
    final bytes = Uint8List.fromList([0xC4, 0xE3, 0xBA, 0xC3]);  // "你好" in GBK
    
    final result = await converter.convertToUnicode(bytes, 'GBK');
    
    expect(result, equals('你好'));
  });
});
```

## 10. 日志记录

```dart
class EncodingLogger {
  final Logger logger;
  
  EncodingLogger({Logger? logger}) : logger = logger ?? Logger();
  
  void logDetection(String filePath, EncodingResult result) {
    logger.info(
      '文件编码检测: $filePath => ${result.encoding} '
      '(置信度: ${(result.confidence * 100).toStringAsFixed(1)}%)',
    );
  }
  
  void logConversion(String filePath, String from, String to) {
    logger.debug('编码转换: $filePath ($from -> $to)');
  }
  
  void logError(String filePath, dynamic error) {
    logger.error('编码处理错误: $filePath', error: error);
  }
}
```
