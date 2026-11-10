import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../Presenters/AuthPresenter.dart';
import '../widgets/profile_avatar.dart';
import 'goals_screen.dart';

import 'browserecipes.dart';
import 'my_recipe_screen.dart';
import 'meal_plan_view.dart';
import '../Views/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authPresenter = AuthPresenter();
    final database = FirebaseDatabase.instance;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 231, 206),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 72.0,
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
                      child: StreamBuilder<User?>(
                        stream: authPresenter.userChanges(),
                        initialData: authPresenter.currentUser,
                        builder: (context, snapshot) {
                          final user = snapshot.data;
                          if (user == null) {
                            return _buildProfileButton(context, null);
                          }

                          return StreamBuilder<DatabaseEvent>(
                            stream: database
                                .ref('profileImages/${user.uid}')
                                .onValue,
                            builder: (context, imageSnapshot) =>
                                _buildProfileButton(
                                  context,
                                  imageSnapshot.data?.snapshot.value,
                                ),
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyRecipeScreen(),
                          ),
                        );
                      },
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

              // Meal Plan Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyMealsScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F5DA8),
                  foregroundColor: Colors.white,
                ),
                child: const SizedBox(
                  height: 72.0,
                  child: Center(child: Text("My Meals")),
                ),
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

  Widget _buildProfileButton(BuildContext context, Object? profileData) {
    return IconButton(
      tooltip: 'Profile',
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFF1F5DA8),
        foregroundColor: Colors.white,
        fixedSize: const Size(40, 40),
        padding: EdgeInsets.zero,
      ),
      icon: ProfileAvatar(profileData: profileData, radius: 20),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
      },
    );
  }
}
