import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Shared page chrome: Pumice canvas, a centered 1280px column, and an
/// optional back affordance rendered as an outlined pill.
class CalderaScaffold extends StatelessWidget {
  const CalderaScaffold({
    super.key,
    required this.child,
    this.onBack,
    this.actions = const [],
  });

  final Widget child;
  final VoidCallback? onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.pumice,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppSpacing.pageMaxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x24,
                vertical: AppSpacing.x24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (onBack != null || actions.isNotEmpty)
                    Row(
                      children: [
                        if (onBack != null)
                          OutlinedButton(
                            onPressed: onBack,
                            child: const Text('Back'),
                          ),
                        const Spacer(),
                        ...actions,
                      ],
                    ),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
