/// Base exception for SATO printer errors.
class SatoException implements Exception {
  /// The error code.
  final String code;

  /// The error message.
  final String message;

  /// Additional details about the error.
  final dynamic details;

  /// Creates a SatoException.
  const SatoException({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'SatoException($code): $message';
}

/// Exception thrown when a connection error occurs.
class SatoConnectionException extends SatoException {
  /// Creates a SatoConnectionException.
  const SatoConnectionException({
    required super.code,
    required super.message,
    super.details,
  });
}

/// Exception thrown when Bluetooth is not available or disabled.
class SatoBluetoothException extends SatoException {
  /// Creates a SatoBluetoothException.
  const SatoBluetoothException({
    required super.code,
    required super.message,
    super.details,
  });
}

/// Exception thrown when a print operation fails.
class SatoPrintException extends SatoException {
  /// Creates a SatoPrintException.
  const SatoPrintException({
    required super.code,
    required super.message,
    super.details,
  });
}

/// Exception thrown when a timeout occurs.
class SatoTimeoutException extends SatoException {
  /// Creates a SatoTimeoutException.
  const SatoTimeoutException({
    required super.code,
    required super.message,
    super.details,
  });
}

/// Exception thrown when required permissions are not granted.
class SatoPermissionException extends SatoException {
  /// Creates a SatoPermissionException.
  const SatoPermissionException({
    required super.code,
    required super.message,
    super.details,
  });
}
