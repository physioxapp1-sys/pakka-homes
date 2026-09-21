import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SubcategoryScreen extends StatelessWidget {
  const SubcategoryScreen({
    super.key,
    required this.title,
    required this.imageFolder,
    required this.itemCount,
  });

  final String title;
  final String imageFolder;
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
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          final imagePath = 'assets/services/$imageFolder/${index + 1}.png';
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
