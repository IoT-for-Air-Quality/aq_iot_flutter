import 'dart:convert';
import 'dart:io';
import 'package:aq_iot_flutter/models/Device.dart';
import 'package:aq_iot_flutter/models/Variable.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../models/Organization.dart';

class HttpService {
  final IP = '192.168.0.3:3000';
  final orgResource = '/organization';
  final deviceResource = '/device';
  final variableResource = '/variable';
  final routeResource = '/route';
  Future<List<Organization>> getOrganizations() async {
    debugPrint("hfwjkh");

    final uri = Uri.http(IP, orgResource);
    final response = await get(uri);
    if (response.statusCode == 200) {
      return Organization.getOrganizations(jsonDecode(response.body) as List);
    } else {
      throw Exception('Failed to load organizations');
    }
  }

  Future<List<Variable>> getVariables() async {
    final uri = Uri.http(IP, variableResource);
    final response = await get(uri);
    if (response.statusCode == 200) {
      return Variable.getVariables(jsonDecode(response.body) as List);
    } else {
      throw Exception('Failed to load variables');
    }
  }

  Future<int> postDevice(Device device) async {
    final queryParameters = {
      'org': "${device.organization}",
      'lat': "${device.lat}",
      'long': "${device.long}",
      'type': "${device.type}",
      'display': "${device.display}",
    };
    final uri = Uri.http(IP, deviceResource, queryParameters);
    final response = await post(uri);
    debugPrint("${response.statusCode}");
    if (response.statusCode == 200) {
      return jsonDecode(response.body)[0]['id'] as int;
    } else {
      throw Exception('Failed to post device');
    }
  }

  Future<int> postRoute(int deviceId, int updateFrecuency) async {
    final queryParameters = {
      'device': "${deviceId}",
      'update_frecuency': "${updateFrecuency}"
    };
    final uri = Uri.http(IP, routeResource, queryParameters);
    final response = await post(uri);
    debugPrint("${response.statusCode}");
    if (response.statusCode == 200) {
      return jsonDecode(response.body)[0]['id'] as int;
    } else {
      throw Exception('Failed to start route');
    }
  }

  Future<int> endRoute(int routeId) async {
    final queryParameters = {
      'id': "${routeId}",
    };
    final uri = Uri.http(IP, routeResource, queryParameters);
    final response = await put(uri);
    debugPrint("${response.statusCode}");
    if (response.statusCode == 200) {
      return jsonDecode(response.body)[0]['id'] as int;
    } else {
      throw Exception('Failed to end route');
    }
  }
}
