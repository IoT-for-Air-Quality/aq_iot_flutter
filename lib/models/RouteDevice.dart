// ignore_for_file: non_constant_identifier_names

import 'package:aq_iot_flutter/models/Measurement.dart';

class RouteDevice {
  int id;
  int device;
  DateTime starttimestamp;
  DateTime endtimestamp;
  int update_frecuency;
  List points;
  bool show;
  List<Measurement> measurements;

  RouteDevice({
    required this.id,
    required this.device,
    required this.starttimestamp,
    required this.endtimestamp,
    required this.update_frecuency,
    required this.points,
    required this.show,
    required this.measurements,
  });

  factory RouteDevice.fromJson(Map<String, dynamic> json) {
    RouteDevice route = RouteDevice(
        id: json['id'],
        device: json['device'],
        starttimestamp: json['endtimestamp'] != null
            ? DateTime.parse(json['starttimestamp'])
            : DateTime(1),
        endtimestamp: json['endtimestamp'] != null
            ? DateTime.parse(json['endtimestamp'])
            : DateTime(1),
        update_frecuency: json['update_frecuency'],
        points: json['points'],
        show: false,
        measurements:
            Measurement.getMeasurements(json['measurements'] as List));
    route.measurements.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return route;
  }

  static getRoutes(List data) {
    List<RouteDevice> routes = [];
    for (var element in data) {
      routes.add(RouteDevice.fromJson(element));
    }
    return routes;
  }
}
