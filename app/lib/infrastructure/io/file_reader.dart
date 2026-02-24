import 'dart:convert';
import 'dart:io';

class ReadOnlyFileReader {
  Future<String> readAsString(
    String filePath, {
    String encoding = 'UTF-8',
  }) async {
    final file = File(filePath);
    final randomAccessFile = await file.open(mode: FileMode.read);

    try {
      final bytes = await randomAccessFile.read(await file.length());
      return _decode(bytes, encoding);
    } finally {
      await randomAccessFile.close();
    }
  }

  String _decode(List<int> bytes, String encoding) {
    switch (encoding.toUpperCase()) {
      case 'UTF-8':
      case 'UTF8':
        return utf8.decode(bytes);
      case 'GBK':
      case 'GB2312':
        return _decodeGBK(bytes);
      case 'LATIN1':
      case 'ISO-8859-1':
        return latin1.decode(bytes);
      default:
        return utf8.decode(bytes);
    }
  }

  String _decodeGBK(List<int> bytes) {
    try {
      return String.fromCharCodes(bytes);
    } catch (e) {
      return utf8.decode(bytes);
    }
  }
}
