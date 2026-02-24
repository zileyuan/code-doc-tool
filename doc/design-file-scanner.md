# 文件扫描模块设计文档

## 1. 模块概述

### 1.1 核心职责
文件扫描模块负责遍历指定目录，收集符合条件的源代码文件，确保全程**只读操作**，不修改任何源文件。

### 1.2 设计原则
- **只读保证**: 严禁任何写入操作
- **性能优先**: 支持大目录快速扫描
- **安全过滤**: 防止扫描敏感目录
- **编码友好**: 支持多种编码自动检测

## 2. 类设计

### 2.1 核心类图
```
┌─────────────────┐
│  FileScanner    │
├─────────────────┤
│ - config: ScanConfig │
│ - validator: PathValidator │
├─────────────────┤
│ + scan(): Future<List<SourceFile>> │
│ + scanDirectory(path: String): Stream<SourceFile> │
│ - _filterFile(file: File): bool │
│ - _detectEncoding(file: File): String │
└─────────────────┘
         │
         ├─── uses ───▶ ┌─────────────────┐
         │              │ ScanConfig      │
         │              ├─────────────────┤
         │              │ - allowedExtensions: Set<String> │
         │              │ - excludedDirs: Set<String> │
         │              │ - maxFileSize: int │
         │              └─────────────────┘
         │
         └─── uses ───▶ ┌─────────────────┐
                        │ PathValidator   │
                        ├─────────────────┤
                        │ + isSafePath(): bool │
                        │ + isAllowedDir(): bool │
                        └─────────────────┘
```

### 2.2 数据模型

#### SourceFile
```dart
class SourceFile {
  final String path;              // 绝对路径
  final String relativePath;      // 相对于根目录的路径
  final String name;              // 文件名
  final String extension;         // 扩展名
  final int size;                 // 文件大小（字节）
  final String encoding;          // 文件编码
  final DateTime lastModified;    // 最后修改时间
  
  SourceFile({
    required this.path,
    required this.relativePath,
    required this.name,
    required this.extension,
    required this.size,
    required this.encoding,
    required this.lastModified,
  });
}
```

#### ScanConfig
```dart
class ScanConfig {
  final Set<String> allowedExtensions;    // 允许的文件后缀
  final Set<String> excludedDirectories;  // 排除的目录
  final int maxFileSize;                  // 最大文件大小限制
  final bool detectEncoding;              // 是否检测编码
  
  static const defaultExtensions = {
    '.dart', '.java', '.kt', '.go', '.rs',
    '.cpp', '.c', '.h', '.hpp',
    '.js', '.ts', '.jsx', '.tsx',
    '.py', '.rb', '.php',
    '.cs', '.swift', '.m',
  };
  
  static const defaultExcludedDirs = {
    'node_modules', 'build', 'dist', 'target',
    '.git', '.svn', '.hg',
    '__pycache__', 'venv', '.venv',
    'bin', 'obj', 'out',
  };
}
```

## 3. 扫描流程

### 3.1 主流程图
```
开始
  ↓
验证输入路径
  ↓
遍历目录树
  ├─ 检查是否排除目录 → 跳过
  ├─ 检查文件后缀 → 跳过
  ├─ 检查文件大小 → 跳过
  ├─ 检测文件编码
  └─ 创建 SourceFile 对象
  ↓
返回文件列表
```

### 3.2 实现代码

