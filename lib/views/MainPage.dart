import 'package:aq_iot_flutter/views/BTConnection.dart';
import 'package:aq_iot_flutter/views/DeviceSelection.dart';
import 'package:aq_iot_flutter/views/Network.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MainPage extends StatefulWidget {
  MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AQ IoT sensor nodes'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            kIsWeb ? Container() : BTConection(),
            DeviceSelection(),
            Network()
          ],
        ),
      ),
    );
  }
}
