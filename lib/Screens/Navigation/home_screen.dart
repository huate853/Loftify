import 'dart:async';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/recommend_api.dart';
import 'package:loftify/Widgets/PostItem/recommend_flow_item_builder.dart';
import 'package:provider/provider.dart';

import '../../Models/recommend_response.dart';
import '../../Theme/loftify_design_theme.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/lottie_files.dart';
import '../../Utils/paged_data_controller.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';
import 'search_screen.dart';
import '../../Utils/content_settings.dart';
import '../../Utils/my_content_filter.dart';
import 'welcome_screen.dart';

int krefreshTimeout = 300;
typedef _ExploreCursor = ({int offset, int page, int feed});

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.scrollController});
  final ScrollController? scrollController;
  static const String routeName = "/nav/home";

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends BaseDynamicState<HomeScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin, ScrollToHideMixin, BottomNavgationMixin {
  @override
  bool get wantKeepAlive => true;
  int lastRefreshTime = 0;
  final EasyRefreshController _refreshController = EasyRefreshController();
  late final ScrollController _scrollController = widget.scrollController ?? ScrollController();
  final ScrollController _nestedScrollController = ScrollController();
  ScrollController? _nestedInnerScrollController;
  late final PagedDataController<PostListItem, int, _ExploreCursor, void> _pagingController;
  late AnimationController _refreshRotationController;
  final ScrollToHideController _scrollToHideController = ScrollToHideController();
  
  bool _showFilterOverlay = false;
  int _tempMin = 0;
  int _tempMax = 999999999;
  bool _tempEnableKw = false;

  Future<void> refresh() async {
    await _scrollHomeToTop();
    if (mounted) await _triggerRefresh();
  }

  @override
  void initState() {
    super.initState();
    _refreshRotationController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _pagingController = PagedDataController(
      initialCursor: (offset: 0, page: 0, feed: 0),
      keyOf: (item) => item.postData?.postView.id ?? item.itemId,
      loader: _loadExplorePage,
      onError: (error, stackTrace) {
        if (!mounted) return;
        IToast.showTop(error is PagedDataException && StringUtil.isNotEmpty(error.message) ? error.message : appLocalizations.loadFailed);
      },
    )..addListener(_handlePagingChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) panelScreenState?.refreshScrollControllers();
    });
  }

  Future<PagedDataPage<PostListItem, _ExploreCursor, void>> _loadExplorePage(_ExploreCursor cursor, bool refresh) async {
    final page = refresh ? 1 : cursor.page + 1;
    final feed = refresh ? 0 : cursor.feed + 1;
    final value = await RecommendApi.getExploreRecomend(offset: refresh ? 0 : cursor.offset, page: page, feed: feed);
    final code = (value['code'] as num?)?.toInt();
    if (code == 4009) return PagedDataPage(items: const [], nextCursor: cursor, hasMore: false);
    if (code != 0) throw PagedDataException(value['msg']?.toString() ?? '');

    final data = value['data'];
    if (data is! Map) throw const PagedDataException('');
    
    final rawItems = data['list'] is List ? List<dynamic>.from(data['list'] as List) : const <dynamic>[];
    final filteredRawItems = MyContentFilter.filterRawList(rawItems);
    
    final items = <PostListItem>[];
    for (final rawItem in filteredRawItems) { 
      try {
        if (rawItem is Map) {
          items.add(PostListItem.fromJson(Map<String, dynamic>.from(rawItem)));
        }
      } catch (e) {}
    }
    final nextOffset = (data['offset'] as num?)?.toInt() ?? cursor.offset;
    return PagedDataPage(
      items: items,
      nextCursor: (offset: nextOffset, page: page, feed: feed),
      hasMore: rawItems.isNotEmpty,
    );
  }

  void _handlePagingChanged() { if (mounted) setState(() {}); }
  Future<IndicatorResult> _onRefresh() => _pagingController.refresh();
  Future<IndicatorResult> _onLoad() => _pagingController.load();

  @override
  void dispose() {
    _pagingController..removeListener(_handlePagingChanged)..dispose();
    _refreshController.dispose();
    _refreshRotationController.dispose();
    _nestedScrollController.dispose();
    if (widget.scrollController == null) _scrollController.dispose();
    super.dispose();
  }

  void _toggleFilterOverlay() {
    if (!_showFilterOverlay) {
      _tempMin = ContentSettings.minLikes;
      _tempMax = ContentSettings.maxLikes;
      _tempEnableKw = ContentSettings.enableKeywords;
    } else {
      if (_tempMin != ContentSettings.minLikes || _tempMax != ContentSettings.maxLikes || _tempEnableKw != ContentSettings.enableKeywords) {
        _onRefresh();
      }
    }
    setState(() => _showFilterOverlay = !_showFilterOverlay);
  }

  void _handleBlockUser(int blogId) {
    _pagingController.items.removeWhere((item) {
      final itemBlogId = item.blogInfo?.blogId ?? item.postData?.postView.blogId;
      return itemBlogId == blogId;
    });
    if (mounted) {
      setState(() {});
      IToast.showTop("已拉黑");
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (ContentSettings.blockHomeFeed) return const WelcomeScreen();
    
    MediaQuery.sizeOf(context);
    final design = context.design;
    final hideAppBar = context.select<AppProvider, bool>((provider) => provider.shouldHideHomeAppBarOnScroll);
    final showSearchAction = context.select<AppProvider, bool>((provider) => provider.shouldHideSearchNavigation);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: design.colors.page,
          appBar: hideAppBar ? null : _buildHomeAppBar(showSearchAction),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final viewportWidth = constraints.maxWidth;
              final centeredInset = ((viewportWidth - design.grid.maximumContentWidth) / 2).clamp(0.0, double.infinity);
              final pageInset = design.grid.denseFeedPagePaddingFor(viewportWidth);
              final horizontalInset = centeredInset + pageInset;
              final gutter = design.grid.gutterFor(viewportWidth);

              if (!hideAppBar) {
                return _buildFeed(design: design, horizontalInset: horizontalInset, gutter: gutter, scrollController: _scrollController, hideAppBar: false);
              }

              return ExtendedNestedScrollView(
                controller: _nestedScrollController,
                floatHeaderSlivers: true,
                onlyOneScrollInBody: true,
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverAppBar(
                    key: const ValueKey('home-floating-app-bar'),
                    floating: true, snap: true, pinned: false, toolbarHeight: 48, titleSpacing: 15,
                    elevation: 0, scrolledUnderElevation: 0, surfaceTintColor: Colors.transparent, backgroundColor: design.colors.page,
                    title: Text(appLocalizations.home, style: ChewieTheme.titleMedium.apply(fontWeightDelta: 2)),
                    actions: _buildActions(showSearchAction),
                  ),
                ],
                body: Builder(
                  builder: (context) {
                    final innerController = PrimaryScrollController.of(context);
                    if (!identical(_nestedInnerScrollController, innerController)) {
                      _nestedInnerScrollController = innerController;
                      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) panelScreenState?.refreshScrollControllers(); });
                    }
                    return _buildFeed(design: design, horizontalInset: horizontalInset, gutter: gutter, scrollController: innerController, hideAppBar: true);
                  },
                ),
              );
            },
          ),
        ),
        
        if (_showFilterOverlay)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleFilterOverlay,
              behavior: HitTestBehavior.translucent,
              child: Container(
                color: Colors.black.withOpacity(0.1),
                alignment: Alignment.topRight,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + (hideAppBar ? 50 : kToolbarHeight),
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: GestureDetector(
                  onTap: () {},
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).colorScheme.surface,
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 0.85,
                      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16, right: 8, top: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('作品过滤', style: Theme.of(context).textTheme.titleMedium),
                                IconButton(icon: const Icon(Icons.close, size: 20), onPressed: _toggleFilterOverlay),
                              ],
                            ),
                          ),
                          const Flexible(child: FilterConsole()),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFeed({required LoftifyDesignThemeData design, required double horizontalInset, required double gutter, required ScrollController scrollController, required bool hideAppBar}) {
    return Stack(
      children: [
        EasyRefresh.builder(
          refreshOnStart: true, controller: _refreshController, scrollController: scrollController,
          header: hideAppBar ? LottieCupertinoHeader(backgroundColor: Colors.transparent, indicator: LottieFiles.buildLoadingAnimation(40, false), safeArea: false, clamping: true, hapticFeedback: true, triggerOffset: 56, maxOverOffset: 84, radius: 20) : null,
          onRefresh: _onRefresh, onLoad: _pagingController.noMore ? null : _onLoad,
          childBuilder: (context, physics) => CustomScrollView(
            controller: scrollController, physics: physics, cacheExtent: MediaQuery.sizeOf(context).height,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.only(top: 8, left: horizontalInset, right: horizontalInset),
                sliver: SliverWaterfallFlow(
                  gridDelegate: SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(mainAxisSpacing: gutter, crossAxisSpacing: gutter, maxCrossAxisExtent: design.grid.maximumDenseCardExtent),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = _pagingController.items[index];
                      return KeyedSubtree(
                        key: ValueKey('explore-${item.postData?.postView.id ?? item.itemId}'),
                        child: RecommendFlowItemBuilder.buildWaterfallFlowPostItem(
                          context, 
                          item, 
                          showMoreButton: true,
                          onBlockUser: _handleBlockUser,
                        ),
                      );
                    },
                    childCount: _pagingController.items.length, addAutomaticKeepAlives: false,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: horizontalInset,
          bottom: ResponsiveUtil.isLandscapeLayout() ? design.spacing.xl : 76,
          child: ScrollToHide.multi(
            controller: _scrollToHideController, scrollControllers: hideAppBar ? [_nestedScrollController, scrollController] : [scrollController], hideDirection: Axis.vertical,
            child: _buildFloatingButtons(),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions(bool showSearchAction) {
    return [
      if (showSearchAction) _buildSearchAction(),
      IconButton(
        icon: Icon(Icons.filter_alt_outlined, color: _showFilterOverlay ? Theme.of(context).primaryColor : null),
        tooltip: '作品过滤',
        onPressed: _toggleFilterOverlay,
      ),
      const SizedBox(width: 8),
    ];
  }

  ResponsiveAppBar _buildHomeAppBar(bool showSearchAction) {
    return ResponsiveAppBar(
      title: appLocalizations.home, titleLeftMargin: 15,
      actions: _buildActions(showSearchAction), landscapeActions: _buildActions(showSearchAction),
    );
  }

  Widget _buildSearchAction() {
    return ChewieIconButton(icon: LoftifyIcons.search, tooltip: appLocalizations.search, onPressed: () => RouteUtil.pushPanelCupertinoRoute(context, const SearchScreen(showBack: true)));
  }

  Future<void> _refreshFromHomeNavigation() async {
    final distanceFromTop = _homeDistanceFromTop;
    final shouldRefreshAfterScroll = distanceFromTop <= MediaQuery.sizeOf(context).height / 2;
    if (distanceFromTop > 1) {
      await _scrollHomeToTop();
      if (!mounted || !shouldRefreshAfterScroll) return;
    }
    await _triggerRefresh();
  }

  double get _homeDistanceFromTop {
    final feed = _feedScrollController;
    final feedDistance = feed.hasClients && feed.offset > 0 ? feed.offset : 0.0;
    final appBarDistance = appProvider.shouldHideHomeAppBarOnScroll && _nestedScrollController.hasClients && !identical(feed, _nestedScrollController) ? (_nestedScrollController.offset > 0 ? _nestedScrollController.offset : 0.0) : 0.0;
    return feedDistance + appBarDistance;
  }

  Future<void> _triggerRefresh() async {
    final feed = _feedScrollController;
    if (!mounted || !feed.hasClients || _pagingController.loading) return;
    final nowTime = DateTime.now().millisecondsSinceEpoch;
    if (lastRefreshTime != 0 && nowTime - lastRefreshTime <= krefreshTimeout) return;
    lastRefreshTime = nowTime;
    await _refreshController.callRefresh(scrollController: feed, jumpToEdge: !appProvider.shouldHideHomeAppBarOnScroll);
  }

  void scrollToTopAndRefresh() => unawaited(refresh());
  Widget _buildFloatingButtons() => ResponsiveUtil.isLandscapeLayout() ? Column(children: [ShadowIconButton(boxShadow: const [], icon: RotationTransition(turns: Tween(begin: 0.0, end: 1.0).animate(_refreshRotationController), child: const ChewieIcon(LoftifyIcons.refresh)), onTap: () async { refresh(); }), const SizedBox(height: 10), ShadowIconButton(boxShadow: const [], icon: const ChewieIcon(LoftifyIcons.scrollTop), onTap: () { scrollToTop(); })]) : emptyWidget;
  ScrollController get _feedScrollController => appProvider.shouldHideHomeAppBarOnScroll ? _nestedInnerScrollController ?? _nestedScrollController : _scrollController;
  Future<void> _scrollHomeToTop() async {
    final feed = _feedScrollController;
    if (feed.hasClients && feed.offset > 0) await feed.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    if (appProvider.shouldHideHomeAppBarOnScroll && _nestedScrollController.hasClients && _nestedScrollController.offset > 0) await _nestedScrollController.animateTo(0, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
  }
  void scrollToTop() => unawaited(_scrollHomeToTop());
  void scrollToTopOrRefresh() => unawaited(_refreshFromHomeNavigation());
  
  @override
  List<ScrollController> getScrollControllers() {
    if (!appProvider.shouldHideHomeAppBarOnScroll) return [_scrollController];
    final inner = _nestedInnerScrollController;
    return [_nestedScrollController, if (inner != null && !identical(inner, _nestedScrollController)) inner];
  }
  
  @override
  FutureOr onTapBottomNavigation() => _refreshFromHomeNavigation();
}
