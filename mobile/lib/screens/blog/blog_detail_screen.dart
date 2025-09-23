import 'dart:ui';
import '../../utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/blog.dart';
import '../../controllers/blog_controller.dart';
import '../../controllers/comment_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/comment_widget.dart';
import '../../widgets/comment_input.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/glass_ui.dart';

class BlogDetailScreen extends StatefulWidget { const BlogDetailScreen({super.key}); @override State<BlogDetailScreen> createState()=> _BlogDetailScreenState(); }

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  final BlogController blogController = Get.find<BlogController>();
  late final CommentController commentController;
  final AuthController authController = Get.find<AuthController>();
  
  late String blogId;
  String? replyToCommentId;
  String? replyToName;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    Blog? passedBlog;
    if (args is String) {
      blogId = args;
    } else if (args is Blog) {
      passedBlog = args;
      blogId = args.id;
      blogController.selectedBlog.value = args; // immediate assignment
    } else {
      blogId = '';
      logDebug('BlogDetailScreen: Unexpected argument: $args');
    }

    // Obtain lazily registered CommentController
    commentController = Get.find<CommentController>();

    // If blog not passed directly try locate by id
    if (passedBlog == null) {
      _loadBlogDetails();
    }

    // Final safety: derive blogId from selectedBlog if still empty
    if (blogId.isEmpty && blogController.selectedBlog.value != null) {
      blogId = blogController.selectedBlog.value!.id;
    }

    if (blogId.isNotEmpty) {
      commentController.fetchComments(blogId);
    }
  }

  @override
  void dispose() {
    // Only clear comments, don't dispose the controller
    if (Get.isRegistered<CommentController>()) {
      try {
        final controller = Get.find<CommentController>();
        controller.clearComments();
      } catch (e) {
        logDebug('Error clearing comments: $e');
      }
    }
    super.dispose();
  }

  void _loadBlogDetails() {
    // Find blog from controller's list and set it to selectedBlog
    final foundBlog = blogController.blogs.firstWhereOrNull(
      (b) => b.id == blogId,
    );
    if (foundBlog != null) {
      blogController.selectedBlog.value = foundBlog;
    }
  }

  Future<void> _toggleLike() async {
    final currentBlog = blogController.selectedBlog.value;
    if (currentBlog == null) return;
    await blogController.likeBlog(currentBlog.id);
    // The controller now properly updates the selectedBlog observable
  }

  Future<void> _toggleBookmark() async {
    final currentBlog = blogController.selectedBlog.value;
    if (currentBlog == null) return;
    await blogController.bookmarkBlog(currentBlog.id);
    // The controller now properly updates the selectedBlog observable
  }

  void _sharePost() async {
    final currentBlog = blogController.selectedBlog.value;
    if (currentBlog == null) return;
    // In a real app, you would implement proper sharing
    Get.snackbar('Share', 'Sharing functionality would be implemented here');
  }

  void _cancelReply() {
    setState(() {
      replyToCommentId = null;
      replyToName = null;
    });
  }

  void _startReply(String commentId, String authorName) {
    setState(() {
      replyToCommentId = commentId;
      replyToName = authorName;
    });
  }

  @override Widget build(BuildContext context){
    return Obx(()=> _body());
  }

  Widget _body(){
    final currentBlog = blogController.selectedBlog.value; 
    if(currentBlog==null){ return const GlassScaffold(child: Center(child: LoadingWidget())); }
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom > 0;
    return GlassScaffold(
      safe:false,
      child: Stack(
        children:[
          _heroCover(currentBlog),
          Positioned.fill(child: _scrollContent(currentBlog, extraBottom: (authController.isLoggedIn.value ? 170.0 : 110.0) + media.viewInsets.bottom)),
          Positioned(top: media.padding.top + 14, left:18, right:18, child: _topBar()),
          Positioned(left:0, right:0, bottom:0, child: _commentInputBar(bottomInset: media.viewInsets.bottom)),
          if(!keyboard) // hide floating actions while typing to avoid overlap
            Positioned(bottom: authController.isLoggedIn.value ? 100 : 40, left:0, right:0, child: _floatingActionBar(currentBlog)),
        ],
      ),
    );
  }

  Widget _heroCover(Blog blog){
    return SizedBox(
      height: 420,
      child: Stack(children:[
        Positioned.fill(child: (blog.featuredImage!=null && blog.featuredImage!.trim().isNotEmpty && blog.featuredImage!.startsWith('http'))
          ? CachedNetworkImage(
              imageUrl: blog.featuredImage!,
              fit: BoxFit.cover,
              placeholder:(c,_)=> Container(color: Colors.white10),
              errorWidget:(c,_,__)=>(Container(color: Colors.white10, child: const Icon(Icons.broken_image,color: Colors.white30)))
            )
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors:[Color(0xFF394663), Color(0xFF1F2A38)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              )
            ),
        ),
  Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors:[Colors.black.withValues(alpha: .15), Colors.black.withValues(alpha: .55), Colors.black.withValues(alpha: .85)])))),
        Positioned(bottom:0,left:0,right:0, child: Padding(
          padding: const EdgeInsets.fromLTRB(24,0,24,30),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children:[
            _categoryBadge(blog.category),
            const SizedBox(height:18),
            Text(blog.title, style: const TextStyle(color: Colors.white, fontSize:32, fontWeight: FontWeight.w800, height:1.10, letterSpacing:-.8, shadows:[Shadow(color: Colors.black54, blurRadius:16, offset: Offset(0,4))])),
            const SizedBox(height:16),
            _authorMeta(blog),
          ]),
        ))
      ]),
    );
  }

  Widget _contentGlass(Blog blog){
    return Glass.surface(
      padding: const EdgeInsets.fromLTRB(26,30,26,34),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        if(blog.tags.isNotEmpty) Wrap(spacing:8, runSpacing:6, children: blog.tags.map((t)=> Container(
          padding: const EdgeInsets.symmetric(horizontal:12, vertical:6),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white.withValues(alpha: .08), border: Border.all(color: Colors.white.withValues(alpha: .22))),
          child: Text('#$t', style: const TextStyle(color: Colors.white70, fontSize:12, fontWeight: FontWeight.w500)),
        )).toList()),
        if(blog.tags.isNotEmpty) const SizedBox(height:22),
        SelectableText(blog.content, style: const TextStyle(color: Colors.white, height:1.45, fontSize:15.5, letterSpacing:.2)),
      ]),
    );
  }

  // Removed floating actions (could be reintroduced as overlay if needed)

  Widget _commentsGlass(){
    return Glass.surface(
      padding: const EdgeInsets.fromLTRB(24,26,24,18),
      child: Obx((){
        if(commentController.isLoading.value){ return const LoadingWidget(); }
        if(commentController.comments.isEmpty){
          return Column(children:[
            const Icon(Icons.comment_outlined, size:54, color: Colors.white30), const SizedBox(height:14),
            const Text('No comments yet', style: TextStyle(color: Colors.white70,fontWeight: FontWeight.w600)),
            if(!authController.isLoggedIn.value) ...[
              const SizedBox(height:8), const Text('Login to start the conversation', style: TextStyle(color: Colors.white54, fontSize:12))
            ]
          ]);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: commentController.comments.map((c)=> Padding(
            padding: const EdgeInsets.only(bottom:14),
            child: CommentWidget(
              comment: c,
              onReply: () => _startReply(c.id, c.author.name),
              onDelete: () => _showDeleteDialog(c.id),
            ),
          )).toList(),
        );
      }),
    );
  }

  void _showDeleteDialog(String commentId){
    Get.dialog(Center(child: Glass.surface(padding: const EdgeInsets.fromLTRB(26,30,26,20), radius:30, child: Column(mainAxisSize: MainAxisSize.min, children:[
      const Text('Delete Comment', style: TextStyle(color: Colors.white,fontSize:18,fontWeight: FontWeight.w700)), const SizedBox(height:14),
      const Text('Are you sure you want to remove this comment? This action cannot be undone.', style: TextStyle(color: Colors.white70,fontSize:13,height:1.35), textAlign: TextAlign.center),
      const SizedBox(height:26),
      Row(children:[
        Expanded(child: Glass.gradientButton(label:'Cancel', onTap: ()=>Get.back(), height:46)),
        const SizedBox(width:14),
        Expanded(child: GestureDetector(onTap: (){ Get.back(); commentController.deleteComment(commentId, blogId); }, child: Container(height:46, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors:[Color(0xFFFF5F6D), Color(0xFFFFC371)])), alignment: Alignment.center, child: const Text('Delete', style: TextStyle(color: Colors.white,fontWeight: FontWeight.w700))))),
      ])
    ]))));
  }

  String _formatDate(DateTime date){ final now = DateTime.now(); final diff = now.difference(date); if(diff.inDays>7){ return '${date.day}/${date.month}/${date.year}'; } if(diff.inDays>0){ return '${diff.inDays}d ago'; } if(diff.inHours>0){ return '${diff.inHours}h ago'; } return '${diff.inMinutes}m ago'; }

  Widget _authorMeta(Blog blog){
    return Row(children:[
  Container(width:48,height:48, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: .35), width:1.4)), child: ClipOval(child: blog.author.avatar!=null ? CachedNetworkImage(imageUrl: blog.author.avatar!, fit: BoxFit.cover) : Center(child: Text((blog.author.name.isNotEmpty? blog.author.name[0] : '?').toUpperCase(), style: const TextStyle(color: Colors.white,fontWeight: FontWeight.w700))))),
      const SizedBox(width:14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Text(blog.author.name, style: const TextStyle(color: Colors.white,fontWeight: FontWeight.w600, fontSize:15, letterSpacing:.2)),
        const SizedBox(height:2),
  Text(_formatDate(blog.createdAt), style: const TextStyle(color: Colors.white54,fontSize:12)),
      ])),
    ]);
  }

  Widget _categoryBadge(String c)=> Container(padding: const EdgeInsets.symmetric(horizontal:14, vertical:7), decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), color: Colors.white.withValues(alpha: .15), border: Border.all(color: Colors.white.withValues(alpha: .35))), child: Text(c.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize:11, fontWeight: FontWeight.w600, letterSpacing:.8)));

  Widget _scrollContent(Blog blog, {double extraBottom = 140}){
    return NotificationListener<OverscrollIndicatorNotification>(
      onNotification: (o){ o.disallowIndicator(); return true; },
      child: CustomScrollView(
        slivers:[
          SliverToBoxAdapter(child: SizedBox(height: 420)),
          SliverPadding(padding: const EdgeInsets.fromLTRB(22, 0,22, 22), sliver: SliverList(delegate: SliverChildListDelegate([
            _contentGlass(blog), const SizedBox(height:26),
            Text('Discussion', style: const TextStyle(color: Colors.white,fontSize:22,fontWeight: FontWeight.w700, letterSpacing:-.2)), const SizedBox(height:14),
            _commentsGlass(), SizedBox(height: extraBottom),
          ])))
        ],
      ),
    );
  }

  Widget _topBar(){
    return Row(children:[
      _circleButton(Icons.arrow_back_ios_new_rounded, ()=>Get.back()), const Spacer(), _circleButton(Icons.share_outlined, _sharePost),
    ]);
  }

  Widget _circleButton(IconData icon, VoidCallback onTap)=> GestureDetector(
    onTap:onTap,
  child: ClipOval(child: BackdropFilter(filter: ImageFilter.blur(sigmaX:10,sigmaY:10), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .20), border: Border.all(color: Colors.white.withValues(alpha: .30)), shape: BoxShape.circle), child: Icon(icon, color: Colors.white,size:20))))
  );

  Widget _commentInputBar({double bottomInset = 0}){
    if(!authController.isLoggedIn.value){ return const SizedBox.shrink(); }
    // Animate position above keyboard
    return AnimatedPadding(
      duration: const Duration(milliseconds:250),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18,0,18, 20),
        child: Glass.surface(
          radius: 26,
            padding: const EdgeInsets.fromLTRB(16,8,12,8),
            child: Column(mainAxisSize: MainAxisSize.min, children:[
              if(replyToCommentId!=null) Row(children:[
                Expanded(child: Text('Replying to $replyToName',
                  style: const TextStyle(color: Colors.white70,fontSize:12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )),
                GestureDetector(onTap: _cancelReply, child: const Icon(Icons.close, size:16,color: Colors.white54))
              ]),
              if(replyToCommentId!=null) const SizedBox(height:6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 170),
                child: CommentInput(
                  blogId: blogId,
                  parentId: replyToCommentId,
                  replyToName: replyToName,
                  onCancel: replyToCommentId!=null? _cancelReply : null,
                ),
              ),
            ]),
        ),
      ),
    );
  }

  Widget _iconAction({required IconData icon, required String label, required bool active, required VoidCallback onTap, Color? activeColor}){
    return GestureDetector(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal:14, vertical:10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.white.withValues(alpha: .10),
            border: Border.all(color: Colors.white.withValues(alpha: active? .55 : .22)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children:[
            Icon(icon, size:18, color: active? (activeColor ?? Colors.white) : Colors.white70),
            const SizedBox(width:6),
            Flexible(child: Text(label, maxLines:1, overflow: TextOverflow.ellipsis, style: TextStyle(color: active? Colors.white : Colors.white70, fontSize:12, fontWeight: FontWeight.w600)))
          ]),
        ),
      ),
    );
  }

  Widget _floatingActionBar(Blog blog){
    return Obx(()=> Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal:22),
        child: Glass.surface(
          radius: 30,
          padding: const EdgeInsets.symmetric(horizontal:12, vertical:10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children:[
              _iconAction(icon: blog.isLiked? Icons.favorite: Icons.favorite_border, label: blog.likesCount.toString(), active: blog.isLiked, onTap: _toggleLike, activeColor: Colors.pinkAccent),
              const SizedBox(width:10),
              _iconAction(icon: Icons.comment_outlined, label: commentController.comments.length.toString(), active:false, onTap: (){}),
              const SizedBox(width:10),
              _iconAction(icon: blog.isBookmarked? Icons.bookmark: Icons.bookmark_outline, label: 'Save', active: blog.isBookmarked, onTap: _toggleBookmark, activeColor: const Color(0xFF7B6CF6)),
              const SizedBox(width:10),
              GestureDetector(onTap: _sharePost, child: Container(padding: const EdgeInsets.symmetric(horizontal:18, vertical:10), decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: const LinearGradient(colors:[Color(0xFF6366F1), Color(0xFF8B5CF6)])), child: const Row(children:[Icon(Icons.share, size:18,color: Colors.white), SizedBox(width:6), Text('Share', style: TextStyle(color: Colors.white,fontWeight: FontWeight.w700, fontSize:12))])))
            ]),
          ),
        ),
      ),
    ));
  }

}