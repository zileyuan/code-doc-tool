# UI界面设计文档

## 1. 界面整体布局

### 1.1 主窗口结构
```
┌─────────────────────────────────────────────────────────┐
│  [App Bar]  软著代码文档生成工具                    [设置]    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌───────────────────────────────────────────────┐     │
│  │  Step 1: 配置源代码目录                        │     │
│  │  ┌───────────────────────────────┬───┐       │     │
│  │  │ /path/to/source/code          │...│       │     │
│  │  └───────────────────────────────┴───┘       │     │
│  │  [+ 添加目录]  [清空列表]                     │     │
│  └───────────────────────────────────────────────┘     │
│                                                         │
│  ┌───────────────────────────────────────────────┐     │
│  │  Step 2: 配置导出参数                          │     │
│  │  软件名称: [____________________]              │     │
│  │  版本号:   [________]                          │     │
│  │  每页行数: [50] ▼                              │     │
│  │  最大页数: [60] ▼  (代码不足则按实际页数)     │     │
│  └───────────────────────────────────────────────┘     │
│                                                         │
│  ┌───────────────────────────────────────────────┐     │
│  │  Step 3: 文件过滤设置                          │     │
│  │  文件后缀: [.dart] [.java] [.go] [+ 自定义]   │     │
│  │  排除目录: [node_modules] [build] [+ 添加]    │     │
│  └───────────────────────────────────────────────┘     │
│                                                         │
│              [扫描文件]  [生成文档]                    │
│                                                         │
│  ┌───────────────────────────────────────────────┐     │
│  │  文件列表 (已选择 15 个文件)                  │     │
│  │  ┌─────────────────────────────────────────┐  │     │
│  │  │ ☑ main.dart            1.2KB  UTF-8    │  │     │
│  │  │ ☑ app_service.dart     3.5KB  UTF-8    │  │     │
│  │  │ ☑ user_model.dart      2.1KB  UTF-8    │  │     │
│  │  │ ...                                     │  │     │
│  │  └─────────────────────────────────────────┘  │     │
│  └───────────────────────────────────────────────┘     │
│                                                         │
│  [████████████████░░░░░░░░] 60%  正在处理...          │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## 2. 页面设计

### 2.1 首页 (HomePage)

#### 布局结构
```dart
Scaffold(
  appBar: _buildAppBar(),
  body: SingleChildScrollView(
    child: Column(
      children: [
        DirectorySelectionSection(),    // 目录选择区
        ExportConfigSection(),          // 导出配置区
        FileFilterSection(),            // 文件过滤区
        ActionButtonsSection(),         // 操作按钮区
        FileListSection(),              // 文件列表区
        ProgressBarSection(),           // 进度条区
      ],
    ),
  ),
)
```

#### 组件尺寸规范
- 左右边距: 24px
- 组件间距: 16px
- 卡片圆角: 8px
- 输入框高度: 48px
- 按钮高度: 40px

### 2.2 设置页面 (SettingsPage)

#### 设置项
```
┌─────────────────────────────────────┐
│  常规设置                           │
│  ├─ 默认导出路径                    │
│  ├─ 默认每页行数                    │
│  └─ 默认字体大小                    │
├─────────────────────────────────────┤
│  外观设置                           │
│  ├─ 主题 (浅色/深色/跟随系统)      │
│  └─ 强调色                          │
├─────────────────────────────────────┤
│  高级设置                           │
│  ├─ 并发处理数量                    │
│  ├─ 编码检测严格度                  │
│  └─ 日志级别                        │
└─────────────────────────────────────┘
```

## 3. 核心组件设计

### 3.1 DirectorySelector (目录选择器)

#### 状态管理
```dart
class DirectorySelector extends StatefulWidget {
  final List<String> initialPaths;
  final ValueChanged<List<String>> onPathsChanged;
}

class _DirectorySelectorState extends State<DirectorySelector> {
  List<String> _paths = [];
  
