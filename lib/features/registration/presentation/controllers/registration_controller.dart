import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/registration_repository.dart';
import '../../data/storage_service.dart';
import '../../domain/registration.dart';

/// Form state for the multi-step student and PC registration process.
class RegistrationFormState {
  const RegistrationFormState({
    this.currentStep = 0,
    this.studentName = '',
    this.studentId = '',
    this.phoneNumber = '',
    this.pcBrand = '',
    this.pcModel = '',
    this.serialNumber = '',
    this.pcPhotoFile,
    this.studentWithPcPhotoFile,
    this.isSubmitting = false,
    this.uploadProgress = 0.0,
    this.statusMessage,
    this.errorMessage,
    this.createdRegistration,
  });

  final int currentStep;
  final String studentName;
  final String studentId;
  final String phoneNumber;
  final String pcBrand;
  final String pcModel;
  final String serialNumber;
  final File? pcPhotoFile;
  final File? studentWithPcPhotoFile;
  final bool isSubmitting;
  final double uploadProgress;
  final String? statusMessage;
  final String? errorMessage;
  final Registration? createdRegistration;

  bool get hasBothPhotos =>
      pcPhotoFile != null && studentWithPcPhotoFile != null;

  RegistrationFormState copyWith({
    int? currentStep,
    String? studentName,
    String? studentId,
    String? phoneNumber,
    String? pcBrand,
    String? pcModel,
    String? serialNumber,
    File? Function()? pcPhotoFile,
    File? Function()? studentWithPcPhotoFile,
    bool? isSubmitting,
    double? uploadProgress,
    String? Function()? statusMessage,
    String? Function()? errorMessage,
    Registration? Function()? createdRegistration,
  }) {
    return RegistrationFormState(
      currentStep: currentStep ?? this.currentStep,
      studentName: studentName ?? this.studentName,
      studentId: studentId ?? this.studentId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      pcBrand: pcBrand ?? this.pcBrand,
      pcModel: pcModel ?? this.pcModel,
      serialNumber: serialNumber ?? this.serialNumber,
      pcPhotoFile: pcPhotoFile != null ? pcPhotoFile() : this.pcPhotoFile,
      studentWithPcPhotoFile: studentWithPcPhotoFile != null
          ? studentWithPcPhotoFile()
          : this.studentWithPcPhotoFile,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      statusMessage:
          statusMessage != null ? statusMessage() : this.statusMessage,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      createdRegistration: createdRegistration != null
          ? createdRegistration()
          : this.createdRegistration,
    );
  }
}

/// Notifier managing registration multi-step state and execution.
class RegistrationController extends Notifier<RegistrationFormState> {
  final ImagePicker _picker = ImagePicker();

  @override
  RegistrationFormState build() => const RegistrationFormState();

  void setStep(int step) {
    state = state.copyWith(currentStep: step, errorMessage: () => null);
  }

  void updateStudentDetails({
    required String name,
    required String id,
    required String phone,
  }) {
    state = state.copyWith(
      studentName: name,
      studentId: id,
      phoneNumber: phone,
      errorMessage: () => null,
    );
  }

  void updateComputerDetails({
    required String brand,
    required String model,
    required String serial,
  }) {
    state = state.copyWith(
      pcBrand: brand,
      pcModel: model,
      serialNumber: serial,
      errorMessage: () => null,
    );
  }

