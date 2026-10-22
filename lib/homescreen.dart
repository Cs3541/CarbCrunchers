import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Carb Crunchers',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 67, 249, 6),
                ),
              ),
              const SizedBox(height: 24.0),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const SizedBox(
                        height: 64.0,
                        child: Center(child: Text('My Recipes')),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const SizedBox(
                        height: 64.0,
                        child: Center(child: Text("Search Recipes")),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {},
                child: const SizedBox(
                  height: 64.0,
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