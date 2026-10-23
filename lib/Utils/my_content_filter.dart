import 'content_settings.dart';

class MyContentFilter {
  /// 拦截原始 JSON 列表
  static List<dynamic> filterRawList(List<dynamic> rawList) {
    if (rawList.isEmpty) return rawList;

    final minLikes = ContentSettings.minLikes;
    final maxLikes = ContentSettings.maxLikes;
    final isKeywordEnabled = ContentSettings.enableKeywords;
    final keywords = ContentSettings.keywords;

    // 如果什么都没开，直接返回
    if (minLikes == 0 && maxLikes >= 999999999 && (!isKeywordEnabled || keywords.isEmpty)) {
      return rawList;
    }

    return rawList.where((item) {
      if (item is! Map) return true;
      
      // 1. 找点赞数
      int likes = _findInt(item, ['favoriteCount', 'postHot', 'likeCount']);
      
      // 2. 找标题
      String title = _findString(item, ['title', 'noticeLinkTitle']);
      
      // 3. 找标签
      String tags = _findTags(item);

      // 点赞过滤：不在区间直接干掉
      if (likes < minLikes || likes > maxLikes) {
        return false;
      }

      // 关键词过滤：只要命中，整篇文章直接干掉，列表自动往下补全！
      if (isKeywordEnabled && keywords.isNotEmpty) {
        final checkStr = '$title $tags';
        for (final kw in keywords) {
          if (checkStr.contains(kw)) {
            return false; // 绝不心慈手软，整篇文章直接扬了，绝不改文字
          }
        }
      }

      return true;
    }).toList();
  }

  static int _findInt(dynamic map, List<String> keys) {
    if (map is Map) {
      for (var key in keys) {
        if (map.containsKey(key) && map[key] is num) return (map[key] as num).toInt();
      }
      for (var val in map.values) {
        int res = _findInt(val, keys);
        if (res > 0) return res;
      }
    } else if (map is List) {
      for (var item in map) {
        int res = _findInt(item, keys);
        if (res > 0) return res;
      }
    }
    return 0;
  }

  static String _findString(dynamic map, List<String> keys) {
    if (map is Map) {
      for (var key in keys) {
        if (map.containsKey(key) && map[key] is String) return map[key] as String;
      }
      for (var val in map.values) {
        final res = _findString(val, keys);
        if (res.isNotEmpty) return res;
      }
    } else if (map is List) {
      for (var item in map) {
        final res = _findString(item, keys);
        if (res.isNotEmpty) return res;
      }
    }
    return '';
  }

  static String _findTags(dynamic map) {
    if (map is Map) {
      if (map.containsKey('tagList') && map['tagList'] is List) {
        return (map['tagList'] as List).join(' ');
      }
      for (var val in map.values) {
        final res = _findTags(val);
        if (res.isNotEmpty) return res;
      }
    } else if (map is List) {
      for (var item in map) {
        final res = _findTags(item);
        if (res.isNotEmpty) return res;
      }
    }
    return '';
  }
}
