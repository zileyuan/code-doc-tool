import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/app_state.dart';

class UpdateDialogWidget {
  static Future<void> show(BuildContext context) async {
    final state = context.read<AppState>();
    await state.checkForUpdates();

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => const _UpdateDialogContent(),
    );
  }
}

class _UpdateDialogContent extends StatelessWidget {
  const _UpdateDialogContent();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('检查更新'),
      content: Consumer<AppState>(
        builder: (context, state, child) {
          switch (state.updateState) {
            case UpdateState.idle:
              return const Text('正在检查...');
            case UpdateState.checking:
              return const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('正在检查更新...'),
                ],
              );
            case UpdateState.available:
              return _buildUpdateAvailable(context, state);
            case UpdateState.downloading:
              return _buildDownloading(context, state);
            case UpdateState.ready:
              return _buildReadyToInstall(context, state);
            case UpdateState.error:
              return Text('检查失败: ${state.updateMessage}');
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _buildUpdateAvailable(BuildContext context, AppState state) {
    final release = state.latestRelease;
    if (release == null) {
      return const Text('已是最新版本');
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('发现新版本: ${release.version}'),
        const SizedBox(height: 8),
        Text('当前版本: ${state.appVersion}'),
        const SizedBox(height: 16),
        if (release.releaseNotes.isNotEmpty)
          Text('更新内容:\n${release.releaseNotes}'),
      ],
    );
  }

  Widget _buildDownloading(BuildContext context, AppState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LinearProgressIndicator(value: state.downloadProgress),
        const SizedBox(height: 12),
        Text('下载中: ${(state.downloadProgress * 100).toStringAsFixed(1)}%'),
      ],
    );
  }

  Widget _buildReadyToInstall(BuildContext context, AppState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 48),
        const SizedBox(height: 12),
        const Text('更新已下载，请重启应用以安装'),
      ],
    );
  }
}
