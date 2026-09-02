import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app_router.dart';
import '../../../application/progress_controller.dart';
import '../../../core/constants/animation_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/levels/level_repository.dart';
import '../../widgets/caldera_scaffold.dart';

/// Motion, sound, and the reset-progress escape hatch.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final progress = ref.watch(progressProvider);
    final controller = ref.read(progressControllerProvider.notifier);
    final text = Theme.of(context).textTheme;
    final levelCount = const LevelRepository().count;

    return CalderaScaffold(
      onBack: () => context.go(AppRoutes.home),
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.x40),
        children: [
          const SizedBox(height: AppSpacing.x16),
          Text('SETTINGS', style: text.headlineLarge),
          const SizedBox(height: AppSpacing.x24),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Animation speed', style: text.titleSmall),
                Text(
                  '${settings.animationSpeed.toStringAsFixed(1)}x — higher is '
                  'quicker.',
                  style: text.bodySmall,
                ),
                Slider(
                  value: settings.animationSpeed,
                  min: AnimationConstants.minSpeed,
                  max: AnimationConstants.maxSpeed,
                  divisions: 6,
                  label: '${settings.animationSpeed.toStringAsFixed(1)}x',
                  onChanged: settings.reducedMotion
                      ? null
                      : (value) => controller.updateSettings(
                            settings.copyWith(animationSpeed: value),
                          ),
                ),
              ],
            ),
          ),
          _Card(
            child: _SwitchRow(
              title: 'Reduced motion',
              subtitle:
                  'Signals and celebrations change state without travelling.',
              value: settings.reducedMotion,
              onChanged: (value) => controller.updateSettings(
                settings.copyWith(reducedMotion: value),
              ),
            ),
          ),
          _Card(
            child: _SwitchRow(
              title: 'Sound effects',
              subtitle: 'Small clicks and chimes while you build.',
              value: settings.soundEnabled,
              onChanged: (value) => controller.updateSettings(
                settings.copyWith(soundEnabled: value),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x24),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Progress', style: text.titleSmall),
                const SizedBox(height: AppSpacing.x4),
                Text(
                  '${progress.totalStars} of ${levelCount * 3} stars, '
                  '${progress.levels.values.where((l) => l.solved).length} of '
                  '$levelCount levels solved.',
                  style: text.bodySmall,
                ),
                const SizedBox(height: AppSpacing.x16),
                OutlinedButton(
                  onPressed: () => _confirmReset(context, ref),
                  child: const Text('Reset all progress'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x24),
          Text(
            'Everything is stored on this device. No account, no server, '
            'nothing leaves the phone.',
            style: text.bodySmall?.copyWith(color: AppColors.obsidianMuted),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset all progress?'),
        content: const Text(
          'Stars, best gate counts and unlocked levels all go back to the '
          'start. Your settings stay as they are. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(progressControllerProvider.notifier).resetProgress();
    }
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.x8),
      padding: const EdgeInsets.all(AppSpacing.x20),
      decoration: BoxDecoration(
        color: AppColors.limestone,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: child,
    );
  }
}

/// A labelled switch.
///
/// Hand-rolled rather than `SwitchListTile`, which insists on painting its
/// background onto the nearest Material and asserts when it sits inside a
/// coloured card — which every card in this flat design is.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Semantics(
      toggled: value,
      label: title,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleSmall),
                const SizedBox(height: AppSpacing.x4),
                Text(subtitle, style: text.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.x12),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
