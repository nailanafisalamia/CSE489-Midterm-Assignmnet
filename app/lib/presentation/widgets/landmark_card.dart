import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:smart_landmarks2/core/theme/app_theme.dart';
import 'package:smart_landmarks2/data/models/landmark_model.dart';

class LandmarkCard extends StatelessWidget {
  final LandmarkModel landmark;
  final VoidCallback? onVisit;
  final VoidCallback? onDelete;
  final Animation<double>? entranceAnim;

  const LandmarkCard({
    super.key,
    required this.landmark,
    this.onVisit,
    this.onDelete,
    this.entranceAnim,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = _CardContent(
        landmark: landmark, onVisit: onVisit, onDelete: onDelete);

    if (entranceAnim == null) return card;

    return AnimatedBuilder(
      animation: entranceAnim!,
      builder: (ctx, child) {
        final v = entranceAnim!.value.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(-30 * (1 - v), 0),
          child: Opacity(opacity: v, child: child),
        );
      },
      child: card,
    );
  }
}

class _CardContent extends StatelessWidget {
  final LandmarkModel landmark;
  final VoidCallback? onVisit;
  final VoidCallback? onDelete;

  const _CardContent({
    required this.landmark,
    this.onVisit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = AppColors.forScore(landmark.score);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left score accent bar
              Container(
                width: 4,
                decoration: BoxDecoration(color: scoreColor),
              ),

              // Thumbnail
              ClipRect(
                child: SizedBox(
                  width: 80,
                  child: landmark.image.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: landmark.imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (ctx, url, err) =>
                              _Placeholder(color: scoreColor),
                        )
                      : _Placeholder(color: scoreColor),
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              landmark.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: scoreColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              landmark.score.toStringAsFixed(1),
                              style: TextStyle(
                                color: scoreColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined,
                              size: 11, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Text(
                            '${landmark.lat.toStringAsFixed(3)}, ${landmark.lon.toStringAsFixed(3)}',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.people_outline_rounded,
                              size: 11, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Text(
                            '${landmark.visitCount} visits · ${landmark.avgDistance.toStringAsFixed(0)} m avg',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (onVisit != null)
                            _TerraButton(
                              label: 'Visit',
                              icon: Icons.directions_walk_rounded,
                              color: AppColors.primary,
                              onTap: onVisit!,
                            ),
                          if (onDelete != null) ...[
                            const SizedBox(width: 6),
                            _TerraButton(
                              label: 'Remove',
                              icon: Icons.remove_circle_outline_rounded,
                              color: AppColors.textMuted,
                              onTap: onDelete!,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final Color color;
  const _Placeholder({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.08),
      child: Center(
        child: Icon(Icons.landscape_rounded,
            size: 28, color: color.withValues(alpha: 0.4)),
      ),
    );
  }
}

class _TerraButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TerraButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
