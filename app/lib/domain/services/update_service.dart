import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';

class ReleaseInfo {
  final String version;
  final String downloadUrlMacos;
  final String downloadUrlWindows;
  final String releaseNotes;

  ReleaseInfo({
    required this.version,
    required this.downloadUrlMacos,
    required this.downloadUrlWindows,
    required this.releaseNotes,
  });
}

class UpdateService {
  static const String _githubApiUrl =
      'https://api.github.com/repos/zileyuan/code-doc-tool/releases/latest';

  Future<ReleaseInfo?> fetchLatestRelease() async {
    try {
      final response = await http.get(Uri.parse(_githubApiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final version = data['tag_name'] as String?;
        final body = data['body'] as String?;

        if (version == null) return null;

        String macosUrl = '';
        String windowsUrl = '';

        for (final asset in data['assets'] ?? []) {
          final name = asset['name'] as String?;
          final url = asset['browser_download_url'] as String?;
          if (name != null && url != null) {
            if (name.contains('macos')) {
              macosUrl = url;
            } else if (name.contains('windows')) {
              windowsUrl = url;
            }
          }
        }

        return ReleaseInfo(
          version: version,
          downloadUrlMacos: macosUrl,
          downloadUrlWindows: windowsUrl,
          releaseNotes: body ?? '',
        );
      }
      return null;
    } catch (e) {
      debugPrint('获取最新版本失败: $e');
      return null;
    }
  }

  bool isNewerVersion(String currentVersion, String latestVersion) {
    final current = _parseVersion(currentVersion);
    final latest = _parseVersion(latestVersion);

    if (latest[0] != current[0]) return latest[0] > current[0];
    if (latest[1] != current[1]) return latest[1] > current[1];
    return latest[2] > current[2];
  }

  /// Parse version string to list of integers.
  /// Handles versions with or without 'v' prefix (e.g., 'v1.2.3' or '1.2.3').
  List<int> _parseVersion(String version) {
    // Remove 'v' or 'V' prefix if present
    final cleanVersion = version.startsWith(RegExp(r'[vV]')) 
        ? version.substring(1) 
        : version;
    final parts = cleanVersion.split('.');
    return [
      int.tryParse(parts[0]) ?? 0,
      parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0,
    ];
  }

  Future<String?> downloadUpdate(
    String url,
    String version,
    Function(double) onProgress,
    bool Function() isCancelled,
  ) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final platform = Platform.isMacOS ? 'macos' : 'windows';
      final fileName = 'code-doc-tool-$version-$platform.zip';
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);

      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }

      if (await file.exists()) {
        await file.delete();
      }

      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        return null;
      }

      final contentLength = response.contentLength ?? 0;
      int downloaded = 0;

      final sink = file.openWrite();
      try {
        await for (final chunk in response.stream) {
          if (isCancelled()) {
            await sink.close();
            if (await file.exists()) {
              await file.delete();
            }
            return null;
          }
          sink.add(chunk);
          downloaded += chunk.length;
          if (contentLength > 0) {
            onProgress(downloaded / contentLength);
          }
        }
      } finally {
        await sink.close();
      }

      if (isCancelled()) {
        if (await file.exists()) {
          await file.delete();
        }
        return null;
      }

      if (await file.exists()) {
        final length = await file.length();
        if (length > 0) {
          return filePath;
        }
      }
      return null;
    } catch (e) {
      debugPrint('下载更新失败: $e');
      return null;
    }
  }

  Future<String?> extractAndPrepare(String zipPath, String version) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final extractDirName = 'code-doc-tool-$version';
      final extractDir = Directory('${tempDir.path}/$extractDirName');
      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
      await extractDir.create();

      final zipFile = File(zipPath);
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filePath = '${extractDir.path}/${file.name}';
        if (file.isFile) {
          final outFile = File(filePath);
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(filePath).create(recursive: true);
        }
      }

      return extractDir.path;
    } catch (e) {
      debugPrint('解压更新包失败: $e');
      return null;
    }
  }
  String getCurrentAppPath() {
    final executablePath = Platform.resolvedExecutable;
    if (Platform.isMacOS) {
      return executablePath.replaceAll('/Contents/MacOS/code_doc_tool', '');
    } else {
      return File(executablePath).parent.path;
    }
  }

  Future<bool> runUpdateScript(String extractPath) async {
    try {
      final currentAppPath = getCurrentAppPath();
      String scriptPath;
      List<String> args;

      if (Platform.isMacOS) {
        final newAppPath = '$extractPath/code_doc_tool.app';
        scriptPath = '$extractPath/update/update.sh';
        args = [currentAppPath, newAppPath];

        final scriptFile = File(scriptPath);
        if (!await scriptFile.exists()) {
          return false;
        }

        await Process.run('chmod', ['+x', scriptPath]);
      } else {
        scriptPath = '$extractPath/update.bat';
        args = [currentAppPath, extractPath];
      }

      await Process.start(scriptPath, args, mode: ProcessStartMode.detached);

      return true;
    } catch (e) {
      debugPrint('运行更新脚本失败: $e');
      return false;
    }
  }
}
