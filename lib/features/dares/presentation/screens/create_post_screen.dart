import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qiviz/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _videoFile;
  bool _isUploading = false;
  final _picker = ImagePicker();

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() => _videoFile = File(video.path));
    }
  }

  Future<void> _uploadPost() async {
    if (_videoFile == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a video and add a title!')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}${p.extension(_videoFile!.path)}';
      final path = 'dares/$fileName';

      // 1. Upload to Storage
      await supabase.storage.from('media').upload(path, _videoFile!);
      final videoUrl = supabase.storage.from('media').getPublicUrl(path);

      // 2. Insert into DB
      await supabase.from('dares').insert({
        'user_id': user?.id,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'video_url': videoUrl,
        'is_active': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post uploaded successfully! 🔥')));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text('Create Viral Dare', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickVideo,
              child: Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.3)),
                ),
                child: _videoFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.video_call, size: 64, color: AppTheme.electricBlue),
                          const SizedBox(height: 12),
                          Text('Upload Video', style: GoogleFonts.outfit(color: AppTheme.textGrey)),
                        ],
                      )
                    : const Center(child: Icon(Icons.check_circle, size: 64, color: Colors.green)),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Dare Title',
                hintStyle: const TextStyle(color: AppTheme.textGrey),
                filled: true,
                fillColor: AppTheme.surfaceDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Tell us more about this challenge...',
                hintStyle: const TextStyle(color: AppTheme.textGrey),
                filled: true,
                fillColor: AppTheme.surfaceDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonPink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Post to Viral Feed', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
