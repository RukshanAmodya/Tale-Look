import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:gal/gal.dart';
import 'package:google_fonts/google_fonts.dart';

late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Allow all orientations for automatic layout rotation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
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
        primaryColor: const Color(0xFFFF2B54),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF2B54),
          secondary: Color(0xFF39FF14),
          surface: Color(0xFF151518),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: Color(0xFFFF2B54),
          thumbColor: Color(0xFFFF2B54),
          inactiveTrackColor: Colors.white12,
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

class TeleprompterScript {
  final String id;
  final String title;
  final String content;

  TeleprompterScript({
    required this.id,
    required this.title,
    required this.content,
  });

  TeleprompterScript copyWith({String? title, String? content}) {
    return TeleprompterScript(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
    );
  }
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
  
  // Scripts List
  final List<TeleprompterScript> _scripts = [
    TeleprompterScript(
      id: 'default_sinhala',
      title: 'Default Sinhala Script',
      content: "මෙන්න Tale Look Smart Teleprompter App එක! 😊\n\n"
          "වීඩියෝ එක Record වෙන අතරතුර ඔයාට පුළුවන් මේ විදිහට තිරය දෙස කෙලින්ම බලාගෙන ස්ක්රිප්ට් එක කියවන්න.\n\n"
          "ස්ක්රිප්ට් කියවන කොටස තිරයේ ඉහළින්ම පිහිටලා තියෙන නිසා ඔයාගේ ඇස් වෙනත් දෙසකට යොමු වෙන්නේ නෑ. ඔයා කෙලින්ම කැමරාව දෙස බලාගෙන කතා කරනවා වගේ තමයි වීඩියෝ එකේ පේන්නේ.\n\n"
          "ඔයාට පුළුවන් මේ අකුරු වල ප්‍රමාණය (Font Size) සහ Text Scroll වෙන වේගය (Speed) Slider එකෙන් පහසුවෙන්ම වෙනස් කරන්න.\n\n"
          "ඒ වගේම YouTube, TikTok හෝ Instagram Reels වලට ගැලපෙන Aspect Ratio Frames පාවිච්චි කරන්නත් පුළුවන්. දැන්ම ඔයාගේ වීඩියෝ එක Record කරන්න පටන් ගන්න!",
    ),
    TeleprompterScript(
      id: 'intro_en',
      title: 'YouTube Tech Review Intro',
      content: "Hey guys! Welcome back to the channel. Today, we are taking a look at a brand-new smart application called Tale Look.\n\n"
          "This app changes the game for content creators by keeping the script scrolling exactly where your camera lens is.\n\n"
          "No more awkward eye shifts, no more forgetting your lines. Let's dive straight into the features and see how it performs in landscape and portrait orientations!",
    ),
    TeleprompterScript(
      id: 'hook_tiktok',
      title: 'TikTok & Reels Hook Template',
      content: "Stop scrolling! If you are a video creator, you need to see this app right now.\n\n"
          "This is Tale Look, and it acts as a smart mirror teleprompter overlay on top of your live recording camera view.\n\n"
          "It saves videos directly to your camera roll in high definition, and automatically switches frames based on how you hold your phone. Try it out!",
    ),
  ];
  
  late int _activeScriptIndex;
  
  // Customization variables
  double _scrollSpeed = 25.0;
  double _fontSize = 24.0;
  bool _isScrolling = false;
  bool _mirrorText = false;
  
  // Expanded Color Palette Selection
  Color _textColor = Colors.white;
  final List<Color> _colorPalette = [
    Colors.white,
    const Color(0xFF39FF14), // Neon Green
    const Color(0xFFFFEA00), // Electric Yellow
    const Color(0xFFFF1493), // Hot Pink
    const Color(0xFF00E5FF), // Cyber Blue
    const Color(0xFFFF5722), // Sunset Orange
  ];
  
  double _readingZoneTopOffset = 130.0; 
  
  // Auto-hide UI states
  bool _showUI = true;
  Timer? _uiInactivityTimer;
  
  // Last manual aspect ratio selection (if null, uses auto-orientation aspect ratio)
  AspectRatioPreset? _manualPresetOverride;
  
  // Active aspect ratio preset helper
  AspectRatioPreset get _effectivePreset {
    if (_manualPresetOverride != null) {
      return _manualPresetOverride!;
    }
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return isLandscape ? AspectRatioPreset.youtube : AspectRatioPreset.tiktok;
  }
  
  // Scroll Controller & Timer
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  double _currentScrollOffset = 0.0;
  
