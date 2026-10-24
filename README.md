# Loftify魔改版…

本项目 Fork 自 [Robert-Stackflow/Loftify](https://github.com/Robert-Stackflow/Loftify)（原作者：[Robert-Stackflow](https://github.com/Robert-Stackflow)）。

首先，**非常感谢原作者的开源精神！** 没有原项目打下的坚实基础，就不会有这些拓展功能。

## ⚠️ 重要免责声明
**本仓库中的修改代码均由 AI（大语言模型）辅助生成，未经专业程序员的人工代码审阅，仅经过了人工的功能测试。**
因此，代码质量和底层逻辑可能与原作者的精良水准有差距。如果你在使用过程中遇到问题，请理解这属于个人魔改版的局限性。本仓库仅供个人学习、测试和交流使用。

## 🛠️ 本分支新增/修改的功能
相比原版，本版本主要针对文章列表的“信息流管理”做了一些列增强，具体包括：
1. **Tag 页面按具体月份筛选**：支持选择具体的年份和月份，强制向服务器请求该特定年月（`postYm`）的作品，方便考古。
2. **Tag 页面按点赞数（心心）区间筛选**：支持输入最低和最高点赞数，提供快捷区间模板。
3. **本地屏蔽词过滤（针对文章标题与 Tag）**：命中屏蔽词的文章直接在本地隐藏（非替换字符）。支持“隐藏操作台标签”防窥视功能（灵感来源于 B 站 UP 主 tjxgame 的插件《Bilibili 按标签、标题、时长、UP主屏蔽视频》，在此表示感谢）。
4. **主页/全站右下角操作台（模块屏蔽开关）**：提供一键屏蔽各类冗余模块的开关，包括：主页算法流、隐藏动态 Tab、大家都在搜、榜单、评论区、合集/粮单、相关标签、相关装扮、自动推荐等。
5. **快捷拉黑（⊘）**：在瀑布流卡片的作者名字旁增加 ⊘ 按钮，点击后调用原版 API 拉黑作者，并将当前文章从列表中即刻抹除。

---
*(以下为原作者的项目介绍内容)*








# Loftify

A LOFTER third-party APP developed based on Flutter.

# Features

- [x] Recommended features
  - [x] Home page recommendation flow
  - [x] Support blocking articles/videos
  - [x] Recommendations within tags
- [x] Subscription function
  - [x] Subscribed tags
  - [x] Subscribed collections
  - [x] Subscribed food orders
- [x] Support search function
- [x] Save original image
- [x] Support collection and food list functions
- [x] Support my likes, my recommendations, my collections, and my footprints
- [x] Support my works, my collections, my food list
- [x] Support personal homepage
- [x] Support checking for updates
- [x] Support gesture password
- [ ] Support creative
  - [ ] supports publishing posts
  - [ ] Support managing favorites
  - [ ] Support management of food orders
  - [ ] Support management collections
