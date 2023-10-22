import 'package:flutter/material.dart';

import '../config.dart';
import '../widgets/extended_tab_bar_view/extended_tabs.dart';

class HorizontalScrollTabListPage extends StatefulWidget {
  const HorizontalScrollTabListPage({Key? key}) : super(key: key);

  @override
  _HorizontalScrollTabListPageState createState() =>
      _HorizontalScrollTabListPageState();
}

class _HorizontalScrollTabListPageState
    extends State<HorizontalScrollTabListPage>
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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            color: Colors.blue,
            child: TabBar(
              controller: _tabController,
              tabs: _tabs.map((e) => Tab(text: e)).toList(),
            ),
          ),
          Expanded(
            child: ExtendedTabBarView(
              controller: _tabController,
              children: _tabs
                  .map(
                    (e) => HorizontalScrollTabView(e),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class HorizontalScrollTabView extends StatefulWidget {
  final String text;
  const HorizontalScrollTabView(this.text, {Key? key}) : super(key: key);

  @override
  _HorizontalScrollTabViewState createState() =>
      _HorizontalScrollTabViewState();
}

class _HorizontalScrollTabViewState extends State<HorizontalScrollTabView> {
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
      scrollDirection: Axis.horizontal,
      child: _listview(),
    );
  }

  Widget _listview() {
    final screen = MediaQuery.of(context).size;
    final tabIdx = int.parse(widget.text.replaceAll('Tab', '')) - 1;
    return ListView.builder(
      physics: NeverScrollableScrollPhysics(),
      itemCount: 3,
      controller: controller,
      scrollDirection: Axis.horizontal,
      key: PageStorageKey<String>('H' + widget.text),
      itemBuilder: (_, idx) {
        return Container(
          width: screen.width,
          padding: EdgeInsets.all(screen.width / 10),
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
        );
      },
    );
  }
}
