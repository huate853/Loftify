import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../Utils/content_settings.dart';
import '../../Utils/enums.dart';

/// 内容控制台
Future<void> showContentConsole(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const ContentConsole(),
  );
}

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
                tooltip: '筛选方式',
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

class ContentConsole extends StatefulWidget {
  const ContentConsole({super.key});

  @override
  State<ContentConsole> createState() => _ContentConsoleState();
}

class _ContentConsoleState extends State<ContentConsole> {
  late TextEditingController _minController;
  late TextEditingController _maxController;
  late TextEditingController _keywordController;
  late List<String> _keywords;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController(text: ContentSettings.minLikes.toString());
    _maxController = TextEditingController(text: ContentSettings.maxLikes >= 999999999 ? '' : ContentSettings.maxLikes.toString());
    _keywordController = TextEditingController();
    _keywords = List.from(ContentSettings.keywords);
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  void _saveLikes() {
    ContentSettings.minLikes = int.tryParse(_minController.text) ?? 0;
    ContentSettings.maxLikes = int.tryParse(_maxController.text) ?? 999999999;
    setState(() {});
  }

  void _addKeyword() {
    final text = _keywordController.text.trim();
    if (text.isNotEmpty && !_keywords.contains(text)) {
      setState(() {
        _keywords.add(text);
        ContentSettings.keywords = _keywords;
        _keywordController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: DefaultTabController(
          length: 3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TabBar(
                tabs: [
                  Tab(text: "模块开关"),
                  Tab(text: "热度过滤"),
                  Tab(text: "屏蔽词"),
                ],
              ),
              SizedBox(
                height: 400,
                child: TabBarView(
                  children: [
                    _buildModulesTab(),
                    _buildLikesTab(),
                    _buildKeywordsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModulesTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _sw('主页算法流', ContentSettings.blockHomeFeed, (v) => ContentSettings.blockHomeFeed = v),
        _sw('右下角悬浮搜索', ContentSettings.showFloatingSearch, (v) => ContentSettings.showFloatingSearch = v),
        _sw('隐藏「动态」Tab', ContentSettings.hideDynamicTab, (v) => ContentSettings.hideDynamicTab = v),
        _sw('大家都在搜', ContentSettings.blockEveryoneSearch, (v) => ContentSettings.blockEveryoneSearch = v),
        _sw('榜单', ContentSettings.blockRank, (v) => ContentSettings.blockRank = v),
        _sw('评论区', ContentSettings.blockComments, (v) => ContentSettings.blockComments = v),
        _sw('合集/粮单', ContentSettings.blockCollection, (v) => ContentSettings.blockCollection = v),
        _sw('相关标签', ContentSettings.blockRelatedTags, (v) => ContentSettings.blockRelatedTags = v),
        _sw('相关装扮', ContentSettings.blockRelatedDress, (v) => ContentSettings.blockRelatedDress = v),
        _sw('自动推荐', ContentSettings.blockAutoRecommend, (v) => ContentSettings.blockAutoRecommend = v),
      ],
    );
  }

  Widget _buildLikesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: TextField(controller: _minController, decoration: const InputDecoration(labelText: '最低点赞'), keyboardType: TextInputType.number, onChanged: (_) => _saveLikes())),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('~')),
              Expanded(child: TextField(controller: _maxController, decoration: const InputDecoration(labelText: '最高点赞'), keyboardType: TextInputType.number, onChanged: (_) => _saveLikes())),
            ],
          ),
          const SizedBox(height: 16),
          Text("快捷模板", style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _templateBtn("20~1000", 20, 1000),
              _templateBtn("1000~5000", 1000, 5000),
              _templateBtn("5000以上", 5000, 999999999),
              _templateBtn("清除", 0, 999999999),
            ],
          ),
        ],
      ),
    );
  }

  Widget _templateBtn(String label, int min, int max) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        _minController.text = min.toString();
        _maxController.text = max >= 999999999 ? '' : max.toString();
        _saveLikes();
      },
    );
  }

  Widget _buildKeywordsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sw('启用屏蔽词', ContentSettings.enableKeywords, (v) => ContentSettings.enableKeywords = v),
          _sw('隐藏屏蔽词 (变成██)', ContentSettings.hideKeywords, (v) => ContentSettings.hideKeywords = v),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _keywordController,
                  decoration: const InputDecoration(hintText: '输入屏蔽词，如：abo', isDense: true),
                  onSubmitted: (_) => _addKeyword(),
                ),
              ),
              IconButton(icon: const Icon(Icons.add), onPressed: _addKeyword),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _keywords.map((k) {
                return InputChip(
                  label: Text(k),
                  onDeleted: () {
                    setState(() {
                      _keywords.remove(k);
                      ContentSettings.keywords = _keywords;
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ],
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
      dense: true,
    );
  }
}
