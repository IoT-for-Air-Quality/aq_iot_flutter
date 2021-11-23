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
        title: const Text('Página principal'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Padding(
                    padding: EdgeInsets.all(17.5),
                    child: Expanded(
                      child: Text(
                        "Conectarse a un nodo",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                        ),
                      ),
                    ))
              ],
            ),
            kIsWeb ? Container() : BTConection(),
            DeviceSelection(),
            Network()
          ],
        ),
      ),
    );
  }
}
