import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_landmarks2/core/theme/app_theme.dart';
import 'package:smart_landmarks2/presentation/providers/landmark_provider.dart';

class AddLandmarkScreen extends StatefulWidget {
  const AddLandmarkScreen({super.key});

  @override
  State<AddLandmarkScreen> createState() => _AddLandmarkScreenState();
}

class _AddLandmarkScreenState extends State<AddLandmarkScreen> {
  // Wizard steps: 0=Details, 1=Location, 2=Photo
  int _step = 0;

  final _titleController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  final _titleKey = GlobalKey<FormFieldState>();
  final _coordKey = GlobalKey<FormState>();

  File? _imageFile;
  bool _locating = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Rebuild so _validateCurrentStep() re-evaluates whenever text changes
    _titleController.addListener(() => setState(() {}));
    _latController.addListener(() => setState(() {}));
    _lonController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  Future<void> _getGps() async {
    setState(() => _locating = true);
    try {
      bool ok = await Geolocator.isLocationServiceEnabled();
      if (!ok) throw Exception('Location services disabled');
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) throw Exception('Permission denied');
      }
      if (perm == LocationPermission.deniedForever) {
        throw Exception('Permission permanently denied');
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10)),
      );
      _latController.text = pos.latitude.toStringAsFixed(6);
      _lonController.text = pos.longitude.toStringAsFixed(6);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('GPS error: $e'),
            backgroundColor: AppColors.scoreLow),
      );
    } finally {
      setState(() => _locating = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 80);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  bool _validateCurrentStep() {
    if (_step == 0) {
      return _titleController.text.trim().isNotEmpty;
    }
    if (_step == 1) {
      final lat = double.tryParse(_latController.text.trim());
      final lon = double.tryParse(_lonController.text.trim());
      return lat != null &&
          lon != null &&
          lat >= -90 &&
          lat <= 90 &&
          lon >= -180 &&
          lon <= 180;
    }
    return true;
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final provider = context.read<LandmarkProvider>();
    final ok = await provider.createLandmark(
      _titleController.text.trim(),
      double.parse(_latController.text.trim()),
      double.parse(_lonController.text.trim()),
      _imageFile,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Landmark created!'),
            backgroundColor: AppColors.scoreTop),
      );
      setState(() {
        _step = 0;
        _titleController.clear();
        _latController.clear();
        _lonController.clear();
        _imageFile = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(provider.error ?? 'Failed'),
            backgroundColor: AppColors.scoreLow),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('New Landmark'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: _StepBar(currentStep: _step, totalSteps: 3),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _buildStep(),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              if (_step > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _step--),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.border),
                      foregroundColor: AppColors.textSecondary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Back'),
                  ),
                ),
              if (_step > 0) const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _validateCurrentStep()
                      ? (_step < 2
                          ? () => setState(() => _step++)
                          : (_submitting ? null : _submit))
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_step < 2 ? 'Continue' : 'Create',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _Step0Details(controller: _titleController, fieldKey: _titleKey);
      case 1:
        return _Step1Location(
          latCtrl: _latController,
          lonCtrl: _lonController,
          formKey: _coordKey,
          locating: _locating,
          onGps: _getGps,
        );
      default:
        return _Step2Photo(
          imageFile: _imageFile,
          onPick: _pickImage,
          onClear: () => setState(() => _imageFile = null),
        );
    }
  }
}

// ── Step progress bar ────────────────────────────────────────────────────────

class _StepBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const _StepBar({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      color: AppColors.border,
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: (currentStep + 1) / totalSteps,
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
      ),
    );
  }
}

// ── Step 0: Title ────────────────────────────────────────────────────────────

class _Step0Details extends StatelessWidget {
  final TextEditingController controller;
  final GlobalKey<FormFieldState> fieldKey;
  const _Step0Details({required this.controller, required this.fieldKey});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepLabel(step: 1, title: 'Name your landmark'),
          const SizedBox(height: 20),
          TextFormField(
            key: fieldKey,
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Landmark Title *',
              hintText: 'e.g. Old City Gate',
              prefixIcon: Icon(Icons.edit_location_alt_rounded, size: 20),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Title required' : null,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 18, color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Give a clear, recognizable name. Location and photo are optional.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
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

// ── Step 1: Location ─────────────────────────────────────────────────────────

class _Step1Location extends StatelessWidget {
  final TextEditingController latCtrl;
  final TextEditingController lonCtrl;
  final GlobalKey<FormState> formKey;
  final bool locating;
  final VoidCallback onGps;

  const _Step1Location({
    required this.latCtrl,
    required this.lonCtrl,
    required this.formKey,
    required this.locating,
    required this.onGps,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepLabel(step: 2, title: 'Set the location'),
          const SizedBox(height: 20),

          // GPS button
          GestureDetector(
            onTap: locating ? null : onGps,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  locating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.accent),
                        )
                      : const Icon(Icons.gps_fixed_rounded,
                          color: AppColors.accent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    locating ? 'Getting GPS...' : 'Use My Current Location',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: const [
              Expanded(child: Divider(color: AppColors.divider)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('or enter manually',
                    style:
                        TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ),
              Expanded(child: Divider(color: AppColors.divider)),
            ],
          ),

          const SizedBox(height: 16),

          Form(
            key: formKey,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: latCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      prefixIcon:
                          Icon(Icons.north_rounded, size: 18),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    validator: (v) {
                      final d = double.tryParse(v?.trim() ?? '');
                      if (d == null || d < -90 || d > 90) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: lonCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      prefixIcon: Icon(Icons.east_rounded, size: 18),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    validator: (v) {
                      final d = double.tryParse(v?.trim() ?? '');
                      if (d == null || d < -180 || d > 180) return 'Invalid';
                      return null;
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

// ── Step 2: Photo ────────────────────────────────────────────────────────────

class _Step2Photo extends StatelessWidget {
  final File? imageFile;
  final Future<void> Function(ImageSource) onPick;
  final VoidCallback onClear;

  const _Step2Photo({
    required this.imageFile,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepLabel(step: 3, title: 'Add a photo (optional)'),
          const SizedBox(height: 20),

          if (imageFile != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(imageFile!,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onClear,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, style: BorderStyle.solid),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined,
                      size: 36, color: AppColors.textMuted),
                  SizedBox(height: 8),
                  Text('No photo selected',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 14)),
                ],
              ),
            ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library_rounded, size: 18),
                  label: const Text('Gallery'),
                  onPressed: () => onPick(ImageSource.gallery),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.camera_alt_rounded, size: 18),
                  label: const Text('Camera'),
                  onPressed: () => onPick(ImageSource.camera),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'You can skip this step — photos are optional and can be added later.',
              style:
                  TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  final int step;
  final String title;
  const _StepLabel({required this.step, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEP $step OF 3',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}
