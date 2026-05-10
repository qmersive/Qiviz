import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qiviz/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  File? _imageFile;
  bool _isUploading = false;
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _imageFile = File(image.path));
    }
  }

  Future<void> _uploadStory() async {
    if (_imageFile == null) return;
    setState(() => _isUploading = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      final fileName = '${user?.id}_${DateTime.now().millisecondsSinceEpoch}${p.extension(_imageFile!.path)}';
      final path = 'stories/$fileName';

      await supabase.storage.from('media').upload(path, _imageFile!);
      final imageUrl = supabase.storage.from('media').getPublicUrl(path);

      await supabase.from('stories').insert({
        'creator_id': user?.id,
        'image_url': imageUrl,
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Story posted! ✨')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post story: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_imageFile != null)
            Positioned.fill(child: Image.file(_imageFile!, fit: BoxFit.cover)),
          
          SafeArea(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                    if (_imageFile != null)
                      TextButton(onPressed: _isUploading ? null : _uploadStory, child: const Text('Post', style: TextStyle(color: AppTheme.electricBlue, fontWeight: FontWeight.bold))),
                  ],
                ),
                const Spacer(),
                if (_imageFile == null)
                  Center(
                    child: Column(
                      children: [
                        IconButton(icon: const Icon(Icons.camera_alt, size: 64, color: Colors.white), onPressed: _pickImage),
                        const SizedBox(height: 12),
                        const Text('Tap to choose a photo', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                const SizedBox(height: 50),
              ],
            ),
          ),
          if (_isUploading) const Center(child: CircularProgressIndicator(color: AppTheme.neonPink)),
        ],
      ),
    );
  }
}
