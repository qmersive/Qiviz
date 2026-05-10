import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qiviz/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final List<Map<String, dynamic>> _chats = [
    {
      'name': 'AI Matchmaker',
      'username': 'qiviz_ai',
      'lastMessage': 'Ready for a practice date? 🤖',
      'time': 'Now',
      'isAI': true,
      'unread': 1,
    },
    {
      'name': 'Sarah Johnson',
      'username': 'sarah_j',
      'lastMessage': 'That dare video was hilarious! 😂',
      'time': '2m ago',
      'isAI': false,
      'unread': 0,
    },
    {
      'name': 'Yuki Tanaka',
      'username': 'yuki_san',
      'lastMessage': 'Are you going to the JNU event?',
      'time': '1h ago',
      'isAI': false,
      'unread': 0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text('Messages', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.search, color: AppTheme.textWhite), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          _buildStories(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 20),
                itemCount: _chats.length,
                separatorBuilder: (context, index) => Divider(color: AppTheme.textWhite.withValues(alpha: 0.05), indent: 80),
                itemBuilder: (context, index) {
                  final chat = _chats[index];
                  return FadeInUp(
                    delay: Duration(milliseconds: index * 100),
                    child: ListTile(
                      onTap: () => context.push('/chat', extra: chat),
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: chat['isAI'] ? AppTheme.electricBlue : AppTheme.primaryPurple,
                            child: chat['isAI'] 
                                ? const Icon(Icons.smart_toy, color: AppTheme.textWhite)
                                : Text(chat['name'][0], style: const TextStyle(color: AppTheme.textWhite, fontSize: 20)),
                          ),
                          if (chat['isAI'])
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 12, height: 12,
                                decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: AppTheme.surfaceDark, width: 2)),
                              ),
                            ),
                        ],
                      ),
                      title: Text(chat['name'], style: GoogleFonts.outfit(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                      subtitle: Text(chat['lastMessage'], style: TextStyle(color: chat['unread'] > 0 ? AppTheme.textWhite : AppTheme.textGrey, fontWeight: chat['unread'] > 0 ? FontWeight.bold : FontWeight.normal), maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(chat['time'], style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                          const SizedBox(height: 4),
                          if (chat['unread'] > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: AppTheme.neonPink, borderRadius: BorderRadius.circular(10)),
                              child: Text(chat['unread'].toString(), style: const TextStyle(color: AppTheme.textWhite, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStories() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [AppTheme.neonPink, AppTheme.primaryPurple]),
                  ),
                  child: const CircleAvatar(radius: 25, backgroundColor: AppTheme.surfaceDark),
                ),
                const SizedBox(height: 4),
                const Text('User', style: TextStyle(color: AppTheme.textGrey, fontSize: 10)),
              ],
            ),
          );
        },
      ),
    );
  }
}
