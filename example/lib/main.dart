import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sato_printers/sato_printers.dart';

import 'zpl_converter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SATO ZPL Example',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
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
  final SatoPrinters _satoPrinters = SatoPrinters();
  final ImagePicker _imagePicker = ImagePicker();
  final ZplConverter _zplConverter = ZplConverter();
  final TextEditingController _tcpIpController = TextEditingController(
    text: '192.168.1.110',
  );
  final TextEditingController _tcpPortController = TextEditingController(
    text: '9100',
  );

  List<PrinterDevice> _printers = <PrinterDevice>[];
  PrinterDevice? _selectedPrinter;

  Uint8List? _imageBytes;
  String? _zpl;

  bool _isDiscovering = false;
  bool _isConnecting = false;
  bool _isPrinting = false;
  bool _isConnected = false;
  bool _compressHex = true;
  int _blacknessPercent = 50;

  @override
  void initState() {
    super.initState();
    _applyConverterOptions();
  }

  @override
  void dispose() {
    _tcpIpController.dispose();
    _tcpPortController.dispose();
    super.dispose();
  }

  void _applyConverterOptions() {
    _zplConverter.setCompressHex(_compressHex);
    _zplConverter.setBlacknessLimitPercentage(_blacknessPercent);
  }

  Future<void> _discoverPrinters() async {
    setState(() {
      _isDiscovering = true;
    });

    try {
      final bluetooth = await _satoPrinters.discoverBluetoothPrinters();
      final usb = await _satoPrinters.discoverUsbPrinters();

      final allPrinters = <PrinterDevice>{...bluetooth, ...usb}.toList();

      if (!mounted) return;
      setState(() {
        _printers = allPrinters;
        _selectedPrinter = allPrinters.contains(_selectedPrinter)
            ? _selectedPrinter
            : (allPrinters.isNotEmpty ? allPrinters.first : null);
      });

      _showMessage('Found ${allPrinters.length} printer(s).');
    } on SatoException catch (e) {
      _showMessage('Discovery error: ${e.message}');
    } catch (e) {
      _showMessage('Discovery error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isDiscovering = false;
        });
      }
    }
  }

  Future<void> _connect() async {
    final printer = _selectedPrinter;
    if (printer == null) {
      _showMessage('Select a printer first.');
      return;
    }

    setState(() {
      _isConnecting = true;
    });

    try {
      final success = await _satoPrinters.connect(printer);
      if (!mounted) return;
      setState(() {
        _isConnected = success;
      });

      _showMessage(
        success ? 'Connected to ${printer.displayName}.' : 'Connection failed.',
      );
    } on SatoException catch (e) {
      _showMessage('Connection error: ${e.message}');
    } catch (e) {
      _showMessage('Connection error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  Future<void> _disconnect() async {
    try {
      final success = await _satoPrinters.disconnect();
      if (!mounted) return;
      setState(() {
        _isConnected = !success ? _isConnected : false;
      });
      _showMessage(success ? 'Disconnected.' : 'Could not disconnect.');
    } on SatoException catch (e) {
      _showMessage('Disconnect error: ${e.message}');
    } catch (e) {
      _showMessage('Disconnect error: $e');
    }
  }

  Future<void> _connectTcp() async {
    final ip = _tcpIpController.text.trim();
    final port = int.tryParse(_tcpPortController.text.trim());

    if (ip.isEmpty) {
      _showMessage('Enter a TCP/IP address.');
      return;
    }
    if (port == null || port < 1 || port > 65535) {
      _showMessage('Enter a valid TCP port (1-65535).');
      return;
    }

    setState(() {
      _isConnecting = true;
    });

    try {
      final success = await _satoPrinters.connectTcp(ip, port);
      if (!mounted) return;
      setState(() {
        _isConnected = success;
      });
      _showMessage(
        success ? 'Connected to $ip:$port.' : 'TCP/IP connection failed.',
      );
    } on SatoException catch (e) {
      _showMessage('TCP/IP connection error: ${e.message}');
    } catch (e) {
      _showMessage('TCP/IP connection error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  Future<void> _pickImageAndConvert() async {
    try {
      final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        return;
      }

      final bytes = await picked.readAsBytes();

      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
      });

      await _convertCurrentImageToZpl();
    } catch (e) {
      _showMessage('Image selection failed: $e');
    }
  }

  Future<void> _convertCurrentImageToZpl() async {
    final bytes = _imageBytes;
    if (bytes == null) {
      _showMessage('Pick an image first.');
      return;
    }

    _applyConverterOptions();
    String zpl;
    try {
      zpl = _zplConverter.convertFromImage(bytes, addHeaderFooter: true);
    } on ArgumentError catch (e) {
      _showMessage(e.message?.toString() ?? 'Could not decode the image.');
      return;
    }

    if (!mounted) return;
    setState(() {
      _zpl = zpl;
    });

    _showMessage('Image converted to ZPL (${zpl.length} chars).');
  }

  Future<void> _sendToPrinter() async {
    if (!_isConnected) {
      _showMessage('Connect to a printer first.');
      return;
    }

    final zpl = _zpl;
    if (zpl == null || zpl.isEmpty) {
      _showMessage('Pick and convert an image first.');
      return;
    }

    setState(() {
      _isPrinting = true;
    });

    try {
      final bytes = Uint8List.fromList(utf8.encode(zpl));
      final result = await _satoPrinters.printRawData(bytes);
      _showMessage(
        result.success
            ? 'Print command sent successfully.'
            : 'Print failed: ${result.message ?? 'Unknown error'}',
      );
    } on SatoException catch (e) {
      _showMessage('Print error: ${e.message}');
    } catch (e) {
      _showMessage('Print error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SATO Printer ZPL Example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Connection', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isDiscovering ? null : _discoverPrinters,
                  icon: const Icon(Icons.search),
                  label: Text(
                    _isDiscovering ? 'Discovering...' : 'Discover Printers',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<PrinterDevice>(
            initialValue: _selectedPrinter,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Printer',
            ),
            items: _printers
                .map(
                  (printer) => DropdownMenuItem<PrinterDevice>(
                    value: printer,
                    child: Text(
                      '${printer.displayName} (${printer.connectionType.name.toUpperCase()})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedPrinter = value;
              });
            },
          ),
          const SizedBox(height: 8),
          Text('TCP/IP', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _tcpIpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'IP Address',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _tcpPortController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Port',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: _isConnecting ? null : _connectTcp,
              icon: const Icon(Icons.lan),
              label: const Text('Connect TCP/IP'),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: _isConnecting ? null : _connect,
                child: Text(_isConnecting ? 'Connecting...' : 'Connect'),
              ),
              OutlinedButton(
                onPressed: _isConnected ? _disconnect : null,
                child: const Text('Disconnect'),
              ),
              Chip(
                label: Text(_isConnected ? 'Connected' : 'Disconnected'),
                avatar: Icon(
                  _isConnected ? Icons.check_circle : Icons.cancel,
                  size: 18,
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          Text(
            'Image & Conversion',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _pickImageAndConvert,
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload Image'),
          ),
          if (_imageBytes != null) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: Image.memory(_imageBytes!, fit: BoxFit.contain),
            ),
          ],
          const SizedBox(height: 12),
          SwitchListTile(
            value: _compressHex,
            title: const Text('Compress ZPL Hex'),
            onChanged: (value) {
              setState(() {
                _compressHex = value;
              });
            },
          ),
          Text('Blackness threshold: $_blacknessPercent%'),
          Slider(
            value: _blacknessPercent.toDouble(),
            min: 1,
            max: 100,
            divisions: 99,
            label: '$_blacknessPercent%',
            onChanged: (value) {
              setState(() {
                _blacknessPercent = value.round();
              });
            },
            onChangeEnd: (_) {
              if (_imageBytes != null) {
                _convertCurrentImageToZpl();
              }
            },
          ),
          Row(
            children: [
              ElevatedButton(
                onPressed: _imageBytes == null
                    ? null
                    : _convertCurrentImageToZpl,
                child: const Text('Rebuild ZPL'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _zpl == null
                      ? 'No ZPL generated yet.'
                      : 'ZPL length: ${_zpl!.length}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_zpl != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: SelectableText(
                _zpl!.length > 500 ? '${_zpl!.substring(0, 500)}...' : _zpl!,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          const Divider(height: 32),
          ElevatedButton.icon(
            onPressed: _isPrinting ? null : _sendToPrinter,
            icon: const Icon(Icons.print),
            label: Text(_isPrinting ? 'Sending...' : 'Send ZPL to Printer'),
          ),
        ],
      ),
    );
  }
}
