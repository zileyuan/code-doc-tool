import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';

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

  List<int> _parseVersion(String version) {
    final cleanVersion = version.replaceAll('v', '');
    final parts = cleanVersion.split('.');
    return [
      int.tryParse(parts[0]) ?? 0,
      parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0,
    ];
  }

  Future<String?> downloadUpdate(
    String url,
    Function(double) onProgress,
  ) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = url.split('/').last;
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);

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
          sink.add(chunk);
          downloaded += chunk.length;
          if (contentLength > 0) {
            onProgress(downloaded / contentLength);
          }
        }
      } finally {
        await sink.close();
      }

      if (await file.exists() && await file.length() > 0) {
        return filePath;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> extractAndPrepare(String zipPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final extractDir = Directory('${tempDir.path}/update_extract');
      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
      await extractDir.create();

      final bytes = await File(zipPath).readAsBytes();
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

      return true;
    } catch (e) {
      return false;
    }
  }

  String getUpdateScriptPath() {
    final scriptDir = Platform.resolvedExecutable;
    if (Platform.isMacOS) {
      return '${scriptDir.replaceAll('/Contents/MacOS/code_doc_tool', '')}/update.sh';
    } else {
      return '${File(scriptDir).parent.path}/update.bat';
    }
  }
}
