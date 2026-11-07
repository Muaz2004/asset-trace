import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/routing/route_paths.dart';
import '../../data/verification_repository.dart';

/// Screen performing real camera-based QR code scanning and backend lookup for computer ownership verification.
class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _scannerController;
  bool _isProcessing = false;
  bool _isTorchOn = false;
  String? _lookupStatusMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      returnImage: false,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_scannerController.value.isInitialized) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _scannerController.stop();
    } else if (state == AppLifecycleState.resumed && !_isProcessing) {
      _scannerController.start();
    }
  }

  Future<void> _handleBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final scannedValue = barcodes.first.rawValue?.trim();
    if (scannedValue == null || scannedValue.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _lookupStatusMessage = 'Verifying QR pass in university database...';
    });

    try {
      final verificationRepo = ref.read(verificationRepositoryProvider);
      final registration = await verificationRepo.lookupByQr(scannedValue);

      if (!mounted) return;

      if (registration != null) {
        // Valid registration record found - navigate to physical ownership inspection screen
        setState(() {
          _isProcessing = false;
          _lookupStatusMessage = null;
        });

        await context.push('/verification/verify/${registration.id}');

        // Resume scanner upon returning from verification screen
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      } else {
        // Scanned code does not correspond to an active registered computer
        setState(() {
          _lookupStatusMessage = null;
        });

        if (!mounted) return;
        await _showUnknownQrDialog(scannedValue);

        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _lookupStatusMessage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lookup error: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _showUnknownQrDialog(String scannedData) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.search_off_rounded, size: 48, color: Colors.orange),
        title: const Text('Unrecognized QR Pass'),
        content: const Text(
          'No active university computer registration matches this QR credential. The computer may not be registered, or the QR code may belong to an external system.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.push(RoutePaths.manualLookup);
            },
            child: const Text('Try 6-Digit Code'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Scan Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Ownership QR'),
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded),
            tooltip: 'Toggle Flashlight',
            onPressed: () async {
              await _scannerController.toggleTorch();
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded),
            tooltip: 'Switch Camera',
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Live camera preview with MobileScanner
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcodeDetected,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.videocam_off_rounded,
                        size: 56,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Camera Unavailable',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Unable to initialize camera. Please grant camera permission in system settings.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () => context.push(RoutePaths.manualLookup),
                        icon: const Icon(Icons.pin_outlined),
                        label: const Text('Use 6-Digit Code Instead'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Viewfinder Overlay Reticle
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ScannerOverlayPainter(
                  borderColor: colorScheme.primary,
                  overlayColor: Colors.black.withValues(alpha: 0.55),
                  scanBoxSize: 260,
                  borderRadius: 16,
                ),
              ),
            ),
          ),

          // Top Instruction Banner
          Positioned(
            top: 24,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: const Text(
                'Point camera at the computer ownership QR pass',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Loading/Lookup Indicator Overlay
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.65),
                child: Center(
                  child: Card(
                    color: colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            _lookupStatusMessage ?? 'Searching database...',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Bottom Manual Code Option Bar
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () => context.push(RoutePaths.manualLookup),
                icon: const Icon(Icons.dialpad_rounded, size: 20),
                label: const Text('Enter 6-Digit Code Manually'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for semi-transparent camera scan window with rounded corners.
class _ScannerOverlayPainter extends CustomPainter {
  const _ScannerOverlayPainter({
    required this.borderColor,
    required this.overlayColor,
    required this.scanBoxSize,
    required this.borderRadius,
  });

  final Color borderColor;
  final Color overlayColor;
  final double scanBoxSize;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = overlayColor;
    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final left = (size.width - scanBoxSize) / 2;
    final top = (size.height - scanBoxSize) / 2.4;
    final rect = Rect.fromLTWH(left, top, scanBoxSize, scanBoxSize);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Draw dark mask with cut-out hole
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()..addRRect(rrect);
    final combinedPath = Path.combine(PathOperation.difference, backgroundPath, holePath);
    canvas.drawPath(combinedPath, backgroundPaint);

    // Draw viewfinder border
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
