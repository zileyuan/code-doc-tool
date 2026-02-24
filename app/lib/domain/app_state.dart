import 'dart:io';
import 'package:flutter/foundation.dart';
import 'models/source_file.dart';
import 'models/clean_code.dart';
import 'models/export_config.dart';
import 'models/scan_config.dart';
import 'services/scan_service.dart';
import 'services/clean_service.dart';
import 'services/export_service.dart';
import 'services/update_service.dart';

enum ProgressState { idle, scanning, cleaning, exporting, completed, error }

enum UpdateState { idle, checking, available, downloading, ready, error }

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

  UpdateState updateState = UpdateState.idle;
  String updateMessage = '';
  double downloadProgress = 0.0;
  ReleaseInfo? latestRelease;
  String? downloadedUpdatePath;
  String? extractedUpdatePath;
  bool _cancelDownload = false;

  final CleanService _cleanService;
  final ExportService _exportService;
  final UpdateService _updateService;

  AppState()
    : _cleanService = CleanService(),
      _exportService = ExportService(),
      _updateService = UpdateService();

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

  Future<void> checkForUpdates() async {
    updateState = UpdateState.checking;
    updateMessage = '正在检查更新...';
    notifyListeners();

    try {
      latestRelease = await _updateService.fetchLatestRelease();

      if (latestRelease == null) {
        updateState = UpdateState.error;
        updateMessage = '无法获取版本信息';
        notifyListeners();
        return;
      }

      if (_updateService.isNewerVersion('v$version', latestRelease!.version)) {
        updateState = UpdateState.available;
        updateMessage = '发现新版本 ${latestRelease!.version}';
      } else {
        updateState = UpdateState.idle;
        updateMessage = '已是最新版本';
      }
      notifyListeners();
    } catch (e) {
      updateState = UpdateState.error;
      updateMessage = '检查更新失败: $e';
      notifyListeners();
    }
  }

  Future<void> downloadUpdate() async {
    if (latestRelease == null) return;

    _cancelDownload = false;
    updateState = UpdateState.downloading;
    updateMessage = '正在下载更新...';
    downloadProgress = 0.0;
    notifyListeners();

    try {
      final downloadUrl = defaultTargetPlatform == TargetPlatform.macOS
          ? latestRelease!.downloadUrlMacos
          : latestRelease!.downloadUrlWindows;

      if (downloadUrl.isEmpty) {
        updateState = UpdateState.error;
        updateMessage = '未找到对应平台的更新包';
        notifyListeners();
        return;
      }

      downloadedUpdatePath = await _updateService.downloadUpdate(
        downloadUrl,
        latestRelease!.version,
        (progress) {
          downloadProgress = progress;
          updateMessage = '正在下载更新... ${(progress * 100).toStringAsFixed(0)}%';
          notifyListeners();
        },
        () => _cancelDownload,
      );

      if (_cancelDownload) {
        updateState = UpdateState.available;
        updateMessage = '下载已取消';
        notifyListeners();
        return;
      }

      if (downloadedUpdatePath == null) {
        updateState = UpdateState.error;
        updateMessage = '下载失败';
        notifyListeners();
        return;
      }

      final extractPath = await _updateService.extractAndPrepare(
        downloadedUpdatePath!,
        latestRelease!.version,
      );
      if (extractPath == null) {
        updateState = UpdateState.error;
        updateMessage = '解压失败';
        notifyListeners();
        return;
      }

      extractedUpdatePath = extractPath;
      updateState = UpdateState.ready;
      updateMessage = '更新已准备就绪，点击"立即安装"完成更新';
      notifyListeners();
    } catch (e) {
      updateState = UpdateState.error;
      updateMessage = '下载更新失败: $e';
      notifyListeners();
    }
  }

  Future<void> installUpdate() async {
    if (extractedUpdatePath == null) return;

    try {
      final success = await _updateService.runUpdateScript(
        extractedUpdatePath!,
      );
      if (success) {
        updateMessage = '正在安装更新，应用即将关闭...';
        notifyListeners();
        await Future.delayed(const Duration(seconds: 1));
        exit(0);
      } else {
        updateState = UpdateState.error;
        updateMessage = '启动更新脚本失败';
        notifyListeners();
      }
    } catch (e) {
      updateState = UpdateState.error;
      updateMessage = '安装更新失败: $e';
      notifyListeners();
    }
  }

  void cancelDownload() {
    _cancelDownload = true;
  }
}
