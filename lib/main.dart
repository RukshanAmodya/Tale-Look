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
  
  // Allow all orientations
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
          surface: Color(0xFF0B0B0C),
        ),
      ),
      home: const TeleprompterNavigationFlow(),
    );
  }
}

// Structured Script Model matching Segment screenshot design
class ScriptSegment {
  String title;
  String content;
  List<String> emotions;

  ScriptSegment({
    required this.title,
    required this.content,
    required this.emotions,
  });

  ScriptSegment copyWith({
    String? title,
    String? content,
    List<String>? emotions,
  }) {
    return ScriptSegment(
      title: title ?? this.title,
      content: content ?? this.content,
      emotions: emotions ?? this.emotions,
    );
  }
}

class TeleprompterScript {
  final String id;
  String title;
  List<ScriptSegment> segments;

  TeleprompterScript({
    required this.id,
    required this.title,
    required this.segments,
  });

  int get wordCount {
    int count = 0;
    for (var seg in segments) {
      count += seg.content.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
    }
    return count;
  }

  int get estimatedSeconds {
    // average reading speed 150 words per minute (2.5 words per second)
    return (wordCount / 2.5).round();
  }

  String get durationString {
    int seconds = estimatedSeconds;
    if (seconds < 60) return '$seconds sec';
    int min = seconds ~/ 60;
    return '$min min';
  }

  String get fullContent {
    return segments.map((s) => s.content).join("\n\n");
  }

  TeleprompterScript copyWith({
    String? title,
    List<ScriptSegment>? segments,
  }) {
    return TeleprompterScript(
      id: id,
      title: title ?? this.title,
      segments: segments ?? this.segments.map((s) => s.copyWith()).toList(),
    );
  }
}

enum AppScreen {
  scriptsList,
  editScript,
  teleprompter
}

class TeleprompterNavigationFlow extends StatefulWidget {
  const TeleprompterNavigationFlow({super.key});

  @override
  State<TeleprompterNavigationFlow> createState() => _TeleprompterNavigationFlowState();
}

class _TeleprompterNavigationFlowState extends State<TeleprompterNavigationFlow> {
  AppScreen _currentScreen = AppScreen.scriptsList;
  late List<TeleprompterScript> _scripts;
  int _activeScriptIndex = 0;
  
  @override
  void initState() {
    super.initState();
    // Default mock data matching the screenshot cards
    _scripts = [
      TeleprompterScript(
        id: 'welcome_speech',
        title: 'Welcome speech',
        segments: [
          ScriptSegment(
            title: 'Introduction',
            content: 'Welcome to your new script — a clean workspace where you can craft, refine, and rehearse your content with full focus...',
            emotions: ['curious', 'confident', 'excited'],
          ),
          ScriptSegment(
            title: 'Dive deeper',
            content: 'This space becomes a quiet companion that helps you explore your thoughts more intentionally — unfolding layers, clarifying meaning, and guiding you toward a script that feels polished, confident, and fully aligned with your voice.',
            emotions: ['focused', 'natural'],
          ),
        ],
      ),
      TeleprompterScript(
        id: 'product_launch',
        title: 'Product launch',
        segments: [
          ScriptSegment(
            title: 'Hook',
            content: 'Preparing for a product launch can feel overwhelming, but keeping direct eye contact with the camera makes all the difference...',
            emotions: ['bold', 'excited'],
          ),
        ],
      ),
    ];
  }

  void _navigateTo(AppScreen screen) {
    setState(() {
      _currentScreen = screen;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentScreen) {
      case AppScreen.scriptsList:
        return ScriptsListScreen(
          scripts: _scripts,
          onSelectScript: (index) {
            setState(() {
              _activeScriptIndex = index;
            });
            _navigateTo(AppScreen.teleprompter);
          },
          onEditScript: (index) {
            setState(() {
              _activeScriptIndex = index;
            });
            _navigateTo(AppScreen.editScript);
          },
          onCreateScript: () {
            final newScript = TeleprompterScript(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: 'Untitled Script',
              segments: [
                ScriptSegment(
                  title: 'Introduction',
                  content: 'Type your content here...',
                  emotions: [],
                ),
              ],
            );
            setState(() {
              _scripts.add(newScript);
              _activeScriptIndex = _scripts.length - 1;
            });
            _navigateTo(AppScreen.editScript);
          },
        );
      case AppScreen.editScript:
        return EditScriptScreen(
          script: _scripts[_activeScriptIndex],
          onSave: (updatedScript) {
            setState(() {
              _scripts[_activeScriptIndex] = updatedScript;
            });
            _navigateTo(AppScreen.scriptsList);
          },
          onStartReading: (updatedScript) {
            setState(() {
              _scripts[_activeScriptIndex] = updatedScript;
            });
            _navigateTo(AppScreen.teleprompter);
          },
          onCancel: () {
            _navigateTo(AppScreen.scriptsList);
          },
        );
      case AppScreen.teleprompter:
        return CameraReadingScreen(
          script: _scripts[_activeScriptIndex],
          onBack: () {
            _navigateTo(AppScreen.scriptsList);
          },
        );
    }
  }
}

// ----------------------------------------------------
// PAGE 1: Scripts List Screen (Premium Mesh Gradient layout)
// ----------------------------------------------------
class ScriptsListScreen extends StatelessWidget {
  final List<TeleprompterScript> scripts;
  final Function(int) onSelectScript;
  final Function(int) onEditScript;
  final VoidCallback onCreateScript;

