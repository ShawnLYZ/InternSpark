import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/web_login_screen.dart';
import 'src/employer_shell.dart';
import 'src/university_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: SupabaseConfig.url, publishableKey: SupabaseConfig.anonKey);
  runApp(const ProviderScope(child: InternSparkWebApp()));
}

class InternSparkWebApp extends StatelessWidget {
  const InternSparkWebApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InternSpark',
      theme: AppThemes.professionalWeb,
      home: const WebAuthGate(),
    );
  }
}

class WebAuthGate extends ConsumerWidget {
  const WebAuthGate({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    return profile.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (p) {
        if (p == null) return const WebLoginScreen();
        switch (p.role) {
          case UserRole.employer:
            return const EmployerShell();
          case UserRole.university:
            return const UniversityShell();
          case UserRole.student:
            return const Scaffold(body: Center(child: Text('Students use the mobile app.')));
        }
      },
    );
  }
}
