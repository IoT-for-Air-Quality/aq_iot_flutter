import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTManager {
  // Private instance of client
  MqttServerClient? _client;
  final String _identifier;
  final String _host;

  // Constructor
  // ignore: sort_constructors_first
  MQTTManager({
    required String host,
    required String identifier,
  })  : _identifier = identifier,
        _host = host;

  void initializeMQTTClient() {
    _client = MqttServerClient("35.237.59.165", '');
    _client!.port = 1883;
    _client!.keepAlivePeriod = 200;
    _client!.onDisconnected = onDisconnected;
    _client!.secure = false;
    _client!.logging(on: true);

    /// Add the successful connection callback
    _client!.onConnected = onConnected;
    _client!.onSubscribed = onSubscribed;

    final MqttConnectMessage connMess = MqttConnectMessage()
        // .withClientIdentifier("client-67")
        .withClientIdentifier(_identifier)
        .withWillTopic(
            'willtopic') // If you set this you must set a will message
        .withWillMessage('My Will message')
        .startClean() // Non persistent session for testing
        .withWillQos(MqttQos.atLeastOnce);
    print('EXAMPLE::Mosquitto client connecting....');
    _client!.connectionMessage = connMess;
  }

  MqttClientConnectionStatus getConnStatus() {
    return _client!.connectionStatus!;
  }

  // Connect to the host
  // ignore: avoid_void_async
  void connect() async {
    assert(_client != null);
    try {
      print('EXAMPLE::Mosquitto start client connecting....');
      await _client!.connect();
    } on Exception catch (e) {
      print('EXAMPLE::client exception - $e');
      disconnect();
    }
  }

  Future<MqttClientConnectionStatus?> connect2() {
    assert(_client != null);
    try {
      print('EXAMPLE::Mosquitto start client connecting....');
      return _client!.connect();
    } on Exception catch (e) {
      print('EXAMPLE::client exception - $e');
      disconnect();
      return _client!.connect();
    }
  }

  void disconnect() {
    print('Disconnected');
    _client!.disconnect();
    connect();
  }

  void publish(String message, String _topic) {
    debugPrint("publishing");
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client!.publishMessage(_topic, MqttQos.exactlyOnce, builder.payload!);
  }

  /// The subscribed callback
  void onSubscribed(String topic) {
    print('EXAMPLE::Subscription confirmed for topic $topic');
  }

  Stream<List<MqttReceivedMessage<MqttMessage>>>? getUpdates() {
    return _client!.updates;
  }

  void listen() {
    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
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
    });
  }

  void subscribeDevice(int deviceId) {
    debugPrint("efghwekryugfkyuergkuesuhfyrgfhjksrghjfruj");
    Subscription? co =
        _client!.subscribe("AQ/Measurement/$deviceId/CO", MqttQos.atMostOnce);
    Subscription? co2 =
        _client!.subscribe("AQ/Measurement/$deviceId/CO2", MqttQos.atMostOnce);
    Subscription? pm25 = _client!
        .subscribe("AQ/Measurement/$deviceId/PM2.5", MqttQos.atMostOnce);
    debugPrint("${co!.topic}");
    debugPrint("${co2!.topic}");
    debugPrint("${pm25!.topic}");
  }

  /// The unsolicited disconnect callback
  void onDisconnected() {
    print('EXAMPLE::OnDisconnected client callback - Client disconnection');
    if (_client!.connectionStatus!.returnCode ==
        MqttConnectReturnCode.noneSpecified) {
      print('EXAMPLE::OnDisconnected callback is solicited, this is correct');
    }
  }

  /// The successful connect callback
  void onConnected() {
    print('EXAMPLE::Mosquitto client connected....');
    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      // ignore: avoid_as
      final MqttPublishMessage recMess = c![0].payload as MqttPublishMessage;

      // final MqttPublishMessage recMess = c![0].payload;
      final String pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message!);
      print(
          'EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
      print('');
    });
    print(
        'EXAMPLE::OnConnected client callback - Client connection was sucessful');
  }
}
