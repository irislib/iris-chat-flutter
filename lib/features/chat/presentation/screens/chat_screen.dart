import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final String sessionId;

  const ChatScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: const Center(
        child: Text('Chat Screen - TODO'),
      ),
    );
  }
}
