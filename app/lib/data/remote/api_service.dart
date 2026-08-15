import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_landmarks2/core/constants/app_constants.dart';
import 'package:smart_landmarks2/core/errors/app_exception.dart';
import 'package:smart_landmarks2/data/models/landmark_model.dart';

class ApiService {
  Uri _uri(String action, [Map<String, String>? extra]) {
    final params = {'action': action, 'key': AppConstants.apiKey, ...?extra};
    return Uri.parse(AppConstants.baseUrl).replace(queryParameters: params);
  }

  Future<List<LandmarkModel>> getLandmarks() async {
    try {
      final res = await http.get(_uri('get_landmarks'));
      _checkStatus(res);
      final decoded = jsonDecode(res.body);
      List<dynamic> list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map<String, dynamic>) {
        final d = decoded['data'];
        list = d is List ? d : [];
      } else {
        list = [];
      }
      return list
          .map((e) => LandmarkModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException('Failed to fetch landmarks: $e');
    }
  }

  Future<Map<String, dynamic>> visitLandmark(
      int id, double lat, double lon) async {
    try {
      final res = await http.post(
        _uri('visit_landmark'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'landmark_id': id, 'user_lat': lat, 'user_lon': lon}),
      );
      _checkStatus(res);
      final decoded = jsonDecode(res.body);
      return decoded is Map<String, dynamic> ? decoded : {};
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException('Failed to visit landmark: $e');
    }
  }

  Future<Map<String, dynamic>> getJobStatus(String jobId) async {
    try {
      final res = await http.get(_uri('get_job_status', {'job_id': jobId}));
      _checkStatus(res);
      final decoded = jsonDecode(res.body);
      return decoded is Map<String, dynamic> ? decoded : {};
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException('Failed to get job status: $e');
    }
  }

  Future<void> deleteLandmark(int id) async {
    try {
      final res = await http.post(
        _uri('delete_landmark'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'id=$id',
      );
      _checkStatus(res);
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException('Failed to delete landmark: $e');
    }
  }

  Future<void> restoreLandmark(int id) async {
    try {
      final res = await http.post(
        _uri('restore_landmark'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'id=$id',
      );
      _checkStatus(res);
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException('Failed to restore landmark: $e');
    }
  }

  Future<LandmarkModel> createLandmark(
      String title, double lat, double lon, dynamic image) async {
    try {
      final request = http.MultipartRequest('POST', _uri('create_landmark'));
      request.fields['title'] = title;
      request.fields['lat'] = lat.toString();
      request.fields['lon'] = lon.toString();
      if (image != null) {
        request.files
            .add(await http.MultipartFile.fromPath('image', image.path));
      }
      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      _checkStatus(res);

      final decoded = jsonDecode(res.body);
      final Map<String, dynamic> root =
          decoded is Map<String, dynamic> ? decoded : {};
      final inner = root['data'];
      final json = inner is Map<String, dynamic> ? inner : root;

      // Full landmark response — parse directly
      if (json['lat'] != null && json['lon'] != null && json['id'] != null) {
        try {
          return LandmarkModel.fromJson(json);
        } catch (_) {}
      }

      // Partial response (only id / status returned) — build from inputs
      final id =
          int.tryParse((json['id'] ?? root['id'] ?? '0').toString()) ?? 0;
      return LandmarkModel(
        id: id,
        title: title,
        lat: lat,
        lon: lon,
        image: '',
        visitCount: 0,
        avgDistance: 0,
        score: 0,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException('Failed to create landmark: $e');
    }
  }

  void _checkStatus(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException('HTTP ${res.statusCode}: ${res.body}',
          statusCode: res.statusCode);
    }
  }
}
