import 'dart:async';
import 'dart:convert' show utf8;
import 'dart:typed_data';
import 'package:aq_iot_flutter/models/Device.dart';
import 'package:aq_iot_flutter/models/RouteDevice.dart';
import 'package:aq_iot_flutter/services/BluetoothService.dart';
import 'package:aq_iot_flutter/views/CurrentInfo.dart';
import 'package:aq_iot_flutter/views/HistoricData.dart';
import 'package:aq_iot_flutter/views/Route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'Route.dart';

class ManageDevice extends StatefulWidget {
  final Device device;
  final DiscoveredDevice? deviceBT;
  const ManageDevice(this.device, this.deviceBT);

  @override
  _ManageDeviceState createState() => new _ManageDeviceState();
}

class _ManageDeviceState extends State<ManageDevice> {
  // Initializing the Bluetooth connection state to be unknown
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  // Get the instance of the Bluetooth
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;

  // Track the Bluetooth connection with the remote device
  late BluetoothConnection connection;

  // To track whether the device is still connected to Bluetooth
  bool get isConnected => false;
  // connection != null && connection.isConnected;
  bool viewingHistoric = false;
  bool showWifiAlert = false;
  bool showDiskAlert = false;
  bool showBatteryAlert = false;
  bool showSoftwareAlert = false;
  bool showHardwareAlert = false;

  late int _deviceState;

  String id = "";
  String wifiSsid = "";
  String wifiPass = "";
  String ipBroker = "";
  String port = "";
  String? wifiStatus;
  double? wifiRSSI;

  double? deviceSpace;
  double? usedSpace;

  String? swVersion;

  bool cId = false;
  bool cWifiSsid = false;
  bool cWifiPass = false;
  bool cIpBroker = false;
  bool cPort = false;

  bool mobile = false;
  bool editingInfo = false;
  bool infoUpdated = true;

  bool inRoute = false;
  late Timer timer;

  void updateCharacteristics() {
    QualifiedCharacteristic wifiCharacteristic = QualifiedCharacteristic(
        serviceId: Uuid.parse("0000180A-0000-1000-8000-00805F9B34FB"),
        characteristicId: Uuid.parse("00005001-0000-1000-8000-00805F9B34FB"),
        deviceId: widget.deviceBT!.id);

    QualifiedCharacteristic rssiCharacteristic = QualifiedCharacteristic(
        serviceId: Uuid.parse("0000180A-0000-1000-8000-00805F9B34FB"),
        characteristicId: Uuid.parse("00005002-0000-1000-8000-00805F9B34FB"),
        deviceId: widget.deviceBT!.id);

    QualifiedCharacteristic spiffsUsed = QualifiedCharacteristic(
        serviceId: Uuid.parse("0000180A-0000-1000-8000-00805F9B34FB"),
        characteristicId: Uuid.parse("00006002-0000-1000-8000-00805F9B34FB"),
        deviceId: widget.deviceBT!.id);

    BluetoothService().readCharacteristic(wifiCharacteristic).then((value) {
      setState(() {
        wifiStatus = value;
      });
    });
    BluetoothService().readCharacteristic(rssiCharacteristic).then((value) {
      setState(() {
        wifiRSSI = double.parse(value);
      });
    });
    BluetoothService().readCharacteristic(spiffsUsed).then((value) {
      setState(() {
        usedSpace = double.parse(value);
      });
    });
  }

