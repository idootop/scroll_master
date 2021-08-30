# scroll_master

An example showing how to handle common scrolling gesture conflicts in Flutter.

[中文文档请戳这里](README.zh.md)

## 🌍 Preview

Web demo 👉   [Click Here](https://killer-1255480117.cos.ap-chongqing.myqcloud.com/web/scrollMaster/index.html)

## 🐛 Problems

### Case 1: NestedScrollView with pinned and stretch SliverAppBar

**Problem: NestedScrollView does not support over-scrolling of external ListView, so its SliverAppBar cannot be stretched.**

*Related issue: [https://github.com/flutter/flutter/issues/54059](https://github.com/flutter/flutter/issues/54059)*

![](screenshots/case1.gif)

### Case 2: TabBarView with horizontal ListView

**Problem: TabBarView does't scroll when the internal ListView is over-scrolled.**

![](screenshots/case2.gif)

## ⚡️ Solutions

### For case 1: NestedScrollView with pinned and stretch SliverAppBar

Override the applyUserOffset method of _NestedScrollCoordinator to allow over-scroll the top of _outerPosition.

Override the unnestOffset, nestOffset, _getMetrics methods of _NestedScrollCoordinator to fix the mapping between _innerPosition and _outerPosition to _NestedScrollPosition (Coordinator).

*For more information, see:*

* `lib/pages/nested_scroll_tab_list_page.dart`
* `lib/widgets/nested_scroll_view_x/src/nested_scroll_view_x.dart`

### For case 2: TabBarView with horizontal ListView

Reference ExtendedTabBarView to implement a TabScrollView with a ScrollController bound to it.

When the internal ListView over-scrolls, the over-scroll amount is applied to the external scrollable ExtendedTabBarView.

*For more information, see:*

* `lib/pages/horizontal_scroll_tab_list_page.dart`
* `lib/widgets/tab_bar_view_x/src/tab_scroll_view.dart`

## ❤️ Acknowledgements

Thanks to [fluttercandies](https://github.com/fluttercandies)'s [extended_tabs](https://github.com/fluttercandies/extended_tabs) and [extended_nested_scroll_view](https://github.com/fluttercandies/extended_nested_scroll_view).

## 📖 References

* [大道至简：Flutter嵌套滑动冲突解决之路](http://vimerzhao.top/posts/flutter-nested-scroll-conflict/)
* [深入进阶-如何解决Flutter上的滑动冲突？ ](https://juejin.cn/post/6900751363173515278)
* [用Flutter实现58App的首页](https://blog.csdn.net/weixin_39891694/article/details/111217123)
* [不一样角度带你了解 Flutter 中的滑动列表实现](https://blog.csdn.net/ZuoYueLiang/article/details/116245138)
* [Flutter 滑动体系 ](https://juejin.cn/post/6983338779415150628)