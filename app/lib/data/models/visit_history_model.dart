class VisitHistoryModel {
  final int? id;
  final int landmarkId;
  final String landmarkTitle;
  final String? jobId;
  final String status;
  final double? distance;
  final int visitedAt;
  final double userLat;
  final double userLon;

  const VisitHistoryModel({
    this.id,
    required this.landmarkId,
    required this.landmarkTitle,
    required this.jobId,
    required this.status,
    this.distance,
    required this.visitedAt,
    required this.userLat,
    required this.userLon,
  });

  VisitHistoryModel copyWith({
    String? jobId,
    String? status,
    double? distance,
  }) =>
      VisitHistoryModel(
        id: id,
        landmarkId: landmarkId,
        landmarkTitle: landmarkTitle,
        jobId: jobId ?? this.jobId,
        status: status ?? this.status,
        distance: distance ?? this.distance,
        visitedAt: visitedAt,
        userLat: userLat,
        userLon: userLon,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'landmark_id': landmarkId,
        'landmark_title': landmarkTitle,
        'job_id': jobId,
        'status': status,
        'distance': distance,
        'visited_at': visitedAt,
        'user_lat': userLat,
        'user_lon': userLon,
      };

  factory VisitHistoryModel.fromMap(Map<String, dynamic> m) =>
      VisitHistoryModel(
        id: m['id'] as int?,
        landmarkId: m['landmark_id'] as int,
        landmarkTitle: m['landmark_title'] as String,
        jobId: m['job_id'] as String?,
        status: m['status'] as String,
        distance: m['distance'] as double?,
        visitedAt: m['visited_at'] as int,
        userLat: m['user_lat'] as double,
        userLon: m['user_lon'] as double,
      );
}
