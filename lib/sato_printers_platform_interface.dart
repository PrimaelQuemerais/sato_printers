import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'sato_printers_method_channel.dart';
import 'src/models/models.dart';

/// The interface that implementations of sato_printers must implement.
///
/// Platform implementations should extend this class rather than implement it
/// as `sato_printers` does not consider newly added methods to be breaking
/// changes. Extending this class ensures that the subclass will get the
/// default implementation of newly added methods.
abstract class SatoPrintersPlatform extends PlatformInterface {
  /// Constructs a SatoPrintersPlatform.
  SatoPrintersPlatform() : super(token: _token);

  static final Object _token = Object();

  static SatoPrintersPlatform _instance = MethodChannelSatoPrinters();

  /// The default instance of [SatoPrintersPlatform] to use.
  ///
  /// Defaults to [MethodChannelSatoPrinters].
  static SatoPrintersPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SatoPrintersPlatform] when
  /// they register themselves.
  static set instance(SatoPrintersPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Gets the platform version.
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  // ============== Discovery Methods ==============

  /// Discovers paired Bluetooth printers.
  Future<List<PrinterDevice>> discoverBluetoothPrinters() {
    throw UnimplementedError(
      'discoverBluetoothPrinters() has not been implemented.',
    );
  }

  /// Discovers connected USB printers.
  Future<List<PrinterDevice>> discoverUsbPrinters() {
    throw UnimplementedError('discoverUsbPrinters() has not been implemented.');
  }

  /// Checks Bluetooth status.
  /// Returns a map with 'available' and 'enabled' boolean values.
  Future<Map<String, bool>> checkBluetoothStatus() {
    throw UnimplementedError(
      'checkBluetoothStatus() has not been implemented.',
    );
  }

  // ============== Connection Methods ==============

  /// Connects to a Bluetooth printer.
  ///
  /// [address] - The Bluetooth MAC address of the printer.
  /// [timeout] - Connection timeout in milliseconds (default: 10000).
  Future<bool> connectBluetooth(String address, {int timeout = 10000}) {
    throw UnimplementedError('connectBluetooth() has not been implemented.');
  }

  /// Connects to a TCP/IP printer.
  ///
  /// [ipAddress] - The IP address of the printer.
  /// [port] - The TCP port (usually 9100).
  /// [timeout] - Connection timeout in milliseconds (default: 10000).
  Future<bool> connectTcp(String ipAddress, int port, {int timeout = 10000}) {
    throw UnimplementedError('connectTcp() has not been implemented.');
  }

  /// Connects to a USB printer.
  ///
  /// [serialNumber] - The USB serial number of the printer.
  Future<bool> connectUsb(String serialNumber) {
    throw UnimplementedError('connectUsb() has not been implemented.');
  }

  /// Disconnects from the current printer.
  Future<bool> disconnect() {
    throw UnimplementedError('disconnect() has not been implemented.');
  }

  /// Checks if a printer is currently connected.
  Future<bool> isConnected() {
    throw UnimplementedError('isConnected() has not been implemented.');
  }

  /// Gets the currently connected device info.
  Future<PrinterDevice?> getCurrentDevice() {
    throw UnimplementedError('getCurrentDevice() has not been implemented.');
  }

  // ============== Print Methods ==============

  /// Sends raw data to the printer.
  ///
  /// [data] - The raw data bytes to send.
  /// [options] - Optional print options.
  Future<PrintResult> printRawData(Uint8List data, {PrintOptions? options}) {
    throw UnimplementedError('printRawData() has not been implemented.');
  }

  /// Prints an image.
  ///
  /// [imageBytes] - The image data (PNG, JPG, etc.).
  /// [options] - Optional print options including positioning.
  Future<PrintResult> printImage(
    Uint8List imageBytes, {
    PrintOptions? options,
  }) {
    throw UnimplementedError('printImage() has not been implemented.');
  }

  /// Gets the current printer status.
  Future<PrinterStatus> getStatus() {
    throw UnimplementedError('getStatus() has not been implemented.');
  }

  /// Sets the read timeout for printer responses.
  ///
  /// [timeout] - Timeout in milliseconds.
  Future<bool> setReadTimeout(int timeout) {
    throw UnimplementedError('setReadTimeout() has not been implemented.');
  }
}
