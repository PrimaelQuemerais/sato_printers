import 'connection_type.dart';

/// Represents a discovered SATO printer device.
class PrinterDevice {
  /// The name of the printer (may be null if not available)
  final String? name;

  /// The address of the printer.
  /// - For Bluetooth: the BD address (MAC address)
  /// - For TCP: IP address with port (e.g., "192.168.1.1:9100")
  /// - For USB: the serial number
  final String address;

  /// The type of connection this device uses.
  final ConnectionType connectionType;

  /// The USB serial number (only for USB devices)
  final String? serialNumber;

  /// Creates a PrinterDevice.
  const PrinterDevice({
    this.name,
    required this.address,
    required this.connectionType,
    this.serialNumber,
  });

  /// Creates a PrinterDevice from a map (typically from method channel).
  factory PrinterDevice.fromMap(Map<dynamic, dynamic> map) {
    return PrinterDevice(
      name: map['name'] as String?,
      address: map['address'] as String,
      connectionType: ConnectionType.fromString(
        map['connectionType'] as String,
      ),
      serialNumber: map['serialNumber'] as String?,
    );
  }

  /// Converts to a map for method channel communication.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'connectionType': connectionType.toValue(),
      'serialNumber': serialNumber,
    };
  }

  /// Creates a Bluetooth printer device.
  factory PrinterDevice.bluetooth({String? name, required String address}) {
    return PrinterDevice(
      name: name,
      address: address,
      connectionType: ConnectionType.bluetooth,
    );
  }

  /// Creates a TCP/IP printer device.
  factory PrinterDevice.tcp({
    String? name,
    required String ipAddress,
    int port = 9100,
  }) {
    return PrinterDevice(
      name: name,
      address: '$ipAddress:$port',
      connectionType: ConnectionType.tcp,
    );
  }

  /// Creates a USB printer device.
  factory PrinterDevice.usb({String? name, required String serialNumber}) {
    return PrinterDevice(
      name: name,
      address: serialNumber,
      connectionType: ConnectionType.usb,
      serialNumber: serialNumber,
    );
  }

  /// Display name for the printer.
  String get displayName => name ?? address;

  @override
  String toString() => 'PrinterDevice($displayName, $connectionType)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrinterDevice &&
          runtimeType == other.runtimeType &&
          address == other.address &&
          connectionType == other.connectionType;

  @override
  int get hashCode => address.hashCode ^ connectionType.hashCode;
}
