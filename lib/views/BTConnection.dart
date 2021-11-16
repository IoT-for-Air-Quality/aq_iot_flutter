import 'dart:async';
import 'dart:convert' show utf8;
import 'dart:typed_data';
import 'package:aq_iot_flutter/models/Device.dart';
import 'package:aq_iot_flutter/services/BluetoothService.dart';
import 'package:aq_iot_flutter/views/ManageDevice.dart';
import 'package:aq_iot_flutter/views/NewDevice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BTConection extends StatefulWidget {
  @override
  _BTConectionSate createState() => new _BTConectionSate();
}

class _BTConectionSate extends State<BTConection> {
  // Initializing the Bluetooth connection state to be unknown
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  // Get the instance of the Bluetooth
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;

  // Track the Bluetooth connection with the remote device
  late BluetoothConnection connection;

  // To track whether the device is still connected to Bluetooth
  bool get isConnected => false;
  // connection != null && connection.isConnected;

  late int _deviceState;

  String id = "";
  String wifiSsid = "";
  String wifiPass = "";
  String ipBroker = "";
  String port = "";

  bool cId = false;
  bool cWifiSsid = false;
  bool cWifiPass = false;
  bool cIpBroker = false;
  bool cPort = false;

  bool mobile = false;
  bool editingInfo = false;
  bool infoUpdated = false;

