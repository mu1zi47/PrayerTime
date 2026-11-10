import 'package:flutter/material.dart';

import 'ambient_surface.dart';
import 'floating_tab_bar.dart';

/// One viewport for all three root tabs. Only the bar and its normal gap
/// stay outside scrolling; top safe-area spacing scrolls with the content.
class RootTabContent extends StatelessWidget {
  final Widget child;
  const RootTabContent({super.key, required this.child});

  static EdgeInsets scrollPadding(BuildContext context) =>
      EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 16);

  @override
  Widget build(BuildContext context) => ScreenContentInset(
    margin: EdgeInsets.fromLTRB(
      18,
      0,
      18,
      FloatingTabBar.contentBottomInset(context),
    ),
    child: child,
  );
}
