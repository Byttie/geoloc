import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'entity.dart';

class ApiService {
  static const String baseUrl = 'https://labs.anontech.info/cse489/t3/api.php';

  Future<Map<String, dynamic>?> createEntity({
    required String title,
    required double lat,
    required double lon,
    File? imageFile,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      
      // Add form fields
      request.fields['title'] = title;
      request.fields['lat'] = lat.toString();
      request.fields['lon'] = lon.toString();
      
      // Add image file if provided
      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
      }
      
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(responseBody);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<List<Entity>?> getAllEntities() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      
            if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final entities = jsonData.map((json) => Entity.fromJson(json)).toList();
        
        return entities;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateEntity({
    required int id,
    required String title,
    required double lat,
    required double lon,
    File? imageFile,
  }) async {
    try {
      if (imageFile != null) {
        var request = http.MultipartRequest('PUT', Uri.parse(baseUrl));
        
        request.fields['id'] = id.toString();
        request.fields['title'] = title;
        request.fields['lat'] = lat.toString();
        request.fields['lon'] = lon.toString();
        
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
        
        var response = await request.send();
        var responseBody = await response.stream.bytesToString();
        
        if (response.statusCode == 200) {
          return json.decode(responseBody);
        } else {
          return null;
        }
      } else {
        final response = await http.put(
          Uri.parse(baseUrl),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'id': id.toString(),
            'title': title,
            'lat': lat.toString(),
            'lon': lon.toString(),
          },
        );
        
        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else {
          return null;
        }
      }
    } catch (e) {
      return null;
    }
  }


} 