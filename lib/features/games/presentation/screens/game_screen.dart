import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
  int _currentQuestionIndex = 0;
  bool _gameOver = false;
  int _timer = 15;
  Timer? _countdownTimer;
  List<dynamic> _apiQuestions = [];
  bool _isLoadingQuestions = true;

  // Agora State
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;
  late String _channelName;

  String _gameMode = 'trivia'; // 'trivia' or 'dare'
  bool _showCaptions = false;
  String _currentCaption = "";
  
  final List<String> _translatedCaptions = [
    "नमस्ते, आप कैसे हैं? (Hello, how are you?)",
    "मुझे आपकी संस्कृति बहुत पसंद है! (I really like your culture!)",
    "क्या आप मुझे इस व्यंजन के बारे में बता सकते हैं? (Can you tell me about this dish?)",
    "यह बहुत अच्छा खेल है! (This is a great game!)",
  ];

  @override
  void initState() {
    super.initState();
    _channelName = widget.opponent['channel'] ?? "qiviz_general";
    initAgora();
    _fetchTrivia();
    _startCaptionSimulation();
  }

  Future<void> _fetchTrivia() async {
    try {
      final response = await http.get(Uri.parse('https://opentdb.com/api.php?amount=10&type=boolean'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _apiQuestions = data['results'];
            _isLoadingQuestions = false;
            _startTimer();
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingQuestions = false);
    }
  }

  void _startCaptionSimulation() {
    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && _showCaptions) {
        setState(() {
          _currentCaption = _translatedCaptions[Random().nextInt(_translatedCaptions.length)];
        });
      }
    });
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
    if (_currentQuestionIndex < _apiQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
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
          // Remote Video
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
                    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
          ),

          // Local Preview
          Positioned(
            top: 60, right: 20,
            child: Container(
              width: 110, height: 150,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.electricBlue, width: 2)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: _localUserJoined ? AgoraVideoView(controller: VideoViewController(rtcEngine: _engine, canvas: const VideoCanvas(uid: 0))) : null,
              ),
            ),
          ),

          // Captions
          if (_showCaptions)
            Positioned(
              bottom: 140, left: 20, right: 20,
              child: FadeInUp(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.acidGreen.withValues(alpha: 0.3))),
                  child: Text(_currentCaption, textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppTheme.acidGreen, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),

          // UI
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const Spacer(),
                if (_isLoadingQuestions) const CircularProgressIndicator(color: AppTheme.neonPink),
                if (!_isLoadingQuestions && !_gameOver) _buildQuestionCard(),
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
                _currentQuestionIndex = 0;
                _startTimer();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(gradient: _gameMode == 'trivia' ? AppTheme.primaryGradient : AppTheme.viralGradient, borderRadius: BorderRadius.circular(20)),
              child: Text(_gameMode == 'trivia' ? 'Live Trivia 🌍' : 'Truth or Dare 🔥', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    final q = _apiQuestions[_currentQuestionIndex];
    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(30), border: Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.3))),
        child: Column(
          children: [
            Text('Question #${_currentQuestionIndex + 1}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
            const SizedBox(height: 12),
            Text(HtmlUnescape().convert(q['question']), textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _answerButton('TRUE', Colors.green),
                _answerButton('FALSE', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _answerButton(String label, Color color) {
    return ElevatedButton(
      onPressed: _nextQuestion,
      style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      child: Text(label),
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
            const Text('Great session! You both learned something new today.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonPink), child: const Text('Back to Home')),
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
        GestureDetector(onTap: () => setState(() => _showCaptions = !_showCaptions), child: _circleIcon(Icons.translate, _showCaptions ? AppTheme.electricBlue : Colors.white24)),
        const SizedBox(width: 20),
        _circleIcon(Icons.videocam, Colors.white24),
      ],
    );
  }

  Widget _circleIcon(IconData icon, Color bg) {
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 28));
  }
}

class HtmlUnescape {
  String convert(String text) {
    return text.replaceAll('&quot;', '"').replaceAll('&#039;', "'").replaceAll('&amp;', '&');
  }
}
