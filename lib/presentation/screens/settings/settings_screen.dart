import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../widgets/caldera_scaffold.dart';

/// Phase 0 stub. Real controls (animation speed, reduced motion, SFX,
/// reset progress) land in Phase 7.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return CalderaScaffold(
      onBack: () => context.go(AppRoutes.home),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.x24),
          Text('SETTINGS', style: text.headlineLarge),
          const SizedBox(height: AppSpacing.x16),
          Text('Controls arrive in Phase 7.', style: text.bodyLarge),
        ],
      ),
    );
  }
}
