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
  bool _isMicOn = true;
  bool _isVideoOn = true;
  late String _channelName;

  final List<Map<String, dynamic>> _questions = [
    {'question': 'Which country is known for Jollof Rice?', 'options': ['Nigeria', 'Kenya', 'India', 'Brazil'], 'answer': 'Nigeria'},
    {'question': 'What is the capital of Uganda?', 'options': ['Nairobi', 'Kampala', 'Kigali', 'Abuja'], 'answer': 'Kampala'},
    {'question': 'Most official languages in the world?', 'options': ['India', 'South Africa', 'Zimbabwe', 'Nigeria'], 'answer': 'Zimbabwe'},
  ];

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
    _timer = 15;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timer > 0) {
        setState(() => _timer--);
      } else {
        _answerQuestion('');
      }
    });
  }

  void _answerQuestion(String selectedAnswer) {
    if (selectedAnswer == _questions[_currentQuestion]['answer']) {
      setState(() => _score++);
    }

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
          Positioned.fill(
            child: _remoteUid != null
                ? AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: _engine,
                      canvas: VideoCanvas(uid: _remoteUid),
                      connection: RtcConnection(channelId: _channelName),
                    ),
                  )
                : Center(child: Text('Waiting for ${widget.opponent['name']}...', style: const TextStyle(color: Colors.white))),
          ),
          Positioned(
            top: 60, right: 20,
            child: Container(
              width: 120, height: 160,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.electricBlue, width: 2)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: _localUserJoined
                    ? AgoraVideoView(controller: VideoViewController(rtcEngine: _engine, canvas: const VideoCanvas(uid: 0)))
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const Spacer(),
                if (!_gameOver) _buildGameCard(),
                if (_gameOver) _buildGameOverCard(),
                const Spacer(),
                _buildControls(),
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
          IconButton(icon: const Icon(Icons.close, color: AppTheme.textWhite), onPressed: () => Navigator.pop(context)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: AppTheme.neonPink, borderRadius: BorderRadius.circular(20)),
            child: Text('00:${_timer.toString().padLeft(2, '0')}', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildGameCard() {
    final question = _questions[_currentQuestion];
    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppTheme.surfaceDark.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(30), border: Border.all(color: AppTheme.textWhite.withValues(alpha: 0.1))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Question ${_currentQuestion + 1}/3', style: const TextStyle(color: AppTheme.electricBlue, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(question['question'], textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
            const SizedBox(height: 32),
            ...question['options'].map((opt) => _buildOption(opt)),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _answerQuestion(text),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceDark, foregroundColor: AppTheme.textWhite, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppTheme.textWhite.withValues(alpha: 0.1))), padding: const EdgeInsets.symmetric(vertical: 14)),
          child: Text(text),
        ),
      ),
    );
  }

  Widget _buildGameOverCard() {
    return ZoomIn(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: AppTheme.neonPink.withValues(alpha: 0.2), blurRadius: 40)]),
        child: Column(
          children: [
            const Text('Match Over! 🎮', style: TextStyle(color: AppTheme.neonPink, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Score: $_score/3', style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Discover')),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: () {
              setState(() => _isMicOn = !_isMicOn);
              _engine.muteLocalAudioStream(!_isMicOn);
            },
            backgroundColor: _isMicOn ? AppTheme.electricBlue : AppTheme.surfaceDark,
            child: Icon(_isMicOn ? Icons.mic : Icons.mic_off, color: AppTheme.textWhite),
          ),
          const SizedBox(width: 20),
          FloatingActionButton(
            onPressed: () {
              setState(() => _isVideoOn = !_isVideoOn);
              _engine.muteLocalVideoStream(!_isVideoOn);
            },
            backgroundColor: _isVideoOn ? AppTheme.neonPink : AppTheme.surfaceDark,
            child: Icon(_isVideoOn ? Icons.videocam : Icons.videocam_off, color: AppTheme.textWhite),
          ),
        ],
      ),
    );
  }
}
