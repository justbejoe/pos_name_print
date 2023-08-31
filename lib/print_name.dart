import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class PrintNameApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Print Name App',
      home: PrintNameScreen(),
    );
  }
}

class PrintNameScreen extends StatefulWidget {
  @override
  _PrintNameScreenState createState() => _PrintNameScreenState();
}

class _PrintNameScreenState extends State<PrintNameScreen> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? selectedDevice;
  List<BluetoothService> services = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Print Name App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Select a Bluetooth Printer:'),
            StreamBuilder<List<ScanResult>>(
              stream: FlutterBlue.instance.scanResults,
              initialData: [],
              builder: (context, snapshot) {
                return Column(
                  children: snapshot.data!.map((result) {
                    return ListTile(
                      title: Text(result.device.name),
                      subtitle: Text(result.device.id.toString()),
                      onTap: () async {
                        selectedDevice = result.device;
                        await result.device.connect();
                        services = await result.device.discoverServices();
                        setState(() {});
                      },
                    );
                  }).toList(),
                );
              },
            ),
            ElevatedButton(
              onPressed: selectedDevice != null ? _printName : null,
              child: Text('Print My Name'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printName() async {
    if (selectedDevice == null) return;
    final BluetoothCharacteristic? characteristic =
        _findPrintCharacteristic(services);
    if (characteristic == null) {
      print('Print characteristic not found.');
      return;
    }
    // Your name to be printed
    final String name = 'Your Name';
    // Send print commands with different font sizes
    final List<int> command1 = utf8.encode('$name\n');
    final List<int> command2 = utf8.encode('\x1B\x21\x10$name\n');
    final List<int> command3 = utf8.encode('\x1B\x21\x20$name\n');
    final List<int> command4 = utf8.encode('\x1B\x21\x30$name\n');
    await characteristic.write(command1);
    await characteristic.write(command2);
    await characteristic.write(command3);
    await characteristic.write(command4);
    print('Name printed successfully.');
  }

  BluetoothCharacteristic? _findPrintCharacteristic(
      List<BluetoothService> services) {
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (characteristic.properties.write) {
          return characteristic;
        }
      }
    }
    return null;
  }
}
