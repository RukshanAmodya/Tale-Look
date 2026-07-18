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
  
  int _wpm = 140; // Default to 140 WPM matching mockup
  double _fontSize = 26.0;
  bool _isScrolling = false;
  
  int _highlightedWordIndex = 0;
  List<String> _words = [];
  
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  double _currentScrollOffset = 0.0;
  
  int _countdownSeconds = 0;
  Timer? _countdownTimer;
  
  late AnimationController _recordPulseController;

  double _faceGuideX = 0.5;
  double _faceGuideY = 0.45;

  bool _showSettingsPanel = false;
  bool _highlightImportantWords = true;

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
    bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Viewport
          _buildCameraPreview(size),
          
          // 2. Face alignment target circle guide
          _buildFaceGuidelineOverlay(),
          
          // 3. Script Text Overlay (No black box backdrop!)
          _buildTeleprompterOverlay(size),
          
          // 4. Custom Mockup Control Elements
          _buildMockupControlOverlays(isLandscape, size),
          
          if (_countdownSeconds > 0) _buildCountdownOverlay(),
          
          // 5. Sliding Prompter Settings Drawer matching third mockup
          if (_showSettingsPanel) _buildSettingsDrawerOverlay(isLandscape, size),
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

  // Pure clean text overlay with NO background containers
  Widget _buildTeleprompterOverlay(Size size) {
    bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    double textContainerHeight = size.height * (isLandscape ? 0.60 : 0.35);
    double containerTop = size.height * (isLandscape ? 0.20 : 0.25);
    
    return Positioned(
      top: containerTop,
      left: isLandscape ? 36 : 30,
      right: isLandscape ? null : 30,
      width: isLandscape ? size.width * 0.40 : null,
      height: textContainerHeight,
      child: IgnorePointer(
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
              top: (size.height * (isLandscape ? 0.40 : 0.42)) - containerTop - 18,
              bottom: textContainerHeight,
            ),
            itemCount: 1,
            itemBuilder: (context, index) {
              return RichText(
                textAlign: isLandscape ? TextAlign.left : TextAlign.center,
                text: TextSpan(
                  children: List.generate(_words.length, (wIndex) {
                    final word = _words[wIndex];
                    final isHighlighted = wIndex == _highlightedWordIndex;
                    
                    // Highlight logic: Active word is bright white, others are faded/dimmed white30
                    final Color wordColor = isHighlighted ? Colors.white : Colors.white30;
                    
                    // Prefix active block with mockup's triangle pointer
                    if (isHighlighted && wIndex > 0 && _words[wIndex - 1].endsWith('.')) {
                      return TextSpan(
                        children: [
                          const TextSpan(
                            text: '▶ ',
                            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: '$word ',
                            style: _getDynamicStyle(word, _fontSize, wordColor).copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    }
                    
                    return TextSpan(
                      text: '$word ',
                      style: _getDynamicStyle(
                        word, 
                        _fontSize, 
                        wordColor
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
    );
  }

  // Renders the exact UI controls, dropdowns, and buttons matching mockups
  Widget _buildMockupControlOverlays(bool isLandscape, Size size) {
    return Stack(
      children: [
        // 1. Top-Left Close Button (X)
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 24,
          child: GestureDetector(
            onTap: widget.onBack,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
        
        // 2. Top-Right "Video clip A ⌵" Dropdown
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          right: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Video clip A',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 16),
              ],
            ),
          ),
        ),

        // 3. Middle-Right Floating Red Recording Button (Landscape only)
        if (isLandscape)
          Positioned(
            right: 120,
            top: (size.height / 2) - 32,
            child: GestureDetector(
              onTap: _startRecordingWorkflow,
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF2B54),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),

        // 4. Vertical Right Control Bar
        Positioned(
          top: isLandscape ? size.height * 0.25 : null,
          bottom: isLandscape ? size.height * 0.20 : MediaQuery.of(context).padding.bottom + 20,
          right: 24,
          left: isLandscape ? null : 24,
          child: isLandscape 
              ? _buildVerticalLandscapeRightBar(size)
              : _buildHorizontalPortraitBottomBar(size),
        ),
      ],
    );
  }

  Widget _buildVerticalLandscapeRightBar(Size size) {
    return Container(
      width: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B1B).withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMockupIconButton(
            icon: Icons.text_fields,
            label: 'Prompter',
            active: _showSettingsPanel,
            onTap: () {
              setState(() {
                _showSettingsPanel = !_showSettingsPanel;
              });
            },
          ),
          _buildMockupIconButton(
            icon: Icons.wb_sunny_outlined,
            label: 'Exposure',
            active: false,
            onTap: () {},
          ),
          _buildMockupIconButton(
            icon: Icons.settings_outlined,
            label: 'Settings',
            active: false,
            onTap: _switchCamera, // Simple camera flip under settings icon
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalPortraitBottomBar(Size size) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Prompter Settings Toggle
        GestureDetector(
          onTap: () {
            setState(() {
              _showSettingsPanel = !_showSettingsPanel;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1B1B).withOpacity(0.85),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: Icon(
              Icons.text_fields,
              color: _showSettingsPanel ? const Color(0xFF14C8A6) : Colors.white,
              size: 22,
            ),
          ),
        ),
        
        // Record Button
        GestureDetector(
          onTap: _startRecordingWorkflow,
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFFF2B54),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                _isRecording ? Icons.stop : Icons.fiber_manual_record,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
        
        // Camera Switcher
        GestureDetector(
          onTap: _switchCamera,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1B1B).withOpacity(0.85),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: const Icon(Icons.sync, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildMockupIconButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: active ? const Color(0xFF14C8A6) : Colors.white70,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: active ? const Color(0xFF14C8A6) : Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          )
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

  // Frosted Settings drawer matching third mockup (Responsive Portrait/Landscape)
  Widget _buildSettingsDrawerOverlay(bool isLandscape, Size size) {
    final double panelWidth = isLandscape ? size.width * 0.44 : size.width;
    final double panelHeight = isLandscape ? size.height * 0.70 : size.height * 0.46;

    final Widget settingsBody = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A1B).withOpacity(0.95), // Premium Dark Teal shade
        borderRadius: isLandscape 
            ? const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24))
            : const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prompter Settings',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showSettingsPanel = false;
                  });
                },
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
              )
            ],
          ),
          const SizedBox(height: 12),

          // 1. SPEED SLIDER matching mockup
          Text(
            'Speed • $_wpm words per min',
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.speed, color: Colors.white24, size: 16),
              Expanded(
                child: Slider(
                  value: _wpm.toDouble(),
                  min: 80,
                  max: 260,
                  activeColor: const Color(0xFF14C8A6), 
                  inactiveColor: Colors.white12,
                  onChanged: (val) {
                    setState(() {
                      _wpm = val.round();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. TEXT SIZE SELECTOR CHIPS matching mockup
          Text(
            'Text size',
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTextSizeChip('Small', 18.0),
              const SizedBox(width: 10),
              _buildTextSizeChip('Medium', 26.0),
              const SizedBox(width: 10),
              _buildTextSizeChip('Big', 34.0),
            ],
          ),
          const SizedBox(height: 20),

          // 3. HIGHLIGHT WORDS TOGGLE matching mockup
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Highlight important words',
                style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70),
              ),
              Switch(
                value: _highlightImportantWords,
                activeColor: const Color(0xFF14C8A6),
                onChanged: (val) {
                  setState(() {
                    _highlightImportantWords = val;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );

    if (isLandscape) {
      return Positioned(
        top: size.height * 0.15,
        bottom: size.height * 0.15,
        right: 94,
        width: panelWidth - 40,
        child: settingsBody,
      );
    } else {
      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        height: panelHeight,
        child: settingsBody,
      );
    }
  }

  Widget _buildTextSizeChip(String label, double size) {
    bool isSelected = _fontSize == size;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _fontSize = size;
          });
        },
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF14C8A6).withOpacity(0.12) : const Color(0xFF1A2627),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF14C8A6) : Colors.white12,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? const Color(0xFF14C8A6) : Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
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
