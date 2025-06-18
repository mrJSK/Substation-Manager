// lib/screens/info_screen.dart

import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Information'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About Substation Manager ✨',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const Text(
              'Welcome to Substation Manager – your essential companion for efficient and accurate management of electrical substations! 🚀\n\n'
              'This app is designed to streamline daily operations, equipment tracking, and reporting. Here’s what you can do:\n\n'
              '➡️ *Digital Plant Register:* Maintain a comprehensive digital record of all equipment within your substations.\n\n'
              '🗺️ *Interactive SLD:* Visualize your substation\'s Single Line Diagram on screen, click on equipment icons for details, and see connections.\n\n'
              '📝 *Daily Readings & Operations:* SSOs can easily enter daily operational readings for assigned equipment. JEs/SDOs can assign and monitor these reading tasks.\n\n'
              '☁️ *Centralized Data:* All collected data is synced to a secure cloud database, ensuring real-time visibility and data integrity across all roles.\n\n'
              '📊 *Progress Monitoring:* Track daily operational compliance and overall substation health from your dashboard.\n\n'
              '📦 *Export Reports:* Generate detailed CSV reports of equipment data, historical readings, and operational summaries.\n\n'
              'Substation Manager is here to enhance efficiency, safety, and data accuracy in your substation operations. Powering tomorrow! 💪',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Text(
              'Developed By:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('Sanjay Kumar'),
            const Text('Sub-Divisional Officer'),
            const Text('UPPTCL'),
            const SizedBox(height: 16),
            Text('Contact:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('Email: fswdsanjay@gmail.com'),
            const Text('Phone: +91-8299189690'),
            const SizedBox(height: 32),
            const Text(
              'Version: 1.0.0 (Development)',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
