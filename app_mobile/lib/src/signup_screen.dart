import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

/// Thin student registration: name + email + password. University selection
/// deliberately lives in the verification wizard (the universities catalog is
/// only readable post-auth under RLS). Signup returns a live session because
/// email confirmation is disabled server-side (ops step, docs/DEMO.md).
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final name = _name.text.trim();
    final email = _email.text.trim();
    if (name.isEmpty || email.isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Fill in your name, email, and password.');
      return;
    }
    if (_password.text != _confirm.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .signUp(email: email, password: _password.text, fullName: name);
      ref.invalidate(currentProfileProvider);
      if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not create your account. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
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
                  Text('Join InternSpark',
                      style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: AppTokens.space4),
                  Text('Students only. Your skills get verified right after this.',
                      style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: AppTokens.space20),
                  TextField(
                    key: const Key('full-name'),
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(
                        labelText: 'Full name', prefixIcon: Icon(Icons.badge_outlined)),
                  ),
                  const SizedBox(height: AppTokens.space12),
                  TextField(
                    key: const Key('email'),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                        labelText: 'Email', prefixIcon: Icon(Icons.alternate_email_rounded)),
                  ),
                  const SizedBox(height: AppTokens.space12),
                  TextField(
                    key: const Key('password'),
                    controller: _password,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.next,
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
                  const SizedBox(height: AppTokens.space12),
                  TextField(
                    key: const Key('confirm-password'),
                    controller: _confirm,
                    obscureText: _obscure,
                    onSubmitted: (_) => _busy ? null : _submit(),
                    decoration: const InputDecoration(
                        labelText: 'Confirm password', prefixIcon: Icon(Icons.lock_outline_rounded)),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppTokens.space12),
                    Row(
                      children: [
                        Icon(Icons.error_outline_rounded, size: 18, color: scheme.error),
                        const SizedBox(width: AppTokens.space8),
                        Expanded(
                            child: Text(_error!,
                                style: text.bodySmall?.copyWith(color: scheme.error))),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppTokens.space20),
                  FilledButton(
                    key: const Key('create-account'),
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Create account'),
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
