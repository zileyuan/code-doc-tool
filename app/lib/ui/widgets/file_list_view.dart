import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/app_state.dart';
import '../../domain/models/source_file.dart';

class FileListView extends StatefulWidget {
  const FileListView({super.key});

  @override
  State<FileListView> createState() => _FileListViewState();
}

class _FileListViewState extends State<FileListView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            _buildFileList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final filteredFiles = _getFilteredFiles(state);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '文件列表 (${state.selectedFiles.length}/${state.scannedFiles.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (state.scannedFiles.isNotEmpty) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索文件...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                      : null,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.select_all, size: 18),
                    label: const Text('全选'),
                    onPressed: () => state.selectAllFiles(),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.deselect, size: 18),
                    label: const Text('取消全选'),
                    onPressed: () => state.deselectAllFiles(),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.filter_list, size: 18),
                    label: const Text('按扩展名选择'),
                    onPressed: () => _showSelectByExtension(context, state),
                  ),
                ],
              ),
            ],
            if (filteredFiles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '显示 ${filteredFiles.length} 个文件',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFileList(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        if (state.scannedFiles.isEmpty) {
          return const SizedBox.shrink();
        }

        final filteredFiles = _getFilteredFiles(state);

        return Container(
          height: 280,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            itemCount: filteredFiles.length,
            itemBuilder: (context, index) {
              final file = filteredFiles[index];
              return _FileTile(file: file);
            },
          ),
        );
      },
    );
  }

  List<SourceFile> _getFilteredFiles(AppState state) {
    if (_searchQuery.isEmpty) {
      return state.scannedFiles;
    }
    final query = _searchQuery.toLowerCase();
    return state.scannedFiles.where((file) {
      return file.name.toLowerCase().contains(query) ||
          file.relativePath.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _showSelectByExtension(BuildContext context, AppState state) async {
    final extensions = <String>{};
    for (final file in state.scannedFiles) {
      final ext = file.extension.toLowerCase();
      extensions.add(ext);
    }

    final selectedExtension = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('按扩展名选择'),
        content: Wrap(
          spacing: 8,
          children: extensions.map((ext) {
            return ActionChip(
              label: Text(ext),
              onPressed: () => Navigator.pop(context, ext),
            );
          }).toList(),
        ),
      ),
    );

    if (selectedExtension != null) {
      for (final file in state.scannedFiles) {
        if (file.extension.toLowerCase() == selectedExtension) {
          state.selectFile(file.path, true);
        }
      }
    }
  }
}

class _FileTile extends StatelessWidget {
  final SourceFile file;

  const _FileTile({required this.file});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final isSelected = state.selectedFiles.contains(file.path);

        return CheckboxListTile(
          value: isSelected,
          onChanged: (checked) =>
              state.selectFile(file.path, checked ?? false),
          title: Text(file.name, style: const TextStyle(fontSize: 13)),
          subtitle: Text(
            '${file.displaySize}  |  ${file.encoding}  |  ${file.relativePath}',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
        );
      },
    );
  }
}
