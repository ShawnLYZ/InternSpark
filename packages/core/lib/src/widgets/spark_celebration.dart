import 'package:flutter/material.dart';
import '../design/app_tokens.dart';

/// The animated mutual-match celebration (scale + fade in). Shown in a dialog.
class SparkCelebration extends StatefulWidget {
  const SparkCelebration({super.key, required this.company});
  final String company;
  @override
  State<SparkCelebration> createState() => _SparkCelebrationState();
}

class _SparkCelebrationState extends State<SparkCelebration> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450))..forward();
  late final Animation<double> _scale = CurvedAnimation(parent: _c, curve: Curves.elasticOut);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return FadeTransition(
      opacity: _c,
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [scheme.primary, scheme.tertiary],
                ),
                shape: BoxShape.circle,
                boxShadow: AppTokens.shadowLg(scheme.primary),
              ),
              child: const Icon(Icons.bolt_rounded, size: 52, color: Colors.white),
            ),
            const SizedBox(height: AppTokens.space20),
            Text("It's a Spark!",
                style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppTokens.space8),
            Text('You matched with ${widget.company}.',
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
