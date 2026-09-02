import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Title screen. Phase 7 adds the idling demo circuit behind the type.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final wide = MediaQuery.sizeOf(context).width >= 768;

    return Scaffold(
      backgroundColor: AppColors.pumice,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppSpacing.pageMaxWidth),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.x24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LOGIC',
                    style: wide ? text.displayLarge : text.headlineLarge,
                  ),
                  Text(
                    'CIRCUIT',
                    style: (wide ? text.displayLarge : text.headlineLarge)
                        ?.copyWith(color: AppColors.ember),
                  ),
                  Text(
                    'BUILDER',
                    style: wide ? text.displayLarge : text.headlineLarge,
                  ),
                  const SizedBox(height: AppSpacing.x24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Text(
                      'Wire gates together until the lamps match the table. '
                      'From a single NOT gate to a full adder.',
                      style: text.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x40),
                  Wrap(
                    spacing: AppSpacing.x12,
                    runSpacing: AppSpacing.x12,
                    children: [
                      FilledButton(
                        onPressed: () => context.go(AppRoutes.levelSelect),
                        child: const Text('Play'),
                      ),
                      OutlinedButton(
                        onPressed: () => context.go(AppRoutes.settings),
                        child: const Text('Settings'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
