import 'package:flutter/material.dart'
    show AppBar, BuildContext, Center, Scaffold, StatelessWidget, Text, Widget;

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Profile Page')),
    );
  }
}
