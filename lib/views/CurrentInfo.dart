import 'package:aq_iot_flutter/models/Device.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import '../managers/MQTTManager.dart';

class CurrentInfo extends StatefulWidget {
  final Device device;
  const CurrentInfo(this.device);

  @override
  _CurrentInfoState createState() => _CurrentInfoState();
}

class _CurrentInfoState extends State<CurrentInfo> {
  MQTTManager manager = MQTTManager(host: "35.237.59.165", identifier: "Yo2");
  Stream<List<MqttReceivedMessage<MqttMessage>>>? stream;
  double? co;
  double? co2;
  double? pm25;
  DateTime? lastUpdated;
  @override
  void initState() {
    super.initState();
    manager.initializeMQTTClient();
    manager.connect2().then((value) {
      debugPrint("TTTTTT");
      manager.subscribeDevice(widget.device.id);
      stream = manager.getUpdates();
      stream!.listen((c) {
        debugPrint("AAAA");
        final recMess = c![0].payload as MqttPublishMessage;
        final pt =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

        /// The above may seem a little convoluted for users only interested in the
        /// payload, some users however may be interested in the received publish message,
        /// lets not constrain ourselves yet until the package has been in the wild
        /// for a while.
        /// The payload is a byte buffer, this will be specific to the topic
        print(
            'EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
        print('');

        if (c[0].topic == "AQ/Measurement/${widget.device.id}/CO") {
          setState(() {
            lastUpdated = DateTime.now();
            co = double.parse(pt);
          });
        }
        if (c[0].topic == "AQ/Measurement/${widget.device.id}/CO2") {
          setState(() {
            co2 = double.parse(pt);
            lastUpdated = DateTime.now();
          });
        }
        if (c[0].topic == "AQ/Measurement/${widget.device.id}/PM2.5") {
          setState(() {
            pm25 = double.parse(pt);
            lastUpdated = DateTime.now();
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  'CO',
                  style: TextStyle(
                    fontSize: 35,
                  ),
                ),
              ),
              co == null
                  ? CircularProgressIndicator()
                  : Container(
                      decoration: BoxDecoration(
                        color: co! < 20
                            ? Colors.green[100]
                            : co! < 50
                                ? Colors.amber[100]
                                : Colors.red[100],
                        border: Border.all(
                          color: co! < 20
                              ? Colors.green[400]!
                              : co! < 50
                                  ? Colors.amber[400]!
                                  : Colors.red[400]!,
                          width: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          "$co ppm",
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                      ))
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  'CO\u2082',
                  style: TextStyle(
                    fontSize: 35,
                  ),
                ),
              ),
              co2 == null
                  ? CircularProgressIndicator()
                  : Container(
                      decoration: BoxDecoration(
                        color: co2! < 50
                            ? Colors.green[100]
                            : co2! < 100
                                ? Colors.amber[100]
                                : Colors.red[100],
                        border: Border.all(
                          color: co2! < 20
                              ? Colors.green[400]!
                              : co2! < 50
                                  ? Colors.amber[400]!
                                  : Colors.red[400]!,
                          width: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          "$co2 ppm",
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                      ))
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  'PM 2.5',
                  style: TextStyle(
                    fontSize: 35,
                  ),
                ),
              ),
              pm25 == null
                  ? CircularProgressIndicator()
                  : Container(
                      decoration: BoxDecoration(
                        color: pm25! < 0.25
                            ? Colors.green[100]
                            : pm25! < 0.75
                                ? Colors.amber[100]
                                : Colors.red[100],
                        border: Border.all(
                          color: pm25! < 0.25
                              ? Colors.green[400]!
                              : pm25! < 0.75
                                  ? Colors.amber[400]!
                                  : Colors.red[400]!,
                          width: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          "$pm25 mg/m\u00B3",
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                      ))
            ],
          ),
          Text(""),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text("Ultima actualización:"),
              lastUpdated == null
                  ? CircularProgressIndicator()
                  : Column(
                      children: [
                        Text(
                            "${lastUpdated!.day}/${lastUpdated!.month}/${lastUpdated!.year} "),
                        Text(
                            " ${lastUpdated!.hour}:${lastUpdated!.minute}:${lastUpdated!.second}")
                      ],
                    )
            ],
          ),
          Text(
            "",
            style: TextStyle(
              fontSize: 5,
            ),
          )
        ],
      ),
    );
  }
}
