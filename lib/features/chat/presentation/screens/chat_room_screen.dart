import 'package:flutter/material.dart';
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
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {'text': 'Hey! I saw your dare video, so cool! 🔥', 'isMe': false},
  ];

  final List<String> _aiResponses = [
    "That's interesting! Tell me more about your interests. 😊",
    "I love your vibe! Ready to start a practice date? 🤖",
    "Did you know that cross-cultural friendships are the best? 🌍",
    "You should check out the latest viral dare, it matches your profile! 🔥",
    "I can help you break the ice with new matches. Just ask! 🧊",
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    final userText = _messageController.text.trim();
    
    setState(() {
      _messages.add({
        'text': userText,
        'isMe': true,
      });
    });
    _messageController.clear();
    
    // Smart AI Logic
    if (widget.chatData['username'] == 'qumersive_ai' || widget.chatData['name'].contains('AI')) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _messages.add({
              'text': _aiResponses[Random().nextInt(_aiResponses.length)],
              'isMe': false,
            });
          });
        }
      });
    }
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
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.electricBlue,
              backgroundImage: widget.chatData['profile_photo_url'] != null ? NetworkImage(widget.chatData['profile_photo_url']) : null,
              child: widget.chatData['profile_photo_url'] == null ? Text(widget.chatData['name'][0]) : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.chatData['name'], style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const Text('Online', style: TextStyle(fontSize: 12, color: AppTheme.acidGreen)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.videocam, color: AppTheme.neonPink), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return FadeInUp(
                  duration: const Duration(milliseconds: 300),
                  child: Align(
                    alignment: msg['isMe'] ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: msg['isMe'] ? AppTheme.primaryGradient : null,
                        color: msg['isMe'] ? null : AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(msg['text'], style: const TextStyle(color: Colors.white)),
                    ),
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
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: emojis.length,
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => _addEmoji(emojis[index]),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(emojis[index], style: const TextStyle(fontSize: 24)),
          ),
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: AppTheme.surfaceDark,
      child: SafeArea(
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.mic, color: AppTheme.textGrey), onPressed: () {}),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: AppTheme.darkBackground, borderRadius: BorderRadius.circular(30)),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Type a message...', hintStyle: TextStyle(color: Colors.grey), border: InputBorder.none),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(gradient: AppTheme.viralGradient, shape: BoxShape.circle),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
