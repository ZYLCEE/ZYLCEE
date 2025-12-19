import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../constants/app_constants.dart';
import '../models/gourd_data.dart';
import 'analytics_page.dart';

class HistoryPage extends StatefulWidget {
  final List<Map<String, dynamic>> history;
  final bool hasCurrentImage;
  final Function(int)? onDeleteItem;

  const HistoryPage({super.key, required this.history, this.hasCurrentImage = true, this.onDeleteItem});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {

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

    // Determine header color based on most common class and current image
    final mostCommonClass = _getMostCommonClass();
    final headerColor = (widget.hasCurrentImage && mostCommonClass.isNotEmpty) 
        ? (GourdData.labelColors[mostCommonClass] ?? AppConstants.primaryColor)
        : AppConstants.primaryColor;

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
                        'History',
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
                        } else if (value == 'analytics') {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => AnalyticsPage(
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
                          value: 'analytics',
                          child: Text('Analytics'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: widget.history.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No history yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start scanning images to see your history',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: widget.history.length,
                        itemBuilder: (context, index) {
                          final item = widget.history[widget.history.length - 1 - index];
                          final actualIndex = widget.history.length - 1 - index;
                          
                          return Dismissible(
                            key: Key('history_item_${item['timestamp']}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.delete_forever,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onDismissed: (direction) {
                              if (widget.onDeleteItem != null) {
                                widget.onDeleteItem!(actualIndex);
                              }
                              
                              // Show confirmation
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Item deleted permanently'),
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(8),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(item['image']),
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                title: Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['label'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getConfidenceColor(item['probability']),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${(item['probability'] * 100).toStringAsFixed(1)}%',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _getHighestClass(item),
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _formatDate(item['timestamp']),
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatTime(item['timestamp']),
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  Color _getConfidenceColor(double probability) {
    if (probability >= 0.8) {
      return Colors.green;
    } else if (probability >= 0.6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getHighestClass(Map<String, dynamic> item) {
    if (item.containsKey('allProbabilities') && item.containsKey('allLabels')) {
      final List<double> allProbs = List<double>.from(item['allProbabilities']);
      final List<String> allLabels = List<String>.from(item['allLabels']);
      
      // Check if lists are not empty
      if (allProbs.isEmpty || allLabels.isEmpty || allProbs.length != allLabels.length) {
        return item['label'] ?? 'Unknown';
      }
      
      // Create pairs and sort by probability
      final pairs = List.generate(
        allLabels.length,
        (i) => MapEntry(allLabels[i], allProbs[i]),
      );
      pairs.sort((a, b) => b.value.compareTo(a.value));
      
      if (pairs.isNotEmpty) {
        return pairs[0].key;
      }
    }
    return item['label'] ?? 'Unknown';
  }
}
