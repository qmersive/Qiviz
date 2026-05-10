import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qiviz/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:math';

class ChatRoomScreen extends StatefulWidget {
  final Map<String, dynamic> chatData;
  const ChatRoomScreen({super.key, required this.chatData});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  late RealtimeChannel _channel;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _setupRealtime();
  }

  @override
  void dispose() {
    _channel.unsubscribe();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    try {
      final myId = _supabase.auth.currentUser?.id;
      final otherId = widget.chatData['id'];

      final response = await _supabase
          .from('messages')
          .select()
          .or('and(sender_id.eq.$myId,receiver_id.eq.$otherId),and(sender_id.eq.$otherId,receiver_id.eq.$myId)')
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupRealtime() {
    final myId = _supabase.auth.currentUser?.id;
    _channel = _supabase.channel('public:messages').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        final newMsg = payload.newRecord;
        if ((newMsg['sender_id'] == myId && newMsg['receiver_id'] == widget.chatData['id']) ||
            (newMsg['sender_id'] == widget.chatData['id'] && newMsg['receiver_id'] == myId)) {
          if (mounted) {
            setState(() => _messages.add(Map<String, dynamic>.from(newMsg)));
          }
        }
      },
    ).subscribe();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final text = _messageController.text.trim();
    _messageController.clear();

    try {
      final myId = _supabase.auth.currentUser?.id;
      await _supabase.from('messages').insert({
        'sender_id': myId,
        'receiver_id': widget.chatData['id'],
        'text': text,
      });

      // Simple AI logic for AI profile
      if (widget.chatData['name'].contains('AI') || widget.chatData['username'] == 'qumersive_ai') {
        Future.delayed(const Duration(seconds: 1), () {
          _sendAiResponse();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    }
  }

  void _sendAiResponse() async {
    final responses = ["That's interesting!", "I love your energy!", "Tell me more!", "Ready for a date?"];
    await _supabase.from('messages').insert({
      'sender_id': widget.chatData['id'],
      'receiver_id': _supabase.auth.currentUser?.id,
      'text': responses[Random().nextInt(responses.length)],
    });
  }

  void _addEmoji(String emoji) {
    _messageController.text += emoji;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.chatData['profile_photo_url'] != null ? NetworkImage(widget.chatData['profile_photo_url']) : null,
              child: widget.chatData['profile_photo_url'] == null ? Text(widget.chatData['name'][0]) : null,
            ),
            const SizedBox(width: 12),
            Text(widget.chatData['name'], style: GoogleFonts.outfit(fontSize: 18, color: Colors.white)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['sender_id'] == _supabase.auth.currentUser?.id;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: isMe ? AppTheme.primaryGradient : null,
                            color: isMe ? null : AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(msg['text'], style: const TextStyle(color: Colors.white)),
                        ),
                      );
                    },
                  ),
          ),
          _buildEmojiBar(),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildEmojiBar() {
    final emojis = ['🔥', '❤️', '😂', '🌍', '🤔', '🙌', '✨', '🤖'];
    return Container(
      height: 44,
      color: AppTheme.surfaceDark.withValues(alpha: 0.5),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: emojis.length,
        itemBuilder: (context, index) => IconButton(
          onPressed: () => _addEmoji(emojis[index]),
          icon: Text(emojis[index], style: const TextStyle(fontSize: 22)),
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.surfaceDark,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: const TextStyle(color: AppTheme.textGrey),
                  filled: true,
                  fillColor: AppTheme.darkBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.send, color: AppTheme.electricBlue),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
