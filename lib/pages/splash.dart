// lib/pages/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onVideoEnd;

  const SplashScreen({Key? key, required this.onVideoEnd}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/intro.mp4')
      ..initialize().then((_) {
        setState(() {
          _initialized = true;
        });
        _controller.play();
      });

    _controller.addListener(_checkVideoFinished);
  }

  void _checkVideoFinished() {
    if (_initialized &&
        !_controller.value.isPlaying &&
        _controller.value.position >= _controller.value.duration) {
      widget.onVideoEnd();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_checkVideoFinished);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // <-- Fond blanc partout
      body: Center(
        child: _initialized
            ? ClipRect( // <-- Pour éviter d'afficher des marges noires autour
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
        )
            : const CircularProgressIndicator(color: Colors.orange), // Petit loader orange le temps que la vidéo charge
      ),
    );
  }
}