  const ScriptsListScreen({
    super.key,
    required this.scripts,
    required this.onSelectScript,
    required this.onEditScript,
    required this.onCreateScript,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header matching design
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  Text(
                    'Scripts',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.search, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              
              // Scrollable list of cards
              Expanded(
                child: ListView.builder(
                  itemCount: scripts.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final script = scripts[index];
                    
                    // Choose mesh-gradient style colors based on index
                    final List<Color> gradientColors = index % 2 == 0
                        ? [const Color(0xFF1E133F), const Color(0xFF0F0B1A), const Color(0xFF121422)]
                        : [const Color(0xFF0F2B22), const Color(0xFF0B1411), const Color(0xFF111422)];
                        
                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradientColors,
                        ),
                        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          )
                        ]
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card details header row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Dec 9 • ${script.wordCount} words • ${script.durationString}',
                                style: GoogleFonts.outfit(
                                  color: Colors.white38,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => onEditScript(index),
                                child: Text(
                                  'Edit',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 18),
                          
                          // Title & Content
                          Text(
                            script.title,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            script.segments.first.content,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: RegExp(r'[\u0D80-\u0DFF]').hasMatch(script.segments.first.content) ? 'SinhalaSangam' : null,
                              color: Colors.white54,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Button row
                          Row(
                            children: [
                              // Sparkle AI button
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome, 
                                  color: Colors.white, 
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              
                              // Start Reading Button
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => onSelectScript(index),
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: Colors.white30, width: 1.2),
                                      color: Colors.black26,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Start reading',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      
      // Floating Plus Button to match UI card-level layout additions
      floatingActionButton: FloatingActionButton(
        onPressed: onCreateScript,
        backgroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
    );
  }
}

// ----------------------------------------------------
// PAGE 2: Edit Script Screen (Segment Editor layout)
// ----------------------------------------------------
class EditScriptScreen extends StatefulWidget {
  final TeleprompterScript script;
  final Function(TeleprompterScript) onSave;
  final Function(TeleprompterScript) onStartReading;
  final VoidCallback onCancel;

  const EditScriptScreen({
    super.key,
    required this.script,
    required this.onSave,
    required this.onStartReading,
    required this.onCancel,
  });

  @override
  State<EditScriptScreen> createState() => _EditScriptScreenState();
}

class _EditScriptScreenState extends State<EditScriptScreen> {
  late TeleprompterScript _editedScript;
  late TextEditingController _titleController;
  final List<TextEditingController> _segmentControllers = [];
  int? _activeEditingSegmentIndex;

  @override
  void initState() {
    super.initState();
    _editedScript = widget.script.copyWith();
    _titleController = TextEditingController(text: _editedScript.title);
    for (var seg in _editedScript.segments) {
      _segmentControllers.add(TextEditingController(text: seg.content));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var c in _segmentControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addNewSegment() {
    setState(() {
      _editedScript.segments.add(
        ScriptSegment(
          title: 'New Segment',
          content: '',
          emotions: ['natural'],
        ),
      );
      _segmentControllers.add(TextEditingController());
    });
  }

  void _saveChanges() {
    _editedScript.title = _titleController.text;
    for (int i = 0; i < _editedScript.segments.length; i++) {
      _editedScript.segments[i].content = _segmentControllers[i].text;
    }
    widget.onSave(_editedScript);
  }

  void _startReading() {
    _editedScript.title = _titleController.text;
    for (int i = 0; i < _editedScript.segments.length; i++) {
      _editedScript.segments[i].content = _segmentControllers[i].text;
    }
    widget.onStartReading(_editedScript);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: widget.onCancel,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  Text(
                    'Edit script',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: _saveChanges,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            
            // Editable Script Form Fields
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Input
                    TextField(
                      controller: _titleController,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Welcome speech',
                        hintStyle: TextStyle(color: Colors.white24),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Dec 9 • ${_editedScript.wordCount} words • ${_editedScript.durationString}',
                      style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
                    ),
                    const SizedBox(height: 30),
                    
                    // Segments Builder
                    ListView.builder(
                      itemCount: _editedScript.segments.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final segment = _editedScript.segments[index];
                        final controller = _segmentControllers[index];
                        final isEditingThis = _activeEditingSegmentIndex == index;
                        
                        return isEditingThis 
                            ? _buildFullSegmentEditor(index, segment, controller)
                            : _buildCompactSegmentBlock(index, segment, controller);
                      },
                    ),
                    
                    const SizedBox(height: 15),
                    // Add segment button
                    GestureDetector(
                      onTap: _addNewSegment,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add, color: Colors.white60, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Segment',
                              style: GoogleFonts.outfit(
                                color: Colors.white60,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            
            // Bottom Action Drawer Panel
            _buildBottomActionPanel(),
          ],
        ),
      ),
    );
  }

  // Segment Card: Compact layout (View Mode)
  Widget _buildCompactSegmentBlock(int index, ScriptSegment segment, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Green dot indicator matching screenshots
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFF0F321C),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.arrow_right_alt, color: Color(0xFF39FF14), size: 10),
              ),
            ),
          ),
          const SizedBox(width: 14),
          
