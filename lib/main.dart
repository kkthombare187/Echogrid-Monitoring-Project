import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_project/screens/auth/auth_wrapper.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const EcoGridApp());
}

class EcoGridApp extends StatelessWidget {
  const EcoGridApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ecogrid Monitor',

      // A consistent dark theme applied globally
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.cyan,
        scaffoldBackgroundColor: const Color(0xff1a2a3a),

        // Use the 'Poppins' font for a modern look
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),

        // Global style for all AppBars
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),

        // Global style for all Cards, corrected to use CardThemeData
        cardTheme: const CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          color: Color(0xff2c4260), // A slightly lighter card color
        ),

        // Global style for all ElevatedButtons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            backgroundColor: Colors.cyan,
            foregroundColor: Colors.black,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),

        // Global style for the BottomNavigationBar
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xff2c4260),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}