  // Visual Audio Monitor Animation
  Timer? _audioMonitorTimer;
  final List<double> _audioLevels = List.filled(8, 0.1);
  final math.Random _random = math.Random();
  
  // Record Countdown State
  int _countdownSeconds = 0;
  Timer? _countdownTimer;
  
  // Animation controllers for premium visual elements
  late AnimationController _recordPulseController;
  late AnimationController _readingZoneGlowController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _activeScriptIndex = 0;
    
    _recordPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _readingZoneGlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _initializeCamera();
    _startAudioMonitorSimulation();
    _resetUITimer();
  }

  Future<void> _initializeCamera() async {
    if (_cameras.isEmpty) return;
    
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
          SnackBar(content: Text('Failed to initialize camera: $e')),
        );
      }
    }
  }

  // Auto-hide UI timer logic
  void _resetUITimer() {
    _uiInactivityTimer?.cancel();
    if (!_showUI) {
      setState(() {
        _showUI = true;
      });
    }
    // Auto-hides panels after 4 seconds of inactivity (2 seconds during recording)
    _uiInactivityTimer = Timer(Duration(seconds: _isRecording ? 2 : 4), () {
      if (mounted && !_isScrolling) {
        // Only auto-hide if not scrolling, or if recording is active
        setState(() {
          _showUI = false;
        });
      } else if (mounted && _isRecording) {
        setState(() {
          _showUI = false;
        });
      }
    });
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
    });
    if (_showUI) {
      _resetUITimer();
    }
  }

  void _startAudioMonitorSimulation() {
    _audioMonitorTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_isRecording) {
        setState(() {
          for (int i = 0; i < _audioLevels.length; i++) {
            _audioLevels[i] = 0.2 + _random.nextDouble() * 0.8;
          }
        });
      } else {
        setState(() {
          for (int i = 0; i < _audioLevels.length; i++) {
            _audioLevels[i] = 0.05 + _random.nextDouble() * 0.1;
          }
        });
      }
    });
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
    _audioMonitorTimer?.cancel();
    _countdownTimer?.cancel();
    _uiInactivityTimer?.cancel();
    _scrollController.dispose();
    _cameraController?.dispose();
    _recordPulseController.dispose();
    _readingZoneGlowController.dispose();
    super.dispose();
  }
  
  void _startScrolling() {
    _scrollTimer?.cancel();
    setState(() {
      _isScrolling = true;
    });
    _resetUITimer();
    
    const double tickMs = 30.0;
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted || !_isScrolling) {
        timer.cancel();
        return;
      }
      
      double delta = (_scrollSpeed * tickMs) / 1000.0;
      _currentScrollOffset += delta;
      
      if (_scrollController.hasClients) {
        if (_currentScrollOffset >= _scrollController.position.maxScrollExtent + 200) {
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
    _resetUITimer();
  }
  
  void _toggleScrolling() {
    if (_isScrolling) {
      _pauseScrolling();
    } else {
      _startScrolling();
    }
  }
  
  TextStyle _getSinhalaStyle(double size, Color color) {
    return TextStyle(
      fontFamily: 'SinhalaSangam',
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
      height: 1.5,
      shadows: const [
        Shadow(
          blurRadius: 6.0,
          color: Colors.black87,
          offset: Offset(1.5, 1.5),
        ),
      ],
    );
  }
  
  TextStyle _getEnglishStyle(double size, Color color) {
    return GoogleFonts.outfit(
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.4,
      shadows: const [
        Shadow(
          blurRadius: 6.0,
          color: Colors.black87,
          offset: Offset(1.5, 1.5),
        ),
      ],
    );
  }
  
  TextStyle _getDynamicStyle(String text, double size, Color color) {
    bool isSinhala = RegExp(r'[\u0D80-\u0DFF]').hasMatch(text);
    return isSinhala ? _getSinhalaStyle(size, color) : _getEnglishStyle(size, color);
  }

  Future<void> _startRecordingWorkflow() async {
    if (_cameraController == null || !_isCameraInitialized) return;
    
    if (_isRecording) {
      await _stopVideoRecording();
    } else {
      setState(() {
        _countdownSeconds = 3;
        _showUI = false; // Hide panels to start clean recording immediately
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start video recording: $e')),
        );
      }
    }
  }

  Future<void> _stopVideoRecording() async {
    try {
      final file = await _cameraController!.stopVideoRecording();
      setState(() {
        _isRecording = false;
      });
      _pauseScrolling();
      _resetUITimer();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF2B54)),
                SizedBox(width: 15),
                Text('Saving video to gallery...'),
              ],
            ),
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
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Permission denied. Video saved locally: ${file.path}'),
              backgroundColor: Colors.orange,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving video: $e')),
        );
      }
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

  void _showScriptManager() {
    _resetUITimer();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Color(0xFF141416),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Script Manager',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Color(0xFFFF2B54), size: 28),
                          onPressed: () => _createNewScriptWorkflow(context, setModalState),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _scripts.length,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemBuilder: (context, index) {
                        final script = _scripts[index];
                        final isActive = _activeScriptIndex == index;
                        
                        return Card(
                          color: isActive ? const Color(0xFFFF2B54).withOpacity(0.15) : Colors.black26,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isActive ? const Color(0xFFFF2B54) : Colors.white10,
                              width: isActive ? 1.5 : 1.0,
                            ),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          child: ListTile(
                            title: Text(
                              script.title,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                color: isActive ? const Color(0xFFFF2B54) : Colors.white,
                              ),
                            ),
                            subtitle: Text(
                              script.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: RegExp(r'[\u0D80-\u0DFF]').hasMatch(script.content) ? 'SinhalaSangam' : null,
                                color: Colors.white60,
                                fontSize: 13,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                                  onPressed: () => _editScriptWorkflow(context, index, setModalState),
                                ),
                                if (_scripts.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                    onPressed: () {
                                      setModalState(() {
                                        _scripts.removeAt(index);
                                        if (_activeScriptIndex >= _scripts.length) {
                                          _activeScriptIndex = 0;
                                        }
                                      });
                                      setState(() {});
                                    },
                                  ),
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                _activeScriptIndex = index;
                                _currentScrollOffset = 0.0;
                                if (_scrollController.hasClients) {
                                  _scrollController.jumpTo(0.0);
                                }
                              });
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _createNewScriptWorkflow(BuildContext parentContext, StateSetter setModalState) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    
    showDialog(
      context: parentContext,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E24),
          title: Text('New Teleprompter Script', style: GoogleFonts.outfit()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Script Title',
                    labelStyle: TextStyle(color: Colors.white60),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF2B54))),
                  ),
                  style: GoogleFonts.outfit(color: Colors.white),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: contentController,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText: 'Type or paste script content here...',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF2B54))),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                  final newScript = TeleprompterScript(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    content: contentController.text,
                  );
                  setModalState(() {
                    _scripts.add(newScript);
                  });
                  setState(() {});
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF2B54)),
              child: const Text('Add Script', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _editScriptWorkflow(BuildContext parentContext, int index, StateSetter setModalState) {
    final script = _scripts[index];
    final titleController = TextEditingController(text: script.title);
    final contentController = TextEditingController(text: script.content);
    
    showDialog(
      context: parentContext,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E24),
          title: Text('Edit Script', style: GoogleFonts.outfit()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Script Title',
                    labelStyle: TextStyle(color: Colors.white60),
                  ),
                  style: GoogleFonts.outfit(color: Colors.white),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: contentController,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF2B54))),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                setModalState(() {
                  _scripts[index] = script.copyWith(
                    title: titleController.text,
                    content: contentController.text,
                  );
                });
                setState(() {});
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF2B54)),
              child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    return Scaffold(
      body: GestureDetector(
        onTap: _toggleUI,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // LAYER 1: Full-Screen Camera Preview
            _buildCameraPreview(size),
            
            // Responsive Crop Guides Overlay
            _buildAspectRatioMasks(size),

            // LAYER 2: Transparent Black Scroller Overlay
            _buildTeleprompterOverlay(size, isLandscape),
            
            // Reading Guide Zone calibrated at target horizontal offset
            _buildReadingZoneFrame(size),

            // Top Header Settings Actions (Floating pill capsules)
            _buildTopNavigationBar(isLandscape),

            // Countdown Overlay
            if (_countdownSeconds > 0) _buildCountdownOverlay(),

            // Bottom Controls Box (Frosted floating glassmorphic dock)
            _buildBottomControlPanel(size, isLandscape),
          ],
        ),
      ),
    );
  }

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
                'Initializing Camera Feed...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }
    
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

  Widget _buildAspectRatioMasks(Size size) {
    final preset = _effectivePreset;
    
    if (preset == AspectRatioPreset.tiktok && MediaQuery.of(context).orientation == Orientation.portrait) {
      return const SizedBox.shrink();
    }
    if (preset == AspectRatioPreset.youtube && MediaQuery.of(context).orientation == Orientation.landscape) {
      return const SizedBox.shrink();
    }

    double viewportWidth = size.width;
    double viewportHeight = size.height;
    double targetRatio = preset.value;
    
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topMaskHeight,
            child: Container(color: Colors.black.withOpacity(0.75)),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: topMaskHeight,
            child: Container(color: Colors.black.withOpacity(0.75)),
          ),
          Positioned(
            top: topMaskHeight,
            bottom: topMaskHeight,
            left: 0,
            width: leftMaskWidth,
            child: Container(color: Colors.black.withOpacity(0.75)),
          ),
          Positioned(
            top: topMaskHeight,
            bottom: topMaskHeight,
            right: 0,
            width: leftMaskWidth,
            child: Container(color: Colors.black.withOpacity(0.75)),
          ),
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

  Widget _buildTeleprompterOverlay(Size size, bool isLandscape) {
    double textContainerHeight = size.height * (isLandscape ? 0.38 : 0.50);
    double containerTop = isLandscape ? 50 : 90;
    
    return Positioned(
      top: containerTop,
      left: isLandscape ? size.width * 0.15 : 20,
      right: isLandscape ? size.width * 0.15 : 20,
      height: textContainerHeight,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.50),
              Colors.black.withOpacity(0.10),
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
              stops: [0.0, 0.45, 0.8, 1.0],
            ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
          },
          blendMode: BlendMode.dstIn,
          child: Transform(
            transform: Matrix4.identity()..scale(_mirrorText ? -1.0 : 1.0, 1.0, 1.0),
            alignment: Alignment.center,
            child: ListView.builder(
              controller: _scrollController,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                top: _readingZoneTopOffset - containerTop,
                bottom: textContainerHeight,
              ),
              itemCount: 1,
              itemBuilder: (context, index) {
                final content = _scripts[_activeScriptIndex].content;
                return Text(
                  content,
                  style: _getDynamicStyle(content, _fontSize, _textColor),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadingZoneFrame(Size size) {
    return Positioned(
      top: _readingZoneTopOffset,
      left: 10,
      right: 10,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _readingZoneGlowController,
          builder: (context, child) {
            final opacity = 0.2 + (_readingZoneGlowController.value * 0.35);
            return Container(
              height: 65,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFFF2B54).withOpacity(opacity),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFFF2B54).withOpacity(0.04),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF2B54).withOpacity(opacity * 0.15),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 14,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        width: 8,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF2B54),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 14,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        width: 8,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF2B54),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopNavigationBar(bool isLandscape) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: _showUI ? (MediaQuery.of(context).padding.top + (isLandscape ? 2 : 5)) : -80,
      left: 15,
      right: 15,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Script selection button
          _buildFloatingTopPill(
            icon: Icons.description,
            label: 'Scripts',
            onTap: _showScriptManager,
          ),
          
          // Mirror Text Mode Toggle
          _buildFloatingTopPill(
            icon: Icons.flip,
            label: 'Mirror',
            isActive: _mirrorText,
            onTap: () {
              setState(() {
                _mirrorText = !_mirrorText;
              });
              _resetUITimer();
            },
          ),

          // Aspect Ratio Manual Overlay Cycle
          _buildFloatingTopPill(
            icon: Icons.aspect_ratio,
            label: '${_effectivePreset.label} ${_manualPresetOverride != null ? "(Manual)" : "(Auto)"}',
            isActive: _manualPresetOverride != null,
            onTap: () {
              setState(() {
                final current = _effectivePreset;
                if (current == AspectRatioPreset.youtube) {
                  _manualPresetOverride = AspectRatioPreset.tiktok;
                } else if (current == AspectRatioPreset.tiktok) {
                  _manualPresetOverride = AspectRatioPreset.square;
                } else {
                  _manualPresetOverride = null; // resets to auto
                }
              });
              _resetUITimer();
            },
          ),

          // Flip Camera
          GestureDetector(
            onTap: () {
              _switchCamera();
              _resetUITimer();
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white12, width: 1),
                  ),
                  child: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Floating Navigation capsules helper
  Widget _buildFloatingTopPill({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFFF2B54).withOpacity(0.25) : Colors.black38,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive ? const Color(0xFFFF2B54).withOpacity(0.5) : Colors.white10,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: isActive ? const Color(0xFFFF2B54) : Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12, 
                    fontWeight: FontWeight.w600,
                    color: isActive ? const Color(0xFFFF2B54) : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: TweenAnimationBuilder<double>(
          key: ValueKey<int>(_countdownSeconds),
          tween: Tween<double>(begin: 2.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: (2.0 - value).clamp(0.0, 1.0),
                child: Text(
                  '$_countdownSeconds',
                  style: GoogleFonts.outfit(
                    fontSize: 150,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFFF2B54),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Floating Control & Settings Glassmorphic dock
  Widget _buildBottomControlPanel(Size size, bool isLandscape) {
    double dockWidth = isLandscape ? size.width * 0.70 : size.width * 0.90;
    
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      bottom: _showUI ? (MediaQuery.of(context).padding.bottom + 10) : -300,
      left: (size.width - dockWidth) / 2,
      width: dockWidth,
      child: GestureDetector(
        onTap: () {
          // Tap inside panel does NOT trigger screen click hide, just resets the timer
          _resetUITimer();
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sliders panel
                  isLandscape ? _buildLandscapeSliders() : _buildPortraitSliders(),
                  const Divider(color: Colors.white10, height: 16),

                  // Horizontal Color Selection Tray
                  _buildColorPaletteTray(),
                  const SizedBox(height: 12),
                  
                  // Bottom Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Play / Pause Scroll
                      IconButton(
                        onPressed: () {
                          _toggleScrolling();
                          _resetUITimer();
                        },
                        icon: Icon(
                          _isScrolling ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                      
                      // Restart/Reset Scroll Offset
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _currentScrollOffset = 0;
                            if (_scrollController.hasClients) {
                              _scrollController.jumpTo(0);
                            }
                          });
                          _resetUITimer();
                        },
                        icon: const Icon(
                          Icons.replay_circle_filled,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                      
                      // CENTRAL ACTION PULSING RECORD BUTTON
                      GestureDetector(
                        onTap: () {
                          _startRecordingWorkflow();
                          _resetUITimer();
                        },
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
                            );
                          },
                        ),
                      ),
                      
                      // Audio indicator waveform
                      Container(
                        width: 50,
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(_audioLevels.length, (index) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 3,
                              height: 25 * _audioLevels[index],
                              decoration: BoxDecoration(
                                color: _isRecording ? const Color(0xFFFF2B54) : Colors.white24,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        ),
                      ),

                      // Keyboard indicator or simple help note icon
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _showUI = false; // Hide immediately manually
                          });
                        },
                        icon: const Icon(
                          Icons.visibility_off,
                          color: Colors.white54,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Circular Color Selection Tray layout
  Widget _buildColorPaletteTray() {
    return SizedBox(
      height: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Script Color: ',
            style: GoogleFonts.outfit(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_colorPalette.length, (index) {
              final color = _colorPalette[index];
              final isSelected = _textColor == color;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _textColor = color;
                  });
                  _resetUITimer();
                },
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ] : null,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitSliders() {
    return Column(
      children: [
        _buildSliderItem(
          label: 'Speed',
          value: _scrollSpeed,
          min: 5.0,
          max: 80.0,
          onChanged: (val) {
            setState(() {
              _scrollSpeed = val;
            });
            if (_isScrolling) _startScrolling();
          },
        ),
        const SizedBox(height: 8),
        _buildSliderItem(
          label: 'Font Size',
          value: _fontSize,
          min: 16.0,
          max: 42.0,
          onChanged: (val) {
            setState(() {
              _fontSize = val;
            });
            _resetUITimer();
          },
        ),
        const SizedBox(height: 8),
        _buildSliderItem(
          label: 'Reading Line Alignment',
          value: _readingZoneTopOffset,
          min: 60.0,
          max: 250.0,
          onChanged: (val) {
            setState(() {
              _readingZoneTopOffset = val;
            });
            _resetUITimer();
          },
        ),
      ],
    );
  }

  Widget _buildLandscapeSliders() {
    return Row(
      children: [
        Expanded(
          child: _buildSliderItem(
            label: 'Speed',
            value: _scrollSpeed,
            min: 5.0,
            max: 80.0,
            onChanged: (val) {
              setState(() {
                _scrollSpeed = val;
              });
              if (_isScrolling) _startScrolling();
            },
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildSliderItem(
            label: 'Font Size',
            value: _fontSize,
            min: 16.0,
            max: 42.0,
            onChanged: (val) {
              setState(() {
                _fontSize = val;
              });
              _resetUITimer();
            },
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildSliderItem(
            label: 'Reading Line Alignment',
            value: _readingZoneTopOffset,
            min: 60.0,
            max: 180.0,
            onChanged: (val) {
              setState(() {
                _readingZoneTopOffset = val;
              });
              _resetUITimer();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSliderItem({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(fontSize: 11, color: Colors.white60, fontWeight: FontWeight.w600),
              ),
              Text(
                '${value.toInt()}',
                style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFFFF2B54), fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 32,
          child: Slider(
            min: min,
            max: max,
            value: value,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
