/// Flutter plugin for SATO label printers.
///
/// This plugin provides a simple API to discover, connect to, and print
/// on SATO label printers using Bluetooth, TCP/IP, or USB connections.
library;

import 'dart:typed_data';

import 'sato_printers_platform_interface.dart';
import 'src/models/models.dart';

// Export all models for public use
export 'src/models/models.dart';

/// The main class for interacting with SATO printers.
///
/// Example usage:
/// ```dart
/// final satoPrinters = SatoPrinters();
///
/// // Discover Bluetooth printers
/// final printers = await satoPrinters.discoverBluetoothPrinters();
///
/// // Connect to a printer
/// if (printers.isNotEmpty) {
///   await satoPrinters.connect(printers.first);
/// }
///
/// // Print an image
/// final imageBytes = await loadImageBytes();
/// await satoPrinters.printImage(imageBytes);
///
/// // Disconnect
/// await satoPrinters.disconnect();
/// ```
class SatoPrinters {
  SatoPrintersPlatform get _platform => SatoPrintersPlatform.instance;

  /// Gets the platform version.
  Future<String?> getPlatformVersion() {
    return _platform.getPlatformVersion();
  }

  // ============== Discovery Methods ==============

  /// Discovers paired Bluetooth printers.
  ///
  /// Returns a list of [PrinterDevice] objects representing paired
  /// Bluetooth devices that could be printers.
  ///
  /// Note: This returns paired devices, not necessarily SATO printers.
  /// The user should select the correct printer from the list.
  ///
  /// Throws [SatoBluetoothException] if Bluetooth is unavailable or disabled.
  /// Throws [SatoPermissionException] if Bluetooth permissions are not granted.
  Future<List<PrinterDevice>> discoverBluetoothPrinters() {
    return _platform.discoverBluetoothPrinters();
  }

  /// Discovers connected USB printers.
  ///
  /// Returns a list of [PrinterDevice] objects representing connected
  /// SATO USB printers.
  Future<List<PrinterDevice>> discoverUsbPrinters() {
    return _platform.discoverUsbPrinters();
  }

  /// Checks the Bluetooth status on the device.
  ///
  /// Returns a map with:
  /// - 'available': Whether Bluetooth hardware is available
  /// - 'enabled': Whether Bluetooth is currently enabled
  Future<Map<String, bool>> checkBluetoothStatus() {
    return _platform.checkBluetoothStatus();
  }

  /// Checks if Bluetooth is available on the device.
  Future<bool> isBluetoothAvailable() async {
    final status = await checkBluetoothStatus();
    return status['available'] ?? false;
  }

  /// Checks if Bluetooth is enabled on the device.
  Future<bool> isBluetoothEnabled() async {
    final status = await checkBluetoothStatus();
    return status['enabled'] ?? false;
  }

  // ============== Connection Methods ==============

  /// Connects to a printer device.
  ///
  /// This is a convenience method that automatically determines the
  /// connection type based on the [device]'s [ConnectionType].
  ///
  /// [device] - The printer device to connect to.
  /// [timeout] - Connection timeout in milliseconds (default: 10000).
  ///
  /// Returns `true` if the connection was successful.
  ///
  /// Throws [SatoConnectionException] if the connection fails.
  Future<bool> connect(PrinterDevice device, {int timeout = 10000}) async {
    switch (device.connectionType) {
      case ConnectionType.bluetooth:
        return connectBluetooth(device.address, timeout: timeout);
      case ConnectionType.tcp:
        final parts = device.address.split(':');
        final ip = parts[0];
        final port = parts.length > 1 ? int.tryParse(parts[1]) ?? 9100 : 9100;
        return connectTcp(ip, port, timeout: timeout);
      case ConnectionType.usb:
        return connectUsb(device.serialNumber ?? device.address);
    }
  }

