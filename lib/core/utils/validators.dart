/// Form field validators for the application.
class Validators {
  Validators._();

  static final RegExp _emailRegExp = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
  );

  // Supports local format (e.g., 0911223344, 0711223344) or international format (+251911223344)
  static final RegExp _phoneRegExp = RegExp(
    r"^(\+251|0)?[97][0-9]{8}$",
  );

  // Student ID pattern (e.g. UGR/1234/14, GSE/5678/15, ETS0123/12, or alphanumeric ID)
  static final RegExp _studentIdRegExp = RegExp(
    r"^[a-zA-Z0-9\/\-]{4,20}$",
  );

  // Serial number pattern: alphanumeric, dashes, underscores, at least 4 chars
  static final RegExp _serialNumberRegExp = RegExp(
    r"^[a-zA-Z0-9\-_]{4,40}$",
  );

  /// Validates email address format and non-emptiness.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final trimmed = value.trim();
    if (!_emailRegExp.hasMatch(trimmed)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validates login password.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validates staff full name.
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  /// Validates student full name.
  static String? validateStudentName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Student full name is required';
    }
    if (value.trim().length < 3) {
      return 'Enter at least first and last name (3+ characters)';
    }
    return null;
  }

  /// Validates university student ID.
  static String? validateStudentId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Student ID is required';
    }
    final trimmed = value.trim();
    if (!_studentIdRegExp.hasMatch(trimmed)) {
      return 'Enter a valid student ID (e.g., UGR/1234/14)';
    }
    return null;
  }

  /// Validates phone number.
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final trimmed = value.trim().replaceAll(' ', '');
    if (!_phoneRegExp.hasMatch(trimmed)) {
      return 'Enter a valid Ethiopian phone number (e.g., 0911223344 or +251911223344)';
    }
    return null;
  }

  /// Validates computer brand.
  static String? validatePcBrand(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Computer brand is required';
    }
    if (value.trim().length < 2) {
      return 'Brand must be at least 2 characters';
    }
    return null;
  }

  /// Validates computer model.
  static String? validatePcModel(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Computer model is required';
    }
    if (value.trim().length < 2) {
      return 'Model must be at least 2 characters';
    }
    return null;
  }

  /// Validates computer hardware serial number.
  static String? validateSerialNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Serial number is required';
    }
    final trimmed = value.trim();
    if (!_serialNumberRegExp.hasMatch(trimmed)) {
      return 'Enter a valid serial number (min 4 alphanumeric characters)';
    }
    return null;
  }

  /// Validates temporary password during staff creation.
  static String? validateTemporaryPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Temporary password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
}
