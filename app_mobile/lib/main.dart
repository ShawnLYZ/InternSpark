import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/login_screen.dart';
import 'src/student_shell.dart';
import 'src/verification_wizard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: SupabaseConfig.url, publishableKey: SupabaseConfig.anonKey);
  runApp(const ProviderScope(child: InternSparkMobileApp()));
}

class InternSparkMobileApp extends StatelessWidget {
  const InternSparkMobileApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InternSpark',
      theme: AppThemes.playfulMobile,
      home: const MobileAuthGate(),
    );
  }
}

class MobileAuthGate extends ConsumerWidget {
  const MobileAuthGate({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    return profile.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (p) {
        if (p == null) return const LoginScreen();
        if (p.role != UserRole.student) {
          return const Scaffold(body: Center(child: Text('This app is for students. Use the web app.')));
        }
        final needs = ref.watch(needsVerificationProvider);
        return needs.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
          data: (n) => n ? const VerificationWizardScreen() : const StudentShell(),
        );
      },
    );
  }
}
