// novel_core_channel.dart
import 'package:flutter/services.dart';

class NovelCore {
  static const _ch = MethodChannel('novel_core');

  static Future<int> importTxt(String uri) async {
    final id = await _ch.invokeMethod('importTxt', {'uri': uri});
    return (id as num).toInt();
  }

  static Future<List<Map>> getNovels({int page = 0, int pageSize = 50}) async {
    final res = await _ch.invokeMethod('getNovels', {'page': page, 'pageSize': pageSize});
    return (res as List).cast<Map>();
  }

  static Future<List<Map>> getChapters(int novelId) async {
    final res = await _ch.invokeMethod('getChapters', {'novelId': novelId});
    return (res as List).cast<Map>();
  }

  static Future<String> getChapterContent(int chapterId) async {
    final res = await _ch.invokeMethod('getChapterContent', {'chapterId': chapterId});
    return (res as String);
  }

  static Future<void> updateProgress(int novelId, int chapterId, int offset) {
    return _ch.invokeMethod('updateProgress', {
      'novelId': novelId, 'chapterId': chapterId, 'offset': offset
    });
  }

  static Future<List<Map>> search(String q) async {
    final res = await _ch.invokeMethod('search', {'q': q});
    return (res as List).cast<Map>();
  }
  static Future<int> addChapter({
    required int novelId,
    required String title,
    required String content,
    int? index,
  }) async {
    final id = await _ch.invokeMethod('addChapter', {
      'novelId': novelId,
      'title': title,
      'content': content,
      'index': index,
    });
    return (id as num).toInt();
  }

  static Future<int> importMoreFromTxt({
    required int novelId,
    required String uri,
  }) async {
    final added = await _ch.invokeMethod('importMoreFromTxt', {
      'novelId': novelId,
      'uri': uri,
    });
    return (added as num).toInt();
  }
}
