import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_page.dart';
import 'ai_onboarding_page.dart';
import 'careplan_view_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // IMPORTANT: await the async login call
    final bool success = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _loading = false);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CarePlanViewPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid username or password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // allow keyboard to push content up
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // logo (put your file at assets/company_logo.png)
              Image.asset(
                'assets/images/company_logo.png',
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 28),

              // boxed card for inputs
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _usernameController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (v) =>
                          (v == null || v.isEmpty) ? 'Enter username' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          obscureText: true,
                          validator: (v) =>
                          (v == null || v.isEmpty) ? 'Enter password' : null,
                          onFieldSubmitted: (_) => _handleLogin(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // full width button with loading indicator
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _loading
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Login',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
