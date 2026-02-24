import '../models/clean_code.dart';
import '../../data/processors/code_cleaner.dart';
import '../../infrastructure/io/file_reader.dart';

class CleanService {
  final CodeCleaner _cleaner;
  final ReadOnlyFileReader _fileReader;

  CleanService() : _cleaner = CodeCleaner(), _fileReader = ReadOnlyFileReader();

  Future<CleanCode> cleanFile(
    String filePath,
    String fileName,
    String encoding,
  ) async {
    final content = await _fileReader.readAsString(
      filePath,
      encoding: encoding,
    );

    final extension = _getExtension(fileName);
    return await _cleaner.clean(content, fileName, extension);
  }

  Future<List<CleanCode>> cleanFiles(List<dynamic> files) async {
    final results = <CleanCode>[];

    for (final file in files) {
      final cleanCode = await cleanFile(file.path, file.name, file.encoding);
      results.add(cleanCode);
    }

    return results;
  }

  String _getExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length > 1) {
      return '.${parts.last}';
    }
    return '';
  }
}
