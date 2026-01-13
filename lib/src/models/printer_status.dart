/// Represents the status of a SATO printer.
class PrinterStatus {
  /// Whether the printer is currently connected.
  final bool isConnected;

  /// Whether the printer is online and ready.
  final bool isOnline;

  /// Whether the printer is out of paper.
  final bool isPaperOut;

  /// Whether the printer is out of ribbon.
  final bool isRibbonOut;

  /// Whether the printer cover is open.
  final bool isCoverOpen;

  /// Whether the printer has an error.
  final bool hasError;

  /// Error message if there's an error.
  final String? errorMessage;

  /// Creates a PrinterStatus.
  const PrinterStatus({
    required this.isConnected,
    this.isOnline = false,
    this.isPaperOut = false,
    this.isRibbonOut = false,
    this.isCoverOpen = false,
    this.hasError = false,
    this.errorMessage,
  });

  /// Creates a PrinterStatus from a map.
  factory PrinterStatus.fromMap(Map<dynamic, dynamic> map) {
    return PrinterStatus(
      isConnected: map['isConnected'] as bool? ?? false,
      isOnline: map['isOnline'] as bool? ?? false,
      isPaperOut: map['isPaperOut'] as bool? ?? false,
      isRibbonOut: map['isRibbonOut'] as bool? ?? false,
      isCoverOpen: map['isCoverOpen'] as bool? ?? false,
      hasError: map['hasError'] as bool? ?? false,
      errorMessage: map['errorMessage'] as String?,
    );
  }

  /// Creates a disconnected status.
  factory PrinterStatus.disconnected() {
    return const PrinterStatus(isConnected: false);
  }

  /// Whether the printer is ready to print.
  bool get isReady =>
      isConnected &&
      isOnline &&
      !isPaperOut &&
      !isRibbonOut &&
      !isCoverOpen &&
      !hasError;

  @override
  String toString() =>
      'PrinterStatus(connected: $isConnected, ready: $isReady)';
}
