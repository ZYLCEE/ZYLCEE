import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'constants/app_constants.dart';
import 'models/gourd_data.dart';
import 'services/classification_service.dart';
import 'services/image_picker_service.dart';
import 'widgets/image_display_widget.dart';
import 'widgets/action_buttons.dart';
import 'widgets/how_to_use_widget.dart';
import 'widgets/prediction_card.dart';
import 'widgets/related_images_widget.dart';
import 'pages/history_page.dart';
import 'pages/analytics_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gourd Scanner',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  File? _image;
  final ClassificationService _classificationService = ClassificationService();
  final ImagePickerService _imagePickerService = ImagePickerService();
  List<double> _probabilities = [];
  bool _isClassifying = false;

  late AnimationController _fadeController;

  final List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _classificationService.loadModel();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppConstants.primaryColor,
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
    final pickedFile = await _imagePickerService.pickImage(source);

    if (pickedFile == null) return;

    setState(() {
      _image = pickedFile;
      _probabilities.clear();
      _isClassifying = true;
    });

    await _classifyImage();
    _fadeController.forward(from: 0);
  }

  Future<void> _classifyImage() async {
    final probs = await _classificationService.classifyImage(_image!);
    final labels = _classificationService.labels;

    // Save to history
    final pairs = List.generate(
      labels.length,
      (i) => MapEntry(labels[i], probs[i]),
    );
    pairs.sort((a, b) => b.value.compareTo(a.value));
    final topLabel = pairs[0].key;
    final topProb = pairs[0].value;

    _history.add({
      'image': _image!.path,
      'label': topLabel,
      'probability': topProb,
      'allProbabilities': probs,
      'allLabels': labels,
      'timestamp': DateTime.now(),
    });

    setState(() {
      _probabilities = probs;
      _isClassifying = false;
    });
  }

  void _deleteHistoryItem(int index) {
    setState(() {
      _history.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine top color based on top prediction
    Color topColor = AppConstants.primaryColor;
    if (_probabilities.isNotEmpty) {
      final labels = _classificationService.labels;
      final pairs = List.generate(
        labels.length,
        (i) => MapEntry(labels[i], _probabilities[i]),
      );
      pairs.sort((a, b) => b.value.compareTo(a.value));
      final topLabel = pairs[0].key;
      topColor = GourdData.labelColors[topLabel] ?? AppConstants.primaryColor;
    }

    final headerColor = topColor.withOpacity(0.95);

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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.appTitle,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppConstants.appSubtitle,
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
                        if (value == 'history') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => HistoryPage(
                                history: _history,
                                hasCurrentImage: _image != null,
                                onDeleteItem: _deleteHistoryItem,
                              ),
                            ),
                          );
                        } else if (value == 'analytics') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AnalyticsPage(
                                history: _history,
                                hasCurrentImage: _image != null,
                              ),
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) => [
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
                      // Image display
                      ImageDisplayWidget(
                        image: _image,
                        onImageRemove: () {
                          setState(() {
                            _image = null;
                            _probabilities.clear();
                          });
                        },
                      ),

                      const SizedBox(height: 18),

                      // Action buttons
                      ActionButtons(
                        onCameraPressed: () => _pickImage(ImageSource.camera),
                        onGalleryPressed: () => _pickImage(ImageSource.gallery),
                        buttonColor: topColor,
                      ),

                      const SizedBox(height: 18),

                      // How to use
                      const HowToUseWidget(),

                      // Classification results
                      if (_isClassifying)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        )
                      else if (_probabilities.isNotEmpty)
                        _buildResults(),
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

  Widget _buildResults() {
    final labels = _classificationService.labels;
    final pairs = List.generate(
      labels.length,
      (i) => MapEntry(labels[i], _probabilities[i]),
    );
    pairs.sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Prediction
          const Text(
            'Top Prediction',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          PredictionCard(
            label: pairs[0].key,
            probability: pairs[0].value,
            description: GourdData.descriptions[pairs[0].key],
          ),
          RelatedImagesWidget(label: pairs[0].key),
          const SizedBox(height: 24),
          // All Predictions
          const Text(
            'All Predictions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: List.generate(pairs.length - 1, (index) {
              final i = index + 1;
              return PredictionCard(
                label: pairs[i].key,
                probability: pairs[i].value,
                showDescription: false,
              );
            }),
          ),
        ],
      ),
    );
  }
}
