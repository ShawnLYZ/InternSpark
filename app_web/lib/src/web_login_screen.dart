import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internspark_core/internspark_core.dart';

/// The login-mode toggle the PRD requires. It themes the heading only —
/// actual routing uses the real `profiles.role` after sign-in.
enum LoginMode { employer, university }

class WebLoginScreen extends ConsumerStatefulWidget {
  const WebLoginScreen({super.key});
  @override
  ConsumerState<WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends ConsumerState<WebLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  LoginMode _mode = LoginMode.employer;
  String? _error;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final form = _FormPanel(
            email: _email,
            password: _password,
            mode: _mode,
            error: _error,
            busy: _busy,
            obscure: _obscure,
            onMode: (m) => setState(() => _mode = m),
            onToggleObscure: () => setState(() => _obscure = !_obscure),
            onSignIn: _busy ? null : _signIn,
          );
          if (!wide) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTokens.space24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppTokens.formMaxWidth),
                  child: form,
                ),
              ),
            );
          }
          return Row(
            children: [
              const Expanded(child: _BrandPanel()),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTokens.space40),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: AppTokens.formMaxWidth),
                      child: form,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.tertiary],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 27),
                ),
                const SizedBox(width: AppTokens.space12),
                Text('InternSpark',
                    style: text.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: AppTokens.space32),
            Text('Hire and place\ninterns with signal,\nnot spam.',
                style: text.displaySmall?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w800, height: 1.1)),
            const SizedBox(height: AppTokens.space20),
            _Point(text: 'Swipe a curated queue of fit-scored applicants'),
            _Point(text: 'Candidates stay anonymous until a mutual match'),
            _Point(text: 'Ghost-busting response metrics keep everyone honest'),
          ],
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
          const SizedBox(width: AppTokens.space12),
          Expanded(
            child: Text(text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    )),
          ),
        ],
      ),
    );
  }
}

class _FormPanel extends StatelessWidget {
  const _FormPanel({
    required this.email,
    required this.password,
    required this.mode,
    required this.error,
    required this.busy,
    required this.obscure,
    required this.onMode,
    required this.onToggleObscure,
    required this.onSignIn,
  });

  final TextEditingController email;
  final TextEditingController password;
  final LoginMode mode;
  final String? error;
  final bool busy;
  final bool obscure;
  final ValueChanged<LoginMode> onMode;
  final VoidCallback onToggleObscure;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Sign in to your workspace',
            style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: AppTokens.space8),
        Text('Choose your account type to continue.',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: AppTokens.space24),
        SegmentedButton<LoginMode>(
          segments: const [
            ButtonSegment(
                value: LoginMode.employer,
                label: Text('Employer'),
                icon: Icon(Icons.business_center_outlined)),
            ButtonSegment(
                value: LoginMode.university,
                label: Text('University'),
                icon: Icon(Icons.school_outlined)),
          ],
          selected: {mode},
          onSelectionChanged: (s) => onMode(s.first),
        ),
        const SizedBox(height: AppTokens.space20),
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.alternate_email_rounded),
          ),
        ),
        const SizedBox(height: AppTokens.space12),
        TextField(
          controller: password,
          obscureText: obscure,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => onSignIn?.call(),
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              tooltip: obscure ? 'Show password' : 'Hide password',
              onPressed: onToggleObscure,
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: AppTokens.space12),
          Row(
            children: [
              Icon(Icons.error_outline_rounded, size: 18, color: scheme.error),
              const SizedBox(width: AppTokens.space8),
              Expanded(child: Text(error!, style: text.bodySmall?.copyWith(color: scheme.error))),
            ],
          ),
        ],
        const SizedBox(height: AppTokens.space20),
        FilledButton(
          onPressed: onSignIn,
          child: busy
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : const Text('Sign in'),
        ),
        const SizedBox(height: AppTokens.space16),
        Container(
          padding: const EdgeInsets.all(AppTokens.space12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: AppTokens.space8),
              Expanded(
                child: Text('Demo: employer@internspark.demo · university@internspark.demo · Passw0rd!demo',
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
