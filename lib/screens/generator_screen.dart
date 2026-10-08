import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../models/scan_record.dart';
import '../services/history_service.dart';

/// Create beautiful, customizable QR codes.
class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  final _tabs = ['Text', 'Link', 'Wi-Fi', 'Contact'];
  int _tab = 0;

  final _textCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _ssidCtrl = TextEditingController();
  final _wifiPassCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  Color _fg = const Color(0xFF1A1A2E);
  Color _bg = Colors.white;
  final _boundaryKey = GlobalKey();

  final _swatches = const [
    Color(0xFF1A1A2E),
    Color(0xFF4F46E5),
    Color(0xFF0EA5E9),
    Color(0xFF14B8A6),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFFEC4899),
    Color(0xFF000000),
  ];

  @override
  void dispose() {
    for (final c in [
      _textCtrl,
      _linkCtrl,
      _ssidCtrl,
      _wifiPassCtrl,
      _nameCtrl,
      _phoneCtrl,
      _emailCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _payload {
    switch (_tab) {
      case 1:
        var u = _linkCtrl.text.trim();
        if (u.isNotEmpty && !u.toLowerCase().startsWith('http')) {
          u = 'https://$u';
        }
        return u;
      case 2:
        final s = _ssidCtrl.text.trim();
        final p = _wifiPassCtrl.text;
        if (s.isEmpty) return '';
        return 'WIFI:T:WPA;S:$s;P:$p;;';
      case 3:
        final n = _nameCtrl.text.trim();
        final ph = _phoneCtrl.text.trim();
        final em = _emailCtrl.text.trim();
        if (n.isEmpty && ph.isEmpty && em.isEmpty) return '';
        return 'BEGIN:VCARD\nVERSION:3.0\nN:$n\nTEL:$ph\nEMAIL:$em\nEND:VCARD';
      default:
        return _textCtrl.text.trim();
    }
  }

  Future<void> _saveToHistory(String payload) async {
    await context.read<HistoryService>().add(ScanRecord(
          id: ScanRecord.newId(),
          content: payload,
          type: ScanRecord.classify(payload),
          timestamp: DateTime.now(),
          isGenerated: true,
        ));
  }

  Future<void> _sharePng() async {
    final payload = _payload;
    if (payload.isEmpty) return;
    try {
      final boundary = _boundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 4);
      final bytes =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/qr_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'QR code'));
      await _saveToHistory(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to history')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final payload = _payload;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SegmentedButton<int>(
          segments: [
            for (var i = 0; i < _tabs.length; i++)
              ButtonSegment(value: i, label: Text(_tabs[i])),
          ],
          selected: {_tab},
          onSelectionChanged: (s) => setState(() => _tab = s.first),
        ),
        const SizedBox(height: 20),
        _buildInputs(),
        const SizedBox(height: 24),
        // Live preview.
        Center(
          child: RepaintBoundary(
            key: _boundaryKey,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.25),
                    blurRadius: 32,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: payload.isEmpty
                  ? SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(
                        child: Icon(Icons.qr_code_2_rounded,
                            size: 96, color: scheme.outlineVariant),
                      ),
                    )
                  : QrImageView(
                      data: payload,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.transparent,
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: _fg,
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: _fg,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Code color',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: scheme.onSurface)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: [
            for (final c in _swatches)
              GestureDetector(
                onTap: () => setState(() => _fg = c),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _fg == c ? scheme.primary : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6)
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Background',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: scheme.onSurface)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: [
            for (final c in [Colors.white, const Color(0xFF0B0E1A)])
              GestureDetector(
                onTap: () => setState(() => _bg = c),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _bg == c ? scheme.primary : scheme.outlineVariant,
                      width: 3,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: payload.isEmpty ? null : _sharePng,
          icon: const Icon(Icons.share_rounded),
          label: const Text('Share / Export PNG',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56)),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildInputs() {
    switch (_tab) {
      case 1:
        return TextField(
          controller: _linkCtrl,
          decoration: const InputDecoration(
            labelText: 'Website URL',
            hintText: 'example.com',
            prefixIcon: Icon(Icons.link_rounded),
          ),
          keyboardType: TextInputType.url,
          onChanged: (_) => setState(() {}),
        );
      case 2:
        return Column(
          children: [
            TextField(
              controller: _ssidCtrl,
              decoration: const InputDecoration(
                labelText: 'Wi-Fi network name (SSID)',
                prefixIcon: Icon(Icons.wifi_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _wifiPassCtrl,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        );
      case 3:
        return Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => setState(() {}),
            ),
          ],
        );
      default:
        return TextField(
          controller: _textCtrl,
          decoration: const InputDecoration(
            labelText: 'Text',
            hintText: 'Type anything…',
            prefixIcon: Icon(Icons.text_fields_rounded),
          ),
          maxLines: 3,
          onChanged: (_) => setState(() {}),
        );
    }
  }
}
