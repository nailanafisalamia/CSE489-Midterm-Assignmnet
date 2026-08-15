import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import 'package:smart_landmarks2/core/constants/app_constants.dart';
import 'package:smart_landmarks2/core/theme/app_theme.dart';
import 'package:smart_landmarks2/data/models/landmark_model.dart';
import 'package:smart_landmarks2/presentation/providers/landmark_provider.dart';
import 'package:smart_landmarks2/presentation/screens/landmarks/visit_dialog.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapCtrl = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        title: const Text('Explore Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                context.read<LandmarkProvider>().fetchLandmarks(forceRefresh: true),
          ),
        ],
      ),
      body: Consumer<LandmarkProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              FlutterMap(
                mapController: _mapCtrl,
                options: MapOptions(
                  initialCenter: LatLng(AppConstants.defaultLat, AppConstants.defaultLon),
                  initialZoom: AppConstants.defaultZoom,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.cse489.smart_landmarks2',
                  ),
                  MarkerLayer(
                    markers: provider.landmarks
                        .map((lm) => _buildMarker(lm))
                        .toList(),
                  ),
                ],
              ),
              // Score key strip at bottom
              Positioned(
                bottom: 90,
                left: 12,
                right: 12,
                child: _ScoreKeyStrip(),
              ),
              if (provider.loading)
                Positioned(
                  top: kToolbarHeight + MediaQuery.of(context).padding.top + 8,
                  left: 0,
                  right: 0,
                  child: const Center(
                    child: _LoadingChip(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Marker _buildMarker(LandmarkModel lm) {
    return Marker(
      point: LatLng(lm.lat, lm.lon),
      width: 40,
      height: 52,
      child: _PinMarker(
        score: lm.score,
        onTap: () => _showSheet(lm),
      ),
    );
  }

  void _showSheet(LandmarkModel lm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _LandmarkDetailSheet(landmark: lm, parentContext: context),
    );
  }
}

// ── Teardrop pin marker ──────────────────────────────────────────────────────

class _PinMarker extends StatelessWidget {
  final double score;
  final VoidCallback onTap;
  const _PinMarker({required this.score, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forScore(score);
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        size: const Size(40, 52),
        painter: _PinPainter(color: color),
        child: Align(
          alignment: const Alignment(0, -0.3),
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            child: Center(
              child: Text(
                score >= 100 ? '∞' : score.toStringAsFixed(0),
                style: TextStyle(
                  color: color,
                  fontSize: score >= 100 ? 8 : 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  final Color color;
  const _PinPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final shadowPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final cx = size.width / 2;
    final r = size.width / 2;
    final headBottom = size.height * 0.62;
    final path = Path()
      ..moveTo(cx, size.height)
      ..lineTo(cx - 6, headBottom)
      ..arcToPoint(
        Offset(cx + 6, headBottom),
        radius: Radius.circular(r),
        largeArc: true,
        clockwise: false,
      )
      ..close();

    canvas.drawCircle(Offset(cx, r), r + 2, shadowPaint);
    canvas.drawCircle(Offset(cx, r), r, paint);
    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, r), r - 1, borderPaint);
  }

  @override
  bool shouldRepaint(_PinPainter old) => old.color != color;
}

// ── Score key strip ──────────────────────────────────────────────────────────

class _ScoreKeyStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final entry in [
            ('< 10', AppColors.scoreLow),
            ('10–25', AppColors.scoreMid),
            ('25–50', AppColors.scoreHigh),
            ('≥ 50', AppColors.scoreTop),
          ])
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: entry.$2,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  entry.$1,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LoadingChip extends StatelessWidget {
  const _LoadingChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
          SizedBox(width: 8),
          Text('Loading...', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Detail bottom sheet ──────────────────────────────────────────────────────

class _LandmarkDetailSheet extends StatelessWidget {
  final LandmarkModel landmark;
  final BuildContext parentContext;
  const _LandmarkDetailSheet({required this.landmark, required this.parentContext});

  @override
  Widget build(BuildContext context) {
    final scoreColor = AppColors.forScore(landmark.score);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Image banner
          if (landmark.image.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(0)),
              child: CachedNetworkImage(
                imageUrl: landmark.imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (ctx, url, err) => Container(
                  height: 160,
                  color: AppColors.surfaceElevated,
                  child: const Icon(Icons.landscape_rounded,
                      size: 48, color: AppColors.border),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        landmark.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _ScoreBadge(score: landmark.score, color: scoreColor),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  children: [
                    _StatChip(
                        icon: Icons.people_outline_rounded,
                        label: '${landmark.visitCount} visits'),
                    _StatChip(
                        icon: Icons.straighten_rounded,
                        label:
                            '${landmark.avgDistance.toStringAsFixed(0)} m avg'),
                    _StatChip(
                        icon: Icons.place_outlined,
                        label:
                            '${landmark.lat.toStringAsFixed(3)}, ${landmark.lon.toStringAsFixed(3)}'),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.directions_walk_rounded),
                    label: const Text('Visit This Landmark'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: parentContext,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        useSafeArea: true,
                        builder: (_) => VisitDialog(landmark: landmark),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final double score;
  final Color color;
  const _ScoreBadge({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        score.toStringAsFixed(1),
        style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
