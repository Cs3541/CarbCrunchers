import 'package:flutter/material.dart';

import 'login.dart';
import 'Presenters/AuthPresenter.dart';
import 'widgets/auth_screen_layout.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _presenter = AuthPresenter();

  String? _errorMessage;

  Future<void> handleSignup() async {
    final error = await _presenter.signUp(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    if (!mounted) return;
    if (error != null) {
      setState(() => _errorMessage = error);
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
      title: 'Create your account',
      description: 'Set up your profile to get started.',
      emailController: emailController,
      passwordController: passwordController,
      submitLabel: 'Sign up',
      onSubmit: handleSignup,
      switchPrompt: 'Already have an account?',
      switchLabel: 'Login',
      onSwitch: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      },
      errorMessage: _errorMessage,
    );
  }
}
