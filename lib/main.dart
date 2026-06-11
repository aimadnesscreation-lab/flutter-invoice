import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_pro/core/di/injection_container.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/core/router/app_router.dart';
import 'package:invoice_pro/services/security_service.dart';
import 'package:invoice_pro/themes/app_theme.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();

  final container = ProviderContainer();
  await container.read(activeBusinessProvider.notifier).loadActiveBusiness();

  // Load saved theme mode
  final securityService = container.read<SecurityService>(securityServiceProvider);
  final savedTheme = await securityService.getThemeMode();
  container.read(themeModeProvider.notifier).state = AppTheme.getThemeMode(savedTheme);

  runApp(UncontrolledProviderScope(container: container, child: const InvoiceProApp()));
}

class InvoiceProApp extends ConsumerWidget {
  const InvoiceProApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Invoice Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
