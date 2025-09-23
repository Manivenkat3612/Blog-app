import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_theme.dart';
import '../../controllers/blog_controller.dart';
import '../../widgets/blog_card.dart';
import '../../widgets/loading_widget.dart';
import '../../constants/app_routes.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final BlogController _blogController = Get.find<BlogController>();
  final TextEditingController _searchController = TextEditingController();
  final RxList _searchResults = [].obs;
  final RxBool _isSearching = false.obs;
  final RxString _searchQuery = ''.obs;
  final RxBool _hasSearchText = false.obs;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      _searchResults.clear();
      return;
    }

    _isSearching.value = true;
    _searchQuery.value = query;

    try {
      // Filter blogs based on title, content, tags, or author name
      final results = _blogController.blogs.where((blog) {
        final searchLower = query.toLowerCase();
        return blog.title.toLowerCase().contains(searchLower) ||
            blog.content.toLowerCase().contains(searchLower) ||
            blog.tags.any((tag) => tag.toLowerCase().contains(searchLower)) ||
            blog.author.name.toLowerCase().contains(searchLower) ||
            blog.category.toLowerCase().contains(searchLower);
      }).toList();

      _searchResults.value = results;
    } catch (e) {
      Get.snackbar('Error', 'Failed to search: $e');
    } finally {
      _isSearching.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Search Blogs'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search blogs, tags, or authors...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(() => _hasSearchText.value
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchResults.clear();
                          _searchQuery.value = '';
                          _hasSearchText.value = false;
                        },
                      )
                    : const SizedBox.shrink()),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
              onChanged: (value) {
                _hasSearchText.value = value.isNotEmpty;
                _performSearch(value);
              },
              textInputAction: TextInputAction.search,
              onSubmitted: _performSearch,
            ),
          ),

          // Search Results
          Expanded(
            child: Obx(() {
              if (_isSearching.value) {
                return const LoadingWidget();
              }

              if (_searchQuery.value.isEmpty) {
                return _buildEmptyState();
              }

              if (_searchResults.isEmpty) {
                return _buildNoResultsState();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final blog = _searchResults[index];
                  return BlogCard(
                    blog: blog,
                    onTap: () => Get.toNamed(
                      AppRoutes.blogDetail,
                      arguments: blog.id,
                    ),
                    onLike: () => _blogController.likeBlog(blog.id),
                    onBookmark: () => _blogController.bookmarkBlog(blog.id),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            'Search for blogs',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find blogs by title, content, tags, or author',
            style: AppTextStyles.body2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildPopularTags(),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Obx(() => Text(
            'No blogs found for "${_searchQuery.value}"',
            style: AppTextStyles.body2,
            textAlign: TextAlign.center,
          )),
          const SizedBox(height: 16),
          Text(
            'Try searching with different keywords',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPopularTags() {
    // Get unique tags from all blogs
    final allTags = <String>{};
    for (final blog in _blogController.blogs) {
      allTags.addAll(blog.tags);
    }
    
    if (allTags.isEmpty) return const SizedBox.shrink();

    final popularTags = allTags.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular Tags',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: popularTags.map((tag) => GestureDetector(
            onTap: () {
              _searchController.text = tag;
              _performSearch(tag);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Text(
                '#$tag',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }
}