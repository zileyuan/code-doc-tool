import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/app_state.dart';
import '../../domain/models/source_file.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _softwareNameController = TextEditingController();
  final TextEditingController _versionController = TextEditingController();
  String _searchQuery = '';
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final state = context.read<AppState>();
      _softwareNameController.text = state.softwareName;
      _versionController.text = state.version;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _softwareNameController.dispose();
    _versionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('软著代码文档生成工具'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '检查更新',
            onPressed: () => _showUpdateDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDirectorySelection(context),
            const SizedBox(height: 16),
            _buildExportConfig(context),
            const SizedBox(height: 16),
            _buildFilterConfig(context),
            const SizedBox(height: 16),
            _buildActionButtons(context),
            const SizedBox(height: 16),
            _buildFileList(context),
            const SizedBox(height: 16),
            _buildProgressBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectorySelection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step 1: 配置源代码目录',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                            final path = state.sourceDirectories[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.folder,
                                    size: 20,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      path,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        state.removeDirectory(path),
                                    tooltip: '移除',
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('添加目录'),
                          onPressed: () => _addDirectory(context),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: state.sourceDirectories.isEmpty
                              ? null
                              : () => state.clearDirectories(),
                          child: const Text('清空列表'),
                        ),
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

  Widget _buildExportConfig(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step 2: 配置导出参数',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Consumer<AppState>(
              builder: (context, state, child) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _softwareNameController,
                            decoration: const InputDecoration(
                              labelText: '软件名称 *',
                              hintText: '例如：软著代码文档生成工具',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (value) =>
                                state.updateConfig(softwareName: value),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: '版本号',
                              hintText: '例如：1.0.0',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            controller: _versionController,
                            onChanged: (value) =>
                                state.updateConfig(version: value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '固定设置：50行/页，最多60页',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
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

  Widget _buildFilterConfig(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step 3: 文件过滤设置',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Consumer<AppState>(
              builder: (context, state, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                              ..._getCommonExtensions().map((ext) {
                                final isSelected = state.allowedExtensions
                                    .contains(ext);
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
                                onPressed: () =>
                                    _showCustomExtensionDialog(context, state),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
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
                                  label: Text(
                                    dir,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  deleteIcon: const Icon(Icons.close, size: 14),
                                  onDeleted: () {
                                    final newDirs = Set<String>.from(
                                      state.excludedDirectories,
                                    );
                                    newDirs.remove(dir);
                                    state.updateFilterConfig(
                                      excludedDirectories: newDirs,
                                    );
                                  },
                                );
                              }),
                              if (state.excludedDirectories.length > 5)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
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
                                ),
                              if (state.excludedDirectories.isNotEmpty)
                                Text(
                                  '共 ${state.excludedDirectories.length} 个',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ActionChip(
                                label: const Text('管理'),
                                avatar: const Icon(Icons.settings, size: 16),
                                onPressed: () =>
                                    _showExcludeDirsDialog(context, state),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildActionButtons(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final isProcessing =
            state.progressState == ProgressState.scanning ||
            state.progressState == ProgressState.cleaning ||
            state.progressState == ProgressState.exporting;

        final canScan = state.sourceDirectories.isNotEmpty && !isProcessing;
        final canExport = state.scannedFiles.isNotEmpty && !isProcessing;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.search),
                  label: const Text('扫描文件'),
                  onPressed: canScan ? () => state.scanFiles() : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.description),
                  label: const Text('生成文档'),
                  onPressed: canExport
                      ? () => _generateDocument(context)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                ),
                const Spacer(),
                if (isProcessing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            if (!canScan || !canExport)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  !canScan ? '💡 请先添加源代码目录' : '💡 请先扫描文件，并输入软件名称',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFileList(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '文件列表',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Consumer<AppState>(
                  builder: (context, state, child) {
                    if (state.scannedFiles.isEmpty)
                      return const SizedBox.shrink();
                    return Text(
                      '已选择 ${state.totalSelectedFiles} / ${state.totalScannedFiles}',
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Consumer<AppState>(
              builder: (context, state, child) {
                if (state.scannedFiles.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '请先添加目录并扫描文件',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final filteredFiles = _searchQuery.isEmpty
                    ? state.scannedFiles
                    : state.scannedFiles
                          .where(
                            (f) =>
                                f.name.toLowerCase().contains(
                                  _searchQuery.toLowerCase(),
                                ) ||
                                f.relativePath.toLowerCase().contains(
                                  _searchQuery.toLowerCase(),
                                ),
                          )
                          .toList();

                return Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '搜索文件...',
                        prefixIcon: const Icon(Icons.search),
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
                          onPressed: () =>
                              _showSelectByExtension(context, state),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 280,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: filteredFiles.length,
                        itemBuilder: (context, index) {
                          final file = filteredFiles[index];
                          return _buildFileTile(context, file, state);
                        },
                      ),
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

  Widget _buildFileTile(BuildContext context, SourceFile file, AppState state) {
    final isSelected = state.selectedFiles.contains(file.path);

    return CheckboxListTile(
      value: isSelected,
      onChanged: (checked) => state.selectFile(file.path, checked ?? false),
      title: Text(file.name, style: const TextStyle(fontSize: 13)),
      subtitle: Text(
        '${file.displaySize}  |  ${file.encoding}  |  ${file.relativePath}',
        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
      ),
      secondary: Icon(_getFileIcon(file.extension), size: 20),
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        if (state.progressState == ProgressState.idle) {
          return const SizedBox.shrink();
        }

        Color progressColor;
        switch (state.progressState) {
          case ProgressState.completed:
            progressColor = Colors.green;
            break;
          case ProgressState.error:
            progressColor = Colors.red;
            break;
          default:
            progressColor = Colors.blue;
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: state.progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(progressColor),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${(state.progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: progressColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        state.statusMessage,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                if (state.progressState == ProgressState.completed ||
                    state.progressState == ProgressState.error)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: ElevatedButton(
                      onPressed: () => state.reset(),
                      child: const Text('重置'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addDirectory(BuildContext context) async {
    debugPrint('===== _addDirectory called =====');
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择源代码目录',
      );
      debugPrint('===== FilePicker result: $result =====');
      if (result != null && context.mounted) {
        context.read<AppState>().addDirectory(result);
        debugPrint('===== Directory added: $result =====');
      }
    } catch (e, stackTrace) {
      debugPrint('===== Error in _addDirectory: $e =====');
      debugPrint('StackTrace: $stackTrace');
    }
  }

  Future<void> _generateDocument(BuildContext context) async {
    debugPrint('===== _generateDocument called =====');
    final state = context.read<AppState>();

    debugPrint('===== selectedFiles: ${state.selectedFiles.length} =====');
    debugPrint('===== softwareName: ${state.softwareName} =====');

    if (state.selectedFiles.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先选择要导出的文件')));
      return;
    }

    if (state.softwareName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入软件名称')));
      return;
    }

    debugPrint('===== Opening save file dialog =====');
    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: '保存Word文档',
      fileName: '${state.softwareName}_${state.version}.docx',
      type: FileType.custom,
      allowedExtensions: ['docx'],
    );

    debugPrint('===== outputPath: $outputPath =====');
    if (outputPath != null && context.mounted) {
      await state.cleanAndExport(outputPath);
    }
  }

  List<String> _getCommonExtensions() {
    return [
      '.dart',
      '.java',
      '.kt',
      '.py',
      '.js',
      '.ts',
      '.go',
      '.cpp',
      '.c',
      '.cs',
      '.swift',
      '.rs',
    ];
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

  void _showCustomExtensionDialog(BuildContext context, AppState state) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加自定义后缀'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '.xxx',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final ext = controller.text.trim();
              if (ext.isNotEmpty) {
                final normalized = ext.startsWith('.') ? ext : '.$ext';
                final newExtensions = Set<String>.from(state.allowedExtensions);
                newExtensions.add(normalized);
                state.updateFilterConfig(allowedExtensions: newExtensions);
              }
              Navigator.pop(context);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showExcludeDirsDialog(BuildContext context, AppState state) {
    final addController = TextEditingController();
    final searchController = TextEditingController();
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final filteredDirs = searchQuery.isEmpty
              ? state.excludedDirectories.toList()
              : state.excludedDirectories
                    .where(
                      (dir) =>
                          dir.toLowerCase().contains(searchQuery.toLowerCase()),
                    )
                    .toList();

          return AlertDialog(
            title: Row(
              children: [
                const Text('管理排除目录'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '共 ${state.excludedDirectories.length} 个',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: addController,
                          decoration: const InputDecoration(
                            hintText: '输入目录名（如：node_modules）',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          onSubmitted: (value) {
                            final dir = value.trim();
                            if (dir.isNotEmpty &&
                                !state.excludedDirectories.contains(dir)) {
                              final newDirs = Set<String>.from(
                                state.excludedDirectories,
                              );
                              newDirs.add(dir);
                              state.updateFilterConfig(
                                excludedDirectories: newDirs,
                              );
                              addController.clear();
                              setState(() {});
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final dir = addController.text.trim();
                          if (dir.isNotEmpty &&
                              !state.excludedDirectories.contains(dir)) {
                            final newDirs = Set<String>.from(
                              state.excludedDirectories,
                            );
                            newDirs.add(dir);
                            state.updateFilterConfig(
                              excludedDirectories: newDirs,
                            );
                            addController.clear();
                            setState(() {});
                          }
                        },
                        child: const Text('添加'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: '搜索筛选目录名...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                searchController.clear();
                                setState(() => searchQuery = '');
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => searchQuery = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        searchQuery.isEmpty
                            ? '排除目录列表：'
                            : '筛选结果（${filteredDirs.length}）：',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      if (filteredDirs.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            final newDirs = Set<String>.from(
                              state.excludedDirectories,
                            );
                            for (final dir in filteredDirs) {
                              newDirs.remove(dir);
                            }
                            state.updateFilterConfig(
                              excludedDirectories: newDirs,
                            );
                            setState(() {});
                          },
                          child: const Text(
                            '删除筛选结果',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: filteredDirs.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                searchQuery.isEmpty ? '暂无排除目录' : '未找到匹配的目录',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredDirs.length,
                            itemBuilder: (context, index) {
                              final dir = filteredDirs[index];
                              return ListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                title: Text(
                                  dir,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () {
                                    final newDirs = Set<String>.from(
                                      state.excludedDirectories,
                                    );
                                    newDirs.remove(dir);
                                    state.updateFilterConfig(
                                      excludedDirectories: newDirs,
                                    );
                                    setState(() {});
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  addController.dispose();
                  searchController.dispose();
                  Navigator.pop(context);
                },
                child: const Text('关闭'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSelectByExtension(BuildContext context, AppState state) {
    final extensions = <String>{};
    for (final file in state.scannedFiles) {
      extensions.add(file.extension);
    }
    final sortedExtensions = extensions.toList()..sort();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('按扩展名选择'),
            content: SizedBox(
              width: 350,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sortedExtensions.map((ext) {
                  final filesWithExt = state.scannedFiles
                      .where((f) => f.extension == ext)
                      .toList();
                  final selectedCount = filesWithExt
                      .where((f) => state.selectedFiles.contains(f.path))
                      .length;
                  final totalCount = filesWithExt.length;
                  final isSelected = selectedCount == totalCount;
                  final isPartial =
                      selectedCount > 0 && selectedCount < totalCount;

                  return FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(ext),
                        const SizedBox(width: 4),
                        Text(
                          '($selectedCount/$totalCount)',
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? Colors.black87
                                : Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected || isPartial,
                    showCheckmark: isSelected,
                    onSelected: (selected) {
                      for (final file in filesWithExt) {
                        state.selectFile(file.path, selected);
                      }
                      setState(() {});
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  state.deselectAllFiles();
                  setState(() {});
                },
                child: const Text('取消全选'),
              ),
              TextButton(
                onPressed: () {
                  state.selectAllFiles();
                  setState(() {});
                },
                child: const Text('全选'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case '.dart':
        return Icons.code;
      case '.java':
      case '.kt':
        return Icons.coffee;
      case '.js':
      case '.ts':
      case '.jsx':
      case '.tsx':
        return Icons.javascript;
      case '.py':
        return Icons.psychology;
      case '.go':
        return Icons.code;
      case '.rs':
        return Icons.code;
      case '.html':
      case '.htm':
        return Icons.html;
      case '.css':
        return Icons.style;
      case '.json':
        return Icons.data_object;
      case '.yaml':
      case '.yml':
        return Icons.list_alt;
      case '.md':
        return Icons.description;
      case '.sql':
        return Icons.storage;
      case '.sh':
      case '.bash':
        return Icons.terminal;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _showUpdateDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const UpdateDialog());
  }
}

class UpdateDialog extends StatefulWidget {
  const UpdateDialog({super.key});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().checkForUpdates();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.system_update),
              const SizedBox(width: 8),
              const Text('检查更新'),
              const Spacer(),
              Text(
                '当前版本: v${state.version}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          content: SizedBox(width: 500, child: _buildContent(state)),
          actions: _buildActions(state),
        );
      },
    );
  }

  Widget _buildContent(AppState state) {
    switch (state.updateState) {
      case UpdateState.checking:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在检查更新...'),
          ],
        );

      case UpdateState.available:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.new_releases, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  '发现新版本 ${state.latestRelease?.version ?? ""}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: Text(
                  state.latestRelease?.releaseNotes ?? '',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        );

      case UpdateState.downloading:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: state.downloadProgress),
            const SizedBox(height: 16),
            Text(state.updateMessage),
          ],
        );

      case UpdateState.ready:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green[700], size: 48),
            const SizedBox(height: 16),
            const Text('更新已下载完成'),
            const SizedBox(height: 8),
            Text(
              '请关闭当前应用，然后从下载目录运行新版本',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        );

      case UpdateState.error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, color: Colors.red[700], size: 48),
            const SizedBox(height: 16),
            Text(state.updateMessage),
          ],
        );

      case UpdateState.idle:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green[700], size: 48),
            const SizedBox(height: 16),
            Text(
              state.updateMessage.isNotEmpty ? state.updateMessage : '已是最新版本',
            ),
          ],
        );
    }
  }

  List<Widget> _buildActions(AppState state) {
    switch (state.updateState) {
      case UpdateState.available:
        return [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('稍后更新'),
          ),
          ElevatedButton(
            onPressed: () => state.downloadUpdate(),
            child: const Text('立即下载'),
          ),
        ];

      case UpdateState.downloading:
        return [
          TextButton(
            onPressed: () {
              state.cancelDownload();
              Navigator.pop(context);
            },
            child: const Text('取消'),
          ),
        ];

      case UpdateState.ready:
        return [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ];

      case UpdateState.error:
        return [
          TextButton(
            onPressed: () {
              state.updateState = UpdateState.idle;
              state.updateMessage = '';
              Navigator.pop(context);
            },
            child: const Text('关闭'),
          ),
          ElevatedButton(
            onPressed: () => state.checkForUpdates(),
            child: const Text('重试'),
          ),
        ];

      default:
        return [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ];
    }
  }
}
