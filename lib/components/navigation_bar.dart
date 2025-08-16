part of 'components.dart';

class PaneItemEntry {
  String label;

  IconData icon;

  IconData activeIcon;

  PaneItemEntry(
      {required this.label, required this.icon, required this.activeIcon});
}

class PaneActionEntry {
  String label;

  IconData icon;

  VoidCallback onTap;

  PaneActionEntry(
      {required this.label, required this.icon, required this.onTap});
}

class NaviPane extends StatefulWidget {
  const NaviPane(
      {required this.paneItems,
      required this.paneActions,
      required this.pageBuilder,
      this.initialPage = 0,
      this.onPageChange,
      required this.observer,
      super.key});

  final List<PaneItemEntry> paneItems;

  final List<PaneActionEntry> paneActions;

  final Widget Function(int page) pageBuilder;

  final void Function(int index)? onPageChange;

  final int initialPage;

  final NaviObserver observer;

  @override
  State<NaviPane> createState() => _NaviPaneState();
}

class _NaviPaneState extends State<NaviPane>
    with SingleTickerProviderStateMixin {
  late int _currentPage = widget.initialPage;

  int get currentPage => _currentPage;

  set currentPage(int value) {
    if (value == _currentPage) return;
    _currentPage = value;
    widget.onPageChange?.call(value);
  }

  late AnimationController controller;

  static const _kBottomBarHeight = 58.0;

  static const _kFoldedSideBarWidth = 80.0;

  static const _kSideBarWidth = 256.0;

  static const _kTopBarHeight = 48.0;

  double get bottomBarHeight =>
      _kBottomBarHeight + MediaQuery.of(context).padding.bottom;

  void onNavigatorStateChange() {
    onRebuild(context);
  }

  @override
  void initState() {
    controller = AnimationController(
        duration: const Duration(milliseconds: 250),
        lowerBound: 0,
        upperBound: 3,
        vsync: this);
    widget.observer.addListener(onNavigatorStateChange);
    StateController.put(NaviPaddingWidgetController());
    super.initState();
  }

  @override
  void didChangeDependencies() {
    controller.value = targetFormContext(context);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    StateController.remove<NaviPaddingWidgetController>();
    controller.dispose();
    widget.observer.removeListener(onNavigatorStateChange);
    super.dispose();
  }

  double targetFormContext(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    double target = 0;
    if (widget.observer.pageCount > 1) {
      target = 1;
    }
    if (width > changePoint) {
      target = 2;
    }
    if (width > changePoint2) {
      target = 3;
    }
    return target;
  }

  double? animationTarget;

  void onRebuild(BuildContext context) {
    double target = targetFormContext(context);
    if (controller.value != target || animationTarget != target) {
      if (controller.isAnimating) {
        if (animationTarget == target) {
          return;
        } else {
          controller.stop();
        }
      }
      if (target == 1) {
        StateController.find<NaviPaddingWidgetController>()
            .setWithPadding(true);
        controller.value = target;
      } else if (controller.value == 1 && target == 0) {
        StateController.findOrNull<NaviPaddingWidgetController>()
            ?.setWithPadding(false);
        controller.value = target;
      } else {
        controller.animateTo(target,
            duration: const Duration(milliseconds: 160), curve: Curves.ease);
      }
      animationTarget = target;
    }
  }

  @override
  Widget build(BuildContext context) {
    onRebuild(context);
    return _NaviPopScope(
      action: () {
        if (App.mainNavigatorKey!.currentState!.canPop()) {
          App.mainNavigatorKey!.currentState!.pop();
        } else {
          SystemNavigator.pop();
        }
      },
      popGesture: App.isIOS && !UiMode.m1(context),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final value = controller.value;
          return Stack(
            children: [
              if (value <= 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: bottomBarHeight * (0 - value),
                  child: buildBottom(),
                ),
              if (value <= 1)
                Positioned(
                  left: 0,
                  right: 0,
                  top: _kTopBarHeight * (0 - value) +
                      MediaQuery.of(context).padding.top * (1 - value),
                  child: buildTop(),
                ),
              Positioned(
                left: _kFoldedSideBarWidth * ((value - 2.0).clamp(-1.0, 0.0)),
                top: 0,
                bottom: 0,
                child: buildLeft(),
              ),
              Positioned(
                top: _kTopBarHeight * ((1 - value).clamp(0, 1)) +
                    MediaQuery.of(context).padding.top * (value == 1 ? 0 : 1),
                left: _kFoldedSideBarWidth * ((value - 1).clamp(0, 1)) +
                    (_kSideBarWidth - _kFoldedSideBarWidth) *
                        ((value - 2).clamp(0, 1)),
                right: 0,
                bottom: bottomBarHeight * ((1 - value).clamp(0, 1)),
                child: MediaQuery.removePadding(
                  removeTop: value >= 2 || value == 0,
                  context: context,
                  child: Material(child: widget.pageBuilder(currentPage)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildTop() {
    return Material(
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 16),
        height: _kTopBarHeight,
        width: double.infinity,
        child: Row(
          children: [
            Text(
              widget.paneItems[currentPage].label,
              style: const TextStyle(fontSize: 18),
            ),
            const Spacer(),
            for (var action in widget.paneActions)
              Tooltip(
                message: action.label,
                child: IconButton(
                  icon: Icon(action.icon),
                  onPressed: action.onTap,
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget buildBottom() {
    return Material(
      textStyle: Theme.of(context).textTheme.labelSmall,
      elevation: 0,
      child: Container(
        height: _kBottomBarHeight + MediaQuery.of(context).padding.bottom,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 0.6,
            ),
          ),
        ),
        child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: Row(
            children: List<Widget>.generate(
                widget.paneItems.length,
                (index) => Expanded(
                        child: _SingleBottomNaviWidget(
                      enabled: currentPage == index,
                      entry: widget.paneItems[index],
                      onTap: () {
                        setState(() {
                          currentPage = index;
                        });
                      },
                      key: ValueKey(index),
                    ))),
          ),
        ),
      ),
    );
  }

  Widget buildLeft() {
    final value = controller.value;
    const paddingHorizontal = 12.0;
    return Material(
      child: Container(
        width: _kFoldedSideBarWidth +
            (_kSideBarWidth - _kFoldedSideBarWidth) * ((value - 2).clamp(0, 1)),
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: paddingHorizontal),
        child: Row(
          children: [
            SizedBox(
              width: value == 3
                  ? (_kSideBarWidth - paddingHorizontal * 2)
                  : (_kFoldedSideBarWidth - paddingHorizontal * 2),
              child: Column(
                children: [
                  const SizedBox(
                    height: 16,
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).padding.top,
                  ),
                  ...List<Widget>.generate(
                    widget.paneItems.length,
                    (index) => _SideNaviWidget(
                      enabled: currentPage == index,
                      entry: widget.paneItems[index],
                      showTitle: value == 3,
                      onTap: () {
                        setState(() {
                          currentPage = index;
                        });
                      },
                      key: ValueKey(index),
                    ),
                  ),
                  const Spacer(),
                  ...List<Widget>.generate(
                    widget.paneActions.length,
                    (index) => _PaneActionWidget(
                      entry: widget.paneActions[index],
                      showTitle: value == 3,
                      key: ValueKey(index + widget.paneItems.length),
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  )
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _SideNaviWidget extends StatefulWidget {
  const _SideNaviWidget(
      {required this.enabled,
      required this.entry,
      required this.onTap,
      required this.showTitle,
      super.key});

  final bool enabled;

  final PaneItemEntry entry;

  final VoidCallback onTap;

  final bool showTitle;

  @override
  State<_SideNaviWidget> createState() => _SideNaviWidgetState();
}

class _SideNaviWidgetState extends State<_SideNaviWidget> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon =
        Icon(widget.enabled ? widget.entry.activeIcon : widget.entry.icon);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (details) => setState(() => isHovering = true),
      onExit: (details) => setState(() => isHovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onTap,
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            width: double.infinity,
            height: widget.showTitle ? 42 : 34,
            decoration: BoxDecoration(
                color: widget.enabled
                    ? colorScheme.primaryContainer
                    : isHovering
                        ? colorScheme.surfaceContainerHigh
                        : null,
                borderRadius: BorderRadius.circular(16)),
            child: widget.showTitle
                ? Row(
                    children: [
                      icon,
                      const SizedBox(
                        width: 12,
                      ),
                      Text(widget.entry.label)
                    ],
                  )
                : Center(
                    child: icon,
                  )),
      ),
    );
  }
}

class _PaneActionWidget extends StatefulWidget {
  const _PaneActionWidget(
      {required this.entry, required this.showTitle, super.key});

  final PaneActionEntry entry;

  final bool showTitle;

  @override
  State<_PaneActionWidget> createState() => _PaneActionWidgetState();
}

class _PaneActionWidgetState extends State<_PaneActionWidget> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = Icon(widget.entry.icon);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (details) => setState(() => isHovering = true),
      onExit: (details) => setState(() => isHovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.entry.onTap,
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            width: double.infinity,
            height: widget.showTitle ? 42 : 34,
            decoration: BoxDecoration(
                color: isHovering ? colorScheme.surfaceContainerHigh : null,
                borderRadius: BorderRadius.circular(16)),
            child: widget.showTitle
                ? Row(
                    children: [
                      icon,
                      const SizedBox(
                        width: 12,
                      ),
                      Text(widget.entry.label)
                    ],
                  )
                : Center(
                    child: icon,
                  )),
      ),
    );
  }
}

class _SingleBottomNaviWidget extends StatefulWidget {
  const _SingleBottomNaviWidget(
      {required this.enabled,
      required this.entry,
      required this.onTap,
      super.key});

  final bool enabled;

  final PaneItemEntry entry;

  final VoidCallback onTap;

  @override
  State<_SingleBottomNaviWidget> createState() =>
      _SingleBottomNaviWidgetState();
}

class _SingleBottomNaviWidgetState extends State<_SingleBottomNaviWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  bool isHovering = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _SingleBottomNaviWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      if (widget.enabled) {
        controller.forward(from: 0);
      } else {
        controller.reverse(from: 1);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      value: widget.enabled ? 1 : 0,
      vsync: this,
      duration: _fastAnimationDuration,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CurvedAnimation(parent: controller, curve: Curves.ease),
      builder: (context, child) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (details) => setState(() => isHovering = true),
          onExit: (details) => setState(() => isHovering = false),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onTap,
            child: buildContent(),
          ),
        );
      },
    );
  }

  Widget buildContent() {
    final value = controller.value;
    final colorScheme = Theme.of(context).colorScheme;
    final icon =
        Icon(widget.enabled ? widget.entry.activeIcon : widget.entry.icon);
    return Center(
      child: Container(
        width: 64,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(32)),
          color: isHovering ? colorScheme.surfaceContainer : Colors.transparent,
        ),
        child: Center(
          child: Container(
            width: 32 + value * 32,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(32)),
              color: value != 0
                  ? colorScheme.secondaryContainer
                  : Colors.transparent,
            ),
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }
}

class NaviObserver extends NavigatorObserver implements Listenable {
  var routes = Queue<Route>();

  int get pageCount => routes.length;

  @override
  void didPop(Route route, Route? previousRoute) {
    routes.removeLast();
    notifyListeners();
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    routes.addLast(route);
    notifyListeners();
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    routes.remove(route);
    notifyListeners();
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    routes.remove(oldRoute);
    if (newRoute != null) {
      routes.add(newRoute);
    }
    notifyListeners();
  }

  List<VoidCallback> listeners = [];

  @override
  void addListener(VoidCallback listener) {
    listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    listeners.remove(listener);
  }

  void notifyListeners() {
    for (var listener in listeners) {
      listener();
    }
  }
}

class _NaviPopScope extends StatelessWidget {
  const _NaviPopScope(
      {required this.child, required this.action, required this.popGesture});

  final Widget child;

  final void Function() action;

  final bool popGesture;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (didPop) return;
        action();
      },
      child: child,
    );
  }
}

class NaviPaddingWidgetController extends StateController {
  NaviPaddingWidgetController() {
    print("init");
  }

  bool _withPadding = false;

  void setWithPadding(bool value) {
    _withPadding = value;
    update();
  }
}

class NaviPaddingWidget extends StatelessWidget {
  const NaviPaddingWidget({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StateBuilder<NaviPaddingWidgetController>(
      builder: (controller) {
        return Padding(
          padding: controller._withPadding ? EdgeInsets.only(
            top: _NaviPaneState._kTopBarHeight + context.padding.top,
            bottom: _NaviPaneState._kBottomBarHeight + context.padding.bottom,
          ) : EdgeInsets.zero,
          child: child,
        );
      },
    );
  }
}
