import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:like_button/like_button.dart';
import 'package:loftify/Widgets/BottomSheet/shield_bottom_sheet.dart';
import 'package:loftify/Widgets/PostItem/general_post_item.dart';

import '../../Api/post_api.dart';
import '../../Api/user_api.dart';
import '../../Models/illust.dart';
import '../../Models/post_detail_response.dart';
import '../../Screens/Info/user_detail_screen.dart';
import '../../Screens/Post/post_detail_screen.dart';
import '../../Screens/Post/video_detail_screen.dart';
import '../../Theme/loftify_design_theme.dart';
import '../../Utils/enums.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/uri_util.dart';
import '../../Utils/utils.dart';
import '../../l10n/l10n.dart';
import '../Item/item_builder.dart';
import '../Item/loftify_item_builder.dart';
import '../Design/loftify_surfaces.dart';
import '../loftify_icons.dart';
import '../loftify_reaction_icon.dart';
import 'image_grid.dart';

export 'package:loftify/Widgets/PostItem/general_post_item.dart';

const double _postCardRadius = 12;

double _safePhotoAspectRatio(PhotoLink photo) {
  if (photo.ow <= 0 || photo.oh <= 0) return 1;
  final ratio = photo.ow / photo.oh;
  return ratio.isFinite && ratio > 0 ? ratio : 1;
}

Widget _buildInvalidPostCard(
  BuildContext context, {
  double? width,
  double? height,
  double minHeight = 96,
  double radius = _postCardRadius,
}) {
  return ContainerItem(
    backgroundColor: ChewieTheme.canvasColor,
    radius: radius,
    roundTop: true,
    roundBottom: true,
    border: Border.all(color: Theme.of(context).dividerColor, width: 0.8),
    child: SizedBox(
      width: width,
      height: height,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(builder: (context, constraints) {
              final label = appLocalizations.invalidContent;
              final style = Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.apply(fontWeightDelta: 1);
              final metrics = TextPainter(
                text: TextSpan(text: 'Ag', style: style),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
              )..layout();
              final lineHeight = metrics.height;
              metrics.dispose();
              final showIcon = !constraints.hasBoundedHeight ||
                  constraints.maxHeight >= 29 + lineHeight * 2;
              final availableHeight =
                  constraints.maxHeight - (showIcon ? 29 : 0);
              final lines = constraints.hasBoundedHeight && lineHeight > 0
                  ? (availableHeight / lineHeight).floor().clamp(1, 4)
                  : 4;
              return Tooltip(
                message: label,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showIcon) ...[
                      ChewieIcon(
                        LoftifyIcons.invalidContent,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                      const SizedBox(height: 5),
                    ],
                    Text(
                      label,
                      semanticsLabel: label,
                      maxLines: lines,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: style,
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    ),
  );
}

class WaterfallFlowPostItemWidget extends StatefulWidget {
  final GeneralPostItem item;
  final Function(int blogId, int postId)? onBlockUser;

  const WaterfallFlowPostItemWidget({
    super.key,
    required this.item,
    this.onBlockUser,
  });

  @override
  WaterfallFlowPostItemWidgetState createState() =>
      WaterfallFlowPostItemWidgetState();
}

class WaterfallFlowPostItemWidgetState
    extends State<WaterfallFlowPostItemWidget> {
  late GeneralPostItem item;

  @override
  void initState() {
    super.initState();
    item = widget.item;
  }

  @override
  void didUpdateWidget(covariant WaterfallFlowPostItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    item = widget.item;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        return buildWaterfallFlowPostItem(width: availableWidth);
      },
    );
  }

  Widget buildWaterfallFlowPostItem({required double width}) {
    final radius = context.design.radii.card;
    PostType type = item.type;
    late Widget main;
    switch (type) {
      case PostType.image:
        main = item.photoLinks.isNotEmpty
            ? buildWaterfallFlowImageItem(width: width)
            : item.hasTitleOrContent
                ? buildWaterfallFlowArticleItem(width: width)
                : _buildInvalidPostCard(
                    context,
                    width: width,
                    minHeight: 120,
                    radius: radius,
                  );
      case PostType.article:
        main = item.showArticle ?? true
            ? buildWaterfallFlowArticleItem(width: width)
            : emptyWidget;
      case PostType.video:
        main = item.showVideo ?? true
            ? item.photoLinks.isNotEmpty
                ? buildWaterfallFlowVideoItem(width: width)
                : item.hasTitleOrContent
                    ? buildWaterfallFlowArticleItem(width: width)
                    : _buildInvalidPostCard(
                        context,
                        width
