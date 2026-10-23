import 'package:awesome_chewie/awesome_chewie.dart';

class ContentSettings {
  static const _p = 'lf_content_';

  static bool _getBool(String key) => ChewieHiveUtil.getBool('$_p$key', defaultValue: true);
  static void _setBool(String key, bool v) => ChewieHiveUtil.put('$_p$key', v);

  static int _getInt(String key, int def) => ChewieHiveUtil.getInt('$_p$key', defaultValue: def) ?? def;
  static void _setInt(String key, int v) => ChewieHiveUtil.put('$_p$key', v);

  // ==== 模块开关 ====
  static bool get blockHomeFeed => _getBool('block_home_feed');
  static set blockHomeFeed(bool v) => _setBool('block_home_feed', v);

  static bool get showFloatingSearch => _getBool('show_floating_search');
  static set showFloatingSearch(bool v) => _setBool('show_floating_search', v);

  static bool get hideDynamicTab => _getBool('hide_dynamic_tab');
  static set hideDynamicTab(bool v) => _setBool('hide_dynamic_tab', v);

  static bool get blockComments => _getBool('block_comments');
  static set blockComments(bool v) => _setBool('block_comments', v);

  static bool get blockRank => _getBool('block_rank');
  static set blockRank(bool v) => _setBool('block_rank', v);

  static bool get blockCollection => _getBool('block_collection');
  static set blockCollection(bool v) => _setBool('block_collection', v);

  static bool get blockRelatedTags => _getBool('block_related_tags');
  static set blockRelatedTags(bool v) => _setBool('block_related_tags', v);

  static bool get blockRelatedDress => _getBool('block_related_dress');
  static set blockRelatedDress(bool v) => _setBool('block_related_dress', v);

  static bool get blockAutoRecommend => _getBool('block_auto_recommend');
  static set blockAutoRecommend(bool v) => _setBool('block_auto_recommend', v);

  static bool get blockEveryoneSearch => _getBool('block_everyone_search');
  static set blockEveryoneSearch(bool v) => _setBool('block_everyone_search', v);

  // ==== 点赞过滤 ====
  static int get minLikes => _getInt('min_likes', 0);
  static set minLikes(int v) => _setInt('min_likes', v);

  static int get maxLikes => _getInt('max_likes', 999999999);
  static set maxLikes(int v) => _setInt('max_likes', v);

  // ==== 屏蔽词 ====
  static bool get hideKeywords => _getBool('hide_keywords');
  static set hideKeywords(bool v) => _setBool('hide_keywords', v);
  
  static bool get enableKeywords => _getBool('enable_keywords');
  static set enableKeywords(bool v) => _setBool('enable_keywords', v);

  static List<String> get keywords {
    final raw = ChewieHiveUtil.getString('${_p}keywords') ?? '';
    if (raw.isEmpty) return [];
    return raw.split(',').where((e) => e.isNotEmpty).toList();
  }

  static set keywords(List<String> list) {
    ChewieHiveUtil.put('${_p}keywords', list.join(','));
  }
}
