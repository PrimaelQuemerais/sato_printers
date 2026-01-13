# SATO Printers

A Flutter plugin for connecting to and printing on SATO label printers via Bluetooth, TCP/IP, or USB.

[![pub package](https://img.shields.io/pub/v/sato_printers.svg)](https://pub.dev/packages/sato_printers)

## Features

- 🔍 **Discover Printers** - Find paired Bluetooth devices and connected USB printers
- 🔌 **Multiple Connection Types** - Support for Bluetooth, TCP/IP, and USB connections
- 🖨️ **Print Raw Data** - Send SBPL commands directly to the printer
- 🖼️ **Print Images** - Convert and print images with automatic SBPL conversion
- 📊 **Printer Status** - Query printer connection and status

## Installation

Add `sato_printers` to your `pubspec.yaml`:

```yaml
dependencies:
  sato_printers: ^0.0.1
```

### Android Setup

Add the required permissions to your `AndroidManifest.xml`:

```xml
<!-- Bluetooth permissions -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />

<!-- Location permission (may be required for Bluetooth scanning) -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

> **Note:** You need to handle runtime permissions in your app for Android 12+.

## Usage

### Import the package

```dart
import 'package:sato_printers/sato_printers.dart';
```

### Create an instance

```dart
final satoPrinters = SatoPrinters();
```

### Discover Printers

#### Bluetooth

```dart
// Check Bluetooth status
final status = await satoPrinters.checkBluetoothStatus();
if (status['available'] == true && status['enabled'] == true) {
  // Discover paired Bluetooth devices
  final printers = await satoPrinters.discoverBluetoothPrinters();
  for (final printer in printers) {
    print('Found: ${printer.displayName} (${printer.address})');
  }
}
```

#### USB

```dart
final printers = await satoPrinters.discoverUsbPrinters();
for (final printer in printers) {
  print('Found: ${printer.displayName} (${printer.serialNumber})');
}
```

### Connect to a Printer

#### Auto-connect (recommended)

```dart
// Automatically determines connection type based on PrinterDevice
final success = await satoPrinters.connect(printer);
```

#### Bluetooth

```dart
final success = await satoPrinters.connectBluetooth(
  'AA:BB:CC:DD:EE:FF',
  timeout: 10000,
);
```

#### TCP/IP

```dart
final success = await satoPrinters.connectTcp(
  '192.168.1.100',
  9100,
  timeout: 10000,
);
```

#### USB

```dart
final success = await satoPrinters.connectUsb('SERIAL_NUMBER');
```

### Print

#### Print Raw SBPL Data

```dart
// Example SBPL commands
final data = Uint8List.fromList([
  0x02, // STX
  ...('A1V100H100P02L0202Hello WorldQ1Z').codeUnits,
  0x03, // ETX
]);

final result = await satoPrinters.printRawData(data);
if (result.success) {
  print('Printed successfully!');
} else {
  print('Print failed: ${result.message}');
}
```

#### Print Image

```dart
// Load image bytes (e.g., from assets or file)
final imageBytes = await rootBundle.load('assets/label.png')
    .then((data) => data.buffer.asUint8List());

final result = await satoPrinters.printImage(
  imageBytes,
  options: PrintOptions(
    xPosition: 100,
    yPosition: 50,
    copies: 1,
  ),
);
```

### Get Printer Status

```dart
final status = await satoPrinters.getStatus();
print('Connected: ${status.isConnected}');
print('Ready: ${status.isReady}');
```

### Disconnect

```dart
await satoPrinters.disconnect();
```

## Error Handling

The plugin throws specific exceptions that you can catch:

```dart
try {
  await satoPrinters.connectBluetooth(address);
} on SatoBluetoothException catch (e) {
  print('Bluetooth error: ${e.message}');
} on SatoConnectionException catch (e) {
  print('Connection error: ${e.message}');
} on SatoPermissionException catch (e) {
  print('Permission denied: ${e.message}');
} on SatoTimeoutException catch (e) {
  print('Timeout: ${e.message}');
} on SatoException catch (e) {
  print('Error: ${e.message}');
}
```

## Models

### PrinterDevice

Represents a discovered or connected printer.

```dart
class PrinterDevice {
  final String? name;
  final String address;
  final ConnectionType connectionType;
  final String? serialNumber;
}
```

### PrintOptions

Options for print operations.

```dart
class PrintOptions {
  final int copies;
  final int timeout;
  final bool expectResponse;
  final int xPosition;
  final int yPosition;
  final bool convertToSbpl;
}
```

### PrintResult

Result of a print operation.

```dart
class PrintResult {
  final bool success;
  final String? message;
  final Uint8List? responseData;
}
```

### PrinterStatus

Status information from the printer.

```dart
class PrinterStatus {
  final bool isConnected;
  final bool isOnline;
  final bool isPaperOut;
  final bool isRibbonOut;
  final bool isCoverOpen;
  final bool hasError;
  final String? errorMessage;
}
```

## Supported Platforms

| Platform | Supported |
|----------|-----------|
| Android  | ✅        |
| iOS      | 🚧 Coming soon |

## Requirements

- Flutter 3.3.0 or higher
- Android SDK 24 (Android 7.0) or higher
- SATO SmaPri SDK (included)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
