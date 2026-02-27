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
> **实现说明**: EncodingDetector 直接在类内实现多种检测算法（BOM检测、UTF-8验证、GBK统计检测），没有使用策略模式分离成独立的策略类。

```
┌──────────────────┐
│ EncodingDetector │
├──────────────────┤
│ - sampleSize: int (默认4096字节) │
├──────────────────┤
│ + detect(file: File): Future<EncodingResult> │
│ - _readSample(file): Future<Uint8List> │
│ - _detectFromBytes(bytes): EncodingResult │
│ - _hasBOM(bytes): bool │
│ - _detectBOM(bytes): String │
│ - _isValidUTF8(bytes): bool │
│ - _analyzeGBK(bytes): EncodingResult? │
└──────────────────┘
         │
         └─── uses ───▶ ┌──────────────────┐
                        │ EncodingResult   │
                        ├──────────────────┤
                        │ - encoding: String │
                        │ - confidence: double │
                        │ - hasBOM: bool │
                        └──────────────────┘
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

  @override
  String toString() =>
      'EncodingResult($encoding, confidence: $confidence, hasBOM: $hasBOM)';
}
```

**置信度说明**:
- BOM 检测：置信度 1.0（最可靠）
- UTF-8 验证通过：置信度 0.9
- GBK 统计检测：置信度 0.5-0.85（根据有效 GBK 字节对比例计算）
- 默认值：置信度 0.5

## 3. 编码检测实现

> **实现说明**: 以下检测逻辑直接实现在 `EncodingDetector` 类中作为私有方法，没有独立的策略类。

### 3.1 EncodingDetector 类实现
```dart
class EncodingDetector {
  final int sampleSize;

  EncodingDetector({this.sampleSize = 4096});

  Future<EncodingResult> detect(File file) async {
    try {
      final bytes = await _readSample(file);
      return _detectFromBytes(bytes);
    } catch (e) {
      return EncodingResult(encoding: 'UTF-8', confidence: 0.5);
    }
  }

  Future<Uint8List> _readSample(File file) async {
    final length = await file.length();
    final readLength = length < sampleSize ? length : sampleSize;

    final randomAccessFile = await file.open(mode: FileMode.read);
    try {
      return await randomAccessFile.read(readLength);
    } finally {
      await randomAccessFile.close();
    }
  }

  EncodingResult _detectFromBytes(Uint8List bytes) {
    // 1. BOM 检测
    if (_hasBOM(bytes)) {
      final encoding = _detectBOM(bytes);
      return EncodingResult(encoding: encoding, confidence: 1.0, hasBOM: true);
    }

    // 2. UTF-8 验证
    if (_isValidUTF8(bytes)) {
      return EncodingResult(encoding: 'UTF-8', confidence: 0.9, hasBOM: false);
    }

    // 3. GBK 统计检测
    final gbkResult = _analyzeGBK(bytes);
    if (gbkResult != null) {
      return gbkResult;
    }

    // 4. 默认返回 UTF-8
    return EncodingResult(encoding: 'UTF-8', confidence: 0.5, hasBOM: false);
  }

  // BOM 检测
  bool _hasBOM(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return true;
    }
    if (bytes.length >= 2) {
      if (bytes[0] == 0xFE && bytes[1] == 0xFF) return true;
      if (bytes[0] == 0xFF && bytes[1] == 0xFE) return true;
    }
    return false;
  }

  String _detectBOM(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return 'UTF-8';
    }
    if (bytes.length >= 2) {
      if (bytes[0] == 0xFE && bytes[1] == 0xFF) return 'UTF-16BE';
      if (bytes[0] == 0xFF && bytes[1] == 0xFE) return 'UTF-16LE';
    }
    return 'UTF-8';
  }

  // UTF-8 验证
  bool _isValidUTF8(Uint8List bytes) {
    var i = 0;
    while (i < bytes.length) {
      final byte = bytes[i];

      if (byte <= 0x7F) {
        i++;
      } else if ((byte & 0xE0) == 0xC0) {
        if (i + 1 >= bytes.length) return false;
        if ((bytes[i + 1] & 0xC0) != 0x80) return false;
        i += 2;
      } else if ((byte & 0xF0) == 0xE0) {
        if (i + 2 >= bytes.length) return false;
        if ((bytes[i + 1] & 0xC0) != 0x80) return false;
        if ((bytes[i + 2] & 0xC0) != 0x80) return false;
        i += 3;
      } else if ((byte & 0xF8) == 0xF0) {
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

  // GBK 统计检测
  EncodingResult? _analyzeGBK(Uint8List bytes) {
    var validPairs = 0;
    var invalidPairs = 0;
    var i = 0;

    while (i < bytes.length - 1) {
      final first = bytes[i];

      if (first >= 0x81 && first <= 0xFE) {
        final second = bytes[i + 1];
        if ((second >= 0x40 && second <= 0xFE) && second != 0x7F) {
          validPairs++;
          i += 2;
          continue;
        } else {
          invalidPairs++;
        }
      }
      i++;
    }

    final totalPairs = validPairs + invalidPairs;
    if (totalPairs == 0) return null;

    final ratio = validPairs / totalPairs;
    if (ratio > 0.8) {
      return EncodingResult(encoding: 'GBK', confidence: ratio);
    }
    return null;
  }
}
```

