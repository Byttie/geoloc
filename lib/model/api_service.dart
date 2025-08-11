import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'entity.dart';

class ApiService {
  static const String baseUrl = 'https://labs.anontech.info/cse489/t3/api.php';

  // Create Entity - POST request
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

  // Retrieve all entities - GET request
  Future<List<Entity>?> getAllEntities() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final entities = jsonData.map((json) => Entity.fromJson(json)).toList();
        
        // Filter out invalid entities (empty title, 0,0 coordinates)
        final validEntities = entities.where((entity) {
          return entity.title.isNotEmpty && 
                 (entity.lat != 0.0 || entity.lon != 0.0);
        }).toList();
        
        return validEntities;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Update Entity - PUT request
  Future<Map<String, dynamic>?> updateEntity({
    required int id,
    required String title,
    required double lat,
    required double lon,
    File? imageFile,
  }) async {
    try {
      if (imageFile != null) {
        // If image is provided, use multipart form data
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
        // If no image, use x-www-form-urlencoded format
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

  // Delete Entity - DELETE request (assuming this endpoint exists)
  Future<bool> deleteEntity(int id) async {
    try {
      final response = await http.delete(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'id': id}),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get Entity by ID (if needed)
  Future<Entity?> getEntityById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?id=$id'),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return Entity.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Helper method to check if the API is reachable
  Future<bool> checkApiConnection() async {
    try {
      final response = await http.get(Uri.parse(baseUrl)).timeout(
        const Duration(seconds: 10),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
} 