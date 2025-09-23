import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/blog_controller.dart';
import '../../widgets/glass_ui.dart';

class EditBlogScreen extends StatefulWidget { const EditBlogScreen({super.key}); @override State<EditBlogScreen> createState()=> _EditBlogScreenState(); }

class _EditBlogScreenState extends State<EditBlogScreen> with SingleTickerProviderStateMixin {
  final _blogController = Get.find<BlogController>();
  final _title = TextEditingController();
  final _excerpt = TextEditingController();
  final _contentText = TextEditingController();
  final _quill = QuillController.basic();
  final _form = GlobalKey<FormState>();
  final _tag = TextEditingController();
  final _picker = ImagePicker();
  File? _image; String _category = ''; final List<String> _tags = [];
  late AnimationController _anim; late Animation<double> _fade;

  @override void initState(){
    super.initState();
    final blogId = Get.arguments; // expecting blog id
    final existing = _blogController.blogs.firstWhereOrNull((b)=> b.id == blogId) ?? _blogController.selectedBlog.value;
    if(existing!=null){
      _title.text = existing.title;
      _excerpt.text = existing.excerpt ?? '';
      _contentText.text = existing.content;
      _quill.document.insert(0, existing.content);
      _tags.addAll(existing.tags);
      _category = existing.category;
      _blogController.selectedBlog.value = existing;
    }
    _anim = AnimationController(vsync:this, duration: const Duration(milliseconds:600));
    _fade = CurvedAnimation(parent:_anim, curve: Curves.easeOutCubic); _anim.forward();
  }

  @override void dispose(){ _anim.dispose(); _title.dispose(); _excerpt.dispose(); _contentText.dispose(); _quill.dispose(); _tag.dispose(); super.dispose(); }

