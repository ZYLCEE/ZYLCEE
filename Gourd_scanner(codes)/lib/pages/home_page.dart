import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import '../services/classification_service.dart';
import '../data/constants.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  File? _image;
  final ClassificationService _classificationService = ClassificationService();
  List<double> _probabilities = [];
  bool _isClassifying = false;

  static const Color _purple = Color(0xFF3271a5);

  late AnimationController _fadeController;

  String _currentPage = 'home';
  final List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _classificationService.loadModel();
    // In debug builds, check that assets referenced in _relatedImages
    // are actually bundled. This will print any missing asset paths to
    // the debug console which helps diagnose "Asset not found" errors.

    // Ensure the Android status bar matches the purple header color
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF3271a5),
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _classificationService.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      _probabilities.clear();
      _isClassifying = true;
    });

    await _classifyImage();
    _fadeController.forward(from: 0);
  }

  Future<void> _classifyImage() async {
    if (_image == null) return;

    final probs = await _classificationService.classifyImage(_image!);

    // Save to history
    final pairs = List.generate(
      _classificationService.labels.length,
      (i) => MapEntry(_classificationService.labels[i], probs[i]),
    );
    pairs.sort((a, b) => b.value.compareTo(a.value));
    final topLabel = pairs[0].key;
    final topProb = pairs[0].value;

    _history.add({
      'image': _image!.path,
      'label': topLabel,
      'probability': topProb,
      'timestamp': DateTime.now(),
    });

    setState(() {
      _probabilities = probs;
      _isClassifying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine top color based on top prediction
    Color topColor = _purple;
    if (_probabilities.isNotEmpty) {
      final pairs = List.generate(
        _classificationService.labels.length,
        (i) => MapEntry(_classificationService.labels[i], _probabilities[i]),
      );
      pairs.sort((a, b) => b.value.compareTo(a.value));
      final topLabel = pairs[0].key;
      topColor = labelColors[topLabel] ?? _purple;
    }

    final headerColor = topColor.withOpacity(0.95);
    final purple = _purple;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    final overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    );
    SystemChrome.setSystemUIOverlayStyle(overlay);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlay,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Purple header
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Scan or upload images for analysis',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.black,
                        size: 28,
                      ),
                      onSelected: (value) {
                        setState(() {
                          _currentPage = value;
                        });
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'home', child: Text('Home')),
                        const PopupMenuItem(
                          value: 'history',
                          child: Text('History'),
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      // Image card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Container(
                              height: 220,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Stack(
                                children: [
                                  _image != null
                                      ? Image.file(_image!, fit: BoxFit.cover)
                                      : Container(
                                          color: Colors.white,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.image_outlined,
                                                color: purple,
                                                size: 58,
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'No image selected',
                                                style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Choose camera or gallery below',
                                                style: TextStyle(
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                  if (_image != null)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _image = null;
                                            _probabilities.clear();
                                          });
                                        },
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Buttons row
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _pickImage(ImageSource.camera),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: topColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Camera',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: topColor,
                                side: BorderSide(color: topColor, width: 2),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(
                                Icons.photo,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Gallery',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // How to use box
                      Container(
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('• Tap Camera to take a new photo'),
                                SizedBox(height: 6),
                                Text(
                                  '• Tap Gallery to choose from your photos',
                                ),
                                SizedBox(height: 6),
                                Text(
                                  '• Ensure the subject is well-lit and in focus',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // classification progress indicator only
                      if (_isClassifying)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        )
                      else if (_probabilities.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Prediction
                              Text(
                                'Top Prediction',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Builder(
                                builder: (context) {
                                  // pair labels with probabilities and sort descending
                                  final pairs = List.generate(
                                    _classificationService.labels.length,
                                    (i) => MapEntry(
                                      _classificationService.labels[i],
                                      _probabilities[i],
                                    ),
                                  );
                                  pairs.sort(
                                    (a, b) => b.value.compareTo(a.value),
                                  );

                                  final topLabel = pairs[0].key;
                                  final topProb = pairs[0].value;
                                  final topDescription =
                                      descriptions[topLabel] ??
                                      'No description available.';

                                  final topColor =
                                      labelColors[topLabel] ??
                                      Colors.deepPurple;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            // colored label text
                                            Expanded(
                                              child: Text(
                                                topLabel,
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),

                                            // percentage pill
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: topColor.withOpacity(
                                                  0.95,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${(topProb * 100).toStringAsFixed(0)}%',
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: topProb,
                                            minHeight: 18,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  topColor,
                                                ),
                                            backgroundColor: topColor
                                                .withOpacity(0.12),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          topDescription,
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              // All Predictions
                              Text(
                                'All Predictions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Builder(
                                builder: (context) {
                                  // pair labels with probabilities and sort descending
                                  final pairs = List.generate(
                                    _classificationService.labels.length,
                                    (i) => MapEntry(
                                      _classificationService.labels[i],
                                      _probabilities[i],
                                    ),
                                  );
                                  pairs.sort(
                                    (a, b) => b.value.compareTo(a.value),
                                  );

                                  return Column(
                                    children: List.generate(pairs.length - 1, (
                                      index,
                                    ) {
                                      final i = index + 1;
                                      final label = pairs[i].key;
                                      final prob = pairs[i].value;
                                      final color =
                                          labelColors[label] ??
                                          Colors.deepPurple;

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                // colored label text
                                                Expanded(
                                                  child: Text(
                                                    label,
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),

                                                // percentage pill
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: color.withOpacity(
                                                      0.95,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '${(prob * 100).toStringAsFixed(0)}%',
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: LinearProgressIndicator(
                                                value: prob,
                                                minHeight: 18,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(color),
                                                backgroundColor: color
                                                    .withOpacity(0.12),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  );
                                },
                              ),
                            ],
                          ),
                        )
                      else
                        const SizedBox(),
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
}
