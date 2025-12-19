import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/gourd_data.dart';
import '../constants/app_constants.dart';
import 'history_page.dart';

class AnalyticsPage extends StatefulWidget {
  final List<Map<String, dynamic>> history;
  final bool hasCurrentImage;

  const AnalyticsPage({super.key, required this.history, this.hasCurrentImage = true});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {

  String _getMostCommonClass() {
    if (widget.history.isEmpty) return '';
    
    final Map<String, int> distribution = {};
    for (final item in widget.history) {
      final label = item['label'] as String;
      distribution[label] = (distribution[label] ?? 0) + 1;
    }
    
    if (distribution.isEmpty) return '';
    
    return distribution.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    final overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    );
    SystemChrome.setSystemUIOverlayStyle(overlay);

    if (widget.history.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlay,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    18,
                    MediaQuery.of(context).padding.top + 20,
                    18,
                    20,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.95),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Analytics',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.menu,
                          color: Colors.black,
                          size: 28,
                        ),
                        onSelected: (value) {
                          if (value == 'home') {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          } else if (value == 'history') {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => HistoryPage(
                                  history: widget.history,
                                  hasCurrentImage: widget.hasCurrentImage,
                                ),
                              ),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'home',
                            child: Text('Home'),
                          ),
                          const PopupMenuItem(
                            value: 'history',
                            child: Text('History'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No data to analyze',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start scanning images to see analytics',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Determine header color based on most common class and current image
    final mostCommonClass = _getMostCommonClass();
    final headerColor = (widget.hasCurrentImage && mostCommonClass.isNotEmpty) 
        ? (GourdData.labelColors[mostCommonClass] ?? AppConstants.primaryColor)
        : AppConstants.primaryColor;

    final stats = _calculateStats();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlay,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  18,
                  MediaQuery.of(context).padding.top + 20,
                  18,
                  20,
                ),
                decoration: BoxDecoration(
                  color: headerColor.withOpacity(0.95),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Analytics',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.black,
                        size: 28,
                      ),
                      onSelected: (value) {
                        if (value == 'home') {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        } else if (value == 'history') {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => HistoryPage(
                                history: widget.history,
                                hasCurrentImage: widget.hasCurrentImage,
                              ),
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'home',
                          child: Text('Home'),
                        ),
                        const PopupMenuItem(
                          value: 'history',
                          child: Text('History'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary cards
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Total Scans',
                              value: stats['totalScans'].toString(),
                              icon: Icons.photo_camera_outlined,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Unique Types',
                              value: stats['uniqueTypes'].toString(),
                              icon: Icons.category_outlined,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Avg Confidence',
                              value: '${(stats['avgConfidence'] * 100).toStringAsFixed(1)}%',
                              icon: Icons.trending_up,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Most Common',
                              value: stats['mostCommon'],
                              icon: Icons.star_outline,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Distribution chart
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Detection Distribution',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...stats['distribution'].entries.map((entry) {
                                final label = entry.key;
                                final count = entry.value;
                                final percentage = (count / stats['totalScans']) * 100;
                                final color = GourdData.labelColors[label] ?? Colors.grey;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            label,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '$count (${percentage.toStringAsFixed(1)}%)',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: percentage / 100,
                                          minHeight: 8,
                                          valueColor: AlwaysStoppedAnimation<Color>(color),
                                          backgroundColor: color.withOpacity(0.12),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateStats() {
    final Map<String, int> distribution = {};
    double totalConfidence = 0;

    for (final item in widget.history) {
      final label = item['label'] as String;
      distribution[label] = (distribution[label] ?? 0) + 1;
      totalConfidence += item['probability'] as double;
    }

    final mostCommon = distribution.entries.isEmpty
        ? 'N/A'
        : distribution.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    return {
      'totalScans': widget.history.length,
      'uniqueTypes': distribution.length,
      'avgConfidence': widget.history.isEmpty ? 0 : totalConfidence / widget.history.length,
      'mostCommon': mostCommon,
      'distribution': distribution,
    };
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
