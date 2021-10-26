import 'dart:async';
import 'package:aq_iot_flutter/models/Device.dart';
import 'package:aq_iot_flutter/services/HttpService.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:mqtt_client/mqtt_client.dart';

import '../managers/MQTTManager.dart';

class DeviceRoute extends StatefulWidget {
  final Device device;
  const DeviceRoute(this.device);
  @override
  _DeviceRouteState createState() => _DeviceRouteState();
}

class _DeviceRouteState extends State<DeviceRoute> {
  static const String _kLocationServicesDisabledMessage =
      'Location services are disabled.';
  static const String _kPermissionDeniedMessage = 'Permission denied.';
  static const String _kPermissionDeniedForeverMessage =
      'Permission denied forever.';
  static const String _kPermissionGrantedMessage = 'Permission granted.';

  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusStreamSubscription;
  bool positionStreamStarted = false;
  MQTTManager manager = MQTTManager(host: "35.237.59.165", identifier: "Yo");

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

  late Timer timer;
  int counter = 0;

  int? idRoute;
  @override
  void initState() {
    final int seconds = 5;
    super.initState();

    manager.initializeMQTTClient();
    manager.connect();
    HttpService().postRoute(widget.device.id, seconds * 100).then((value) {
      setState(() {
        idRoute = value;
      });
      timer = Timer.periodic(
          Duration(seconds: seconds), (Timer t) => addValue(value));
    });
  }

  void addValue(int idRoute) {
    pubData(idRoute);
    setState(() {
      counter++;
    });
  }

  void pubData(int idRoute) {
    _determinePosition().then((value) {
      if (manager.getConnStatus().state == MqttConnectionState.connected) {
        manager.publish("${value.latitude}&${value.longitude}",
            'AQ/RoutePoint/$idRoute/Lat&Long');
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  void _endRoute() async {
    HttpService().endRoute(idRoute!).then((value) {
      timer.cancel();
      return true;
    }).catchError((e) {
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("$counter"),
        Container(
          child: FutureBuilder<Position>(
              future: _determinePosition(),
              builder:
                  (BuildContext context, AsyncSnapshot<Position> snapshot) {
                if (snapshot.hasData) {
                  return Column(
                    children: [
                      Row(children: [
                        Text("Latitud"),
                        Text("${snapshot.data!.latitude}")
                      ]),
                      Row(children: [
                        Text("Longitud"),
                        Text("${snapshot.data!.longitude}")
                      ]),
                      ElevatedButton(
                          onPressed: () {
                            _endRoute();
                          },
                          style: ButtonStyle(
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                          ))),
                          child: Text('Finalizar ruta'))
                    ],
                  );
                } else
                  return Container();
              }),
        )
      ],
    );
  }
}
