import 'dart:async';
import 'dart:math';
import 'package:aq_iot_flutter/models/Device.dart';
import 'package:aq_iot_flutter/services/HttpService.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

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

  Completer<GoogleMapController> _controller = Completer();

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
  late BitmapDescriptor pinLocationIcon;
  int? idRoute;
  bool? onRoute;
  final int seconds = 5;
  @override
  void initState() {
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: 2.5), 'assets/morado.png')
        .then((onValue) {
      pinLocationIcon = onValue;
    });
    super.initState();

    manager.initializeMQTTClient();
    manager.connect();
    setState(() {
      onRoute = false;
    });
  }

  void addValue() {
    setState(() {
      pubData();
      counter++;
    });
  }

  List<Position> positions = [];

  void pubData() {
    _determinePosition().then((value) async {
      debugPrint("HOLAAA");
      if (manager.getConnStatus().state == MqttConnectionState.connected) {
        debugPrint("Estoy conectadooo");
        manager.publish("${value.latitude}&${value.longitude}",
            'AQ/RoutePoint/$idRoute/Lat&Long');
      }
      final GoogleMapController controller = await _controller.future;
      setState(() {
        debugPrint("$value");
        positions.add(value);

        controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
            zoom: 17.476, target: LatLng(value.latitude, value.longitude))));
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  void _newRoute() {
    HttpService().postRoute(widget.device.id, seconds * 100).then((value) {
      setState(() {
        positions = [];
        onRoute = true;
        idRoute = value;
      });
      timer =
          Timer.periodic(Duration(seconds: seconds), (Timer t) => addValue());
    });
  }

  void _endRoute() async {
    HttpService().endRoute(idRoute!).then((value) async {
      timer.cancel();
      final GoogleMapController controller = await _controller.future;

      double sumLat = 0;
      double sumLong = 0;

      double minLat = positions[0].latitude;
      double minLong = positions[0].longitude;
      double maxLat = positions[0].latitude;
      double maxLong = positions[0].longitude;
      positions.forEach((point) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLong) minLong = point.longitude;
        if (point.longitude > maxLong) maxLong = point.longitude;
      });
      double dist = max(
          (pow(positions[0].latitude, 2).toDouble() -
                  pow(positions[positions.length - 1].latitude, 2).toDouble())
              .abs(),
          (pow(positions[0].longitude, 2).toDouble() -
                  pow(positions[positions.length - 1].longitude, 2).toDouble())
              .abs());
      debugPrint("$dist");
      controller.animateCamera((CameraUpdate.newLatLngBounds(
          LatLngBounds(
              southwest: LatLng(minLat - 0.0005, minLong - 0.0005),
              northeast: LatLng(maxLat + 0.0005, maxLong + 0.0005)),
          20)));
      setState(() {
        onRoute = false;
      });
      return true;
    }).catchError((e) {
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Route: $idRoute"),
        Container(
            child: Column(
          children: [
            FutureBuilder<Position>(
              future:
                  _determinePosition(), // a previously-obtained Future<String> or null
              builder:
                  (BuildContext context, AsyncSnapshot<Position> snapshot) {
                Widget child;
                if (snapshot.hasData) {
                  child = Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        height: 310,
                        width: 280,
                        child: GoogleMap(
                            gestureRecognizers:
                                <Factory<OneSequenceGestureRecognizer>>[
                              new Factory<OneSequenceGestureRecognizer>(
                                () => new EagerGestureRecognizer(),
                              ),
                            ].toSet(),
                            mapType: MapType.normal,
                            polylines: [
                              Polyline(
                                  polylineId: PolylineId(''),
                                  points: positions
                                      .map((e) =>
                                          LatLng(e.latitude, e.longitude))
                                      .toList())
                            ].toSet(),
                            markers: positions
                                .map((e) => Marker(
                                    icon: pinLocationIcon,
                                    markerId: MarkerId(e.timestamp.toString()),
                                    position: LatLng(e.latitude, e.longitude)))
                                .toSet(),
                            myLocationEnabled: true,
                            initialCameraPosition: CameraPosition(
                              target: LatLng(snapshot.data!.latitude,
                                  snapshot.data!.longitude),
                              zoom: 17.4746,
                            ),
                            onMapCreated: (GoogleMapController controller) {
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
            ElevatedButton(
                onPressed: () {
                  if (onRoute!) {
                    _endRoute();
                  } else {
                    _newRoute();
                  }
                },
                style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ))),
                child:
                    Text(onRoute! ? 'Finalizar ruta' : 'Iniciar nueva ruta')),
          ],
        ))
      ],
    );
  }
}
