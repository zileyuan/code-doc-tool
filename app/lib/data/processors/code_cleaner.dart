import 'dart:isolate';
import '../../domain/models/clean_code.dart';

abstract class CleanStrategy {
  String removeComments(String code);
  String removeEmptyLines(String code);
}

class CodeCleaner {
  final Map<String, CleanStrategy> _strategies;
  static const int isolateThreshold = 100 * 1024; // 100KB 以上使用 Isolate

  CodeCleaner({Map<String, CleanStrategy>? strategies})
    : _strategies = strategies ?? _defaultStrategies();

  static Map<String, CleanStrategy> _defaultStrategies() {
    return {
      'c-style': CStyleCleanStrategy(),
      'python': PythonCleanStrategy(),
      'html': HTMLCleanStrategy(),
      'shell': ShellCleanStrategy(),
      'sql': SQLCleanStrategy(),
      'css': CSSCleanStrategy(),
    };
  }

  Future<CleanCode> clean(
    String content,
    String fileName,
    String extension,
  ) async {
    if (content.length > isolateThreshold) {
      return await cleanInIsolate(content, fileName, extension);
    }
    return _cleanSync(content, fileName, extension);
  }

  CleanCode _cleanSync(String content, String fileName, String extension) {
    final languages = LanguageMapper.getLanguages(extension);

    var currentContent = content;

    for (final language in languages) {
      final strategy = _strategies[language] ?? _strategies['c-style']!;
      currentContent = strategy.removeComments(currentContent);
    }

    currentContent = _removeEmptyLinesStatic(currentContent);
    currentContent = _trimWhitespaceStatic(currentContent);
    currentContent = _convertTabsToSpacesStatic(currentContent);

    final originalLines = content.split('\n').length;
    final cleanedLines = currentContent.split('\n').length;

    return CleanCode(
      fileName: fileName,
      originalContent: content,
      cleanedContent: currentContent,
      originalLines: originalLines,
      cleanedLines: cleanedLines,
      removedComments: _estimateRemovedComments(content, currentContent),
      removedEmptyLines: originalLines - cleanedLines,
    );
  }

  Future<CleanCode> cleanInIsolate(
    String content,
    String fileName,
    String extension,
  ) async {
    return await Isolate.run(() {
      return _cleanInIsolate(
        _IsolateParams(
          content: content,
          fileName: fileName,
          extension: extension,
        ),
      );
    });
  }

  static CleanCode _cleanInIsolate(_IsolateParams params) {
    final strategies = _defaultStrategies();
    final languages = LanguageMapper.getLanguages(params.extension);

    var currentContent = params.content;

    for (final language in languages) {
      final strategy = strategies[language] ?? strategies['c-style']!;
      currentContent = strategy.removeComments(currentContent);
    }

    currentContent = _removeEmptyLinesStatic(currentContent);
    currentContent = _trimWhitespaceStatic(currentContent);
    currentContent = _convertTabsToSpacesStatic(currentContent);

    final originalLines = params.content.split('\n').length;
    final cleanedLines = currentContent.split('\n').length;

    return CleanCode(
      fileName: params.fileName,
      originalContent: params.content,
      cleanedContent: currentContent,
      originalLines: originalLines,
      cleanedLines: cleanedLines,
      removedComments: (params.content.length - currentContent.length) ~/ 10,
      removedEmptyLines: originalLines - cleanedLines,
    );
  }



  static String _removeEmptyLinesStatic(String content) {
    return content
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .join('\n');
  }

  static String _trimWhitespaceStatic(String content) {
    return content.split('\n').map((line) => line.trimRight()).join('\n');
  }

  static String _convertTabsToSpacesStatic(String content) {
    return content
        .split('\n')
        .map((line) {
          final leadingMatch = RegExp(r'^[\t ]+').firstMatch(line);
          if (leadingMatch == null) return line;
          final leading = leadingMatch.group(0)!;
          final convertedLeading = leading.replaceAll('\t', '  ');
          return convertedLeading + line.substring(leading.length);
        })
        .join('\n');
  }




