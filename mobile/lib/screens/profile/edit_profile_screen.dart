import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/user_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/glass_ui.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>{
  final userController = Get.find<UserController>();
  final auth = Get.find<AuthController>();
  final _form = GlobalKey<FormState>();
  late TextEditingController name;
  late TextEditingController bio;
  bool saving = false;

  @override
  void initState(){
    super.initState();
    final u = auth.currentUser.value!;
    name = TextEditingController(text: u.name);
    bio = TextEditingController(text: u.bio ?? '');
  }

  @override
  void dispose(){
    name.dispose();
    bio.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try{
      final picker = ImagePicker();
      final XFile? f = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxHeight: 1024, maxWidth: 1024);
      if(f!=null){
        final res = await userController.uploadAvatar(f.path);
        if(res!=null){
          await userController.fetchUserProfile();
          Get.snackbar('Updated','Avatar changed', snackPosition: SnackPosition.BOTTOM);
          setState((){});
        }
      }
    }catch(e){
      Get.snackbar('Error','Failed: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _save() async {
    if(!_form.currentState!.validate()) return;
    setState(()=> saving = true);
  final success = await userController.updateProfile(name: name.text.trim(), bio: bio.text.trim());
    setState(()=> saving = false);
    if(success){
      await userController.fetchUserProfile();
      Get.back();
      Get.snackbar('Saved','Profile updated', snackPosition: SnackPosition.BOTTOM);
    } else {
      Get.snackbar('Error','Update failed', snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context){
    final u = auth.currentUser.value!;
    return GlassScaffold(
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22,20,22,40),
          children:[
            Row(children:[
              GestureDetector(
                onTap: _pickAvatar,
                child: Stack(children:[
                  Container(
                    width:90, height:90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: .35), width:1.4),
                      gradient: const LinearGradient(colors:[Color(0xFF7F5AF0), Color(0xFF6344C6)])
                    ),
                    child: ClipOval(
                      child: u.avatar!=null
                        ? Image.network(u.avatar!, fit: BoxFit.cover)
                        : Center(child: Text((u.name.isNotEmpty ? u.name.substring(0, u.name.length >=2 ? 2 : 1) : '?').toUpperCase(), style: const TextStyle(color: Colors.white,fontSize:26,fontWeight: FontWeight.w700))),
                    ),
                  ),
                  Positioned(
                    bottom:4, right:4,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: .85),
                        boxShadow:[BoxShadow(color: Colors.black.withValues(alpha: .25), blurRadius:6)],
                      ),
                      child: const Icon(Icons.edit, size:16, color: Color(0xFF6366F1)),
                    ),
                  )
                ]),
              ),
              const SizedBox(width:20),
              Expanded(child: Text('Edit Profile', style: const TextStyle(color: Colors.white,fontSize:24,fontWeight: FontWeight.w700))),
              IconButton(
                onPressed: saving? null : ()=> Get.back(),
                icon: const Icon(Icons.close, color: Colors.white70),
              )
            ]),
            const SizedBox(height:26),
            Glass.surface(
              padding: const EdgeInsets.fromLTRB(20,22,20,26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  const Text('Name', style: TextStyle(color: Colors.white70,fontSize:12,fontWeight: FontWeight.w600, letterSpacing: .5)),
                  const SizedBox(height:6),
                  Glass.frostedField(child: TextFormField(
                    controller: name,
                    style: const TextStyle(color: Colors.white,fontSize:14.5),
                    decoration: Glass.inputDec('Your display name', Icons.person_outline),
                    validator: (v)=> (v==null || v.trim().length<2)? 'Too short' : null,
                  )),
                  const SizedBox(height:20),
                  const Text('Bio', style: TextStyle(color: Colors.white70,fontSize:12,fontWeight: FontWeight.w600, letterSpacing: .5)),
                  const SizedBox(height:6),
                  Glass.frostedField(child: TextFormField(
                    controller: bio,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white,fontSize:14.5,height:1.3),
                    decoration: Glass.inputDec('Tell something about you', Icons.notes_outlined),
                  )),
                ],
              ),
            ),
            const SizedBox(height:30),
            Glass.gradientButton(label: saving? 'Saving...' : 'Save Changes', onTap: saving? null : _save, height:54),
          ],
        ),
      ),
    );
  }
}