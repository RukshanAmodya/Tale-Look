import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:telelook/models/script.dart';
import 'package:telelook/screens/scripts_list_screen.dart';
import 'package:telelook/screens/edit_script_screen.dart';
import 'package:telelook/screens/camera_reading_screen.dart';

enum AppScreen {
  scriptsList,
  editScript,
  teleprompter
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Allow all orientations for automatic layout rotation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
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
