import 'dart:convert';
import 'package:http/http.dart';
import '../models/Organization.dart';

class HttpService {
  final URL = '';
  Future<Organization> getOrganizations() async {
    final response = await get(Uri.parse(URL));
    if (response.statusCode == 200) {
      return Organization.getOrganizations(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load album');
    }
  }
}
