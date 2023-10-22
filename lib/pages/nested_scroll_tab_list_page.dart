import 'package:nested_scroll_view_plus/nested_scroll_view_plus.dart';
import 'package:flutter/material.dart';
import '../config.dart';

import '../widgets/extended_tab_bar_view/extended_tabs.dart';

class NestedScrollTabListPage extends StatelessWidget {
  const NestedScrollTabListPage({Key? key}) : super(key: key);

  ///Header collapsed height
  final minHeight = 120.0;

  ///Header expanded height
  final maxHeight = 400.0;

  @override
  Widget build(BuildContext context) {
    final tabBar = TabBar(
      tabs: <Widget>[Text('Tab1'), Text('Tab2')],
    );
    final topHeight = MediaQuery.of(context).padding.top;
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          body: NestedScrollViewPlus(
            headerSliverBuilder: (context, innerScrolled) => <Widget>[
              OverlapAbsorberPlus(
                sliver: SliverAppBar(
                  pinned: true,
                  stretch: true,
                  toolbarHeight:
                      minHeight - tabBar.preferredSize.height - topHeight,
                  collapsedHeight:
                      minHeight - tabBar.preferredSize.height - topHeight,
                  expandedHeight:
                      maxHeight - tabBar.preferredSize.height - topHeight,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    title: Container(
                      alignment: Alignment.center,
                      child: Text(projectName),
                    ),
                    stretchModes: <StretchMode>[
                      StretchMode.zoomBackground,
                      StretchMode.blurBackground,
                    ],
                    background: Image.asset(
                      ius[1],
                      fit: BoxFit.cover,
                    ),
                  ),
                  bottom: tabBar,
                ),
              ),
            ],
            body: ExtendedTabBarView(children: [
              _tabView(),
              _tabView(true),
            ]),
          ),
        ));
  }

  Widget _tabView([bool reverse = false]) => CustomScrollView(
        key: PageStorageKey<String>('$reverse'),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          OverlapInjectorPlus(),
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

  Widget _tile(int idx, Color color) => SliverToBoxAdapter(
        key: Key('$idx'),
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
      );
}
