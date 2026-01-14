import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  UserRole _selectedRole = UserRole.parent;
  bool _isLogin = true;
  bool _isLoading = false;

  void _handleAuth() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    if (!_isLogin && _nameController.text.isEmpty) return;

    setState(() => _isLoading = true);
    final state = context.read<AppState>();
    
    String? error;
    if (_isLogin) {
      error = await state.signIn(_emailController.text, _passwordController.text);
    } else {
      error = await state.signUp(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        role: _selectedRole,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monitor_heart, color: Colors.white, size: 60),
              const SizedBox(height: 16),
              const Text(
                'FAMILY PULSE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 48),
              if (!_isLogin)
                _buildTextField(_nameController, 'Your Name', Icons.person),
              const SizedBox(height: 16),
              _buildTextField(_emailController, 'Email Address', Icons.email, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextField(_passwordController, 'Password', Icons.lock, isPassword: true),
              const SizedBox(height: 32),
              
              if (!_isLogin) ...[
                const Text(
                  'I AM A...',
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _RoleButton(
                        role: UserRole.parent,
                        isSelected: _selectedRole == UserRole.parent,
                        onTap: () => setState(() => _selectedRole = UserRole.parent),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _RoleButton(
                        role: UserRole.child,
                        isSelected: _selectedRole == UserRole.child,
                        onTap: () => setState(() => _selectedRole = UserRole.child),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleAuth,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(_isLogin ? 'LOG IN' : 'CREATE ACCOUNT'),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin ? "NEW HERE? SIGN UP" : "ALREADY HAVE AN ACCOUNT? LOG IN",
                  style: const TextStyle(color: Colors.grey, letterSpacing: 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final UserRole role;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleButton({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white),
        ),
        child: Center(
          child: Text(
            role == UserRole.parent ? 'PARENT' : 'CHILD',
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
