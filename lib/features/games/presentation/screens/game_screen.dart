import 'package:flutter/material.dart';
import 'dart:async';
import 'package:qiviz/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

const String agoraAppId = "dfbaefd9c44c4a86ab40f459f667e89d";

class GameScreen extends StatefulWidget {
  final Map<String, dynamic> opponent;
  const GameScreen({super.key, required this.opponent});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _currentQuestion = 0;
  int _score = 0;
  bool _gameOver = false;
  int _timer = 15;
  Timer? _countdownTimer;

  // Agora State
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;
  late String _channelName;

  String _gameMode = 'trivia'; // 'trivia' or 'dare'
  
  final List<Map<String, dynamic>> _triviaQuestions = [
    {'q': 'What is the most popular street food in your country?', 'type': 'icebreaker'},
    {'q': 'Which festival is your absolute favorite?', 'type': 'culture'},
    {'q': 'What is one thing people get wrong about your culture?', 'type': 'deep'},
    {'q': 'If I visited your city, where is the first place you would take me?', 'type': 'travel'},
  ];

  final List<Map<String, dynamic>> _dareQuestions = [
    {'q': 'Sing the chorus of a popular song from your country!', 'type': 'dare'},
    {'q': 'Show us a traditional dance move!', 'type': 'dare'},
    {'q': 'Try to say "I love food" in my native language!', 'type': 'dare'},
    {'q': 'Do 10 pushups while counting in your language!', 'type': 'dare'},
  ];

  List<Map<String, dynamic>> get _questions => _gameMode == 'trivia' ? _triviaQuestions : _dareQuestions;

  @override
  void initState() {
    super.initState();
    _channelName = widget.opponent['channel'] ?? "qiviz_general";
    initAgora();
    _startTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  Future<void> initAgora() async {
    await [Permission.microphone, Permission.camera].request();
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: agoraAppId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() => _localUserJoined = true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          setState(() => _remoteUid = null);
        },
      ),
    );

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.enableVideo();
    await _engine.startPreview();

    await _engine.joinChannel(
      token: '',
      channelId: _channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  void _startTimer() {
    _timer = 20;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timer > 0) {
        setState(() => _timer--);
      } else {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestion < _questions.length - 1) {
      setState(() {
        _currentQuestion++;
        _startTimer();
      });
    } else {
      setState(() {
        _gameOver = true;
        _countdownTimer?.cancel();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Video (Remote)
          Positioned.fill(
            child: _remoteUid != null
                ? AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: _engine,
                      canvas: VideoCanvas(uid: _remoteUid),
                      connection: RtcConnection(channelId: _channelName),
                    ),
                  )
                : Container(
                    decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
                    child: Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 16),
                        Text('Waiting for ${widget.opponent['name']}...', style: const TextStyle(color: Colors.white)),
                      ],
                    )),
                  ),
          ),

          // Local Preview
          Positioned(
            top: 60, right: 20,
            child: Container(
              width: 110, height: 150,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.electricBlue, width: 2), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10)]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: _localUserJoined
                    ? AgoraVideoView(controller: VideoViewController(rtcEngine: _engine, canvas: const VideoCanvas(uid: 0)))
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),

          // Game UI
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const Spacer(),
                if (!_gameOver) _buildQuestionCard(),
                if (_gameOver) _buildGameOverCard(),
                const SizedBox(height: 40),
                _buildControls(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context)),
          GestureDetector(
            onTap: () {
              setState(() {
                _gameMode = _gameMode == 'trivia' ? 'dare' : 'trivia';
                _currentQuestion = 0;
                _startTimer();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(gradient: _gameMode == 'trivia' ? AppTheme.primaryGradient : AppTheme.viralGradient, borderRadius: BorderRadius.circular(20)),
              child: Text(_gameMode == 'trivia' ? 'Get to Know 🌍' : 'Truth or Dare 🔥', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    final q = _questions[_currentQuestion];
    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_outlined, color: AppTheme.neonPink, size: 20),
                const SizedBox(width: 8),
                Text('$_timer', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.neonPink)),
              ],
            ),
            const SizedBox(height: 16),
            Text(q['q'], textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _nextQuestion,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.electricBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Next Question'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverCard() {
    return ZoomIn(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(30), border: Border.all(color: AppTheme.acidGreen)),
        child: Column(
          children: [
            const Text('Match Ended! ✨', style: TextStyle(color: AppTheme.acidGreen, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('You both earned +50 XP for sharing your culture!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonPink), child: const Text('Back to Discover')),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _circleIcon(Icons.mic, Colors.white24),
        const SizedBox(width: 20),
        _circleIcon(Icons.videocam, Colors.white24),
        const SizedBox(width: 20),
        _circleIcon(Icons.emoji_emotions, Colors.white24),
      ],
    );
  }

  Widget _circleIcon(IconData icon, Color bg) {
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 28));
  }
}
