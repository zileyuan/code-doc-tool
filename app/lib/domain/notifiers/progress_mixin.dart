import 'package:flutter/foundation.dart';

mixin ProgressMixin<T> on ChangeNotifier {
  T? _progressState;
  double _progress = 0.0;
  String _statusMessage = '';

  T? get progressState => _progressState;
  double get progress => _progress;
  String get statusMessage => _statusMessage;

  void updateProgress(T state, double value, String message) {
    _progressState = state;
    _progress = value;
    _statusMessage = message;
    notifyListeners();
  }
}
