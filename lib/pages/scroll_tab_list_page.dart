import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../widgets/extended_tab_bar_view/extended_tabs.dart';

class ScrollTabListPage extends HookWidget {
  final Axis scrollDirection;
  const ScrollTabListPage({super.key, this.scrollDirection = Axis.horizontal});

  @override
  Widget build(BuildContext context) {
    final tabs = List.generate(3, (idx) => 'Tab${idx + 1}');
    final tabController = useTabController(initialLength: tabs.length);
    final tabBar = scrollDirection == Axis.horizontal
        ? TabBar(
            controller: tabController,
            tabs: tabs.map((e) => Tab(text: e)).toList(),
          )
        : ExtendedTabBar(
            controller: tabController,
            scrollDirection: Axis.vertical,
            tabs: tabs
                .map((e) => ExtendedTab(
                      text: e,
                      scrollDirection: Axis.vertical,
                    ))
                .toList(),
          );
    final body = [
      Material(
        color: Colors.blue,
        child: tabBar,
      ),
      Expanded(
        child: ExtendedTabBarView(
          controller: tabController,
          scrollDirection: scrollDirection,
          children: tabs
              .map(
                (e) => ScrollTabView(e, scrollDirection: scrollDirection),
              )
              .toList(),
        ),
      ),
    ];
    return scrollDirection == Axis.horizontal
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: body,
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: body,
          );
  }
}

class ScrollTabView extends HookWidget {
  final String text;
  final Axis scrollDirection;
  const ScrollTabView(
    this.text, {
    super.key,
    required this.scrollDirection,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useScrollController();
    final tabIdx = int.parse(text.replaceAll('Tab', '')) - 1;
    final screen = MediaQuery.of(context).size;
    final sizeUint = min(screen.width, screen.height) / 10;
    return TabScrollView(
      controller: controller,
      scrollDirection: scrollDirection,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        controller: controller,
        scrollDirection: scrollDirection,
        key: PageStorageKey<String>('$scrollDirection-$text'),
        itemBuilder: (_, idx) {
          return Container(
            width: scrollDirection == Axis.horizontal
                ? screen.width
                : screen.height - 180 - sizeUint,
            height: scrollDirection == Axis.horizontal
                ? null
                : screen.height - 60 - sizeUint,
            padding: EdgeInsets.all(sizeUint),
            child: Container(
              color: Colors.blue,
              child: Column(
                children: [
                  Expanded(
                    child: Image.asset(
                      [
                        'assets/1.jpg',
                        'assets/2.jpg',
                        'assets/3.jpg',
                      ][tabIdx],
                      width: screen.width,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(sizeUint / 2),
                    child: Text(
                      '$text - ${idx + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
