import 'dart:io';
import 'dart:typed_data';

class EncodingResult {
  final String encoding;
  final double confidence;
  final bool hasBOM;

  EncodingResult({
    required this.encoding,
    required this.confidence,
    this.hasBOM = false,
  });

  bool get isHighConfidence => confidence > 0.8;

  @override
  String toString() =>
      'EncodingResult($encoding, confidence: $confidence, hasBOM: $hasBOM)';
}

class EncodingDetector {
  final int sampleSize;

  EncodingDetector({this.sampleSize = 4096});

  Future<EncodingResult> detect(File file) async {
    try {
      final bytes = await _readSample(file);
      return _detectFromBytes(bytes);
    } catch (e) {
      return EncodingResult(encoding: 'UTF-8', confidence: 0.5);
    }
  }

  Future<Uint8List> _readSample(File file) async {
    final length = await file.length();
    final readLength = length < sampleSize ? length : sampleSize;

    final randomAccessFile = await file.open(mode: FileMode.read);
    try {
      return await randomAccessFile.read(readLength);
    } finally {
      await randomAccessFile.close();
    }
  }

  EncodingResult _detectFromBytes(Uint8List bytes) {
    if (_hasBOM(bytes)) {
      final encoding = _detectBOM(bytes);
      return EncodingResult(encoding: encoding, confidence: 1.0, hasBOM: true);
    }

    if (_isValidUTF8(bytes)) {
      return EncodingResult(encoding: 'UTF-8', confidence: 0.9, hasBOM: false);
    }

    final gbkResult = _analyzeGBK(bytes);
    if (gbkResult != null) {
      return gbkResult;
    }

    return EncodingResult(encoding: 'UTF-8', confidence: 0.5, hasBOM: false);
  }

  bool _hasBOM(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return true;
    }
    if (bytes.length >= 2) {
      if (bytes[0] == 0xFE && bytes[1] == 0xFF) return true;
      if (bytes[0] == 0xFF && bytes[1] == 0xFE) return true;
    }
    return false;
  }

  String _detectBOM(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return 'UTF-8';
    }
    if (bytes.length >= 2) {
      if (bytes[0] == 0xFE && bytes[1] == 0xFF) return 'UTF-16BE';
      if (bytes[0] == 0xFF && bytes[1] == 0xFE) return 'UTF-16LE';
    }
    return 'UTF-8';
  }

  bool _isValidUTF8(Uint8List bytes) {
    try {
      int i = 0;
      while (i < bytes.length) {
        final byte = bytes[i];

        if (byte <= 0x7F) {
          i++;
        } else if ((byte & 0xE0) == 0xC0) {
          if (i + 1 >= bytes.length) return false;
          if ((bytes[i + 1] & 0xC0) != 0x80) return false;
          i += 2;
        } else if ((byte & 0xF0) == 0xE0) {
          if (i + 2 >= bytes.length) return false;
          if ((bytes[i + 1] & 0xC0) != 0x80) return false;
          if ((bytes[i + 2] & 0xC0) != 0x80) return false;
          i += 3;
        } else if ((byte & 0xF8) == 0xF0) {
          if (i + 3 >= bytes.length) return false;
          if ((bytes[i + 1] & 0xC0) != 0x80) return false;
          if ((bytes[i + 2] & 0xC0) != 0x80) return false;
          if ((bytes[i + 3] & 0xC0) != 0x80) return false;
          i += 4;
        } else {
          return false;
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  EncodingResult? _analyzeGBK(Uint8List bytes) {
    int highBytes = 0;
    for (final byte in bytes) {
      if (byte >= 0x80) {
        highBytes++;
      }
    }

    if (highBytes < bytes.length * 0.1) {
      return null;
    }

    int validGBKPairs = 0;
    int i = 0;

    while (i < bytes.length - 1) {
      final first = bytes[i];
      final second = bytes[i + 1];

      if (first >= 0x81 && first <= 0xFE) {
        if ((second >= 0x40 && second <= 0xFE) && second != 0x7F) {
          validGBKPairs++;
          i += 2;
          continue;
        }
      }
      i++;
    }

    if (validGBKPairs < bytes.length * 0.05) {
      return null;
    }

    final ratio = validGBKPairs / (highBytes / 2);
    final confidence = (0.5 + ratio * 0.5).clamp(0.5, 0.85);

    return EncodingResult(
      encoding: 'GBK',
      confidence: confidence,
      hasBOM: false,
    );
  }
}
