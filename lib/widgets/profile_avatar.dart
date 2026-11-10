
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.profileData,
    this.radius = 56,
    super.key,
  });

  final Object? profileData;
  final double radius;

  Uint8List? _imageBytes() {
    final data = profileData;

    if (data is! Map) return null;

    final encodedImage = data['imageData'];

    if (encodedImage is! String) return null;

    try {
      return base64Decode(encodedImage);
    } on FormatException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageBytes = _imageBytes();
    final diameter = radius * 2;
    final cacheSize =
        (diameter * MediaQuery.devicePixelRatioOf(context)).round();

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF1F5DA8),
      child: imageBytes == null
          ? Icon(
              Icons.person_outline,
              color: Colors.white,
              size: radius * 1.14,
            )
          : ClipOval(
              child: Image.memory(
                imageBytes,
                width: diameter,
                height: diameter,
                cacheWidth: cacheSize,
                cacheHeight: cacheSize,
                alignment: Alignment.center,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: radius * 1.14,
                ),
              ),
            ),
    );
  }
}
