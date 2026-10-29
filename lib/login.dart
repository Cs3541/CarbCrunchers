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
  String? _successMessage;
  bool _isSendingReset = false;

  Future<void> handleLogin() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
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

  Future<void> handlePasswordReset() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Enter your email address to reset your password.';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _isSendingReset = true;
    });

    final error = await _presenter.resetPassword(email);

    if (!mounted) return;
    setState(() {
      _isSendingReset = false;
      if (error != null) {
        _errorMessage = error;
      } else {
        _successMessage = 'If an account exists for that email, a password reset link will be sent.';
      }
    });
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
      onPasswordReset: handlePasswordReset,
      isSendingReset: _isSendingReset,
      switchPrompt: "Don't have an account?",
      switchLabel: 'Sign up',
      onSwitch: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SignupScreen()),
        );
      },
      errorMessage: _errorMessage,
      successMessage: _successMessage,
    );
  }
}
