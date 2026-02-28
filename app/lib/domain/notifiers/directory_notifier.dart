import 'package:flutter/foundation.dart';

class DirectoryNotifier extends ChangeNotifier {
  final List<String> _sourceDirectories = [];

  List<String> get sourceDirectories => List.unmodifiable(_sourceDirectories);

  int get directoryCount => _sourceDirectories.length;

  bool get hasDirectories => _sourceDirectories.isNotEmpty;

  void addDirectory(String path) {
    if (!_sourceDirectories.contains(path)) {
      _sourceDirectories.add(path);
      notifyListeners();
    }
  }

  void removeDirectory(String path) {
    if (_sourceDirectories.remove(path)) {
      notifyListeners();
    }
  }

  void clearDirectories() {
    if (_sourceDirectories.isNotEmpty) {
      _sourceDirectories.clear();
      notifyListeners();
    }
  }

  bool contains(String path) => _sourceDirectories.contains(path);
  @override
  void dispose() {
    // Clean up resources
    super.dispose();
  }

}
