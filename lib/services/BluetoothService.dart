import 'dart:convert';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter/material.dart';

class BluetoothService {
  final flutterReactiveBle = FlutterReactiveBle();

  Stream<DiscoveredDevice> getDevices() {
    return flutterReactiveBle
        .scanForDevices(withServices: [], scanMode: ScanMode.lowLatency);
  }

  Stream<ConnectionStateUpdate> connectDevice(String foundDeviceId, service) {
    //{serviceId: [char1, char2]}
    return flutterReactiveBle.connectToDevice(
      id: foundDeviceId,
      servicesWithCharacteristicsToDiscover: service,
      connectionTimeout: const Duration(seconds: 2),
    );
  }

  Future<String> readCharacteristic(
      QualifiedCharacteristic characteristic) async {
    return new String.fromCharCodes(
        await flutterReactiveBle.readCharacteristic(characteristic));
  }

  Future<void> writeSlow(QualifiedCharacteristic characteristic, String value) {
    List<int> bytes = utf8.encode(value);
    return flutterReactiveBle.writeCharacteristicWithResponse(characteristic,
        value: bytes);
  }
}
