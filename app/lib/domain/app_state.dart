import 'package:flutter/foundation.dart';
import 'models/source_file.dart';
import 'models/clean_code.dart';
import 'services/update_service.dart';
import 'notifiers/directory_notifier.dart';
import 'notifiers/scan_notifier.dart';
import 'notifiers/export_notifier.dart';
import 'notifiers/update_notifier.dart';

export 'notifiers/directory_notifier.dart';
export 'notifiers/scan_notifier.dart';
export 'notifiers/export_notifier.dart';
export 'notifiers/update_notifier.dart';

/// 兼容旧代码的枚举别名
typedef ProgressState = ScanProgressState;

class AppState extends ChangeNotifier {
  final DirectoryNotifier directoryNotifier;
  final ScanNotifier scanNotifier;
  final ExportNotifier exportNotifier;
  final UpdateNotifier updateNotifier;

  AppState()
    : directoryNotifier = DirectoryNotifier(),
      scanNotifier = ScanNotifier(),
      exportNotifier = ExportNotifier(),
      updateNotifier = UpdateNotifier() {
    _setupListeners();
  }

  void _setupListeners() {
    directoryNotifier.addListener(notifyListeners);
    scanNotifier.addListener(notifyListeners);
    exportNotifier.addListener(notifyListeners);
    updateNotifier.addListener(notifyListeners);
  }

  @override
  void dispose() {
    directoryNotifier.removeListener(notifyListeners);
    scanNotifier.removeListener(notifyListeners);
    exportNotifier.removeListener(notifyListeners);
    updateNotifier.removeListener(notifyListeners);
    directoryNotifier.dispose();
    scanNotifier.dispose();
    exportNotifier.dispose();
    updateNotifier.dispose();
    super.dispose();
  }

  // ===== Directory Notifier Delegates =====
  List<String> get sourceDirectories => directoryNotifier.sourceDirectories;

  void addDirectory(String path) => directoryNotifier.addDirectory(path);

  void removeDirectory(String path) => directoryNotifier.removeDirectory(path);

  void clearDirectories() {
    directoryNotifier.clearDirectories();
    scanNotifier.reset();
  }

  // ===== Scan Notifier Delegates =====
  Set<String> get allowedExtensions => scanNotifier.allowedExtensions;
  Set<String> get excludedDirectories => scanNotifier.excludedDirectories;
  List<SourceFile> get scannedFiles => scanNotifier.scannedFiles;
  Set<String> get selectedFiles => scanNotifier.selectedFiles;
  ScanProgressState get progressState => scanNotifier.progressState;
  double get progress => scanNotifier.progress;
  String get statusMessage => scanNotifier.statusMessage;
  int get totalScannedFiles => scanNotifier.totalScannedFiles;
  int get totalSelectedFiles => scanNotifier.totalSelectedFiles;

  void selectFile(String path, bool selected) =>
      scanNotifier.selectFile(path, selected);

  void selectAllFiles() => scanNotifier.selectAllFiles();

  void deselectAllFiles() => scanNotifier.deselectAllFiles();

  void updateFilterConfig({
    Set<String>? allowedExtensions,
    Set<String>? excludedDirectories,
  }) => scanNotifier.updateFilterConfig(
        allowedExtensions: allowedExtensions,
        excludedDirectories: excludedDirectories,
      );

  void updateProgress(ScanProgressState state, double value, String message) =>
      scanNotifier.updateProgress(state, value, message);

  Future<void> scanFiles() async {
    await scanNotifier.scanFiles(directoryNotifier.sourceDirectories);
  }

  // ===== Export Notifier Delegates =====
  String get softwareName => exportNotifier.softwareName;
  String get version => exportNotifier.version;
  String get appVersion => exportNotifier.appVersion;
  int get linesPerPage => exportNotifier.linesPerPage;
  int get maxPages => exportNotifier.maxPages;
  int get maxTotalLines => exportNotifier.maxTotalLines;
  ExportProgressState get exportProgressState => exportNotifier.progressState;
  List<CleanCode> get cleanedCodes => exportNotifier.cleanedCodes;

  void updateConfig({String? softwareName, String? version}) =>
      exportNotifier.updateConfig(softwareName: softwareName, version: version);

  Future<void> cleanAndExport(String outputPath) async {
    final filesToClean = scanNotifier.getSelectedFileObjects();
    await exportNotifier.cleanAndExport(filesToClean, outputPath);
  }

  // ===== Update Notifier Delegates =====
  UpdateState get updateState => updateNotifier.updateState;
  String get updateMessage => updateNotifier.updateMessage;
  double get downloadProgress => updateNotifier.downloadProgress;
  ReleaseInfo? get latestRelease => updateNotifier.latestRelease;
  String? get downloadedUpdatePath => updateNotifier.downloadedUpdatePath;
  String? get extractedUpdatePath => updateNotifier.extractedUpdatePath;

  Future<void> checkForUpdates() async {
    await updateNotifier.checkForUpdates(exportNotifier.appVersion);
  }

  Future<void> downloadUpdate() async => updateNotifier.downloadUpdate();

  Future<void> installUpdate() async => updateNotifier.installUpdate();

  void cancelDownload() => updateNotifier.cancelDownload();

  // ===== Legacy Support =====
  void reset() {
    scanNotifier.reset();
    exportNotifier.reset();
  }
}