  int _estimateRemovedComments(String original, String cleaned) {
    return (original.length - cleaned.length) ~/ 10;
  }
}

class _IsolateParams {
  final String content;
  final String fileName;
  final String extension;

  _IsolateParams({
    required this.content,
    required this.fileName,
    required this.extension,
  });
}

class LanguageMapper {
  static const Map<String, List<String>> extensionToLanguage = {
    '.dart': ['c-style'],
    '.java': ['c-style'],
    '.kt': ['c-style'],
    '.cpp': ['c-style'],
    '.c': ['c-style'],
    '.h': ['c-style'],
    '.hpp': ['c-style'],
    '.cs': ['c-style'],
    '.swift': ['c-style'],
    '.go': ['c-style'],
    '.rs': ['c-style'],
    '.js': ['c-style'],
    '.ts': ['c-style'],
    '.jsx': ['c-style'],
    '.tsx': ['c-style'],
    '.py': ['python'],
    '.rb': ['python'],
    '.sh': ['shell'],
    '.bash': ['shell'],
    '.html': ['html'],
    '.htm': ['html'],
    '.xml': ['html'],
    '.css': ['css'],
    '.scss': ['css'],
    '.less': ['css'],
    '.sql': ['sql'],
  };

  static List<String> getLanguages(String extension) {
    return extensionToLanguage[extension.toLowerCase()] ?? ['c-style'];
  }
}

class CStyleCleanStrategy implements CleanStrategy {
  @override
  String removeComments(String code) {
    final buffer = StringBuffer();
    var i = 0;

    while (i < code.length) {
      if (i < code.length - 1 && code[i] == '/' && code[i + 1] == '*') {
        i += 2;
        while (i < code.length - 1) {
          if (code[i] == '*' && code[i + 1] == '/') {
            i += 2;
            break;
          }
          i++;
        }
        continue;
      }

      if (i < code.length - 1 && code[i] == '/' && code[i + 1] == '/') {
        while (i < code.length && code[i] != '\n') {
          i++;
        }
        continue;
      }

      if (code[i] == '"' || code[i] == "'" || code[i] == '`') {
        final quote = code[i];
        buffer.write(code[i]);
        i++;

        while (i < code.length && code[i] != quote) {
          if (code[i] == '\\') {
            buffer.write(code[i]);
            i++;
            if (i < code.length) {
              buffer.write(code[i]);
              i++;
            }
          } else {
            buffer.write(code[i]);
            i++;
          }
        }
        if (i < code.length) {
          buffer.write(code[i]);
          i++;
        }
        continue;
      }

      buffer.write(code[i]);
      i++;
    }

    return buffer.toString();
  }

  @override
  String removeEmptyLines(String code) {
    return code.split('\n').where((line) => line.trim().isNotEmpty).join('\n');
  }
}

class PythonCleanStrategy implements CleanStrategy {
  @override
  String removeComments(String code) {
    final buffer = StringBuffer();
    var i = 0;

    while (i < code.length) {
      if (i < code.length - 2) {
        final threeChars = code.substring(i, i + 3);
        if (threeChars == '"""' || threeChars == "'''") {
          final quote = threeChars;
          buffer.write(quote);
          i += 3;
          while (i < code.length - 2) {
            if (code.substring(i, i + 3) == quote) {
              buffer.write(quote);
              i += 3;
              break;
            }
            if (code[i] == '\\') {
              buffer.write(code[i]);
              i++;
              if (i < code.length) {
                buffer.write(code[i]);
                i++;
              }
            } else {
              buffer.write(code[i]);
              i++;
            }
          }
          continue;
        }
      }

      if (code[i] == '"' || code[i] == "'") {
        final quote = code[i];
        buffer.write(code[i]);
        i++;
        while (i < code.length && code[i] != quote) {
          if (code[i] == '\\') {
            buffer.write(code[i]);
            i++;
            if (i < code.length) {
              buffer.write(code[i]);
              i++;
            }
          } else {
            buffer.write(code[i]);
            i++;
          }
        }
        if (i < code.length) {
          buffer.write(code[i]);
          i++;
        }
        continue;
      }

      if (code[i] == '#') {
        while (i < code.length && code[i] != '\n') {
          i++;
        }
        continue;
      }

      buffer.write(code[i]);
      i++;
    }

    return buffer.toString();
  }

