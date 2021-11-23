import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:aq_iot_flutter/models/Device.dart';
import 'package:aq_iot_flutter/models/Measurement.dart';
import 'package:aq_iot_flutter/models/Organization.dart';
import 'package:aq_iot_flutter/services/HttpService.dart';
import 'package:aq_iot_flutter/utils/Points.dart';
import 'package:aq_iot_flutter/views/ManageDevice.dart';
import 'package:date_format/date_format.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share/share.dart';

class MapAQ extends StatefulWidget {
  MapAQ({Key? key}) : super(key: key);

  @override
  _MapAQState createState() => _MapAQState();
}

class _MapAQState extends State<MapAQ> {
  Future<BitmapDescriptor> _myPainterToBitmap(
      double max, double min, double value) async {
    PictureRecorder recorder = new PictureRecorder();
    final canvas = new Canvas(recorder);
    MyPoints myPoints = new MyPoints(max, min, value);
    myPoints.paint(canvas, Size(20, 20));
    final image = await recorder.endRecording().toImage(20, 20);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  late BitmapDescriptor pinLocationIcon;
  List<Measurement>? measurements;
  List<Device>? devices;

  bool canDownload = false;

  bool isUpdatingMap = false;

  double latitude = 4.634335;

  double longitude = -74.113644;

  String mapType = "Points";

  String nodesTypes = "Estáticos";

  int variable = 1;

  List<Organization>? organizations;
  Organization? currentOrganizarion;

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
        _updateGraph();
        updateMap();
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

  void _downloadMeasurements() {
    String value = "";
    for (var e in measurements!) {
      value += "${e.timestamp},${e.value}\n";
    }
    Share.share(value);
  }

  Completer<GoogleMapController> _controller = Completer();

  @override
  void initState() {
    super.initState();
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: 2.5), 'assets/morado.png')
        .then((onValue) {
      pinLocationIcon = onValue;
    });
    setState(() {
      _setDate = formatDate(selectedDate, [yyyy, '-', mm, '-', dd]);
    });

    selectedDate = DateTime(selectedDate.year, selectedDate.month,
        selectedDate.day, _currentRangeValues.start.toInt(), 0);
    selectedDateEnd = DateTime(selectedDate.year, selectedDate.month,
        selectedDate.day, _currentRangeValues.end.toInt(), 0);
    HttpService()
        .getDevicesOrganizationData(0, selectedDate.toIso8601String(),
            selectedDateEnd.toIso8601String())
        .then((value) {
      setState(() {
        value.removeWhere((element) => element.promCO == null);
        devices = [];

        if (value.length > 0) {
          Device max = value.reduce((a, b) => a.promCO! > b.promCO! ? a : b);
          Device min = value.reduce((a, b) => a.promCO! < b.promCO! ? a : b);
          devices = [];
          if (max != null) {
            for (var item in value) {
              _myPainterToBitmap(max.promCO!, min.promCO!, item.promCO!)
                  .then((v) {
                item.bm = v;
                devices!.add(item);
              });
            }
          }
        }

        // devices = value;
      });
    });

