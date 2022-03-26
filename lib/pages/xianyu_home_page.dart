import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:scroll_master/util.dart';
import 'package:scroll_master/widgets/alive_keeper.dart';
import 'package:scroll_master/widgets/custom_nested_scroll_view/custom_nested_scroll_view.dart';
import 'package:scroll_master/widgets/l_sliver_app_bar.dart';

import '../widgets/tab_bar_view_x/extended_tabs.dart';

import 'package:get/get.dart';

enum RefreshStatus {
  // 刷新中
  refreshing,
  // 释放刷新
  release2refresh,
  // 下拉刷新
  pull2refresh,
  // 静止
  idle
}

class RefreshContoller extends GetxController {
  static RefreshContoller get to => Get.find();

  RefreshContoller({this.refreshCallback});

  // 刷新回调
  Function? refreshCallback;
  // 头部高度
  double headerHeight = 200.0;
  // 内部tab栏高度
  double innerTabBarHeight = 48.0;
  // 外部tab栏高度
  double outerTabBarHeight = 48.0;
  // 刷新指示器高度
  final double _refreshIndicatorHeight = 48.0;
  // 下拉刷新触发高度
  double pullTrigerHeight = 0.0;
  // 释放刷新触发高度
  double releaseTrigerHeight = 48.0;

  // 过度滑动距离
  double _overscroll = 0.0;
  // 刷新状态
  RefreshStatus _status = RefreshStatus.idle;

  double get overscroll => _overscroll;
  RefreshStatus get status => _status;

  double get refreshIndicatorHeight => (status == RefreshStatus.refreshing
      ? _refreshIndicatorHeight
      : status != RefreshStatus.idle
          ? (_overscroll / _refreshIndicatorHeight).clamp(0, 1) *
              _refreshIndicatorHeight
          : 0);

  set overscroll(double v) {
    if (v != _overscroll) {
      _overscroll = v;
      update();
    }
  }

  set status(RefreshStatus v) {
    if (v != _status) {
      _status = v;
      update();
    }
  }

  Future<void> handlePointerEvent(PointerEvent event) async {
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      if (_status == RefreshStatus.release2refresh) {
        // 在释放刷新阶段放手，则刷新
        status = RefreshStatus.refreshing;
        await refreshCallback?.call();
        status = RefreshStatus.idle;
      }
    }
  }

  Future<void> refreshTriger(offset) async {
    overscroll = offset * 1.0;
    if (_status == RefreshStatus.idle && overscroll > pullTrigerHeight) {
      status = RefreshStatus.pull2refresh;
      update();
    } else if (_status == RefreshStatus.pull2refresh) {
      if (overscroll > releaseTrigerHeight) {
        status = RefreshStatus.release2refresh;
      } else if (overscroll < pullTrigerHeight) {
        status = RefreshStatus.idle;
      }
    } else if (_status == RefreshStatus.release2refresh) {
      if (overscroll <= releaseTrigerHeight) {
        if (status != RefreshStatus.refreshing) {
          // 没有在释放刷新阶段放手，取消刷新
          status = RefreshStatus.pull2refresh;
        }
      }
    }
  }
}

