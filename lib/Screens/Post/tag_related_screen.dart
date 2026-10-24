import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/tag_api.dart';
import 'package:loftify/Models/recommend_response.dart';

import '../../Utils/enums.dart';
import '../../Utils/global_filter_overlay.dart';
import '../../Utils/my_content_filter.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/PostItem/recommend_flow_item_builder.dart';
import '../../l10n/l10n.dart';

class TagRelatedScreen extends StatefulWidget {
  const TagRelatedScreen({super.key, required this.tag});

  static const String routeName = "/tag/related";

  final String tag;

  @override
  State<TagRelatedScreen> createState() => _TagRelatedScreenState();
}

class _TagRelatedScreenState extends BaseDynamicState<TagRelatedScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<PostListItem> _postList = [];
  final EasyRefreshController _refreshController = EasyRefreshController();

  int _pageCount = 0;
  bool _loading = false;
  bool _noMore = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GlobalFilterWrapper(
      isTagPage: false,
      onFilterChanged: () {
        _refreshController.callRefresh();
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        backgroundColor: ChewieTheme.getBackground(context),
        body: _buildMainBody(),
      ),
    );
  }

  _fetchResult({bool refresh = false}) async {
    if (_loading) return;
    _loading = true;
    if (refresh) {
      _noMore = false;
      _pageCount = 0;
    } else {
      _pageCount++;
    }
    return await TagApi.getRelatedTagPostList(
      tag: widget.tag,
      count: _pageCount,
    ).then((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(value['msg']);
        } else {
          List<PostListItem> tmp = [];
          var rawListIsEmpty = true;
          if (value['data'] != null) {
            if (value['data']['list'] != null) {
              final rawList = value['data']['list'] as List;
              rawListIsEmpty = rawList.isEmpty;
              final filteredRawList = MyContentFilter.filterRawList(rawList);
              tmp = filteredRawList
                  .whereType<Map>()
                  .map((e) => PostListItem.fromJson(Map<String, dynamic>.from(e)))
                  .toList();
              if (refresh) _postList.clear();
              for (var exist in _postList) {
                tmp.removeWhere((element) => element.itemId == exist.itemId);
              }
              _postList.addAll(tmp);
            }
          }
          if (mounted) setState(() {});
          if (rawListIsEmpty) {
            _noMore = true;
            return IndicatorResult.noMore;
          } else {
            return IndicatorResult.success;
          }
        }
      } catch (e, t) {
        ILogger.error("Failed to load tag related tag post result list", e, t);
        IToast.showTop(appLocalizations.loadFailed);
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
        _loading = false;
      }
    });
  }

  // 修改点：精准移除作品
  void _handleBlockUser(int blogId, int postId) {
    _postList.removeWhere((item) => item.itemId == postId);
    if (mounted) setState(() {});
  }

  _buildMainBody() {
    return EasyRefresh.builder(
      refreshOnStart: true,
      controller: _refreshController,
      onRefresh: () async => await _fetchResult(refresh: true),
      onLoad: () async => await _fetchResult(),
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => LoadMoreNotification(
        noMore: _noMore,
        onLoad: () async => await _fetchResult(),
        child: WaterfallFlow.builder(
          cacheExtent: MediaQuery.sizeOf(context).height,
          physics: physics,
          padding: const EdgeInsets.only(top: 10, left: 8, right: 8),
          gridDelegate: const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            maxCrossAxisExtent: 300,
          ),
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              child: RecommendFlowItemBuilder.buildWaterfallFlowPostItem(
                context,
                _postList[index],
                excludeTag: widget.tag,
                onBlockUser: _handleBlockUser,
              ),
            );
          },
          itemCount: _postList.length,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ResponsiveAppBar(
      backgroundColor: ChewieTheme.getBackground(context),
      showBack: true,
      titleWidget: ClickableWrapper(
        child: ItemBuilder.buildTagItem(
          context,
          widget.tag,
          TagType.normal,
          shownTag: appLocalizations.tagRelatedTags(widget.tag),
          backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
          color: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          showRightIcon: true,
          showTagLabel: false,
        ),
      ),
      centerTitle: true,
      actions: const [BlankIconButton()],
    );
  }
}
