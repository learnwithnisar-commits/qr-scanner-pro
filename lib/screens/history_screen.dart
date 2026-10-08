import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/scan_record.dart';
import '../services/ad_service.dart';
import '../services/history_service.dart';

/// Searchable scan history with favorites + swipe-to-delete.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _search = TextEditingController();
  bool _onlyFavs = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    if (d.inDays < 30) return '${d.inDays}d ago';
    return '${t.day}/${t.month}/${t.year}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final history = context.watch<HistoryService>();
    final q = _search.text.toLowerCase();
    var items = history.items;
    if (_onlyFavs) items = items.where((e) => e.isFavorite).toList();
    if (q.isNotEmpty) {
      items = items.where((e) => e.content.toLowerCase().contains(q)).toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    hintText: 'Search history…',
                    prefixIcon: Icon(Icons.search_rounded),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: _onlyFavs,
                label: const Text('★'),
                onSelected: (v) => setState(() => _onlyFavs = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? _EmptyState(query: q, onlyFavs: _onlyFavs)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final r = items[i];
                    return Dismissible(
                      key: ValueKey(r.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: scheme.error,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: Colors.white),
                      ),
                      onDismissed: (_) {
                        context.read<HistoryService>().remove(r.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Deleted')),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          leading: _TypeBadge(type: r.type),
                          title: Text(
                            r.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            '${_timeAgo(r.timestamp)}${r.isGenerated ? ' • generated' : ''}',
                            style: TextStyle(
                                fontSize: 12, color: scheme.onSurfaceVariant),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              r.isFavorite
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: r.isFavorite
                                  ? Colors.amber
                                  : scheme.outline,
                            ),
                            onPressed: () => context
                                .read<HistoryService>()
                                .toggleFavorite(r.id),
                          ),
                          onTap: () => _showActions(context, r),
                        ),
                      ),
                    );
                  },
                ),
        ),
        AdService.banner(),
      ],
    );
  }

  void _showActions(BuildContext context, ScanRecord r) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: r.content));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                SharePlus.instance.share(ShareParams(text: r.content));
              },
            ),
            if (r.type == 'url')
              ListTile(
                leading: const Icon(Icons.open_in_new_rounded),
                title: const Text('Open link'),
                onTap: () async {
                  Navigator.pop(context);
                  var url = r.content.trim();
                  if (!url.toLowerCase().startsWith('http')) {
                    url = 'https://$url';
                  }
                  final uri = Uri.tryParse(url);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri,
                        mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Delete'),
              onTap: () {
                context.read<HistoryService>().remove(r.id);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = switch (type) {
      'url' => Icons.link_rounded,
      'wifi' => Icons.wifi_rounded,
      'contact' => Icons.person_rounded,
      _ => Icons.qr_code_2_rounded,
    };
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: scheme.onPrimaryContainer, size: 22),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String query;
  final bool onlyFavs;
  const _EmptyState({required this.query, required this.onlyFavs});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 72, color: scheme.outlineVariant),
          const SizedBox(height: 12),
          Text(
            query.isNotEmpty
                ? 'No matches found'
                : onlyFavs
                    ? 'No favorites yet'
                    : 'No scans yet',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Scan a QR code and it will appear here.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
