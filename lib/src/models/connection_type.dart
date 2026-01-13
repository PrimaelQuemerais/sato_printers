/// The type of connection to establish with a SATO printer.
enum ConnectionType {
  /// Bluetooth connection using BD address
  bluetooth,
  /// TCP/IP connection using IP address and port
  tcp,
  /// USB connection using serial number
  usb;
  /// Creates a ConnectionType from a string value.
  static ConnectionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'bluetooth':
        return ConnectionType.bluetooth;
      case 'tcp':
        return ConnectionType.tcp;
      case 'usb':
        return ConnectionType.usb;
      default:
        throw ArgumentError('Unknown connection type: $value');
    }
  }
  /// Converts to string representation.
  String toValue() => name.toLowerCase();
}
