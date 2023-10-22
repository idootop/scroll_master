import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:scroll_master/widgets/alive_keeper.dart';
import 'package:nested_scroll_view_plus/nested_scroll_view_plus.dart';
import 'package:scroll_master/widgets/l_sliver_app_bar.dart';

import '../widgets/extended_tab_bar_view/extended_tabs.dart';

import 'package:get/get.dart';

class HomePage extends HookWidget {
  const HomePage({super.key});

  Widget refreshIndicator() {
    return GetBuilder<RefreshContoller>(
      builder: (state) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: state.refreshIndicatorHeight,
        child: Center(
          child: Text(
            state.status == RefreshStatus.pull2refresh
                ? 'Pull to refresh'
                : state.status == RefreshStatus.release2refresh
                    ? 'Release to refresh'
                    : state.status == RefreshStatus.idle
                        ? ''
                        : 'Refreshing...',
            style: const TextStyle(color: Colors.black, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget tabBar(text) =>
      Container(height: 48 - 2, alignment: Alignment.center, child: Text(text));

  TabBar get outerTabBar => TabBar(
        indicatorColor: Colors.white,
        tabs: <Widget>[tabBar('For you'), tabBar('Following')],
      );

  TabBar get innerTabBar => TabBar(
        labelColor: Colors.white,
        indicatorColor: Colors.white,
        tabs: <Widget>[tabBar('Flutter'), tabBar('React')],
      );

  Widget header() {
    final state = RefreshContoller.to;
    return LSliverAppBar(
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
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                height: state.headerHeight,
                color: Colors.white,
                child: const Center(
                  child: Text(
                    'Scroll Master',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: state.innerTabBarHeight)
            ],
          ),
        );
      },
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(innerTabBar.preferredSize.height),
        child: Container(color: Colors.blue, child: innerTabBar),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tab1controller = useScrollController();
    final tab2controller = useScrollController();
    useEffect(() {
      Get.put(RefreshContoller());
      final refreshContoller = RefreshContoller.to
        ..refreshCallback = refresh
        ..innerTabBarHeight = innerTabBar.preferredSize.height
        ..outerTabBarHeight = outerTabBar.preferredSize.height;
      tab1controller.addListener(() {
        final overflow = (0 - tab1controller.offset).clamp(0, double.infinity);
        refreshContoller.refreshTriger(overflow);
      });
      tab2controller.addListener(() {
        final overflow = (0 - tab2controller.offset).clamp(0, double.infinity);
        refreshContoller.refreshTriger(overflow);
      });
      GestureBinding.instance.pointerRouter
          .addGlobalRoute(refreshContoller.handlePointerEvent);
      return () {
        GestureBinding.instance.pointerRouter
            .removeGlobalRoute(refreshContoller.handlePointerEvent);
      };
    }, []);

    return SafeArea(
      top: true,
      child: DefaultTabController(
        length: 2,
        child: Stack(
          children: [
            Column(
              children: [
                Opacity(opacity: 0, child: refreshIndicator()),
                SizedBox(height: outerTabBar.preferredSize.height),
                Expanded(
                  child: ExtendedTabBarView(children: [
                    AliveKeeper(child: tabPage1(tab1controller)),
                    AliveKeeper(child: tabPage2(tab2controller)),
                  ]),
                ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GetBuilder<RefreshContoller>(
                  builder: (state) => SizedBox(
                    height: state._overscroll.clamp(0, double.infinity),
                  ),
                ),
                refreshIndicator(),
                Material(
                  color: Colors.black,
                  child: outerTabBar,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> refresh() async {
    await Future.delayed(const Duration(seconds: 2));
  }

  Widget tabPage1(controller) => DefaultTabController(
        length: 2,
        child: NestedScrollViewPlus(
          controller: controller,
          headerSliverBuilder: (context, __) => <Widget>[
            OverlapAbsorberPlus(
              sliver: header(),
            ),
          ],
          body: ExtendedTabBarView(children: [
            _tabView(),
            _tabView(true),
          ]),
        ),
      );

  Widget tabPage2(tab2controller) => Builder(
        builder: (context) => SizedBox(
          width: MediaQuery.of(context).size.width,
          child: ListView(
            controller: tab2controller,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height - 100,
                child: const Center(
                  child: Text('No following yet'),
                ),
              )
            ],
          ),
        ),
      );
}

Widget _tabView([bool reverse = false]) => CustomScrollView(
      key: PageStorageKey<String>('$reverse'),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: <Widget>[
        const OverlapInjectorPlus(),
        SliverFixedExtentList(
          delegate: SliverChildBuilderDelegate(
            (_, index) => Container(
              key: Key('$reverse-$index'),
              color: index.isEven ? Colors.white : Colors.grey[100],
              child: Center(
                child: Text('ListTile ${reverse ? 30 - index : index + 1}'),
              ),
            ),
            childCount: 30,
          ),
          itemExtent: 60,
        ),
      ],
    );

enum RefreshStatus { refreshing, release2refresh, pull2refresh, idle }

class RefreshContoller extends GetxController {
  static RefreshContoller get to => Get.find();

  RefreshContoller({this.refreshCallback});

  Function? refreshCallback;
  double headerHeight = 200.0;
  double innerTabBarHeight = 48.0;
  double outerTabBarHeight = 48.0;
  final double _refreshIndicatorHeight = 48.0;
  double pullTrigerHeight = 0.0;
  double releaseTrigerHeight = 48.0;

  double _overscroll = 0.0;
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
          status = RefreshStatus.pull2refresh;
        }
      }
    }
  }
}
