import 'dart:io';
import '../models/clean_code.dart';
import '../models/export_config.dart';
import '../models/export_result.dart';
import '../../infrastructure/exporters/word_exporter.dart';

class ExportService {
  Future<ExportResult> exportToWord(
    List<CleanCode> codes,
    String outputPath,
    ExportConfig config,
  ) async {
    final exporter = WordExporter(config: config);

    final dir = File(outputPath).parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return await exporter.export(codes, outputPath);
  }
}
