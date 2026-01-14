import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'screens/auth_screen.dart';
import 'screens/family_setup_screen.dart';
import 'screens/hub_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const FamilyScreenTimeApp(),
    ),
  );
}

class FamilyScreenTimeApp extends StatelessWidget {
  const FamilyScreenTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family Pulse',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const RootScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.firebaseUser == null) {
      return const AuthScreen();
    }
    
    // Auth succeeded, but waiting for Firestore profile to load
    if (state.currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state.authError != null) ...[
                  const Icon(Icons.cloud_off, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    state.authError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: state.logout,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                    child: const Text('BACK TO LOGIN'),
                  ),
                ] else ...[
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 24),
                  const Text(
                    'Syncing from Cloud...',
                    style: TextStyle(color: Colors.grey, letterSpacing: 1),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    
    if (state.currentFamily == null) {
      return const FamilySetupScreen();
    }
    
    return const HubScreen();
  }
}