  Future<void> _addDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null && !_paths.contains(result)) {
      setState(() {
        _paths.add(result);
        widget.onPathsChanged(_paths);
      });
    }
  }
  
  void _removePath(String path) {
    setState(() {
      _paths.remove(path);
      widget.onPathsChanged(_paths);
    });
  }
}
```

#### UI 组件
```dart
Column(
  children: [
    // 路径列表
    ..._paths.map((path) => _buildPathTile(path)),
    
    // 操作按钮
    Row(
      children: [
        ElevatedButton.icon(
          icon: Icon(Icons.add),
          label: Text('添加目录'),
          onPressed: _addDirectory,
        ),
        SizedBox(width: 8),
        TextButton(
          child: Text('清空列表'),
          onPressed: _paths.isEmpty ? null : _clearAll,
        ),
      ],
    ),
  ],
)
```

### 3.2 FileListView (文件列表视图)

#### 功能特性
- 多选支持
- 编码显示
- 文件大小显示
- 搜索过滤

#### 实现代码
```dart
class FileListView extends StatelessWidget {
  final List<SourceFile> files;
  final Set<String> selectedFiles;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 搜索栏
        _buildSearchBar(),
        
        // 文件列表
        Expanded(
          child: ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              return _buildFileTile(files[index]);
            },
          ),
        ),
        
        // 底部统计
        _buildFooter(),
      ],
    );
  }
  
  Widget _buildFileTile(SourceFile file) {
    return CheckboxListTile(
      value: selectedFiles.contains(file.path),
      onChanged: (checked) => _toggleSelection(file.path),
      title: Text(file.name),
      subtitle: Text('${file.size}  |  ${file.encoding}'),
      secondary: Icon(_getFileIcon(file.extension)),
    );
  }
}
```

### 3.3 ProgressBar (进度条)

#### 状态定义
```dart
enum ProgressState {
  idle,        // 空闲
  scanning,    // 扫描中
  processing,  // 处理中
  exporting,   // 导出中
  completed,   // 完成
  error,       // 错误
}
```

#### UI 实现
```dart
class ProgressBar extends StatelessWidget {
  final double progress;      // 0.0 - 1.0
  final ProgressState state;
  final String statusText;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(
                _getProgressColor(state),
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(statusText),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getProgressColor(ProgressState state) {
    switch (state) {
      case ProgressState.completed:
        return Colors.green;
      case ProgressState.error:
        return Colors.red;
      default:
        return Theme.of(context).primaryColor;
    }
  }
}
```

## 4. 状态管理

### 4.1 全局状态模型

```dart
class AppState extends ChangeNotifier {
  // 目录配置
  List<String> sourceDirectories = [];
  
  // 导出配置
  String softwareName = '';
  String version = '1.0.0';
  int linesPerPage = 50;
  int maxPages = 60;  // 最大页数限制（默认60页）
  
  // 文件过滤
  Set<String> allowedExtensions = {'.dart', '.java', '.go'};
  Set<String> excludedDirectories = {'node_modules', 'build', '.git'};
  
  // 扫描结果
  List<SourceFile> scannedFiles = [];
  Set<String> selectedFiles = {};
  
  // 处理状态
  ProgressState progressState = ProgressState.idle;
  double progress = 0.0;
  String statusMessage = '';
  
  // 方法
  void addDirectory(String path) {
    sourceDirectories.add(path);
    notifyListeners();
  }
  
  void updateProgress(ProgressState state, double value, String message) {
    progressState = state;
    progress = value;
    statusMessage = message;
    notifyListeners();
  }
  
  void updateMaxPages(int pages) {
    maxPages = pages;
    notifyListeners();
  }
  
  // 获取最大允许的总行数
  int get maxTotalLines => maxPages * linesPerPage;
}
```

### 4.2 Provider 配置

```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        Provider(create: (_) => ScanService()),
        Provider(create: (_) => CleanService()),
        Provider(create: (_) => ExportService()),
      ],
      child: CodeDocToolApp(),
    ),
  );
}
```

## 5. 交互流程

### 5.1 扫描流程
```
1. 用户点击"添加目录"按钮
   ↓
