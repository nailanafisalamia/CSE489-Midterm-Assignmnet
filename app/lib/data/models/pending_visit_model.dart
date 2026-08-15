class PendingVisitModel {
  final int? id;
  final int landmarkId;
  final double userLat;
  final double userLon;
  final int createdAt;
  final int retryCount;

  const PendingVisitModel({
    this.id,
    required this.landmarkId,
    required this.userLat,
    required this.userLon,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'landmark_id': landmarkId,
        'user_lat': userLat,
        'user_lon': userLon,
        'created_at': createdAt,
        'retry_count': retryCount,
      };

  factory PendingVisitModel.fromMap(Map<String, dynamic> m) =>
      PendingVisitModel(
        id: m['id'] as int?,
        landmarkId: m['landmark_id'] as int,
        userLat: m['user_lat'] as double,
        userLon: m['user_lon'] as double,
        createdAt: m['created_at'] as int,
        retryCount: m['retry_count'] as int,
      );
}
