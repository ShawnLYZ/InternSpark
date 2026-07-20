import 'dart:async';
import 'package:flutter/material.dart';
import '../domain/countdown.dart';
import 'app_ui.dart';

/// The one shared countdown badge. Renders time-left to [deadline], ticking each
/// minute, tone-coded by urgency. Inject [clock] in tests for determinism
/// (defaults to DateTime.now).
class SparkCountdown extends StatefulWidget {
  const SparkCountdown({super.key, required this.deadline, this.clock});

  final DateTime deadline;
  final DateTime Function()? clock;

  @override
  State<SparkCountdown> createState() => _SparkCountdownState();
}

class _SparkCountdownState extends State<SparkCountdown> {
  Timer? _timer;
  DateTime get _now => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    if (widget.clock == null) {
      _timer = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = countdownRemaining(widget.deadline, _now);
    final expired = left <= Duration.zero;
    final urgent = !expired && left < const Duration(hours: 12);
    final tone = expired
        ? PillTone.danger
        : urgent
            ? PillTone.warning
            : PillTone.info;
    return Pill(
      expired ? 'Expired' : '${formatCountdown(left)} left',
      icon: expired ? Icons.timer_off_outlined : Icons.timer_outlined,
      tone: tone,
    );
  }
}
