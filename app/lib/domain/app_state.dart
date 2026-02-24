import 'package:flutter/foundation.dart';
import 'models/source_file.dart';
import 'models/clean_code.dart';
import 'models/export_config.dart';
import 'models/scan_config.dart';
import 'services/scan_service.dart';
import 'services/clean_service.dart';
import 'services/export_service.dart';

enum ProgressState { idle, scanning, cleaning, exporting, completed, error }

class AppState extends ChangeNotifier {
  List<String> sourceDirectories = [];

  String softwareName = '';
  String version = '1.0.0';
  int linesPerPage = 50;
  int maxPages = 60;

  Set<String> allowedExtensions = ScanConfig.defaultExtensions;
  Set<String> excludedDirectories = ScanConfig.defaultExcludedDirs;

  List<SourceFile> scannedFiles = [];
  Set<String> selectedFiles = {};

  ProgressState progressState = ProgressState.idle;
  double progress = 0.0;
  String statusMessage = '';

  List<CleanCode> cleanedCodes = [];

  final CleanService _cleanService;
  final ExportService _exportService;

  AppState() : _cleanService = CleanService(), _exportService = ExportService();

  int get maxTotalLines => maxPages * linesPerPage;
  int get totalSelectedFiles => selectedFiles.length;
  int get totalScannedFiles => scannedFiles.length;

  void addDirectory(String path) {
    if (!sourceDirectories.contains(path)) {
      sourceDirectories.add(path);
      notifyListeners();
    }
  }

  void removeDirectory(String path) {
    sourceDirectories.remove(path);
    notifyListeners();
  }

  void clearDirectories() {
    sourceDirectories.clear();
    scannedFiles.clear();
    selectedFiles.clear();
    notifyListeners();
  }

  void updateConfig({String? softwareName, String? version}) {
    if (softwareName != null) this.softwareName = softwareName;
    if (version != null) this.version = version;
    notifyListeners();
  }

  void updateFilterConfig({
    Set<String>? allowedExtensions,
    Set<String>? excludedDirectories,
  }) {
    if (allowedExtensions != null) this.allowedExtensions = allowedExtensions;
    if (excludedDirectories != null)
      this.excludedDirectories = excludedDirectories;
    notifyListeners();
  }

  void updateProgress(ProgressState state, double value, String message) {
    progressState = state;
    progress = value;
    statusMessage = message;
    notifyListeners();
  }

  void selectFile(String path, bool selected) {
    if (selected) {
      selectedFiles.add(path);
    } else {
      selectedFiles.remove(path);
    }
    notifyListeners();
  }

  void selectAllFiles() {
    selectedFiles = scannedFiles.map((f) => f.path).toSet();
    notifyListeners();
  }

  void deselectAllFiles() {
    selectedFiles.clear();
    notifyListeners();
  }

  Future<void> scanFiles() async {
    try {
      updateProgress(ProgressState.scanning, 0.0, '正在扫描文件...');

      final config = ScanConfig(
        allowedExtensions: allowedExtensions,
        excludedDirectories: excludedDirectories,
      );

      final service = ScanService(config: config);
      scannedFiles = await service.scanDirectories(sourceDirectories);
      selectedFiles = scannedFiles.map((f) => f.path).toSet();

      updateProgress(
        ProgressState.completed,
        1.0,
        '扫描完成，共找到 ${scannedFiles.length} 个文件',
      );
    } catch (e) {
      updateProgress(ProgressState.error, 0.0, '扫描失败: $e');
    }
  }

  Future<void> cleanAndExport(String outputPath) async {
    try {
      if (selectedFiles.isEmpty) {
        updateProgress(ProgressState.error, 0.0, '请先选择要导出的文件');
        return;
      }

      if (softwareName.isEmpty) {
        updateProgress(ProgressState.error, 0.0, '请输入软件名称');
        return;
      }

      updateProgress(ProgressState.cleaning, 0.0, '正在清洗代码...');

      final filesToClean = scannedFiles
          .where((f) => selectedFiles.contains(f.path))
          .toList();

      cleanedCodes = await _cleanService.cleanFiles(filesToClean);

      updateProgress(ProgressState.exporting, 0.5, '正在生成Word文档...');

      final config = ExportConfig(
        softwareName: softwareName,
        version: version,
        linesPerPage: linesPerPage,
        maxPages: maxPages,
      );

      final result = await _exportService.exportToWord(
        cleanedCodes,
        outputPath,
        config,
      );

      updateProgress(ProgressState.completed, 1.0, result.summary);
    } catch (e) {
      updateProgress(ProgressState.error, 0.0, '导出失败: $e');
    }
  }

  void reset() {
    progressState = ProgressState.idle;
    progress = 0.0;
    statusMessage = '';
    notifyListeners();
  }
}
