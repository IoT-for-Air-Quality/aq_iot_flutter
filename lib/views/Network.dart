import 'package:aq_iot_flutter/models/Device.dart';
import 'package:aq_iot_flutter/models/Organization.dart';
import 'package:aq_iot_flutter/services/HttpService.dart';
import 'package:aq_iot_flutter/views/ManageDeviceWeb.dart';
import 'package:aq_iot_flutter/views/MapAQ.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import '';

import 'ManageDevice.dart';

class Network extends StatefulWidget {
  Network({Key? key}) : super(key: key);

  @override
  _NetworkState createState() => _NetworkState();
}

class _NetworkState extends State<Network> {
  double currentRadius = 500;

  List<Device>? devices;

  void _openMap() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => MapAQ()));
  }

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

  @override
  void initState() {
    _determinePosition().then((value) {
      HttpService()
          .getInfoAQ(value.latitude, value.longitude, currentRadius)
          .then((value) {
        if (value.length > 0) {
          setState(() {
            value.sort((a, b) => a.distance!.compareTo(b.distance!));
            devices = value;
          });
        } else {
          setState(() {
            devices = [];
          });
        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10.0),
      alignment: Alignment.center,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Padding(
                  padding: EdgeInsets.all(7.5),
                  child: Expanded(
                    child: Text(
                      "Información actual\n de la red",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                      ),
                    ),
                  ))
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Padding(
                  padding: EdgeInsets.only(top: 7.5, bottom: 15),
                  child: Container(
                    width: 300,
                    child: Text(
                      "Basado en la ubicación de tu celular, tomamos los nodos cuya distancia a tí es menor a ${currentRadius.toInt()}m.",
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        fontSize: 15,
                      ),
                    ),
                  ))
            ],
          ),
          devices == null
              ? Row(
                  children: [
                    Container(
                        height: 100,
                        child: Text("Determinando tu ubicación..."))
                  ],
                )
              : devices!.length == 0
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                            height: 100,
                            width: 300,
                            child: Padding(
                              padding: EdgeInsets.all(30),
                              child: Text(
                                "No se encontraron nodos cercanos a tu ubicacion",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ))
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                          width: 170,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Text(
                                      'CO',
                                      style: TextStyle(
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Container(
                                      decoration: BoxDecoration(
                                        color: (devices!
                                                        .map((e) => e.promCO)
                                                        .reduce((a, b) =>
                                                            a! + b!)! /
                                                    devices!.length)! <
                                                20
                                            ? Colors.green[100]
                                            : (devices!
                                                            .map(
                                                                (e) => e.promCO)
                                                            .reduce((a, b) =>
                                                                a! + b!)! /
                                                        devices!.length)! <
                                                    50
                                                ? Colors.amber[100]
                                                : Colors.red[100],
                                        border: Border.all(
                                          color: (devices!
                                                          .map((e) => e.promCO)
                                                          .reduce((a, b) =>
                                                              a! + b!)! /
                                                      devices!.length)! <
                                                  20
                                              ? Colors.green[400]!
                                              : (devices!
                                                              .map((e) =>
                                                                  e.promCO)
                                                              .reduce((a, b) =>
                                                                  a! + b!)! /
                                                          devices!.length)! <
                                                      50
                                                  ? Colors.amber[400]!
                                                  : Colors.red[400]!,
                                          width: 0.5,
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Text(
                                          "${(devices!.map((e) => e.promCO).reduce((a, b) => a! + b!)! / devices!.length).toStringAsFixed(2)} ppm",
                                          style: TextStyle(
                                            fontSize: 10,
                                          ),
                                        ),
                                      ))
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Text(
                                      'CO\u2082',
                                      style: TextStyle(
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Container(
                                      decoration: BoxDecoration(
                                        color: (devices!
                                                        .map((e) => e.promCO2)
                                                        .reduce((a, b) =>
                                                            a! + b!)! /
                                                    devices!.length)! <
                                                50
                                            ? Colors.green[100]
                                            : (devices!
                                                            .map((e) =>
                                                                e.promCO2)
                                                            .reduce((a, b) =>
                                                                a! + b!)! /
                                                        devices!.length)! <
                                                    100
                                                ? Colors.amber[100]
                                                : Colors.red[100],
                                        border: Border.all(
                                          color: (devices!
                                                          .map((e) => e.promCO2)
                                                          .reduce((a, b) =>
                                                              a! + b!)! /
                                                      devices!.length)! <
                                                  20
                                              ? Colors.green[400]!
                                              : (devices!
                                                              .map((e) =>
                                                                  e.promCO2)
                                                              .reduce((a, b) =>
                                                                  a! + b!)! /
                                                          devices!.length)! <
                                                      50
                                                  ? Colors.amber[400]!
                                                  : Colors.red[400]!,
                                          width: 0.5,
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Text(
                                          "${(devices!.map((e) => e.promCO2).reduce((a, b) => a! + b!)! / devices!.length).toStringAsFixed(2)} ppm",
                                          style: TextStyle(
                                            fontSize: 10,
                                          ),
                                        ),
                                      ))
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Text(
                                      'PM 2.5',
                                      style: TextStyle(
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Container(
                                      decoration: BoxDecoration(
                                        color: (devices!
                                                        .map((e) => e.promPM)
                                                        .reduce((a, b) =>
                                                            a! + b!)! /
                                                    devices!.length)! <
                                                0.25
                                            ? Colors.green[100]
                                            : (devices!
                                                            .map(
                                                                (e) => e.promPM)
                                                            .reduce((a, b) =>
                                                                a! + b!)! /
                                                        devices!.length)! <
                                                    0.75
                                                ? Colors.amber[100]
                                                : Colors.red[100],
                                        border: Border.all(
                                          color: (devices!
                                                          .map((e) => e.promPM)
                                                          .reduce((a, b) =>
                                                              a! + b!)! /
                                                      devices!.length)! <
                                                  0.25
                                              ? Colors.green[400]!
                                              : (devices!
                                                              .map((e) =>
                                                                  e.promPM)
                                                              .reduce((a, b) =>
                                                                  a! + b!)! /
                                                          devices!.length)! <
                                                      0.75
                                                  ? Colors.amber[400]!
                                                  : Colors.red[400]!,
                                          width: 0.5,
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Text(
                                          "${(devices!.map((e) => e.promPM).reduce((a, b) => a! + b!)! / devices!.length).toStringAsFixed(2)} mg/m\u00B3",
                                          style: TextStyle(
                                            fontSize: 10,
                                          ),
                                        ),
                                      ))
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(10),
                              child: Text(
                                "Dispositivos en cuenta",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Container(
                              height: 100,
                              width: 150,
                              child: ListView.builder(
                                  itemCount: devices!.length,
                                  itemBuilder:
                                      (BuildContext context2, int index) {
                                    return Container(
                                        height: 20,
                                        child: Column(
                                          children: [
                                            Container(
                                                child: GestureDetector(
                                              child: Text(
                                                  "ID: ${devices![index].id} -  ${(devices![index].distance! * 1000)!.toStringAsFixed(1)}m"),
                                              onTap: () {
                                                Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            ManageDevice(
                                                                devices![index],
                                                                null)));
                                              },
                                            ))
                                          ],
                                        ));
                                  }),
                            )
                          ],
                        )
                      ],
                    ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Padding(
                  padding: EdgeInsets.only(top: 15, bottom: 15),
                  child: Container(
                    width: 300,
                    child: Text(
                      "Las medidas que observas son el promedio de la  ultima hora que han obtenido los sensores",
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 15,
                      ),
                    ),
                  ))
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 40),
            child: GestureDetector(
              onTap: _openMap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20.0),
                    child: Image.asset("assets/iconoMapa.png",
                        height: 150, width: 150, fit: BoxFit.fill),
                  ),
                  Text(
                    "Mapa de la \n calidad del aire",
                    textAlign: TextAlign.center,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
