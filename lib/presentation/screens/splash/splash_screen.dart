import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../shell/app_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final VideoPlayerController _controller;
  bool _navigated = false;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    Future.delayed(const Duration(seconds: 8), _goHome);

    _controller = VideoPlayerController.asset('assets/videos/splash1.mp4');

    WidgetsBinding.instance.addPostFrameCallback((_) => _initVideo());
  }

  Future<void> _initVideo() async {
    try {
      await _controller.initialize();
      if (!mounted) return;
      await _controller.setLooping(false);
      await _controller.play();

      final dur = _controller.value.duration;
      if (dur > Duration.zero) {
        Future.delayed(dur + const Duration(milliseconds: 300), _goHome);
      }

      setState(() => _videoReady = true);
    } catch (e) {
      debugPrint('Splash video error: $e');
      _goHome();
    }
  }

  void _goHome() {
    if (!mounted || _navigated) return;
    _navigated = true;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AppShell(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _videoReady ? _buildCoverVideo(context) : const ColoredBox(color: Colors.black),
    );
  }

  Widget _buildCoverVideo(BuildContext context) {
    final videoSize = _controller.value.size;
    if (videoSize == Size.zero) return const ColoredBox(color: Colors.black);

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: videoSize.width,
          height: videoSize.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}
