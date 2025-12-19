import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onCameraPressed;
  final VoidCallback onGalleryPressed;
  final Color buttonColor;

  const ActionButtons({
    super.key,
    required this.onCameraPressed,
    required this.onGalleryPressed,
    required this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onCameraPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
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
            onPressed: onGalleryPressed,
            style: OutlinedButton.styleFrom(
              backgroundColor: buttonColor,
              side: BorderSide(color: buttonColor, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
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
    );
  }
}
