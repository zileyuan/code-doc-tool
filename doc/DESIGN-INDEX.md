# 设计文档索引

## 1. 文档清单

本文档整理了"软著代码文档生成工具"的详细设计文档，所有设计基于 Flutter 3.38 技术栈。

### 1.1 架构与概览
- **[design-architecture.md](./design-architecture.md)** - 技术架构设计
  - 技术栈选型（Flutter 3.38）
  - 分层架构设计
  - 目录结构设计
  - 核心模块划分
  - 数据流设计
  - 并发与性能设计
  - 安全性设计
  - 扩展性设计

### 1.2 界面设计
- **[design-ui.md](./design-ui.md)** - UI界面设计
  - 主窗口布局
  - 页面设计（首页、设置页）
  - 核心组件设计
  - 状态管理
  - 交互流程
  - 响应式设计
  - 主题设计
  - 动画与过渡
  - 国际化支持
  - 无障碍设计

### 1.3 核心模块设计
- **[design-file-scanner.md](./design-file-scanner.md)** - 文件扫描模块设计
  - 只读文件扫描
  - 路径验证
  - 编码检测
  - 后缀过滤
  - 排除目录
  - 性能优化
  - 并发扫描
  - 缓存机制
  - 错误处理

- **[design-code-cleaner.md](./design-code-cleaner.md)** - 代码清洗模块设计
  - 注释去除（多语言支持）
  - 空行过滤
  - 内存中处理
  - 语言适配策略
  - C-Style/Python/HTML 策略实现
  - 性能优化（Isolate）
  - 批量处理
  - 正则表达式方案

- **[design-word-exporter.md](./design-word-exporter.md)** - Word导出模块设计
  - OOXML 标准格式
  - 精确排版控制
  - 每页行数控制
  - **最大页数限制（默认60页）**
  - 页眉页脚设计
  - 字体配置
  - 性能优化
  - 内存优化
  - 批量导出
  - 导出结果反馈

- **[design-encoding.md](./design-encoding.md)** - 编码处理模块设计
  - 自动编码检测
  - BOM 检测
  - UTF-8 验证
  - 统计检测
  - 编码转换
  - 智能转换器
  - 常见编码支持
  - 错误处理

- **[design-update.md](./design-update.md)** - 自动更新模块设计
  - GitHub Release API 集成
  - 版本检查与比较
  - 下载与解压
  - 自动安装脚本
  - 更新状态管理

## 2. 技术栈

### 2.1 核心技术
- **框架**: Flutter 3.38
- **语言**: Dart 3.x
- **平台**: Desktop (Windows / macOS / Linux)

### 2.2 关键依赖
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # 文件系统
  path_provider: ^2.1.0
  file_picker: ^6.1.0
  
  # 编码处理
  charset_converter: ^2.1.0
  
  # Word 文档
  docx_template: ^0.3.0
  archive: ^3.4.0
  
  # 状态管理
  provider: ^6.1.0
```

## 3. 系统架构

### 3.1 分层架构
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

### 3.2 核心数据流
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

## 4. 目录结构

```
lib/
├── main.dart                     # 应用入口
├── app/                          # 应用配置
├── ui/                           # 表现层
│   ├── pages/                    # 页面
│   ├── widgets/                  # 组件
│   └── theme/                    # 主题
├── domain/                       # 业务逻辑层
│   ├── models/                   # 数据模型
│   ├── services/                 # 业务服务
│   └── usecases/                 # 用例
├── data/                         # 数据处理层
│   ├── processors/               # 处理器
│   └── repositories/             # 数据仓库
├── infrastructure/               # 基础设施层
│   ├── encoding/                 # 编码处理
│   ├── io/                       # 文件IO
│   └── exporters/                # 导出器
└── utils/                        # 工具类
```

## 5. 关键设计决策

### 5.1 只读安全保证
- 强制使用 `FileMode.read` 模式
- 路径验证防止注入攻击
- 符号链接检测
- 禁止任何写入操作

### 5.2 内存处理
- 所有代码清洗在内存中完成
- 不创建临时文件
- 流式处理大文件
- 及时释放内存

### 5.3 编码自动检测
- 多策略检测（BOM、UTF-8 验证、统计）
- 采样检测提高性能
- 置信度评估
- 中文环境优化（默认 GBK）

### 5.4 Word 文档生成
- 符合 OOXML 标准
- 精确控制每页行数
- **页数限制控制**
  - 默认最大60页
  - 代码不足时按实际页数生成
  - 超出限制时自动截断并提示用户
  - 最大总行数 = 最大页数 × 每页行数
- 等宽字体排版
- 自动页眉页脚
- 导出结果反馈（页数、是否截断）

### 5.5 性能优化
- Isolate 并发处理
- Stream 流式处理
- 批量操作
- 缓存机制

## 6. 开发指南

### 6.1 开发环境
```bash
# 安装 Flutter
flutter upgrade

# 检查环境
flutter doctor

# 获取依赖
flutter pub get
```

### 6.2 运行项目
```bash
# 开发模式
flutter run -d macos

# 构建生产版本
flutter build macos --release
flutter build windows --release
flutter build linux --release
```

### 6.3 测试
```bash
# 运行单元测试
flutter test

# 运行集成测试
flutter test integration_test/
```

## 7. 风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 编码检测误判 | 中 | 提供手动指定选项 |
| Word 兼容性 | 低 | 使用标准 OOXML |
| 性能问题 | 中 | Isolate 并发处理 |
| 内存溢出 | 中 | 流式处理、及时释放 |

## 8. 后续扩展

### 8.1 短期（v1.1）
- [ ] PDF 导出支持
- [ ] 更多编程语言支持
- [ ] 自定义注释规则

### 8.2 中期（v2.0）
- [ ] 批量项目管理
- [ ] 代码统计报告
- [ ] 版本历史记录

### 8.3 长期（v3.0）
- [ ] 云端同步
- [ ] 团队协作
- [ ] AI 辅助分析

## 9. 文档维护

- **创建日期**: 2026-02-23
- **最后更新**: 2026-02-24 - 新增自动更新功能
- **版本**: v1.2
- **维护者**: 开发团队

### 更新记录

#### v1.2 (2026-02-24)
- 新增自动更新功能设计文档 (design-update.md)
- 新增 GitHub Release API 集成
- 新增 macOS 和 Windows 自动安装脚本
- 新增更新状态管理和 UI 对话框

#### v1.1 (2026-02-23)
- 新增 Word 文档最大页数限制功能
- 默认最大60页，代码不足时按实际页数生成
- 更新 ExportConfig 数据模型
- 更新 WordExporter 实现逻辑
- 更新 UI 界面设计，添加最大页数配置
- 新增 PageLimiter 类处理页数限制
- 新增导出结果反馈（ExportResult）
- 完善测试用例

#### v1.0 (2026-02-23)
- 初始版本
- 完成基础架构设计
- 完成核心模块设计

## 10. 参考资料

- [Flutter 官方文档](https://flutter.dev/docs)
- [Dart 官方文档](https://dart.dev/guides)
- [Office Open XML 标准](https://docs.microsoft.com/en-us/office/open-xml/open-xml-sdk)
- [字符编码标准](https://www.unicode.org/standard/standard.html)
