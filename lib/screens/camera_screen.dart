import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/alarm.dart';
import '../models/alarm_history.dart';
import '../services/alarm_scheduler.dart';
import '../storage/alarm_storage.dart';
import '../theme.dart';

class CameraScreen extends StatefulWidget {
  final Alarm alarm;
  final DateTime startTime;
  const CameraScreen({super.key, required this.alarm, required this.startTime});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _initialized = false;
  bool _initFailed = false;
  bool _taking = false;
  bool _missionDone = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    setState(() { _initFailed = false; _initialized = false; });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _initFailed = true);
        return;
      }
      final controller = CameraController(cameras.first, ResolutionPreset.high);
      await controller.initialize();
      if (!mounted) { controller.dispose(); return; }
      _controller = controller;
      setState(() => _initialized = true);
    } catch (_) {
      if (mounted) setState(() => _initFailed = true);
    }
  }

  Future<void> _takePhoto() async {
    if (!_initialized || _taking || _controller == null) return;
    setState(() => _taking = true);

    try {
      final file = await _controller!.takePicture();
      final storage = AlarmStorage();
      await storage.init();
      final seconds = DateTime.now().difference(widget.startTime).inSeconds;
      await storage.saveHistory(AlarmHistory(
        id: const Uuid().v4(),
        alarmId: widget.alarm.id,
        firedAt: widget.startTime,
        status: AlarmStatus.completed,
        photoPath: file.path,
        secondsToComplete: seconds,
      ));
      await AlarmScheduler.dismissNotification(widget.alarm.id);
      if (mounted) setState(() => _missionDone = true);
      await Future.delayed(const Duration(milliseconds: 1800));
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (mounted) setState(() => _taking = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_missionDone) {
      return const _SuccessOverlay();
    }

    if (_initFailed) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined, color: BedBreakerTheme.textSecondary, size: 64),
              const SizedBox(height: 16),
              Text(
                'Camera unavailable',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: BedBreakerTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check camera permissions in Settings',
                style: GoogleFonts.spaceGrotesk(color: BedBreakerTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _initCamera,
                style: FilledButton.styleFrom(backgroundColor: BedBreakerTheme.accent),
                child: Text('Retry', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: _initialized
          ? Stack(
              children: [
                SizedBox.expand(child: CameraPreview(_controller!)),
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Text(
                      'Take a photo to stop the alarm',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: BedBreakerTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 48, left: 0, right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _taking ? null : _takePhoto,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: _taking ? 64 : 76,
                        height: _taking ? 64 : 76,
                        decoration: BoxDecoration(
                          color: _taking
                              ? BedBreakerTheme.textSecondary
                              : BedBreakerTheme.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: BedBreakerTheme.textPrimary,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: BedBreakerTheme.success.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: _taking
                            ? const Center(
                                child: SizedBox(
                                  width: 24, height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: BedBreakerTheme.textPrimary,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_rounded,
                                color: BedBreakerTheme.onSuccess,
                                size: 32,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator(color: BedBreakerTheme.accent)),
    );
  }
}

class _SuccessOverlay extends StatefulWidget {
  const _SuccessOverlay();

  @override
  State<_SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<_SuccessOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BedBreakerTheme.bgPrimary,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: BedBreakerTheme.success.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: BedBreakerTheme.success,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Mission Complete!',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: BedBreakerTheme.success,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You crushed it. Alarm dismissed.',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    color: BedBreakerTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
