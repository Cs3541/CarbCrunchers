import 'package:flutter/material.dart';

class AuthScreenLayout extends StatelessWidget {
  const AuthScreenLayout({
    required this.title,
    required this.description,
    required this.emailController,
    required this.passwordController,
    required this.submitLabel,
    required this.onSubmit,
    required this.switchPrompt,
    required this.switchLabel,
    required this.onSwitch,
    this.errorMessage,
    super.key,
  });

  final String title;
  final String description;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String submitLabel;
  final VoidCallback onSubmit;
  final String switchPrompt;
  final String switchLabel;
  final VoidCallback onSwitch;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7E7CE),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFFF7E7CE),
        foregroundColor: const Color(0xFF1F5DA8),
        elevation: 0,
        title: const Text(
          'Carb Crunchers',
          style: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'Homemade Apple',
            color: Color(0xFFB45309),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight > 48.0
                    ? constraints.maxHeight - 48.0
                    : 0.0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440.0),
                  child: Card(
                    color: Colors.white,
                    elevation: 2.0,
                    shadowColor: const Color(0x331F5DA8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFB45309),
                              fontSize: 26.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF66594A),
                              fontSize: 15.0,
                            ),
                          ),
                          const SizedBox(height: 28.0),
                          if (errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0ED),
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(
                                  color: const Color(0xFFE8B4AA),
                                ),
                              ),
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFF9B2C20),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                          ],
                          TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: _inputDecoration(
                              label: 'Email',
                              icon: Icons.email_outlined,
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onSubmitted: (_) => onSubmit(),
                            decoration: _inputDecoration(
                              label: 'Password',
                              icon: Icons.lock_outline,
                            ),
                          ),
                          const SizedBox(height: 24.0),
                          SizedBox(
                            height: 56.0,
                            child: ElevatedButton(
                              onPressed: onSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1F5DA8),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              child: Text(
                                submitLabel,
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                switchPrompt,
                                style: const TextStyle(
                                  color: Color(0xFF66594A),
                                ),
                              ),
                              TextButton(
                                onPressed: onSwitch,
                                child: Text(switchLabel),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF1F5DA8)),
      filled: true,
      fillColor: const Color(0xFFFFFBF5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Color(0xFFE6D5BD)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Color(0xFFE6D5BD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Color(0xFF1F5DA8), width: 2.0),
      ),
    );
  }
}
