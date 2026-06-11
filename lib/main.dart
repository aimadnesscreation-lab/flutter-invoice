import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_pro/core/di/injection_container.dart';
import 'package:invoice_pro/core/di/providers.dart';
import 'package:invoice_pro/core/router/app_router.dart';
import 'package:invoice_pro/themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  
  final container = ProviderContainer();
  await container.read(activeBusinessProvider.notifier).loadActiveBusiness();
  
  runApp(UncontrolledProviderScope(container: container, child: const InvoiceProApp()));
}

class InvoiceProApp extends ConsumerWidget {
  const InvoiceProApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Invoice Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