  bool inRoute = false;
  List<DiscoveredDevice> devices = [];
  DiscoveredDevice? device;
  Stream<DiscoveredDevice> streamDevices = BluetoothService().getDevices();
  StreamSubscription<DiscoveredDevice>? subscription;
  @override
  void initState() {
    super.initState();

    subscription = streamDevices.listen((event) {
      setState(() {
        var contain = devices.where((element) => element.id == event.id);
        if (contain.isEmpty) {
          devices.add(event);
        }
      });
    });
    // .then((value) => debugPrint("$value"));

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    _deviceState = 0; // neutral

    // If the Bluetooth of the device is not enabled,
    // then request permission to turn on Bluetooth
    // as the app starts up
    enableBluetooth();

    // Listen for further state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // For retrieving the paired devices list
        getPairedDevices();
      });
    });
  }

  Future<bool> enableBluetooth() async {
    // Retrieving the current Bluetooth state
    _bluetoothState = await FlutterBluetoothSerial.instance.state;

    // If the Bluetooth is off, then turn it on first
    // and then retrieve the devices that are paired.
    if (_bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
      await getPairedDevices();
      return true;
    } else {
      await getPairedDevices();
    }
    return false;
  }

  List<BluetoothDevice> _devicesList = [];

  Future<void> getPairedDevices() async {
    List<BluetoothDevice> devices = [];

    // To get the list of paired devices
    try {
      devices = await _bluetooth.getBondedDevices();
    } on Exception {
      print("Error");
    }

    // It is an error to call [setState] unless [mounted] is true.
    if (!mounted) {
      return;
    }

    // Store the [devices] list in the [_devicesList] for accessing
    // the list outside this class
    setState(() {
      _devicesList = devices;
    });
  }

  bool isDisconnecting = false;
  bool _isButtonUnavailable = true;

  void _disconnect() async {
    // Closing the Bluetooth connection
    connection.output.add(utf8.encode("EXIT" + "\r\n") as Uint8List);
    // await connection.close();
    //show('Device disconnected');
    setState(() {
      _connected = false;
    });
    // Update the [_connected] variable
    // if (!connection.isConnected) {
    //   setState(() {
    //     _connected = false;
    //   });
    // }
  }

  dynamic getCharacteristicID() async {
    final characteristic = QualifiedCharacteristic(
        serviceId: Uuid.parse("0000180A-0000-1000-8000-00805F9B34FB"),
        characteristicId: Uuid.parse("00002A23-0000-1000-8000-00805F9B34FB"),
        deviceId: device!.id);
    return await BluetoothService().readCharacteristic(characteristic);
  }

  Future<bool> getFullCharacteristics() async {
    //Device type

    nodeSensor.type = await BluetoothService().readCharacteristic(
        QualifiedCharacteristic(
            serviceId: Uuid.parse("0000180A-0000-1000-8000-00805F9B34FB"),
            characteristicId:
                Uuid.parse("00003000-0000-1000-8000-00805F9B34FB"),
            deviceId: device!.id));
    // nodeSensor.swVersion = await BluetoothService().readCharacteristic(
    //     QualifiedCharacteristic(
    //         serviceId: Uuid.parse("0000180A-0000-1000-8000-00805F9B34FB"),
    //         characteristicId:
    //             Uuid.parse("00002A28-0000-1000-8000-00805F9B34FB"),
    //         deviceId: device!.id));

    nodeSensor.lat = double.parse(await BluetoothService().readCharacteristic(
        QualifiedCharacteristic(
            serviceId: Uuid.parse("0000180A-0000-1000-8000-00805F9B34FB"),
            characteristicId:
                Uuid.parse("00002AAE-0000-1000-8000-00805F9B34FB"),
            deviceId: device!.id)));

    nodeSensor.long = double.parse(await BluetoothService().readCharacteristic(
        QualifiedCharacteristic(
            serviceId: Uuid.parse("0000180A-0000-1000-8000-00805F9B34FB"),
            characteristicId:
                Uuid.parse("00002AAF-0000-1000-8000-00805F9B34FB"),
            deviceId: device!.id)));

    nodeSensor.wifiSSID = await BluetoothService().readCharacteristic(
        QualifiedCharacteristic(
            serviceId: Uuid.parse("0000180A-0000-1000-8000-00805F9B34FB"),
            characteristicId:
                Uuid.parse("00003001-0000-1000-8000-00805F9B34FB"),
            deviceId: device!.id));

    return true;
  }

  Device nodeSensor = new Device(
      id: 0,
      lat: 0,
      long: 0,
      type: '',
      organization: 0,
      display: false,
      wifiSSID: '',
      wifiPASS: '',
      swVersion: '');
  void _connect() async {
    if (device == null) {
      return null;
    }
    List<Uuid> characteristics = [];
    characteristics.add(Uuid.parse("00002A23-0000-1000-8000-00805F9B34FB"));
    characteristics.add(Uuid.parse("00002AAE-0000-1000-8000-00805F9B34FB"));
    characteristics.add(Uuid.parse("00002AAF-0000-1000-8000-00805F9B34FB"));
    characteristics.add(Uuid.parse("00002A28-0000-1000-8000-00805F9B34FB"));
    characteristics.add(Uuid.parse("00003000-0000-1000-8000-00805F9B34FB"));
    characteristics.add(Uuid.parse("00003001-0000-1000-8000-00805F9B34FB"));
    characteristics.add(Uuid.parse("00003002-0000-1000-8000-00805F9B34FB"));

    BluetoothService().connectDevice(device!.id, {
      Uuid.parse("0000180A-0000-1000-8000-00805F9B34FB"): characteristics
    }).listen((event) async {
      if (event.connectionState == DeviceConnectionState.connected) {
        debugPrint("ID:");
        nodeSensor.id = int.parse(await getCharacteristicID());
        debugPrint("ID:${nodeSensor.id}");
        if (nodeSensor.id == 0) {
          await subscription!.cancel();
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => NewDevice(device!.id)));
        } else {
          debugPrint("Previous");
          // await getFullCharacteristics();
          await subscription!.cancel();
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ManageDevice(nodeSensor)));
        }
      }
    });

    //{serviceId: [char1, char2]}
    // if (_device == null) {
    //   debugPrint('No device selected');
    // } else {
    //   if (!isConnected) {
    //     // Trying to connect to the device using
    //     // its address
    //     debugPrint("hi");
    //     await BluetoothConnection.toAddress(_device.address)
    //         .then((_connection) {
    //       print('Connected to the device');
    //       connection = _connection;

    //       // Updating the device connectivity
    //       // status to [true]
    //       setState(() {
    //         _connected = true;
    //       });

    //       // This is for tracking when the disconnecting process
    //       // is in progress which uses the [isDisconnecting] variable
    //       // defined before.
    //       // Whenever we make a disconnection call, this [onDone]
    //       // method is fired.
    //       connection.input!.listen(_onDataReceived).onDone(() {
    //         if (isDisconnecting) {
    //           print('Disconnecting locally!');
    //         } else {
    //           print('Disconnected remotely!');
    //         }
    //         if (this.mounted) {
    //           setState(() {});
    //         }
    //       });
    //     }).catchError((error) {
    //       print('Cannot connect, exception occurred');
    //       print(error);
    //     });
    //     debugPrint('Device connected');
    //     connection.output.add(utf8.encode("HELLO" + "\r\n") as Uint8List);
    //   }
    // }
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    debugPrint("$dataString");

    var dd = dataString.split("\r\n");
    for (var d in dd) {
      if (d == "OK") {
        setState(() {
          infoUpdated = true;
        });
      }

      var info = d.split(":");

      debugPrint("$info");
      if (info[0] == "ID") {
        setState(() {
          debugPrint(info[1]);
          id = info[1];
        });
      }
      if (info[0] == "WIFI-SSID") {
        setState(() {
          wifiSsid = info[1];
        });
      }
      if (info[0] == "WIFI-PASS") {
        setState(() {
          wifiPass = info[1];
        });
      }
      if (info[0] == "IP-BROKER") {
        setState(() {
          ipBroker = info[1];
        });
      }
      if (info[0] == "PORT") {
        setState(() {
          port = info[1];
        });
      }
      if (info[0] == "MOBILE") {
        setState(() {
          mobile = info[1] == "1" ? true : false;
        });
      }
    }
  }

  @override
  void dispose() {
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      //connection = null;
    }

    super.dispose();
  }

  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    debugPrint("$_device");
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devicesList.isEmpty) {
      items.add(DropdownMenuItem(
        child: Text('NONE'),
      ));
    } else {
      _devicesList.forEach((device) {
        items.add(DropdownMenuItem(
          child: Text("${device.name}"),
          value: device,
        ));
      });
    }
    return items;
  }

  void changeToMobile() {
    setState(() {
      mobile = true;
    });

    connection.output.add(utf8.encode("MOBILE\r\n") as Uint8List);
  }

  void changeToStatic() {
    setState(() {
      mobile = false;
    });

    connection.output.add(utf8.encode("STATIC\r\n") as Uint8List);
  }

  void editInfo() {
    setState(() {
      editingInfo = true;
    });
  }

  void cancelEdit() {
    setState(() {
      editingInfo = false;
    });
  }

  void startRoute() {
    setState(() {
      inRoute = true;
    });
  }

  refresh() {
    setState(() {
      infoUpdated = false;
    });
    connection.output.add(utf8.encode("HELLO" + "\r\n") as Uint8List);
  }

  finish() {
    connection.output.add(utf8.encode("EXIT" + "\r\n") as Uint8List);
  }

  restartDevice() {
    connection.output.add(utf8.encode("RESTART" + "\r\n") as Uint8List);
  }

  updateInfo() {
    setState(() {
      infoUpdated = false;
    });
    if (cId) connection.output.add(utf8.encode(id + ":ID\r\n") as Uint8List);
    if (cWifiSsid)
      connection.output
          .add(utf8.encode(wifiSsid + ":WIFI-SSID\r\n") as Uint8List);
    if (cWifiPass)
      connection.output
          .add(utf8.encode(wifiPass + ":WIFI-PASS\r\n") as Uint8List);
    if (cIpBroker)
      connection.output.add(utf8.encode(id + ":IP\r\n") as Uint8List);
    if (cPort)
      connection.output.add(utf8.encode(id + ":PORT\r\n") as Uint8List);

    setState(() {
      cId = false;
      cWifiSsid = false;
      cWifiPass = false;
      cIpBroker = false;
      cPort = false;
    });
    // connection.output.add(utf8.encode("WIFI-SSID:" + id + "\r\n") as Uint8List);
    cancelEdit();
  }

  bool _connected = false;
  late BluetoothDevice _device = BluetoothDevice(address: "");
  @override
  Widget build(BuildContext context) {
    return Container(
      child: devices == []
          ? Container()
          : Container(
              height: 150,
              margin: const EdgeInsets.all(10.0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xfffcf4bf),
                border: Border.all(
                  color: Colors.black,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text("Bluetooth"),
                      Switch(
                        value: _bluetoothState.isEnabled,
                        onChanged: (bool value) {
                          future() async {
                            if (value) {
                              // Enable Bluetooth
                              await FlutterBluetoothSerial.instance
                                  .requestEnable();
                            } else {
                              // Disable Bluetooth
                              await FlutterBluetoothSerial.instance
                                  .requestDisable();
                            }

                            // In order to update the devices list
                            await getPairedDevices();
                            _isButtonUnavailable = false;

                            // Disconnect from any device before
                            // turning off Bluetooth
                            if (_connected) {
                              _disconnect();
                            }
                          }

                          future().then((_) {
                            setState(() {});
                          });
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      DropdownButton<DiscoveredDevice>(
                          items: devices
                              .map<DropdownMenuItem<DiscoveredDevice>>(
                                  (DiscoveredDevice value) {
                            return DropdownMenuItem<DiscoveredDevice>(
                              value: value,
                              child: value.name == ''
                                  ? Text("${value.id}")
                                  : Text("${value.name}"),
                            );
                          }).toList(),
                          value: device,
                          onChanged: (value) => setState(() => device = value)),
                      ElevatedButton(
                        onPressed: _connect,
                        child: Text('Connect'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
