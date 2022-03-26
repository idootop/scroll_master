import 'package:flutter/material.dart';
import 'package:scroll_master/util.dart';

import '../config.dart';
import '../widgets/tab_bar_view_x/extended_tabs.dart';

class VerticalScrollTabListPage extends StatefulWidget {
  const VerticalScrollTabListPage({Key? key}) : super(key: key);

  @override
  _VerticalScrollTabListPageState createState() =>
      _VerticalScrollTabListPageState();
}

class _VerticalScrollTabListPageState extends State<VerticalScrollTabListPage>
    with SingleTickerProviderStateMixin {
  final _tabs = List.generate(4, (idx) => 'Tab${idx + 1}');
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(projectName),
        centerTitle: true,
        elevation: 0,
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            color: Colors.blue,
            child: ExtendedTabBar(
              controller: _tabController,
              scrollDirection: Axis.vertical,
              tabs: _tabs
                  .map((e) => ExtendedTab(
                        text: e,
                        scrollDirection: Axis.vertical,
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: ExtendedTabBarView(
              controller: _tabController,
              scrollDirection: Axis.vertical,
              children: _tabs
                  .map(
                    (e) => VerticalScrollTabView(e),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class VerticalScrollTabView extends StatefulWidget {
  final String text;
  const VerticalScrollTabView(this.text, {Key? key}) : super(key: key);

  @override
  _VerticalScrollTabViewState createState() => _VerticalScrollTabViewState();
}

class _VerticalScrollTabViewState extends State<VerticalScrollTabView> {
  late final ScrollController controller;

  @override
  void initState() {
    super.initState();
    controller = ScrollController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TabScrollView(
      controller: controller,
      scrollDirection: Axis.vertical,
      child: _listview(),
    );
  }

  Widget _listview() {
    final screen = MediaQuery.of(context).size;
    final tabIdx = int.parse(widget.text.replaceAll('Tab', '')) - 1;
    return ListView.builder(
      itemCount: 3,
      controller: controller,
      // 必须为NeverScrollableScrollPhysics，由外部TabScrollView更新positon
      physics: NeverScrollableScrollPhysics(),
      scrollDirection: Axis.vertical,
      key: PageStorageKey<String>('V' + widget.text),
      itemBuilder: (_, idx) {
        return Container(
          width: screen.width,
          height: screen.height - 180 - screen.width / 10,
          padding: EdgeInsets.all(screen.width / 10),
          child: GestureDetector(
            onTap: () => showToast(),
            child: Container(
              color: Colors.blue,
              child: Column(
                children: [
                  Expanded(
                    child: Image.asset(
                      ius[tabIdx],
                      width: screen.width,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(screen.width / 10),
                    child: Text(
                      widget.text + ' - ${idx + 1}',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
