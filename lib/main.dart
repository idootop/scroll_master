import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:scroll_master/pages/xianyu_home_page.dart';
import 'pages/horizontal_scroll_tab_list_page.dart';
import 'pages/nested_scroll_tab_list_page.dart';
import 'pages/vertical_scroll_tab_list_page.dart';

import 'widgets/alive_keeper.dart';
import 'widgets/tab_bar_view_x/src/tab_view.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OKToast(
      movingOnWindowChange: false,
      child: MaterialApp(
        title: 'ScrollMaster',
        home: Home(),
      ),
    );
  }
}

class Home extends StatefulWidget {
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      initialIndex: _currentPage,
      length: 4,
      vsync: this,
    )..addListener(() {
        if (!_tabController.indexIsChanging &&
            _tabController.index != _currentPage) {
          _onPageChanged(_tabController.index);
        }
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onPageChanged(int idx) {
    if (idx != _currentPage) {
      setState(() {
        _currentPage = idx;
        _tabController.animateTo(_currentPage);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ExtendedTabBarView(
        physics: ClampingScrollPhysics(),
        controller: _tabController,
        children: [
          XianyuHomePage(),
          HorizontalScrollTabListPage(),
          VerticalScrollTabListPage(),
          NestedScrollTabListPage(),
        ].map<Widget>((e) => AliveKeeper(child: e)).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentPage,
        onTap: _onPageChanged,
        items: [
          BottomNavigationBarItem(
            label: 'Home',
            icon: Icon(Icons.home),
          ),
          BottomNavigationBarItem(
            label: 'Horizontal',
            icon: Transform.rotate(
              angle: 3.14 / 2,
              child: Icon(Icons.unfold_more),
            ),
          ),
          BottomNavigationBarItem(
            label: 'Vertical',
            icon: Icon(Icons.unfold_more),
          ),
          BottomNavigationBarItem(
            label: 'Nested',
            icon: Icon(Icons.unfold_less),
          ),
        ],
      ),
    );
  }
}
