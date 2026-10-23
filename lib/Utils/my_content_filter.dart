import 'content_settings.dart';

class MyContentFilter {
  /// 拦截原始 JSON 列表
  static List<dynamic> filterRawList(List<dynamic> rawList) {
    if (rawList.isEmpty) return rawList;

    final minLikes = ContentSettings.minLikes;
    final maxLikes = ContentSettings.maxLikes;
    final isKeywordEnabled = ContentSettings.enableKeywords;
    final keywords = ContentSettings.keywords;
    final hideKeywords = ContentSettings.hideKeywords;

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

      // 关键词过滤
      if (isKeywordEnabled && keywords.isNotEmpty) {
        final checkStr = '$title $tags';
        bool hit = false;
        for (final kw in keywords) {
          if (checkStr.contains(kw)) {
            hit = true;
            break;
          }
        }
        if (hit) {
          if (hideKeywords) {
            _replaceKeyword(item, keywords, '██');
            return true; // 保留但打码
          } else {
            return false; // 直接干掉
          }
        }
      }

      return true;
    }).toList();
  }

  static void _replaceKeyword(dynamic map, List<String> keywords, String mask) {
    if (map is Map) {
      map.forEach((key, value) {
        if ((key == 'title' || key == 'noticeLinkTitle') && value is String) {
          String newStr = value;
          for (var kw in keywords) {
            newStr = newStr.replaceAll(kw, mask);
          }
          map[key] = newStr;
        } else if (key == 'tagList' && value is List) {
          for (int i = 0; i < value.length; i++) {
            if (value[i] is String) {
              String newStr = value[i];
              for (var kw in keywords) {
                newStr = newStr.replaceAll(kw, mask);
              }
              value[i] = newStr;
            }
          }
        } else {
          _replaceKeyword(value, keywords, mask);
        }
      });
    } else if (map is List) {
      for (var item in map) {
        _replaceKeyword(item, keywords, mask);
      }
    }
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

  static List<String> _findTags(dynamic map) {
    if (map is Map) {
      if (map.containsKey('tagList') && map['tagList'] is List) {
        return (map['tagList'] as List).map((e) => e.toString()).toList();
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
    return [];
  }
}
