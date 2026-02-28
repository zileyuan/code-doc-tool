import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/app_state.dart';

class DirectorySelectionWidget extends StatelessWidget {
  const DirectorySelectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step 1: 配置源代码目录',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Consumer<AppState>(
              builder: (context, state, child) {
                return Column(
                  children: [
                    if (state.sourceDirectories.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: state.sourceDirectories.length,
                          itemBuilder: (context, index) {
                            final dir = state.sourceDirectories[index];
                            return ListTile(
                              dense: true,
                              title: Text(
                                dir,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => state.removeDirectory(dir),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _addDirectory(context),
                          icon: const Icon(Icons.add),
                          label: const Text('添加目录'),
                        ),
                        if (state.sourceDirectories.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => state.clearDirectories(),
                            child: const Text('清空'),
                          ),
                        ],
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addDirectory(BuildContext context) async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择源代码目录',
      );
      if (result != null && context.mounted) {
        context.read<AppState>().addDirectory(result);
      }
    } catch (e) {
      debugPrint('目录选择失败: $e');
    }
  }
}
