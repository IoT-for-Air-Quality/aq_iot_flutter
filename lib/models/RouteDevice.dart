// ignore_for_file: non_constant_identifier_names

class RouteDevice {
  int id;
  int device;
  DateTime starttimestamp;
  DateTime endtimestamp;
  int update_frecuency;
  List points;
  bool show;

  RouteDevice({
    required this.id,
    required this.device,
    required this.starttimestamp,
    required this.endtimestamp,
    required this.update_frecuency,
    required this.points,
    required this.show,
  });

  factory RouteDevice.fromJson(Map<String, dynamic> json) {
    return RouteDevice(
        id: json['id'],
        device: json['device'],
        starttimestamp: json['endtimestamp'] != null
            ? DateTime.parse(json['starttimestamp'])
            : DateTime(1),
        endtimestamp: json['endtimestamp'] != null
            ? DateTime.parse(json['endtimestamp'])
            : DateTime(1),
        update_frecuency: json['update_frecuency'],
        points: json['points'],
        show: false);
  }

  static getRoutes(List data) {
    List<RouteDevice> routes = [];
    for (var element in data) {
      routes.add(RouteDevice.fromJson(element));
    }
    return routes;
  }
}
