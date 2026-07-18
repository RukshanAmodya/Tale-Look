import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:gal/gal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:telelook/models/script.dart';
import 'package:telelook/widgets/face_guideline_painter.dart';

class CameraReadingScreen extends StatefulWidget {
  final TeleprompterScript script;
  final VoidCallback onBack;

  const CameraReadingScreen({
    super.key,
    required this.script,
    required this.onBack,
  });

  @override
  State<CameraReadingScreen> createState() => _CameraReadingScreenState();
}

class _CameraReadingScreenState extends State<CameraReadingScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  int _selectedCameraIndex = 0;
  
  int _wpm = 160;
  double _fontSize = 26.0;
  bool _isScrolling = false;
  
  int _highlightedWordIndex = 0;
  List<String> _words = [];
  
  bool _isTabReading = true; 
  
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  double _currentScrollOffset = 0.0;
  
  int _countdownSeconds = 0;
  Timer? _countdownTimer;
  
  late AnimationController _recordPulseController;

  double _faceGuideX = 0.5;
  double _faceGuideY = 0.4;

  List<CameraDescription> _cameras = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _words = widget.script.fullContent.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    
    _recordPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      int frontCamIndex = _cameras.indexWhere(
          (cam) => cam.lensDirection == CameraLensDirection.front);
      _selectedCameraIndex = frontCamIndex != -1 ? frontCamIndex : 0;
      await _setupCameraController();
    } catch (e) {
      debugPrint("Camera List Error: $e");
    }
  }
  
  Future<void> _setupCameraController() async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }
    
    final controller = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    
    _cameraController = controller;
    
    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Camera Initialization Error: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _setupCameraController();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollTimer?.cancel();
    _countdownTimer?.cancel();
    _scrollController.dispose();
    _cameraController?.dispose();
    _recordPulseController.dispose();
    super.dispose();
  }
  
  double _getPixelsPerSecond() {
    double lineSize = _fontSize * 1.5;
    double linesPerSecond = _wpm / (60 * 4.5); 
    return lineSize * linesPerSecond;
  }

  void _startScrolling() {
    _scrollTimer?.cancel();
    setState(() {
      _isScrolling = true;
    });
    
    const double tickMs = 30.0;
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted || !_isScrolling) {
        timer.cancel();
        return;
      }
      
      double speed = _getPixelsPerSecond();
      double delta = (speed * tickMs) / 1000.0;
      _currentScrollOffset += delta;
      
      double totalHeight = _scrollController.position.maxScrollExtent;
      if (totalHeight > 0 && _words.isNotEmpty) {
        double ratio = (_currentScrollOffset / totalHeight).clamp(0.0, 1.0);
        setState(() {
          _highlightedWordIndex = (ratio * (_words.length - 1)).round();
        });
      }
      
      if (_scrollController.hasClients) {
        if (_currentScrollOffset >= _scrollController.position.maxScrollExtent + 100) {
          _currentScrollOffset = 0.0;
          _scrollController.jumpTo(0.0);
        } else {
          _scrollController.jumpTo(_currentScrollOffset);
        }
      }
    });
  }
  
  void _pauseScrolling() {
    _scrollTimer?.cancel();
    setState(() {
      _isScrolling = false;
    });
  }
  
  void _toggleScrolling() {
    if (_isScrolling) {
      _pauseScrolling();
    } else {
      _startScrolling();
    }
  }

  Future<void> _startRecordingWorkflow() async {
    if (_cameraController == null || !_isCameraInitialized) return;
    
    if (_isRecording) {
      await _stopVideoRecording();
    } else {
      setState(() {
        _countdownSeconds = 3;
      });
      
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }
        
        if (_countdownSeconds > 1) {
          setState(() {
            _countdownSeconds--;
          });
          HapticFeedback.mediumImpact();
        } else {
          timer.cancel();
          setState(() {
            _countdownSeconds = 0;
          });
          HapticFeedback.heavyImpact();
          await _startVideoRecording();
        }
      });
    }
  }

  Future<void> _startVideoRecording() async {
    try {
      await _cameraController!.prepareForVideoRecording();
      await _cameraController!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _currentScrollOffset = 0.0;
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0.0);
        }
      });
      _startScrolling();
    } catch (e) {
      debugPrint("Error starting video record: $e");
    }
  }

  Future<void> _stopVideoRecording() async {
    try {
      final file = await _cameraController!.stopVideoRecording();
      setState(() {
        _isRecording = false;
      });
      _pauseScrolling();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saving video to gallery...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      bool access = await Gal.hasAccess();
      if (!access) {
        access = await Gal.requestAccess();
      }
      
      if (access) {
        await Gal.putVideo(file.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video saved to Gallery successfully! (MP4)'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      
      final localFile = File(file.path);
      if (await localFile.exists()) {
        await localFile.delete();
      }
    } catch (e) {
      debugPrint("Error stopping video record: $e");
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
      _isCameraInitialized = false;
    });
    await _setupCameraController();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildCameraPreview(size),
          _buildFaceGuidelineOverlay(),
          _buildTeleprompterOverlay(size),
          _buildRedDashedLineGuide(size),
          _buildTopTabsHeader(),
          if (_countdownSeconds > 0) _buildCountdownOverlay(),
          _buildBottomActionDock(size),
        ],
      ),
    );
  }

  Widget _buildCameraPreview(Size size) {
    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF2B54)),
        ),
      );
    }
    return Center(
      child: CameraPreview(_cameraController!),
    );
  }

  Widget _buildFaceGuidelineOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onPanUpdate: (details) {
          final size = MediaQuery.of(context).size;
          setState(() {
            _faceGuideX = (_faceGuideX + details.delta.dx / size.width).clamp(0.1, 0.9);
            _faceGuideY = (_faceGuideY + details.delta.dy / size.height).clamp(0.1, 0.9);
          });
        },
        child: CustomPaint(
          painter: FaceGuidelinePainter(
            centerX: _faceGuideX,
            centerY: _faceGuideY,
          ),
        ),
      ),
    );
  }

  Widget _buildRedDashedLineGuide(Size size) {
    return const SizedBox.shrink();
  }

  Widget _buildTeleprompterOverlay(Size size) {
    double textContainerHeight = size.height * 0.35;
    double containerTop = size.height * 0.25;
    
    return Positioned(
      top: containerTop,
      left: 30,
      right: 30,
      height: textContainerHeight,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.65), 
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.2),
          ),
          child: ShaderMask(
            shaderCallback: (rect) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.white,
                  Colors.white,
                  Colors.transparent,
                ],
                stops: [0.0, 0.15, 0.85, 1.0],
              ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
            },
            blendMode: BlendMode.dstIn,
            child: ListView.builder(
              controller: _scrollController,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                top: (size.height * 0.42) - containerTop - 18,
                bottom: textContainerHeight,
              ),
              itemCount: 1,
              itemBuilder: (context, index) {
                return RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: List.generate(_words.length, (wIndex) {
                      final word = _words[wIndex];
                      final isHighlighted = wIndex == _highlightedWordIndex;
                      
                      return TextSpan(
                        text: '$word ',
                        style: _getDynamicStyle(
                          word, 
                          _fontSize, 
                          isHighlighted ? const Color(0xFFFF2B54) : Colors.white70
                        ).copyWith(
                          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopTabsHeader() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isTabReading = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: !_isTabReading ? Colors.white12 : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Preview',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isTabReading = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isTabReading ? Colors.white12 : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Reading',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildCountdownOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Text(
          '$_countdownSeconds',
          style: GoogleFonts.outfit(
            fontSize: 130,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFFF2B54),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionDock(Size size) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      left: 30,
      right: 30,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    if (_wpm > 80) _wpm -= 10;
                  });
                  HapticFeedback.lightImpact();
                },
                icon: const Icon(Icons.remove, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: _toggleScrolling,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    color: Colors.black38,
                  ),
                  child: Center(
                    child: Icon(
                      _isScrolling ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              IconButton(
                onPressed: () {
                  setState(() {
                    if (_wpm < 260) _wpm += 10;
                  });
                  HapticFeedback.lightImpact();
                },
                icon: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$_wpm WPM',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 44),
              GestureDetector(
                onTap: _startRecordingWorkflow,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _isRecording ? 30 : 52,
                      height: _isRecording ? 30 : 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF2B54),
                        borderRadius: BorderRadius.circular(_isRecording ? 8 : 26),
                      ),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _switchCamera,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white10,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.sync, color: Colors.white, size: 22),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  TextStyle _getDynamicStyle(String text, double size, Color color) {
    bool isSinhala = RegExp(r'[\u0D80-\u0DFF]').hasMatch(text);
    return isSinhala ? _getSinhalaStyle(size, color) : _getEnglishStyle(size, color);
  }

  TextStyle _getSinhalaStyle(double size, Color color) {
    return TextStyle(
      fontFamily: 'SinhalaSangam',
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
      height: 1.5,
    );
  }

  TextStyle _getEnglishStyle(double size, Color color) {
    return GoogleFonts.outfit(
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.45,
    );
  }
}
