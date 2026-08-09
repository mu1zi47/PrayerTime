import 'package:flutter/material.dart';

/// Global key so a fired notification's tap handler (which runs outside
/// any widget's BuildContext) can still push a route.
final navigatorKey = GlobalKey<NavigatorState>();
