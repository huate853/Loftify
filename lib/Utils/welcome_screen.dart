import 'package:flutter/material.dart';

import '../../Utils/content_settings.dart';
import '../../Utils/enums.dart';

/// 内容控制台：所有开关集中在这里，改了立即生效。
Future<void> showContentConsole(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const ContentConsole(),
  );
}

/// 首页欢迎页：开屏即搜索，右上角有控制台入口。
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _goSearch() {
    panelScreenState?.jumpToPage(SideBarChoice.Search.index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 20),
                  Text(
                    '欢迎来到老福特',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '点击下方按钮搜索你感兴趣的标签',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _goSearch,
                    icon: const Icon(Icons.search),
                    label: const Text('开始搜索'),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                tooltip: '内容控制台',
                onPressed: () async {
                  await showContentConsole(context);
                  panelScreenState?.initPage();
                },
                icon: const Icon(Icons.tune),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 操作台 UI
class ContentConsole extends StatefulWidget {
  const ContentConsole({super.key});

  @override
  State<ContentConsole> createState() => _ContentConsoleState();
}

class _ContentConsoleState extends State<ContentConsole> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('内容控制台', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '全部默认开启，关闭即可恢复原版行为',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _sw('屏蔽主页算法流（显示欢迎搜索页）', ContentSettings.blockHomeFeed,
                      (v) => ContentSettings.blockHomeFeed = v),
                  _sw('显示右下角悬浮搜索按钮', ContentSettings.showFloatingSearch,
                      (v) => ContentSettings.showFloatingSearch = v),
                  _sw('隐藏底部「动态」Tab', ContentSettings.hideDynamicTab,
                      (v) => ContentSettings.hideDynamicTab = v),
                  _sw('屏蔽评论区', ContentSettings.blockComments,
                      (v) => ContentSettings.blockComments = v),
                  _sw('屏蔽榜单', ContentSettings.blockRank,
                      (v) => ContentSettings.blockRank = v),
                  _sw('屏蔽合集/粮单', ContentSettings.blockCollection,
                      (v) => ContentSettings.blockCollection = v),
                  _sw('屏蔽相关标签', ContentSettings.blockRelatedTags,
                      (v) => ContentSettings.blockRelatedTags = v),
                  _sw('屏蔽相关装扮', ContentSettings.blockRelatedDress,
                      (v) => ContentSettings.blockRelatedDress = v),
                  _sw('屏蔽自动推荐', ContentSettings.blockAutoRecommend,
                      (v) => ContentSettings.blockAutoRecommend = v),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sw(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: (v) {
        onChanged(v);
        setState(() {});
      },
      contentPadding: EdgeInsets.zero,
    );
  }
}
