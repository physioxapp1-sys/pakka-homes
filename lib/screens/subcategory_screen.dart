import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SubcategoryScreen extends StatelessWidget {
  const SubcategoryScreen({
    super.key,
    required this.title,
    required this.imagePathPrefix,
    required this.itemCount,
  });

  final String title;

  /// Base asset path for this category's images, e.g. 'assets/services/mason'.
  /// Images are expected at '$imagePathPrefix/1.png', '.../2.png', etc.
  final String imagePathPrefix;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(title),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.95,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          final imagePath = '$imagePathPrefix/${index + 1}.png';
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Material(
              color: Colors.white,
              child: InkWell(
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(imagePath, fit: BoxFit.contain),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
