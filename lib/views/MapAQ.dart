import 'dart:async';

import 'package:aq_iot_flutter/models/Organization.dart';
import 'package:aq_iot_flutter/services/HttpService.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapAQ extends StatefulWidget {
  MapAQ({Key? key}) : super(key: key);

  @override
  _MapAQState createState() => _MapAQState();
}

class _MapAQState extends State<MapAQ> {
  double latitude = 4.634335;

  double longitude = -74.113644;

  String mapType = "Points";

  String nodesTypes = "Estáticos";

  String variable = "CO";

  List<Organization>? organizations;
  Organization? dropdownValue;

  String? _setDate;

  DateTime selectedDate = DateTime.now();

  TextEditingController _dateController = TextEditingController();

  Future<Null> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        initialDatePickerMode: DatePickerMode.day,
        firstDate: DateTime(2015),
        lastDate: DateTime.now());
    if (picked != null)
      setState(() {
        selectedDate = picked;
        _dateController.text =
            formatDate(selectedDate, [yyyy, '-', mm, '-', dd]);
      });
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

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openEndDrawer() {
    _scaffoldKey.currentState!.openEndDrawer();
  }

  void _closeEndDrawer() {
    Navigator.of(context).pop();
  }

  Completer<GoogleMapController> _controller = Completer();

  @override
  void initState() {
    super.initState();
    HttpService().getOrganizations().then((value) {
      setState(() => {organizations = value});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          leading: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
          title: const Text('AQ map'),
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                _openEndDrawer();
              },
            )
          ],
        ),
        endDrawer: Drawer(
            child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                  padding: EdgeInsets.only(top: 25, bottom: 5),
                  child: Text(
                    "Tipo de mapa",
                    style: TextStyle(fontSize: 20),
                  )),
              ListTile(
                visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                title: Text("Points"),
                leading: Radio<String>(
                  value: "Points",
                  groupValue: mapType,
                  onChanged: (String? value) {
                    setState(() {
                      mapType = value!;
                    });
                  },
                ),
              ),
              ListTile(
                visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                title: Text("Heat map"),
                leading: Radio<String>(
                  value: "Heat map",
                  groupValue: mapType,
                  onChanged: (String? value) {
                    setState(() {
                      mapType = value!;
                    });
                  },
                ),
              ),
              Padding(
                  padding: EdgeInsets.only(top: 25, bottom: 5),
                  child: Text(
                    "Tipo de nodo",
                    style: TextStyle(fontSize: 20),
                  )),
              ListTile(
                visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                title: Text("Estáticos"),
                leading: Radio<String>(
                  value: "Estáticos",
                  groupValue: nodesTypes,
                  onChanged: (String? value) {
                    setState(() {
                      nodesTypes = value!;
                    });
                  },
                ),
              ),
              ListTile(
                visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                title: Text("Dinámicos"),
                leading: Radio<String>(
                  value: "Dinámicos",
                  groupValue: nodesTypes,
                  onChanged: (String? value) {
                    setState(() {
                      nodesTypes = value!;
                    });
                  },
                ),
              ),
              Padding(
                  padding: EdgeInsets.only(top: 25, bottom: 5),
                  child: Text(
                    "Variable",
                    style: TextStyle(fontSize: 20),
                  )),
              ListTile(
                visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                title: Text("CO"),
                leading: Radio<String>(
                  value: "CO",
                  groupValue: variable,
                  onChanged: (String? value) {
                    setState(() {
                      variable = value!;
                    });
                  },
                ),
              ),
              ListTile(
                visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                title: Text("CO2"),
                leading: Radio<String>(
                  value: "CO2",
                  groupValue: variable,
                  onChanged: (String? value) {
                    setState(() {
                      variable = value!;
                    });
                  },
                ),
              ),
              ListTile(
                visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                title: Text("PM 2.5"),
                leading: Radio<String>(
                  value: "PM 2.5",
                  groupValue: variable,
                  onChanged: (String? value) {
                    setState(() {
                      variable = value!;
                    });
                  },
                ),
              ),
              Padding(
                  padding: EdgeInsets.only(top: 25, bottom: 5),
                  child: Text(
                    "Organización",
                    style: TextStyle(fontSize: 20),
                  )),
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
                        setState(() {
                          dropdownValue = newValue!;
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
              Padding(
                  padding: EdgeInsets.only(top: 25, bottom: 5),
                  child: Text(
                    "Día",
                    style: TextStyle(fontSize: 20),
                  )),
              Padding(
                padding: EdgeInsets.only(left: 20, right: 20),
                child: Flexible(
                    child: GestureDetector(
                  onTap: () {
                    _selectDate(context);
                  },
                  child: TextField(
                    style: TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                    enabled: false,
                    decoration: InputDecoration(
                        labelText: _setDate == null
                            ? 'Selecciona una fecha'
                            : 'Fecha:',
                        contentPadding: EdgeInsets.only(top: 0.0)),
                    keyboardType: TextInputType.text,
                    controller: _dateController,
                    onChanged: (val) {
                      _setDate = val;
                    },
                  ),
                )),
              ),
              Padding(
                padding: EdgeInsets.only(top: 30),
                child: ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.grey),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(35.0),
                      ))),
                  onPressed: _closeEndDrawer,
                  child: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        )),
        body: Container(
          child: Column(
            children: [
              Container(
                height: 500,
                child: GoogleMap(
                    myLocationEnabled: true,
                    initialCameraPosition: CameraPosition(
                        zoom: 11.0746, target: LatLng(latitude, longitude))),
              )
            ],
          ),
        ));
  }
}
