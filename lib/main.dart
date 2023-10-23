import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:scroll_master/pages/home_page.dart';
import 'package:scroll_master/pages/scroll_tab_list_page.dart';
import 'pages/nested_scroll_tab_list_page.dart';

import 'widgets/alive_keeper.dart';
import 'widgets/extended_tab_bar_view/src/tab_view.dart';

void main() => runApp(const MyAPP());

class MyAPP extends StatelessWidget {
  const MyAPP({super.key});

  @override
  Widget build(context) {
    return SafeArea(
      top: true,
      child: AnnotatedRegion(
        value: SystemUiOverlayStyle.light,
        child: MaterialApp(
          theme: ThemeData.light(useMaterial3: true).copyWith(
            primaryColor: Colors.black,
            appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
            tabBarTheme: const TabBarTheme(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              selectedItemColor: Colors.black,
            ),
          ),
          home: const ScrollMaster(),
        ),
      ),
    );
  }
}

class ScrollMaster extends HookWidget {
  const ScrollMaster({super.key});

  @override
  Widget build(BuildContext context) {
    final tabController = useTabController(initialLength: 4);
    final currentPage = useState(0);
    final onPageChanged = useCallback((int idx) {
      if (idx != currentPage.value) {
        currentPage.value = idx;
        tabController.animateTo(idx);
      }
    });
    useEffect(() {
      tabController.addListener(() {
        if (!tabController.indexIsChanging &&
            tabController.index != currentPage.value) {
          onPageChanged(tabController.index);
        }
      });
    }, []);
    return Scaffold(
      body: ExtendedTabBarView(
        controller: tabController,
        children: [
          const HomePage(),
          const ScrollTabListPage(scrollDirection: Axis.horizontal),
          const ScrollTabListPage(scrollDirection: Axis.vertical),
          const NestedScrollTabListPage(),
        ].map<Widget>((e) => AliveKeeper(child: e)).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentPage.value,
        onTap: onPageChanged,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            label: 'Home',
            icon: Icon(Icons.home),
          ),
          BottomNavigationBarItem(
            label: 'Horizontal',
            icon: Transform.rotate(
              angle: 3.14 / 2,
              child: const Icon(Icons.unfold_more),
            ),
          ),
          const BottomNavigationBarItem(
            label: 'Vertical',
            icon: Icon(Icons.unfold_more),
          ),
          const BottomNavigationBarItem(
            label: 'Nested',
            icon: Icon(Icons.unfold_less),
          ),
        ],
      ),
    );
  }
}
