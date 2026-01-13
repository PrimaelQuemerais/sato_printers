import 'dart:typed_data';

/// Options for print operations.
class PrintOptions {
  /// Number of copies to print.
  final int copies;

  /// Timeout in milliseconds for the operation.
  final int timeout;

  /// Whether to expect a response from the printer.
  final bool expectResponse;

  /// Number of bytes to expect in response (-1 for unknown).
  final int responseByteCount;

  /// Terminator bytes for response reading.
  final Uint8List? responseTerminator;

  /// X position for image printing.
  final int xPosition;

  /// Y position for image printing.
  final int yPosition;

  /// Whether to convert images to SBPL format.
  final bool convertToSbpl;

  /// Creates PrintOptions.
  const PrintOptions({
    this.copies = 1,
    this.timeout = 10000,
    this.expectResponse = false,
    this.responseByteCount = -1,
    this.responseTerminator,
    this.xPosition = 0,
    this.yPosition = 0,
    this.convertToSbpl = true,
  });

  /// Converts to a map for method channel communication.
  Map<String, dynamic> toMap() {
    return {
      'copies': copies,
      'timeout': timeout,
      'expectResponse': expectResponse,
      'responseByteCount': responseByteCount,
      'responseTerminator': responseTerminator,
      'xPosition': xPosition,
      'yPosition': yPosition,
      'convertToSbpl': convertToSbpl,
    };
  }

  /// Creates a copy with modified properties.
  PrintOptions copyWith({
    int? copies,
    int? timeout,
    bool? expectResponse,
    int? responseByteCount,
    Uint8List? responseTerminator,
    int? xPosition,
    int? yPosition,
    bool? convertToSbpl,
  }) {
    return PrintOptions(
      copies: copies ?? this.copies,
      timeout: timeout ?? this.timeout,
      expectResponse: expectResponse ?? this.expectResponse,
      responseByteCount: responseByteCount ?? this.responseByteCount,
      responseTerminator: responseTerminator ?? this.responseTerminator,
      xPosition: xPosition ?? this.xPosition,
      yPosition: yPosition ?? this.yPosition,
      convertToSbpl: convertToSbpl ?? this.convertToSbpl,
    );
  }
}
