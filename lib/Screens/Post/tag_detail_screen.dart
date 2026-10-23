// ===== 新增：强制覆盖参数并刷新数据 =====
void forceApplyParams(GetTagPostListParams newParam) {
  _hottestParams = newParam.clone();
  _hottestResultOffset = 0;
  _hottestNoMore = false;
  _hottestList.clear(); // 核心：强制清空界面旧数据
  if (mounted) setState(() {});
  _fetchHottestResult(refresh: true);
}

Future<IndicatorResult> _fetchHottestResult({bool refresh = false}) async {
  if (_hottestResultLoading || (!refresh && _hottestNoMore)) {
    return IndicatorResult.none;
  }
  if (refresh) _hottestNoMore = false;
  _hottestResultLoading = true;

  final String postYm = _hottestParams!.postYm;
  TagPostResultType finalResultType = _hottestParams!.tagPostResultType;

  // 核心：只要有 postYm，强制覆盖为 total，强制 offset 为 0
  if (postYm.isNotEmpty) {
    finalResultType = TagPostResultType.total;
  }

  return await TagApi.getPostList(
    _hottestParams!.copyWith(
      offset: postYm.isNotEmpty ? 0 : (refresh ? 0 : _hottestResultOffset),
      tagPostResultType: finalResultType,
      postYm: postYm,
    ),
  ).then<IndicatorResult>((value) {
    try {
      if (value['code'] != 0) {
        IToast.showTop(value['msg']);
        return IndicatorResult.fail;
      } else {
        List<PostListItem> newPosts = [];
        bool rawListIsEmpty = true;
        if (value['data'] != null) {
          if (postYm.isEmpty) {
            _hottestResultOffset = value['data']['offset'];
          }
          if (refresh) _hottestList.clear();

          final rawList = value['data']['list'] as List;
          rawListIsEmpty = rawList.isEmpty;
          final filteredRawList = MyContentFilter.filterRawList(rawList);
          newPosts = filteredRawList
              .whereType<Map>()
              .map((e) =>
                  PostListItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();

          newPosts.removeWhere((e) =>
              _hottestList.any((element) => element.itemId == e.itemId));
          _hottestList.addAll(newPosts);
          _hottestList
              .removeWhere((e) => RecommendFlowItemBuilder.isInvalid(e));
        }
        if (mounted) setState(() {});
        _hottestNoMore = rawListIsEmpty;
        if (_hottestNoMore && !refresh) {
          return IndicatorResult.noMore;
        } else {
          return IndicatorResult.success;
        }
      }
    } catch (e, t) {
      ILogger.error("Failed to load tag hottest result list", e, t);
      return IndicatorResult.fail;
    } finally {
      if (mounted) setState(() {});
      _hottestResultLoading = false;
    }
  });
}
