import 'package:flutter/widgets.dart';

/// 页面保活，可确保子组件在切换tab时保持活性
class AliveKeeper extends StatefulWidget {
  final Widget child;

  const AliveKeeper({Key? key, required this.child}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AliveState();
}

class _AliveState extends State<AliveKeeper>
    with AutomaticKeepAliveClientMixin<AliveKeeper> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
