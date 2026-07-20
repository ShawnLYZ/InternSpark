import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internspark_core/internspark_core.dart';
import 'student_shell.dart' show studentProfileProvider;
import 'wizard_cards.dart';

/// True when the signed-in student must be in the wizard: no student_profiles
/// row yet (fresh signup), or a resumable in-flight verification session.
final needsVerificationProvider = FutureProvider<bool>((ref) async {
  final sp = await ref.watch(studentRepositoryProvider).fetchMyStudentProfile();
  if (sp == null) return true;
  return ref.watch(verificationRepositoryProvider).hasActiveSession();
});

/// The agent console: one scrolling timeline rendering the session's
/// persisted log, with one interactive card at the current step. Resume is
/// just re-rendering the same log from the server.
class VerificationWizardScreen extends ConsumerStatefulWidget {
  const VerificationWizardScreen({super.key, this.pickCert});

  /// Test seam for the OS file picker (wired in the certificate task).
  final Future<PickedCert?> Function()? pickCert;

  @override
  ConsumerState<VerificationWizardScreen> createState() => _VerificationWizardScreenState();
}

class _VerificationWizardScreenState extends ConsumerState<VerificationWizardScreen> {
  VerificationSession? _session;
  Object? _loadError;
  bool _busy = false;
  final List<Certification> _certs = [];
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      final s = await ref.read(verificationRepositoryProvider).startOrResume();
      if (mounted) setState(() => _session = s);
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  Future<void> _run(Future<VerificationSession> Function() op) async {
    setState(() => _busy = true);
    try {
      final s = await op();
      if (mounted) setState(() => _session = s);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish() async {
    await _run(() => ref.read(verificationRepositoryProvider).complete(_session!.id));
    ref.invalidate(needsVerificationProvider);
    ref.invalidate(studentProfileProvider);
    if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  Future<PickedCert?> _realPick() async {
    // file_picker 11.x made `FilePicker` a static-only API (no more
    // instance-based `.platform` accessor) — call the static method directly.
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true,
    );
    final f = result?.files.singleOrNull;
    if (f == null || f.bytes == null) return null;
    return (bytes: f.bytes!, name: f.name);
  }

  Future<void> _uploadCertificate() async {
    final picked = await (widget.pickCert ?? _realPick)();
    if (picked == null) return;
    setState(() => _busy = true);
    try {
      final res = await ref.read(verificationRepositoryProvider).uploadCertificate(
          sessionId: _session!.id, bytes: picked.bytes, filename: picked.name);
      if (mounted) {
        setState(() {
          _session = res.session;
          _certs.add(res.certification);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _session;
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your skills'), automaticallyImplyLeading: false),
      body: _loadError != null
          ? AppError(
              message: 'Could not start verification: $_loadError',
              onRetry: () {
                setState(() => _loadError = null);
                _start();
              },
            )
          : s == null
              ? const AppLoading()
              : ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.all(AppTokens.space16),
                  children: [
                    for (final e in s.log) LogEntryTile(entry: e),
                    _stepCard(s),
                    const SizedBox(height: AppTokens.space24),
                  ],
                ),
    );
  }

  Widget _stepCard(VerificationSession s) {
    final repo = ref.read(verificationRepositoryProvider);
    final profile = ref.watch(studentProfileProvider).value;
    switch (s.step) {
      case VerificationStep.collectInput:
        return ProgramFormCard(
          busy: _busy,
          initial: profile,
          onSubmit: (universityId, course, year, semester) => _run(() => repo.submitInput(
              sessionId: s.id, universityId: universityId, course: course, year: year, semester: semester)),
        );
      case VerificationStep.confirmProgram:
        return ConfirmProgramCard(
          busy: _busy,
          candidates: s.findings.candidates,
          onDecide: (programId, accept) =>
              _run(() => repo.confirmProgram(sessionId: s.id, programId: programId, accept: accept)),
        );
      case VerificationStep.certificates:
        return SkillsSplitCard(
          busy: _busy,
          findings: s.findings,
          certifications: _certs,
          onUpload: _uploadCertificate,
          onDone: () => _run(() => repo.certificatesDone(s.id)),
        );
      case VerificationStep.preferences:
        return PreferencesCard(
          busy: _busy,
          initial: profile,
          onSave: ({
            required growthStatement,
            availabilityStart,
            durationWeeks,
            remotePref,
            salaryExpectation,
            required roleInterests,
            required industryInterests,
          }) =>
              _run(() => repo.savePreferences(
                    sessionId: s.id,
                    growthStatement: growthStatement,
                    availabilityStart: availabilityStart,
                    durationWeeks: durationWeeks,
                    remotePref: remotePref,
                    salaryExpectation: salaryExpectation,
                    roleInterests: roleInterests,
                    industryInterests: industryInterests,
                  )),
        );
      case VerificationStep.summary:
        return SummaryCard(busy: _busy, findings: s.findings, certifications: _certs, onFinish: _finish);
      case VerificationStep.completed:
        return const SizedBox.shrink();
    }
  }
}
