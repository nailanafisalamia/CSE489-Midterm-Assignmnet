class Landmark {
  final int id;
  final String title;
  final double lat;
  final double lon;
  final String imageUrl;
  final int visitCount;
  final double avgDistance;
  final double score;

  const Landmark({
    required this.id,
    required this.title,
    required this.lat,
    required this.lon,
    required this.imageUrl,
    required this.visitCount,
    required this.avgDistance,
    required this.score,
  });
}