## 4. 编码转换

> **实现说明**: 使用 `charset_converter` 包进行 GBK 解码，不使用自定义的 EncodingConverter 类。

### 4.1 ReadOnlyFileReader 实现
```dart
import 'package:charset_converter/charset_converter.dart';

class ReadOnlyFileReader {
  Future<String> readAsString(
    String filePath, {
    String encoding = 'UTF-8',
  }) async {
    final file = File(filePath);
    final randomAccessFile = await file.open(mode: FileMode.read);

    try {
      final bytes = await randomAccessFile.read(await file.length());
      return await _decode(bytes, encoding);
    } finally {
      await randomAccessFile.close();
    }
  }

  Future<String> _decode(List<int> bytes, String encoding) async {
    switch (encoding.toUpperCase()) {
      case 'UTF-8':
      case 'UTF8':
        return utf8.decode(bytes);
      case 'GBK':
      case 'GB2312':
        return await _decodeGBK(bytes);
      case 'LATIN1':
      case 'ISO-8859-1':
        return latin1.decode(bytes);
      default:
        return utf8.decode(bytes);
    }
  }

  Future<String> _decodeGBK(List<int> bytes) async {
    try {
      final uint8List = Uint8List.fromList(bytes);
      return await CharsetConverter.decode('gbk', uint8List);
    } catch (e) {
      try {
        return utf8.decode(bytes);
      } catch (_) {
        return String.fromCharCodes(bytes);
      }
    }
  }
}
```

## 5. 支持的编码

| 编码 | 检测方式 | 解码方式 |
|------|----------|----------|
| UTF-8 | BOM检测、格式验证 | Dart 内置 utf8 |
| UTF-8 with BOM | BOM检测 | Dart 内置 utf8 |
| GBK/GB2312 | 统计检测 | charset_converter 包 |
| Latin1/ISO-8859-1 | 默认回退 | Dart 内置 latin1 |

## 6. 错误处理

检测或转换失败时的处理策略：
1. 首先尝试使用检测到的编码进行解码
2. 如果失败，尝试 UTF-8
3. 如果仍失败，使用 latin1 解码（不会抛出异常）

```dart
// 简化的错误处理示例
Future<String> safeDecode(List<int> bytes, String encoding) async {
  try {
    return await _decode(bytes, encoding);
  } catch (e) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return String.fromCharCodes(bytes);  // 最后的回退方案
    }
  }
}
```

## 7. 性能考虑

- **采样检测**: 默认只读取前 4096 字节进行编码检测
- **只读模式**: 使用 `FileMode.read` 确保不修改源文件
- **及时关闭**: 使用 `try-finally` 确保文件句柄及时释放

## 8. 测试要点

- UTF-8 有/无 BOM 的文件
- GBK/GB2312 编码的中文文件
- 混合编码的目录扫描
- 超大文件（超过采样大小）
- 特殊字符和 Emoji
