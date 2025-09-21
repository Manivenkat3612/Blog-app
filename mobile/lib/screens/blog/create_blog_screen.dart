import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../constants/app_theme.dart';
import '../../controllers/blog_controller.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class CreateBlogScreen extends StatefulWidget {
  const CreateBlogScreen({super.key});

  @override
  State<CreateBlogScreen> createState() => _CreateBlogScreenState();
}

class _CreateBlogScreenState extends State<CreateBlogScreen> {
  final BlogController _blogController = Get.find<BlogController>();
  final _titleController = TextEditingController();
  final _excerptController = TextEditingController();
  final _contentController = TextEditingController(); // For web content
  final QuillController _quillController = QuillController.basic();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  
  File? _featuredImage;
  String _selectedCategory = 'General';
  final List<String> _tags = [];
  final _tagController = TextEditingController();
  
  final List<String> _categories = [
    'Technology',
    'Health',
    'Lifestyle',
    'Travel',
    'Business',
    'General'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _excerptController.dispose();
    _contentController.dispose();
    _quillController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        if (kIsWeb) {
          // For web, we don't use File, just store the path/name
          setState(() {
            _featuredImage = null; // We'll handle web differently
          });
          Get.snackbar(
            'Info',
            'Image selected: ${image.name}',
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
          setState(() {
            _featuredImage = File(image.path);
          });
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _saveBlog() async {
    if (!_formKey.currentState!.validate()) return;

    String content;
    if (kIsWeb) {
      content = _contentController.text.trim();
    } else {
      // For mobile, get the plain text from Quill controller
      final plainText = _quillController.document.toPlainText().trim();
      content = plainText;
    }
    
    print('Content extracted: "$content" (length: ${content.length})'); // Debug log
    
    if (content.isEmpty) {
      Get.snackbar(
        'Error',
        'Blog content cannot be empty',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      Get.snackbar(
        'Error', 
        'Blog title cannot be empty',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      await _blogController.createNewBlog(
        title: _titleController.text.trim(),
        content: content,
        excerpt: _excerptController.text.trim(),
        category: _selectedCategory.toLowerCase(),
        tags: _tags,
        featuredImage: _featuredImage,
      );
      
      Get.back();
      Get.snackbar(
        'Success',
        'Blog created successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create blog: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Blog'),
        actions: [
          Obx(() => _blogController.isLoading.value
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _saveBlog,
                  child: const Text(
                    'Publish',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              CustomTextField(
                controller: _titleController,
                label: 'Blog Title',
                hintText: 'Enter your blog title...',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  if (value.trim().length < 5) {
                    return 'Title must be at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Excerpt Field
              CustomTextField(
                controller: _excerptController,
                label: 'Excerpt (Optional)',
                hintText: 'Brief description of your blog...',
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Featured Image Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Featured Image',
                            style: AppTextStyles.h3,
                          ),
                          TextButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image),
                            label: Text(_featuredImage == null 
                                ? 'Add Image' 
                                : 'Change Image'),
                          ),
                        ],
                      ),
                      if (_featuredImage != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _featuredImage!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Category',
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tags Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tags',
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _tagController,
                              decoration: const InputDecoration(
                                hintText: 'Add a tag...',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onSubmitted: (_) => _addTag(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _addTag,
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      if (_tags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _tags.map((tag) {
                            return Chip(
                              label: Text(tag),
                              onDeleted: () => _removeTag(tag),
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              labelStyle: const TextStyle(color: AppColors.primary),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Content Editor
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Content',
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: kIsWeb 
                          ? Container(
                              padding: const EdgeInsets.all(16),
                              child: TextField(
                                controller: _contentController,
                                maxLines: 15,
                                decoration: const InputDecoration(
                                  hintText: 'Write your blog content here...',
                                  border: InputBorder.none,
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                QuillSimpleToolbar(
                                  controller: _quillController,
                                ),
                                Container(
                                  height: 300,
                                  padding: const EdgeInsets.all(16),
                                  child: QuillEditor.basic(
                                    controller: _quillController,
                                  ),
                                ),
                              ],
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Draft Button
              CustomButton(
                text: 'Save as Draft',
                backgroundColor: Colors.grey.shade600,
                onPressed: () {
                  // TODO: Implement save as draft functionality
                  Get.snackbar(
                    'Info',
                    'Save as draft feature coming soon!',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
              const SizedBox(height: 80), // Extra space for floating action
            ],
          ),
        ),
      ),
    );
  }
}