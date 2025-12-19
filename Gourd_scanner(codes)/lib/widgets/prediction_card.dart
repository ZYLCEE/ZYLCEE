import 'package:flutter/material.dart';
import '../models/gourd_data.dart';

class PredictionCard extends StatelessWidget {
  final String label;
  final double probability;
  final String? description;
  final bool showDescription;

  const PredictionCard({
    super.key,
    required this.label,
    required this.probability,
    this.description,
    this.showDescription = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = GourdData.labelColors[label] ?? Colors.deepPurple;
    final percentage = (probability * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: probability,
              minHeight: 18,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              backgroundColor: color.withOpacity(0.12),
            ),
          ),
          if (showDescription && description != null) ...[
            const SizedBox(height: 12),
            Text(
              description!,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
