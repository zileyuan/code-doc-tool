import 'dart:io';
import 'package:path/path.dart' as p;

class PathValidationResult {
  final bool isValid;
  final String? error;
  final String? normalizedPath;

  PathValidationResult({
    required this.isValid,
    this.error,
    this.normalizedPath,
  });
}

class PathValidator {
  static const List<String> _dangerousPatterns = [
    '../',
    '..\\',
    '~',
    '|',
    '>',
    '<',
    '\$',
    '`',
    ';',
    '&',
    '||',
    '&&',
  ];

  static const List<String> _dangerousExtensions = [
    '.exe',
    '.bat',
    '.cmd',
    '.sh',
    '.ps1',
    '.vbs',
    '.js',
    '.jar',
    '.msi',
    '.dll',
    '.so',
    '.dylib',
  ];

  Future<PathValidationResult> validate(String path) async {
    if (path.isEmpty) {
      return PathValidationResult(isValid: false, error: '路径不能为空');
    }

    for (final pattern in _dangerousPatterns) {
      if (path.contains(pattern)) {
        return PathValidationResult(
          isValid: false,
          error: '路径包含不安全字符: $pattern',
        );
      }
    }

    final normalizedPath = _normalizePath(path);
    if (normalizedPath == null) {
      return PathValidationResult(isValid: false, error: '路径格式无效');
    }

    try {
      final absolutePath = p.absolute(normalizedPath);
      final canonicalPath = await File(absolutePath).resolveSymbolicLinks();

      if (!_isWithinSafeBounds(canonicalPath)) {
        return PathValidationResult(isValid: false, error: '路径超出安全范围');
      }

      return PathValidationResult(isValid: true, normalizedPath: canonicalPath);
    } catch (e) {
      return PathValidationResult(
        isValid: false,
        error: '路径解析失败: ${e.toString()}',
      );
    }
  }

  Future<PathValidationResult> validateFile(String path) async {
    final baseResult = await validate(path);
    if (!baseResult.isValid) {
      return baseResult;
    }

    final file = File(baseResult.normalizedPath!);
    if (!await file.exists()) {
      return PathValidationResult(isValid: false, error: '文件不存在');
    }

    final extension = p.extension(path).toLowerCase();
    if (_dangerousExtensions.contains(extension)) {
      return PathValidationResult(
        isValid: false,
        error: '不允许的文件类型: $extension',
      );
    }

    return baseResult;
  }

  Future<PathValidationResult> validateDirectory(String path) async {
    final baseResult = await validate(path);
    if (!baseResult.isValid) {
      return baseResult;
    }

    final dir = Directory(baseResult.normalizedPath!);
    if (!await dir.exists()) {
      return PathValidationResult(isValid: false, error: '目录不存在');
    }

    return baseResult;
  }

  String? _normalizePath(String path) {
    try {
      path = path.trim();
      path = path.replaceAll('\\', '/');
      while (path.contains('//')) {
        path = path.replaceAll('//', '/');
      }
      return path;
    } catch (e) {
      return null;
    }
  }

  bool _isWithinSafeBounds(String path) {
    final systemPaths = _getSystemPaths();
    final lowerPath = path.toLowerCase();

    for (final systemPath in systemPaths) {
      if (lowerPath.startsWith(systemPath.toLowerCase())) {
        return false;
      }
    }

    return true;
  }

  List<String> _getSystemPaths() {
    if (Platform.isWindows) {
      return [
        'C:\\Windows',
        'C:\\Program Files',
        'C:\\Program Files (x86)',
        'C:\\System',
      ];
    } else if (Platform.isMacOS) {
      return ['/System', '/Library', '/usr', '/bin', '/sbin', '/etc'];
    } else {
      return ['/bin', '/sbin', '/usr', '/etc', '/var', '/sys', '/proc'];
    }
  }

  Future<bool> isSymlink(String path) async {
    try {
      final link = Link(path);
      return await link.exists();
    } catch (e) {
      return false;
    }
  }

  Future<String?> resolveSymlink(String path) async {
    try {
      final link = Link(path);
      if (await link.exists()) {
        return await link.resolveSymbolicLinks();
      }
      return path;
    } catch (e) {
      return null;
    }
  }
}
