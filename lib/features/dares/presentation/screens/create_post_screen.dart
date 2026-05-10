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
  XFile? _pickedVideo;
  bool _isUploading = false;
  final _picker = ImagePicker();

  Future<void> _pickVideo() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Gallery...'), duration: Duration(seconds: 1)));
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() => _pickedVideo = video);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking video: $e')));
    }
  }

  Future<void> _uploadPost() async {
    if (_pickedVideo == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a video and add a title!')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      final fileName = '${user?.id}_${DateTime.now().millisecondsSinceEpoch}${p.extension(_pickedVideo!.name)}';
      final path = 'dares/$fileName';

      // Use bytes for web compatibility
      final bytes = await _pickedVideo!.readAsBytes();
      
      await supabase.storage.from('media').uploadBinary(
        path, 
        bytes,
        fileOptions: const FileOptions(contentType: 'video/mp4'),
      );
      
      final videoUrl = supabase.storage.from('media').getPublicUrl(path);

      await supabase.from('dares').insert({
        'creator_id': user?.id,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'video_url': videoUrl,
        'is_active': true,
        'end_time': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
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
            InkWell(
              onTap: _pickVideo,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.3)),
                ),
                child: _pickedVideo == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.video_call, size: 64, color: AppTheme.electricBlue),
                          const SizedBox(height: 12),
                          Text('Tap to Choose Video', style: GoogleFonts.outfit(color: AppTheme.textGrey)),
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
