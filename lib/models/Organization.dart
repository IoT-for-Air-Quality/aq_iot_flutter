import 'package:flutter/material.dart';

class Organization {
  final int id;
  final String name;

  Organization({
    required this.id,
    required this.name,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'],
      name: json['name'],
    );
  }

  static getOrganizations(List data) {
    List<Organization> organtions = [];
    for (var element in data) {
      organtions.add(Organization(
        id: element['id'],
        name: element['name'],
      ));
    }
    return organtions;
  }
}
