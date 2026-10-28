import 'package:flutter/material.dart';

import 'browserecipes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 123, 186, 253),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Carb Crunchers',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Homemade Apple',
                  color: Color(0xFFB45309),
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
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F5DA8),
                  foregroundColor: Colors.white,
                ),
                child: const SizedBox(
                  height: 72.0,
                  child: Center(child: Text('Goals')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
