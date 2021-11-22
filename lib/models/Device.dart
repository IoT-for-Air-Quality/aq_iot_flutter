import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Device {
  int id;
  double lat;
  double long;
  String type;
  int organization;
  bool display;
  String wifiSSID;
  String wifiPASS;
  String swVersion;
  double? promCO;
  double? promCO2;
  double? promPM;
  BitmapDescriptor? bm;

  Device(
      {required this.id,
      required this.lat,
      required this.long,
      required this.type,
      required this.organization,
      required this.display,
      required this.wifiSSID,
      required this.wifiPASS,
      required this.swVersion,
      this.promCO,
      this.promCO2,
      this.promPM,
      this.bm});

  factory Device.fromJson(Map<String, dynamic> json) {
    debugPrint("${json['promedioCO'] == null}");
    if (json['promedioCO'] == null) json['promedioCO'] = 0;
    if (json['promedioCO2'] == null) json['promedioCO2'] = 0;
    if (json['promedioPM25'] == null) json['promedioPM25'] = 0;
    if (json['lat'] == null) json['lat'] = 0;
    if (json['long'] == null) json['long'] = 0;
    return Device(
        id: json['id'] as int,
        lat: double.parse("${json['lat']}"),
        long: double.parse("${json['long']}"),
        type: json['type'],
        organization: json['organization'] as int,
        display: json['display'],
        promCO: json['promedioCO'] == null
            ? null
            : double.parse("${json['promedioCO']}"),
        promCO2: json['promedioCO2'] == null
            ? null
            : double.parse("${json['promedioCO2']}"),
        promPM: json['promedioPM25'] == null
            ? null
            : double.parse("${json['promedioPM25']}"),
        wifiSSID: '',
        wifiPASS: '',
        swVersion: '');
  }
  static getDevices(List data) {
    List<Device> devices = [];
    for (var element in data) {
      devices.add(Device.fromJson(element));
    }
    return devices;
  }
}