  Future<void> _pickImage() async { final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality:80); if(img!=null){ setState(()=> _image = File(img.path)); } }

  void _addTag(){ final t = _tag.text.trim(); if(t.isNotEmpty && !_tags.contains(t)){ setState(()=> _tags.add(t)); } _tag.clear(); }
  void _removeTag(String t){ setState(()=> _tags.remove(t)); }

  Future<void> _save() async {
    if(!_form.currentState!.validate()) return;
    final blog = _blogController.selectedBlog.value; if(blog==null) return;
    try {
      final content = _quill.document.toPlainText().trim();
      final success = await _blogController.updateBlog(blog.id, {
        'title': _title.text.trim(),
        'excerpt': _excerpt.text.trim(),
        'content': content,
        'category': _category,
        'tags': _tags.join(','),
      });
      if(success){ Get.back(); Get.snackbar('Updated','Blog changes saved'); }
    } catch(e){ Get.snackbar('Error','Failed to update: $e'); }
  }

  @override Widget build(BuildContext context){
    return GlassScaffold(
      child: FadeTransition(
        opacity: _fade,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: Column(children:[
              _topBar(), const SizedBox(height:18), Expanded(child: _body()), const SizedBox(height:10), _footer(),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _topBar(){
    return Row(children:[
  GestureDetector(onTap: ()=>Get.back(), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white.withValues(alpha: .08), border: Border.all(color: Colors.white.withValues(alpha: .18))), child: const Icon(Icons.arrow_back_ios_new_rounded,color: Colors.white,size:18))),
      const SizedBox(width:16), const Text('Edit Article', style: TextStyle(color: Colors.white,fontSize:24,fontWeight: FontWeight.w800, letterSpacing:-.5)), const Spacer(),
      Obx(()=> Glass.gradientButton(label:'Save', onTap: _blogController.isLoading.value? null : _save, height:48, loading: _blogController.isLoading.value)),
    ]);
  }

  Widget _body(){
    return LayoutBuilder(builder:(c,con){ return Row(crossAxisAlignment: CrossAxisAlignment.start, children:[
      Expanded(flex:3, child: _editor()), const SizedBox(width:24), Expanded(flex:2, child: _meta()),
    ]);});
  }

  Widget _editor(){
    return Glass.surface(padding: const EdgeInsets.fromLTRB(28,30,28,34), child: Form(key:_form, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      TextFormField(controller:_title, style: const TextStyle(color: Colors.white,fontSize:30,fontWeight: FontWeight.w700, letterSpacing:-.8), decoration: const InputDecoration(border: InputBorder.none, hintText:'Title...', hintStyle: TextStyle(color: Colors.white38)), validator:(v)=> v==null||v.trim().length<5? 'Min 5 chars' : null),
      const SizedBox(height:8),
      TextFormField(controller:_excerpt, maxLines:2, style: const TextStyle(color: Colors.white70, fontSize:13.5), decoration: const InputDecoration(border: InputBorder.none, hintText:'Short excerpt (optional)', hintStyle: TextStyle(color: Colors.white30))),
      const SizedBox(height:24),
      Container(
  decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: .15)), color: Colors.white.withValues(alpha: .05)),
        child: Column(children:[ QuillSimpleToolbar(controller:_quill), Container(height:300, padding: const EdgeInsets.all(12), child: QuillEditor.basic(controller:_quill)), ]),
      ),
      const SizedBox(height:30),
      Row(children:[ Expanded(child: Glass.gradientButton(label:'Preview', onTap: ()=>Get.snackbar('Preview','Coming soon'), height:46)), const SizedBox(width:14), Expanded(child: Glass.gradientButton(label:'History', onTap: ()=>Get.snackbar('History','Versioning not implemented'), height:46)),])
    ]))));
  }

  Widget _meta(){
    return SingleChildScrollView(child: Column(children:[
      Glass.surface(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        const Text('Cover Image', style: TextStyle(color: Colors.white,fontWeight: FontWeight.w600, fontSize:16)), const SizedBox(height:14),
  GestureDetector(onTap:_pickImage, child: Container(height:160, decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: .20)), color: Colors.white.withValues(alpha: .05), image: _image!=null? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover): null), child: _image==null? Center(child: Column(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.add_a_photo_outlined,color: Colors.white54), SizedBox(height:6), Text('Change Image', style: TextStyle(color: Colors.white54,fontSize:12))])): null)),
      ])), const SizedBox(height:22),
      Glass.surface(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        const Text('Category', style: TextStyle(color: Colors.white,fontWeight: FontWeight.w600, fontSize:16)), const SizedBox(height:14),
  DropdownButtonFormField<String>(value:_category.isEmpty? null : _category, dropdownColor: const Color(0xFF22323f), style: const TextStyle(color: Colors.white), iconEnabledColor: Colors.white70, decoration: InputDecoration(filled:true, fillColor: Colors.white.withValues(alpha: .08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white24)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white24))), items: ['technology','health','lifestyle','travel','business','general'].map((c)=> DropdownMenuItem(value:c, child: Text(c.capitalize!))).toList(), onChanged:(v)=> setState(()=> _category=v??'')),
      ])), const SizedBox(height:22),
      Glass.surface(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        const Text('Tags', style: TextStyle(color: Colors.white,fontWeight: FontWeight.w600, fontSize:16)), const SizedBox(height:14),
  Row(children:[ Expanded(child: Glass.frostedField(child: TextField(controller:_tag, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(border: InputBorder.none, hintText:'Add tag', hintStyle: TextStyle(color: Colors.white38), contentPadding: EdgeInsets.symmetric(horizontal:14, vertical:14)), onSubmitted:(_)=>_addTag(),))), const SizedBox(width:10), GestureDetector(onTap:_addTag, child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors:[Color(0xFF6366F1), Color(0xFF8B5CF6)]), boxShadow:[BoxShadow(color: Color(0xFF6366F1).withValues(alpha: .4), blurRadius:16, offset: Offset(0,6))]), child: const Icon(Icons.add,color: Colors.white))) ]),
  if(_tags.isNotEmpty) ...[ const SizedBox(height:12), Wrap(spacing:8, runSpacing:6, children: _tags.map((t)=> GestureDetector(onTap: ()=>_removeTag(t), child: Container(padding: const EdgeInsets.symmetric(horizontal:12, vertical:6), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white.withValues(alpha: .10), border: Border.all(color: Colors.white.withValues(alpha: .22))), child: Row(mainAxisSize: MainAxisSize.min, children:[ Text('#$t', style: const TextStyle(color: Colors.white,fontSize:12)), const SizedBox(width:6), const Icon(Icons.close, size:14,color: Colors.white54)])))).toList()) ],
      ])),
    ]));
  }

  Widget _footer()=> Opacity(opacity:.6, child: Text('© ${DateTime.now().year} Blog Studio – Refined Editing', style: const TextStyle(color: Colors.white60,fontSize:11)));
}