    HttpService().getOrganizations().then((value) {
      setState(() {
        organizations = value;
        organizations!.add(Organization(id: 0, name: 'Todas'));
        currentOrganizarion = organizations!.last;
      });
    });
  }

  RangeValues _currentRangeValues = const RangeValues(0, 24);

  void updateMap() {
    setState(() {
      isUpdatingMap = true;
    });
    selectedDate = DateTime(selectedDate.year, selectedDate.month,
        selectedDate.day, _currentRangeValues.start.toInt(), 0);
    selectedDateEnd = DateTime(selectedDate.year, selectedDate.month,
        selectedDate.day, _currentRangeValues.end.toInt(), 0);

    HttpService()
      ..getDevicesOrganizationData(currentOrganizarion!.id,
              selectedDate.toIso8601String(), selectedDateEnd.toIso8601String())
          .then((value) {
        setState(() {
          value.removeWhere((element) => element.promCO == null);
          devices = [];

          if (value.length > 0) {
            Device max = value.reduce((a, b) => a.promCO! > b.promCO! ? a : b);
            Device min = value.reduce((a, b) => a.promCO! < b.promCO! ? a : b);
            devices = [];
            if (max != null) {
              for (var item in value) {
                _myPainterToBitmap(max.promCO!, min.promCO!, item.promCO!)
                    .then((v) {
                  item.bm = v;
                  devices!.add(item);
                });
              }
            }
          }
          isUpdatingMap = false;
          // devices = value;
        });
      });
  }

  DateTime selectedDateEnd = DateTime.now();
  int currentNodeId = 0;

  void _updateGraph() {
    selectedDate = DateTime(selectedDate.year, selectedDate.month,
        selectedDate.day, _currentRangeValues.start.toInt(), 0);
    selectedDateEnd = DateTime(selectedDate.year, selectedDate.month,
        selectedDate.day, _currentRangeValues.end.toInt(), 0);
    HttpService()
        .getMeasurements(currentNodeId, selectedDate.toIso8601String(),
            selectedDateEnd.toIso8601String())
        .then((value) {
      setState(() {
        value.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        measurements = value;
      });
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
          title: const Text('Mapa calidad del aire'),
          actions: [
            measurements == null
                ? Container()
                : measurements!.length == 0
                    ? Container()
                    : IconButton(
                        icon: Icon(Icons.download),
                        onPressed: () {
                          _downloadMeasurements();
                        },
                      ),
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
                leading: Radio<int>(
                  value: 1,
                  groupValue: variable,
                  onChanged: (int? value) {
                    setState(() {
                      variable = value!;
                    });
                  },
                ),
              ),
              ListTile(
                visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                title: Text("CO\u2082"),
                leading: Radio<int>(
                  value: 2,
                  groupValue: variable,
                  onChanged: (int? value) {
                    setState(() {
                      variable = value!;
                    });
                  },
                ),
              ),
              ListTile(
                visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                title: Text("PM 2.5"),
                leading: Radio<int>(
                  value: 3,
                  groupValue: variable,
                  onChanged: (int? value) {
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
                      value: currentOrganizarion,
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
                          currentOrganizarion = newValue!;
                          updateMap();
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
                  height: 450,
                  child: devices == null
                      ? Padding(
                          padding: EdgeInsets.only(top: 150, bottom: 150),
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              Text(''),
                              Text('Cargando mapa...')
                            ],
                          ))
                      : Stack(
                          children: [
                            GoogleMap(
                                onTap: (LatLng lng) {
                                  setState(() {
                                    measurements = null;
                                  });
                                },
                                markers: devices!
                                    .map((e) => Marker(
                                          onTap: () {
                                            setState(() {
                                              currentNodeId = e.id;
                                              _updateGraph();
                                            });
                                          },
                                          icon: e.bm == null
                                              ? pinLocationIcon
                                              : e.bm!,
                                          markerId: MarkerId(e.id.toString()),
                                          position: LatLng(e.lat, e.long),
                                          infoWindow: InfoWindow(
                                              title: e.id.toString(),
                                              snippet: variable == 1
                                                  ? " CO: ${e.promCO!.toStringAsFixed(2)}"
                                                  : variable == 2
                                                      ? " CO\u2082: ${e.promCO2!.toStringAsFixed(2)}"
                                                      : " PM 2.5: ${e.promPM!.toStringAsFixed(2)}",
                                              onTap: () {
                                                Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            ManageDevice(
                                                                e, null)));
                                              }),
                                        ))
                                    .toSet(),
                                myLocationEnabled: true,
                                initialCameraPosition: CameraPosition(
                                    zoom: 11.0746,
                                    target: LatLng(latitude, longitude))),
                            isUpdatingMap
                                ? Positioned(
                                    top: 0,
                                    right: 0,
                                    left: 0,
                                    child: Container(
                                        height: 450,
                                        decoration: BoxDecoration(
                                            color: Color.fromRGBO(0, 0, 0,
                                                0.5) // I played with different colors code for get transparency of color but Alway display White.
                                            ),
                                        child: Padding(
                                            padding: EdgeInsets.only(top: 200),
                                            child: Center(
                                              child: Column(
                                                children: [
                                                  CircularProgressIndicator(
                                                    color: Colors.white,
                                                  ),
                                                  Text("Actualizando mapa...",
                                                      style: TextStyle(
                                                        fontSize: 30,
                                                        color: Colors.white,
                                                      )),
                                                ],
                                              ),
                                            ))),
                                  )
                                : Container()
                          ],
                        )),
              RangeSlider(
                values: _currentRangeValues,
                min: 0,
                max: 24,
                divisions: 24,
                labels: RangeLabels(
                    _currentRangeValues.start < 12
                        ? "${_currentRangeValues.start.round()}:00 am"
                        : _currentRangeValues.start == 12
                            ? "${_currentRangeValues.start.round()}:00 m"
                            : "${_currentRangeValues.start.round() - 12}:00 pm",
                    _currentRangeValues.end < 12
                        ? "${_currentRangeValues.end.round()}:00 am"
                        : _currentRangeValues.end == 12
                            ? "${_currentRangeValues.end.round()}:00 m"
                            : "${_currentRangeValues.end.round() - 12}:00 pm"),
                onChanged: (RangeValues values) {
                  setState(() {
                    _currentRangeValues = values;
                    _updateGraph();
                    updateMap();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.access_alarms),
                  Icon(Icons.brightness_5),
                  Icon(Icons.nights_stay_outlined)
                ],
              ),
              measurements == null
                  ? SizedBox(
                      height: 200,
                      child: Center(
                          child: Padding(
                        padding: EdgeInsets.all(70),
                        child: Text(
                          "Selecciona un nodo para visualizar la gráfica a detalle",
                          textAlign: TextAlign.center,
                        ),
                      )),
                    )
                  : measurements!.length < 1
                      ? SizedBox(
                          height: 200,
                          child: Center(
                              child: Padding(
                            padding: EdgeInsets.all(70),
                            child: Text(
                              "No hay datos para visualizar",
                              textAlign: TextAlign.center,
                            ),
                          )),
                        )
                      : SizedBox(
                          height: 200,
                          child: Container(
                            margin: EdgeInsets.only(top: 20, bottom: 20),
                            child: LineChart(
                              LineChartData(lineBarsData: [
                                LineChartBarData(
                                    spots: measurements!
                                        .where((element) =>
                                            element.variable == variable)
                                        .toList()
                                        .map((e) => FlSpot(
                                            e.timestamp.millisecondsSinceEpoch
                                                .toDouble(),
                                            e.value))
                                        .toList())
                              ]),
                            ),
                          )),
            ],
          ),
        ));
  }
}
