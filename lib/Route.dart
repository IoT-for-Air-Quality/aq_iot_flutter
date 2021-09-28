import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:mqtt_client/mqtt_client.dart';

import 'package:mqtt_client/mqtt_server_client.dart';
import './MQTTManager.dart';

class DeviceRoute extends StatefulWidget {
  DeviceRoute({Key? key}) : super(key: key);

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
  MQTTManager manager =
      MQTTManager(host: "test.mosquitto.org", identifier: "Yo");

  static const topicLat = 'AQ/ESP32/LAT';
  static const topicLon = 'AQ/ESP32/LON';

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
  @override
  void initState() {
    super.initState();

    manager.initializeMQTTClient();
    manager.connect();
    timer = Timer.periodic(Duration(seconds: 10), (Timer t) => addValue());
  }

  void addValue() {
    pubData();
    setState(() {
      counter++;
    });
  }

  void pubData() {
    _determinePosition().then((value) {
      if (manager.getConnStatus().state == MqttConnectionState.connected) {
        manager.publish(value.latitude.toString(), topicLat);
        manager.publish(value.longitude.toString(), topicLon);
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
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
                      Row(children: [Text("Longitud"), Text("${counter}")]),
                      ElevatedButton(
                          onPressed: () => {pubData()}, child: Text("hola"))
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
