class Measurement {
  final int id;
  final DateTime timestamp;
  final int variable;
  final int device;
  final double value;

  Measurement({
    required this.id,
    required this.timestamp,
    required this.variable,
    required this.device,
    required this.value,
  });

  factory Measurement.fromJson(Map<String, dynamic> json) {
    return Measurement(
        id: json['id'],
        timestamp: DateTime.parse(json['timestamp']),
        device: json['device'],
        variable: json['variable'],
        value: (json['value']).toDouble());
  }

  static getMeasurements(List data) {
    List<Measurement> measurements = [];
    for (var element in data) {
      measurements.add(Measurement.fromJson(element));
    }
    return measurements;
  }
}
