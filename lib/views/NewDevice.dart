import 'package:aq_iot_flutter/views/MainPage.dart';
import 'package:aq_iot_flutter/models/Organization.dart';
import 'package:aq_iot_flutter/models/Variable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/gestures.dart';
import '../models/Device.dart';
import '../services/HttpService.dart';

class NewDevice extends StatefulWidget {
  NewDevice({Key? key}) : super(key: key);

  @override
  _NewDeviceState createState() => _NewDeviceState();
}

class _NewDeviceState extends State<NewDevice> {
  Device device = new Device(
      id: 0, organization: 0, type: 'static', lat: 0, long: 0, display: false);
  double latitude = 0;
  double longitude = 0;

  void _createVariable() {}

  void _submit() {
    HttpService().postDevice(device).then(
      (value) {
        device.id = value;
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => MainPage()));
      },
    );
  }

  List<Organization>? organizations;
  List<Variable>? variables;

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  Completer<GoogleMapController> _controller = Completer();

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  static final CameraPosition _kLake = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(37.43296265331129, -122.08832357078792),
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);
  Organization? dropdownValue;
  String dropdownValue2 = 'Estático';
  bool isChecked = false;

  @override
  void initState() {
    super.initState();
    debugPrint("jwhefkj");
    HttpService().getOrganizations().then((value) {
      debugPrint("jwhefkj");
      setState(() => {organizations = value});
    });
    HttpService().getVariables().then((value) {
      setState(() => {variables = value});
      debugPrint("$variables");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Setup your new device'),
        ),
        body: Container(
          child: SingleChildScrollView(
            child: Container(
                child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(50.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Flexible(
                            child: Text(
                              'Configuración inicial de nodo sensor',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 37,
                              ),
                            ),
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Flexible(
                              child: Padding(
                            padding: const EdgeInsets.only(
                              top: 20,
                            ),
                            child: Text(
                              'A continuación debes ingresar cierta información básica para que tu nodo pueda transmitir la información que sensa',
                              textAlign: TextAlign.center,
                            ),
                          ))
                        ],
                      )
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(20.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Selecciona a que grupo de sensores va a pertenecer tu nodo',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Flexible(
                              child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 20,
                                    bottom: 40,
                                  ),
                                  child: DropdownButton<Organization>(
                                    value: dropdownValue,
                                    icon: const Icon(Icons.arrow_downward),
                                    iconSize: 24,
                                    elevation: 16,
                                    style: const TextStyle(
                                        color: Colors.deepPurple),
                                    underline: Container(
                                      height: 2,
                                      color: Colors.deepPurpleAccent,
                                    ),
                                    onChanged: (Organization? newValue) {
                                      setState(() {
                                        dropdownValue = newValue!;
                                        device.organization = dropdownValue!.id;
                                      });
                                    },
                                    items: organizations!
                                        .map<DropdownMenuItem<Organization>>(
                                            (Organization value) {
                                      return DropdownMenuItem<Organization>(
                                        value: value,
                                        child: Text(value.name),
                                      );
                                    }).toList(),
                                  )))
                        ],
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Selecciona las variables a sensar',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ),
                          Container(
                            width: 70,
                            child: ElevatedButton(
                              style: ButtonStyle(
                                  shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25.0),
                              ))),
                              onPressed: _createVariable,
                              child: Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 30.0,
                              ),
                            ),
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Flexible(
                              child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 20,
                                    bottom: 40,
                                  ),
                                  child: SizedBox(
                                      height: 25.0 * variables!.length,
                                      child: GridView.count(
                                          shrinkWrap: true,
                                          childAspectRatio: 4,
                                          physics:
                                              NeverScrollableScrollPhysics(),
                                          crossAxisCount: 2,
                                          children: variables!
                                              .map((e) => Container(
                                                    child: Row(
                                                      children: [
                                                        Checkbox(
                                                          checkColor:
                                                              Colors.white,
                                                          value: e.isActive,
                                                          onChanged:
                                                              (bool? value) {
                                                            setState(() {
                                                              e.isActive =
                                                                  value!;
                                                            });
                                                          },
                                                        ),
                                                        Text(
                                                            "${e.name}[${e.unit}]")
                                                      ],
                                                    ),
                                                  ))
                                              .toList()))

                                  // Row(
                                  //   children: [
                                  //     Column(
                                  //       children: [
                                  //         Padding(
                                  //           padding: const EdgeInsets.all(10),
                                  //           child: Row(
                                  //             children: [
                                  //               Checkbox(
                                  //                 checkColor: Colors.white,
                                  //                 value: isChecked,
                                  //                 onChanged: (bool? value) {
                                  //                   setState(() {
                                  //                     isChecked = value!;
                                  //                   });
                                  //                 },
                                  //               ),
                                  //               Text('datamuylarga')
                                  //             ],
                                  //           ),
                                  //         )
                                  //       ],
                                  //     ),
                                  //     Column(
                                  //       children: [
                                  //         Padding(
                                  //           padding: const EdgeInsets.all(10),
                                  //           child: Row(
                                  //             children: [
                                  //               Checkbox(
                                  //                 checkColor: Colors.white,
                                  //                 value: isChecked,
                                  //                 onChanged: (bool? value) {
                                  //                   setState(() {
                                  //                     isChecked = value!;
                                  //                   });
                                  //                 },
                                  //               ),
                                  //               Text('datamuylarga')
                                  //             ],
                                  //           ),
                                  //         )
                                  //       ],
                                  //     ),
                                  //   ],
                                  // ))),
                                  ))
                        ],
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Selecciona el tipo de dispositivo que vas a utilizar',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Flexible(
                              child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 20,
                                    bottom: 40,
                                  ),
                                  child: DropdownButton<String>(
                                    value: dropdownValue2,
                                    icon: const Icon(Icons.arrow_downward),
                                    iconSize: 24,
                                    elevation: 16,
                                    style: const TextStyle(
                                        color: Colors.deepPurple),
                                    underline: Container(
                                      height: 2,
                                      color: Colors.deepPurpleAccent,
                                    ),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        dropdownValue2 = newValue!;
                                        device.type =
                                            (dropdownValue2 == 'Estático'
                                                ? 'static'
                                                : 'mobile');
                                      });
                                    },
                                    items: <String>[
                                      'Estático',
                                      'Dinámico',
                                    ].map<DropdownMenuItem<String>>(
                                        (String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                  )))
                        ],
                      ),
                      dropdownValue2 == 'Dinámico'
                          ? Container()
                          : Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'Define la ubicación de tu dispositivo.',
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: 20,
                                    ),
                                  ),
                                )
                              ],
                            ),
                      dropdownValue2 == 'Dinámico'
                          ? Container()
                          : FutureBuilder<Position>(
                              future:
                                  _determinePosition(), // a previously-obtained Future<String> or null
                              builder: (BuildContext context,
                                  AsyncSnapshot<Position> snapshot) {
                                Widget child;
                                if (snapshot.hasData) {
                                  child = Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Container(
                                        height: 310,
                                        width: 310,
                                        child: GoogleMap(
                                            gestureRecognizers: <
                                                Factory<
                                                    OneSequenceGestureRecognizer>>[
                                              new Factory<
                                                  OneSequenceGestureRecognizer>(
                                                () =>
                                                    new EagerGestureRecognizer(),
                                              ),
                                            ].toSet(),
                                            mapType: MapType.normal,
                                            myLocationEnabled: true,
                                            markers: [
                                              Marker(
                                                markerId: MarkerId("1"),
                                                position:
                                                    LatLng(latitude, longitude),
                                              )
                                            ].toSet(),
                                            onCameraMove: (object) => {
                                                  setState(() {
                                                    latitude =
                                                        object.target.latitude;
                                                    longitude =
                                                        object.target.longitude;
                                                    device.lat = latitude;
                                                    device.long = longitude;
                                                  })
                                                },
                                            initialCameraPosition:
                                                CameraPosition(
                                              target: LatLng(
                                                  snapshot.data!.latitude,
                                                  snapshot.data!.longitude),
                                              zoom: 14.4746,
                                            ),
                                            onMapCreated: (GoogleMapController
                                                controller) {
                                              _controller.complete(controller);
                                            }),
                                      ),
                                    ],
                                  );
                                  ;
                                } else if (snapshot.hasError) {
                                  child = Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Text('Error: ${snapshot.error}'),
                                  );
                                } else {
                                  child = SizedBox(
                                    child: CircularProgressIndicator(),
                                    width: 60,
                                    height: 60,
                                  );
                                }
                                return Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: child,
                                  ),
                                );
                              },
                            ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Flexible(
                            child: ElevatedButton(
                              onPressed: _submit,
                              child: Text('Finalizar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            )),
          ),
        ));
  }
}
