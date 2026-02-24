class ScanConfig {
  final Set<String> allowedExtensions;
  final Set<String> excludedDirectories;
  final int maxFileSize;
  final bool detectEncoding;

  ScanConfig({
    Set<String>? allowedExtensions,
    Set<String>? excludedDirectories,
    this.maxFileSize = 10 * 1024 * 1024, // 10MB
    this.detectEncoding = true,
  }) : allowedExtensions = allowedExtensions ?? defaultExtensions,
       excludedDirectories = excludedDirectories ?? defaultExcludedDirs;

  static const defaultExtensions = {
    '.dart',
    '.java',
    '.kt',
    '.go',
    '.rs',
    '.cpp',
    '.c',
    '.h',
    '.hpp',
    '.js',
    '.ts',
    '.jsx',
    '.tsx',
    '.py',
    '.rb',
    '.php',
    '.cs',
    '.swift',
    '.m',
    '.sh',
    '.sql',
  };

  static const defaultExcludedDirs = {
    'node_modules',
    'build',
    'dist',
    'target',
    '.git',
    '.svn',
    '.hg',
    '__pycache__',
    'venv',
    '.venv',
    'bin',
    'obj',
    'out',
    '.idea',
    '.vscode',
    '.dart_tool',
    '.gradle',
    'Pods',
    'vendor',
    '.cache',
    '.next',
    '.nuxt',
    '.yarn',
    '.pnpm',
    'DerivedData',
    'coverage',
    'logs',
    'tmp',
    'temp',
  };

  ScanConfig copyWith({
    Set<String>? allowedExtensions,
    Set<String>? excludedDirectories,
    int? maxFileSize,
    bool? detectEncoding,
  }) {
    return ScanConfig(
      allowedExtensions: allowedExtensions ?? this.allowedExtensions,
      excludedDirectories: excludedDirectories ?? this.excludedDirectories,
      maxFileSize: maxFileSize ?? this.maxFileSize,
      detectEncoding: detectEncoding ?? this.detectEncoding,
    );
  }
}
