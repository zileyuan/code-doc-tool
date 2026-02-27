import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/app_state.dart';
import '../../domain/models/scan_config.dart';

class FilterConfigWidget extends StatelessWidget {
  const FilterConfigWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step 3: 文件过滤设置',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Consumer<AppState>(
              builder: (context, state, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExtensionsRow(context, state),
                    const SizedBox(height: 12),
                    _buildExcludeDirsRow(context, state),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtensionsRow(BuildContext context, AppState state) {
    return Row(
      children: [
        const Text(
          '文件后缀：',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ..._getCommonExtensions(state).map((ext) {
                final isSelected = state.allowedExtensions.contains(ext);
                return FilterChip(
                  label: Text(ext),
                  selected: isSelected,
                  onSelected: (selected) {
                    _toggleExtension(state, ext, selected);
                  },
                );
              }),
              ActionChip(
                label: const Text('自定义'),
                avatar: const Icon(Icons.add, size: 16),
                onPressed: () => _showCustomExtensionDialog(context, state),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExcludeDirsRow(BuildContext context, AppState state) {
    return Row(
      children: [
        const Text(
          '排除目录：',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ...state.excludedDirectories.take(5).map((dir) {
                return Chip(
                  label: Text(dir, style: const TextStyle(fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () {
                    final newDirs = Set<String>.from(state.excludedDirectories);
                    newDirs.remove(dir);
                    state.updateFilterConfig(excludedDirectories: newDirs);
                  },
                );
              }),
              if (state.excludedDirectories.length > 5)
                _buildMoreIndicator(state),
              if (state.excludedDirectories.isNotEmpty)
                Text(
                  '共 ${state.excludedDirectories.length} 个',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ActionChip(
                label: const Text('管理'),
                avatar: const Icon(Icons.settings, size: 16),
                onPressed: () => _showExcludeDirsDialog(context, state),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMoreIndicator(AppState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '+${state.excludedDirectories.length - 5}',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  List<String> _getCommonExtensions(AppState state) {
    final allExtensions = <String>{
      ...ScanConfig.defaultExtensions,
      ...state.allowedExtensions,
    };
    return allExtensions.toList()..sort();
  }

  void _toggleExtension(AppState state, String ext, bool selected) {
    final newExtensions = Set<String>.from(state.allowedExtensions);
    if (selected) {
      newExtensions.add(ext);
    } else {
      newExtensions.remove(ext);
    }
    state.updateFilterConfig(allowedExtensions: newExtensions);
  }

  Future<void> _showCustomExtensionDialog(BuildContext context, AppState state) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加自定义后缀'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '例如：.vue, .svelte',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('添加'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final extensions = result
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && e.startsWith('.'));
      final newExtensions = Set<String>.from(state.allowedExtensions)
        ..addAll(extensions);
      state.updateFilterConfig(allowedExtensions: newExtensions);
    }
    controller.dispose();
  }

  Future<void> _showExcludeDirsDialog(BuildContext context, AppState state) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('管理排除目录'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入目录名，例如：vendor',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('添加'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final newDirs = Set<String>.from(state.excludedDirectories)..add(result);
      state.updateFilterConfig(excludedDirectories: newDirs);
    }
    controller.dispose();
  }
}
