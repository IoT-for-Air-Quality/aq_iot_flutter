class Device {
  final int id;
  final double lat;
  final double long;
  final String type;
  final int organization;
  final bool display;

  Device({
    required this.id,
    required this.lat,
    required this.long,
    required this.type,
    required this.organization,
    required this.display,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      lat: json['lat'],
      long: json['long'],
      type: json['type'],
      organization: json['organization'],
      display: json['display'],
    );
  }
}
