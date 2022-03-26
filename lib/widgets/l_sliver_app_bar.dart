import 'package:flutter/material.dart';

import 'l_flexible_space_bar.dart';

typedef FlexibleBuilder = Widget Function(
  BuildContext context,
  double minHeight,
  double maxHeight,
  double currentHeight,
);

class LSliverAppBar extends StatelessWidget {
  const LSliverAppBar({
    Key? key,
    this.minHeight = 100,
    this.maxHeight = 400,
    this.titleBuilder,
    required this.backgroundBuilder,
    this.bottom,
    this.backgroundColor,
    this.pinned = true,
    this.stretch = true,
  }) : super(key: key);

  final double minHeight;
  final double maxHeight;

  final FlexibleBuilder? titleBuilder;
  final FlexibleBuilder backgroundBuilder;

  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;
  final bool pinned;
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    final topPadding = MediaQuery.of(context).padding.top;

    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: pinned,
      stretch: stretch,
      toolbarHeight: minHeight - bottomHeight - topPadding,
      collapsedHeight: minHeight - bottomHeight - topPadding,
      expandedHeight: maxHeight - topPadding,
      elevation: 0,
      titleSpacing: 0,
      backgroundColor: backgroundColor,
      bottom: bottom,
      flexibleSpace: LFlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        stretchModes: [StretchMode.zoomBackground],
        titlePadding: EdgeInsets.zero,
        titleBuilder: (_, setting) => LayoutBuilder(
          builder: (context, constraints) {
            final minHeight = setting.minExtent;
            final maxHeight = setting.maxExtent;
            final currentHeight = constraints.maxHeight;
            if (titleBuilder == null) return Container();
            return titleBuilder!(context, minHeight, maxHeight, currentHeight);
          },
        ),
        backgroundBuilder: (_, setting) => LayoutBuilder(
          builder: (context, constraints) {
            final minHeight = setting.minExtent;
            final maxHeight = setting.maxExtent;
            final currentHeight = constraints.maxHeight;
            return backgroundBuilder(
                context, minHeight, maxHeight, currentHeight);
          },
        ),
      ),
    );
  }
}
