# 测试计划文档

## 1. 测试概述

### 1.1 测试目标
验证软著代码文档生成工具各模块功能正确性、性能及兼容性。

### 1.2 测试范围
- 单元测试：核心算法、工具类
- 集成测试：模块间协作
- 端到端测试：完整工作流程

## 2. 测试策略

### 2.1 单元测试
使用 `flutter_test` 框架，覆盖以下模块：

| 模块 | 测试重点 | 测试文件 |
|------|----------|----------|
| 文件扫描 | 后缀过滤、编码检测 | `test/scanner_test.dart` |
| 代码清洗 | 注释去除、空行过滤 | `test/cleaner_test.dart` |
| 编码处理 | 编码检测准确率 | `test/encoding_test.dart` |
| Word导出 | 文档生成、分页逻辑 | `test/exporter_test.dart` |

### 2.2 集成测试
- 扫描 → 清洗 → 导出 完整流程
- 多目录扫描集成
- 大文件处理性能

### 2.3 手动测试清单
- [ ] 界面操作流程
- [ ] 跨平台兼容性 (macOS/Windows)
- [ ] 多种编码文件处理 (UTF-8/GBK/GB2312)

## 3. 测试用例

### 3.1 文件扫描测试
```dart
test('扫描指定后缀文件', () {
  final scanner = FileScanner(extensions: ['.dart', '.java']);
  final files = scanner.scan('test/fixtures');
  expect(files.length, equals(5));
});
```

### 3.2 代码清洗测试
```dart
test('去除 C 风格注释', () {
  final cleaner = CodeCleaner.forLanguage('c');
  final result = cleaner.clean('int x; // comment');
  expect(result, equals('int x;'));
});
```

### 3.3 编码检测测试
```dart
test('检测 UTF-8 编码', () {
  final detector = EncodingDetector();
  final encoding = detector.detect(utf8Bytes);
  expect(encoding, equals('UTF-8'));
});
```

## 4. 性能基准

| 场景 | 目标性能 |
|------|----------|
| 扫描 1000 个文件 | < 3 秒 |
| 处理 10MB 代码文件 | < 5 秒 |
| 生成 60 页 Word | < 10 秒 |

## 5. 持续集成

### 5.1 GitHub Actions 配置
```yaml
name: Test
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test
```

## 6. 测试覆盖率目标
- 核心模块：≥ 80%
- UI 层：≥ 60%
- 整体：≥ 70%
