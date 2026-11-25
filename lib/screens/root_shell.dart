import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_design_system.dart';
import '../widgets/ambient_surface.dart';
import 'home_screen.dart';

class RootShell extends StatelessWidget {
  const RootShell({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    return AmbientScaffold(
      backgroundColor: AppColors.bg,
      body: HomeScreen(appState: appState),
    );
  }
}
