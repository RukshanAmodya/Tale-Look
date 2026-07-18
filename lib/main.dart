import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:gal/gal.dart';
import 'package:google_fonts/google_fonts.dart';

late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ensure orientation is locked to portrait for the best experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  try {
    _cameras = await availableCameras();
  } catch (e) {
    debugPrint("Failed to initialize cameras: $e");
    _cameras = [];
  }
  
  runApp(const TaleLookApp());
}

class TaleLookApp extends StatelessWidget {
  const TaleLookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tale Look',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFFFF2B54), // Elegant TikTok red/pink color
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF2B54),
          secondary: Color(0xFF1DE9B6),
          surface: Color(0xFF1E1E24),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: Color(0xFFFF2B54),
          thumbColor: Color(0xFFFF2B54),
          inactiveTrackColor: Colors.white24,
        ),
      ),
      home: const MainTeleprompterScreen(),
    );
  }
}

enum AspectRatioPreset {
  youtube('16:9', 16 / 9),
  tiktok('9:16', 9 / 16),
  square('1:1', 1.0);

  final String label;
  final double value;
  const AspectRatioPreset(this.label, this.value);
}

class MainTeleprompterScreen extends StatefulWidget {
  const MainTeleprompterScreen({super.key});

  @override
  State<MainTeleprompterScreen> createState() => _MainTeleprompterScreenState();
}

