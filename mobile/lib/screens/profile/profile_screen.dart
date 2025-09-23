import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/app_routes.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/blog_controller.dart';
import '../../controllers/user_controller.dart';
import '../../widgets/glass_blog_card.dart';
import '../../widgets/glass_ui.dart';
// removed unused legacy loading_widget import – glass cards handle loading states

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final auth = Get.find<AuthController>();
  final blogs = Get.find<BlogController>();
  final users = Get.find<UserController>();

  late TabController tabs;

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prime();
      final args = Get.arguments as Map<String,dynamic>?;
      if(args!=null && args['initialTab']!=null){
        tabs.animateTo(args['initialTab']);
      }
    });
  }

  Future<void> _prime() async {
    await users.fetchUserProfile();
    await blogs.fetchMyBlogs();
    await users.fetchBookmarkedBlogs();
    await users.fetchUserStats();
  }

  @override
  void dispose(){
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx((){
      final user = auth.currentUser.value;
      if(user==null){
  return GlassScaffold(child: Center(child: Text('Please login', style: TextStyle(color: Colors.white.withValues(alpha: .8)))));
      }
      return GlassScaffold(
        foreground: [
          Positioned(
            right: 18, top: 44,
            child: _menuButton(),
          )
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            _header(user),
            const SizedBox(height: 14),
            _segmentBar(),
            const SizedBox(height: 10),
            Expanded(child: TabBarView(
              controller: tabs,
              children: [
                _myBlogs(),
                _bookmarks(),
                _stats(),
              ],
            ))
          ],
        ),
      );
    });
  }

  Widget _header(user){
    return Glass.surface(
      padding: const EdgeInsets.fromLTRB(20,22,20,20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Stack(children:[
            _avatar(user),
            Positioned(
              bottom:0,right:0,
              child: GestureDetector(
                onTap: _pickFrom,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .85),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .25), blurRadius: 8)],
                  ),
                  child: const Icon(Icons.camera_alt, size:16, color: Color(0xFF6366F1)),
                ),
              ),
            )
          ]),
          const SizedBox(width: 22),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Text(user.name, style: const TextStyle(color: Colors.white,fontSize:22,fontWeight: FontWeight.w700, letterSpacing: .2)),
              const SizedBox(height:4),
              Text(user.email, style: const TextStyle(color: Colors.white70,fontSize:13,fontWeight: FontWeight.w400)),
              const SizedBox(height:10),
              if(user.bio!=null && user.bio!.trim().isNotEmpty)
                Text(user.bio!, maxLines:3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60,fontSize:12.5,height:1.25)),
              const SizedBox(height:16),
              _quickStats(),
            ],
          ))
        ],
      ),
    );
  }

  Widget _avatar(user){
    return Container(
      width:90, height:90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
  border: Border.all(color: Colors.white.withValues(alpha: .35), width:1.4),
        gradient: const LinearGradient(colors:[Color(0xFF7F5AF0), Color(0xFF6344C6)])
      ),
      child: ClipOval(
        child: user.avatar!=null
          ? CachedNetworkImage(imageUrl: user.avatar!, fit: BoxFit.cover)
          : Center(child: Text((user.name.isNotEmpty ? user.name.substring(0, user.name.length >=2 ? 2 : 1) : '?').toUpperCase(), style: const TextStyle(color: Colors.white,fontSize:26,fontWeight: FontWeight.w700))),
      ),
    );
  }

  Widget _quickStats(){
    final s = users.userStats.value;
    return Row(children:[
      _miniStat('Blogs', (s?.totalBlogs ?? blogs.myBlogs.length).toString()),
      _miniStat('Likes', (s?.totalLikes ?? 0).toString()),
      _miniStat('Bookmarks', (s?.bookmarksCount ?? users.bookmarkedBlogs.length).toString()),
    ]);
  }

  Widget _miniStat(String label, String value){
    return Expanded(child: Container(
      margin: const EdgeInsets.only(right:10),
      padding: const EdgeInsets.symmetric(vertical:10, horizontal:12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
  color: Colors.white.withValues(alpha: .10),
  border: Border.all(color: Colors.white.withValues(alpha: .22)),
      ),
      child: Column(children:[
        Text(value, style: const TextStyle(color: Colors.white,fontSize:16,fontWeight: FontWeight.w600)),
        const SizedBox(height:4),
        Text(label, style: const TextStyle(color: Colors.white54,fontSize:10,fontWeight: FontWeight.w500, letterSpacing: .4)),
      ]),
    ));
  }

  Widget _segmentBar(){
    return Glass.surface(
      padding: const EdgeInsets.symmetric(vertical:6, horizontal:10),
      child: TabBar(
        controller: tabs,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(colors:[Color(0xFF6366F1), Color(0xFF8B5CF6)]),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(fontSize:12.5,fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: 'My Blogs (${blogs.myBlogs.length})'),
          Tab(text: 'Bookmarks (${users.bookmarkedBlogs.length})'),
          const Tab(text: 'Stats'),
        ],
      ),
    );
  }

  Widget _myBlogs(){
    return Obx((){
      if(blogs.isLoading.value){
        return const Center(child: CircularProgressIndicator());
      }
      if(blogs.myBlogs.isEmpty){
        return _empty('No blogs yet','Create your first story');
      }
      return RefreshIndicator(
        onRefresh: () => blogs.fetchMyBlogs(),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(4,6,4,90),
          itemCount: blogs.myBlogs.length,
          itemBuilder: (_,i){
            final b = blogs.myBlogs[i];
            return GlassBlogCard(
              blog: b,
              onTap: ()=> Get.toNamed(AppRoutes.blogDetail, arguments: b),
              onLike: ()=> blogs.likeBlog(b.id),
              onBookmark: ()=> blogs.bookmarkBlog(b.id),
            );
          },
        ),
      );
    });
  }

  Widget _bookmarks(){
    return Obx((){
      if(users.isLoading.value){
        return const Center(child: CircularProgressIndicator());
      }
      if(users.bookmarkedBlogs.isEmpty){
        return _empty('No bookmarks','Save blogs to read later');
      }
      return RefreshIndicator(
        onRefresh: () => users.fetchBookmarkedBlogs(),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(4,6,4,90),
          itemCount: users.bookmarkedBlogs.length,
          itemBuilder: (_,i){
            final b = users.bookmarkedBlogs[i];
            return GlassBlogCard(
              blog: b,
              onTap: ()=> Get.toNamed(AppRoutes.blogDetail, arguments: b),
              onLike: ()=> blogs.likeBlog(b.id),
              onBookmark: ()=> blogs.bookmarkBlog(b.id),
            );
          },
        ),
      );
    });
  }

  Widget _stats(){
    return Obx((){
      final s = users.userStats.value;
      final user = auth.currentUser.value!;
      return ListView(
        padding: const EdgeInsets.fromLTRB(4,6,4,120),
        children:[
          Row(children:[
            Expanded(child: _statCard('Total Blogs', (s?.totalBlogs ?? blogs.myBlogs.length).toString(), Icons.notes, const Color(0xFF6366F1))),
            const SizedBox(width:14),
            Expanded(child: _statCard('Published', (s?.publishedBlogs ?? 0).toString(), Icons.outbox, Colors.tealAccent.shade400)),
          ]),
          const SizedBox(height:14),
          Row(children:[
            Expanded(child: _statCard('Likes', (s?.totalLikes ?? 0).toString(), Icons.favorite, Colors.pinkAccent)),
            const SizedBox(width:14),
            Expanded(child: _statCard('Bookmarks', (s?.bookmarksCount ?? users.bookmarkedBlogs.length).toString(), Icons.bookmark, Colors.amberAccent)),
          ]),
          const SizedBox(height:14),
            _statCard('Comments', (s?.totalComments ?? 0).toString(), Icons.comment, Colors.lightBlueAccent),
          const SizedBox(height:20),
          Glass.surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                const Text('Account Information', style: TextStyle(color: Colors.white,fontSize:16,fontWeight: FontWeight.w700)),
                const SizedBox(height:14),
                _info('Member Since', _fmtDate(s?.joinedDate ?? user.createdAt)),
                _info('Recent Activity', '${s?.recentActivity ?? 0} blogs this month'),
                _info('Account Type', 'Free'),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _empty(String title, String subtitle){
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,children:[
      Icon(Icons.inbox_outlined, size:60, color: Colors.white24),
      const SizedBox(height:14),
      Text(title, style: const TextStyle(color: Colors.white70,fontSize:18,fontWeight: FontWeight.w600)),
      const SizedBox(height:6),
      Text(subtitle, style: const TextStyle(color: Colors.white54,fontSize:12)),
    ]));
  }

  Widget _statCard(String label, String value, IconData icon, Color color){
    return Glass.surface(
      padding: const EdgeInsets.fromLTRB(16,18,16,16),
      child: Column(children:[
        Icon(icon, size:30, color: color),
        const SizedBox(height:10),
        Text(value, style: const TextStyle(color: Colors.white,fontSize:20,fontWeight: FontWeight.w700)),
        const SizedBox(height:4),
        Text(label, style: const TextStyle(color: Colors.white60,fontSize:11,fontWeight: FontWeight.w500, letterSpacing: .4)),
      ]),
    );
  }

  Widget _info(String label, String value){
    return Padding(
      padding: const EdgeInsets.only(bottom:10),
      child: Row(children:[
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white54,fontSize:12))),
        Text(value, style: const TextStyle(color: Colors.white,fontSize:12.5,fontWeight: FontWeight.w600)),
      ]),
    );
  }

  String _fmtDate(DateTime d)=> '${d.day}/${d.month}/${d.year}';

  void _pickFrom() async {
    try{
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxHeight: 1024, maxWidth: 1024, imageQuality: 85);
      if(image!=null){
        final res = await users.uploadAvatar(image.path);
        if(res!=null){
          await users.fetchUserProfile();
          Get.snackbar('Updated','Profile photo changed', snackPosition: SnackPosition.BOTTOM);
        }
      }
    }catch(e){
      Get.snackbar('Error','Failed to update: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Widget _menuButton(){
    return PopupMenuButton<String>(
  color: Colors.white.withValues(alpha: .92),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onSelected: (v){
        if(v=='edit'){
          Get.toNamed(AppRoutes.editProfile);
        } else if(v=='logout'){
          _logoutDialog();
        }
      },
      itemBuilder: (_)=>[
        const PopupMenuItem(value:'edit', child: Row(children:[Icon(Icons.edit, size:18), SizedBox(width:8), Text('Edit Profile')])),
        const PopupMenuItem(value:'logout', child: Row(children:[Icon(Icons.logout, size:18), SizedBox(width:8), Text('Logout')])),
      ],
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal:14, vertical:10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              border: Border.all(color: Colors.white.withValues(alpha: .28)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.more_vert, color: Colors.white70, size:22),
          ),
        ),
      ),
    );
  }

  void _logoutDialog(){
    Get.dialog(AlertDialog(
      title: const Text('Logout'),
      content: const Text('Are you sure you want to sign out?'),
      actions: [
        TextButton(onPressed: ()=>Get.back(), child: const Text('Cancel')),
        TextButton(onPressed: (){Get.back(); auth.logout();}, child: const Text('Logout')),
      ],
    ));
  }
}