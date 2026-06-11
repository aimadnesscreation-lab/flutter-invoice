import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Business Section
          _buildSectionHeader(context, 'Business'),
          _buildSettingTile(
            context,
            icon: Icons.business,
            title: 'Business Settings',
            subtitle: 'Manage your business details',
            onTap: () {},
          ),
          _buildSettingTile(
            context,
            icon: Icons.currency_exchange,
            title: 'Currencies',
            subtitle: 'Manage currencies and exchange rates',
            onTap: () {},
          ),
          _buildSettingTile(
            context,
            icon: Icons.receipt,
            title: 'Tax Rates',
            subtitle: 'GST, VAT, and other tax rates',
            onTap: () {},
          ),
          const SizedBox(height: 24),

          // Invoice Section
          _buildSectionHeader(context, 'Invoices'),
          _buildSettingTile(
            context,
            icon: Icons.receipt_long,
            title: 'Invoice Settings',
            subtitle: 'Default terms, numbering, templates',
            onTap: () {},
          ),
          _buildSettingTile(
            context,
            icon: Icons.style,
            title: 'Invoice Templates',
            subtitle: 'Modern, Classic, Simple',
            onTap: () {},
          ),
          _buildSettingTile(
            context,
            icon: Icons.repeat,
            title: 'Recurring Invoices',
            subtitle: 'Manage auto-generated invoices',
            onTap: () {},
          ),
          const SizedBox(height: 24),

          // Appearance Section
          _buildSectionHeader(context, 'Appearance'),
          _buildSettingTile(
            context,
            icon: Icons.palette,
            title: 'Theme',
            subtitle: 'Light, Dark, or System',
            onTap: () => _showThemeDialog(context),
          ),
          _buildSettingTile(
            context,
            icon: Icons.format_size,
            title: 'Number Format',
            subtitle: 'Set number and date formats',
            onTap: () {},
          ),
          const SizedBox(height: 24),

          // Security Section
          _buildSectionHeader(context, 'Security'),
          _buildSettingTile(
            context,
            icon: Icons.lock,
            title: 'App Lock',
            subtitle: 'PIN, password, or biometric lock',
            onTap: () => context.go('/settings/security'),
          ),
          _buildSettingTile(
            context,
            icon: Icons.timer,
            title: 'Auto Lock',
            subtitle: 'Auto-lock after inactivity',
            onTap: () {},
          ),
          const SizedBox(height: 24),

          // Data Section
          _buildSectionHeader(context, 'Data'),
          _buildSettingTile(
            context,
            icon: Icons.backup,
            title: 'Backup & Restore',
            subtitle: 'Backup or restore your data',
            onTap: () => context.go('/backup'),
          ),
          _buildSettingTile(
            context,
            icon: Icons.delete_sweep,
            title: 'Recycle Bin',
            subtitle: 'View and restore deleted items',
            onTap: () {},
          ),
          _buildSettingTile(
            context,
            icon: Icons.history,
            title: 'Audit Logs',
            subtitle: 'Track all changes made',
            onTap: () {},
          ),
          const SizedBox(height: 24),

          // About
          _buildSectionHeader(context, 'About'),
          _buildSettingTile(
            context,
            icon: Icons.info,
            title: 'About Invoice Pro',
            subtitle: 'Version 1.0.0',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Light'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings_brightness),
              title: const Text('System'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
