import 'package:flutter/material.dart';

import 'goals_screen.dart';

import 'Presenters/AuthPresenter.dart';
import 'browserecipes.dart';
import 'login.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authPresenter = AuthPresenter();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 123, 186, 253),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 48.0,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 48.0),
                      child: Text(
                        'Carb Crunchers',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Homemade Apple',
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      child: StreamBuilder(
                        stream: authPresenter.authStateChanges(),
                        initialData: authPresenter.currentUser,
                        builder: (context, snapshot) {
                          final user = snapshot.data;
                          return PopupMenuButton<String>(
                            tooltip: 'Profile',
                            icon: const Icon(
                              Icons.account_circle_outlined,
                              size: 30.0,
                              color: Color(0xFF1F5DA8),
                            ),
                            onSelected: (action) async {
                              if (action == 'sign-in') {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              } else if (action == 'sign-out') {
                                try {
                                  await authPresenter.signOut();
                                } catch (error) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Could not sign out: $error',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            itemBuilder: (context) => user == null
                                ? const [
                                    PopupMenuItem(
                                      value: 'sign-in',
                                      child: Text('Sign in / Sign up'),
                                    ),
                                  ]
                                : [
                                    PopupMenuItem<String>(
                                      enabled: false,
                                      child: Text(user.email ?? 'Signed in'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'sign-out',
                                      child: Text('Sign out'),
                                    ),
                                  ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BrowseRecipiesScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F5DA8),
                        foregroundColor: Colors.white,
                      ),
                      child: const SizedBox(
                        height: 72.0,
                        child: Center(child: Text('Browse Recipes')),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F5DA8),
                        foregroundColor: Colors.white,
                      ),
                      child: const SizedBox(
                        height: 72.0,
                        child: Center(child: Text("My Recipes")),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GoalsScreen(),
                    ),
                  );
                },
                child: const Text('Goals'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
