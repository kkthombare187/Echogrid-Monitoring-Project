import 'package:flutter/material.dart';
import 'package:flutter_project/screens/auth/welcome_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Wrap everything in try-catch to see exactly what's failing
  try {
    print("=== STARTING APP INITIALIZATION ===");
    
    // Ensures that all Flutter bindings are initialized before running the app
    WidgetsFlutterBinding.ensureInitialized();
    print("✓ Flutter bindings initialized");
    
    // Check Firebase apps status
    print("Current Firebase apps: ${Firebase.apps.length}");
    for (var app in Firebase.apps) {
      print("  - App name: ${app.name}, options: ${app.options}");
    }
    
    // Try multiple approaches to Firebase initialization
    try {
      if (Firebase.apps.isEmpty) {
        print("Attempting to initialize Firebase...");
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print("✓ Firebase initialized successfully");
      } else {
        print("✓ Firebase already initialized, using existing app");
      }
    } catch (firebaseError) {
      print("⚠ Firebase initialization error: $firebaseError");
      print("⚠ Trying alternative Firebase initialization...");
      
      // Try without options as fallback
      try {
        await Firebase.initializeApp();
        print("✓ Firebase initialized with default options");
      } catch (fallbackError) {
        print("⚠ Firebase fallback failed: $fallbackError");
        print("⚠ Continuing without Firebase initialization...");
      }
    }
    
    print("=== LAUNCHING APP ===");
    runApp(const EcoGridApp());
    
  } catch (error, stackTrace) {
    print("=== CRITICAL ERROR ===");
    print("Error: $error");
    print("Stack trace: $stackTrace");
    
    // Run a minimal app that will definitely work
    runApp(const DebugApp());
  }
}

class EcoGridApp extends StatelessWidget {
  const EcoGridApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("=== BUILDING MAIN APP ===");
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoGrid Monitor',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1a1a1a),
      ),
      home: const SafeWrapper(child: WelcomeScreen()),
    );
  }
}

// Wrapper to catch any widget errors
class SafeWrapper extends StatelessWidget {
  final Widget child;
  
  const SafeWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    try {
      print("=== BUILDING WELCOME SCREEN ===");
      return child;
    } catch (error, stackTrace) {
      print("=== WIDGET ERROR ===");
      print("Error: $error");
      print("Stack trace: $stackTrace");
      
      return Scaffold(
        backgroundColor: const Color(0xFF1a1a1a),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Widget Error Detected',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Error: $error',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    print("Manual navigation to debug screen");
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const DebugScreen()),
                    );
                  },
                  child: const Text('Go to Debug Screen'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

// Minimal debug app that will always work
class DebugApp extends StatelessWidget {
  const DebugApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Debug Mode',
      theme: ThemeData.dark(),
      home: const DebugScreen(),
    );
  }
}

// Simple debug screen to verify app is working
class DebugScreen extends StatelessWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        title: const Text('Debug Mode'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'App Debug Information',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildDebugInfo('Flutter Version', 'Check console output'),
            _buildDebugInfo('Firebase Apps', Firebase.apps.length.toString()),
            _buildDebugInfo('Screen Size', '${MediaQuery.of(context).size}'),
            _buildDebugInfo('Platform', Theme.of(context).platform.toString()),
            const SizedBox(height: 30),
            const Text(
              'Actions:',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                print("=== MANUAL TEST: Trying to load WelcomeScreen ===");
                try {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                  );
                } catch (e) {
                  print("Error loading WelcomeScreen: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Test Welcome Screen'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                print("=== FIREBASE STATUS CHECK ===");
                print("Firebase apps: ${Firebase.apps.length}");
                for (var app in Firebase.apps) {
                  print("App: ${app.name}");
                }
              },
              child: const Text('Check Firebase Status'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}