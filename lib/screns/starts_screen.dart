import 'package:flutter/material.dart';

class StartsScreen extends StatefulWidget {
  const StartsScreen({super.key});

  @override
  State<StartsScreen> createState() => _StartsScreenState();
}

class _StartsScreenState extends State<StartsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Home Pulse')),
        backgroundColor: Colors.brown,
        actions: [IconButton(icon: Icon(Icons.settings), onPressed: () {})],
      ),
      body: Center(child: Text('Welcome to the Home Pulse!')),
    );
  }
}
