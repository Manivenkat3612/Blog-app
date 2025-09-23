import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/blog.dart';
import 'glass_ui.dart';

class GlassBlogCard extends StatelessWidget {
  final Blog blog;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onBookmark;

  const GlassBlogCard({
    super.key,
    required this.blog,
    this.onTap,
    this.onLike,
    this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical:10),
      child: GestureDetector(
        onTap: onTap,
        child: Glass.surface(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cover(),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      blog.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                        letterSpacing: -.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if ((blog.excerpt ?? blog.content).isNotEmpty)
                      Text(
                        _excerptText(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13.5,
                          height: 1.35,
                        ),
                      ),
                    const SizedBox(height: 14),
                    if (blog.tags.isNotEmpty) _tagsRow(),
                    const SizedBox(height: 16),
                    _metaAndActions(),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    ));
  }

  Widget _cover() {
    final img = blog.featuredImage;
    return AspectRatio(
      aspectRatio: 16/9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (img != null)
            CachedNetworkImage(
              imageUrl: img,
              fit: BoxFit.cover,
              placeholder: (c,_)=> Container(color: Colors.white10),
              errorWidget: (c,_,__)=>(Container(color: Colors.white10, child: const Icon(Icons.broken_image,color: Colors.white38))),
            )
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors:[Color(0xFF394663), Color(0xFF1F2A38)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              ),
              child: const Center(
                child: Icon(Icons.image,size:42,color: Colors.white30),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors:[
                    Colors.black.withValues(alpha: .05),
                    Colors.black.withValues(alpha: .55),
                  ],
                )
              ),
            ),
          ),
          Positioned(
            right: 14,
            top: 14,
            child: _bookmarkButton(),
          ),
          Positioned(
            left: 16,
            bottom: 14,
            child: _categoryBadge(),
          ),
        ],
      ),
    );
  }

  Widget _bookmarkButton(){
    return GestureDetector(
        onTap: onBookmark,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX:8, sigmaY:8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .14),
                border: Border.all(color: Colors.white.withValues(alpha: .3)),
              ),
              child: Icon(blog.isBookmarked? Icons.bookmark: Icons.bookmark_outline, color: blog.isBookmarked? const Color(0xFF7B6CF6): Colors.white, size:20),
            ),
          ),
        ),
      );
  }

  Widget _categoryBadge(){
    return Container(
      padding: const EdgeInsets.symmetric(horizontal:12, vertical:6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white.withValues(alpha: .15),
        border: Border.all(color: Colors.white.withValues(alpha: .35)),
      ),
      child: Text(
        blog.category.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: .7),
      ),
    );
  }

  String _excerptText(){
    final base = blog.excerpt?.trim();
    if(base!=null && base.isNotEmpty) return base;
    final content = blog.content.trim();
    if(content.isEmpty) return '';
    if(content.length <= 180) return content;
    // Ensure safe end index
    final end = content.length >= 180 ? 180 : content.length;
    return content.substring(0,end).trim()+'…';
  }

  Widget _tagsRow(){
    return Wrap(
      spacing:8,
      runSpacing:6,
      children: blog.tags.take(4).map((t)=> Container(
        padding: const EdgeInsets.symmetric(horizontal:10, vertical:5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withValues(alpha: .08),
          border: Border.all(color: Colors.white.withValues(alpha: .22)),
        ),
        child: Text('#$t', style: const TextStyle(color: Colors.white70, fontSize:11, fontWeight: FontWeight.w500)),
      )).toList(),
    );
  }

  Widget _metaAndActions(){
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _authorAvatar(),
        const SizedBox(width:10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            Text(blog.author.name, style: const TextStyle(color: Colors.white,fontWeight: FontWeight.w600, fontSize:13, height:1.1)),
            Text(_formatDate(blog.createdAt), style: const TextStyle(color: Colors.white54,fontSize:11.5, height:1.2)),
          ],
        )),
        _iconButton(icon: blog.isLiked? Icons.favorite: Icons.favorite_border, color: blog.isLiked? Colors.pinkAccent : Colors.white70, label: blog.likesCount.toString(), onTap: onLike),
        const SizedBox(width:6),
        _iconStatic(icon: Icons.comment_outlined, color: Colors.white54, label: blog.commentsCount.toString()),
      ],
    );
  }

  Widget _authorAvatar(){
    return Container(
      width:40, height:40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: .35), width:1.2),
        gradient: const LinearGradient(colors:[Color(0xFF47566F), Color(0xFF2E3A49)])
      ),
      child: ClipOval(
        child: blog.author.avatar!=null
          ? CachedNetworkImage(imageUrl: blog.author.avatar!, fit: BoxFit.cover)
          : Center(child: Text((blog.author.name.isNotEmpty? blog.author.name[0] : '?').toUpperCase(), style: const TextStyle(color: Colors.white,fontWeight: FontWeight.w600)) ),
      ),
    );
  }

  Widget _iconButton({required IconData icon, required Color color, required String label, VoidCallback? onTap}){
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal:10, vertical:6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white.withValues(alpha: .10),
          border: Border.all(color: Colors.white.withValues(alpha: .22)),
        ),
        child: Row(children:[Icon(icon, size:17, color: color), const SizedBox(width:4), Text(label, style: const TextStyle(color: Colors.white70, fontSize:11, fontWeight: FontWeight.w500))]),
      ),
    );
  }

  Widget _iconStatic({required IconData icon, required Color color, required String label}){
    return Container(
      padding: const EdgeInsets.symmetric(horizontal:10, vertical:6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white.withValues(alpha: .06),
        border: Border.all(color: Colors.white.withValues(alpha: .18)),
      ),
      child: Row(children:[Icon(icon, size:17, color: color), const SizedBox(width:4), Text(label, style: const TextStyle(color: Colors.white60, fontSize:11, fontWeight: FontWeight.w500))]),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inMinutes}m ago';
    }
  }
}