#### FileScanner 核心实现
```dart
class FileScanner {
  final ScanConfig config;
  final PathValidator validator;
  final EncodingDetector encodingDetector;
  
  FileScanner({
    required this.config,
    PathValidator? validator,
    EncodingDetector? encodingDetector,
  })  : validator = validator ?? PathValidator(),
        encodingDetector = encodingDetector ?? EncodingDetector();
  
  Future<List<SourceFile>> scan(List<String> rootPaths) async {
    final files = <SourceFile>[];
    
    for (final rootPath in rootPaths) {
      await for (final file in scanDirectory(rootPath)) {
        files.add(file);
      }
    }
    
    return files;
  }
  
  Stream<SourceFile> scanDirectory(String rootPath) async* {
    // 验证路径安全性
    if (!await validator.isSafePath(rootPath)) {
      throw ScannerException('非法路径: $rootPath');
    }
    
    final rootDir = Directory(rootPath);
    if (!await rootDir.exists()) {
      throw ScannerException('目录不存在: $rootPath');
    }
    
    // 遍历目录
    await for (final entity in rootDir.list(recursive: true)) {
      if (entity is File) {
        final sourceFile = await _processFile(entity, rootPath);
        if (sourceFile != null) {
          yield sourceFile;
        }
      }
    }
  }
  
  Future<SourceFile?> _processFile(File file, String rootPath) async {
    // 1. 检查文件后缀
    final extension = path.extension(file.path).toLowerCase();
    if (!config.allowedExtensions.contains(extension)) {
      return null;
    }
    
    // 2. 检查路径是否在排除目录中
    final relativePath = path.relative(file.path, from: rootPath);
    if (_isInExcludedDirectory(relativePath)) {
      return null;
    }
    
    // 3. 检查文件大小
    final fileSize = await file.length();
    if (fileSize > config.maxFileSize) {
      return null;
    }
    
    // 4. 检测文件编码
    String encoding = 'UTF-8';
    if (config.detectEncoding) {
      encoding = await encodingDetector.detect(file);
    }
    
    // 5. 获取文件元数据
    final stat = await file.stat();
    
    return SourceFile(
      path: file.absolute.path,
      relativePath: relativePath,
      name: path.basename(file.path),
      extension: extension,
      size: fileSize,
      encoding: encoding,
      lastModified: stat.modified,
    );
  }
  
  bool _isInExcludedDirectory(String relativePath) {
    final parts = path.split(relativePath);
    return parts.any((part) => config.excludedDirectories.contains(part));
  }
}
```

## 4. 路径验证

### 4.1 PathValidator 实现

路径验证器确保只处理安全的文件路径，防止路径遍历攻击和访问系统敏感目录。

```dart
class PathValidator {
  // 危险字符模式
  static const _dangerousPatterns = ['../', '..\\', '~', '|', '>', '<', '\$', '`', ';', '&'];
  
  // 危险文件扩展名
  static const _dangerousExtensions = ['.exe', '.bat', '.cmd', '.sh', '.ps1', '.dll', '.so', '.dylib'];
  
  // 验证路径安全性
  Future<PathValidationResult> validate(String path) async {
    // 1. 检查危险字符
    // 2. 规范化路径
    // 3. 解析符号链接
    // 4. 检查是否在系统目录内
  }
  
  // 验证文件路径
  Future<PathValidationResult> validateFile(String path) async {
    // 额外检查文件是否存在、扩展名是否安全
  }
  
  // 验证目录路径
  Future<PathValidationResult> validateDirectory(String path) async {
    // 检查目录是否存在
  }
  
  // 检测符号链接
  Future<bool> isSymlink(String path) async;
  
  // 解析符号链接
  Future<String?> resolveSymlink(String path) async;
}
```

**验证流程**：
1. 检查路径是否包含危险字符（`..`、`~`、`|` 等）
2. 规范化路径格式
3. 解析符号链接到真实路径
4. 检查是否在系统敏感目录内（如 `/System`、`/etc`、`C:\Windows`）
5. 对于文件，额外检查扩展名是否安全

**系统保护目录**：
- Windows: `C:\Windows`、`C:\Program Files`、`C:\System`
- macOS: `/System`、`/Library`、`/usr`、`/bin`、`/etc`
- Linux: `/bin`、`/sbin`、`/usr`、`/etc`、`/var`、`/sys`、`/proc`

## 5. 编码检测

### 5.1 EncodingDetector 实现
```dart
class EncodingDetector {
  final int sampleSize;
  
  EncodingDetector({this.sampleSize = 4096});
  
