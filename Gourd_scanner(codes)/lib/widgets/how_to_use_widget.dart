import 'package:flutter/material.dart';

class HowToUseWidget extends StatelessWidget {
  const HowToUseWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to use:',
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• Tap Camera to take a new photo'),
              SizedBox(height: 6),
              Text('• Tap Gallery to choose from your photos'),
              SizedBox(height: 6),
              Text('• Ensure the subject is well-lit and in focus'),
            ],
          ),
        ],
      ),
    );
  }
}
