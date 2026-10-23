import 'package:flutter/material.dart';
import 'content_settings.dart';

/// 全局筛选悬浮组件
/// 将任何页面包裹进去，右上角自动出现筛选按钮
class GlobalFilterWrapper extends StatefulWidget {
  final Widget child;
  final bool isTagPage; // 只有 Tag 页传 true，显示月份筛选
  final VoidCallback? onFilterChanged; // 筛选条件变动后的回调（用于刷新列表）

  const GlobalFilterWrapper({
    super.key,
    required this.child,
    this.isTagPage = false,
    this.onFilterChanged,
  });

  @override
  State<GlobalFilterWrapper> createState() => _GlobalFilterWrapperState();
}

class _GlobalFilterWrapperState extends State<GlobalFilterWrapper> {
  bool _showOverlay = false;

  void _toggleOverlay() {
    setState(() => _showOverlay = !_showOverlay);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. 原本的页面内容
        widget.child,

        // 2. 悬浮按钮（永远是右上角）
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 12,
          child: GestureDetector(
            onTap: _toggleOverlay,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
                border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune,
                    color: _showOverlay ? Theme.of(context).primaryColor : Theme.of(context).iconTheme.color,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '筛选',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _showOverlay ? Theme.of(context).primaryColor : Theme.of(context).iconTheme.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 3. 点击后的带遮罩弹窗
        if (_showOverlay)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleOverlay, // 点击外部关闭
              behavior: HitTestBehavior.translucent,
              child: Container(
                color: Colors.black.withValues(alpha: 0.15), // 半透明遮罩
                alignment: Alignment.topRight,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 50, // 留出按钮空间
                  right: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20, // 键盘避让
                ),
                child: GestureDetector(
                  onTap: () {}, // 阻止点击内部关闭
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).colorScheme.surface,
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 0.85,
                      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.65),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerColor, width: 0.8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 弹窗头部：标题 + 关闭按钮
                          Padding(
                            padding: const EdgeInsets.only(left: 16, right: 4, top: 4, bottom: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('筛选', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: _toggleOverlay,
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          // 弹窗内容
                          Flexible(
                            child: FilterConsole(
                              isTagPage: widget.isTagPage,
                              onChanged: () {
                                // 当选项改变时，触发外部的刷新回调
                                if (widget.onFilterChanged != null) {
                                  widget.onFilterChanged!();
                                }
                              },
                            ),
                          ),
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
}

/// 筛选面板内容
class FilterConsole extends StatefulWidget {
  final bool isTagPage;
  final VoidCallback? onChanged;

  const FilterConsole({super.key, required this.isTagPage, this.onChanged});

  @override
  State<FilterConsole> createState() => _FilterConsoleState();
}

class _FilterConsoleState extends State<FilterConsole> {
  late TextEditingController _minController;
  late TextEditingController _maxController;
  late TextEditingController _keywordController;
  late List<String> _keywords;

  int _selectedYear = ContentSettings.tagSelectedYear;
  int _selectedMonth = ContentSettings.tagSelectedMonth;

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
    widget.onChanged?.call();
  }

  void _addKeyword() {
    final text = _keywordController.text.trim();
    if (text.isNotEmpty && !_keywords.contains(text)) {
      setState(() {
        _keywords.add(text);
        ContentSettings.keywords = _keywords;
        _keywordController.clear();
      });
      widget.onChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 如果是 Tag 页，就有 3 个 Tab
    return DefaultTabController(
      length: widget.isTagPage ? 3 : 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            tabs: [
              const Tab(text: "热度筛选"),
              const Tab(text: "屏蔽词"),
              if (widget.isTagPage) const Tab(text: "月份筛选"),
            ],
          ),
          Flexible(
            child: TabBarView(
              children: [
                _buildLikesTab(),
                _buildKeywordsTab(),
                if (widget.isTagPage) _buildTimeTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikesTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minController,
                decoration: const InputDecoration(labelText: '最低点赞', isDense: true),
                keyboardType: TextInputType.number,
                onChanged: (_) => _saveLikes(),
              ),
            ),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('~')),
            Expanded(
              child: TextField(
                controller: _maxController,
                decoration: const InputDecoration(labelText: '最高点赞', isDense: true),
                keyboardType: TextInputType.number,
                onChanged: (_) => _saveLikes(),
              ),
            ),
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
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("启用屏蔽词", style: TextStyle(fontWeight: FontWeight.bold)),
            Switch(
              value: ContentSettings.enableKeywords,
              onChanged: (v) {
                setState(() => ContentSettings.enableKeywords = v);
                widget.onChanged?.call();
              },
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("隐藏操作台标签 (防窥视)"),
            Switch(
              value: ContentSettings.hideKeywords,
              onChanged: (v) {
                setState(() => ContentSettings.hideKeywords = v);
                widget.onChanged?.call();
              },
            ),
          ],
        ),
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
        if (ContentSettings.hideKeywords)
          Text(
            _keywords.asMap().entries.map((e) => '屏蔽词${e.key + 1}').join(''),
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _keywords.map((k) => InputChip(
              label: Text(k),
              onDeleted: () {
                setState(() {
                  _keywords.remove(k);
                  ContentSettings.keywords = _keywords;
                });
                widget.onChanged?.call();
              },
            )).toList(),
          ),
      ],
    );
  }

  Widget _buildTimeTab() {
    final currentYear = DateTime.now().year;
    // 生成近 10 年的选项
    final years = List.generate(10, (index) => currentYear - index);
    final months = List.generate(12, (index) => index + 1);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          "仅 Tag 页生效：按选定年月从热到冷重排",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: '年份', isDense: true),
                value: _selectedYear == 0 ? null : _selectedYear,
                items: years
                    .map((e) => DropdownMenuItem(value: e, child: Text('$e 年')))
                    .toList(),
                onChanged: (v) {
                  setState(() => _selectedYear = v ?? 0);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: '月份', isDense: true),
                value: _selectedMonth == 0 ? null : _selectedMonth,
                items: months
                    .map((e) => DropdownMenuItem(value: e, child: Text('$e 月')))
                    .toList(),
                onChanged: (v) {
                  setState(() => _selectedMonth = v ?? 0);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedYear == 0 || _selectedMonth == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("请先选择年份和月份")),
                    );
                    return;
                  }
                  ContentSettings.tagSelectedYear = _selectedYear;
                  ContentSettings.tagSelectedMonth = _selectedMonth;
                  widget.onChanged?.call();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("时间筛选已应用，请切换到「最热」查看")),
                  );
                },
                child: const Text("应用时间"),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _selectedYear = 0;
                    _selectedMonth = 0;
                  });
                  ContentSettings.tagSelectedYear = 0;
                  ContentSettings.tagSelectedMonth = 0;
                  widget.onChanged?.call();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("已清除时间限制")),
                  );
                },
                child: const Text("清除时间"),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
