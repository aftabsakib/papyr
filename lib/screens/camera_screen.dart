import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/alarm.dart';
import '../models/alarm_history.dart';
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
  bool _taking = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    _controller = CameraController(cameras.first, ResolutionPreset.high);
    await _controller!.initialize();
    if (mounted) setState(() => _initialized = true);
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: _initialized
          ? Stack(
              children: [
                SizedBox.expand(child: CameraPreview(_controller!)),
                // Top instruction
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
                // Shutter button
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
