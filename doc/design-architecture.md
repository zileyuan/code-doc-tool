# 技术架构设计文档

## 1. 技术栈选型

### 1.1 核心技术
- **框架**: Flutter 3.38
- **语言**: Dart 3.x
- **平台**: Desktop (Windows / macOS / Linux)

### 1.2 关键依赖包
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # 文件系统操作
  path_provider: ^2.1.0
  file_picker: ^6.1.0
  
  # 编码检测
  charset_converter: ^2.1.0
  
  # Word文档生成
  docx_template: ^0.3.0
  archive: ^3.4.0
  
  # 状态管理
  provider: ^6.1.0
  
  # 正则表达式
  regex: ^0.1.0
```

## 2. 架构分层设计

### 2.1 分层架构图
```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│  (UI Widgets, Pages, Controllers)   │
├─────────────────────────────────────┤
│         Business Logic Layer        │
│   (Services, Use Cases, Managers)   │
├─────────────────────────────────────┤
│         Data Processing Layer       │
│  (Scanner, Cleaner, Transformer)    │
├─────────────────────────────────────┤
│         Infrastructure Layer        │
│    (File IO, Encoding, Export)      │
└─────────────────────────────────────┘
```

### 2.2 各层职责

#### Presentation Layer (表现层)
- **职责**: 用户界面渲染、用户交互处理
- **组件**: Pages、Widgets、ViewModels
- **技术**: Flutter Widgets、Provider/Riverpod

#### Business Logic Layer (业务逻辑层)
- **职责**: 核心业务流程编排、任务调度
- **组件**: Services、Use Cases、State Managers
- **技术**: Service Classes、StateNotifier

#### Data Processing Layer (数据处理层)
- **职责**: 代码扫描、清洗、转换
- **组件**: FileScanner、CodeCleaner、DataTransformer
- **技术**: Dart Stream、Isolate

#### Infrastructure Layer (基础设施层)
- **职责**: 文件系统访问、编码处理、文档导出
- **组件**: FileReader、EncodingDetector、WordExporter
- **技术**: dart:io、charset_converter、docx_template

## 3. 目录结构设计

```
lib/
├── main.dart                     # 应用入口
├── app/                          # 应用配置
│   ├── app.dart                  # MaterialApp配置
│   └── routes.dart               # 路由配置
│
├── ui/                           # 表现层
│   ├── pages/                    # 页面
│   │   ├── home_page.dart
│   │   └── settings_page.dart
│   ├── widgets/                  # 通用组件
│   │   ├── directory_selector.dart
│   │   ├── file_list_view.dart
│   │   └── progress_indicator.dart
│   └── theme/                    # 主题配置
│       ├── app_theme.dart
│       └── colors.dart
│
├── domain/                       # 业务逻辑层
│   ├── models/                   # 数据模型
│   │   ├── source_file.dart
│   │   ├── clean_code.dart
│   │   └── export_config.dart
│   ├── services/                 # 业务服务
│   │   ├── scan_service.dart
│   │   ├── clean_service.dart
│   │   └── export_service.dart
│   └── usecases/                 # 用例
│       ├── scan_directory_usecase.dart
│       └── export_word_usecase.dart
│
├── data/                         # 数据处理层
│   ├── processors/               # 处理器
│   │   ├── file_scanner.dart
│   │   ├── code_cleaner.dart
│   │   └── comment_remover.dart
│   └── repositories/             # 数据仓库
│       └── file_repository.dart
│
├── infrastructure/               # 基础设施层
│   ├── encoding/                 # 编码处理
│   │   ├── encoding_detector.dart
│   │   └── encoding_converter.dart
│   ├── io/                       # 文件IO
│   │   ├── file_reader.dart
│   │   └── file_system.dart
│   └── exporters/                # 导出器
│       ├── word_exporter.dart
│       └── pdf_exporter.dart (未来扩展)
│
└── utils/                        # 工具类
    ├── constants.dart
    ├── logger.dart
    └── validators.dart

