import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sato_printers/sato_printers.dart';
import 'package:sato_printers/sato_printers_method_channel.dart';
import 'package:sato_printers/sato_printers_platform_interface.dart';

class MockSatoPrintersPlatform
    with MockPlatformInterfaceMixin
    implements SatoPrintersPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<List<PrinterDevice>> discoverBluetoothPrinters() => Future.value([]);

  @override
  Future<List<PrinterDevice>> discoverUsbPrinters() => Future.value([]);

  @override
  Future<Map<String, bool>> checkBluetoothStatus() =>
      Future.value({'available': true, 'enabled': true});

  @override
  Future<bool> connectBluetooth(String address, {int timeout = 10000}) =>
      Future.value(true);

  @override
  Future<bool> connectTcp(String ipAddress, int port, {int timeout = 10000}) =>
      Future.value(true);

  @override
  Future<bool> connectUsb(String serialNumber) => Future.value(true);

  @override
  Future<bool> disconnect() => Future.value(true);

  @override
  Future<bool> isConnected() => Future.value(false);

  @override
  Future<PrinterDevice?> getCurrentDevice() => Future.value(null);

  @override
  Future<PrintResult> printRawData(Uint8List data, {PrintOptions? options}) =>
      Future.value(PrintResult.ok());

  @override
  Future<PrintResult> printImage(
    Uint8List imageBytes, {
    PrintOptions? options,
  }) => Future.value(PrintResult.ok());

  @override
  Future<PrinterStatus> getStatus() =>
      Future.value(PrinterStatus.disconnected());

  @override
  Future<bool> setReadTimeout(int timeout) => Future.value(true);
}

void main() {
  final SatoPrintersPlatform initialPlatform = SatoPrintersPlatform.instance;

  test('$MethodChannelSatoPrinters is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSatoPrinters>());
  });

  test('getPlatformVersion', () async {
    SatoPrinters satoPrintersPlugin = SatoPrinters();
    MockSatoPrintersPlatform fakePlatform = MockSatoPrintersPlatform();
    SatoPrintersPlatform.instance = fakePlatform;

    expect(await satoPrintersPlugin.getPlatformVersion(), '42');
  });

  test('discoverBluetoothPrinters returns empty list', () async {
    SatoPrinters satoPrintersPlugin = SatoPrinters();
    MockSatoPrintersPlatform fakePlatform = MockSatoPrintersPlatform();
    SatoPrintersPlatform.instance = fakePlatform;

    expect(await satoPrintersPlugin.discoverBluetoothPrinters(), isEmpty);
  });

  test('isConnected returns false when not connected', () async {
    SatoPrinters satoPrintersPlugin = SatoPrinters();
    MockSatoPrintersPlatform fakePlatform = MockSatoPrintersPlatform();
    SatoPrintersPlatform.instance = fakePlatform;

    expect(await satoPrintersPlugin.isConnected(), false);
  });

  test('checkBluetoothStatus returns available and enabled', () async {
    SatoPrinters satoPrintersPlugin = SatoPrinters();
    MockSatoPrintersPlatform fakePlatform = MockSatoPrintersPlatform();
    SatoPrintersPlatform.instance = fakePlatform;

    final status = await satoPrintersPlugin.checkBluetoothStatus();
    expect(status['available'], true);
    expect(status['enabled'], true);
  });
}
