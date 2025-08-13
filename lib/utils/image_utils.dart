import 'package:flutter/material.dart';

class ImageDisplayUtils {
  static Widget buildNetworkImage({
    required String imageUrl,
    required double height,
    double? width,
    BoxFit fit = BoxFit.cover,
  }) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          fit: fit,
        ),
      ),
    );
  }
} 