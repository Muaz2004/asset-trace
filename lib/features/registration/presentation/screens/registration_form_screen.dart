import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../controllers/registration_controller.dart';
import '../widgets/photo_capture_card.dart';
import '../widgets/registration_summary_card.dart';

/// Multi-step registration form for enrolling student computers.
class RegistrationFormScreen extends ConsumerStatefulWidget {
  const RegistrationFormScreen({super.key});

  @override
  ConsumerState<RegistrationFormScreen> createState() =>
      _RegistrationFormScreenState();
}

class _RegistrationFormScreenState
    extends ConsumerState<RegistrationFormScreen> {
  final _studentFormKey = GlobalKey<FormState>();
  final _computerFormKey = GlobalKey<FormState>();

  late final TextEditingController _studentNameController;
  late final TextEditingController _studentIdController;
  late final TextEditingController _phoneController;

  late final TextEditingController _pcBrandController;
  late final TextEditingController _pcModelController;
  late final TextEditingController _serialNumberController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(registrationControllerProvider);
    _studentNameController = TextEditingController(text: state.studentName);
    _studentIdController = TextEditingController(text: state.studentId);
    _phoneController = TextEditingController(text: state.phoneNumber);

    _pcBrandController = TextEditingController(text: state.pcBrand);
    _pcModelController = TextEditingController(text: state.pcModel);
    _serialNumberController = TextEditingController(text: state.serialNumber);
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _studentIdController.dispose();
    _phoneController.dispose();

    _pcBrandController.dispose();
    _pcModelController.dispose();
    _serialNumberController.dispose();
    super.dispose();
  }

  void _saveCurrentFields() {
    final notifier = ref.read(registrationControllerProvider.notifier);
    notifier.updateStudentDetails(
      name: _studentNameController.text,
      id: _studentIdController.text,
      phone: _phoneController.text,
    );
    notifier.updateComputerDetails(
      brand: _pcBrandController.text,
      model: _pcModelController.text,
      serial: _serialNumberController.text,
    );
  }

  void _onStepContinue() {
    final currentStep = ref.read(registrationControllerProvider).currentStep;
    final notifier = ref.read(registrationControllerProvider.notifier);

    if (currentStep == 0) {
      if (!_studentFormKey.currentState!.validate()) return;
      _saveCurrentFields();
      notifier.setStep(1);
    } else if (currentStep == 1) {
      if (!_computerFormKey.currentState!.validate()) return;
      _saveCurrentFields();
      notifier.setStep(2);
    } else if (currentStep == 2) {
      final state = ref.read(registrationControllerProvider);
      if (!state.hasBothPhotos) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please capture both required verification photographs before proceeding.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      notifier.setStep(3);
    } else if (currentStep == 3) {
      _handleFinalSubmission();
    }
  }

  void _onStepCancel() {
    final currentStep = ref.read(registrationControllerProvider).currentStep;
    if (currentStep > 0) {
      ref.read(registrationControllerProvider.notifier).setStep(currentStep - 1);
    } else {
      context.pop();
    }
  }

  Future<void> _handleFinalSubmission() async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Confirm Registration',
      message:
          'Are you sure you want to finalize this computer registration? The serial number and ownership record will be permanently registered.',
      confirmLabel: 'Submit Registration',
    );

    if (!confirmed || !mounted) return;

    final success = await ref
        .read(registrationControllerProvider.notifier)
        .submitRegistration();

    if (success && mounted) {
      context.go(RoutePaths.registrationSuccess);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formState = ref.watch(registrationControllerProvider);
    final notifier = ref.read(registrationControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Computer Registration'),
      ),
      body: SafeArea(
        child: formState.isSubmitting
            ? _buildSubmittingView(theme, colorScheme, formState)
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Stepper(
                    type: StepperType.horizontal,
                    currentStep: formState.currentStep,
                    onStepContinue: _onStepContinue,
                    onStepCancel: _onStepCancel,
                    onStepTapped: (step) {
                      _saveCurrentFields();
                      notifier.setStep(step);
                    },
                    controlsBuilder: (context, details) {
                      final isLastStep = formState.currentStep == 3;
                      return Padding(
                        padding: const EdgeInsets.only(top: 24.0),
                        child: Row(
                          children: [
                            FilledButton(
                              onPressed: details.onStepContinue,
                              child: Text(
                                isLastStep
                                    ? 'Confirm & Register'
                                    : 'Continue',
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: details.onStepCancel,
                              child: Text(
                                formState.currentStep == 0
                                    ? 'Cancel'
                                    : 'Back',
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    steps: [
                      // Step 1: Student Information
                      Step(
                        title: const Text('Student'),
                        isActive: formState.currentStep >= 0,
                        state: formState.currentStep > 0
                            ? StepState.complete
                            : StepState.indexed,
                        content: Form(
                          key: _studentFormKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _SectionHeader(
                                title: 'Student Information',
                                subtitle:
                                    'Enter details from the presented university student ID.',
                                colorScheme: colorScheme,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _studentNameController,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Student Full Name *',
                                  hintText: 'e.g. Almaz Ayana',
                                  prefixIcon: Icon(Icons.person_outline_rounded),
                                ),
                                validator: Validators.validateStudentName,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _studentIdController,
                                textCapitalization: TextCapitalization.characters,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'University Student ID *',
                                  hintText: 'e.g. UGR/1234/14',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                                validator: Validators.validateStudentId,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.done,
                                decoration: const InputDecoration(
                                  labelText: 'Contact Phone Number *',
                                  hintText: '0911223344',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                                validator: Validators.validatePhoneNumber,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Step 2: Computer Details
                      Step(
                        title: const Text('Computer'),
                        isActive: formState.currentStep >= 1,
                        state: formState.currentStep > 1
                            ? StepState.complete
                            : StepState.indexed,
                        content: Form(
                          key: _computerFormKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _SectionHeader(
                                title: 'Computer Hardware Details',
                                subtitle:
                                    'Accurately record the manufacturer hardware specifications.',
                                colorScheme: colorScheme,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _pcBrandController,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Computer Brand *',
                                  hintText: 'e.g. Dell, HP, Lenovo, Apple',
                                  prefixIcon: Icon(Icons.laptop_chromebook_rounded),
                                ),
                                validator: Validators.validatePcBrand,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _pcModelController,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Computer Model *',
                                  hintText: 'e.g. Latitude 5420, ThinkPad T14',
                                  prefixIcon: Icon(Icons.devices_rounded),
                                ),
                                validator: Validators.validatePcModel,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _serialNumberController,
                                textCapitalization: TextCapitalization.characters,
                                textInputAction: TextInputAction.done,
                                decoration: const InputDecoration(
                                  labelText: 'Hardware Serial Number *',
                                  hintText: 'e.g. 5CD2341ABC',
                                  helperText: 'Validated for duplicates against all active registrations.',
                                  prefixIcon: Icon(Icons.pin_outlined),
                                ),
                                validator: Validators.validateSerialNumber,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Step 3: Photograph Capture
                      Step(
                        title: const Text('Photos'),
                        isActive: formState.currentStep >= 2,
                        state: formState.currentStep > 2
                            ? StepState.complete
                            : StepState.indexed,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SectionHeader(
                              title: 'Verification Photographs',
                              subtitle:
                                  'Capture required visual evidence for campus verification audit.',
                              colorScheme: colorScheme,
                            ),
                            const SizedBox(height: 16),
                            PhotoCaptureCard(
                              title: '1. Computer Photograph *',
                              subtitle:
                                  'Clear picture of laptop device and keyboard area.',
                              icon: Icons.laptop_rounded,
                              imageFile: formState.pcPhotoFile,
                              onPickImage: (source) =>
                                  notifier.pickPcPhoto(source),
                              onRemoveImage: notifier.removePcPhoto,
                            ),
                            const SizedBox(height: 16),
                            PhotoCaptureCard(
                              title: '2. Student Holding Computer *',
                              subtitle:
                                  'Clear picture of the student holding the device.',
                              icon: Icons.person_pin_rounded,
                              imageFile: formState.studentWithPcPhotoFile,
                              onPickImage: (source) =>
                                  notifier.pickStudentWithPcPhoto(source),
                              onRemoveImage: notifier.removeStudentWithPcPhoto,
                            ),
                          ],
                        ),
                      ),

                      // Step 4: Review and Submit
                      Step(
                        title: const Text('Review'),
                        isActive: formState.currentStep >= 3,
                        state: StepState.indexed,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (formState.errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      size: 20,
                                      color: colorScheme.onErrorContainer,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        formState.errorMessage!,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onErrorContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            RegistrationSummaryCard(
                              studentName: _studentNameController.text,
                              studentId: _studentIdController.text,
                              phoneNumber: _phoneController.text,
                              pcBrand: _pcBrandController.text,
                              pcModel: _pcModelController.text,
                              serialNumber: _serialNumberController.text,
                              pcPhotoFile: formState.pcPhotoFile,
                              studentWithPcPhotoFile:
                                  formState.studentWithPcPhotoFile,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSubmittingView(
    ThemeData theme,
    ColorScheme colorScheme,
    RegistrationFormState formState,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(
                    value: formState.uploadProgress > 0.05
                        ? formState.uploadProgress
                        : null,
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Processing Registration',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formState.statusMessage ??
                    'Saving verified registration record...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: formState.uploadProgress,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Text(
                '${(formState.uploadProgress * 100).toInt()}% completed',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.colorScheme,
  });

  final String title;
  final String subtitle;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
