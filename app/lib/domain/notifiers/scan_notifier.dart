import 'package:flutter/foundation.dart';
import '../models/source_file.dart';
import '../models/scan_config.dart';
import '../services/scan_service.dart';

enum ScanProgressState { idle, scanning, cleaning, exporting, completed, error }

class ScanNotifier extends ChangeNotifier {
  final List<SourceFile> _scannedFiles = [];
  final Set<String> _selectedFiles = {};

  ScanProgressState _progressState = ScanProgressState.idle;
  double _progress = 0.0;
  String _statusMessage = '';

  Set<String> _allowedExtensions = ScanConfig.defaultExtensions;
  Set<String> _excludedDirectories = ScanConfig.defaultExcludedDirs;

  List<SourceFile> get scannedFiles => List.unmodifiable(_scannedFiles);

  Set<String> get selectedFiles => Set.unmodifiable(_selectedFiles);

  ScanProgressState get progressState => _progressState;

  double get progress => _progress;

  String get statusMessage => _statusMessage;

  Set<String> get allowedExtensions => _allowedExtensions;

  Set<String> get excludedDirectories => _excludedDirectories;

  int get totalScannedFiles => _scannedFiles.length;

  int get totalSelectedFiles => _selectedFiles.length;

  bool get hasScannedFiles => _scannedFiles.isNotEmpty;

  bool get hasSelectedFiles => _selectedFiles.isNotEmpty;

  bool isFileSelected(String path) => _selectedFiles.contains(path);

  void updateFilterConfig({
    Set<String>? allowedExtensions,
    Set<String>? excludedDirectories,
  }) {
    if (allowedExtensions != null) {
      _allowedExtensions = allowedExtensions;
    }
    if (excludedDirectories != null) {
      _excludedDirectories = excludedDirectories;
    }
    notifyListeners();
  }

  void updateProgress(ScanProgressState state, double value, String message) {
    _progressState = state;
    _progress = value;
    _statusMessage = message;
    notifyListeners();
  }

  void selectFile(String path, bool selected) {
    if (selected) {
      _selectedFiles.add(path);
    } else {
      _selectedFiles.remove(path);
    }
    notifyListeners();
  }

  void selectAllFiles() {
    _selectedFiles.addAll(_scannedFiles.map((f) => f.path));
    notifyListeners();
  }

  void deselectAllFiles() {
    if (_selectedFiles.isNotEmpty) {
      _selectedFiles.clear();
      notifyListeners();
    }
  }

  Future<void> scanFiles(List<String> sourceDirectories) async {
    if (sourceDirectories.isEmpty) {
      updateProgress(ScanProgressState.error, 0.0, '请先添加源代码目录');
      return;
    }

    try {
      updateProgress(ScanProgressState.scanning, 0.0, '正在扫描文件...');

      final config = ScanConfig(
        allowedExtensions: _allowedExtensions,
        excludedDirectories: _excludedDirectories,
      );

      final service = ScanService(config: config);
      final files = await service.scanDirectories(sourceDirectories);

      _scannedFiles
        ..clear()
        ..addAll(files);
      _selectedFiles.addAll(files.map((f) => f.path));

      updateProgress(
        ScanProgressState.completed,
        1.0,
        '扫描完成，共找到 ${files.length} 个文件',
      );
    } catch (e) {
      updateProgress(ScanProgressState.error, 0.0, '扫描失败: $e');
    }
  }

  void reset() {
    _progressState = ScanProgressState.idle;
    _progress = 0.0;
    _statusMessage = '';
    _scannedFiles.clear();
    _selectedFiles.clear();
    notifyListeners();
  }

  List<SourceFile> getSelectedFileObjects() {
    return _scannedFiles.where((f) => _selectedFiles.contains(f.path)).toList();
  }

}
