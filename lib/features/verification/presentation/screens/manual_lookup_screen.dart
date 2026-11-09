import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../data/verification_repository.dart';

/// Screen allowing authorized staff to manually verify ownership using the 6-digit numeric registration code.
class ManualLookupScreen extends ConsumerStatefulWidget {
  const ManualLookupScreen({super.key});

  @override
  ConsumerState<ManualLookupScreen> createState() => _ManualLookupScreenState();
}

class _ManualLookupScreenState extends ConsumerState<ManualLookupScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;
  int _cooldownRemaining = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_onCodeChanged);
    _checkInitialCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _checkInitialCooldown() {
    final remaining = ref.read(verificationRepositoryProvider).remainingCooldownSeconds;
    if (remaining > 0) {
      _startCooldownTimer(remaining);
    }
  }

  void _startCooldownTimer(int seconds) {
    setState(() {
      _cooldownRemaining = seconds;
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownRemaining <= 1) {
        timer.cancel();
        setState(() {
          _cooldownRemaining = 0;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _cooldownRemaining--;
        });
      }
    });
  }

  void _onCodeChanged() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    } else {
      setState(() {});
    }
  }

  Future<void> _submitLookup() async {
    final code = _codeController.text.trim();
    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() {
        _errorMessage = 'Please enter all 6 numeric digits.';
      });
      return;
    }

    if (_cooldownRemaining > 0 || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final verificationRepo = ref.read(verificationRepositoryProvider);
      final registration = await verificationRepo.lookupByCode(code);

      if (!mounted) return;

      if (registration != null) {
        setState(() {
          _isLoading = false;
        });
        _codeController.clear();
        await context.push('/verification/verify/${registration.id}');
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Registration code "$code" not found. Please verify the 6-digit number printed on the student credential.';
        });
      }
    } on RateLimitException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
      _startCooldownTimer(e.cooldownSeconds);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Verification error: ${e.toString().replaceFirst('Exception: ', '')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentCode = _codeController.text;
    final isReadyToSubmit = currentCode.length == 6 && !_isLoading && _cooldownRemaining == 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Code Lookup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Switch to Scanner',
            onPressed: () => context.pushReplacement(RoutePaths.qrScanner),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.pin_outlined,
                        size: 38,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Enter 6-Digit Registration Code',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Input the six-digit code printed on the official student computer verification credential.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  GestureDetector(
                    onTap: () => _focusNode.requestFocus(),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final availableWidth = constraints.maxWidth;
                        final boxWidth = ((availableWidth - (5 * 8)) / 6).clamp(36.0, 50.0);
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(6, (index) {
                            final hasChar = index < currentCode.length;
                            final isFocused =
                                index == currentCode.length && _focusNode.hasFocus;
                            final char = hasChar ? currentCode[index] : '';

                            return Container(
                              width: boxWidth,
                              height: boxWidth * 1.2,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isFocused
                                      ? colorScheme.primary
                                      : hasChar
                                          ? colorScheme.primary.withValues(alpha: 0.6)
                                          : colorScheme.outlineVariant,
                                  width: isFocused ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                char,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: boxWidth * 0.48,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),

                  // Invisible Native Text Field for Real Soft Keyboard
                  Opacity(
                    opacity: 0.0,
                    child: SizedBox(
                      height: 1,
                      child: TextField(
                        controller: _codeController,
                        focusNode: _focusNode,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submitLookup(),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error / Rate Limit Message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: colorScheme.onErrorContainer,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Cooldown Countdown Banner
                  if (_cooldownRemaining > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        'Security lockout: Retry in $_cooldownRemaining seconds',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Submit Button
                  FilledButton.icon(
                    onPressed: isReadyToSubmit ? _submitLookup : null,
                    icon: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.search_rounded),
                    label: Text(
                      _isLoading ? 'Verifying...' : 'Verify Computer Ownership',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Scanner Option
                  OutlinedButton.icon(
                    onPressed: () => context.pushReplacement(RoutePaths.qrScanner),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Scan QR Code with Camera'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
