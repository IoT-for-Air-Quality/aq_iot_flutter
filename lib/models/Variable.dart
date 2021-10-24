class Variable {
  final int id;
  final String name;
  final String unit;
  bool isActive = false;

  Variable({
    required this.id,
    required this.name,
    required this.unit,
  });

  factory Variable.fromJson(Map<String, dynamic> json) {
    return Variable(id: json['id'], name: json['name'], unit: json['unit']);
  }

  static getVariables(List data) {
    List<Variable> organtions = [];
    for (var element in data) {
      organtions.add(Variable(
          id: element['id'], name: element['name'], unit: element['unit']));
    }
    return organtions;
  }
}
