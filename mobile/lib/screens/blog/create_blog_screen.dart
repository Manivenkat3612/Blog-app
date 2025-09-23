import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../controllers/blog_controller.dart';
import '../../widgets/glass_ui.dart';
// removed unused modern_app_routes import

class CreateBlogScreen extends StatefulWidget { const CreateBlogScreen({super.key}); @override State<CreateBlogScreen> createState() => _CreateBlogScreenState(); }

class _CreateBlogScreenState extends State<CreateBlogScreen> with SingleTickerProviderStateMixin {
  final _blogController = Get.find<BlogController>();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _excerptController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final _quillController = QuillController.basic();
  final _imagePicker = ImagePicker();

  File? _featuredImage; String _selectedCategory = 'Technology'; final List<String> _tags = []; 
  final List<String> _categories = ['Technology','Health','Lifestyle','Travel','Business','General'];

  late AnimationController _anim; late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    // Initialize animations that were previously missing (preventing LateInitializationError)
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    _anim.forward();
  }

  @override void dispose(){
    // Dispose animation & controllers
    if(mounted){
      _anim.dispose();
    }
    _titleController.dispose();
    _excerptController.dispose();
    _contentController.dispose();
    _quillController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async { try { final image = await _imagePicker.pickImage(source: ImageSource.gallery,imageQuality:80); if(image!=null && !kIsWeb){ setState(()=>_featuredImage=File(image.path)); } else if(image!=null){ Get.snackbar('Image','Selected: ${image.name}', snackPosition: SnackPosition.BOTTOM);} } catch(e){ Get.snackbar('Error','Failed to pick image: $e', snackPosition: SnackPosition.BOTTOM); } }

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

  Future<void> _saveBlog() async { if(!_formKey.currentState!.validate()) return; final content = kIsWeb ? _contentController.text.trim() : _quillController.document.toPlainText().trim(); if(content.isEmpty){ Get.snackbar('Error','Content cannot be empty'); return;} try{ await _blogController.createNewBlog(title:_titleController.text.trim(), content: content, excerpt:_excerptController.text.trim(), category:_selectedCategory.toLowerCase(), tags:_tags, featuredImage:_featuredImage); Get.back(); Get.snackbar('Success','Blog published'); } catch(e){ Get.snackbar('Error','Failed: $e'); } }

  @override Widget build(BuildContext context){
    return GlassScaffold(
      child: FadeTransition(
        opacity: _fade,
        child: LayoutBuilder(
          builder:(ctx,con){
            final isNarrow = con.maxWidth < 760;
            final content = ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: isNarrow
                ? _mobileBody()
                : Column(
                    children:[
                      _topBar(),
                      const SizedBox(height:16),
                      Expanded(child: _editorBody()),
                      const SizedBox(height:12),
                      _footer(),
                    ],
                  ),
            );
            return Center(child: content);
          },
        ),
      ),
    );
  }

  // Mobile friendly scrollable body to avoid RenderFlex overflow & expose image picker early
  Widget _mobileBody(){
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16,12,16, bottomInset + 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            _topBar(),
            const SizedBox(height:18),
            // Inline cover image picker (so user immediately sees option)
            _coverImagePickerCard(),
            const SizedBox(height:22),
            _mainForm(),
            const SizedBox(height:26),
            _categoryCard(),
            const SizedBox(height:26),
            _tagsCard(),
            const SizedBox(height:28),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _topBar(){
    return Row(children:[
      GestureDetector(
        onTap: ()=>Get.back(),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.white.withValues(alpha: .08), border: Border.all(color: Colors.white.withValues(alpha: .18))),
          child: const Icon(Icons.arrow_back_ios_new_rounded,color: Colors.white,size:18),
        ),
      ),
      const SizedBox(width:14),
      const Text('New Article', style: TextStyle(color: Colors.white,fontSize:22,fontWeight: FontWeight.w700)),
      const Spacer(),
      Obx(()=>Glass.gradientButton(label: 'Publish', onTap: _blogController.isLoading.value? null : _saveBlog, height:46, loading: _blogController.isLoading.value)),
    ]);
  }

  Widget _editorBody(){
  return LayoutBuilder(builder:(c,con){
    // On narrow screens show meta panel (image, category, tags) BELOW the form in a scroll view
    if(con.maxWidth <= 750){
      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom:120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            _mainForm(),
            const SizedBox(height:22),
            _metaPanel(),
          ],
        ),
      );
    }
    // Wide layout: side-by-side
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children:[
      Expanded(flex:3, child: _mainForm()),
      const SizedBox(width:22),
      Expanded(flex:2, child: _metaPanel()),
    ]);
  });
  }

  Widget _mainForm(){
    return Glass.surface(
      padding: const EdgeInsets.fromLTRB(26,30,26,30),
      tint: Colors.white,
      opacity: .85,
      border: const BorderSide(color: Color(0x22000000)),
      child: Form(
      key:_formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        TextFormField(
          controller:_titleController,
          style: const TextStyle(color:Colors.black,fontSize:28,fontWeight: FontWeight.w700, letterSpacing:-.5),
          decoration: const InputDecoration(border: InputBorder.none, hintText: 'Title your masterpiece...', hintStyle: TextStyle(color: Colors.black38, fontSize:26,fontWeight: FontWeight.w600)),
          validator:(v)=> (v==null||v.trim().length<5)?'Min 5 chars':null,
        ),
        const SizedBox(height:10),
        TextFormField(
          controller:_excerptController,
          maxLines:2,
          style: const TextStyle(color:Colors.black87,fontSize:14,height:1.3),
          decoration: const InputDecoration(border: InputBorder.none, hintText:'Short teaser (optional)', hintStyle: TextStyle(color: Colors.black38)),
        ),
        const SizedBox(height:22),
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.black.withValues(alpha: .12)), color: Colors.white.withValues(alpha: .92)),
          child: kIsWeb
            ? TextField(
                controller:_contentController,
                maxLines:18,
                style: const TextStyle(color:Colors.black87,height:1.4),
                decoration: const InputDecoration(contentPadding: EdgeInsets.all(18), border: InputBorder.none, hintText:'Write your story...', hintStyle: TextStyle(color: Colors.black38)),
              )
            : Column(children:[
                Theme(
                  data: Theme.of(context).copyWith(
                    iconTheme: const IconThemeData(color: Colors.black87),
                    textTheme: Theme.of(context).textTheme.apply(bodyColor: Colors.black87, displayColor: Colors.black87),
                  ),
                  child: QuillSimpleToolbar(controller: _quillController),
                ),
                Container(
                  height:300,
                  padding: const EdgeInsets.all(12),
                  color: Colors.white.withValues(alpha: .0),
                  child: Theme(
                    data: Theme.of(context).copyWith(textTheme: Theme.of(context).textTheme.apply(bodyColor: Colors.black87, displayColor: Colors.black87)),
                    child: QuillEditor.basic(controller:_quillController),
                  ),
                ),
              ]),
        ),
        const SizedBox(height:28),
        Row(children:[
          Expanded(child: Glass.gradientButton(label:'Save Draft', onTap: ()=>Get.snackbar('Coming soon','Draft feature pending'))),
          const SizedBox(width:14),
          Expanded(child: Glass.gradientButton(label:'Preview', onTap: ()=>Get.snackbar('Preview','Coming soon'))),
        ])
      ]),
    ));
  }

  Widget _metaPanel(){
    return SingleChildScrollView(child: Column(children:[
      _coverImagePickerCard(),
      const SizedBox(height:22),
      _categoryCard(),
      const SizedBox(height:22),
      _tagsCard(),
    ]));
  }

  Widget _coverImagePickerCard(){
    return Glass.surface(padding: const EdgeInsets.all(20), tint: Colors.white, opacity: .85, border: const BorderSide(color: Color(0x22000000)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      const Text('Cover Image', style: TextStyle(color: Colors.black,fontWeight: FontWeight.w600, fontSize:16)),
      const SizedBox(height:14),
      GestureDetector(
        onTap:_pickImage,
        child: Container(
          height:170,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: .15)),
            color: Colors.white.withValues(alpha: .90),
            image: _featuredImage!=null ? DecorationImage(image: FileImage(_featuredImage!), fit: BoxFit.cover):null,
          ),
          child: _featuredImage==null ? Center(child: Column(mainAxisSize: MainAxisSize.min,children: const [Icon(Icons.add_a_photo_outlined,color: Colors.black54,size:30), SizedBox(height:8), Text('Add Image', style: TextStyle(color: Colors.black54))])):null,
        ),
      ),
    ]));
  }

  Widget _categoryCard(){
    return Glass.surface(padding: const EdgeInsets.all(20), tint: Colors.white, opacity: .85, border: const BorderSide(color: Color(0x22000000)), child: Column(crossAxisAlignment: CrossAxisAlignment.start,children:[
      const Text('Category', style: TextStyle(color: Colors.black,fontWeight: FontWeight.w600, fontSize:16)),
      const SizedBox(height:12),
      DropdownButtonFormField<String>(
        value:_selectedCategory,
        dropdownColor: Colors.white,
        iconEnabledColor: Colors.black54,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          filled: true, fillColor: Colors.black.withValues(alpha: .04),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.black.withValues(alpha: .25))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.black.withValues(alpha: .25))),
        ),
        items: _categories.map((c)=>DropdownMenuItem(value:c, child: Text(c))).toList(),
        onChanged:(v)=>setState(()=>_selectedCategory=v!),
      ),
    ]));
  }

  Widget _tagsCard(){
    return Glass.surface(padding: const EdgeInsets.all(20), tint: Colors.white, opacity: .85, border: const BorderSide(color: Color(0x22000000)), child: Column(crossAxisAlignment: CrossAxisAlignment.start,children:[
      const Text('Tags', style: TextStyle(color: Colors.black,fontWeight: FontWeight.w600, fontSize:16)),
      const SizedBox(height:12),
      Row(children:[
        Expanded(child: Glass.frostedField(child: TextField(
          controller:_tagController,
          style: const TextStyle(color: Colors.black87),
          decoration: const InputDecoration(border: InputBorder.none, hintText:'Add tag', hintStyle: TextStyle(color: Colors.black38), contentPadding: EdgeInsets.symmetric(horizontal:14, vertical:14)),
          onSubmitted:(_)=>_addTag(),
        ))),
        const SizedBox(width:10),
        GestureDetector(onTap:_addTag, child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors:[Color(0xFF6366F1),Color(0xFF8B5CF6)]), boxShadow:[BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: .4), blurRadius:16, offset: Offset(0,6))]), child: const Icon(Icons.add,color: Colors.white)))
      ]),
      if(_tags.isNotEmpty) ...[
        const SizedBox(height:12),
        Wrap(spacing:8, runSpacing:6, children: _tags.map((t)=>_tagChip(t)).toList())
      ]
    ]));
  }

  Widget _tagChip(String tag)=> GestureDetector(onTap: ()=>_removeTag(tag), child: Container(
    padding: const EdgeInsets.symmetric(horizontal:12, vertical:6),
  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.black.withValues(alpha: .05), border: Border.all(color: Colors.black.withValues(alpha: .18))),
    child: Row(mainAxisSize: MainAxisSize.min, children:[ Text('#$tag', style: const TextStyle(color: Colors.black87,fontSize:12)), const SizedBox(width:6), const Icon(Icons.close, size:14,color: Colors.black54)])
  ));

  Widget _footer()=> Opacity(opacity:.7, child: Text('© ${DateTime.now().year} Blog Studio – Writing Redefined', style: const TextStyle(color: Colors.black54, fontSize:12)));
}