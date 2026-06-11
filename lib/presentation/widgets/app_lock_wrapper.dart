import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/services/security_service.dart';
import 'package:invoice_pro/core/di/injection_container.dart';

/// Wraps the app and handles auto-lock when the app returns from background.
/// Listens to [WidgetsBindingObserver] to detect app lifecycle changes
/// and triggers the lock state based on the configured auto-lock duration.
class AppLockWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const AppLockWrapper({super.key, required this.child});

  @override
  ConsumerState<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends ConsumerState<AppLockWrapper>
    with WidgetsBindingObserver {
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialLockState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkInitialLockState() async {
    final securityService = sl<SecurityService>();
    final hasPin = await securityService.hasPinCode();
    if (hasPin && mounted) {
      ref.read(authProvider.notifier).lock();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _checkAutoLock();
    }
  }

  Future<void> _checkAutoLock() async {
    if (_backgroundedAt == null) return;

    final securityService = sl<SecurityService>();
    final hasPin = await securityService.hasPinCode();
    if (!hasPin) return;

    final autoLockMinutes = await securityService.getAutoLockDuration();
    final elapsed = DateTime.now().difference(_backgroundedAt!).inMinutes;

    if (elapsed >= autoLockMinutes && mounted) {
      ref.read(authProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