  Future<String> detect(File file) async {
    try {
      // 读取文件前 N 字节
      final randomAccessFile = await file.open(mode: FileMode.read);
      final bytes = await randomAccessFile.read(sampleSize);
      await randomAccessFile.close();
      
      // 尝试检测编码
      return await _detectFromBytes(bytes);
    } catch (e) {
      // 默认返回 UTF-8
      return 'UTF-8';
    }
  }
  
  Future<String> _detectFromBytes(Uint8List bytes) async {
    // 1. 检查 BOM
    if (bytes.length >= 3 && 
        bytes[0] == 0xEF && 
        bytes[1] == 0xBB && 
        bytes[2] == 0xBF) {
      return 'UTF-8';
    }
    
    // 2. 检查 UTF-16 BOM
    if (bytes.length >= 2) {
      if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
        return 'UTF-16BE';
      }
      if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
        return 'UTF-16LE';
      }
    }
    
    // 3. 尝试 UTF-8 解码
    try {
      utf8.decode(bytes);
      return 'UTF-8';
    } catch (e) {
      // 不是 UTF-8
    }
    
    // 4. 使用 charset_converter 检测
    try {
      final detected = await CharsetConverter.detect(bytes);
      return detected ?? 'GBK';
    } catch (e) {
      return 'GBK';
    }
  }
}
```

## 6. 只读安全保证

### 6.1 ReadOnlyFileReader
```dart
class ReadOnlyFileReader {
  Future<String> readAsString(String filePath, {String? encoding}) async {
    final file = File(filePath);
    
    // 强制使用只读模式
    final randomAccessFile = await file.open(mode: FileMode.read);
    
    try {
      final bytes = await randomAccessFile.read(await file.length());
      
      // 根据 encoding 解码
      final codec = _getCodec(encoding ?? 'UTF-8');
      return codec.decode(bytes);
    } finally {
      // 确保关闭文件句柄
      await randomAccessFile.close();
    }
  }
  
  Future<Uint8List> readAsBytes(String filePath) async {
    final file = File(filePath);
    final randomAccessFile = await file.open(mode: FileMode.read);
    
    try {
      return await randomAccessFile.read(await file.length());
    } finally {
      await randomAccessFile.close();
    }
  }
  
  Encoding _getCodec(String encoding) {
    switch (encoding.toUpperCase()) {
      case 'UTF-8':
        return utf8;
      case 'GBK':
      case 'GB2312':
        return gbk;  // 需要引入 gbk 编码库
      default:
        return utf8;
    }
  }
}
```

### 6.2 安全检查机制
```dart
class SecurityChecker {
  static void ensureReadOnlyOperation(String operation) {
    final writeOperations = ['write', 'delete', 'rename', 'move', 'copy'];
    
    if (writeOperations.any((op) => operation.toLowerCase().contains(op))) {
      throw SecurityException('不允许的写操作: $operation');
    }
  }
  
  static void validatePath(String path) {
    // 防止路径注入
    if (path.contains('\x00')) {
      throw SecurityException('路径包含非法字符');
    }
    
    // 防止符号链接攻击
    final link = Link(path);
    if (link.existsSync()) {
      throw SecurityException('不允许访问符号链接');
    }
  }
}
```

## 7. 性能优化

### 7.1 并发扫描
```dart
class ParallelScanner {
  final int concurrency;
  final FileScanner scanner;
  
  ParallelScanner({
    required this.scanner,
    this.concurrency = 4,
  });
  
  Future<List<SourceFile>> scanParallel(List<String> rootPaths) async {
    final files = <SourceFile>[];
    final queue = StreamQueue(Stream.fromIterable(rootPaths));
    
    // 创建多个工作流
    final workers = List.generate(concurrency, (_) => _worker(queue, scanner));
    
    // 等待所有工作流完成
    final results = await Future.wait(workers);
    
    for (final result in results) {
      files.addAll(result);
    }
    
    return files;
  }
  
