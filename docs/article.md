# Flutter中的常见滑动手势冲突解决方案

## 📖 背景简介

手势冲突，一个让人头疼的问题，尤其是在Flutter上。

最近我也遇到了两个嵌套列表滑动手势冲突的场景，搞得我有些怀疑人生～

下面让我们一起来看下吧 😊

## 🐛 已知问题

### 场景 1: 带有pinned且stretch的SliverAppBar的NestedScrollView

**问题: NestedScrollView不支持外部列表过度滑动, 所以SliverAppBar的stretch效果无法被触发**

*相关issue: [https://github.com/flutter/flutter/issues/54059](https://github.com/flutter/flutter/issues/54059)*

![](https://i.loli.net/2021/08/31/JtOo7KP3jNip8S1.gif)

### 场景 2: 带有水平滑动ListView的TabBarView

**问题: 当ListView过度滑动（滑到底部或顶部）时没有带动外部的TabBarView滑动**

![](https://i.loli.net/2021/08/31/7xMyZpWHOhPbiut.gif)

## 💡 解决思路

### 对于场景 1: 

首先，我们需要搞清楚NestedScrollView的内部运作原理，先从它的源码入手吧。

*Tips:不要被NestedScrollView的2000多行源码吓坏，其实关键的地方就几处*

#### NestedScrollView源码

##### NestedScrollView

```dart
class NestedScrollViewState extends State<NestedScrollView> {

  ScrollController get innerController => _coordinator!._innerController;

  ScrollController get outerController => _coordinator!._outerController;

  _NestedScrollCoordinator? _coordinator;

  @override
  void initState() {
    super.initState();
    _coordinator = _NestedScrollCoordinator(
      this,
      widget.controller,
      _handleHasScrolledBodyChanged,
      widget.floatHeaderSlivers,
    );
  }

  ...

}
```

可以看到NestedScrollView在initState的时候初始化了一个_NestedScrollCoordinator，

然后我们可以从这个_NestedScrollCoordinator拿到innerController和outerController，分别对应内外部列表的滑动控制器。

OK，我们接着进_NestedScrollCoordinator看下他是什么东西。

##### _NestedScrollCoordinator

```dart
class _NestedScrollCoordinator implements ScrollActivityDelegate, ScrollHoldController {
  _NestedScrollCoordinator(
    this._state,
    this._parent,
    this._floatHeaderSlivers,
  ) {
    final double initialScrollOffset = _parent?.initialScrollOffset ?? 0.0;
    _outerController = _NestedScrollController(
      this,
      initialScrollOffset: initialScrollOffset,
      debugLabel: 'outer',
    );
    _innerController = _NestedScrollController(
      this,
      initialScrollOffset: 0.0,
      debugLabel: 'inner',
    );
  }

  late _NestedScrollController _outerController;
  late _NestedScrollController _innerController;

  _NestedScrollPosition? get _outerPosition {
    ...
  }

  Iterable<_NestedScrollPosition> get _innerPositions {
    ...
  }


  ScrollActivity createOuterBallisticScrollActivity(double velocity) {
    ...
  }

  @protected
  ScrollActivity createInnerBallisticScrollActivity(_NestedScrollPosition position, double velocity) {
    ...
  }

  @override
  void applyUserOffset(double delta) {
    ...
  }
}
```

可以看到_NestedScrollCoordinator在初始化的时候创建了_innerController和_outerController，

它们都是_NestedScrollController，让我们继续跟下看看 👀

##### _NestedScrollController

```dart
class _NestedScrollController extends ScrollController {

  ...

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _NestedScrollPosition(
      coordinator: coordinator,
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }

  Iterable<_NestedScrollPosition> get nestedPositions sync* {
    yield* Iterable.castFrom<ScrollPosition, _NestedScrollPosition>(positions);
  }
}
```

这里的_NestedScrollController重写了createScrollPosition方法，生成了_NestedScrollPosition，

并通过nestedPositions将附加到当前ScrollController上的ScrollPosition转换为_NestedScrollPosition，

所以我们继续跟下_NestedScrollPosition，看看它又是什么东西。

##### _NestedScrollPosition

```dart
// The _NestedScrollPosition is used by both the inner and outer viewports of a
// NestedScrollView. It tracks the offset to use for those viewports, and knows
// about the _NestedScrollCoordinator, so that when activities are triggered on
// this class, they can defer, or be influenced by, the coordinator.
class _NestedScrollPosition extends ScrollPosition implements ScrollActivityDelegate {

  ...

  final _NestedScrollCoordinator coordinator;

  @override
  double applyUserOffset(double delta) {
    ...
  }

  // This is called by activities when they finish their work.
  @override
  void goIdle() {
    ...
  }

  // This is called by activities when they finish their work and want to go
  // ballistic.
  @override
  void goBallistic(double velocity) {
    ...
  }

  ScrollActivity createBallisticScrollActivity(
    Simulation? simulation, {
    required _NestedBallisticScrollActivityMode mode,
    _NestedScrollMetrics? metrics,
  }) {
    ...
    switch (mode) {
      case _NestedBallisticScrollActivityMode.outer:
        return _NestedOuterBallisticScrollActivity(
          coordinator,
          this,
          metrics,
          simulation,
          context.vsync,
        );
      case _NestedBallisticScrollActivityMode.inner:
        return _NestedInnerBallisticScrollActivity(
          coordinator,
          this,
          simulation,
          context.vsync,
        );
      case _NestedBallisticScrollActivityMode.independent:
        return BallisticScrollActivity(this, simulation, context.vsync);
    }
  }

  ...

  @override
  void jumpTo(double value) {
    return coordinator.jumpTo(coordinator.unnestOffset(value, this));
  }

  @override
  ScrollHoldController hold(VoidCallback holdCancelCallback) {
    return coordinator.hold(holdCancelCallback);
  }

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    return coordinator.drag(details, dragCancelCallback);
  }
}
```

_NestedScrollPosition实现了ScrollActivityDelegate，并把相关的滑动事件转发到_NestedScrollCoordinator处理，可见_NestedScrollCoordinator实际上是内外滑动列表的手势协调器。

这里的createBallisticScrollActivity方法，对内外滑动列表分别返回了_NestedInnerBallisticScrollActivity、_NestedOuterBallisticScrollActivity。

让我们继续跟下看看。

##### _NestedBallisticScrollActivity

```dart
class _NestedInnerBallisticScrollActivity extends BallisticScrollActivity {

  ...

  final _NestedScrollCoordinator coordinator;

  @override
  bool applyMoveTo(double value) {
    return super.applyMoveTo(coordinator.nestOffset(value, delegate));
  }
}

class _NestedOuterBallisticScrollActivity extends BallisticScrollActivity {

  ...

  final _NestedScrollCoordinator coordinator;
  final _NestedScrollMetrics metrics;

  @override
  bool applyMoveTo(double value) {
    ...
  }
}
```

这里的_NestedInnerBallisticScrollActivity和_NestedOuterBallisticScrollActivity主要重写了BallisticScrollActivity的applyMoveTo方法，

将内外部滑动列表上的弹道模拟值交由_NestedScrollCoordinator协调器处理。

##### 连在一起

OK，我们已经知道了NestedScrollView内部的几个重要类，以及它们的创建流程。

总结下就是，NestedScrollView在initState时创建了一个_NestedScrollCoordinator，

并从coordinator中取出_innerController和_outerController分配给内部和外部滑动列表，

内外列表发生滑动事件时会通过_NestedScrollPosition和_NestedBallisticScrollActivity等把相应事件转发给coordinator处理，

所以coordinator才能协调内外列表的滑动过程，让它们无缝衔接起来。

现在我们回过头来看下_NestedScrollCoordinator是怎么协调outer跟inner二者之间的滑动过程的。

#### 滑动过程分析

对于ScrollActivity，作用在列表上主要表现在两个部分：

1. **applyUserOffset**，用户手指接触屏幕时的滑动

2. **goBallistic**，用户手指离开屏幕后的惯性滑动

*Tips:这部分比较枯燥，读不下去的可以直接看最后的解决方法*

##### applyUserOffset

首先分析下_NestedScrollCoordinator的applyUserOffset方法

```dart
  @override
  void applyUserOffset(double delta) {
    //更新滑动方向
    updateUserScrollDirection(
      delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse,
    );
    if (_innerPositions.isEmpty) {
      //内部列表尚未附加，由外部列表消耗全部滑动量
      _outerPosition!.applyFullDragUpdate(delta);
    } else if (delta < 0.0) {
      // 手指上滑
      double outerDelta = delta;
      for (final _NestedScrollPosition position in _innerPositions) {
        //内部列表顶部overscroll
        if (position.pixels < 0.0) {
          // 内部列表消耗上滑量，直到不再overscroll
          final double potentialOuterDelta = position.applyClampedDragUpdate(delta);
          outerDelta = math.max(outerDelta, potentialOuterDelta);
        }
      }
      if (outerDelta != 0.0) {
        //外部列表消耗剩余下滑量，不允许overscroll
        final double innerDelta = _outerPosition!.applyClampedDragUpdate(
          outerDelta,
        );
        if (innerDelta != 0.0) {
          //内部列表全量消耗剩余下滑量
          for (final _NestedScrollPosition position in _innerPositions)
            position.applyFullDragUpdate(innerDelta);
        }
      }
    } else {
      // 手指下滑
      double innerDelta = delta;
      // 如果外部列表的头部是float的，则由外部列表先消耗下滑量，不允许overscroll
      if (_floatHeaderSlivers)
        innerDelta = _outerPosition!.applyClampedDragUpdate(delta);
      if (innerDelta != 0.0) {
        double outerDelta = 0.0;
        final List<double> overscrolls = <double>[];
        final List<_NestedScrollPosition> innerPositions =  _innerPositions.toList();
        //内部列表先消耗下滑量，不允许overscroll
        for (final _NestedScrollPosition position in innerPositions) {
          final double overscroll = position.applyClampedDragUpdate(innerDelta);
          outerDelta = math.max(outerDelta, overscroll);
          overscrolls.add(overscroll);
        }
        //外部列表消耗剩余下滑量，不允许overscroll
        if (outerDelta != 0.0)
          outerDelta -= _outerPosition!.applyClampedDragUpdate(outerDelta);
        //内部列表全量消耗剩余下滑量
        for (int i = 0; i < innerPositions.length; ++i) {
          final double remainingDelta = overscrolls[i] - outerDelta;
          if (remainingDelta > 0.0)
            innerPositions[i].applyFullDragUpdate(remainingDelta);
        }
      }
    }
  }
```

符合NestedScrollView当前的行为：

外部列表不允许overscroll，内部列表可以overscroll，外部列表不可滑后，继续滚动内部列表。

##### goBallistic

```dart
  @override
  void goBallistic(double velocity) {
    beginActivity(
      createOuterBallisticScrollActivity(velocity),
      (_NestedScrollPosition position) {
        return createInnerBallisticScrollActivity(
          position,
          velocity,
        );
      },
    );
  }
```

在goBallistic阶段_NestedScrollCoordinator分别通过createInnerBallisticScrollActivity和createOuterBallisticScrollActivity方法，

在内外列表上创建了惯性滑动活动，下面让我们一起来看下这两个方法。

```dart
  ScrollActivity createOuterBallisticScrollActivity(double velocity) {

    ...

    final _NestedScrollMetrics metrics = _getMetrics(innerPosition, velocity);

    return _outerPosition!.createBallisticScrollActivity(
      _outerPosition!.physics.createBallisticSimulation(metrics, velocity),
      mode: _NestedBallisticScrollActivityMode.outer,
      metrics: metrics,
    );
  }

  @protected
  ScrollActivity createInnerBallisticScrollActivity(_NestedScrollPosition position, double velocity) {
    return position.createBallisticScrollActivity(
      position.physics.createBallisticSimulation(
        _getMetrics(position, velocity),
        velocity,
      ),
      mode: _NestedBallisticScrollActivityMode.inner,
    );
  }

  _NestedScrollMetrics _getMetrics(_NestedScrollPosition innerPosition, double velocity) {

    ...

    return _NestedScrollMetrics(
      minScrollExtent: _outerPosition!.minScrollExtent,
      maxScrollExtent: _outerPosition!.maxScrollExtent + innerPosition.maxScrollExtent - innerPosition.minScrollExtent + extra,
      pixels: pixels,
      viewportDimension: _outerPosition!.viewportDimension,
      axisDirection: _outerPosition!.axisDirection,
      minRange: minRange,
      maxRange: maxRange,
      correctionOffset: correctionOffset,
    );
  }
```

这两个方法的核心是让_innerPosition和_outerPosition以_innerPosition为基准，在内外列表的联合轨道上创建惯性滑动。

这里的_getMetrics方法是用来根据_innerPosition创建内外列表的联合轨道的。

通俗一点讲就是，把内外列表可滑动空间连接起来看成一个整体的可滑动空间。

现在让我们把目光收回到_NestedBallisticScrollActivity的applyMoveTo方法上，它是内外列表惯性滑动的最终执行者。

```dart
class _NestedInnerBallisticScrollActivity extends BallisticScrollActivity {

  ...

  final _NestedScrollCoordinator coordinator;

  @override
  bool applyMoveTo(double value) {
    return super.applyMoveTo(coordinator.nestOffset(value, delegate));
  }
}
```

注意这里的`coordinator.nestOffset`，它的作用是把coordinator中的联合轨道上的位置映射到对应的inner、outer列表中的位置。

```dart
  double nestOffset(double value, _NestedScrollPosition target) {
    if (target == _outerPosition)
      //外部列表不允许overscroll
      return value.clamp(
        _outerPosition!.minScrollExtent,
        _outerPosition!.maxScrollExtent,
      );
    if (value < _outerPosition!.minScrollExtent)
      return value - _outerPosition!.minScrollExtent + target.minScrollExtent;
    if (value > _outerPosition!.maxScrollExtent)
      return value - _outerPosition!.maxScrollExtent + target.minScrollExtent;
    return target.minScrollExtent;
  }
```

既然有从coordinator到inner、outer中位置的映射，自然也有从inner、outer中位置到coordinator的映射。

```dart
  double unnestOffset(double value, _NestedScrollPosition source) {
    if (source == _outerPosition)
      //外部列表不允许overscroll
      return value.clamp(
        _outerPosition!.minScrollExtent,
        _outerPosition!.maxScrollExtent,
      );
    if (value < source.minScrollExtent)
      return value - source.minScrollExtent + _outerPosition!.minScrollExtent;
    return value - source.minScrollExtent + _outerPosition!.maxScrollExtent;
  }
```


#### 解决方法

通过上面的层层分析可知，我们只需要：

1. 重写_NestedScrollCoordinator的applyUserOffset方法，允许_outerPosition的顶部过度滑动。

2. 重写_NestedScrollCoordinator的unnestOffset、nestOffset、_getMetrics方法，
修正_innerPosition与_outerPosition到_NestedScrollPosition（Coordinator）之间的映射关系。

即可让NestedScrollView支持带有stretch的SliverAppBar的NestedScrollView。

### 对于场景 2: 

首先，这个问题的解决方法有很多种，比较容易实现的是[ExtendedTabBarView](https://github.com/fluttercandies/extended_tabs)那种：

当内部的列表开始overscroll时，如果外部Tab还没有overscroll，则将用户的过度滑动量通过外部Tab的drag方法作用到外部。

不过这种方法并没有像NestedScrollView那样在内外Tab滑动列表之间建立联合轨道，完美协调内外列表的滑动过程。

而仅仅只是通过drag方法勾通内外列表的滑动过程，必然会存在各种各样的小问题，不过时间有限，我们这里不再深究。

#### 解决方法

参考ExtendedTabBarView，新增TabScrollView，绑定ScrollController，

当内部列表过度滑动时，将过度滑动量作用到外部可滚动ExtendedTabBarView上。


## 🌈 组件封装

限于篇幅，这里我只贴出关键代码，完整代码可以查看文章底部的项目地址。

### 对于场景 1: 

```dart
class _NestedScrollCoordinatorX extends _NestedScrollCoordinator {

  ...

  @override
  _NestedScrollMetrics _getMetrics(
      _NestedScrollPosition innerPosition, double velocity) {
    return _NestedScrollMetrics(
      minScrollExtent: _outerPosition!.minScrollExtent, 
      maxScrollExtent: _outerPosition!.maxScrollExtent + (innerPosition.maxScrollExtent - innerPosition.minScrollExtent), 
      pixels: unnestOffset(innerPosition.pixels, innerPosition), 
      viewportDimension: _outerPosition!.viewportDimension, 
      axisDirection: _outerPosition!.axisDirection,
      minRange: 0,
      maxRange: 0,
      correctionOffset: 0,
    );
  }

  @override
  double unnestOffset(double value, _NestedScrollPosition source) {
    if (source == _outerPosition) {
      if (_innerPosition!.pixels > _innerPosition!.minScrollExtent) {
        //inner在滚动，以inner位置为基准
        return source.maxScrollExtent + _innerPosition!.pixels - _innerPosition!.minScrollExtent;
      }
      return value;
    } else {
      if (_outerPosition!.pixels < _outerPosition!.maxScrollExtent) {
        //outer在滚动，以outer位置为基准
        return _outerPosition!.pixels;
      }
      return _outerPosition!.maxScrollExtent + (value - source.minScrollExtent);
    }
  }

  @override
  double nestOffset(double value, _NestedScrollPosition target) {
    if (target == _outerPosition) {
      if (value > _outerPosition!.maxScrollExtent) {
        //不允许outer底部overscroll
        return _outerPosition!.maxScrollExtent;
      }
      return value;
    } else {
      if (value < _outerPosition!.maxScrollExtent) {
        //不允许innner顶部overscroll
        return target.minScrollExtent;
      }
      return (target.minScrollExtent +
          (value - _outerPosition!.maxScrollExtent));
    }
  }

  @override
  void applyUserOffset(double delta) {
    ...
    if (delta < 0.0) {
      ...
    } else {
      // 手指下滑
      double innerDelta = delta;
      // 如果外部列表的头部是float的，则由外部列表先消耗下滑量，不允许overscroll
      if (_floatHeaderSlivers)
        innerDelta = _outerPosition!.applyClampedDragUpdate(delta);
      if (innerDelta != 0.0) {
        double outerDelta = 0.0;
        final List<double> overscrolls = <double>[];
        final List<_NestedScrollPosition> innerPositions =  _innerPositions.toList();
        //内部列表先消耗下滑量，不允许overscroll
        for (final _NestedScrollPosition position in innerPositions) {
          final double overscroll = position.applyClampedDragUpdate(innerDelta);
          outerDelta = math.max(outerDelta, overscroll);
          overscrolls.add(overscroll);
        }
        if (outerDelta != 0.0) {
          //外部列表全量消耗剩余下滑量
          _outerPosition!.applyFullDragUpdate(outerDelta);
        }
      }
    }
  }
}

class _NestedBallisticScrollActivityX extends BallisticScrollActivity {

  ...

  @override
  bool applyMoveTo(double value) {
    return super.applyMoveTo(coordinator.nestOffset(value, delegate));
  }
}
```

### 对于场景 2: 

```dart
class _TabScrollViewState extends State<TabScrollView> {

  ...

  @override
  Widget build(BuildContext context) {
    return _canDrag
        ? RawGestureDetector(
            gestures: _gestureRecognizers!,
            behavior: HitTestBehavior.opaque,
            child: AbsorbPointer(
              child: widget.child, //屏蔽内部滑动列表的滑动手势，交给RawGestureDetector去处理拖拽量
            ),
          )
        : widget.child;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _handleAncestor(details, _ancestor);
    if (_ancestor?._drag != null) {
      _ancestor!._drag!.update(details);
    } else {
      _drag?.update(details);
    }
  }

  _ExtendedTabBarViewState? _ancestorCanDrag(DragUpdateDetails details, _ExtendedTabBarViewState? state) {
    var ancestor = state;
    final delta = widget.scrollDirection == Axis.horizontal
        ? details.delta.dx
        : details.delta.dy;
    if (delta < 0) {
      while (ancestor != null) {
        if (ancestor._position?.extentAfter != 0) {
          return ancestor;
        }
        ancestor = ancestor._ancestor;
      }
    }
    if (delta > 0) {
      while (ancestor != null) {
        if (ancestor._position?.extentBefore != 0) {
          return ancestor;
        }
        ancestor = ancestor._ancestor;
      }
    }
    return null;
  }

  bool _handleAncestor(DragUpdateDetails details, _ExtendedTabBarViewState? state) {
    if (state?._position != null) {
      final delta = widget.scrollDirection == Axis.horizontal
          ? details.delta.dx
          : details.delta.dy;
      //当前过滑
      if ((delta < 0 &&
              _position?.extentAfter == 0 &&
              _ancestorCanDrag(details, state) != null) ||
          (delta > 0 &&
              _position?.extentBefore == 0 &&
              _ancestorCanDrag(details, state) != null)) {
        state = _ancestorCanDrag(details, state)!;
        if (state.widget.scrollDirection == widget.scrollDirection) {
          if (state._drag == null && state._hold == null) {
            state._handleDragDown(null);
          }
          if (state._drag == null) {
            state._handleDragStart(DragStartDetails(
              globalPosition: details.globalPosition,
              localPosition: details.localPosition,
              sourceTimeStamp: details.sourceTimeStamp,
            ));
          }
          return true;
        }
      }
    }
    return false;
  }
}
```

## 🔧 项目地址

更多细节请戳 👉 [网页链接](https://github.com/idootop/scroll_master)

## 🌍 在线预览

打开网页查看效果 👉  [网页链接](https://killer-1255480117.cos.ap-chongqing.myqcloud.com/web/scrollMaster/index.html)

## ❤️ 鸣谢

非常感谢[fluttercandies](https://github.com/fluttercandies)的[extended_tabs](https://github.com/fluttercandies/extended_tabs)和[extended_nested_scroll_view](https://github.com/fluttercandies/extended_nested_scroll_view)

## 📖 参考资料

* [大道至简：Flutter嵌套滑动冲突解决之路](http://vimerzhao.top/posts/flutter-nested-scroll-conflict/)
* [深入进阶-如何解决Flutter上的滑动冲突？ ](https://juejin.cn/post/6900751363173515278)
* [用Flutter实现58App的首页](https://blog.csdn.net/weixin_39891694/article/details/111217123)
* [不一样角度带你了解 Flutter 中的滑动列表实现](https://blog.csdn.net/ZuoYueLiang/article/details/116245138)
* [Flutter 滑动体系 ](https://juejin.cn/post/6983338779415150628)