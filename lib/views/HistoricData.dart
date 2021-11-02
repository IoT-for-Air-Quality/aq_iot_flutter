import 'package:aq_iot_flutter/models/Device.dart';
import 'package:aq_iot_flutter/models/Measurement.dart';
import 'package:aq_iot_flutter/services/HttpService.dart';
import 'package:flutter/material.dart';
import 'package:date_format/date_format.dart';
import 'package:fl_chart/fl_chart.dart';

class HistoricData extends StatefulWidget {
  final Device device;
  const HistoricData(this.device);

  @override
  _HistoricDataState createState() => _HistoricDataState();
}

class _HistoricDataState extends State<HistoricData> {
  String? _setTime, _setDate;
  List<Measurement>? measurements;
  TextEditingController _dateController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay(hour: 00, minute: 00);
  String? _hour, _minute, _time;
  TextEditingController _timeController = TextEditingController();

  TextEditingController _dateControllerEnd = TextEditingController();
  DateTime selectedDateEnd = DateTime.now();
  TimeOfDay selectedTimeEnd = TimeOfDay(hour: 00, minute: 00);
  // String? _hour, _minute, _time;
  TextEditingController _timeControllerEnd = TextEditingController();
  Future<Null> _selectStartDate(BuildContext context) async {
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

  Future<Null> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null)
      setState(() {
        selectedTime = picked;
        _hour = selectedTime.hour.toString();
        _minute = selectedTime.minute.toString();
        _time = _hour! + ' : ' + _minute!;
        _timeController.text = _time!;
        _timeController.text = formatDate(
            DateTime(2019, 08, 1, selectedTime.hour, selectedTime.minute),
            [hh, ':', nn, " ", am]).toString();
      });
  }

  Future<Null> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDateEnd,
        initialDatePickerMode: DatePickerMode.day,
        firstDate: selectedDate,
        lastDate: DateTime.now());
    if (picked != null)
      setState(() {
        selectedDateEnd = picked;
        _dateControllerEnd.text =
            formatDate(selectedDateEnd, [yyyy, '-', mm, '-', dd]);
      });
  }

  Future<Null> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTimeEnd,
    );
    if (picked != null)
      setState(() {
        selectedTimeEnd = picked;
        _hour = selectedTimeEnd.hour.toString();
        _minute = selectedTimeEnd.minute.toString();
        _time = _hour! + ' : ' + _minute!;
        _timeControllerEnd.text = _time!;
        _timeControllerEnd.text = formatDate(
            DateTime(2019, 08, 1, selectedTimeEnd.hour, selectedTimeEnd.minute),
            [hh, ':', nn, " ", am]).toString();
      });
  }

  void updateMeasurements() {
    selectedDate = DateTime(selectedDate.year, selectedDate.month,
        selectedDate.day, selectedTime.hour, selectedTime.minute);
    selectedDateEnd = DateTime(selectedDateEnd.year, selectedDateEnd.month,
        selectedDateEnd.day, selectedTimeEnd.hour, selectedTimeEnd.minute);
    HttpService()
        .getMeasurements(widget.device.id, selectedDate.toIso8601String(),
            selectedDateEnd.toIso8601String())
        .then((value) {
      setState(() {
        value.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        measurements = value;
      });
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      child: Column(
        children: [
          Text(''),
          Row(
            children: [
              Text('Fecha de inicio'),
              Flexible(
                  child: GestureDetector(
                onTap: () {
                  _selectStartDate(context);
                },
                child: TextField(
                  style: TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                  enabled: false,
                  decoration: InputDecoration(
                      // disabledBorder:
                      //     UnderlineInputBorder(borderSide: BorderSide.none),
                      // labelText: 'Time',
                      contentPadding: EdgeInsets.only(top: 0.0)),
                  keyboardType: TextInputType.text,
                  controller: _dateController,
                  onChanged: (val) {
                    _setDate = val;
                  },
                ),
              ))
            ],
          ),
          Row(
            children: [
              Text('Hora de inicio'),
              Flexible(
                  child: GestureDetector(
                onTap: () {
                  _selectStartTime(context);
                },
                child: TextField(
                  style: TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                  enabled: false,
                  decoration: InputDecoration(
                      // disabledBorder:
                      //     UnderlineInputBorder(borderSide: BorderSide.none),
                      // labelText: 'Time',
                      contentPadding: EdgeInsets.only(top: 0.0)),
                  keyboardType: TextInputType.text,
                  controller: _timeController,
                  onChanged: (val) {
                    _setDate = val;
                  },
                ),
              ))
            ],
          ),
          Row(
            children: [
              Text('Fecha de fin'),
              Flexible(
                  child: GestureDetector(
                onTap: () {
                  _selectEndDate(context);
                },
                child: TextField(
                  style: TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                  enabled: false,
                  decoration: InputDecoration(
                      // disabledBorder:
                      //     UnderlineInputBorder(borderSide: BorderSide.none),
                      // labelText: 'Time',
                      contentPadding: EdgeInsets.only(top: 0.0)),
                  keyboardType: TextInputType.text,
                  controller: _dateControllerEnd,
                  onChanged: (val) {
                    _setDate = val;
                  },
                ),
              ))
            ],
          ),
          Row(
            children: [
              Text('Hora de inicio'),
              Flexible(
                  child: GestureDetector(
                onTap: () {
                  _selectEndTime(context);
                },
                child: TextField(
                  style: TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                  enabled: false,
                  decoration: InputDecoration(
                      // disabledBorder:
                      //     UnderlineInputBorder(borderSide: BorderSide.none),
                      // labelText: 'Time',
                      contentPadding: EdgeInsets.only(top: 0.0)),
                  keyboardType: TextInputType.text,
                  controller: _timeControllerEnd,
                  onChanged: (val) {
                    _setDate = val;
                  },
                ),
              ))
            ],
          ),
          ElevatedButton(
              style: ButtonStyle(
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.0),
              ))),
              onPressed: () => {updateMeasurements()},
              child: Container(
                  width: 150,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [Text('Actualizar gráficas'), Icon(Icons.update)],
                  ))),
          measurements == null
              ? Container(
                  height: 300,
                  child: Padding(
                    child: CircularProgressIndicator(),
                    padding: EdgeInsets.all(140),
                  ),
                )
              : Container(
                  child: Column(
                    children: [
                      Container(
                        child: Column(
                          children: [
                            Text(
                              'CO:',
                              style: TextStyle(fontSize: 20),
                            ),
                            SizedBox(
                                height: 300,
                                child: Container(
                                  margin: EdgeInsets.only(top: 20, bottom: 20),
                                  child: LineChart(
                                    LineChartData(lineBarsData: [
                                      LineChartBarData(
                                          isCurved: true,
                                          spots: measurements!
                                              .where((element) =>
                                                  element.variable == 1)
                                              .toList()
                                              .map((e) => FlSpot(
                                                  e.timestamp
                                                      .millisecondsSinceEpoch
                                                      .toDouble(),
                                                  e.value))
                                              .toList())
                                    ]),
                                  ),
                                )),
                          ],
                        ),
                      ),
                      Container(
                        child: Column(
                          children: [
                            Text(
                              'CO2:',
                              style: TextStyle(fontSize: 20),
                            ),
                            SizedBox(
                                height: 300,
                                child: Container(
                                  margin: EdgeInsets.only(top: 20, bottom: 20),
                                  child: LineChart(
                                    LineChartData(lineBarsData: [
                                      LineChartBarData(
                                          isCurved: true,
                                          spots: measurements!
                                              .where((element) =>
                                                  element.variable == 2)
                                              .toList()
                                              .map((e) => FlSpot(
                                                  e.timestamp
                                                      .millisecondsSinceEpoch
                                                      .toDouble(),
                                                  e.value))
                                              .toList())
                                    ]),
                                  ),
                                )),
                          ],
                        ),
                      ),
                      Container(
                        child: Column(
                          children: [
                            Text(
                              'PM2.5:',
                              style: TextStyle(fontSize: 20),
                            ),
                            SizedBox(
                                height: 300,
                                child: Container(
                                  margin: EdgeInsets.only(top: 20, bottom: 20),
                                  child: LineChart(
                                    LineChartData(lineBarsData: [
                                      LineChartBarData(
                                          isCurved: true,
                                          spots: measurements!
                                              .where((element) =>
                                                  element.variable == 3)
                                              .toList()
                                              .map((e) => FlSpot(
                                                  e.timestamp
                                                      .millisecondsSinceEpoch
                                                      .toDouble(),
                                                  e.value))
                                              .toList())
                                    ]),
                                  ),
                                )),
                          ],
                        ),
                      )
                    ],
                  ),
                )
        ],
      ),
    );
  }
}
