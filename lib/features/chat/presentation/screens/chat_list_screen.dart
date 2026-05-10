import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qiviz/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  Future<void> _fetchChats() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      // For MVP, we fetch all onboarded users as potential chat partners
      final response = await _supabase
          .from('profiles')
          .select()
          .neq('id', currentUserId ?? '')
          .eq('is_onboarded', true);

      if (mounted) {
        setState(() {
          _chats = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text('Messages', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.search, color: AppTheme.electricBlue), onPressed: () {}),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.neonPink))
          : _chats.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _chats.length,
                  itemBuilder: (context, index) {
                    final chat = _chats[index];
                    return FadeInUp(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ListTile(
                          onTap: () => context.push('/chat', extra: chat),
                          contentPadding: const EdgeInsets.all(12),
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: AppTheme.primaryPurple,
                                backgroundImage: chat['profile_photo_url'] != null ? NetworkImage(chat['profile_photo_url']) : null,
                                child: chat['profile_photo_url'] == null ? Text(chat['name'][0], style: const TextStyle(color: Colors.white)) : null,
                              ),
                              if (chat['is_online'] == true)
                                Positioned(right: 0, bottom: 0, child: Container(width: 14, height: 14, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: AppTheme.darkBackground, width: 2)))),
                            ],
                          ),
                          title: Text(chat['name'], style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: const Text('Start a conversation...', style: TextStyle(color: AppTheme.textGrey)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textGrey),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 80, color: AppTheme.textGrey),
          const SizedBox(height: 16),
          const Text('No messages yet', style: TextStyle(color: AppTheme.textGrey, fontSize: 18)),
          const SizedBox(height: 8),
          Text('Connect with students to start chatting!', style: TextStyle(color: AppTheme.textGrey.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}
