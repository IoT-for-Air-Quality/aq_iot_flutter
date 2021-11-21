import 'package:aq_iot_flutter/models/Device.dart';
import 'package:aq_iot_flutter/models/Organization.dart';
import 'package:aq_iot_flutter/services/HttpService.dart';
import 'package:aq_iot_flutter/views/ManageDeviceWeb.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'ManageDevice.dart';

class DeviceSelection extends StatefulWidget {
  DeviceSelection({Key? key}) : super(key: key);

  @override
  _DeviceSelectionState createState() => _DeviceSelectionState();
}

class _DeviceSelectionState extends State<DeviceSelection> {
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

  void _selectDevice() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) =>
            kIsWeb ? ManageDeviceWeb(device) : ManageDevice(device, null)));
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
                child: Text("Devices from organization"),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              organizations == null
                  ? CircularProgressIndicator()
                  : DropdownButton<Organization>(
                      value: dropdownValue,
                      icon: const Icon(Icons.arrow_downward),
                      iconSize: 24,
                      elevation: 16,
                      style: const TextStyle(color: Colors.deepPurple),
                      underline: Container(
                        height: 2,
                        color: Colors.deepPurpleAccent,
                      ),
                      onChanged: (Organization? newValue) {
                        HttpService()
                            .getDevicesOrganization(newValue!.id)
                            .then((value) {
                          setState(() {
                            dropdownValue = newValue;
                            device.organization = dropdownValue!.id;

                            devices = value;
                          });
                        });
                      },
                      items: organizations!.map<DropdownMenuItem<Organization>>(
                          (Organization value) {
                        return DropdownMenuItem<Organization>(
                          value: value,
                          child: Text(value.name),
                        );
                      }).toList(),
                    ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              devices == null
                  ? Container()
                  : DropdownButton<Device>(
                      value: dropdownDevice,
                      icon: const Icon(Icons.arrow_downward),
                      iconSize: 24,
                      elevation: 16,
                      style: const TextStyle(color: Colors.deepPurple),
                      underline: Container(
                        height: 2,
                        color: Colors.deepPurpleAccent,
                      ),
                      onChanged: (Device? newValue) {
                        setState(() {
                          dropdownDevice = newValue!;
                          device.id = dropdownDevice!.id;
                        });
                      },
                      items: devices!
                          .map<DropdownMenuItem<Device>>((Device value) {
                        return DropdownMenuItem<Device>(
                          value: value,
                          child: Text("${value.id}"),
                        );
                      }).toList(),
                    ),
              ElevatedButton(
                onPressed: _selectDevice,
                child: Text('View data'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
