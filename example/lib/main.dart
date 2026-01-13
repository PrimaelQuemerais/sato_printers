import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sato_printers/sato_printers.dart';

void main() {
  runApp(const MyApp());
}

/// Logger utility for consistent logging throughout the app
class PrinterLogger {
  static const String _tag = 'SatoPrinters';

  static void info(String message) {
    developer.log(message, name: _tag, level: 800);
    debugPrint('[$_tag] INFO: $message');
  }

  static void debug(String message) {
    developer.log(message, name: _tag, level: 500);
    debugPrint('[$_tag] DEBUG: $message');
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _tag,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
    debugPrint('[$_tag] ERROR: $message');
    if (error != null) {
      debugPrint('[$_tag] ERROR Details: $error');
    }
    if (stackTrace != null) {
      debugPrint('[$_tag] StackTrace: $stackTrace');
    }
  }

  static void data(String label, Uint8List data) {
    final hexString = data
        .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
    final asciiString = String.fromCharCodes(
      data.map(
        (b) => (b >= 32 && b <= 126) ? b : 46,
      ), // Replace non-printable with '.'
    );
    debug('$label:');
    debug('  HEX: $hexString');
    debug('  ASCII: $asciiString');
    debug('  Length: ${data.length} bytes');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SATO Printers Example',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const PrinterScreen(),
    );
  }
}

class PrinterScreen extends StatefulWidget {
  const PrinterScreen({super.key});

