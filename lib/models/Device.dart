class Device {
  int id;
  double lat;
  double long;
  String type;
  int organization;
  bool display;
  String wifiSSID;
  String wifiPASS;
  String swVersion;

  Device({
    required this.id,
    required this.lat,
    required this.long,
    required this.type,
    required this.organization,
    required this.display,
    required this.wifiSSID,
    required this.wifiPASS,
    required this.swVersion,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    if (json['lat'] == null) json['lat'] = 0;
    if (json['long'] == null) json['long'] = 0;
    return Device(
        id: json['id'] as int,
        lat: double.parse("${json['lat']}"),
        long: double.parse("${json['long']}"),
        type: json['type'],
        organization: json['organization'] as int,
        display: json['display'],
        wifiSSID: '',
        wifiPASS: '',
        swVersion: '');
  }
  static getDevices(List data) {
    List<Device> devices = [];
    for (var element in data) {
      devices.add(Device.fromJson(element));
    }
    return devices;
  }
}