class _MainTeleprompterScreenState extends State<MainTeleprompterScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  int _selectedCameraIndex = 0;
  
  // Script and scrolling state
  String _scriptText = "මෙන්න Tale Look Smart Teleprompter App එක! 😊\n\n"
      "වීඩියෝ එක Record වෙන අතරතුර ඔයාට පුළුවන් මේ විදිහට තිරය දෙස කෙලින්ම බලාගෙන ස්ක්රිප්ට් එක කියවන්න.\n\n"
      "ස්ක්රිප්ට් කියවන කොටස තිරයේ ඉහළින්ම පිහිටලා තියෙන නිසා ඔයාගේ ඇස් වෙනත් දෙසකට යොමු වෙන්නේ නෑ. ඔයා කෙලින්ම කැමරාව දෙස බලාගෙන කතා කරනවා වගේ තමයි වීඩියෝ එකේ පේන්නේ.\n\n"
      "ඔයාට පුළුවන් මේ අකුරු වල ප්‍රමාණය (Font Size) සහ Text Scroll වෙන වේගය (Speed) Slider එකෙන් පහසුවෙන්ම වෙනස් කරන්න.\n\n"
      "ඒ වගේම YouTube, TikTok හෝ Instagram Reels වලට ගැලපෙන Aspect Ratio Frames පාවිච්චි කරන්නත් පුළුවන්. දැන්ම ඔයාගේ වීඩියෝ එක Record කරන්න පටන් ගන්න!";
  
  double _scrollSpeed = 25.0; // pixels per second
  double _fontSize = 24.0;
  bool _isScrolling = false;
  
  // Layout aspect ratio preset
  AspectRatioPreset _aspectRatioPreset = AspectRatioPreset.tiktok;
  
  // Scroll Controller & Timer
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  double _currentScrollOffset = 0.0;
  
  // Animation controllers for premium visual elements
  late AnimationController _recordPulseController;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize record button pulse animation
    _recordPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (_cameras.isEmpty) return;
    
    // Default to front camera for content creators if available
    int frontCamIndex = _cameras.indexWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front);
    _selectedCameraIndex = frontCamIndex != -1 ? frontCamIndex : 0;
    
    await _setupCameraController();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('කැමරාව සක්‍රිය කිරීමට නොහැකි විය: $e')),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    // App state changed, manage camera resources safely
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
    _scrollController.dispose();
    _cameraController?.dispose();
    _recordPulseController.dispose();
    super.dispose();
  }
  
  // Dynamic Scroll Mechanism
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
      
      // Calculate delta step based on speed and time delta (30ms)
      double delta = (_scrollSpeed * tickMs) / 1000.0;
      _currentScrollOffset += delta;
      
      if (_scrollController.hasClients) {
        if (_currentScrollOffset >= _scrollController.position.maxScrollExtent + 200) {
          // Reset to start if finished
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
  
  // Custom font styling loaders
  TextStyle _getSinhalaStyle(double size) {
    return TextStyle(
      fontFamily: 'SinhalaSangam',
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      height: 1.5,
      shadows: const [
        Shadow(
          blurRadius: 4.0,
          color: Colors.black,
          offset: Offset(1.0, 1.0),
        ),
      ],
    );
  }
  
  TextStyle _getEnglishStyle(double size) {
    return GoogleFonts.lexend(
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      height: 1.4,
      shadows: const [
        Shadow(
          blurRadius: 4.0,
          color: Colors.black,
          offset: Offset(1.0, 1.0),
        ),
      ],
    );
  }
  
  TextStyle _getDynamicStyle(String text, double size) {
    // Basic regex check to detect Sinhala characters
    bool isSinhala = RegExp(r'[\u0D80-\u0DFF]').hasMatch(text);
    return isSinhala ? _getSinhalaStyle(size) : _getEnglishStyle(size);
  }

  // Camera Recording Actions
  Future<void> _toggleRecording() async {
    if (_cameraController == null || !_isCameraInitialized) return;
    
    if (_isRecording) {
      // Stop Video Recording
      try {
        final file = await _cameraController!.stopVideoRecording();
        setState(() {
          _isRecording = false;
        });
        _pauseScrolling();
        
        // Show saving feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(width: 15),
                  Text('වීඩියෝව ගැලරියට සුරකිමින් පවතී...'),
                ],
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        // Save to gallery via Gal
        bool access = await Gal.hasAccess();
        if (!access) {
          access = await Gal.requestAccess();
        }
        
        if (access) {
          await Gal.putVideo(file.path);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('වීඩියෝව සාර්ථකව ගැලරියට සුරකින ලදී! (MP4)'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // Fallback message with local path
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gallery Permission ප්‍රතික්ෂේප විය. සුරකින ලද ස්ථානය: ${file.path}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
        
        // Clean up recorded file from app temp directory
        final localFile = File(file.path);
        if (await localFile.exists()) {
          await localFile.delete();
        }
        
      } catch (e) {
        debugPrint("Error stopping video record: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('වීඩියෝව සුරැකීමේදී ගැටළුවක් ඇති විය: $e')),
          );
        }
      }
    } else {
      // Start Video Recording
      try {
        // Prepare directory
        await _cameraController!.prepareForVideoRecording();
        await _cameraController!.startVideoRecording();
        setState(() {
          _isRecording = true;
          // Auto start teleprompter scroll when recording starts
          _currentScrollOffset = 0.0;
          _scrollController.jumpTo(0.0);
        });
        _startScrolling();
      } catch (e) {
        debugPrint("Error starting video record: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('වීඩියෝ පටිගත කිරීම ආරම්භ කිරීමට නොහැකි විය: $e')),
          );
        }
      }
    }
  }

  // Switch between front and rear cameras
  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
      _isCameraInitialized = false;
    });
    await _setupCameraController();
  }

  // Open Edit Script dialog
  void _showEditScriptDialog() {
    final TextEditingController textController = TextEditingController(text: _scriptText);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E24),
          title: Row(
            children: [
              const Icon(Icons.edit_note, color: Color(0xFFFF2B54)),
              const SizedBox(width: 8),
              Text(
                'Script එක සකසන්න',
                style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: textController,
              maxLines: 12,
              style: const TextStyle(
                fontFamily: 'SinhalaSangam',
                fontSize: 16,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'මෙතන ඔබේ ස්ක්රිප්ට් එක ලියන්න හෝ Paste කරන්න...',
                hintStyle: TextStyle(color: Colors.white30, fontFamily: 'SinhalaSangam'),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF2B54), width: 2),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'අවලංගු කරන්න',
                style: GoogleFonts.lexend(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _scriptText = textController.text;
                  _currentScrollOffset = 0.0;
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(0.0);
                  }
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2B54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'සුරකින්න',
                style: GoogleFonts.lexend(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Stack(
        children: [
          // LAYER 1: Full-Screen Camera Preview / Crop Guidelines
          _buildCameraPreview(size),
          
          // Aspect Ratio Overlay Masks (Fades area outside target format)
          _buildAspectRatioMasks(size),

          // LAYER 2: Transparent Black Overlay for Teleprompter Text
          _buildTeleprompterOverlay(size),
          
          // Camera-Proximal Reading Window Frame Highlight
          _buildReadingZoneFrame(size),

          // Top App Bar Controls (Edit, Switch Cam, Aspect Ratio)
          _buildTopNavigationBar(),

          // Bottom Controls & Sliders
          _buildBottomControlPanel(size),
        ],
      ),
    );
  }

  // Camera Preview widget
  Widget _buildCameraPreview(Size size) {
    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFFF2B54)),
              SizedBox(height: 16),
              Text(
                'කැමරාව සක්‍රිය වෙමින් පවතී...',
                style: TextStyle(fontFamily: 'SinhalaSangam', color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }
    
    // Scale preview to ensure no stretching and full fill
    final cameraValue = _cameraController!.value;
    double scale = size.aspectRatio * cameraValue.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Transform.scale(
      scale: scale,
      alignment: Alignment.center,
      child: Center(
        child: CameraPreview(_cameraController!),
      ),
    );
  }

  // Aspect ratio mask overlay
  Widget _buildAspectRatioMasks(Size size) {
    if (_aspectRatioPreset == AspectRatioPreset.tiktok) {
      // 9:16 is standard full screen, no crop overlay needed
      return const SizedBox.shrink();
    }

    double viewportWidth = size.width;
    double viewportHeight = size.height;
    double targetRatio = _aspectRatioPreset.value;
    
    double boxWidth = viewportWidth;
    double boxHeight = viewportWidth / targetRatio;
    
    if (boxHeight > viewportHeight) {
      boxHeight = viewportHeight;
      boxWidth = viewportHeight * targetRatio;
    }

    double topMaskHeight = (viewportHeight - boxHeight) / 2;
    double leftMaskWidth = (viewportWidth - boxWidth) / 2;

    return IgnorePointer(
      child: Stack(
        children: [
          // Top Mask
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topMaskHeight,
            child: Container(color: Colors.black.withOpacity(0.7)),
          ),
          // Bottom Mask
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: topMaskHeight,
            child: Container(color: Colors.black.withOpacity(0.7)),
          ),
          // Left Mask
          Positioned(
            top: topMaskHeight,
            bottom: topMaskHeight,
            left: 0,
            width: leftMaskWidth,
            child: Container(color: Colors.black.withOpacity(0.7)),
          ),
          // Right Mask
          Positioned(
            top: topMaskHeight,
            bottom: topMaskHeight,
            right: 0,
            width: leftMaskWidth,
            child: Container(color: Colors.black.withOpacity(0.7)),
          ),
          // Outer Border Frame
          Positioned(
            top: topMaskHeight,
            left: leftMaskWidth,
            width: boxWidth,
            height: boxHeight,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Main Teleprompter Text overlay
  Widget _buildTeleprompterOverlay(Size size) {
    // Define the box in which the list scrolls
    double textContainerHeight = size.height * 0.50; // top 50% of the screen
    
    return Positioned(
      top: 90, // below header bar
      left: 20,
      right: 20,
      height: textContainerHeight,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.55),
              Colors.black.withOpacity(0.20),
            ],
          ),
        ),
        child: ShaderMask(
          shaderCallback: (rect) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Colors.white,
                Colors.white38,
                Colors.transparent,
              ],
              stops: [0.0, 0.5, 0.85, 1.0],
            ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
          },
          blendMode: BlendMode.dstIn,
          child: ListView.builder(
            controller: _scrollController,
            physics: const NeverScrollableScrollPhysics(), // Scroll only via code controller
            // Add padding so first line starts in the active reading area and ends fully scrolled
            padding: EdgeInsets.only(
              top: 50,
              bottom: textContainerHeight,
            ),
            itemCount: 1,
            itemBuilder: (context, index) {
              return Text(
                _scriptText,
                style: _getDynamicStyle(_scriptText, _fontSize),
                textAlign: TextAlign.center,
              );
            },
          ),
        ),
      ),
    );
  }

  // Overlay reading zone guide near the camera lens
  Widget _buildReadingZoneFrame(Size size) {
    return Positioned(
      top: 130, // Positioned at the top third of teleprompter zone
      left: 10,
      right: 10,
      child: IgnorePointer(
        child: Container(
          height: 65,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFFF2B54).withOpacity(0.35),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFFF2B54).withOpacity(0.07),
          ),
          child: Stack(
            children: [
              // Eye-line indicator lines
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(width: 8, height: 1.5, color: const Color(0xFFFF2B54)),
                ),
              ),
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(width: 8, height: 1.5, color: const Color(0xFFFF2B54)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Top header with actions
  Widget _buildTopNavigationBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 5,
      left: 15,
      right: 15,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Edit Script Button
          GestureDetector(
            onTap: _showEditScriptDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Script',
                    style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          
          // Aspect Ratio Cycle
          GestureDetector(
            onTap: () {
              setState(() {
                if (_aspectRatioPreset == AspectRatioPreset.youtube) {
                  _aspectRatioPreset = AspectRatioPreset.tiktok;
                } else if (_aspectRatioPreset == AspectRatioPreset.tiktok) {
                  _aspectRatioPreset = AspectRatioPreset.square;
                } else {
                  _aspectRatioPreset = AspectRatioPreset.youtube;
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.aspect_ratio, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _aspectRatioPreset.label,
                    style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

          // Switch camera button
          GestureDetector(
            onTap: _switchCamera,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // Floating Control & Slider Panel
  Widget _buildBottomControlPanel(Size size) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 15,
          bottom: MediaQuery.of(context).padding.bottom + 15,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          border: const Border(
            top: BorderSide(color: Colors.white10),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row of sliders: Speed & Font Size
            Row(
              children: [
                // Speed Controls
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('වේගය (Speed)', style: TextStyle(fontFamily: 'SinhalaSangam', fontSize: 11, color: Colors.white60)),
                            Text('${_scrollSpeed.toInt()}', style: GoogleFonts.lexend(fontSize: 11, color: const Color(0xFFFF2B54))),
                          ],
                        ),
                      ),
                      Slider(
                        min: 5.0,
                        max: 80.0,
                        value: _scrollSpeed,
                        onChanged: (val) {
                          setState(() {
                            _scrollSpeed = val;
                          });
                          if (_isScrolling) {
                            _startScrolling(); // restart with new speed
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                // Font Size Controls
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('අකුරු (Font Size)', style: TextStyle(fontFamily: 'SinhalaSangam', fontSize: 11, color: Colors.white60)),
                            Text('${_fontSize.toInt()}', style: GoogleFonts.lexend(fontSize: 11, color: const Color(0xFFFF2B54))),
                          ],
                        ),
                      ),
                      Slider(
                        min: 16.0,
                        max: 42.0,
                        value: _fontSize,
                        onChanged: (val) {
                          setState(() {
                            _fontSize = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Bottom Buttons Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Play / Pause Button
                IconButton(
                  onPressed: _toggleScrolling,
                  icon: Icon(
                    _isScrolling ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                
                // MAIN RECORD BUTTON
                GestureDetector(
                  onTap: _toggleRecording,
                  child: AnimatedBuilder(
                    animation: _recordPulseController,
                    builder: (context, child) {
                      double scale = 1.0;
                      if (_isRecording) {
                        scale = 1.0 + (_recordPulseController.value * 0.08);
                      }
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: _isRecording ? 30 : 54,
                              height: _isRecording ? 30 : 54,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF2B54),
                                borderRadius: BorderRadius.circular(_isRecording ? 8 : 27),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Restart / Reset Scroll Offset
                IconButton(
                  onPressed: () {
                    setState(() {
                      _currentScrollOffset = 0;
                      if (_scrollController.hasClients) {
                        _scrollController.jumpTo(0);
                      }
                    });
                  },
                  icon: const Icon(
                    Icons.replay_circle_filled,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