  @override
  State<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends State<PrinterScreen> {
  final _satoPrinters = SatoPrinters();

  String _platformVersion = 'Unknown';
  List<PrinterDevice> _discoveredPrinters = [];
  PrinterDevice? _connectedDevice;
  bool _isConnected = false;
  bool _isLoading = false;
  String _statusMessage = '';

  // TCP connection fields
  final _ipController = TextEditingController(text: '192.168.1.1');
  final _portController = TextEditingController(text: '9100');

  @override
  void initState() {
    super.initState();
    _initPlatformState();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _satoPrinters.disconnect();
    super.dispose();
  }

  Future<void> _initPlatformState() async {
    try {
      final version = await _satoPrinters.getPlatformVersion() ?? 'Unknown';
      setState(() => _platformVersion = version);
    } on PlatformException {
      setState(() => _platformVersion = 'Failed to get platform version');
    }
  }

  void _setLoading(bool loading) {
    setState(() => _isLoading = loading);
  }

  void _setStatus(String message) {
    setState(() => _statusMessage = message);
  }

  Future<void> _discoverBluetoothPrinters() async {
    _setLoading(true);
    _setStatus('Discovering Bluetooth printers...');
    PrinterLogger.info('Starting Bluetooth printer discovery...');

    try {
      // Check Bluetooth status first
      final status = await _satoPrinters.checkBluetoothStatus();
      PrinterLogger.debug('Bluetooth status: $status');

      if (!(status['available'] ?? false)) {
        PrinterLogger.error('Bluetooth is not available on this device');
        _setStatus('Bluetooth is not available on this device');
        return;
      }
      if (!(status['enabled'] ?? false)) {
        PrinterLogger.error('Bluetooth is not enabled');
        _setStatus('Bluetooth is not enabled. Please enable Bluetooth.');
        return;
      }

      final printers = await _satoPrinters.discoverBluetoothPrinters();
      PrinterLogger.info('Found ${printers.length} Bluetooth device(s)');
      for (final printer in printers) {
        PrinterLogger.debug('  - ${printer.displayName} (${printer.address})');
      }

      setState(() {
        _discoveredPrinters = printers;
        _statusMessage = 'Found ${printers.length} Bluetooth device(s)';
      });
    } on SatoBluetoothException catch (e, stackTrace) {
      PrinterLogger.error('Bluetooth exception', e, stackTrace);
      _setStatus('Bluetooth error: ${e.message}');
    } on SatoPermissionException catch (e, stackTrace) {
      PrinterLogger.error('Permission exception', e, stackTrace);
      _setStatus('Permission denied: ${e.message}');
    } catch (e, stackTrace) {
      PrinterLogger.error('Unexpected error during discovery', e, stackTrace);
      _setStatus('Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _discoverUsbPrinters() async {
    _setLoading(true);
    _setStatus('Discovering USB printers...');

    try {
      final printers = await _satoPrinters.discoverUsbPrinters();
      setState(() {
        _discoveredPrinters = printers;
        _statusMessage = 'Found ${printers.length} USB printer(s)';
      });
    } catch (e) {
      _setStatus('Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _connectToDevice(PrinterDevice device) async {
    _setLoading(true);
    _setStatus('Connecting to ${device.displayName}...');
    PrinterLogger.info('Connecting to device: ${device.displayName}');
    PrinterLogger.debug('  Address: ${device.address}');
    PrinterLogger.debug('  Connection type: ${device.connectionType}');

    try {
      final success = await _satoPrinters.connect(device);
      PrinterLogger.info('Connection result: $success');

      if (success) {
        setState(() {
          _isConnected = true;
          _connectedDevice = device;
          _statusMessage = 'Connected to ${device.displayName}';
        });
        PrinterLogger.info('Successfully connected to ${device.displayName}');
      } else {
        PrinterLogger.error('Failed to connect - returned false');
        _setStatus('Failed to connect');
      }
    } on SatoConnectionException catch (e, stackTrace) {
      PrinterLogger.error('Connection exception', e, stackTrace);
      _setStatus('Connection error: ${e.message}');
    } catch (e, stackTrace) {
      PrinterLogger.error('Unexpected error during connection', e, stackTrace);
      _setStatus('Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _connectTcp() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 9100;

    if (ip.isEmpty) {
      _setStatus('Please enter an IP address');
      return;
    }

    _setLoading(true);
    _setStatus('Connecting to $ip:$port...');
    PrinterLogger.info('Connecting via TCP to $ip:$port...');

    try {
      final success = await _satoPrinters.connectTcp(ip, port);
      PrinterLogger.info('TCP connection result: $success');

      if (success) {
        setState(() {
          _isConnected = true;
          _connectedDevice = PrinterDevice.tcp(ipAddress: ip, port: port);
          _statusMessage = 'Connected to $ip:$port';
        });
        PrinterLogger.info('Successfully connected to $ip:$port');
      } else {
        PrinterLogger.error('TCP connection failed - returned false');
        _setStatus('Failed to connect');
      }
    } on SatoConnectionException catch (e, stackTrace) {
      PrinterLogger.error('TCP connection exception', e, stackTrace);
      _setStatus('Connection error: ${e.message}');
    } catch (e, stackTrace) {
      PrinterLogger.error(
        'Unexpected error during TCP connection',
        e,
        stackTrace,
      );
      _setStatus('Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _disconnect() async {
    _setLoading(true);
    _setStatus('Disconnecting...');

    try {
      await _satoPrinters.disconnect();
      setState(() {
        _isConnected = false;
        _connectedDevice = null;
        _statusMessage = 'Disconnected';
      });
    } catch (e) {
      _setStatus('Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _printTestLabel() async {
    if (!_isConnected) {
      _setStatus('Please connect to a printer first');
      return;
    }

    _setLoading(true);
    _setStatus('Printing test label...');
    PrinterLogger.info('Starting print test label operation...');

    try {
      // Build a proper SBPL (SATO Barcode Printer Language) command
      // SBPL uses ESC (0x1B) as command prefix
      // Format: <STX><ESC>A<CR> - Start of label format
      //         ... field definitions ...
      //         <ESC>Q<quantity><CR> - Print command
      //         <ESC>Z<CR> - End of label format
      //         <ETX>

      final sbplCommand = _buildSbplTestLabel();
      final testData = Uint8List.fromList(sbplCommand.codeUnits);

      PrinterLogger.info('SBPL Command built successfully');
      PrinterLogger.debug('Command string:\n$sbplCommand');
      PrinterLogger.data('Raw SBPL data', testData);

      PrinterLogger.info('Sending data to printer...');
      final result = await _satoPrinters.printRawData(testData);

      PrinterLogger.info('Print result received:');
      PrinterLogger.debug('  Success: ${result.success}');
      PrinterLogger.debug('  Message: ${result.message}');
      if (result.responseData != null) {
        PrinterLogger.data('Response data', result.responseData!);
      }

      if (result.success) {
        PrinterLogger.info('Test label printed successfully');
        _setStatus('Test label printed successfully');
      } else {
        PrinterLogger.error('Print failed: ${result.message}');
        _setStatus('Print failed: ${result.message}');
      }
    } catch (e, stackTrace) {
      PrinterLogger.error('Error during print operation', e, stackTrace);
      _setStatus('Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Builds a proper SBPL test label command.
  ///
  /// SBPL Command Reference:
  /// - STX (0x02): Start of transmission
  /// - ESC A: Start label format mode
  /// - ESC V: Vertical position (in dots from top)
  /// - ESC H: Horizontal position (in dots from left)
  /// - ESC P or ESC L####: Font selection
  /// - Text data followed by CR
  /// - ESC Q: Print quantity
  /// - ESC Z: End label format
  /// - ETX (0x03): End of transmission
  String _buildSbplTestLabel() {
    const stx = '\x02'; // Start of text
    const etx = '\x03'; // End of text
    const esc = '\x1B'; // Escape
    const cr = '\x0D'; // Carriage return (line terminator for SBPL)

    final buffer = StringBuffer();

    // Start of transmission
    buffer.write(stx);

    // Start label format
    buffer.write('${esc}A$cr');

    // Set print speed (optional, 2 = medium speed)
    buffer.write('${esc}CS2$cr');

    // Set print darkness/heat (optional, H10 = medium heat)
    buffer.write('${esc}H10$cr');

    // First text field: "SATO TEST LABEL"
    // Using alternative L#### syntax (L0202 = bitmap font type 2, size 2)
    // Position: V0100 = 100 dots from top, H0100 = 100 dots from left
    buffer.write('${esc}V0100$cr'); // Vertical position
    buffer.write('${esc}H0100$cr'); // Horizontal position
    buffer.write('${esc}L0202$cr'); // Font: bitmap type 2, size 2
    buffer.write('SATO TEST LABEL$cr'); // Text data

    // Second text field: Date/time stamp
    buffer.write('${esc}V0180$cr'); // Vertical position
    buffer.write('${esc}H0100$cr'); // Horizontal position
    buffer.write('${esc}L0101$cr'); // Smaller font
    buffer.write('Printed: ${DateTime.now().toString().substring(0, 19)}$cr');

    // Third text field: Additional info
    buffer.write('${esc}V0250$cr');
    buffer.write('${esc}H0100$cr');
    buffer.write('${esc}L0101$cr');
    buffer.write('Flutter SATO Plugin v1.0$cr');

    // Print 1 copy
    buffer.write('${esc}Q1$cr');

    // End label format
    buffer.write('${esc}Z$cr');

    // End of transmission
    buffer.write(etx);

    return buffer.toString();
  }

  Future<void> _getStatus() async {
    if (!_isConnected) {
      _setStatus('Please connect to a printer first');
      return;
    }

    _setLoading(true);
    _setStatus('Getting printer status...');
    PrinterLogger.info('Requesting printer status...');

    try {
      final status = await _satoPrinters.getStatus();
      PrinterLogger.info('Printer status received:');
      PrinterLogger.debug('  Connected: ${status.isConnected}');
      PrinterLogger.debug('  Online: ${status.isOnline}');
      PrinterLogger.debug('  Ready: ${status.isReady}');
      PrinterLogger.debug('  Paper out: ${status.isPaperOut}');
      PrinterLogger.debug('  Ribbon out: ${status.isRibbonOut}');
      PrinterLogger.debug('  Cover open: ${status.isCoverOpen}');
      PrinterLogger.debug('  Has error: ${status.hasError}');
      if (status.errorMessage != null) {
        PrinterLogger.debug('  Error message: ${status.errorMessage}');
      }

      _setStatus(
        'Status: Connected=${status.isConnected}, '
        'Online=${status.isOnline}, '
        'Ready=${status.isReady}',
      );
    } catch (e, stackTrace) {
      PrinterLogger.error('Error getting printer status', e, stackTrace);
      _setStatus('Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Prints a minimal test label (simpler command for debugging).
  Future<void> _printMinimalTestLabel() async {
    if (!_isConnected) {
      _setStatus('Please connect to a printer first');
      return;
    }

    _setLoading(true);
    _setStatus('Printing minimal test label...');
    PrinterLogger.info('Starting minimal test label print...');

    try {
      // Minimal SBPL command - just text
      const stx = '\x02';
      const etx = '\x03';
      const esc = '\x1B';
      const cr = '\x0D';

      final command =
          '$stx${esc}A$cr${esc}V0050$cr${esc}H0050$cr${esc}P2$cr${esc}LTEST$cr${esc}Q1$cr${esc}Z$cr$etx';
      final testData = Uint8List.fromList(command.codeUnits);

      PrinterLogger.debug(
        'Minimal command: ${command.replaceAll('\x02', '<STX>').replaceAll('\x03', '<ETX>').replaceAll('\x1B', '<ESC>').replaceAll('\x0D', '<CR>')}',
      );
      PrinterLogger.data('Minimal SBPL data', testData);

      final result = await _satoPrinters.printRawData(testData);

      PrinterLogger.info(
        'Minimal print result: success=${result.success}, message=${result.message}',
      );

      if (result.success) {
        _setStatus('Minimal test label printed');
      } else {
        _setStatus('Print failed: ${result.message}');
      }
    } catch (e, stackTrace) {
      PrinterLogger.error('Error during minimal print', e, stackTrace);
      _setStatus('Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Prints the simplest possible label using raw bytes.
  /// This is useful for debugging to ensure the printer responds to any data.
  Future<void> _printSimplestLabel() async {
    if (!_isConnected) {
      _setStatus('Please connect to a printer first');
      return;
    }

    _setLoading(true);
    _setStatus('Printing simplest label (raw bytes)...');
    PrinterLogger.info('Starting simplest test label print with raw bytes...');

    try {
      // Build raw SBPL bytes manually (most compatible format)
      // Format based on SATO SBPL documentation:
      // <STX> <ESC>A <fields...> <ESC>Qn <ESC>Z <ETX>

      final List<int> rawBytes = [
        0x02, // STX - Start of Text
        0x1B, 0x41, // ESC A - Start label format
        0x0D, // CR - Command terminator
        // Position and text field
        0x1B,
        0x56,
        0x30,
        0x30,
        0x35,
        0x30, // ESC V0050 - Vertical position (50 dots)
        0x0D,
        0x1B,
        0x48,
        0x30,
        0x30,
        0x35,
        0x30, // ESC H0050 - Horizontal position (50 dots)
        0x0D,
        0x1B, 0x4C, // ESC L - Label data command
        0x54, 0x45, 0x53, 0x54, // "TEST"
        0x0D,

        // Print quantity
        0x1B, 0x51, 0x31, // ESC Q1 - Print 1 copy
        0x0D,

        // End label format
        0x1B, 0x5A, // ESC Z - End label format
        0x0D,

        0x03, // ETX - End of Text
      ];

      final testData = Uint8List.fromList(rawBytes);

      PrinterLogger.debug('Raw bytes command description:');
      PrinterLogger.debug('  STX ESC A CR');
      PrinterLogger.debug('  ESC V0050 CR (Vertical position 50 dots)');
      PrinterLogger.debug('  ESC H0050 CR (Horizontal position 50 dots)');
      PrinterLogger.debug('  ESC L TEST CR (Label data)');
      PrinterLogger.debug('  ESC Q1 CR (Print 1 copy)');
      PrinterLogger.debug('  ESC Z CR ETX');
      PrinterLogger.data('Simplest SBPL raw bytes', testData);

      final result = await _satoPrinters.printRawData(testData);

      PrinterLogger.info(
        'Simplest print result: success=${result.success}, message=${result.message}',
      );
      if (result.responseData != null && result.responseData!.isNotEmpty) {
        PrinterLogger.data('Printer response', result.responseData!);
      }

      if (result.success) {
        _setStatus('Simplest test label printed');
      } else {
        _setStatus('Print failed: ${result.message}');
      }
    } catch (e, stackTrace) {
      PrinterLogger.error('Error during simplest print', e, stackTrace);
      _setStatus('Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Sends a printer initialization/reset command.
  /// This can help clear any error states and prepare the printer.
  Future<void> _initializePrinter() async {
    if (!_isConnected) {
      _setStatus('Please connect to a printer first');
      return;
    }

    _setLoading(true);
    _setStatus('Initializing printer...');
    PrinterLogger.info('Sending printer initialization command...');

    try {
      // Send ESC AR (Reset) command
      const esc = 0x1B;
      const cr = 0x0D;

      final List<int> resetCommand = [
        esc, 0x41, 0x52, cr, // ESC AR - Reset printer
      ];

      final testData = Uint8List.fromList(resetCommand);
      PrinterLogger.data('Reset command', testData);

      final result = await _satoPrinters.printRawData(testData);

      PrinterLogger.info('Reset result: success=${result.success}');

      if (result.success) {
        _setStatus('Printer initialized - try printing now');
      } else {
        _setStatus('Initialize failed: ${result.message}');
      }
    } catch (e, stackTrace) {
      PrinterLogger.error('Error during initialization', e, stackTrace);
      _setStatus('Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Prints a label with explicit label size definition.
  /// Some SATO printers require the label dimensions to be specified.
  Future<void> _printWithLabelSize() async {
    if (!_isConnected) {
      _setStatus('Please connect to a printer first');
      return;
    }

    _setLoading(true);
    _setStatus('Printing with label size...');
    PrinterLogger.info('Starting print with label size definition...');

    try {
      const stx = '\x02';
      const etx = '\x03';
      const esc = '\x1B';
      const cr = '\x0D';

      final buffer = StringBuffer();

      // Start of transmission
      buffer.write(stx);

      // Start label format
      buffer.write('${esc}A$cr');

      // Define label size: ESC A3 H#### V#### (Horizontal x Vertical in dots)
      // Common label: 4" x 3" at 203 DPI = ~812 x 609 dots
      // Let's use a smaller size for testing: 400 x 300 dots
      buffer.write('${esc}A3H0400V0300$cr');

      // Set print speed (2 = medium)
      buffer.write('${esc}CS2$cr');

      // Set heat/darkness (H10 = medium heat)
      buffer.write('${esc}H10$cr');

      // Text field
      buffer.write('${esc}V0050$cr'); // Vertical position
      buffer.write('${esc}H0050$cr'); // Horizontal position
      buffer.write('${esc}L0202$cr'); // Font selection (alternative syntax)
      buffer.write('TEST WITH SIZE$cr');

      // Print 1 copy
      buffer.write('${esc}Q1$cr');

      // End label format
      buffer.write('${esc}Z$cr');

      // End of transmission
      buffer.write(etx);

      final command = buffer.toString();
      final testData = Uint8List.fromList(command.codeUnits);

      PrinterLogger.debug('Command with label size:\n$command');
      PrinterLogger.data('Label size SBPL data', testData);

      final result = await _satoPrinters.printRawData(testData);

      PrinterLogger.info('Print with size result: success=${result.success}');

      if (result.success) {
        _setStatus('Label with size sent');
      } else {
        _setStatus('Print failed: ${result.message}');
      }
    } catch (e, stackTrace) {
      PrinterLogger.error('Error during print with size', e, stackTrace);
      _setStatus('Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SATO Printers'),
        actions: [
          if (_isConnected)
            IconButton(
              icon: const Icon(Icons.power_settings_new),
              onPressed: _disconnect,
              tooltip: 'Disconnect',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Platform info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Running on: $_platformVersion'),
              ),
            ),
            const SizedBox(height: 16),

            // Status message
            if (_statusMessage.isNotEmpty)
              Card(
                color: _isConnected ? Colors.green[50] : Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      Expanded(child: Text(_statusMessage)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Discovery section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Discover Printers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : _discoverBluetoothPrinters,
                            icon: const Icon(Icons.bluetooth),
                            label: const Text('Bluetooth'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _discoverUsbPrinters,
                            icon: const Icon(Icons.usb),
                            label: const Text('USB'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // TCP Connection section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TCP/IP Connection',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _ipController,
                            decoration: const InputDecoration(
                              labelText: 'IP Address',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _portController,
                            decoration: const InputDecoration(
                              labelText: 'Port',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading || _isConnected
                            ? null
                            : _connectTcp,
                        icon: const Icon(Icons.lan),
                        label: const Text('Connect TCP/IP'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Discovered printers list
            if (_discoveredPrinters.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Discovered Printers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(_discoveredPrinters.length, (index) {
                        final printer = _discoveredPrinters[index];
                        return ListTile(
                          leading: Icon(
                            printer.connectionType == ConnectionType.bluetooth
                                ? Icons.bluetooth
                                : Icons.usb,
                          ),
                          title: Text(printer.displayName),
                          subtitle: Text(printer.address),
                          trailing: ElevatedButton(
                            onPressed: _isLoading || _isConnected
                                ? null
                                : () => _connectToDevice(printer),
                            child: const Text('Connect'),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Connected device actions
            if (_isConnected)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connected: ${_connectedDevice?.displayName ?? "Unknown"}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _printTestLabel,
                              icon: const Icon(Icons.print),
                              label: const Text('Print Test'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _getStatus,
                              icon: const Icon(Icons.info_outline),
                              label: const Text('Status'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : _printMinimalTestLabel,
                              icon: const Icon(Icons.bug_report),
                              label: const Text('Minimal Test'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : _printSimplestLabel,
                              icon: const Icon(Icons.science),
                              label: const Text('Simplest'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _initializePrinter,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Init Printer'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : _printWithLabelSize,
                              icon: const Icon(Icons.aspect_ratio),
                              label: const Text('With Size'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _disconnect,
                          icon: const Icon(Icons.power_settings_new),
                          label: const Text('Disconnect'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
