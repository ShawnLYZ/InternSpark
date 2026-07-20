import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internspark_core/internspark_core.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;
  bool _obscure = true;

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signIn(email: _email.text.trim(), password: _password.text);
      ref.invalidate(currentProfileProvider);
    } catch (_) {
      setState(() => _error = 'Sign-in failed. Check your credentials.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTokens.space24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppTokens.formMaxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand hero.
                  Container(
                    padding: const EdgeInsets.all(AppTokens.space24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [scheme.primary, scheme.tertiary],
                      ),
                      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                      boxShadow: AppTokens.shadowMd(scheme.primary),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BrandMark(size: 44, showWordmark: false),
                        const SizedBox(height: AppTokens.space16),
                        Text('Swipe into the\ninternship that grows you.',
                            style: text.headlineMedium?.copyWith(
                                color: Colors.white, fontWeight: FontWeight.w800, height: 1.15)),
                        const SizedBox(height: AppTokens.space8),
                        Text('For students. Anonymous until you match.',
                            style: text.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9))),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.space24),
                  Text('Welcome back', style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppTokens.space16),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                  ),
                  const SizedBox(height: AppTokens.space12),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _busy ? null : _signIn(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        tooltip: _obscure ? 'Show password' : 'Hide password',
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppTokens.space12),
                    Row(
                      children: [
                        Icon(Icons.error_outline_rounded, size: 18, color: scheme.error),
                        const SizedBox(width: AppTokens.space8),
                        Expanded(
                          child: Text(_error!, style: text.bodySmall?.copyWith(color: scheme.error)),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppTokens.space20),
                  FilledButton(
                    onPressed: _busy ? null : _signIn,
                    child: _busy
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Sign in'),
                  ),
                  const SizedBox(height: AppTokens.space16),
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const SignupScreen())),
                    child: const Text('Create account'),
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
