import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_pro/services/security_service.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/core/di/injection_container.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePin = true;
  late Future<bool> _biometricEnabledFuture;

  @override
  void initState() {
    super.initState();
    _biometricEnabledFuture = sl<SecurityService>().isBiometricEnabled();
    _tryBiometricAuth();
  }

  Future<void> _tryBiometricAuth() async {
    final securityService = sl<SecurityService>();
    final isEnabled = await securityService.isBiometricEnabled();
    if (isEnabled) {
      final authenticated = await securityService.authenticateWithBiometrics();
      if (authenticated && mounted) {
        ref.read(authProvider.notifier).unlock();
      }
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final securityService = sl<SecurityService>();
    final isValid = await securityService.verifyPinCode(_pinController.text);

    if (!mounted) return;

    if (isValid) {
      ref.read(authProvider.notifier).unlock();
    } else {
      setState(() {
        _errorMessage = 'Wrong PIN. Please try again.';
        _isLoading = false;
      });
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 80,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'App Locked',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your PIN to unlock',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _pinController,
                    obscureText: _obscurePin,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      letterSpacing: 12,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'Enter PIN',
                      prefixIcon: const Icon(Icons.pin),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePin ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _obscurePin = !_obscurePin);
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your PIN';
                      }
                      if (value.trim().length < 4) {
                        return 'PIN must be at least 4 digits';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _verifyPin(),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.error.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.error.withAlpha(60),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _errorMessage!,
                            style: TextStyle(color: colorScheme.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyPin,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Unlock'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<bool>(
                    future: _biometricEnabledFuture,
                    builder: (context, snapshot) {
                      if (snapshot.data != true) return const SizedBox();
                      return TextButton.icon(
                        onPressed: _tryBiometricAuth,
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('Use Fingerprint'),
                      );
                    },
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
