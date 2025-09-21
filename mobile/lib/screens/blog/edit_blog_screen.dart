import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';

class EditBlogScreen extends StatelessWidget {
  const EditBlogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Blog'),
      ),
      body: const Center(
        child: Text(
          'Edit Blog Screen',
          style: AppTextStyles.h2,
        ),
      ),
    );
  }
}