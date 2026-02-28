import 'dart:convert';
import 'dart:io';
import 'package:charset_converter/charset_converter.dart';
import 'package:flutter/foundation.dart';

class ReadOnlyFileReader {
  Future<String> readAsString(
    String filePath, {
    String encoding = 'UTF-8',
  }) async {
    final file = File(filePath);
    final randomAccessFile = await file.open(mode: FileMode.read);

    try {
      final bytes = await randomAccessFile.read(await file.length());
      return await _decode(bytes, encoding);
    } finally {
      await randomAccessFile.close();
    }
  }

  Future<String> _decode(List<int> bytes, String encoding) async {
    switch (encoding.toUpperCase()) {
      case 'UTF-8':
      case 'UTF8':
        return utf8.decode(bytes);
      case 'GBK':
      case 'GB2312':
        return await _decodeGBK(bytes);
      case 'LATIN1':
      case 'ISO-8859-1':
        return latin1.decode(bytes);
      default:
        return utf8.decode(bytes);
    }
  }

  Future<String> _decodeGBK(List<int> bytes) async {
    try {
      final uint8List = Uint8List.fromList(bytes);
      return await CharsetConverter.decode('gbk', uint8List);
    } catch (e) {
      try {
        return utf8.decode(bytes);
      } catch (e) {
        debugPrint('读取文件失败: $e');
        return String.fromCharCodes(bytes);
      }
    }
  }
}
