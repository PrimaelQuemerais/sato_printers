import 'dart:typed_data';

/// Represents the result of a print operation.
class PrintResult {
  /// Whether the print operation was successful.
  final bool success;

  /// Optional message about the operation.
  final String? message;

  /// Response data from the printer, if any.
  final Uint8List? responseData;

  /// Creates a PrintResult.
  const PrintResult({required this.success, this.message, this.responseData});

  /// Creates a PrintResult from a map.
  factory PrintResult.fromMap(Map<dynamic, dynamic> map) {
    return PrintResult(
      success: map['success'] as bool? ?? false,
      message: map['message'] as String?,
      responseData: map['responseData'] != null
          ? Uint8List.fromList((map['responseData'] as List).cast<int>())
          : null,
    );
  }

  /// Creates a successful result.
  factory PrintResult.ok([String? message]) {
    return PrintResult(success: true, message: message);
  }

  /// Creates a failed result.
  factory PrintResult.error(String message) {
    return PrintResult(success: false, message: message);
  }

  @override
  String toString() => 'PrintResult(success: $success, message: $message)';
}
