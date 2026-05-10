import 'package:flutter/material.dart';
import 'package:qiviz/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

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

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Which country is known for Jollof Rice?',
      'options': ['Nigeria', 'Kenya', 'India', 'Brazil'],
      'answer': 'Nigeria'
    },
    {
      'question': 'What is the capital of Uganda?',
      'options': ['Nairobi', 'Kampala', 'Kigali', 'Abuja'],
      'answer': 'Kampala'
    },
    {
      'question': 'Which country has the most official languages in the world?',
      'options': ['India', 'South Africa', 'Zimbabwe', 'Nigeria'],
      'answer': 'Zimbabwe'
    },
  ];

  void _answerQuestion(String selectedAnswer) {
    if (selectedAnswer == _questions[_currentQuestion]['answer']) {
      setState(() {
        _score++;
      });
    }

    if (_currentQuestion < _questions.length - 1) {
      setState(() {
        _currentQuestion++;
      });
    } else {
      setState(() {
        _gameOver = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Guess My Country', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _gameOver ? _buildGameOver() : _buildGame(),
      ),
    );
  }

  Widget _buildGame() {
    final question = _questions[_currentQuestion];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Playing with ${widget.opponent['name']}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.electricBlue, fontSize: 18),
        ),
        const SizedBox(height: 48),
        Text(
          question['question'],
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textWhite,
          ),
        ),
        const SizedBox(height: 48),
        ...(question['options'] as List<String>).map((option) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: ElevatedButton(
              onPressed: () => _answerQuestion(option),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surfaceDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppTheme.primaryPurple),
              ),
              child: Text(option, style: const TextStyle(fontSize: 18)),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGameOver() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Game Over!',
          style: GoogleFonts.outfit(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppTheme.neonPink,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Your Score: $_score / ${_questions.length}',
          style: const TextStyle(fontSize: 24, color: AppTheme.textWhite),
        ),
        const SizedBox(height: 48),
        Text(
          _score >= 2 ? 'You vibed well with ${widget.opponent['name']}!' : 'Time to learn more about different cultures!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, color: AppTheme.textGrey),
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Return to Discover'),
        ),
      ],
    );
  }
}
