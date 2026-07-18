import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:telelook/models/script.dart';
import 'package:telelook/screens/home_screen.dart';
import 'package:telelook/screens/all_templates_screen.dart';
import 'package:telelook/screens/project_details_screen.dart';
import 'package:telelook/screens/video_clips_screen.dart';
import 'package:telelook/screens/wizard_screens.dart';
import 'package:telelook/screens/scripts_list_screen.dart';
import 'package:telelook/screens/edit_script_screen.dart';
import 'package:telelook/screens/camera_reading_screen.dart';
import 'package:telelook/screens/splash_screen.dart';

enum AppScreen {
  splash,
  home,
  allTemplates,
  projectDetails,
  scriptsList,
  editScript,
  teleprompter,
  videoClipsList,
  wizardStep1,
  wizardStep2
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
      themeMode: ThemeMode.light, // Set default to light theme to match white/teal layouts
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F4F0),
        primaryColor: const Color(0xFF147A6D), // Teal brand primary color
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF147A6D),
          secondary: Color(0xFF14C8A6),
          surface: Colors.white,
        ),
      ),
      darkTheme: ThemeData.dark(),
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
  AppScreen _currentScreen = AppScreen.splash;
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
      case AppScreen.splash:
        return SplashScreen(
          onFinished: () => _navigateTo(AppScreen.home), // Route to Home Screen after splash
        );
      case AppScreen.home:
        return HomeScreen(
          onSelectProject: () => _navigateTo(AppScreen.projectDetails),
          onSeeTemplates: () => _navigateTo(AppScreen.allTemplates),
        );
      case AppScreen.allTemplates:
        return AllTemplatesScreen(
          onBack: () => _navigateTo(AppScreen.home),
          onSelectTemplate: () => _navigateTo(AppScreen.projectDetails),
        );
      case AppScreen.projectDetails:
        return ProjectDetailsScreen(
          onBack: () => _navigateTo(AppScreen.home),
          onWriteScript: () => _navigateTo(AppScreen.editScript),
          onRecordClips: () => _navigateTo(AppScreen.videoClipsList),
        );
      case AppScreen.videoClipsList:
        return VideoClipsScreen(
          onBack: () => _navigateTo(AppScreen.projectDetails),
          onAskToEdit: () => _navigateTo(AppScreen.wizardStep1),
        );
      case AppScreen.wizardStep1:
        return WizardStep1Screen(
          onBack: () => _navigateTo(AppScreen.videoClipsList),
          onNext: () => _navigateTo(AppScreen.wizardStep2),
        );
      case AppScreen.wizardStep2:
        return WizardStep2Screen(
          onBack: () => _navigateTo(AppScreen.wizardStep1),
          onSubmit: () {
            // Show submit confirmation
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Brand guidelines submitted successfully!'),
                backgroundColor: Color(0xFF147A6D),
              ),
            );
            _navigateTo(AppScreen.home);
          },
        );
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
            _navigateTo(AppScreen.projectDetails);
          },
          onStartReading: (updatedScript) {
            setState(() {
              _scripts[_activeScriptIndex] = updatedScript;
            });
            _navigateTo(AppScreen.teleprompter);
          },
          onCancel: () {
            _navigateTo(AppScreen.projectDetails);
          },
        );
      case AppScreen.teleprompter:
        return CameraReadingScreen(
          script: _scripts[_activeScriptIndex],
          onBack: () {
            _navigateTo(AppScreen.videoClipsList);
          },
        );
    }
  }
}
