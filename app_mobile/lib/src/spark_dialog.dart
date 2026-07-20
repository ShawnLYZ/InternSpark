import 'package:flutter/material.dart';
import 'package:internspark_core/internspark_core.dart';

Future<void> showSparkDialog(BuildContext context, String company) {
  return showDialog(
    context: context,
    builder: (_) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SparkCelebration(company: company),
            const SizedBox(height: AppTokens.space24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Keep swiping'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
