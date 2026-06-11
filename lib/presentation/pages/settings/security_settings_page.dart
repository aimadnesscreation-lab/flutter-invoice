import 'package:flutter/material.dart';
import 'package:invoice_pro/services/security_service.dart';
import 'package:invoice_pro/core/di/injection_container.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  final _securityService = sl<SecurityService>();
  bool _hasPin = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  int _autoLockMinutes = 5;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final hasPin = await _securityService.hasPinCode();
    final bioAvailable = await _securityService.isBiometricAvailable();
    final bioEnabled = await _securityService.isBiometricEnabled();
    final autoLock = await _securityService.getAutoLockDuration();
    setState(() {
      _hasPin = hasPin;
      _biometricAvailable = bioAvailable;
      _biometricEnabled = bioEnabled;
      _autoLockMinutes = autoLock;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Security Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // PIN Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PIN Code', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (_hasPin)
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('PIN code is set')),
                        TextButton(
                          onPressed: _changePin,
                          child: const Text('Change'),
                        ),
                        TextButton(
                          onPressed: _removePin,
                          child: const Text('Remove', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _setPin,
                        icon: const Icon(Icons.lock),
                        label: const Text('Set PIN Code'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Biometric Section
          if (_biometricAvailable)
            Card(
              child: SwitchListTile(
                title: const Text('Biometric Authentication'),
                subtitle: const Text('Use fingerprint or face to unlock'),
                value: _biometricEnabled,
                onChanged: (value) async {
                  if (value) {
                    final authenticated = await _securityService.authenticateWithBiometrics();
                    if (authenticated) {
                      await _securityService.setBiometricEnabled(true);
                      setState(() => _biometricEnabled = true);
                    }
                  } else {
                    await _securityService.setBiometricEnabled(false);
                    setState(() => _biometricEnabled = false);
                  }
                },
                secondary: const Icon(Icons.fingerprint),
              ),
            ),
          if (_biometricAvailable) const SizedBox(height: 16),

          // Auto Lock Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Auto Lock', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Lock the app after inactivity', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _autoLockMinutes,
                    decoration: const InputDecoration(labelText: 'Auto Lock Duration', prefixIcon: Icon(Icons.timer)),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 minute')),
                      DropdownMenuItem(value: 5, child: Text('5 minutes')),
                      DropdownMenuItem(value: 15, child: Text('15 minutes')),
                      DropdownMenuItem(value: 30, child: Text('30 minutes')),
                      DropdownMenuItem(value: 60, child: Text('1 hour')),
                    ],
                    onChanged: (value) async {
                      if (value != null) {
                        await _securityService.setAutoLockDuration(value);
                        setState(() => _autoLockMinutes = value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setPin() async {
    final pin = await _showPinDialog('Set PIN Code', isNew: true);
    if (pin != null) {
      final confirm = await _showPinDialog('Confirm PIN Code', isNew: false);
      if (confirm == pin) {
        await _securityService.setPinCode(pin);
        setState(() => _hasPin = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN code set successfully')),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PINs do not match'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _changePin() async {
    final oldPin = await _showPinDialog('Enter Current PIN', isNew: false);
    if (oldPin != null) {
      final verified = await _securityService.verifyPinCode(oldPin);
      if (verified) {
        final newPin = await _showPinDialog('Enter New PIN', isNew: true);
        if (newPin != null) {
          final confirm = await _showPinDialog('Confirm New PIN', isNew: false);
          if (confirm == newPin) {
            await _securityService.setPinCode(newPin);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PIN changed successfully')),
              );
            }
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PINs do not match'), backgroundColor: Colors.red),
            );
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wrong PIN'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removePin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove PIN'),
        content: const Text('Are you sure you want to remove the PIN code?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await _securityService.removePinCode();
      setState(() => _hasPin = false);
    }
  }

  Future<String?> _showPinDialog(String title, {required bool isNew}) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: isNew ? 'Enter PIN' : 'Enter current PIN',
            prefixIcon: const Icon(Icons.lock),
          ),
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.length >= 4) {
                Navigator.pop(context, controller.text);
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