2. FilePicker 打开目录选择对话框
   ↓
3. 用户选择目录
   ↓
4. 调用 ScanService 扫描文件
   ↓
5. 更新 AppState.scannedFiles
   ↓
6. FileListView 刷新显示文件列表
```

### 5.2 导出流程
```
1. 用户点击"生成文档"按钮
   ↓
2. 验证必填字段（软件名称、版本等）
   ↓
3. 显示进度条，状态=processing
   ↓
4. 调用 CleanService 清洗代码
   ↓
5. 更新进度条（30%）
   ↓
6. 调用 ExportService 生成 Word
   ↓
7. 更新进度条（100%）
   ↓
8. 显示完成对话框
   ↓
9. 提供"打开文件"或"打开目录"选项
```

## 6. 响应式设计

### 6.1 断点定义
```dart
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}
```

### 6.2 布局适配
```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < Breakpoints.mobile) {
      return MobileLayout();
    } else if (constraints.maxWidth < Breakpoints.tablet) {
      return TabletLayout();
    } else {
      return DesktopLayout();
    }
  },
)
```

## 7. 主题设计

### 7.1 浅色主题
```dart
ThemeData(
  brightness: Brightness.light,
  primaryColor: Color(0xFF2196F3),
  accentColor: Color(0xFF03A9F4),
  scaffoldBackgroundColor: Color(0xFFFAFAFA),
  cardColor: Colors.white,
  textTheme: TextTheme(
    headline6: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    bodyText2: TextStyle(fontSize: 14, color: Colors.black87),
  ),
)
```

### 7.2 深色主题
```dart
ThemeData(
  brightness: Brightness.dark,
  primaryColor: Color(0xFF90CAF9),
  accentColor: Color(0xFF4FC3F7),
  scaffoldBackgroundColor: Color(0xFF121212),
  cardColor: Color(0xFF1E1E1E),
  textTheme: TextTheme(
    headline6: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    bodyText2: TextStyle(fontSize: 14, color: Colors.white70),
  ),
)
```

## 8. 动画与过渡

### 8.1 页面切换
```dart
Navigator.push(
  context,
  PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => SettingsPage(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  ),
);
```

### 8.2 列表项动画
```dart
AnimatedList(
  initialItemCount: files.length,
  itemBuilder: (context, index, animation) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, 0.1),
          end: Offset.zero,
        ).animate(animation),
        child: FileTile(files[index]),
      ),
    );
  },
)
```

## 9. 国际化支持

### 9.1 多语言配置
```dart
MaterialApp(
  localizationsDelegates: [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: [
    const Locale('zh', 'CN'),
    const Locale('en', 'US'),
  ],
)
```

### 9.2 文本提取
```dart
class AppLocalizations {
  static const Map<String, Map<String, String>> _localizedValues = {
    'zh': {
      'app_title': '软著代码文档生成工具',
      'add_directory': '添加目录',
      'generate_document': '生成文档',
    },
    'en': {
      'app_title': 'Code Archive Tool',
      'add_directory': 'Add Directory',
      'generate_document': 'Generate Document',
    },
  };
}
```

## 10. 无障碍设计

### 10.1 语义标签
```dart
Semantics(
  label: '源代码目录选择器',
  hint: '点击添加要扫描的目录',
  child: ElevatedButton(
    child: Text('添加目录'),
    onPressed: _addDirectory,
  ),
)
```

### 10.2 键盘导航
```dart
FocusNode _focusNode = FocusNode();

@override
Widget build(BuildContext context) {
  return Shortcuts(
    shortcuts: {
      LogicalKeySet(LogicalKeyboardKey.enter): _ActivateIntent(),
    },
    child: Actions(
      actions: {
        _ActivateIntent: CallbackAction(onInvoke: _handleActivate),
      },
      child: Focus(
        focusNode: _focusNode,
        child: MyWidget(),
      ),
    ),
  );
}
```