  Future<List<SourceFile>> _worker(
    StreamQueue<String> queue,
    FileScanner scanner,
  ) async {
    final files = <SourceFile>[];
    
    while (await queue.hasNext) {
      final path = await queue.next;
      final scannedFiles = await scanner.scan([path]);
      files.addAll(scannedFiles);
    }
    
    return files;
  }
}
```

## 8. 错误处理

### 8.1 异常定义
```dart
class ScannerException implements Exception {
  final String message;
  final String? path;
  final dynamic originalError;
  
  ScannerException(
    this.message, {
    this.path,
    this.originalError,
  });
  
  @override
  String toString() => 'ScannerException: $message${path != null ? ' (path: $path)' : ''}';
}

class SecurityException extends ScannerException {
  SecurityException(String message, {String? path})
      : super(message, path: path);
}

class EncodingException extends ScannerException {
  EncodingException(String message, {String? path})
      : super(message, path: path);
}
```

### 8.2 错误处理策略
```dart
class ScanErrorHandler {
  final Logger logger;
  
  ScanErrorHandler({Logger? logger}) 
      : logger = logger ?? Logger();
  
  Future<SourceFile?> handleFileError(
    File file,
    dynamic error,
    ErrorStrategy strategy,
  ) async {
    logger.warning('处理文件失败: ${file.path}', error: error);
    
    switch (strategy) {
      case ErrorStrategy.skip:
        return null;
        
      case ErrorStrategy.retry:
        // 重试一次
        try {
          return await _retryScan(file);
        } catch (e) {
          logger.error('重试失败: ${file.path}', error: e);
          return null;
        }
        
      case ErrorStrategy.abort:
        throw ScannerException(
          '扫描中止',
          path: file.path,
          originalError: error,
        );
    }
  }
  
  Future<SourceFile> _retryScan(File file) async {
    // 重试逻辑
  }
}

enum ErrorStrategy {
  skip,    // 跳过
  retry,   // 重试
  abort,   // 中止
}
```

## 9. 日志记录

### 9.1 日志格式
```dart
class ScanLogger {
  void logFileScanned(SourceFile file) {
    logger.info('扫描文件: ${file.path} (${file.size} bytes, ${file.encoding})');
  }
  
  void logFileSkipped(String path, String reason) {
    logger.debug('跳过文件: $path - 原因: $reason');
  }
  
  void logDirectoryScanned(String path, int fileCount) {
    logger.info('扫描目录: $path - 发现 $fileCount 个文件');
  }
  
  void logError(String path, dynamic error) {
    logger.error('错误: $path', error: error);
  }
}
```

## 10. 测试用例

### 10.1 单元测试
```dart
group('FileScanner', () {
  test('应该正确扫描指定目录', () async {
    final scanner = FileScanner(config: ScanConfig.default());
    final files = await scanner.scan(['test/fixtures/sample_project']);
    
    expect(files.length, greaterThan(0));
    expect(files.every((f) => f.path.endsWith('.dart')), isTrue);
  });
  
  test('应该排除指定目录', () async {
    final config = ScanConfig(
      excludedDirectories: {'node_modules'},
    );
    final scanner = FileScanner(config: config);
    final files = await scanner.scan(['test/fixtures/project']);
    
    expect(files.any((f) => f.path.contains('node_modules')), isFalse);
  });
  
  test('应该检测文件编码', () async {
    final scanner = FileScanner(
      config: ScanConfig(detectEncoding: true),
    );
    final files = await scanner.scan(['test/fixtures/encoded_files']);
    
    final gbkFile = files.firstWhere((f) => f.name == 'chinese_gbk.txt');
    expect(gbkFile.encoding, equals('GBK'));
  });
});
```

### 10.2 性能测试
```dart
test('大目录扫描性能', () async {
  final scanner = FileScanner(config: ScanConfig.default());
  
  final stopwatch = Stopwatch()..start();
  final files = await scanner.scan(['large_project']);
  stopwatch.stop();
  
  expect(files.length, greaterThan(1000));
  expect(stopwatch.elapsedMilliseconds, lessThan(5000));
});
```
