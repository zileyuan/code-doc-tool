import 'dart:io';

import 'package:flutter/foundation.dart';
import '../services/update_service.dart';

enum UpdateState { idle, checking, available, downloading, ready, error }

class UpdateNotifier extends ChangeNotifier {
  UpdateState _updateState = UpdateState.idle;
  String _updateMessage = '';
  double _downloadProgress = 0.0;
  ReleaseInfo? _latestRelease;
  String? _downloadedUpdatePath;
  String? _extractedUpdatePath;
  bool _cancelDownload = false;

  final UpdateService _updateService;

  UpdateNotifier() : _updateService = UpdateService();

  UpdateState get updateState => _updateState;

  String get updateMessage => _updateMessage;

  double get downloadProgress => _downloadProgress;

  ReleaseInfo? get latestRelease => _latestRelease;

  String? get downloadedUpdatePath => _downloadedUpdatePath;

  String? get extractedUpdatePath => _extractedUpdatePath;

  bool get isUpdateAvailable => _updateState == UpdateState.available;

  bool get isDownloading => _updateState == UpdateState.downloading;

  bool get isReadyToInstall => _updateState == UpdateState.ready;

  bool get hasError => _updateState == UpdateState.error;

  Future<void> checkForUpdates(String currentVersion) async {
    _updateState = UpdateState.checking;
    _updateMessage = '正在检查更新...';
    notifyListeners();

    try {
      _latestRelease = await _updateService.fetchLatestRelease();

      if (_latestRelease == null) {
        _updateState = UpdateState.error;
        _updateMessage = '无法获取版本信息';
        notifyListeners();
        return;
      }

      if (_updateService.isNewerVersion('v$currentVersion', _latestRelease!.version)) {
        _updateState = UpdateState.available;
        _updateMessage = '发现新版本 ${_latestRelease!.version}';
      } else {
        _updateState = UpdateState.idle;
        _updateMessage = '已是最新版本';
      }
      notifyListeners();
    } catch (e) {
      _updateState = UpdateState.error;
      _updateMessage = '检查更新失败: $e';
      notifyListeners();
    }
  }

  Future<void> downloadUpdate() async {
    if (_latestRelease == null) return;

    _cancelDownload = false;
    _updateState = UpdateState.downloading;
    _updateMessage = '正在下载更新...';
    _downloadProgress = 0.0;
    notifyListeners();

    try {
      final downloadUrl = defaultTargetPlatform == TargetPlatform.macOS
          ? _latestRelease!.downloadUrlMacos
          : _latestRelease!.downloadUrlWindows;

      if (downloadUrl.isEmpty) {
        _updateState = UpdateState.error;
        _updateMessage = '未找到对应平台的更新包';
        notifyListeners();
        return;
      }

      _downloadedUpdatePath = await _updateService.downloadUpdate(
        downloadUrl,
        _latestRelease!.version,
        (progress) {
          _downloadProgress = progress;
          _updateMessage = '正在下载更新... ${(progress * 100).toStringAsFixed(0)}%';
          notifyListeners();
        },
        () => _cancelDownload,
      );

      if (_cancelDownload) {
        _updateState = UpdateState.available;
        _updateMessage = '下载已取消';
        notifyListeners();
        return;
      }

      if (_downloadedUpdatePath == null) {
        _updateState = UpdateState.error;
        _updateMessage = '下载失败';
        notifyListeners();
        return;
      }

      final extractPath = await _updateService.extractAndPrepare(
        _downloadedUpdatePath!,
        _latestRelease!.version,
      );
      if (extractPath == null) {
        _updateState = UpdateState.error;
        _updateMessage = '解压失败';
        notifyListeners();
        return;
      }

      _extractedUpdatePath = extractPath;
      _updateState = UpdateState.ready;
      _updateMessage = '更新已准备就绪，点击"立即安装"完成更新';
      notifyListeners();
    } catch (e) {
      _updateState = UpdateState.error;
      _updateMessage = '下载更新失败: $e';
      notifyListeners();
    }
  }

  Future<void> installUpdate() async {
    if (_extractedUpdatePath == null) return;

    try {
      final success = await _updateService.runUpdateScript(_extractedUpdatePath!);
      if (success) {
        _updateMessage = '正在安装更新，应用即将关闭...';
        notifyListeners();
        await Future.delayed(const Duration(seconds: 1));
        exit(0);
      } else {
        _updateState = UpdateState.error;
        _updateMessage = '启动更新脚本失败';
        notifyListeners();
      }
    } catch (e) {
      _updateState = UpdateState.error;
      _updateMessage = '安装更新失败: $e';
      notifyListeners();
    }
  }

  void cancelDownload() {
    _cancelDownload = true;
  }

  void reset() {
    _updateState = UpdateState.idle;
    _updateMessage = '';
    _downloadProgress = 0.0;
    _latestRelease = null;
    _downloadedUpdatePath = null;
    _extractedUpdatePath = null;
    _cancelDownload = false;
    notifyListeners();
  }

}
