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
            co = double.parse(pt);
          });
        }
        if (c[0].topic == "AQ/Measurement/${widget.device.id}/CO2") {
          setState(() {
            co2 = double.parse(pt);
          });
        }
        if (c[0].topic == "AQ/Measurement/${widget.device.id}/PM2.5") {
          setState(() {
            pm25 = double.parse(pt);
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
                    fontSize: 20,
                  ),
                ),
              ),
              Text("$co")
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  'CO2',
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
              ),
              Text("$co2")
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  'PM2.5',
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
              ),
              Text("$pm25")
            ],
          )
        ],
      ),
    );
  }
}
