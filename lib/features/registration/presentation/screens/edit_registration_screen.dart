import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/registration_repository.dart';
import '../../domain/registration.dart';

/// Screen allowing authorized staff (Administrators and Registration Officers) to edit permitted
/// registration information with strict audit logging.
class EditRegistrationScreen extends ConsumerStatefulWidget {
  const EditRegistrationScreen({super.key, required this.registrationId});

  final String registrationId;

  @override
  ConsumerState<EditRegistrationScreen> createState() =>
      _EditRegistrationScreenState();
}

class _EditRegistrationScreenState
    extends ConsumerState<EditRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _brandController;
  late TextEditingController _modelController;

  bool _initialized = false;
  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _brandController = TextEditingController();
    _modelController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _populateFields(Registration reg) {
    if (_initialized) return;
    _nameController.text = reg.studentName;
    _phoneController.text = reg.phoneNumber;
    _brandController.text = reg.pcBrand;
    _modelController.text = reg.pcModel;
    _initialized = true;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = ref.read(appAuthStateProvider).profile;
    if (profile == null) {
      setState(() => _saveError = 'Authorized staff profile not active.');
      return;
    }

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final repo = ref.read(registrationRepositoryProvider);
      await repo.updateRegistrationDetails(
        registrationId: widget.registrationId,
        studentName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        pcBrand: _brandController.text.trim(),
        pcModel: _modelController.text.trim(),
        updatedBy: profile.uid,
        updatedByName: profile.name,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration information updated successfully.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = 'Failed to update registration: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final registrationStream = ref
        .watch(registrationRepositoryProvider)
        .watchRegistration(widget.registrationId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Registration Details'),
      ),
      body: StreamBuilder<Registration?>(
        stream: registrationStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !_initialized) {
            return const AppLoadingIndicator(
              message: 'Loading registration record...',
            );
          }

          if (snapshot.hasError) {
            return AppErrorView(
              message: 'Failed to load record: ${snapshot.error}',
            );
          }

          final reg = snapshot.data;
          if (reg == null) {
            return const Center(
              child: Text('Registration record not found.'),
            );
          }

          _populateFields(reg);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Immutability Notice Card
                        Card(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    color: colorScheme.primary, size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Fixed Hardware Identifiers',
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Student ID (${reg.studentId}) and Serial Number (${reg.serialNumber}) cannot be modified here to protect physical ownership integrity.',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (_saveError != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: colorScheme.onErrorContainer),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _saveError!,
                                    style: TextStyle(
                                      color: colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Student Information
                        Text(
                          'Student Information',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Student Full Name *',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: Validators.validateStudentName,
                          textCapitalization: TextCapitalization.words,
                          enabled: !_isSaving,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number *',
                            prefixIcon: Icon(Icons.phone_outlined),
                            hintText: '09xxxxxxxx or +2519xxxxxxxx',
                            border: OutlineInputBorder(),
                          ),
                          validator: Validators.validatePhoneNumber,
                          keyboardType: TextInputType.phone,
                          enabled: !_isSaving,
                        ),
                        const SizedBox(height: 24),

                        // Computer Information
                        Text(
                          'Computer Specifications',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _brandController,
                          decoration: const InputDecoration(
                            labelText: 'Computer Brand *',
                            prefixIcon: Icon(Icons.laptop_chromebook),
                            hintText: 'e.g. Dell, HP, Lenovo, Apple',
                            border: OutlineInputBorder(),
                          ),
                          validator: Validators.validatePcBrand,
                          textCapitalization: TextCapitalization.words,
                          enabled: !_isSaving,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _modelController,
                          decoration: const InputDecoration(
                            labelText: 'Computer Model *',
                            prefixIcon: Icon(Icons.devices_outlined),
                            hintText: 'e.g. Latitude 5420, ThinkPad T14',
                            border: OutlineInputBorder(),
                          ),
                          validator: Validators.validatePcModel,
                          enabled: !_isSaving,
                        ),
                        const SizedBox(height: 32),

                        // Submit Button
                        FilledButton.icon(
                          onPressed: _isSaving ? null : _handleSave,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(_isSaving
                              ? 'Saving Changes...'
                              : 'Save Registration Changes'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
