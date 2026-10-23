import 'package:awesome_chewie/awesome_chewie.dart';

/// 内容过滤开关：全部默认开启。
/// 关掉某个开关后，应用行为立即恢复原版；所有状态存 Hive，重启保留。
class ContentSettings {
  static const _p = 'lf_content_';

  static bool _get(String key) =>
      ChewieHiveUtil.getBool('$_p$key', defaultValue: true);
  static void _set(String key, bool v) => ChewieHiveUtil.put('$_p$key', v);

  /// 屏蔽主页算法流（首页显示欢迎搜索页）
  static bool get blockHomeFeed => _get('block_home_feed');
  static set blockHomeFeed(bool v) => _set('block_home_feed', v);

  /// 显示右下角悬浮搜索按钮
  static bool get showFloatingSearch => _get('show_floating_search');
  static set showFloatingSearch(bool v) => _set('show_floating_search', v);

  /// 隐藏底部导航「动态」Tab
  static bool get hideDynamicTab => _get('hide_dynamic_tab');
  static set hideDynamicTab(bool v) => _set('hide_dynamic_tab', v);

  /// 屏蔽评论区
  static bool get blockComments => _get('block_comments');
  static set blockComments(bool v) => _set('block_comments', v);

  /// 屏蔽榜单模块
  static bool get blockRank => _get('block_rank');
  static set blockRank(bool v) => _set('block_rank', v);

  /// 屏蔽合集/粮单
  static bool get blockCollection => _get('block_collection');
  static set blockCollection(bool v) => _set('block_collection', v);

  /// 屏蔽相关标签
  static bool get blockRelatedTags => _get('block_related_tags');
  static set blockRelatedTags(bool v) => _set('block_related_tags', v);

  /// 屏蔽相关装扮
  static bool get blockRelatedDress => _get('block_related_dress');
  static set blockRelatedDress(bool v) => _set('block_related_dress', v);

  /// 屏蔽自动推荐
  static bool get blockAutoRecommend => _get('block_auto_recommend');
  static set blockAutoRecommend(bool v) => _set('block_auto_recommend', v);
}
