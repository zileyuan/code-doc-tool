# 自动更新功能设计文档

## 1. 功能概述

自动更新功能允许应用从 GitHub Release 检查并下载新版本，支持自动替换安装。

## 2. 架构设计

### 2.1 目录结构
```
lib/
├── domain/
│   ├── services/
│   │   └── update_service.dart    # 更新服务
│   └── app_state.dart             # 状态管理
└── ui/
    └── pages/
        └── home_page.dart         # 更新对话框UI
```

### 2.2 核心类

#### ReleaseInfo 模型
```dart
class ReleaseInfo {
  final String version;            // 版本号 (如 v1.0.2)
  final String downloadUrlMacos;   // macOS 下载链接
  final String downloadUrlWindows; // Windows 下载链接
  final String releaseNotes;       // 更新说明
}
```

#### UpdateService 服务
```dart
class UpdateService {
  // 获取最新 Release 信息
  Future<ReleaseInfo?> fetchLatestRelease();
  
  // 比较版本号
  bool isNewerVersion(String current, String latest);
  
  // 下载更新包
  Future<String?> downloadUpdate(
    String url,
    String version,
    Function(double) onProgress,
    bool Function() isCancelled,
  );
  
  // 解压更新包
  Future<String?> extractAndPrepare(String zipPath, String version);
  
  // 执行更新脚本
  Future<bool> runUpdateScript(String extractPath);
}
```

#### UpdateState 状态枚举
```dart
enum UpdateState {
  idle,        // 空闲
  checking,    // 检查中
  available,   // 有新版本
  downloading, // 下载中
  ready,       // 准备就绪
  error,       // 错误
}
```

## 3. 更新流程

```
┌─────────────┐
│ 点击检查更新 │
└──────┬──────┘
       ▼
┌─────────────┐
│ 调用GitHub API│
│ 获取最新版本  │
└──────┬──────┘
       ▼
┌─────────────┐    ┌─────────────┐
│ 版本比较     │───▶│ 已是最新版本 │
└──────┬──────┘    └─────────────┘
       │ 有新版本
       ▼
┌─────────────┐
│ 显示更新对话框│
│ 展示更新日志  │
└──────┬──────┘
       ▼
┌─────────────┐
│ 用户点击下载  │
└──────┬──────┘
       ▼
┌─────────────┐
│ 下载ZIP包    │
│ 显示进度     │
└──────┬──────┘
       ▼
┌─────────────┐
│ 解压到临时目录│
└──────┬──────┘
       ▼
┌─────────────┐
│ 用户点击安装  │
└──────┬──────┘
       ▼
┌─────────────┐
│ 启动更新脚本  │
│ 应用退出     │
└──────┬──────┘
       ▼
┌─────────────┐
│ 脚本替换文件  │
│ 启动新版本    │
└─────────────┘
```

## 4. 更新脚本

### 4.1 macOS (update.sh)
```bash
#!/bin/bash
# 等待应用退出
# 删除旧版本
# 复制新版本
# 启动新版本
```

### 4.2 Windows (update.bat)
```batch
@echo off
REM 等待应用退出
REM 删除旧版本
REM 复制新版本
REM 启动新版本
```

## 5. 文件存储

| 文件 | 路径 | 说明 |
|------|------|------|
| 下载包 | `{临时目录}/code-doc-tool-{版本}-macos.zip` | 带版本号的ZIP包 |
| 解压目录 | `{临时目录}/code-doc-tool-{版本}/` | 解压后的文件 |

## 6. GitHub Release API

```
GET https://api.github.com/repos/zileyuan/code-doc-tool/releases/latest

Response:
{
  "tag_name": "v1.0.2",
  "body": "更新说明...",
  "assets": [
    {
      "name": "code-doc-tool-macos.zip",
      "browser_download_url": "https://..."
    }
  ]
}
```

## 7. UI设计

### 7.1 入口
- 位置：AppBar 右侧刷新图标
- 提示文字："检查更新"

### 7.2 更新对话框
- 宽度：500px
- 显示：当前版本、新版本号、更新日志、下载进度
- 按钮：取消下载、立即下载、立即安装

## 8. 错误处理

| 场景 | 处理方式 |
|------|----------|
| 网络错误 | 显示错误提示，提供重试按钮 |
| 下载失败 | 显示错误提示，允许重新下载 |
| 解压失败 | 显示错误提示 |
| 脚本执行失败 | 显示错误提示 |