test/                             # 测试目录
├── unit/
├── widget/
└── integration/
```

## 4. 核心模块设计

### 4.1 模块划分
```
┌─────────────────────────────────────────┐
│           Application Core              │
├─────────────────────────────────────────┤
│  ┌──────────────┐    ┌──────────────┐  │
│  │   Scanner    │───▶│   Cleaner    │  │
│  │   Module     │    │   Module     │  │
│  └──────────────┘    └──────────────┘  │
│          │                    │         │
│          └─────────┬──────────┘         │
│                    ▼                    │
│          ┌──────────────┐              │
│          │   Exporter   │              │
│          │   Module     │              │
│          └──────────────┘              │
└─────────────────────────────────────────┘
```

### 4.2 模块职责

#### Scanner Module (扫描模块)
- 文件系统遍历
- 后缀名过滤
- 编码检测
- 只读安全保障

#### Cleaner Module (清洗模块)
- 注释去除
- 空行过滤
- 内存中处理
- 不修改源文件

#### Exporter Module (导出模块)
- Word文档生成
- 排版控制
- 页眉页脚配置
- 文件保存

## 5. 数据流设计

### 5.1 主数据流
```
用户输入
   ↓
[Directory Paths + Config]
   ↓
Scanner Module (只读扫描)
   ↓
[File List + Raw Content]
   ↓
Encoding Detector (编码检测)
   ↓
[Decoded Content]
   ↓
Code Cleaner (内存清洗)
   ↓
[Cleaned Lines]
   ↓
Word Exporter (排版导出)
   ↓
[.docx File]
```

### 5.2 错误处理流
```
Exception
   ↓
ErrorHandler
   ├─ Log Error
   ├─ Show User Message
   └─ Continue/Skip (根据策略)
```

## 6. 并发与性能设计

### 6.1 Isolate 使用

对于大文件（超过 100KB），使用 Isolate 在后台线程处理，避免阻塞 UI：

```dart
// 大文件处理使用 Isolate
class CodeCleaner {
  static const int isolateThreshold = 100 * 1024; // 100KB

  Future<CleanCode> clean(String content, String fileName, String extension) async {
    if (content.length > isolateThreshold) {
      return await Isolate.run(() => _cleanInIsolate(...));
    }
    return _cleanSync(content, fileName, extension);
  }
}
```

**优点**：
- 大文件处理不阻塞 UI
- 保持界面响应流畅
- 自动根据文件大小选择处理方式

### 6.2 Stream 处理
```dart
// 使用 Stream 进行批量文件处理
Stream<CleanCode> processFiles(List<String> paths) async* {
  for (final path in paths) {
    yield await _processFile(path);
  }
}
```

### 6.3 内存管理
- 流式读取，避免一次性加载所有文件
- 及时释放已处理的数据
- 大文件分块处理

## 7. 安全性设计

### 7.1 只读保证
```dart
class ReadOnlyFileReader {
  Future<String> read(String path) async {
    final file = File(path);
    // 强制使用只读模式
    final randomAccessFile = await file.open(mode: FileMode.read);
    final content = await randomAccessFile.read(file.lengthSync());
    await randomAccessFile.close();
    return content;
  }
}
```

### 7.2 路径验证
```dart
class PathValidator {
  static bool isSafePath(String path, List<String> allowedRoots) {
    final absolutePath = File(path).absolute.path;
    return allowedRoots.any((root) => 
      absolutePath.startsWith(File(root).absolute.path)
    );
  }
}
```

## 8. 扩展性设计

### 8.1 插件式架构
```dart
abstract class CodeProcessor {
  String process(String code);
}

class CommentRemover implements CodeProcessor {
  @override
  String process(String code) {
    // 去注释实现
  }
}

class EmptyLineRemover implements CodeProcessor {
  @override
  String process(String code) {
    // 去空行实现
  }
}
```

### 8.2 策略模式
```dart
abstract class ExportStrategy {
  Future<void> export(List<CleanCode> codes, String outputPath);
}

class WordExportStrategy implements ExportStrategy {
  // Word 导出实现
}

class PdfExportStrategy implements ExportStrategy {
  // PDF 导出实现（未来）
}
```

## 9. 测试策略

### 9.1 单元测试
- 每个模块独立测试
- Mock 文件系统操作
- 编码检测测试

### 9.2 集成测试
- 端到端流程测试
- 多种编程语言测试
- 不同编码文件测试

### 9.3 性能测试
- 大文件处理性能
- 批量文件处理性能
- 内存占用测试

## 10. 部署与发布

### 10.1 构建命令
```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

### 10.2 打包策略
- 静态链接所有依赖
- 包含必要的运行时库
- 提供安装向导

## 11. 技术风险与缓解

### 11.1 编码检测准确性
- **风险**: chardet 可能误判
- **缓解**: 提供手动指定编码选项

### 11.2 Word 生成兼容性
- **风险**: 不同 Word 版本兼容性
- **缓解**: 使用标准 OOXML 格式

### 11.3 性能问题
- **风险**: 大量文件处理慢
- **缓解**: 使用 Isolate 并发处理
