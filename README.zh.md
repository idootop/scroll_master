# scroll_master

一个展示如何处理Flutter中的常见滑动手势冲突的示例。

## 🌍 在线预览

打开网页查看效果 👉  [网页链接](https://killer-1255480117.cos.ap-chongqing.myqcloud.com/web/scrollMaster/index.html)

## 🐛 已知问题

### 场景 1: 带有pinned且stretch的SliverAppBar的NestedScrollView

**问题: NestedScrollView不支持外部列表过度滑动, 所以SliverAppBar的stretch效果无法被触发**

*相关issue: [https://github.com/flutter/flutter/issues/54059](https://github.com/flutter/flutter/issues/54059)*

![](screenshots/case1.gif)

### 场景 2: 带有水平滑动ListView的TabBarView

**问题: 当ListView过度滑动（滑到底部或顶部）时没有带动外部的TabBarView滑动**

![](screenshots/case2.gif)

## ⚡️ 解决方案

### 对于场景 1: 

重写_NestedScrollCoordinator的applyUserOffset方法，允许_outerPosition的顶部过度滑动。

重写_NestedScrollCoordinator的unnestOffset、nestOffset、_getMetrics方法，
修正_innerPosition与_outerPosition到_NestedScrollPosition（Coordinator）之间的映射关系。

*详见:*

* `lib/pages/nested_scroll_tab_list_page.dart`
* `lib/widgets/nested_scroll_view_x/src/nested_scroll_view_x.dart`

### 对于场景 2: 

参考ExtendedTabBarView，新增TabScrollView，绑定ScrollController，

当内部列表过度滑动时，将过度滑动量作用到外部可滚动ExtendedTabBarView上。

*详见:*

* `lib/pages/horizontal_scroll_tab_list_page.dart`
* `lib/widgets/tab_bar_view_x/src/tab_scroll_view.dart`

## ❤️ 鸣谢

非常感谢[fluttercandies](https://github.com/fluttercandies)的[extended_tabs](https://github.com/fluttercandies/extended_tabs)和[extended_nested_scroll_view](https://github.com/fluttercandies/extended_nested_scroll_view)

## 📖 参考资料

* [大道至简：Flutter嵌套滑动冲突解决之路](http://vimerzhao.top/posts/flutter-nested-scroll-conflict/)
* [深入进阶-如何解决Flutter上的滑动冲突？ ](https://juejin.cn/post/6900751363173515278)
* [用Flutter实现58App的首页](https://blog.csdn.net/weixin_39891694/article/details/111217123)
* [不一样角度带你了解 Flutter 中的滑动列表实现](https://blog.csdn.net/ZuoYueLiang/article/details/116245138)
* [Flutter 滑动体系 ](https://juejin.cn/post/6983338779415150628)