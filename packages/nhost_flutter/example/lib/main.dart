// nhost_flutter example app.
// Demonstrates every P1 Flutter Experience API:
//   Nhost.initialize(), NhostAuthGate, NhostAuthStateBuilder,
//   NhostSignedIn/Out, NhostUserBuilder, authStateChanges, authStateListenable
//   sign-in, register, anonymous sign-in, forgot password, change password
import 'package:flutter/material.dart';
import 'package:nhost_flutter/nhost_flutter.dart';

import 'config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Nhost.initialize(
    subdomain: Subdomain(subdomain: subdomain, region: region),
    // SecureAuthStore is used by default — tokens are persisted automatically.
    // For local development, swap the line above with:
    //   await Nhost.local();
  );

  runApp(const NhostExampleApp());
}

class NhostExampleApp extends StatelessWidget {
  const NhostExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return NhostAuthProvider(
      auth: Nhost.instance.auth,
      child: MaterialApp(
        title: 'nhost_flutter example',
        home: NhostAuthGate(
          loading: (_) => const _SplashScreen(),
          signedOut: (_) => const _SignInScreen(),
          signedIn: (_, user, __) => _HomeScreen(user: user),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Splash
// ---------------------------------------------------------------------------

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

// ---------------------------------------------------------------------------
// Sign-in
// ---------------------------------------------------------------------------

class _SignInScreen extends StatefulWidget {
  const _SignInScreen();

  @override
  State<_SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<_SignInScreen> {
  final _email = TextEditingController(text: 'user-1@nhost.io');
  final _password = TextEditingController(text: 'password-1');
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      await Nhost.instance.auth.signInEmailPassword(
        email: _email.text,
        password: _password.text,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed: ${e.responseBody}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInAnonymously() async {
    setState(() => _loading = true);
    try {
      await Nhost.instance.auth.signInAnonymous(null, null, null);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anonymous sign in failed: ${e.responseBody}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToRegister() => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const _RegisterScreen()),
      );

  void _goToForgotPassword() => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const _ForgotPasswordScreen()),
      );

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _goToForgotPassword,
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _signIn,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign in'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.person_outline),
                label: const Text('Continue as guest'),
                onPressed: _loading ? null : _signInAnonymously,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _goToRegister,
              child: const Text("Don't have an account? Register"),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Register
// ---------------------------------------------------------------------------

class _RegisterScreen extends StatefulWidget {
  const _RegisterScreen();

  @override
  State<_RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<_RegisterScreen> {
  final _displayName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    setState(() => _loading = true);
    try {
      await Nhost.instance.auth.signUp(
        email: _email.text,
        password: _password.text,
        displayName: _displayName.text.isEmpty ? null : _displayName.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! Check your email to verify.'),
        ),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: ${e.responseBody}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _displayName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _displayName,
              decoration: const InputDecoration(
                labelText: 'Display name (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create account'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Already have an account? Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Forgot password — sends reset email
// ---------------------------------------------------------------------------

class _ForgotPasswordScreen extends StatefulWidget {
  const _ForgotPasswordScreen();

  @override
  State<_ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<_ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  Future<void> _send() async {
    setState(() => _loading = true);
    try {
      await Nhost.instance.auth.resetPassword(email: _email.text);
      if (!mounted) return;
      setState(() => _sent = true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${e.responseBody}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _sent
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mark_email_read_outlined,
                      size: 64, color: Colors.green),
                  const SizedBox(height: 16),
                  Text(
                    'Password reset email sent to ${_email.text}.\nCheck your inbox.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to sign in'),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Enter your email and we'll send you a link to reset your password.",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _send,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send reset email'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home — demonstrates all P1 widgets
// ---------------------------------------------------------------------------

class _HomeScreen extends StatelessWidget {
  const _HomeScreen({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    final isAnonymous = user.isAnonymous;

    return Scaffold(
      appBar: AppBar(
        title: const Text('nhost_flutter demo'),
        actions: [
          if (isAnonymous)
            TextButton.icon(
              icon: const Icon(Icons.upgrade),
              label: const Text('Upgrade'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const _ConvertAnonymousScreen(),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.lock_outline),
            tooltip: 'Change password',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const _ChangePasswordScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => Nhost.instance.auth.signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isAnonymous)
            _InfoBanner(
              message:
                  'You are signed in as a guest. Upgrade your account to save your data.',
              action: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const _ConvertAnonymousScreen(),
                  ),
                ),
                child: const Text('Upgrade now'),
              ),
            ),
          _Section(
            title: 'NhostUserBuilder',
            child: NhostUserBuilder(
              builder: (_, u) => Text(
                'Hello, ${u.displayName.isNotEmpty ? u.displayName : (u.email ?? 'guest')}!',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          _Section(
            title: 'NhostSignedIn / NhostSignedOut',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NhostSignedIn(
                  child: Chip(
                    avatar: const Icon(Icons.check_circle, color: Colors.green),
                    label: const Text('Signed in'),
                  ),
                ),
                NhostSignedOut(
                  child: Chip(
                    avatar: const Icon(Icons.cancel, color: Colors.red),
                    label: const Text('Signed out'),
                  ),
                ),
              ],
            ),
          ),
          _Section(
            title: 'NhostAuthStateBuilder (sealed switch)',
            child: NhostAuthStateBuilder(
              builder: (_, state) => switch (state) {
                AuthStateLoading() => const Text('Loading…'),
                AuthStateSignedOut() => const Text('Not signed in'),
                AuthStateSignedIn(:final user) =>
                  Text('Signed in as ${user.email ?? 'guest'}'),
              },
            ),
          ),
          _Section(
            title: 'authStateChanges stream',
            child: StreamBuilder<AuthState>(
              stream: Nhost.instance.auth.authStateChanges,
              builder: (_, snap) {
                final state = snap.data;
                return Text(switch (state) {
                  null => 'Waiting for first event…',
                  AuthStateLoading() => 'Loading…',
                  AuthStateSignedOut() => 'Stream: signed out',
                  AuthStateSignedIn(:final user) =>
                    'Stream: signed in as ${user.email ?? 'guest'}',
                });
              },
            ),
          ),
          _Section(
            title: 'authStateListenable',
            child: ValueListenableBuilder<AuthState>(
              valueListenable: Nhost.instance.auth.authStateListenable,
              builder: (_, state, __) => Text(switch (state) {
                AuthStateLoading() => 'Listenable: loading…',
                AuthStateSignedOut() => 'Listenable: signed out',
                AuthStateSignedIn(:final user) =>
                  'Listenable: signed in as ${user.email ?? 'guest'}',
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Convert anonymous account → full account
// ---------------------------------------------------------------------------

class _ConvertAnonymousScreen extends StatefulWidget {
  const _ConvertAnonymousScreen();

  @override
  State<_ConvertAnonymousScreen> createState() =>
      _ConvertAnonymousScreenState();
}

class _ConvertAnonymousScreenState extends State<_ConvertAnonymousScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  Future<void> _convert() async {
    setState(() => _loading = true);
    try {
      await Nhost.instance.auth.deanonymizeUser(
        DeanonymizeOptions(
          signInMethod: DeanonymizeSignInMethod.emailPassword,
          email: _email.text,
          password: _password.text,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account upgraded! Check your email.')),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upgrade failed: ${e.responseBody}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade account')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Convert your guest account to a permanent account.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _convert,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Upgrade account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Change password (for logged-in users)
// ---------------------------------------------------------------------------

class _ChangePasswordScreen extends StatefulWidget {
  const _ChangePasswordScreen();

  @override
  State<_ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<_ChangePasswordScreen> {
  final _newPassword = TextEditingController();
  bool _loading = false;

  Future<void> _changePassword() async {
    setState(() => _loading = true);
    try {
      await Nhost.instance.auth.changePassword(
        newPassword: _newPassword.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully.')),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${e.responseBody}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _newPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _newPassword,
              decoration: const InputDecoration(
                labelText: 'New password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _changePassword,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Change password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message, required this.action});
  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
          action,
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Colors.grey)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
