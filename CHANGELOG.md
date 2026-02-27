# 变更日志

所有显著的变更都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)。

## [1.0.7] - 2024-02-26

### 修复
- 修复文档中依赖版本与实际 pubspec.yaml 不一致的问题
- 统一编码检测库引用（chardet → charset_converter）
- 修复 README 中 Flutter 版本号（3.38 → 3.10.8+）
- 修复 README 支持语言列表，添加 Objective-C (.m) 和 PHP

### 文档
- 新增测试计划文档 (testing.md)
- 新增变更日志 (CHANGELOG.md)
- 重命名文档文件：DESIGN-INDEX.md → design-index.md，Requirements.md → requirement.md

### 文档更新
- **design-word-exporter.md**: 更新为反映实际实现（使用 archive+xml 直接构建 docx，不使用 docx_template）
- **design-encoding.md**: 更新为反映实际实现（删除虚构的策略类、EncodingConverter 等，添加实际的 ReadOnlyFileReader）
- **design-architecture.md** / **DESIGN-INDEX.md**: 更新依赖列表，删除 regex 和 docx_template

## [1.0.0] - 2024-02-23

### 新增
- 初始版本发布
- 多目录源代码扫描（只读）
- 自动编码检测（UTF-8/GBK/GB2312）
- 智能代码清洗（去注释、去空行）
- Word 文档导出（每页50行、最大60页）
- 支持15+编程语言
- 自动更新功能
- 跨平台支持（macOS/Windows）
