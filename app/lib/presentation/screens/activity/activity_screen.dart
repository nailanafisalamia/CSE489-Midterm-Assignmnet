import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_landmarks2/core/theme/app_theme.dart';
import 'package:smart_landmarks2/data/models/visit_history_model.dart';
import 'package:smart_landmarks2/presentation/providers/visit_provider.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VisitProvider>().fetchHistory();
      _startPolling();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) {
        _pollTimer?.cancel();
        return;
      }
      final provider = context.read<VisitProvider>();
      final hasPending = provider.history
          .any((v) => v.status == 'pending' || v.status == 'offline');
      if (hasPending) {
        await provider.fetchHistory();
      } else {
        _pollTimer?.cancel();
      }
    });
  }

  // Group history by date
  Map<String, List<VisitHistoryModel>> _groupByDate(
      List<VisitHistoryModel> history) {
    final map = <String, List<VisitHistoryModel>>{};
    for (final v in history) {
      final dt = DateTime.fromMillisecondsSinceEpoch(v.visitedAt);
      final key = DateFormat('EEEE, MMM d yyyy').format(dt);
      map.putIfAbsent(key, () => []).add(v);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Trip Log'),
        actions: [
          Consumer<VisitProvider>(
            builder: (ctx, provider, child) => IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => provider.fetchHistory(),
            ),
          ),
        ],
      ),
      body: Consumer<VisitProvider>(
        builder: (context, provider, child) {
          if (!provider.loading &&
              provider.history.any((v) => v.status == 'pending' || v.status == 'offline') &&
              (_pollTimer == null || !_pollTimer!.isActive)) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _startPolling());
          }

          if (provider.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (provider.history.isEmpty) {
            return const _EmptyTrips();
          }

          final grouped = _groupByDate(provider.history);
          final keys = grouped.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: keys.length,
            itemBuilder: (ctx, gi) {
              final dateKey = keys[gi];
              final items = grouped[dateKey]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DateHeader(label: dateKey),
                  ...items.asMap().entries.map((entry) => _TripCard(
                        visit: entry.value,
                        index: gi * 4 + entry.key,
                      )),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final String label;
  const _DateHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Divider(color: AppColors.divider)),
        ],
      ),
    );
  }
}

class _TripCard extends StatefulWidget {
  final VisitHistoryModel visit;
  final int index;
  const _TripCard({required this.visit, required this.index});

  @override
  State<_TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<_TripCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) _anim.forward();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.12), end: Offset.zero)
            .animate(
                CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic)),
        child: _buildCard(),
      ),
    );
  }

  Widget _buildCard() {
    final visit = widget.visit;
    final (statusColor, statusIcon, statusLabel) = _statusInfo(visit.status);
    final time = DateFormat('h:mm a')
        .format(DateTime.fromMillisecondsSinceEpoch(visit.visitedAt));

    String distText = '';
    if (visit.status == 'done' && visit.distance != null) {
      final d = visit.distance!;
      distText = d >= 1000
          ? '${(d / 1000).toStringAsFixed(2)} km'
          : '${d.toStringAsFixed(0)} m';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(statusIcon, size: 18, color: statusColor),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        visit.landmarkTitle,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(time,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
                if (distText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.straighten_rounded,
                          size: 12, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(distText,
                          style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              fontFeatures: [FontFeature.tabularFigures()])),
                      const Text(' away',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ],
                if (visit.status == 'pending') ...[
                  const SizedBox(height: 6),
                  Row(
                    children: const [
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5, color: AppColors.scoreHigh),
                      ),
                      SizedBox(width: 6),
                      Text('Calculating distance...',
                          style: TextStyle(
                              color: AppColors.scoreHigh, fontSize: 11)),
                    ],
                  ),
                ],
                if (visit.status == 'offline') ...[
                  const SizedBox(height: 4),
                  Row(
                    children: const [
                      Icon(Icons.cloud_off_rounded,
                          size: 11, color: AppColors.textMuted),
                      SizedBox(width: 4),
                      Text('Queued for sync',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static (Color, IconData, String) _statusInfo(String status) {
    return switch (status) {
      'done' => (AppColors.scoreTop, Icons.check_circle_rounded, 'DONE'),
      'pending' => (AppColors.scoreHigh, Icons.schedule_rounded, 'PENDING'),
      'offline' => (AppColors.textMuted, Icons.cloud_off_rounded, 'QUEUED'),
      'failed' =>
        (AppColors.scoreLow, Icons.cancel_rounded, 'FAILED'),
      _ => (AppColors.textMuted, Icons.circle_outlined, status.toUpperCase()),
    };
  }
}

class _EmptyTrips extends StatelessWidget {
  const _EmptyTrips();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.luggage_rounded,
                size: 30, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          const Text('No trips logged yet',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Visit landmarks to see them here',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}
