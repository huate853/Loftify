/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Screens/Login/login_by_captcha_screen.dart';
import 'package:loftify/Screens/Navigation/dynamic_screen.dart';
import 'package:loftify/Screens/Navigation/mine_screen.dart';
import 'package:provider/provider.dart';

import '../Utils/app_provider.dart';
import '../Utils/content_settings.dart';
import '../Utils/enums.dart';
import '../Utils/lottie_files.dart';
import '../Widgets/Navigation/loftify_glass_navigation_bar.dart';
import '../Widgets/loftify_icons.dart';
import '../l10n/l10n.dart';
import 'Navigation/home_screen.dart';
import 'Navigation/search_screen.dart';
import 'Navigation/welcome_screen.dart';

class PanelBackScope extends StatelessWidget {
  const PanelBackScope({
    super.key,
    required this.canRootPop,
    required this.onNestedPop,
    required this.child,
  });

  final bool canRootPop;
  final FutureOr<void> Function() onNestedPop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canRootPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onNestedPop();
      },
      child: child,
    );
  }
}

List<SideBarChoice> visiblePanelChoices({
  required bool hideSearch,
  required bool hideDynamic,
}) =>
    [
      SideBarChoice.Home,
      if (!hideSearch) SideBarChoice.Search,
      if (!hideDynamic) SideBarChoice.Dynamic,
      SideBarChoice.Mine,
    ];

int visiblePanelPageIndex(
  SideBarChoice choice, {
  required bool hideSearch,
  required bool hideDynamic,
}) =>
    visiblePanelChoices(hideSearch: hideSearch, hideDynamic: hideDynamic)
        .indexOf(choice);

class PanelScreen extends StatefulWidget {
  const PanelScreen({
    super.key,
  });

  static const String routeName = "/panel";

  @override
  State<PanelScreen> createState() => PanelScreenState();
}

class PanelScreenState extends BasePanelScreenState<PanelScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        ScrollToHideMixin {
  PageController _pageController = PageController();
  List<Widget> _pageList = [];
  List<GlobalKey> _keyList = [];
  bool unlogin = false;
  int _currentIndex = 0;
  bool _searchNavigationHidden = false;
  bool _dynamicTabHidden = false;

  List<SideBarChoice> get _visibleChoices => visiblePanelChoices(
        hideSearch: appProvider.shouldHideSearchNavigation,
        hideDynamic: ContentSettings.hideDynamicTab,
      );

  int _visibleIndexFor(int logicalIndex) {
    final index = visiblePanelPageIndex(
      SideBarChoice.fromInt(logicalIndex),
      hideSearch: appProvider.shouldHideSearchNavigation,
      hideDynamic: ContentSettings.hideDynamicTab,
    );
    return index < 0 ? 0 : index;
  }

  List<Widget> _buildVisiblePages() => _visibleChoices.map((choice) {
        return switch (choice) {
          SideBarChoice.Home => ContentSettings.blockHomeFeed
              ? WelcomeScreen(key: _keyList[choice.index])
              : HomeScreen(key: _keyList[choice.index]),
          SideBarChoice.Search => SearchScreen(key: _keyList[choice.index]),
          SideBarChoice.Dynamic => DynamicScreen(key: _keyList[choice.index]),
          SideBarChoice.Mine => MineScreen(key: _keyList[choice.index]),
        };
      }).toList();

