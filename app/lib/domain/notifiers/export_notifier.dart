import 'package:flutter/foundation.dart';
import '../models/clean_code.dart';
import '../models/export_config.dart';
import '../models/source_file.dart';
import '../services/clean_service.dart';
import '../services/export_service.dart';

enum ExportProgressState { idle, cleaning, exporting, completed, error }

class ExportNotifier extends ChangeNotifier {
  String _softwareName = '';
  String _version = '';
  final int _linesPerPage = 50;
  final int _maxPages = 60;
  List<CleanCode> _cleanedCodes = [];
  
  ExportProgressState _progressState = ExportProgressState.idle;
  double _progress = 0.0;
  String _statusMessage = '';

  // Getters
  String get softwareName => _softwareName;
  String get version => _version;
  String get appVersion => _version;
  int get linesPerPage => _linesPerPage;
  int get maxPages => _maxPages;
  int get maxTotalLines => _maxPages * _linesPerPage;
  List<CleanCode> get cleanedCodes => List.unmodifiable(_cleanedCodes);
  ExportProgressState get progressState => _progressState;
  double get progress => _progress;
  String get statusMessage => _statusMessage;

  void updateConfig({String? softwareName, String? version}) {
    if (softwareName != null) _softwareName = softwareName;
    if (version != null) _version = version;
    notifyListeners();
  }

  void updateProgress(ExportProgressState state, double value, String message) {
    _progressState = state;
    _progress = value;
    _statusMessage = message;
    notifyListeners();
  }

  Future<void> cleanAndExport(List<SourceFile> filesToClean, String outputPath) async {
    try {
      updateProgress(ExportProgressState.cleaning, 0.0, '正在清洗代码...');
      final cleanService = CleanService();
      _cleanedCodes = await cleanService.cleanFiles(filesToClean);
      
      updateProgress(ExportProgressState.exporting, 0.5, '正在生成 Word 文档...');
      final config = ExportConfig(softwareName: _softwareName, version: _version, linesPerPage: _linesPerPage, maxPages: _maxPages);
      final exportService = ExportService();
      await exportService.exportToWord(_cleanedCodes, outputPath, config);
      
      updateProgress(ExportProgressState.completed, 1.0, '导出完成！');
    } catch (e) {
      updateProgress(ExportProgressState.error, 0.0, '导出失败: \$e');
    }
  }

  void reset() {
    _progressState = ExportProgressState.idle;
    _progress = 0.0;
    _statusMessage = '';
    _cleanedCodes.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
