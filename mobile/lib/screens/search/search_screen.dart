import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/blog_controller.dart';
import '../../constants/app_routes.dart';
import '../../widgets/glass_blog_card.dart';
import '../../widgets/glass_ui.dart';

class SearchScreen extends StatefulWidget { const SearchScreen({super.key}); @override State<SearchScreen> createState()=> _SearchScreenState(); }

class _SearchScreenState extends State<SearchScreen>{
  final blogs = Get.find<BlogController>();
  final q = TextEditingController();
  final RxString query = ''.obs;
  DateTime _lastSearch = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void dispose(){ q.dispose(); super.dispose(); }

  void _search(String text){
    query.value = text;
    if(text.trim().isEmpty){
      blogs.searchResults.clear();
      blogs.isSearching.value = false;
      return;
    }
    // debounce basic (300ms)
    final now = DateTime.now();
    _lastSearch = now;
    Future.delayed(const Duration(milliseconds:300), (){
      if(now != _lastSearch) return; // a newer keystroke happened
      blogs.searchBlogs(text.trim());
    });
  }

  @override
  Widget build(BuildContext context){
    return GlassScaffold(
      child: Column(
        children:[
          const SizedBox(height: 6),
          _bar(),
          const SizedBox(height: 10),
          Obx(()=> blogs.error.value.isNotEmpty && blogs.searchQuery.value.isNotEmpty ? _errorBanner(blogs.error.value) : const SizedBox.shrink()),
          Expanded(child: Obx((){
            final loading = blogs.isSearching.value && query.value.isNotEmpty;
            final list = query.value.isEmpty ? <dynamic>[] : blogs.searchResults;
            if(loading){ return const Center(child: CircularProgressIndicator()); }
            if(query.value.isEmpty){ return _empty(); }
            if(list.isEmpty){ return _noResults(); }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(6,4,6,110),
              itemCount: list.length,
              itemBuilder: (_,i){
                final b = list[i];
                return GlassBlogCard(
                  blog: b,
                  onTap: ()=> Get.toNamed(AppRoutes.blogDetail, arguments: b),
                  onLike: ()=> blogs.likeBlog(b.id),
                  onBookmark: ()=> blogs.bookmarkBlog(b.id),
                );
              },
            );
          }))
        ],
      ),
    );
  }

  Widget _errorBanner(String msg)=> Padding(
    padding: const EdgeInsets.fromLTRB(14,0,14,6),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal:14, vertical:10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.red.withValues(alpha: .08),
        border: Border.all(color: Colors.red.withValues(alpha: .25)),
      ),
      child: Row(children:[
        const Icon(Icons.error_outline, color: Colors.red, size:18),
        const SizedBox(width:8),
        Expanded(child: Text(msg, style: const TextStyle(color: Colors.red, fontSize:12))),
        GestureDetector(onTap: ()=> blogs.clearError(), child: const Icon(Icons.close, size:16, color: Colors.red))
      ]),
    ),
  );

  Widget _bar(){
    return Padding(
      padding: const EdgeInsets.fromLTRB(14,8,14,0),
      child: Glass.surface(
        padding: EdgeInsets.zero,
        tint: Colors.white,
        opacity: .80,
        border: const BorderSide(color: Color(0x22000000)),
        child: Row(children:[
          const SizedBox(width:10),
          const Icon(Icons.search, color: Colors.black54, size:20),
          const SizedBox(width:10),
          Expanded(child: TextField(
            controller: q,
            cursorColor: Colors.black,
            style: const TextStyle(color: Colors.black, fontSize:14.5, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Search blogs, tags, authors...',
              hintStyle: TextStyle(color: Colors.black54, fontSize:14,fontWeight: FontWeight.w400),
            ),
            onChanged: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: _search,
          )),
          Obx(()=> query.value.isNotEmpty
            ? GestureDetector(
                onTap: (){q.clear(); query.value=''; blogs.searchResults.clear(); blogs.isSearching.value=false;},
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: .06),
                    border: Border.all(color: Colors.black.withValues(alpha: .15)),
                  ),
                  child: const Icon(Icons.close, size:16, color: Colors.black54),
                ),
              )
            : const SizedBox(width:4)),
          const SizedBox(width:10),
        ]),
      ),
    );
  }

  Widget _empty(){
    return Center(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal:30),
      child: Column(mainAxisAlignment: MainAxisAlignment.center,children:[
        const Icon(Icons.search, size:66, color: Colors.black26),
        const SizedBox(height:18),
        const Text('Search Blogs', style: TextStyle(color: Colors.black87,fontSize:22,fontWeight: FontWeight.w700)),
        const SizedBox(height:8),
        Text('Find stories by title, tag, author or category', style: TextStyle(color: Colors.black54,fontSize:13), textAlign: TextAlign.center),
        const SizedBox(height:30),
        _popularTags(),
      ]),
    ));
  }

  Widget _noResults(){
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,children:[
      const Icon(Icons.search_off, size:64, color: Colors.black26),
      const SizedBox(height:18),
      const Text('No results', style: TextStyle(color: Colors.black87,fontSize:20,fontWeight: FontWeight.w600)),
      const SizedBox(height:8),
      Obx(()=> Text('Nothing found for "${query.value}"', style: const TextStyle(color: Colors.black54,fontSize:13))),
    ]));
  }

  Widget _popularTags(){
    final tags = <String>{};
    for(final b in blogs.blogs){ tags.addAll(b.tags); }
    if(tags.isEmpty) return const SizedBox.shrink();
    final list = tags.take(8).toList();
    return Wrap(spacing:8, runSpacing:8, children: list.map((t)=> GestureDetector(
      onTap: (){ q.text = t; _search(t); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal:12, vertical:7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black.withValues(alpha: .06),
          border: Border.all(color: Colors.black.withValues(alpha: .18)),
        ),
        child: Text('#$t', style: const TextStyle(color: Colors.black87,fontSize:12,fontWeight: FontWeight.w500)),
      ),
    )).toList());
  }
}