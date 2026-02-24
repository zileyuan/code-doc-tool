import 'dart:io';
import 'package:path/path.dart' as p;
import '../../domain/models/source_file.dart';
import '../../domain/models/scan_config.dart';
import '../../infrastructure/encoding/encoding_detector.dart';

class FileScanner {
  final ScanConfig config;
  final EncodingDetector encodingDetector;

  FileScanner({required this.config, EncodingDetector? encodingDetector})
    : encodingDetector = encodingDetector ?? EncodingDetector();

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
    final rootDir = Directory(rootPath);
    if (!await rootDir.exists()) {
      throw ScannerException('目录不存在: $rootPath');
    }

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
    final extension = p.extension(file.path).toLowerCase();
    if (!config.allowedExtensions.contains(extension)) {
      return null;
    }

    final relativePath = p.relative(file.path, from: rootPath);
    if (_isInExcludedDirectory(relativePath)) {
      return null;
    }

    final fileSize = await file.length();
    if (fileSize > config.maxFileSize) {
      return null;
    }

    String encoding = 'UTF-8';
    if (config.detectEncoding) {
      encoding = await encodingDetector.detect(file);
    }

    final stat = await file.stat();

    return SourceFile(
      path: file.absolute.path,
      relativePath: relativePath,
      name: p.basename(file.path),
      extension: extension,
      size: fileSize,
      encoding: encoding,
      lastModified: stat.modified,
    );
  }

  bool _isInExcludedDirectory(String relativePath) {
    final parts = p.posix.split(relativePath.replaceAll('\\', '/'));
    return parts.any((part) => config.excludedDirectories.contains(part));
  }
}

class ScannerException implements Exception {
  final String message;
  final String? path;

  ScannerException(this.message, {this.path});

  @override
  String toString() =>
      'ScannerException: $message${path != null ? ' (path: $path)' : ''}';
}
