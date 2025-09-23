import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../controllers/blog_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../constants/app_routes.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/glass_ui.dart';
import '../../widgets/glass_blog_card.dart';

class BlogListScreen extends StatefulWidget { const BlogListScreen({super.key}); @override State<BlogListScreen> createState()=> _BlogListScreenState(); }

class _BlogListScreenState extends State<BlogListScreen> with SingleTickerProviderStateMixin {
  final _blogController = Get.find<BlogController>();
  final _authController = Get.find<AuthController>();
  final _refreshController = RefreshController(initialRefresh: false);
  final _searchController = TextEditingController();
  late AnimationController _anim; late Animation<double> _fade;

  @override void initState(){
    super.initState();
    _blogController.fetchBlogs(refresh:true);
    _anim = AnimationController(vsync:this, duration: const Duration(milliseconds:800));
    _fade = CurvedAnimation(parent:_anim, curve: Curves.easeOutQuart);
    _anim.forward();
  }

  @override void dispose(){ _refreshController.dispose(); _searchController.dispose(); _anim.dispose(); super.dispose(); }

  @override Widget build(BuildContext context){
    return GlassScaffold(
      foreground: [
        Positioned(
          bottom: 30, right: 26,
          child: Glass.gradientButton(label:'Write', onTap: ()=>Get.toNamed(AppRoutes.createBlog), height:54),
        )
      ],
      child: FadeTransition(
        opacity: _fade,
        child: Column(
          children:[
            _topBar(),
            const SizedBox(height:16),
            _categoryStrip(),
            const SizedBox(height:14),
            Expanded(child: _blogStream()),
          ],
        ),
      ),
    );
  }

