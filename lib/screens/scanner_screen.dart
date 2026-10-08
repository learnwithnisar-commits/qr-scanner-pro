import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

import '../models/scan_record.dart';
import '../services/ad_service.dart';
import '../services/history_service.dart';
import '../services/settings_service.dart';
import '../widgets/scan_overlay.dart';
import 'result_sheet.dart';

/// Full-screen premium scanner with animated overlay.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  bool _torchOn = false;
  bool _handling = false;
  bool _noPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      _controller.start();
    } else if (state == AppLifecycleState.paused) {
      _controller.stop();
    }
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final result = await Permission.camera.request();
      if (!result.isGranted && mounted) {
        setState(() => _noPermission = true);
      }
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    await _processRaw(raw);
  }

  /// Shared scan pipeline: feedback -> history -> stop camera ->
  /// result sheet -> interstitial policy -> resume camera.
  Future<void> _processRaw(String raw) async {
    if (_handling) return;
    _handling = true;
    try {
      final settings = context.read<SettingsService>();
      final history = context.read<HistoryService>();
      final ads = context.read<AdService>();

      if (settings.vibrate) {
        if (await Vibration.hasVibrator()) {
          Vibration.vibrate(duration: 60);
        } else {
          HapticFeedback.mediumImpact();
        }
      }
      if (settings.beep) {
        SystemSound.play(SystemSoundType.click);
      }

      final record = ScanRecord(
        id: ScanRecord.newId(),
        content: raw,
        type: ScanRecord.classify(raw),
        timestamp: DateTime.now(),
      );
      await history.add(record);
      await _controller.stop();
      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ResultSheet(record: record),
      );
      // Count a result-close for the interstitial policy.
      await ads.onResultClosed();
      if (mounted) await _controller.start();
    } finally {
      _handling = false;
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    try {
      // mobile_scanner v7: analyzeImage returns the BarcodeCapture directly.
      final capture = await _controller.analyzeImage(file.path);
      final raw = capture?.barcodes.firstOrNull?.rawValue;
      if (raw == null || raw.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No QR code found in that image.')),
          );
        }
        return;
      }
      await _processRaw(raw);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read that image.')),
        );
      }
    }
  }

  void _toggleTorch() {
    setState(() => _torchOn = !_torchOn);
    _controller.toggleTorch();
  }

  void _switchCamera() => _controller.switchCamera();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_noPermission) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.no_photography_outlined,
                  size: 72, color: scheme.outline),
              const SizedBox(height: 16),
              const Text(
                'Camera access needed',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Allow camera access in Settings to scan QR codes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: openAppSettings,
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
        ),
        const ScanOverlay(),
        // Top hint.
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                'Align a QR code inside the frame',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ),
        // Bottom controls + banner ad.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CircleBtn(
                    icon: _torchOn ? Icons.flash_on : Icons.flash_off,
                    label: 'Flash',
                    active: _torchOn,
                    onTap: _toggleTorch,
                  ),
                  const SizedBox(width: 28),
                  _CircleBtn(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                    onTap: _pickFromGallery,
                  ),
                  const SizedBox(width: 28),
                  _CircleBtn(
                    icon: Icons.cameraswitch_outlined,
                    label: 'Flip',
                    onTap: _switchCamera,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AdService.banner(),
            ],
          ),
        ),
      ],
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _CircleBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: active
              ? scheme.secondary
              : Colors.black.withValues(alpha: 0.55),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    );
  }
}
