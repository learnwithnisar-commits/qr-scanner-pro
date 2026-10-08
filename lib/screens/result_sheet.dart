import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/scan_record.dart';
import '../services/history_service.dart';

/// Bottom sheet shown after a successful scan — with smart actions.
class ResultSheet extends StatelessWidget {
  final ScanRecord record;
  const ResultSheet({super.key, required this.record});

  String get _typeLabel => switch (record.type) {
        'url' => 'Website link',
        'wifi' => 'Wi-Fi network',
        'contact' => 'Contact card',
        _ => record.isGenerated ? 'Generated code' : 'Text',
      };

  IconData get _typeIcon => switch (record.type) {
        'url' => Icons.link_rounded,
        'wifi' => Icons.wifi_rounded,
        'contact' => Icons.person_rounded,
        _ => Icons.text_fields_rounded,
      };

  Future<void> _openUrl(BuildContext context, String raw) async {
    var url = raw.trim();
    if (!url.toLowerCase().startsWith('http')) url = 'https://$url';
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this link.')),
      );
    }
  }

  Map<String, String> _parseWifi(String raw) {
    // WIFI:T:WPA;S:MyNetwork;P:secret;;
    final out = <String, String>{};
    final body = raw.substring(5).split(';');
    for (final part in body) {
      final kv = part.split(':');
      if (kv.length >= 2) out[kv[0]] = kv.sublist(1).join(':');
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isFav =
        context.watch<HistoryService>().items.any((e) => e.id == record.id && e.isFavorite);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_typeIcon, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Scan result',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    Text(_typeLabel,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: scheme.primary)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isFav ? Colors.amber : scheme.outline),
                onPressed: () =>
                    context.read<HistoryService>().toggleFavorite(record.id),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: SelectableText(
              record.content,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ),
          if (record.type == 'wifi') ...[
            const SizedBox(height: 12),
            _WifiInfo(raw: record.content, parse: _parseWifi),
          ],
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (record.type == 'url')
                FilledButton.icon(
                  onPressed: () => _openUrl(context, record.content),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open link'),
                ),
              FilledButton.tonalIcon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: record.content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => SharePlus.instance
                    .share(ShareParams(text: record.content)),
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share'),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Done'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WifiInfo extends StatelessWidget {
  final String raw;
  final Map<String, String> Function(String) parse;
  const _WifiInfo({required this.raw, required this.parse});

  @override
  Widget build(BuildContext context) {
    final info = parse(raw);
    final ssid = info['S'] ?? '—';
    final pass = info['P'] ?? '';
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.wifi_rounded, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('Network: $ssid')),
            ],
          ),
          if (pass.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.lock_outline_rounded, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Password: $pass')),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: pass));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Wi-Fi password copied')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Tip: open your Wi-Fi settings and join "$ssid" with the password above.',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
