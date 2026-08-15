import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_landmarks2/core/theme/app_theme.dart';
import 'package:smart_landmarks2/presentation/providers/landmark_provider.dart';
import 'package:smart_landmarks2/presentation/screens/landmarks/visit_dialog.dart';
import 'package:smart_landmarks2/presentation/widgets/landmark_card.dart';

class LandmarksScreen extends StatefulWidget {
  const LandmarksScreen({super.key});

  @override
  State<LandmarksScreen> createState() => _LandmarksScreenState();
}

class _LandmarksScreenState extends State<LandmarksScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  final _searchCtrl = TextEditingController();
  final List<Animation<double>> _itemAnims = [];
  int _animatedForCount = -1;

  @override
  void dispose() {
    _anim.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _triggerAnimation(int count) {
    if (count == _animatedForCount || count == 0) return;
    _animatedForCount = count;
    final limit = min(count, 16);
    _itemAnims
      ..clear()
      ..addAll(List.generate(limit, (i) {
        final start = (i * 0.06).clamp(0.0, 0.72);
        final end = (start + 0.4).clamp(0.0, 1.0);
        return CurvedAnimation(
          parent: _anim,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        );
      }));
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Consumer<LandmarkProvider>(
        builder: (context, provider, child) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _triggerAnimation(provider.landmarks.length);
          });

          return CustomScrollView(
            slivers: [
              // App bar with search
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.bg,
                elevation: 0,
                title: const Text('Landmarks'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () =>
                        provider.fetchLandmarks(forceRefresh: true),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: provider.setSearch,
                      decoration: InputDecoration(
                        hintText: 'Search landmarks...',
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.textMuted, size: 20),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  provider.setSearch('');
                                },
                              )
                            : null,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                    ),
                  ),
                ),
              ),

              // Sort + filter chips
              SliverToBoxAdapter(
                child: _SortChips(provider: provider),
              ),

              // Error banner
              if (provider.error != null)
                SliverToBoxAdapter(
                  child: _ErrorBanner(message: provider.error!),
                ),

              // List
              if (provider.loading && provider.landmarks.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              if (!provider.loading && provider.landmarks.isEmpty)
                const SliverFillRemaining(child: _EmptyState()),
              if (provider.landmarks.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.only(top: 4, bottom: 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final lm = provider.landmarks[i];
                        final anim =
                            i < _itemAnims.length ? _itemAnims[i] : null;
                        return LandmarkCard(
                          landmark: lm,
                          entranceAnim: anim,
                          onVisit: () => _showVisit(context, lm),
                          onDelete: () =>
                              _confirmDelete(context, provider, lm.id, lm.title),
                        );
                      },
                      childCount: provider.landmarks.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showVisit(BuildContext context, lm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => VisitDialog(landmark: lm),
    );
  }

  void _confirmDelete(
      BuildContext ctx, LandmarkProvider provider, int id, String title) {
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Landmark?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text('"$title" will be soft-deleted and can be restored.',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.scoreLow,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(dCtx);
              final ok = await provider.deleteLandmark(id);
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: Text(ok ? '"$title" removed.' : provider.error ?? 'Failed'),
                backgroundColor:
                    ok ? AppColors.scoreTop : AppColors.scoreLow,
              ));
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _SortChips extends StatelessWidget {
  final LandmarkProvider provider;
  const _SortChips({required this.provider});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          const Text('Sort:',
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          for (final entry in [
            (SortOrder.scoreDesc, 'Score ↓'),
            (SortOrder.scoreAsc, 'Score ↑'),
            (SortOrder.nameAsc, 'A–Z'),
          ])
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(entry.$2),
                selected: provider.sortOrder == entry.$1,
                onSelected: (_) => provider.setSortOrder(entry.$1),
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: provider.sortOrder == entry.$1
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: provider.sortOrder == entry.$1
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : AppColors.border,
                  ),
                ),
                backgroundColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          const SizedBox(width: 12),
          const Text('Min:',
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          SizedBox(
            width: 130,
            child: Slider(
              value: provider.minScore,
              min: 0,
              max: 100,
              divisions: 20,
              label: provider.minScore.toStringAsFixed(0),
              onChanged: provider.setMinScore,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.scoreLow.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.scoreLow.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.scoreLow, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: AppColors.scoreLow, fontSize: 13))),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
            child: const Icon(Icons.place_outlined,
                size: 30, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          const Text('No landmarks found',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Adjust filter or refresh',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}