class XianyuHomePage extends HookWidget {
  Widget refreshIndicator() {
    return GetBuilder<RefreshContoller>(
      builder: (state) => AnimatedContainer(
        duration: Duration(milliseconds: 200),
        height: state.refreshIndicatorHeight,
        child: Center(
          child: Text(
            state.status == RefreshStatus.pull2refresh
                ? '下拉刷新'
                : state.status == RefreshStatus.release2refresh
                    ? '释放刷新'
                    : state.status == RefreshStatus.idle
                        ? ''
                        : '刷新中',
            style: TextStyle(color: Colors.black, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget header() {
    return GetBuilder<RefreshContoller>(
      builder: (state) => LSliverAppBar(
        pinned: true,
        stretch: true,
        minHeight: state.innerTabBarHeight,
        maxHeight: state.innerTabBarHeight + state.headerHeight,
        backgroundColor: Colors.transparent,
        backgroundBuilder: (
          BuildContext context,
          double minHeight,
          double maxHeight,
          double currentHeight,
        ) {
          return SizedBox(
            height: currentHeight,
            child: Column(
              children: [
                Expanded(child: Container()),
                Container(
                  height: state.headerHeight,
                  color: Colors.white,
                  child: Center(
                    child: Text('发现'),
                  ),
                ),
                SizedBox(height: state.innerTabBarHeight)
              ],
            ),
          );
        },
        bottom: PreferredSize(
          preferredSize: Size(Get.width, innerTabBar.preferredSize.height),
          child: Container(color: Colors.lightBlueAccent, child: innerTabBar),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = useScrollController();
    final controller2 = useScrollController();
    useEffect(() {
      if (!Get.isRegistered<RefreshContoller>()) {
        Get.put(RefreshContoller());
      }
      final refreshContoller = RefreshContoller.to
        ..refreshCallback = refresh
        ..innerTabBarHeight = innerTabBar.preferredSize.height
        ..outerTabBarHeight = outerTabBar.preferredSize.height;
      controller.addListener(() {
        // 关键，监听 NestedScrollViewX 过度滑动距离
        final overflow = (0 - controller.offset).clamp(0, double.infinity);
        refreshContoller.refreshTriger(overflow);
      });
      controller2.addListener(() {
        // 关键，监听 NestedScrollViewX 过度滑动距离
        final overflow = (0 - controller2.offset).clamp(0, double.infinity);
        refreshContoller.refreshTriger(overflow);
      });
      // 全局手势监听
      GestureBinding.instance!.pointerRouter
          .addGlobalRoute(refreshContoller.handlePointerEvent);
      return () {
        GestureBinding.instance!.pointerRouter
            .removeGlobalRoute(refreshContoller.handlePointerEvent);
      };
    });

    return SafeArea(
      top: true,
      child: DefaultTabController(
        length: 2,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 用一个隐藏的 refreshIndicator 撑开高度
                  Opacity(opacity: 0, child: refreshIndicator()),
                  SizedBox(height: outerTabBar.preferredSize.height),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: ExtendedTabBarView(children: [
                      AliveKeeper(child: nestedScrollViewTab(controller)),
                      AliveKeeper(child: blankTab(controller2)),
                    ]),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 同步过度滑动距离
                GetBuilder<RefreshContoller>(
                  builder: (state) => SizedBox(
                    height: state._overscroll.clamp(0, double.infinity),
                  ),
                ),
                refreshIndicator(),
                outerTabBar,
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> refresh() async {
    await Future.delayed(Duration(seconds: 2));
  }

  TabBar get outerTabBar => TabBar(
        labelColor: Colors.black,
        indicatorWeight: 4,
        tabs: <Widget>[tabBar('发现'), tabBar('关注')],
      );

  TabBar get innerTabBar => TabBar(
        labelColor: Colors.black,
        indicatorWeight: 4,
        tabs: <Widget>[tabBar('热门'), tabBar('同城')],
      );

  Widget tabBar(text) =>
      Container(height: 48 - 2, alignment: Alignment.center, child: Text(text));

  Widget blankTab(controller2) => Builder(
        builder: (context) => SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: ListView(
            controller: controller2,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Center(
                  child: Text('关注'),
                ),
              )
            ],
          ),
        ),
      );

  Widget nestedScrollViewTab(controller) => DefaultTabController(
        length: 2,
        child: CustomNestedScrollView(
          controller: controller,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          headerSliverBuilder: (context, __) => <Widget>[
            CustomSliverOverlapAbsorber(
              overscrollType: CustomOverscroll.outer,
              handle: CustomNestedScrollView.sliverOverlapAbsorberHandleFor(
                  context),
              sliver: header(),
            ),
          ],
          body: ExtendedTabBarView(children: [
            AliveKeeper(child: _tabView()),
            AliveKeeper(child: _tabView(true)),
          ]),
        ),
      );
}

Widget _tabView([bool reverse = false]) => Builder(builder: (context) {
      return CustomScrollView(
        key: PageStorageKey<String>('$reverse'),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: <Widget>[
          Builder(
            builder: (context) => CustomSliverOverlapInjector(
              overscrollType: CustomOverscroll.outer,
              handle: CustomNestedScrollView.sliverOverlapAbsorberHandleFor(
                  context),
            ),
          ),
          ...List.generate(
            20,
            (idx) => _tile(
              reverse ? 20 - idx : idx + 1,
              const [
                Colors.yellow,
                Colors.black,
                Colors.blue,
                Colors.purple,
              ][idx % 4],
            ),
          ),
        ],
      );
    });

Widget _tile(int idx, Color color) => SliverToBoxAdapter(
      key: Key('$idx'),
      child: GestureDetector(
        onTap: () => showToast(),
        child: Container(
          height: 64,
          color: color,
          child: Center(
            child: Text(
              '$idx',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
        ),
      ),
    );