  /// Connects to a Bluetooth printer.
  ///
  /// [address] - The Bluetooth MAC address of the printer.
  /// [timeout] - Connection timeout in milliseconds (default: 10000).
  ///
  /// Returns `true` if the connection was successful.
  ///
  /// Throws [SatoConnectionException] if the connection fails.
  /// Throws [SatoBluetoothException] if Bluetooth is unavailable or disabled.
  Future<bool> connectBluetooth(String address, {int timeout = 10000}) {
    return _platform.connectBluetooth(address, timeout: timeout);
  }

  /// Connects to a TCP/IP printer.
  ///
  /// [ipAddress] - The IP address of the printer.
  /// [port] - The TCP port (usually 9100 for SATO printers).
  /// [timeout] - Connection timeout in milliseconds (default: 10000).
  ///
  /// Returns `true` if the connection was successful.
  ///
  /// Throws [SatoConnectionException] if the connection fails.
  Future<bool> connectTcp(String ipAddress, int port, {int timeout = 10000}) {
    return _platform.connectTcp(ipAddress, port, timeout: timeout);
  }

  /// Connects to a USB printer.
  ///
  /// [serialNumber] - The USB serial number of the printer.
  ///
  /// Returns `true` if the connection was successful.
  ///
  /// Throws [SatoConnectionException] if the connection fails.
  Future<bool> connectUsb(String serialNumber) {
    return _platform.connectUsb(serialNumber);
  }

  /// Disconnects from the current printer.
  ///
  /// Returns `true` if the disconnection was successful.
  Future<bool> disconnect() {
    return _platform.disconnect();
  }

  /// Checks if a printer is currently connected.
  ///
  /// Returns `true` if a printer is connected, `false` otherwise.
  Future<bool> isConnected() {
    return _platform.isConnected();
  }

  /// Gets the currently connected printer device.
  ///
  /// Returns the [PrinterDevice] if connected, or `null` if not connected.
  Future<PrinterDevice?> getCurrentDevice() {
    return _platform.getCurrentDevice();
  }

  // ============== Print Methods ==============

  /// Sends raw data to the printer.
  ///
  /// Use this method to send raw SBPL commands or pre-formatted data
  /// directly to the printer.
  ///
  /// [data] - The raw data bytes to send.
  /// [options] - Optional print options.
  ///
  /// Returns a [PrintResult] indicating success or failure.
  ///
  /// Throws [SatoConnectionException] if not connected.
  /// Throws [SatoPrintException] if printing fails.
  /// Throws [SatoTimeoutException] if the operation times out.
  Future<PrintResult> printRawData(Uint8List data, {PrintOptions? options}) {
    return _platform.printRawData(data, options: options);
  }

  /// Prints an image.
  ///
  /// The image will be converted to a format suitable for the printer.
  /// Supported image formats: PNG, JPG.
  ///
  /// [imageBytes] - The image data.
  /// [options] - Optional print options including:
  ///   - `xPosition`: X position on the label (default: 0)
  ///   - `yPosition`: Y position on the label (default: 0)
  ///   - `convertToSbpl`: Whether to convert to SBPL format (default: true)
  ///   - `copies`: Number of copies to print (default: 1)
  ///
  /// Returns a [PrintResult] indicating success or failure.
  ///
  /// Throws [SatoConnectionException] if not connected.
  /// Throws [SatoPrintException] if printing fails.
  Future<PrintResult> printImage(
    Uint8List imageBytes, {
    PrintOptions? options,
  }) {
    return _platform.printImage(imageBytes, options: options);
  }

  /// Gets the current printer status.
  ///
  /// Returns a [PrinterStatus] with information about the printer state.
  Future<PrinterStatus> getStatus() {
    return _platform.getStatus();
  }

  /// Sets the read timeout for printer responses.
  ///
  /// [timeout] - Timeout in milliseconds.
  ///
  /// Returns `true` if successful.
  Future<bool> setReadTimeout(int timeout) {
    return _platform.setReadTimeout(timeout);
  }
}
