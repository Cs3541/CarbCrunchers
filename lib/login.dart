import 'package:carb_cruncher/Presenters/AuthPresenter.dart';
import 'package:flutter/material.dart';

import 'signup.dart';
import 'widgets/auth_screen_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _presenter = AuthPresenter();

  String? _errorMessage;

  Future<void> handleLogin() async {
    final error = await _presenter.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    if (!mounted) return;
    if (error != null) {
      setState(() => _errorMessage = error.toString());
    } else {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(
      title: 'Welcome back',
      description: 'Sign in to continue to Carb Crunchers.',
      emailController: emailController,
      passwordController: passwordController,
      submitLabel: 'Login',
      onSubmit: handleLogin,
      switchPrompt: "Don't have an account?",
      switchLabel: 'Sign up',
      onSwitch: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SignupScreen()),
        );
      },
      errorMessage: _errorMessage,
    );
  }
}
