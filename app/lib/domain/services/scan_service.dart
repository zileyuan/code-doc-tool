import '../models/source_file.dart';
import '../models/scan_config.dart';
import '../../data/processors/file_scanner.dart';
import '../../infrastructure/encoding/encoding_detector.dart';

class ScanService {
  final FileScanner _scanner;

  ScanService({ScanConfig? config})
    : _scanner = FileScanner(
        config: config ?? ScanConfig(),
        encodingDetector: EncodingDetector(),
      );

  Future<List<SourceFile>> scanDirectories(List<String> directoryPaths) async {
    return await _scanner.scan(directoryPaths);
  }

  Stream<SourceFile> scanDirectory(String directoryPath) async* {
    yield* _scanner.scanDirectory(directoryPath);
  }
}
