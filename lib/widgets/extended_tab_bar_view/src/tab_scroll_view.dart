part of 'tab_view.dart';

class TabScrollView extends StatefulWidget {
  final Widget child;
  final Axis scrollDirection;
  final ScrollController controller;
  final ScrollPhysics? physics;
  const TabScrollView({
    required this.child,
    required this.controller,
    this.physics,
    this.scrollDirection = Axis.horizontal,
    Key? key,
  }) : super(key: key);

  @override
  _TabScrollViewState createState() => _TabScrollViewState();
}

class _TabScrollViewState extends State<TabScrollView> {
  ScrollController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _updatePhysics();
    _initGestureRecognizers();
  }

  bool _handleGlowNotification(OverscrollIndicatorNotification notification) {
    if (notification.depth == 0 &&
        (_disallowGlow(notification.leading, {
              'offset': _ancestor?._pageController?.offset,
              'position': _ancestor?._pageController?.position,
            }) ||
            _disallowGlow(notification.leading, {
              'offset': _controller.offset,
              'position': _controller.position,
            }))) {
      notification.disallowIndicator();
      return true;
    }
    return false;
  }

  bool _disallowGlow(bool leading, Map<String, dynamic> p) {
    if (p['position'] == null) {
      return false;
    }

    return (leading && p['offset'] != p['position']?.minScrollExtent) ||
        (!leading && p['offset'] != p['position']?.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    return _canDrag
        ? RawGestureDetector(
            gestures: _gestureRecognizers!,
            behavior: HitTestBehavior.opaque,
            child: NotificationListener<OverscrollIndicatorNotification>(
                onNotification: _handleGlowNotification, child: widget.child),
          )
        : widget.child;
  }

  _ExtendedTabBarViewState? _ancestor;
  late bool _canDrag;

  Drag? _drag;
  ScrollHoldController? _hold;
  ScrollPosition? get _position =>
      _controller.hasClients ? _controller.position : null;
  Map<Type, GestureRecognizerFactory>? _gestureRecognizers =
      const <Type, GestureRecognizerFactory>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateAncestor();
  }

  @override
  void didUpdateWidget(TabScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAncestor();
    if (widget.physics != oldWidget.physics) {
      _updatePhysics();
    }
    _initGestureRecognizers(oldWidget);
  }

  void _updatePhysics() {

    if (widget.physics == null) {
      _canDrag = true;
    } else {
      _canDrag = widget.physics!.shouldAcceptUserOffset(_testPageMetrics);
    }
  }

  void _updateAncestor() {
    if (_ancestor != null) {
      _ancestor!._child = null;
      _ancestor = null;
    }
    _ancestor = context.findAncestorStateOfType<_ExtendedTabBarViewState>();
  }

  void _initGestureRecognizers([TabScrollView? oldWidget]) {
    if (oldWidget == null ||
        oldWidget.scrollDirection != widget.scrollDirection ||
        oldWidget.physics != widget.physics) {
      if (_canDrag) {
        switch (widget.scrollDirection) {
          case Axis.vertical:
            _gestureRecognizers = <Type, GestureRecognizerFactory>{
              VerticalDragGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                      VerticalDragGestureRecognizer>(
                () => VerticalDragGestureRecognizer(),
                (VerticalDragGestureRecognizer instance) {
                  instance
                    ..onDown = _handleDragDown
                    ..onStart = _handleDragStart
                    ..onUpdate = _handleDragUpdate
                    ..onEnd = _handleDragEnd
                    ..onCancel = _handleDragCancel
                    ..minFlingDistance = widget.physics?.minFlingDistance
                    ..minFlingVelocity = widget.physics?.minFlingVelocity
                    ..maxFlingVelocity = widget.physics?.maxFlingVelocity;
                },
              ),
            };
            break;
          case Axis.horizontal:
            _gestureRecognizers = <Type, GestureRecognizerFactory>{
              HorizontalDragGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                      HorizontalDragGestureRecognizer>(
                () => HorizontalDragGestureRecognizer(),
                (HorizontalDragGestureRecognizer instance) {
                  instance
                    ..onDown = _handleDragDown
                    ..onStart = _handleDragStart
                    ..onUpdate = _handleDragUpdate
                    ..onEnd = _handleDragEnd
                    ..onCancel = _handleDragCancel
                    ..minFlingDistance = widget.physics?.minFlingDistance
                    ..minFlingVelocity = widget.physics?.minFlingVelocity
                    ..maxFlingVelocity = widget.physics?.maxFlingVelocity;
                },
              ),
            };
            break;
        }
      } else {
        _gestureRecognizers = null;
        _hold?.cancel();
        _drag?.cancel();
      }
    }
  }

  void _handleDragDown(DragDownDetails? details) {
    if (_drag != null) {
      _drag!.cancel();
    }
    assert(_drag == null);
    assert(_hold == null);

    _hold = _position?.hold(_disposeHold);
  }

  void _handleDragStart(DragStartDetails details) {
    if (_drag != null) {
      _drag!.cancel();
    }
    // It's possible for _hold to become null between _handleDragDown and
    // _handleDragStart, for example if some user code calls jumpTo or otherwise
    // triggers a new activity to begin.
    assert(_drag == null);
    _drag = _position?.drag(details, _disposeDrag);
    assert(_drag != null);
    assert(_hold == null);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    // _drag might be null if the drag activity ended and called _disposeDrag.
    assert(_hold == null || _drag == null);
    _handleAncestor(details, _ancestor);

    if (_ancestor?._drag != null) {
      _ancestor!._drag!.update(details);
    } else {
      _drag?.update(details);
    }
  }

  _ExtendedTabBarViewState? _ancestorCanDrag(
      DragUpdateDetails details, _ExtendedTabBarViewState? state) {
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

  bool _handleAncestor(
      DragUpdateDetails details, _ExtendedTabBarViewState? state) {
    if (state?._position != null) {
      final delta = widget.scrollDirection == Axis.horizontal
          ? details.delta.dx
          : details.delta.dy;

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

  void _handleDragEnd(DragEndDetails details) {
    // _drag might be null if the drag activity ended and called _disposeDrag.
    assert(_hold == null || _drag == null);

    _ancestor?._drag?.end(details);
    _drag?.end(details);

    assert(_drag == null);
  }

  void _handleDragCancel() {
    // _hold might be null if the drag started.
    // _drag might be null if the drag activity ended and called _disposeDrag.
    assert(_hold == null || _drag == null);
    _ancestor?._hold?.cancel();
    _ancestor?._drag?.cancel();
    _hold?.cancel();
    _drag?.cancel();
    assert(_hold == null);
    assert(_drag == null);
  }

  void _disposeHold() {
    _hold = null;
  }

  void _disposeDrag() {
    _drag = null;
  }
}
