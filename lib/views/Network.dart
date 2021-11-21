import 'package:aq_iot_flutter/models/Device.dart';
import 'package:aq_iot_flutter/models/Organization.dart';
import 'package:aq_iot_flutter/services/HttpService.dart';
import 'package:aq_iot_flutter/views/ManageDeviceWeb.dart';
import 'package:aq_iot_flutter/views/MapAQ.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'ManageDevice.dart';

class Network extends StatefulWidget {
  Network({Key? key}) : super(key: key);

  @override
  _NetworkState createState() => _NetworkState();
}

class _NetworkState extends State<Network> {
  Device device = new Device(
      id: 0,
      organization: 0,
      type: 'static',
      lat: 0,
      long: 0,
      display: false,
      wifiSSID: '',
      wifiPASS: '',
      swVersion: '');
  List<Organization>? organizations;
  List<Device>? devices;
  Organization? dropdownValue;
  Device? dropdownDevice;

  void _openMap() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => MapAQ()));
  }

  @override
  void initState() {
    HttpService().getOrganizations().then((value) {
      setState(() => {organizations = value});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Padding(
                padding: EdgeInsets.all(7.5),
                child: Text("Current network information"),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [Text("Calidad del aire optima")],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _openMap,
                child: Text('Ver mapa'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
