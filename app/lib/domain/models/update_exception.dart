/// 更新服务相关的自定义异常类。
///
/// 用于在更新过程中抛出详细的错误信息，便于诊断问题。


/// 获取版本信息失败
class UpdateFetchException implements Exception {
  final String message;
  final Object? cause;

  UpdateFetchException(this.message, {this.cause});

  @override
  String toString() =>
      'UpdateFetchException: $message${cause != null ? ' (cause: $cause)' : ''}';
}

/// 下载更新失败
class UpdateDownloadException implements Exception {
  final String message;
  final Object? cause;

  UpdateDownloadException(this.message, {this.cause});

  @override
  String toString() =>
      'UpdateDownloadException: $message${cause != null ? ' (cause: $cause)' : ''}';
}

/// 安装更新失败
class UpdateInstallException implements Exception {
  final String message;
  final Object? cause;

  UpdateInstallException(this.message, {this.cause});

  @override
  String toString() =>
      'UpdateInstallException: $message${cause != null ? ' (cause: $cause)' : ''}';
}

/// 通用更新异常
class UpdateException implements Exception {
  final String message;
  final Object? cause;

  UpdateException(this.message, {this.cause});

  @override
  String toString() =>
      'UpdateException: $message${cause != null ? ' (cause: $cause)' : ''}';
}