  void _replacePageController(int logicalIndex) {
    final previous = _pageController;
    _pageController = PageController(
      initialPage: _visibleIndexFor(logicalIndex),
      keepPage: false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
  }

  void _configurePages() {
    _searchNavigationHidden = appProvider.shouldHideSearchNavigation;
    _dynamicTabHidden = ContentSettings.hideDynamicTab;
    _keyList = [
      homeScreenKey,
      searchScreenKey,
      GlobalKey(),
      GlobalKey(),
    ];
    _pageList = _buildVisiblePages();
    _currentIndex = appProvider.sidebarChoice.index;
    _replacePageController(_currentIndex);
  }

  late AnimationController darkModeController;
  Widget? darkModeWidget;
  final ScrollToHideController _scrollToHideController =
      ScrollToHideController();

  GlobalKey<NavigatorState> panelNavigatorKey = GlobalKey<NavigatorState>();

  NavigatorState? get panelNavigatorState => panelNavigatorKey.currentState;

  bool canRootPop = true;
  bool _nestedPopInProgress = false;
  final List<TransitionRoute<dynamic>> _nestedRoutes = [];

  @override
  void initState() {
    super.initState();
    updateStatusBar();
    darkModeController = AnimationController(vsync: this);
    _configurePages();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      darkModeWidget = LottieFiles.buildAnimation(
        LottieFiles.sunLight,
        size: 25,
        autoForward: !ColorUtil.isDark(context),
        controller: darkModeController,
      );
    });
  }

  void login() {
    popAll();
    initPage();
  }

  void logout() {
    popAll();
    initPage();
  }

  @override
  void popAll([bool initPage = true]) {
    _nestedPopInProgress = false;
    _nestedRoutes.clear();
    while (panelNavigatorState?.canPop() ?? false) {
      panelNavigatorState?.pop();
    }
    canRootPop = !(panelNavigatorState?.canPop() ?? false);
    appProvider.showPanelNavigator = false;
    if (initPage) {
      _replacePageController(appProvider.sidebarChoice.index);
    }
  }

  @override
  void pushPage(Widget page) {
    final navigator = panelNavigatorState;
    if (navigator == null) return;
    appProvider.showPanelNavigator = true;
    canRootPop = false;
    if (mounted) setState(() {});
    final TransitionRoute<dynamic> route = ResponsiveUtil.isLandscapeLayout()
        ? RouteUtil.getFadeRoute(page)
        : CustomCupertinoPageRoute(builder: (context) => page);
    _nestedRoutes.add(route);
    unawaited(navigator.push(route));
    unawaited(route.completed.whenComplete(() {
      _nestedRoutes.remove(route);
      _nestedPopInProgress = false;
      _syncPanelAfterRoutePop();
    }));
  }

  void _syncPanelAfterRoutePop() {
    if (!mounted) return;
    final hasNestedPage = panelNavigatorState?.canPop() ?? false;
    canRootPop = !hasNestedPage;
    appProvider.showPanelNavigator = hasNestedPage;
    setState(() {});
  }

  @override
  void popPage() {
    if (_nestedPopInProgress) return;
    final navigator = panelNavigatorState;
    if (navigator == null || !navigator.canPop()) return;
    final route = _nestedRoutes.isEmpty ? null : _nestedRoutes.last;
    final willRemoveRoute = route?.popDisposition == RoutePopDisposition.pop &&
        !(route?.willHandlePopInternally ?? false);
    if (willRemoveRoute) _nestedPopInProgress = true;
    unawaited(navigator.maybePop().whenComplete(() {
      if (route?.animation?.status != AnimationStatus.reverse) {
        _nestedPopInProgress = false;
      }
    }));
  }

  @override
  void updateStatusBar() {
    final brightness = appProvider.getBrightness() ??
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final systemUiOverlayStyle =
        AppBarWrapper.systemUiOverlayStyleForBrightness(
      brightness,
      includeNavigationBar: true,
    );
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  }

  Future<void> initPage() async {
    _configurePages();
    try {
      ILogger.debug("init panel page and jump to $_currentIndex");
    } catch (e, t) {
      ILogger.error("Failed to init panel page", e, t);
    }
    if (mounted) setState(() {});
  }

  void updateSearchNavigationVisibility() {
    if (_keyList.length != SideBarChoice.values.length) return;
    _searchNavigationHidden = appProvider.shouldHideSearchNavigation;
    _dynamicTabHidden = ContentSettings.hideDynamicTab;
    if (appProvider.shouldHideSearchNavigation &&
        _currentIndex == SideBarChoice.Search.index) {
      _currentIndex = SideBarChoice.Home.index;
    }
    if (ContentSettings.hideDynamicTab &&
        _currentIndex == SideBarChoice.Dynamic.index) {
      _currentIndex = SideBarChoice.Home.index;
    }
    _pageList = _buildVisiblePages();
    _replacePageController(_currentIndex);
    if (mounted) setState(() {});
  }

  @override
  void jumpToPage(int index) {
    if (index < 0 || index >= SideBarChoice.values.length) return;
    if (appProvider.shouldHideSearchNavigation &&
        index == SideBarChoice.Search.index) {
      index = SideBarChoice.Home.index;
    }
    if (ContentSettings.hideDynamicTab &&
        index == SideBarChoice.Dynamic.index) {
      index = SideBarChoice.Home.index;
    }
    _scrollToHideController.show();
    if (_currentIndex == index && _keyList.isNotEmpty) {
      BottomNavgationMixin? mixin =
          _keyList[_currentIndex].currentState is BottomNavgationMixin?
              ? _keyList[_currentIndex].currentState as BottomNavgationMixin?
              : null;
      mixin?.onTapBottomNavigation();
    } else {
      _currentIndex = index;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_visibleIndexFor(index));
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void refreshScrollControllers() {
    setState(() {});
  }

  @override
  void showBottomNavigationBar() {
    _scrollToHideController.show();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    MediaQuery.sizeOf(context);
    if (_searchNavigationHidden != appProvider.shouldHideSearchNavigation ||
        _dynamicTabHidden != ContentSettings.hideDynamicTab) {
      _currentIndex = appProvider.sidebarChoice.index;
      updateSearchNavigationVisibility();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var scaffold = Stack(
      children: [
        MyScaffold(
          body: unlogin
              ? Stack(
                  children: [
                    Center(
                      child: RoundIconTextButton(
                        text: appLocalizations.goToLogin,
                        background: ChewieTheme.primaryColor,
                        onPressed: () {
                          RouteUtil.pushDialogRoute(
                            rootContext,
                            const LoginByCaptchaScreen(),
                            popAll: true,
                          );
                        },
                      ),
                    ),
                    ResponsiveUtil.selectByPlatform(
                        andCondition: unlogin,
                        desktop: const WindowMoveHandle()),
                  ],
                )
              : PageView(
                  key: ValueKey(
                      '$_searchNavigationHidden-$_dynamicTabHidden'),
                  physics: const NeverScrollableScrollPhysics(),
                  controller: _pageController,
                  children: _pageList,
                ),
          extendBody: true,
          bottomNavigationBar: ResponsiveUtil.selectByOrientationNullable(
            orCondition: unlogin,
            landscape: null,
            portrait: _buildBottomNavigationBar(),
          ),
        ),
        Selector<AppProvider, bool>(
          selector: (context, provider) => provider.showPanelNavigator,
          builder: (context, value, child) => Offstage(
            offstage: !value,
            child: Navigator(
              key: panelNavigatorKey,
              onGenerateRoute: (settings) {
                return RouteUtil.getFadeRoute(
                  emptyWidget,
                  duration: Duration.zero,
                );
              },
            ),
          ),
        ),
        // ===== 核心：全局悬浮操作台按钮 =====
        Selector<AppProvider, bool>(
          selector: (context, provider) => provider.showPanelNavigator,
          builder: (context, showPanelNavigator, child) {
            if (showPanelNavigator || !ContentSettings.showFloatingSearch) {
              return const SizedBox.shrink();
            }
            return Positioned(
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 90,
              child: FloatingActionButton.small(
                heroTag: 'lf_floating_console',
                onPressed: () async {
                  await showUiConsole(context);
                  initPage();
                },
                child: const Icon(Icons.tune),
              ),
            );
          },
        ),
        // =====================================
      ],
    );
    return PanelBackScope(
      canRootPop: canRootPop,
      onNestedPop: popPage,
      child: scaffold,
    );
  }

  Widget _buildBottomNavigationBar() {
    if (!LoftifyGlassNavigationBar.shouldShowForKeyboard(
      MediaQuery.of(context),
    )) {
      return const SizedBox.shrink();
    }
    return ScrollToHide.multi(
      controller: _scrollToHideController,
      scrollControllers: getScrollControllers(),
      hideDirection: Axis.vertical,
      child: Selector<
          AppProvider,
          ({
            bool reduceTransparency,
            NavigationBarDisplayStyle displayStyle,
            bool hideSearchNavigation,
          })>(
        selector: (context, appProvider) => (
          reduceTransparency: appProvider.reduceTransparency,
          displayStyle: appProvider.navigationBarDisplayStyle,
          hideSearchNavigation: appProvider.shouldHideSearchNavigation,
        ),
        builder: (context, preferences, child) {
          final visibleChoices = visiblePanelChoices(
            hideSearch: preferences.hideSearchNavigation,
            hideDynamic: ContentSettings.hideDynamicTab,
          );
          final currentVisibleIndex = visibleChoices.indexOf(
            SideBarChoice.fromInt(_currentIndex),
          );
          return LoftifyGlassNavigationBar(
            currentIndex:
                currentVisibleIndex < 0 ? 0 : currentVisibleIndex,
            enableBlur: !preferences.reduceTransparency,
            displayStyle: preferences.displayStyle,
            destinations: [
              LoftifyNavigationDestination(
                icon: LoftifyIcons.home,
                lottieAsset: LottieFiles.navHome,
                label: appLocalizations.home,
              ),
              if (!preferences.hideSearchNavigation)
                LoftifyNavigationDestination(
                  icon: LoftifyIcons.search,
                  lottieAsset: LottieFiles.navSearch,
                  label: appLocalizations.search,
                ),
              if (!ContentSettings.hideDynamicTab)
                LoftifyNavigationDestination(
                  icon: LoftifyIcons.activity,
                  lottieAsset: LottieFiles.navHeart,
                  label: appLocalizations.dynamicTab,
                ),
              LoftifyNavigationDestination(
                icon: LoftifyIcons.profile,
                lottieAsset: LottieFiles.navUser,
                label: appLocalizations.mine,
              ),
            ],
            onSelect: (index) {
              appProvider.sidebarChoice = visibleChoices[index];
            },
          );
        },
      ),
    );
  }

  void changeMode() {
    if (ColorUtil.isDark(context)) {
      appProvider.themeMode = ActiveThemeMode.light;
      darkModeController.forward();
    } else {
      appProvider.themeMode = ActiveThemeMode.dark;
      darkModeController.reverse();
    }
  }

  @override
  List<ScrollController> getScrollControllers() {
    if (_currentIndex < 0 || _currentIndex >= _keyList.length) {
      return const [];
    }
    final state = _keyList[_currentIndex].currentState;
    if (state is! ScrollToHideMixin) return const [];
    return (state as ScrollToHideMixin).getScrollControllers();
  }

  @override
  bool get wantKeepAlive => true;
}
