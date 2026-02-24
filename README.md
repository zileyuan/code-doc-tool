# 软著代码文档生成工具

一款用于生成软件著作权申请所需代码文档的桌面工具。

## 功能特性

- **源代码扫描** - 递归扫描源代码目录，支持多种编程语言
- **智能注释去除** - 自动去除各类编程语言的注释，保留纯净代码
- **编码自动检测** - 支持 UTF-8、GBK、GB2312 等多种编码自动检测
- **Word 文档生成** - 生成符合软著申请规范的 Word 文档
- **自动更新** - 支持 GitHub Release 自动检查更新

## 支持的编程语言

| 语言 | 文件后缀 |
|------|----------|
| Dart | .dart |
| Java | .java |
| Kotlin | .kt |
| C/C++ | .c, .cpp, .h, .hpp |
| C# | .cs |
| Swift | .swift |
| Go | .go |
| Rust | .rs |
| JavaScript | .js, .jsx |
| TypeScript | .ts, .tsx |
| Python | .py |
| Ruby | .rb |
| Shell | .sh, .bash |
| HTML/XML | .html, .htm, .xml |
| CSS | .css, .scss, .less |
| SQL | .sql |

## 系统要求

- macOS 10.14 或更高版本
- Windows 10 或更高版本

## 安装使用

### 从 Release 下载

1. 前往 [Releases](https://github.com/zileyuan/code-doc-tool/releases) 页面
2. 下载最新版本的安装包
   - macOS: `code-doc-tool-macos.zip`
   - Windows: `code-doc-tool-windows.zip`
3. 解压后运行应用

### 从源码构建

```bash
# 克隆仓库
git clone https://github.com/zileyuan/code-doc-tool.git
cd code-doc-tool

# 安装依赖
cd app
flutter pub get

# 运行开发版本
flutter run -d macos

# 构建生产版本
flutter build macos --release
flutter build windows --release
```

## 使用说明

1. **添加源代码目录** - 选择包含源代码的目录
2. **配置参数** - 填写软件名称、版本号
3. **扫描文件** - 点击"扫描文件"按钮扫描目录中的源代码文件
4. **选择文件** - 从扫描结果中选择需要导出的文件
5. **生成文档** - 点击"生成文档"按钮导出 Word 文档

## 文档格式

- 固定配置：每页 50 行，最多 60 页
- 自动添加页眉页脚
- 等宽字体排版
- 符合 OOXML 标准

## 技术栈

- **框架**: Flutter 3.38
- **语言**: Dart
- **平台**: macOS / Windows

## 项目结构

```
app/lib/
├── main.dart                 # 应用入口
├── domain/                   # 业务逻辑层
│   ├── app_state.dart       # 全局状态管理
│   ├── models/              # 数据模型
│   └── services/            # 业务服务
├── data/                     # 数据处理层
│   └── processors/          # 处理器
├── infrastructure/           # 基础设施层
│   ├── encoding/            # 编码处理
│   ├── exporters/           # 导出器
│   ├── io/                  # 文件IO
│   └── security/            # 安全验证
└── ui/                       # 表现层
    └── pages/               # 页面
```

## 开发文档

详细的设计文档请参阅 [doc](./doc) 目录：

- [架构设计](./doc/design-architecture.md)
- [UI设计](./doc/design-ui.md)
- [文件扫描](./doc/design-file-scanner.md)
- [代码清洗](./doc/design-code-cleaner.md)
- [Word导出](./doc/design-word-exporter.md)
- [编码处理](./doc/design-encoding.md)
- [自动更新](./doc/design-update.md)

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request。
