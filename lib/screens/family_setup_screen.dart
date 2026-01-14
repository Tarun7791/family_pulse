import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import 'hub_screen.dart'; // Import HubScreen

class FamilySetupScreen extends StatefulWidget {
  const FamilySetupScreen({super.key});

  @override
  State<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends State<FamilySetupScreen> {
  final _familyController = TextEditingController();
  final _joinCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FAMILY SETUP', style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (user.role == UserRole.parent) ...[
              const Text(
                'CREATE FAMILY',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _familyController,
                decoration: const InputDecoration(
                  labelText: 'Family Name',
                  prefixIcon: Icon(Icons.family_restroom),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_familyController.text.isNotEmpty) {
                    await state.createFamily(_familyController.text);
                    // No need to Navigator.push as RootScreen in main.dart handles the switch to HubScreen
                  }
                },
                child: const Text('CREATE & START'),
              ),
            ] else ...[
              const Text(
                'JOIN FAMILY',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _joinCodeController,
                decoration: const InputDecoration(
                  labelText: 'Enter 6-Digit Code',
                  prefixIcon: Icon(Icons.key),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_joinCodeController.text.isNotEmpty) {
                    final success = await state.joinFamily(_joinCodeController.text);
                    if (!success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid code. Try "123456"')),
                      );
                    }
                  }
                },
                child: const Text('JOIN FAMILY'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ask your parent for the family code.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
