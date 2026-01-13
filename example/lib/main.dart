import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sato_printers/sato_printers.dart';

void main() {
  runApp(const MyApp());
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

    try {
      // Check Bluetooth status first
      final status = await _satoPrinters.checkBluetoothStatus();
      if (!(status['available'] ?? false)) {
        _setStatus('Bluetooth is not available on this device');
        return;
      }
      if (!(status['enabled'] ?? false)) {
        _setStatus('Bluetooth is not enabled. Please enable Bluetooth.');
        return;
      }

      final printers = await _satoPrinters.discoverBluetoothPrinters();
      setState(() {
        _discoveredPrinters = printers;
        _statusMessage = 'Found ${printers.length} Bluetooth device(s)';
      });
    } on SatoBluetoothException catch (e) {
      _setStatus('Bluetooth error: ${e.message}');
    } on SatoPermissionException catch (e) {
      _setStatus('Permission denied: ${e.message}');
    } catch (e) {
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

    try {
      final success = await _satoPrinters.connect(device);
      if (success) {
        setState(() {
          _isConnected = true;
          _connectedDevice = device;
          _statusMessage = 'Connected to ${device.displayName}';
        });
      } else {
        _setStatus('Failed to connect');
      }
    } on SatoConnectionException catch (e) {
      _setStatus('Connection error: ${e.message}');
    } catch (e) {
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

    try {
      final success = await _satoPrinters.connectTcp(ip, port);
      if (success) {
        setState(() {
          _isConnected = true;
          _connectedDevice = PrinterDevice.tcp(ipAddress: ip, port: port);
          _statusMessage = 'Connected to $ip:$port';
        });
      } else {
        _setStatus('Failed to connect');
      }
    } on SatoConnectionException catch (e) {
      _setStatus('Connection error: ${e.message}');
    } catch (e) {
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

    try {
      // Simple SBPL test label command
      // This is a basic example - actual commands depend on your printer model
      final testData = Uint8List.fromList([
        0x02, // STX
        ...('A1').codeUnits,
        0x1B, 0x41, // ESC A - Start format
        ...('V100').codeUnits,
        ...('H100').codeUnits,
        ...('P02').codeUnits,
        ...('L0202').codeUnits,
        ...('TEST LABEL').codeUnits,
        ...('Q1').codeUnits, // Print 1 copy
        ...('Z').codeUnits, // End format
        0x03, // ETX
      ]);

      final result = await _satoPrinters.printRawData(testData);
      if (result.success) {
        _setStatus('Test label printed successfully');
      } else {
        _setStatus('Print failed: ${result.message}');
      }
    } catch (e) {
      _setStatus('Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _getStatus() async {
    if (!_isConnected) {
      _setStatus('Please connect to a printer first');
      return;
    }

    _setLoading(true);
    _setStatus('Getting printer status...');

    try {
      final status = await _satoPrinters.getStatus();
      _setStatus(
        'Status: Connected=${status.isConnected}, '
        'Online=${status.isOnline}, '
        'Ready=${status.isReady}',
      );
    } catch (e) {
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