  @override
  String removeEmptyLines(String code) {
    return code.split('\n').where((line) => line.trim().isNotEmpty).join('\n');
  }
}

class HTMLCleanStrategy implements CleanStrategy {
  @override
  String removeComments(String code) {
    final buffer = StringBuffer();
    var i = 0;

    while (i < code.length) {
      if (i < code.length - 3 &&
          code[i] == '<' &&
          code[i + 1] == '!' &&
          code[i + 2] == '-' &&
          code[i + 3] == '-') {
        i += 4;
        while (i < code.length - 2) {
          if (code[i] == '-' && code[i + 1] == '-' && code[i + 2] == '>') {
            i += 3;
            break;
          }
          i++;
        }
        continue;
      }

      buffer.write(code[i]);
      i++;
    }

    return buffer.toString();
  }

  @override
  String removeEmptyLines(String code) {
    return code.split('\n').where((line) => line.trim().isNotEmpty).join('\n');
  }
}

class ShellCleanStrategy implements CleanStrategy {
  @override
  String removeComments(String code) {
    final buffer = StringBuffer();
    var i = 0;

    while (i < code.length) {
      if (code[i] == '#') {
        while (i < code.length && code[i] != '\n') {
          i++;
        }
        continue;
      }

      buffer.write(code[i]);
      i++;
    }

    return buffer.toString();
  }

  @override
  String removeEmptyLines(String code) {
    return code.split('\n').where((line) => line.trim().isNotEmpty).join('\n');
  }
}

class SQLCleanStrategy implements CleanStrategy {
  @override
  String removeComments(String code) {
    final buffer = StringBuffer();
    var i = 0;

    while (i < code.length) {
      if (i < code.length - 1 && code[i] == '-' && code[i + 1] == '-') {
        while (i < code.length && code[i] != '\n') {
          i++;
        }
        continue;
      }

      if (i < code.length - 1 && code[i] == '/' && code[i + 1] == '*') {
        i += 2;
        while (i < code.length - 1) {
          if (code[i] == '*' && code[i + 1] == '/') {
            i += 2;
            break;
          }
          i++;
        }
        continue;
      }

      buffer.write(code[i]);
      i++;
    }

    return buffer.toString();
  }

  @override
  String removeEmptyLines(String code) {
    return code.split('\n').where((line) => line.trim().isNotEmpty).join('\n');
  }
}

class CSSCleanStrategy implements CleanStrategy {
  @override
  String removeComments(String code) {
    final buffer = StringBuffer();
    var i = 0;

    while (i < code.length) {
      if (i < code.length - 1 && code[i] == '/' && code[i + 1] == '*') {
        i += 2;
        while (i < code.length - 1) {
          if (code[i] == '*' && code[i + 1] == '/') {
            i += 2;
            break;
          }
          i++;
        }
        continue;
      }

      if (code[i] == '"' || code[i] == "'") {
        final quote = code[i];
        buffer.write(code[i]);
        i++;
        while (i < code.length && code[i] != quote) {
          if (code[i] == '\\' && i + 1 < code.length) {
            buffer.write(code[i]);
            i++;
            buffer.write(code[i]);
            i++;
          } else {
            buffer.write(code[i]);
            i++;
          }
        }
        if (i < code.length) {
          buffer.write(code[i]);
          i++;
        }
        continue;
      }

      buffer.write(code[i]);
      i++;
    }

    return buffer.toString();
  }

  @override
  String removeEmptyLines(String code) {
    return code.split('\n').where((line) => line.trim().isNotEmpty).join('\n');
  }
}
