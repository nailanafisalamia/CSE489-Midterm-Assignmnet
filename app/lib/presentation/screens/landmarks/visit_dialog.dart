import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:smart_landmarks2/core/theme/app_theme.dart';
import 'package:smart_landmarks2/data/models/landmark_model.dart';
import 'package:smart_landmarks2/presentation/providers/visit_provider.dart';
import 'package:smart_landmarks2/workers/background_workers.dart';

class VisitDialog extends StatefulWidget {
  final LandmarkModel landmark;
  const VisitDialog({super.key, required this.landmark});

  @override
  State<VisitDialog> createState() => _VisitDialogState();
}

class _VisitDialogState extends State<VisitDialog> {
  bool _locating = true;
  String? _locationError;
  Position? _position;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });
    try {
      bool ok = await Geolocator.isLocationServiceEnabled();
      if (!ok) throw Exception('GPS is disabled. Enable it and retry.');
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }
      if (perm == LocationPermission.deniedForever) {
        throw Exception('Permission permanently denied. Enable in Settings.');
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (mounted) setState(() => _position = pos);
    } catch (e) {
      if (mounted) setState(() => _locationError = e.toString());
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _visit() async {
    if (_position == null) return;
    final visitProvider = context.read<VisitProvider>();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);

    final success = await visitProvider.visitLandmark(
      widget.landmark.id,
      _position!.latitude,
      _position!.longitude,
    );

    if (success) {
      BackgroundWorkerManager.scheduleImmediateJobPoll();
      messenger.showSnackBar(SnackBar(
        content: Text(visitProvider.visitMessage ?? 'Visit submitted!'),
        backgroundColor: AppColors.scoreTop,
      ));
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(visitProvider.error ?? 'Visit failed'),
        backgroundColor: AppColors.scoreLow,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 20,
        right: 20,
        top: 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 18),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.hiking_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Log a Visit',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6)),
                    Text(
                      widget.landmark.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 14),

          // Location panel
          _buildLocationPanel(),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.border),
                    foregroundColor: AppColors.textSecondary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Consumer<VisitProvider>(
                  builder: (ctx, vp, child) {
                    final canVisit =
                        _position != null && !vp.visiting && !_locating;
                    return ElevatedButton(
                      onPressed: canVisit ? _visit : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: vp.visiting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Confirm Visit',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPanel() {
    if (_locating) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.accent),
            ),
            SizedBox(width: 12),
            Text('Locating your position...',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    if (_locationError != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.scoreLow.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.scoreLow.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_locationError!,
                style: const TextStyle(
                    color: AppColors.scoreLow, fontSize: 13)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _getLocation,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Try Again'),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.scoreLow,
                  padding: EdgeInsets.zero),
            ),
          ],
        ),
      );
    }

    if (_position == null) {
      return const Text('Could not get location.',
          style: TextStyle(color: AppColors.textMuted));
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.my_location_rounded,
                color: AppColors.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('GPS Ready',
                  style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              Text(
                '${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}',
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontFeatures: [FontFeature.tabularFigures()]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
