import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/history_service.dart';
import '../services/settings_service.dart';

/// Settings: theme, haptics, sound, about, privacy, rate.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _playUrl =
      'https://play.google.com/store/apps/details?id=com.nisarahmedkatyar.qrscannerpro';

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionTitle('Appearance'),
        Card(
          child: RadioGroup<String>(
            groupValue: settings.themeMode,
            onChanged: (v) =>
                context.read<SettingsService>().setThemeMode(v!),
            child: Column(
              children: [
                for (final (value, label, icon) in [
                  ('system', 'Follow system', Icons.settings_suggest_outlined),
                  ('light', 'Light', Icons.light_mode_outlined),
                  ('dark', 'Dark', Icons.dark_mode_outlined),
                ])
                  RadioListTile<String>(
                    value: value,
                    title: Text(label),
                    secondary: Icon(icon),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _SectionTitle('Scanner feedback'),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: settings.vibrate,
                onChanged: (v) =>
                    context.read<SettingsService>().setVibrate(v),
                title: const Text('Vibrate on scan'),
                secondary: const Icon(Icons.vibration_outlined),
              ),
              SwitchListTile(
                value: settings.beep,
                onChanged: (v) =>
                    context.read<SettingsService>().setBeep(v),
                title: const Text('Sound on scan'),
                secondary: const Icon(Icons.volume_up_outlined),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _SectionTitle('Data'),
        Card(
          child: ListTile(
            leading: const Icon(Icons.delete_sweep_outlined),
            title: const Text('Clear history'),
            subtitle: const Text('Remove all scans and generated codes'),
            onTap: () => _confirmClear(context),
          ),
        ),
        const SizedBox(height: 8),
        _SectionTitle('About'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: const Text('Developer'),
                subtitle: const Text('Engr. Nisar Ahmed Katyar'),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy policy'),
                trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.star_outline_rounded),
                title: const Text('Rate this app'),
                subtitle: const Text('Your rating helps a lot!'),
                trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                onTap: () => _open(_playUrl, context),
              ),
              const ListTile(
                leading: Icon(Icons.info_outline_rounded),
                title: Text('Version'),
                subtitle: Text('1.0.0'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Made with care by Engr. Nisar Ahmed Katyar',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Future<void> _open(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link.')),
      );
    }
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text(
            'All scanned and generated codes will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<HistoryService>().clear();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('History cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// In-app privacy policy (also host this text at a public URL for the
/// Play Console "Privacy policy" listing field).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _text = '''
Privacy Policy — QR Scanner Pro
Last updated: October 8, 2026
Developer: Engr. Nisar Ahmed Katyar

1. NO DATA COLLECTED
QR Scanner Pro does not collect, store, transmit, or share any personal
data. There is no account system, no analytics SDK, and no tracking.

2. CAMERA
The camera is used solely on your device to scan QR codes and barcodes
in real time. Camera frames are processed locally by the on-device
scanner and are never recorded, uploaded, or shared.

3. PHOTOS / GALLERY
If you choose "scan from gallery", the image you pick is analyzed
on-device to find a QR code. The image never leaves your phone.

4. HISTORY
Your scan and generator history is stored only on your own device.
You can delete individual entries or clear all history at any time
from Settings. Uninstalling the app removes it permanently.

5. ADVERTISING (AdMob)
This app shows ads provided by Google AdMob. Google may collect and use
data as described in Google's Privacy Policy
(https://policies.google.com/privacy) and Google's publisher policies.
You can opt out of personalized ads in your device's Google settings.

6. PERMISSIONS USED
• Camera — QR/barcode scanning only.
• Vibration — haptic feedback on scan (can be disabled in Settings).

7. CHILDREN
The app is a general utility and is not directed at children under 13.
No data is collected from anyone, including children.

8. CHANGES
If this policy changes, the updated version will be published inside
the app and at the Play Store listing.

9. CONTACT
For privacy questions, contact: engr.nisarahmedkatyar@gmail.com
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: SelectableText(_text, style: TextStyle(fontSize: 14, height: 1.6)),
      ),
    );
  }
}
