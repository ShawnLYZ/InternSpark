import 'package:flutter/material.dart';
import '../design/app_tokens.dart';

/// Shared loading state.
class AppLoading extends StatelessWidget {
  const AppLoading({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

/// Shared error state with an optional retry.
class AppError extends StatelessWidget {
  const AppError({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => _StatePane(
        icon: Icons.error_outline_rounded,
        tone: AppTokens.danger,
        toneContainer: AppTokens.dangerContainer,
        message: message,
        actionLabel: onRetry != null ? 'Retry' : null,
        onAction: onRetry,
      );
}

/// Shared empty state with an optional action.
class AppEmpty extends StatelessWidget {
  const AppEmpty({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.inbox_outlined,
  });
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) => _StatePane(
        icon: icon,
        message: message,
        actionLabel: (actionLabel != null && onAction != null) ? actionLabel : null,
        onAction: onAction,
      );
}

class _StatePane extends StatelessWidget {
  const _StatePane({
    required this.icon,
    required this.message,
    this.tone,
    this.toneContainer,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final Color? tone;
  final Color? toneContainer;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: toneContainer ?? scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: tone ?? scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppTokens.space16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppTokens.space20),
              FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
