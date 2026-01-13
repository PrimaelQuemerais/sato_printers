import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'sato_printers_platform_interface.dart';
import 'src/models/models.dart';

/// An implementation of [SatoPrintersPlatform] that uses method channels.
class MethodChannelSatoPrinters extends SatoPrintersPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('sato_printers');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  // ============== Discovery Methods ==============

  @override
  Future<List<PrinterDevice>> discoverBluetoothPrinters() async {
    try {
      final result = await methodChannel.invokeMethod<List>(
        'discoverBluetoothPrinters',
      );
      if (result == null) return [];

      return result
          .cast<Map>()
          .map((map) => PrinterDevice.fromMap(map))
          .toList();
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  @override
  Future<List<PrinterDevice>> discoverUsbPrinters() async {
    try {
      final result = await methodChannel.invokeMethod<List>(
        'discoverUsbPrinters',
      );
      if (result == null) return [];

      return result
          .cast<Map>()
          .map((map) => PrinterDevice.fromMap(map))
          .toList();
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  @override
  Future<Map<String, bool>> checkBluetoothStatus() async {
    try {
      final result = await methodChannel.invokeMethod<Map>(
        'checkBluetoothStatus',
      );
      if (result == null) {
        return {'available': false, 'enabled': false};
      }
      return {
        'available': result['available'] as bool? ?? false,
        'enabled': result['enabled'] as bool? ?? false,
      };
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  // ============== Connection Methods ==============

  @override
  Future<bool> connectBluetooth(String address, {int timeout = 10000}) async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'connectBluetooth',
        {'address': address, 'timeout': timeout},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  @override
  Future<bool> connectTcp(
    String ipAddress,
    int port, {
    int timeout = 10000,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<bool>('connectTcp', {
        'ipAddress': ipAddress,
        'port': port,
        'timeout': timeout,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  @override
  Future<bool> connectUsb(String serialNumber) async {
    try {
      final result = await methodChannel.invokeMethod<bool>('connectUsb', {
        'serialNumber': serialNumber,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  @override
  Future<bool> disconnect() async {
    try {
      final result = await methodChannel.invokeMethod<bool>('disconnect');
      return result ?? false;
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  @override
  Future<bool> isConnected() async {
    try {
      final result = await methodChannel.invokeMethod<bool>('isConnected');
      return result ?? false;
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  @override
  Future<PrinterDevice?> getCurrentDevice() async {
    try {
      final result = await methodChannel.invokeMethod<Map>('getCurrentDevice');
      if (result == null) return null;
      return PrinterDevice.fromMap(result);
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  // ============== Print Methods ==============

  @override
  Future<PrintResult> printRawData(
    Uint8List data, {
    PrintOptions? options,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<Map>('printRawData', {
        'data': data,
        'options': options?.toMap(),
      });
      if (result == null) {
        return PrintResult.error('No response from printer');
      }
      return PrintResult.fromMap(result);
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  @override
  Future<PrintResult> printImage(
    Uint8List imageBytes, {
    PrintOptions? options,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<Map>('printImage', {
        'imageBytes': imageBytes,
        'options': options?.toMap(),
      });
      if (result == null) {
        return PrintResult.error('No response from printer');
      }
      return PrintResult.fromMap(result);
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  @override
  Future<PrinterStatus> getStatus() async {
    try {
      final result = await methodChannel.invokeMethod<Map>('getStatus');
      if (result == null) {
        return PrinterStatus.disconnected();
      }
      return PrinterStatus.fromMap(result);
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  @override
  Future<bool> setReadTimeout(int timeout) async {
    try {
      final result = await methodChannel.invokeMethod<bool>('setReadTimeout', {
        'timeout': timeout,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  /// Maps a PlatformException to a SatoException.
  SatoException _mapPlatformException(PlatformException e) {
    final code = e.code;
    final message = e.message ?? 'Unknown error';

    switch (code) {
      case 'BLUETOOTH_UNAVAILABLE':
      case 'BLUETOOTH_DISABLED':
        return SatoBluetoothException(
          code: code,
          message: message,
          details: e.details,
        );
      case 'CONNECTION_FAILED':
      case 'NOT_CONNECTED':
        return SatoConnectionException(
          code: code,
          message: message,
          details: e.details,
        );
      case 'TIMEOUT':
        return SatoTimeoutException(
          code: code,
          message: message,
          details: e.details,
        );
      case 'PERMISSION_DENIED':
        return SatoPermissionException(
          code: code,
          message: message,
          details: e.details,
        );
      case 'PRINTER_ERROR':
        return SatoPrintException(
          code: code,
          message: message,
          details: e.details,
        );
      default:
        return SatoException(code: code, message: message, details: e.details);
    }
  }
}
