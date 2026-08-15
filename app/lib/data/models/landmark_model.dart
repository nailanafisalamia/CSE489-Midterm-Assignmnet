import 'package:smart_landmarks2/core/constants/app_constants.dart';

class LandmarkModel {
  final int id;
  final String title;
  final double lat;
  final double lon;
  final String image;
  final int visitCount;
  final double avgDistance;
  final double score;
  final bool isDeleted;

  const LandmarkModel({
    required this.id,
    required this.title,
    required this.lat,
    required this.lon,
    required this.image,
    required this.visitCount,
    required this.avgDistance,
    required this.score,
    this.isDeleted = false,
  });

  String get imageUrl => '${AppConstants.imageBaseUrl}$image';

  factory LandmarkModel.fromJson(Map<String, dynamic> j) => LandmarkModel(
        id: int.parse(j['id'].toString()),
        title: j['title'] as String? ?? '',
        lat: double.parse(j['lat'].toString()),
        lon: double.parse(j['lon'].toString()),
        image: j['image'] as String? ?? '',
        visitCount: int.parse((j['visit_count'] ?? '0').toString()),
        avgDistance: double.parse((j['avg_distance'] ?? '0').toString()),
        score: double.parse((j['score'] ?? '0').toString()),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'lat': lat,
        'lon': lon,
        'image': image,
        'visit_count': visitCount,
        'avg_distance': avgDistance,
        'score': score,
        'is_deleted': isDeleted ? 1 : 0,
      };

  factory LandmarkModel.fromMap(Map<String, dynamic> m) => LandmarkModel(
        id: m['id'] as int,
        title: m['title'] as String,
        lat: m['lat'] as double,
        lon: m['lon'] as double,
        image: m['image'] as String,
        visitCount: m['visit_count'] as int,
        avgDistance: m['avg_distance'] as double,
        score: m['score'] as double,
        isDeleted: (m['is_deleted'] as int) == 1,
      );
}