  /// Captures or selects the computer photograph.
  Future<void> pickPcPhoto(ImageSource source) async {
    try {
      final xFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (xFile != null) {
        state = state.copyWith(
          pcPhotoFile: () => File(xFile.path),
          errorMessage: () => null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: () => 'Failed to capture photo: $e',
      );
    }
  }

  /// Removes the captured computer photo.
  void removePcPhoto() {
    state = state.copyWith(pcPhotoFile: () => null);
  }

  /// Captures or selects the student holding computer photograph.
  Future<void> pickStudentWithPcPhoto(ImageSource source) async {
    try {
      final xFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (xFile != null) {
        state = state.copyWith(
          studentWithPcPhotoFile: () => File(xFile.path),
          errorMessage: () => null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: () => 'Failed to capture student photo: $e',
      );
    }
  }

  /// Removes the student holding computer photo.
  void removeStudentWithPcPhoto() {
    state = state.copyWith(studentWithPcPhotoFile: () => null);
  }

  /// Submits the registration with duplicate detection, photo uploads, and Firestore transaction.
  Future<bool> submitRegistration() async {
    if (!state.hasBothPhotos) {
      state = state.copyWith(
        errorMessage: () =>
            'Both the computer photo and the student holding computer photo are required.',
      );
      return false;
    }

    final officer = ref.read(authRepositoryProvider).currentUser;
    final officerProfile =
        ref.read(currentStaffProfileStreamProvider).value;

    if (officer == null) {
      state = state.copyWith(
        errorMessage: () => 'Authentication error: Please sign in again.',
      );
      return false;
    }

    state = state.copyWith(
      isSubmitting: true,
      uploadProgress: 0.05,
      statusMessage: () => 'Verifying serial number uniqueness...',
      errorMessage: () => null,
    );

    final registrationRepo = ref.read(registrationRepositoryProvider);
    final storageService = ref.read(storageServiceProvider);

    String? uploadedPcUrl;
    String? uploadedStudentUrl;

    try {
      // 1. Pre-check serial duplicate
      final alreadyRegistered =
          await registrationRepo.isSerialAlreadyRegistered(state.serialNumber);
      if (alreadyRegistered) {
        throw DuplicateSerialException(
          'Computer with serial number "${state.serialNumber.trim().toUpperCase()}" is already actively registered. Duplicate serial numbers are rejected.',
        );
      }

      // 2. Upload computer photo
      state = state.copyWith(
        uploadProgress: 0.25,
        statusMessage: () => 'Uploading computer photograph...',
      );

      final tempId =
          'reg_${DateTime.now().millisecondsSinceEpoch}_${state.studentId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}';

      uploadedPcUrl = await storageService.uploadRegistrationPhoto(
        file: state.pcPhotoFile!,
        registrationTempId: tempId,
        photoType: 'pc_photo',
        onProgress: (p) {
          state = state.copyWith(uploadProgress: 0.25 + (p * 0.3));
        },
      );

      // 3. Upload student with computer photo
      state = state.copyWith(
        uploadProgress: 0.55,
        statusMessage: () => 'Uploading student identification photograph...',
      );

      uploadedStudentUrl = await storageService.uploadRegistrationPhoto(
        file: state.studentWithPcPhotoFile!,
        registrationTempId: tempId,
        photoType: 'student_pc_photo',
        onProgress: (p) {
          state = state.copyWith(uploadProgress: 0.55 + (p * 0.3));
        },
      );

      // 4. Save registration document to Firestore
      state = state.copyWith(
        uploadProgress: 0.90,
        statusMessage: () => 'Creating permanent registration record...',
      );

      final registration = await registrationRepo.createRegistration(
        studentName: state.studentName,
        studentId: state.studentId,
        phoneNumber: state.phoneNumber,
        pcBrand: state.pcBrand,
        pcModel: state.pcModel,
        serialNumber: state.serialNumber,
        pcPhotoUrl: uploadedPcUrl,
        studentWithPcPhotoUrl: uploadedStudentUrl,
        registeredBy: officer.uid,
        registeredByName: officerProfile?.name,
        registeredByEmail: officerProfile?.email ?? officer.email,
      );

      state = state.copyWith(
        isSubmitting: false,
        uploadProgress: 1.0,
        statusMessage: () => null,
        createdRegistration: () => registration,
      );

      return true;
    } catch (e) {
      // Clean up uploaded photos if Firestore write failed
      if (uploadedPcUrl != null) {
        await storageService.deletePhotoByUrl(uploadedPcUrl);
      }
      if (uploadedStudentUrl != null) {
        await storageService.deletePhotoByUrl(uploadedStudentUrl);
      }

      state = state.copyWith(
        isSubmitting: false,
        statusMessage: () => null,
        errorMessage: () => e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Resets the form for a new registration.
  void resetForm() {
    state = const RegistrationFormState();
  }
}

final registrationControllerProvider =
    NotifierProvider.autoDispose<RegistrationController, RegistrationFormState>(
  RegistrationController.new,
);
