import 'content_settings.dart';

class PostFilterUtil {
  /// 拦截原始 JSON 列表，直接返回过滤后的 JSON 列表
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

      // 点赞过滤
      if (likes < minLikes || likes > maxLikes) {
        return false;
      }

      // 屏蔽词过滤
      if (isKeywordEnabled && keywords.isNotEmpty) {
        final checkStr = '$title $tags';
        for (final kw in keywords) {
          if (checkStr.contains(kw)) {
            return false; // 命中屏蔽词，直接干掉
          }
        }
      }

      return true;
    }).toList();
  }

  // 递归寻找某个 key 的 int 值
  static int _findInt(dynamic map, List<String> keys) {
    if (map is Map) {
      for (var key in keys) {
        if (map.containsKey(key) && map[key] is num) {
          return (map[key] as num).toInt();
        }
      }
      // 没找到就继续往下找
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

  // 递归寻找 title
  static String _findString(dynamic map, List<String> keys) {
    if (map is Map) {
      for (var key in keys) {
        if (map.containsKey(key) && map[key] is String) {
          return map[key] as String;
        }
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

  // 递归寻找标签
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