          // Script Content View Area
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeEditingSegmentIndex = index;
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    segment.title,
                    style: GoogleFonts.outfit(
                      color: Colors.white38,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    controller.text.isNotEmpty ? controller.text : 'Tap to write...',
                    style: TextStyle(
                      fontFamily: RegExp(r'[\u0D80-\u0DFF]').hasMatch(controller.text) ? 'SinhalaSangam' : null,
                      color: controller.text.isNotEmpty ? Colors.white : Colors.white24,
                      fontSize: 16,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Segment Card: Detailed Editor (Edit Mode)
  Widget _buildFullSegmentEditor(int index, ScriptSegment segment, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Editing Segment',
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _activeEditingSegmentIndex = null;
                  });
                },
                child: Text(
                  'Done',
                  style: GoogleFonts.outfit(color: const Color(0xFFFF2B54), fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
          
          // Segment title field
          TextFormField(
            initialValue: segment.title,
            style: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16),
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Segment Label',
              labelStyle: TextStyle(color: Colors.white24),
              border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF2B54))),
            ),
            onChanged: (val) {
              segment.title = val;
            },
          ),
          const SizedBox(height: 15),
          
          // Segment content body editor field
          TextField(
            controller: controller,
            maxLines: null,
            style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.45),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Type script details...',
              hintStyle: TextStyle(color: Colors.white24),
            ),
          ),
          const SizedBox(height: 20),
          
          // Mood/Emotion Chips Tray matching screenshot
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...List.generate(segment.emotions.length, (emoIndex) {
                final emo = segment.emotions[emoIndex];
                return Chip(
                  label: Text(emo, style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70)),
                  backgroundColor: const Color(0xFF1A1528),
                  side: const BorderSide(color: Colors.white10),
                  onDeleted: () {
                    setState(() {
                      segment.emotions.removeAt(emoIndex);
                    });
                  },
                  deleteIcon: const Icon(Icons.close, size: 12, color: Colors.white30),
                );
              }),
              GestureDetector(
                onTap: () {
                  // Prompt custom emotion dialog
                  _addEmotionTag(segment);
                },
                child: Chip(
                  avatar: const Icon(Icons.add, color: Colors.white38, size: 12),
                  label: Text('Emotion', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38)),
                  backgroundColor: Colors.transparent,
                  side: const BorderSide(color: Colors.white24),
                ),
              )
            ],
          ),
          
          const SizedBox(height: 15),
          // Voice Dictation Box simulator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Simulate voice dictation',
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.white30),
              ),
              GestureDetector(
                onTap: () {
                  // Simulate typing
                  setState(() {
                    controller.text += " (dictated speech block)";
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic, color: Colors.black, size: 14),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  void _addEmotionTag(ScriptSegment segment) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E24),
          title: Text('Add Emotion/Tone Tag', style: GoogleFonts.outfit()),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'e.g. confident, excited, bold',
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF2B54))),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    segment.emotions.add(controller.text.trim());
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF2B54)),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Bottom action drawer
  Widget _buildBottomActionPanel() {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F10),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Start Reading
          GestureDetector(
            onTap: _startReading,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(27),
              ),
              child: Center(
                child: Text(
                  'Start reading',
                  style: GoogleFonts.outfit(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Preview Outline
          GestureDetector(
            onTap: _saveChanges,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(27),
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
              child: Center(
                child: Text(
                  'Save & Exit',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// PAGE 3: Camera Teleprompter Reading Screen
// ----------------------------------------------------
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
  
  // Customization variables
  int _wpm = 160; // Words Per Minute based speed
  double _fontSize = 26.0;
  bool _isScrolling = false;
  
  // High contrast text properties
  Color _textColor = Colors.white;
  int _highlightedWordIndex = 0;
  List<String> _words = [];
  
  // Navigation tabs state matching screenshot
  bool _isTabReading = true; // true = Reading, false = Preview
  
  // Scroll Controller & Timer
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  double _currentScrollOffset = 0.0;
  
  // Record Countdown State
  int _countdownSeconds = 0;
  Timer? _countdownTimer;
  
  // Animation controllers
  late AnimationController _recordPulseController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Parse words for high contrast highlighted reading tracking
    _words = widget.script.fullContent.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    
    _recordPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    
    _initializeCamera();
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
  
  // Speed calculation based on WPM
  double _getPixelsPerSecond() {
    // 160 wpm ≈ 2.6 words/sec. Each line typically has 4-5 words.
    // Line height is fontSize * 1.5. So 160 WPM ≈ 0.6 lines/sec.
    double lineSize = _fontSize * 1.5;
    double linesPerSecond = _wpm / (60 * 4.5); // assuming avg 4.5 words per line
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
      
      // Highlight word index simulation as we scroll
      // A simple formula mapping scroll offset to word index
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
          // LAYER 1: Full-Screen Camera Viewport (unzoomed, native aspect ratio)
          _buildCameraPreview(size),
          
          // Dotted Ellipse Target Guideline Overlay
          _buildFaceGuidelineOverlay(),

          // LAYER 2: Semi-transparent reading overlay
          _buildTeleprompterOverlay(size),
          
          // Thin horizontal dashed red reading target line guide
          _buildRedDashedLineGuide(size),

          // Top Header Tab Switcher (Preview | Reading)
          _buildTopTabsHeader(),

          // Center countdown overlay
          if (_countdownSeconds > 0) _buildCountdownOverlay(),

          // Bottom float WPM and recording controls panel
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

  // Face tracker guideline custom painter overlay matching screenshots
  Widget _buildFaceGuidelineOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: FaceGuidelinePainter(),
        ),
      ),
    );
  }

  // Horizontal dashed red target line guide
  Widget _buildRedDashedLineGuide(Size size) {
    // Red guideline aligned with reading text box
    return Positioned(
      top: size.height * 0.40,
      left: 10,
      right: 10,
      child: IgnorePointer(
        child: Row(
          children: List.generate(40, (index) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 1.5,
                color: const Color(0xFFFF2B54).withOpacity(0.8),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTeleprompterOverlay(Size size) {
    double textContainerHeight = size.height * 0.35;
    double containerTop = size.height * 0.25;
    
    // We split current segment and render with active highlighting
    return Positioned(
      top: containerTop,
      left: 30,
      right: 30,
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
              stops: [0.0, 0.25, 0.75, 1.0],
            ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
          },
          blendMode: BlendMode.dstIn,
          child: ListView.builder(
            controller: _scrollController,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              top: (size.height * 0.40) - containerTop - 18,
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
                    
                    // Highlight active word in Red, other words in white/grey
                    return TextSpan(
                      text: '$word ',
                      style: _getDynamicStyle(
                        word, 
                        _fontSize, 
                        isHighlighted ? const Color(0xFFFF2B54) : Colors.white70
                      ).copyWith(
                        fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                        backgroundColor: isHighlighted ? Colors.black54 : Colors.transparent,
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

  Widget _buildTopTabsHeader() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
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
          
          // Tabs: Preview | Reading
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

          // Buffer block for space alignment
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

  // WPM & Playback Action controls tray (Clean minimal capsule style)
  Widget _buildBottomActionDock(Size size) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      left: 30,
      right: 30,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row of play controls matching screenshots: Minus, Play Circle, Plus
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Speed Decrease (-)
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
              
              // Central Play / Pause Button
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
              
              // Speed Increase (+)
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
          
          // Display WPM
          Text(
            '$_wpm WPM',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 24),

          // Central Action Bar: Record & Flip Camera
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Spacing helper
              const SizedBox(width: 44),
              
              // Central Pulsing Record Button
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
              
              // Switch Camera Circle Button
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

// Custom Painter to draw circular guideline matching screenshots
class FaceGuidelinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw elliptical target guideline at the center third height
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.40),
      width: size.width * 0.72,
      height: size.height * 0.42,
    );
    canvas.drawOval(rect, paint);
    
    // Draw fine vertical axis guidelines
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.19),
      Offset(size.width / 2, size.height * 0.61),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