  Widget _topBar(){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal:22),
      child: Row(children:[
        const Text('Discover', style: TextStyle(color: Colors.white,fontSize:30,fontWeight: FontWeight.w800, letterSpacing:-1.2)),
        const Spacer(),
        _menuButton(),
      ]),
    );
  }

  Widget _menuButton(){
    return PopupMenuButton<String>(
      color: const Color(0xFF22323f),
      icon: const Icon(Icons.more_horiz,color: Colors.white),
      onSelected: _handleMenuSelection,
      itemBuilder: (c)=> [
        _menuItem('profile', Icons.person,'Profile'),
        _menuItem('my_blogs', Icons.article,'My Blogs'),
        _menuItem('bookmarks', Icons.bookmark,'Bookmarks'),
        _menuItem('logout', Icons.logout,'Logout'),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label)=> PopupMenuItem(
    value:value,
    child: Row(children:[Icon(icon,color: Colors.white70,size:18), const SizedBox(width:10), Text(label, style: const TextStyle(color: Colors.white70))]),
  );

  Widget _categoryStrip(){
    final pills = [
      _catPill('All',''),
      _catPill('Technology','technology'),
      _catPill('Lifestyle','lifestyle'),
      _catPill('Business','business'),
      _catPill('Health','health'),
      _catPill('Travel','travel'),
      _catPill('General','general'),
    ];
    return SizedBox(
      height: 104,
      child: Column(
        children:[
          _searchBar(),
          const SizedBox(height:12),
          Expanded(
            // The pills themselves each use Obx internally where needed; wrapping the whole
            // horizontal ListView in another Obx adds an unnecessary reactive scope and was
            // triggering the "improper use of a GetX" warning when no reactive vars changed here.
            child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal:18), children: pills),
          ),
        ],
      ),
    );
  }

  Widget _searchBar(){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal:18),
      child: Glass.frostedField(
        child: Row(children:[
          const SizedBox(width:10),
          const Icon(Icons.search, color: Colors.white54,size:20),
            const SizedBox(width:8),
          Expanded(child: TextField(
            controller:_searchController,
            cursorColor: Colors.white,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(border: InputBorder.none, hintText:'Search articles, tags, authors…', hintStyle: TextStyle(color: Colors.white54, fontWeight: FontWeight.w400)),
            onChanged: (q){ if(q.isEmpty){ _blogController.searchResults.clear(); } else { _blogController.searchBlogs(q); } setState((){}); },
          )),
          if(_searchController.text.isNotEmpty)
            GestureDetector(onTap: (){ _searchController.clear(); _blogController.searchResults.clear(); setState((){}); }, child: const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.close, size:18,color: Colors.white54)))
        ]),
      ),
    );
  }

  Widget _catPill(String label, String category){
    return Obx((){ final sel = _blogController.selectedCategory.value == category; return GestureDetector(
      onTap: ()=> _blogController.setCategory(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds:300),
        margin: const EdgeInsets.only(right:12),
        padding: const EdgeInsets.symmetric(horizontal:18, vertical:10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: sel ? const LinearGradient(colors:[Color(0xFF6366F1), Color(0xFF8B5CF6)]) : null,
          color: sel ? null : Colors.white.withValues(alpha: .08),
          border: Border.all(color: Colors.white.withValues(alpha: sel? .0 : .22)),
          boxShadow: sel ? [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: .45), blurRadius:18, offset: const Offset(0,6))] : null,
        ),
        child: Row(children:[
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: sel? .95 : .70), fontWeight: FontWeight.w600, letterSpacing:.3)),
          if(sel) ...[ const SizedBox(width:6), const Icon(Icons.circle, size:6, color: Colors.white) ]
        ]),
      ),
    );});
  }

  Widget _blogStream(){
    return Obx((){
      final searching = _blogController.isSearching.value && _searchController.text.isNotEmpty;
      if(searching){ return const Center(child: LoadingWidget()); }
      final list = _searchController.text.isNotEmpty ? _blogController.searchResults : _blogController.blogs;
      if(_blogController.error.value.isNotEmpty && list.isEmpty){ return _errorState(); }
      if(list.isEmpty){ return _emptyState(); }
      return SmartRefresher(
        controller: _refreshController,
        enablePullDown: true,
        enablePullUp: _searchController.text.isEmpty,
        onRefresh: _onRefresh,
        onLoading: _onLoading,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal:18, vertical: 6),
          itemCount: list.length,
          itemBuilder:(c,i){ final blog = list[i]; return GlassBlogCard(
            blog: blog,
            onTap: ()=> Get.toNamed(AppRoutes.blogDetail, arguments: blog),
            onLike: ()=> _blogController.likeBlog(blog.id),
            onBookmark: ()=> _blogController.bookmarkBlog(blog.id),
          );},
        ),
      );
    });
  }

  Widget _errorState(){
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[
      const Icon(Icons.cloud_off_outlined,color: Colors.white38,size:54), const SizedBox(height:18),
      Text(_blogController.error.value, style: const TextStyle(color: Colors.white70,fontWeight: FontWeight.w600)),
      const SizedBox(height:16),
      Glass.gradientButton(label:'Retry', onTap: (){ _blogController.clearError(); _blogController.fetchBlogs(refresh:true); }, height:46),
    ]));
  }

  Widget _emptyState(){
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[
      const Icon(Icons.menu_book_outlined,color: Colors.white30,size:64), const SizedBox(height:22),
      const Text('No articles yet', style: TextStyle(color: Colors.white,fontSize:20,fontWeight: FontWeight.w600)),
      const SizedBox(height:8),
      const Text('Start the knowledge flow – write the first one!', style: TextStyle(color: Colors.white60,fontSize:12)),
      const SizedBox(height:26),
  Glass.gradientButton(label:'Write Now', onTap: ()=>Get.toNamed(AppRoutes.createBlog), height:48),
    ]));
  }

  void _onRefresh() async { await _blogController.fetchBlogs(refresh:true); _refreshController.refreshCompleted(); }
  void _onLoading() async { if(_blogController.hasMorePages.value){ await _blogController.fetchBlogs(); _refreshController.loadComplete(); } else { _refreshController.loadNoData(); } }

  void _handleMenuSelection(String value){
    switch(value){
  case 'profile': Get.toNamed(AppRoutes.profile); break;
  case 'my_blogs': Get.toNamed(AppRoutes.profile, arguments:{'initialTab':0}); break;
  case 'bookmarks': Get.toNamed(AppRoutes.profile, arguments:{'initialTab':1}); break;
      case 'logout': _showLogoutDialog(); break;
    }
  }

  void _showLogoutDialog(){
    Get.dialog(AlertDialog(
      title: const Text('Logout'),
      content: const Text('Are you sure you want to logout?'),
      actions:[
        TextButton(onPressed: ()=>Get.back(), child: const Text('Cancel')),
  TextButton(onPressed: () async { Get.back(); await _authController.logout(); Get.offAllNamed(AppRoutes.login); }, child: const Text('Logout')),
      ],
    ));
  }
}