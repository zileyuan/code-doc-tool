import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/app_state.dart';

class ActionButtonsWidget extends StatelessWidget {
  const ActionButtonsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final isProcessing = state.progressState == ProgressState.scanning ||
            state.progressState == ProgressState.cleaning ||
            state.progressState == ProgressState.exporting;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: isProcessing ? null : () => _scanFiles(context),
              icon: const Icon(Icons.search),
              label: const Text('扫描文件'),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: isProcessing || state.selectedFiles.isEmpty
                  ? null
                  : () => _generateDocument(context),
              icon: const Icon(Icons.description),
              label: const Text('生成文档'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _scanFiles(BuildContext context) async {
    final state = context.read<AppState>();

    if (state.sourceDirectories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先添加源代码目录')),
      );
      return;
    }

    await state.scanFiles();
  }

  Future<void> _generateDocument(BuildContext context) async {
    final state = context.read<AppState>();

    if (state.selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择要导出的文件')),
      );
      return;
    }

    if (state.softwareName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入软件名称')),
      );
      return;
    }

    if (state.version.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入版本号')),
      );
      return;
    }

    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: '保存Word文档',
      fileName: '${state.softwareName}_${state.version}.docx',
      type: FileType.custom,
      allowedExtensions: ['docx'],
    );

    if (outputPath != null && context.mounted) {
      await state.cleanAndExport(outputPath);
    }
  }
}
