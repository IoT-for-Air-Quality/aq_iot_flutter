import 'dart:async';
import 'dart:convert' show utf8;
import 'dart:typed_data';
import 'package:aq_iot_flutter/models/Device.dart';
import 'package:aq_iot_flutter/models/RouteDevice.dart';
import 'package:aq_iot_flutter/views/CurrentInfo.dart';
import 'package:aq_iot_flutter/views/CurrentInfoWeb.dart';
import 'package:aq_iot_flutter/views/HistoricData.dart';
import 'package:aq_iot_flutter/views/Route.dart';
import 'package:flutter/material.dart';

import 'Route.dart';

class ManageDeviceWeb extends StatefulWidget {
  final Device device;
  const ManageDeviceWeb(this.device);

  @override
  _ManageDeviceWebState createState() => new _ManageDeviceWebState();
}

class _ManageDeviceWebState extends State<ManageDeviceWeb> {
  // Initializing the Bluetooth connection state to be unknown

  // Get the instance of the Bluetooth

  // Track the Bluetooth connection with the remote device

  // To track whether the device is still connected to Bluetooth
  bool get isConnected => false;
  // connection != null && connection.isConnected;
  bool viewingHistoric = false;

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
  bool infoUpdated = true;

  bool inRoute = false;

  @override
  void initState() {
    super.initState();

    // Get current state

    _deviceState = 0; // neutral

    // If the Bluetooth of the device is not enabled,
    // then request permission to turn on Bluetooth
    // as the app starts up

    // Listen for further state changes
  }

  bool isDisconnecting = false;
  bool _isButtonUnavailable = true;

  void _disconnect() async {
    // Closing the Bluetooth connection
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
      //connection = null;
    }

    super.dispose();
  }

  void changeToMobile() {
    setState(() {
      mobile = true;
    });
  }

  void changeToStatic() {
    setState(() {
      mobile = false;
    });
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
  }

  finish() {}

  restartDevice() {}

  updateInfo() {
    setState(() {
      infoUpdated = false;
    });
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
                                      'Información del dispositivo',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                          CurrentInfoWeb(widget.device),
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
                                  Text(widget.device.swVersion),
                                  Text("No hay actualizaciones disponibles")
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