  @override
  void initState() {
    super.initState();
    QualifiedCharacteristic spiffsTotal = QualifiedCharacteristic(
        serviceId: Uuid.parse("0000180A-0000-1000-8000-00805F9B34FB"),
        characteristicId: Uuid.parse("00006001-0000-1000-8000-00805F9B34FB"),
        deviceId: widget.deviceBT!.id);

    QualifiedCharacteristic versionSW = QualifiedCharacteristic(
        serviceId: Uuid.parse("0000180A-0000-1000-8000-00805F9B34FB"),
        characteristicId: Uuid.parse("00002A28-0000-1000-8000-00805F9B34FB"),
        deviceId: widget.deviceBT!.id);
    BluetoothService().readCharacteristic(spiffsTotal).then((value) {
      setState(() {
        deviceSpace = double.parse(value);
      });
    });
    BluetoothService().readCharacteristic(versionSW).then((value) {
      setState(() {
        swVersion = value;
      });
    });

    timer = Timer.periodic(
        Duration(seconds: 1), (Timer t) => updateCharacteristics());

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

  void _connect() async {
    debugPrint("hola");
    if (_device == null) {
      debugPrint('No device selected');
    } else {
      if (!isConnected) {
        // Trying to connect to the device using
        // its address
        debugPrint("hi");
        await BluetoothConnection.toAddress(_device.address)
            .then((_connection) {
          print('Connected to the device');
          connection = _connection;

          // Updating the device connectivity
          // status to [true]
          setState(() {
            _connected = true;
          });

          // This is for tracking when the disconnecting process
          // is in progress which uses the [isDisconnecting] variable
          // defined before.
          // Whenever we make a disconnection call, this [onDone]
          // method is fired.
          connection.input!.listen(_onDataReceived).onDone(() {
            if (isDisconnecting) {
              print('Disconnecting locally!');
            } else {
              print('Disconnected remotely!');
            }
            if (this.mounted) {
              setState(() {});
            }
          });
        }).catchError((error) {
          print('Cannot connect, exception occurred');
          print(error);
        });
        debugPrint('Device connected');
        connection.output.add(utf8.encode("HELLO" + "\r\n") as Uint8List);
      }
    }
  }

  void closeHistoric() {
    setState(() {
      viewingHistoric = false;
    });
  }

  void viewHistoric() {
    setState(() {
      viewingHistoric = true;
    });
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
    timer.cancel();
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
      inRoute = !inRoute;
    });
  }

  refresh() {
    setState(() {
      infoUpdated = false;
    });
    connection.output.add(utf8.encode("HELLO" + "\r\n") as Uint8List);
  }

  finish() {
    timer.cancel();
    Navigator.pop(context);
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
    return Scaffold(
        appBar: AppBar(
          title: const Text('AQ iot nodes managment'),
        ),
        body: SingleChildScrollView(
          child: widget.device == null
              ? Container()
              : Container(
                  child: Column(
                  children: [
                    Container(
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
                          Container(
                            height: 50,
                            child: wifiStatus == null ||
                                    usedSpace == null ||
                                    deviceSpace == null
                                ? CircularProgressIndicator()
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            showWifiAlert = !showWifiAlert;
                                            showDiskAlert = false;
                                            showBatteryAlert = false;
                                            showSoftwareAlert = false;
                                            showHardwareAlert = false;
                                          });
                                        },
                                        child: wifiStatus! == "Connected"
                                            ? Icon(
                                                Icons.wifi,
                                                color: Colors.green,
                                                size: 30.0,
                                              )
                                            : Icon(
                                                Icons.wifi_off,
                                                color: Colors.red,
                                                size: 30.0,
                                              ),
                                      ),
                                      GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              showWifiAlert = false;
                                              showBatteryAlert = false;
                                              showSoftwareAlert = false;
                                              showHardwareAlert = false;
                                              showDiskAlert = !showDiskAlert;
                                            });
                                          },
                                          child:
                                              usedSpace! / deviceSpace! > 0.75
                                                  ? Icon(
                                                      Icons.disc_full,
                                                      color: Colors.red,
                                                      size: 30.0,
                                                    )
                                                  : Icon(
                                                      Icons.storage,
                                                      color: Colors.green,
                                                      size: 30.0,
                                                    )),
                                      GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              showWifiAlert = false;
                                              showDiskAlert = false;
                                              showSoftwareAlert = false;
                                              showHardwareAlert = false;
                                              showBatteryAlert =
                                                  !showBatteryAlert;
                                            });
                                          },
                                          child: Icon(
                                            Icons.battery_alert,
                                            color: Colors.red,
                                            size: 30.0,
                                          )),
                                      GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              showWifiAlert = false;
                                              showDiskAlert = false;
                                              showBatteryAlert = false;
                                              showHardwareAlert = false;
                                              showSoftwareAlert =
                                                  !showSoftwareAlert;
                                            });
                                          },
                                          child: Icon(
                                            Icons.warning,
                                            color: Colors.red,
                                            size: 30.0,
                                          )),
                                      GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              showWifiAlert = false;
                                              showDiskAlert = false;
                                              showBatteryAlert = false;
                                              showSoftwareAlert = false;
                                              showHardwareAlert =
                                                  !showHardwareAlert;
                                            });
                                          },
                                          child: Icon(
                                            Icons.settings,
                                            color: Colors.red,
                                            size: 30.0,
                                          )),
                                    ],
                                  ),
                          ),
                          Column(
                            children: [
                              showWifiAlert
                                  ? Container(
                                      height: 50,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Row(
                                            children: [
                                              wifiStatus! == "Connected"
                                                  ? Icon(
                                                      Icons.wifi,
                                                      color: Colors.green,
                                                      size: 30.0,
                                                    )
                                                  : Icon(
                                                      Icons.wifi_off,
                                                      color: Colors.red,
                                                      size: 30.0,
                                                    ),
                                              wifiStatus! == "Connected"
                                                  ? Text(
                                                      '   Señal WiFi ${wifiRSSI}dB',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    )
                                                  : Text(
                                                      '   Nodo sin conexión a internet',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    )
                                            ],
                                          ),
                                        ],
                                      ),
                                    )
                                  : Container(),
                              showDiskAlert
                                  ? Container(
                                      height: 50,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Row(
                                            children: [
                                              usedSpace! / deviceSpace! > 0.75
                                                  ? Icon(
                                                      Icons.disc_full,
                                                      color: Colors.red,
                                                      size: 30.0,
                                                    )
                                                  : Icon(
                                                      Icons.storage,
                                                      color: Colors.green,
                                                      size: 30.0,
                                                    ),
                                              usedSpace! / deviceSpace! > 0.75
                                                  ? Text(
                                                      '   Almacenamiento casi lleno',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    )
                                                  : Column(
                                                      children: [
                                                        Text(
                                                          '',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                          ),
                                                        ),
                                                        Text(
                                                          '   Memoria total: ${deviceSpace! / 1000}KB',
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                        Text(
                                                          '   Memoria usada: ${usedSpace! / 1000}KB',
                                                          textAlign:
                                                              TextAlign.center,
                                                        )
                                                      ],
                                                    )
                                            ],
                                          ),
                                        ],
                                      ),
                                    )
                                  : Container(),
                              showBatteryAlert
                                  ? Container(
                                      height: 50,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.battery_alert,
                                                color: Colors.red,
                                                size: 30.0,
                                              ),
                                              Text(
                                                '   Nodo con baja bateria',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              )
                                            ],
                                          ),
                                        ],
                                      ),
                                    )
                                  : Container(),
                              showSoftwareAlert
                                  ? Container(
                                      height: 50,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.warning,
                                                color: Colors.red,
                                                size: 30.0,
                                              ),
                                              Text(
                                                '   Problema de software',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              )
                                            ],
                                          ),
                                        ],
                                      ),
                                    )
                                  : Container(),
                              showHardwareAlert
                                  ? Container(
                                      height: 50,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.settings,
                                                color: Colors.red,
                                                size: 30.0,
                                              ),
                                              Text(
                                                '   Problema de hardware',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              )
                                            ],
                                          ),
                                        ],
                                      ),
                                    )
                                  : Container(),
                            ],
                          )
                        ],
                      ),
                    ),
                    Container(
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
                          Container(
                            height: 50,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.green,
                                      size: 30.0,
                                    ),
                                    Text(
                                      'Calidad del aire en nodo ${widget.device.id}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                          CurrentInfo(widget.device),
                          ElevatedButton(
                              style: ButtonStyle(
                                  shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25.0),
                              ))),
                              onPressed: () => {
                                    viewingHistoric
                                        ? closeHistoric()
                                        : viewHistoric()
                                  },
                              child: Container(
                                  width: 150,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: viewingHistoric
                                        ? [
                                            Text('Cerrar historico'),
                                            Icon(Icons.close)
                                          ]
                                        : [
                                            Text('Ver historico'),
                                            Icon(Icons.calendar_today)
                                          ],
                                  ))),
                          viewingHistoric
                              ? HistoricData(widget.device)
                              : Container()
                        ],
                      ),
                    ),
                    Container(
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
                          Container(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.alt_route,
                                      color: Colors.green,
                                      size: 30.0,
                                    ),
                                    Text(
                                      'Nodo movil',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    )
                                  ],
                                ),
                                infoUpdated
                                    ? Switch(
                                        value: mobile,
                                        onChanged: (v) => {
                                              v
                                                  ? changeToMobile()
                                                  : changeToStatic()
                                            })
                                    : Container(
                                        margin: EdgeInsets.all(20),
                                        child: Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: CircularProgressIndicator(),
                                        )),
                              ],
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.all(20),
                            child: Column(
                                children:
                                    mobile ? [DeviceRoute(widget.device)] : []),
                          ),
                        ],
                      ),
                    ),
                    Container(
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
                          Container(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.green,
                                      size: 30.0,
                                    ),
                                    Text(
                                      'Configuración del dispositivo',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    )
                                  ],
                                ),
                                ElevatedButton(
                                    style: ButtonStyle(
                                        shape: MaterialStateProperty.all<
                                                RoundedRectangleBorder>(
                                            RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25.0),
                                    ))),
                                    onPressed: () => {
                                          editingInfo
                                              ? cancelEdit()
                                              : editInfo()
                                        },
                                    child: Icon(
                                        editingInfo ? Icons.close : Icons.edit))
                              ],
                            ),
                          ),
                          infoUpdated
                              ? Container(
                                  margin: EdgeInsets.all(0),
                                  color: Colors.amberAccent,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: [
                                              Text("ID"),
                                              Container(
                                                width: 200,
                                                height: 25,
                                                child: editingInfo
                                                    ? TextField(
                                                        onChanged: (value) => {
                                                              setState(() {
                                                                widget.device
                                                                        .id =
                                                                    value
                                                                        as int;
                                                                cId = true;
                                                              })
                                                            },
                                                        decoration:
                                                            InputDecoration(
                                                          border:
                                                              OutlineInputBorder(),
                                                          labelText: "id",
                                                        ))
                                                    : Text(
                                                        "${widget.device.id}"),
                                              )
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: [
                                              Text("Wi-Fi ssid"),
                                              Container(
                                                width: 200,
                                                height: 25,
                                                child: editingInfo
                                                    ? TextField(
                                                        onChanged: (value) => {
                                                              setState(() {
                                                                widget.device
                                                                        .wifiSSID =
                                                                    value;
                                                                cWifiSsid =
                                                                    true;
                                                              })
                                                            },
                                                        decoration:
                                                            InputDecoration(
                                                          border:
                                                              OutlineInputBorder(),
                                                          labelText: "ssid",
                                                        ))
                                                    : Text(
                                                        widget.device.wifiSSID),
                                              )
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: [
                                              Text("Wi-Fi pass"),
                                              Container(
                                                width: 200,
                                                height: 25,
                                                child: editingInfo
                                                    ? TextField(
                                                        onChanged: (value) => {
                                                              setState(() {
                                                                widget.device
                                                                        .wifiPASS =
                                                                    value;
                                                                cWifiPass =
                                                                    true;
                                                              })
                                                            },
                                                        obscureText: true,
                                                        decoration:
                                                            InputDecoration(
                                                          border:
                                                              OutlineInputBorder(),
                                                          labelText: "password",
                                                        ))
                                                    : Text(
                                                        widget.device.wifiPASS),
                                              )
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: [
                                              Text("Node type"),
                                              Container(
                                                width: 200,
                                                height: 25,
                                                child: editingInfo
                                                    ? TextField(
                                                        onChanged: (value) => {
                                                              setState(() {
                                                                ipBroker =
                                                                    value;
                                                                cIpBroker =
                                                                    true;
                                                              })
                                                            },
                                                        decoration:
                                                            InputDecoration(
                                                          border:
                                                              OutlineInputBorder(),
                                                          labelText:
                                                              "ip broker",
                                                        ))
                                                    : Text(widget.device.type),
                                              )
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: [
                                              Text("Port"),
                                              Container(
                                                width: 200,
                                                height: 25,
                                                child: editingInfo
                                                    ? TextField(
                                                        onChanged: (value) => {
                                                              setState(() {
                                                                port = value;
                                                                cPort = true;
                                                              })
                                                            },
                                                        decoration:
                                                            InputDecoration(
                                                          border:
                                                              OutlineInputBorder(),
                                                          labelText: "port",
                                                        ))
                                                    : Text(port),
                                              )
                                            ],
                                          ),
                                        ),
                                        editingInfo
                                            ? ElevatedButton(
                                                onPressed: () => {updateInfo()},
                                                child: Container(
                                                  width: 100,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: [
                                                      Icon(
                                                        Icons.save,
                                                        color: Colors.white,
                                                        size: 30.0,
                                                      ),
                                                      Text('Actualizar')
                                                    ],
                                                  ),
                                                ))
                                            : Container(),
                                      ],
                                    ),
                                  ),
                                )
                              : Container(
                                  margin: EdgeInsets.all(20),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: CircularProgressIndicator(),
                                  ))
                        ],
                      ),
                    ),
                    Container(
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
                          Container(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.upgrade,
                                      color: Colors.green,
                                      size: 30.0,
                                    ),
                                    Text(
                                      'Actualización de software',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                          Container(
                              margin: EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  swVersion == null
                                      ? CircularProgressIndicator()
                                      : Text("$swVersion")
                                  // Text("No hay actualizaciones disponibles")
                                ],
                              ))
                        ],
                      ),
                    ),
                    Container(
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
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () => {refresh()},
                                child: Text('Recargar'),
                              ),
                              ElevatedButton(
                                onPressed: () => {finish()},
                                child: Text('Salir'),
                              ),
                              ElevatedButton(
                                onPressed: () => {restartDevice()},
                                child: Text('Reiniciar'),
                              ),
                            ])),
                  ],
                )),
        ));
  }
}
