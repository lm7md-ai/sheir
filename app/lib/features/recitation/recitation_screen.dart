import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/data/models/verse.dart';
import '../../core/nlp/recitation_alignment_engine.dart';
import '../../core/theme/theme_extension.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/record_button.dart';

class RecitationScreen extends StatefulWidget {
  final Verse verse;
  final Function(RecitationEvaluationResult result)? onEvaluationComplete;
  final VoidCallback? onCancel;

  const RecitationScreen({
    super.key,
    required this.verse,
    this.onEvaluationComplete,
    this.onCancel,
  });

  @override
  State<RecitationScreen> createState() => _RecitationScreenState();
}

class _RecitationScreenState extends State<RecitationScreen> {
  bool _isRecording = false;
  int _activeWordIndex = 0;
  Timer? _simulationTimer;
  final List<String> _simulatedSpokenWords = [];

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });

    if (_isRecording) {
      _startSimulatedRecognition();
    } else {
      _simulationTimer?.cancel();
      _evaluateRecitation();
    }
  }

  void _startSimulatedRecognition() {
    final expectedWords = '${widget.verse.sadr} ${widget.verse.ajuz}'.split(RegExp(r'\s+'));
    _activeWordIndex = 0;
    _simulatedSpokenWords.clear();

    _simulationTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (_activeWordIndex < expectedWords.length) {
        setState(() {
          _simulatedSpokenWords.add(expectedWords[_activeWordIndex]);
          _activeWordIndex++;
        });
      } else {
        timer.cancel();
        _toggleRecording(); // إنهاء تلقائي بعد إتمام البيت
      }
    });
  }

  void _evaluateRecitation() {
    final expectedText = '${widget.verse.sadr} ${widget.verse.ajuz}';
    final heardText = _simulatedSpokenWords.join(' ');

    final result = RecitationAlignmentEngine.evaluate(
      expectedText: expectedText,
      heardText: heardText.isEmpty ? expectedText : heardText,
    );

    widget.onEvaluationComplete?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    final diwan = context.diwan;
    final allWords = '${widget.verse.sadr} ${widget.verse.ajuz}'.split(RegExp(r'\s+'));

    return Scaffold(
      backgroundColor: diwan.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: diwan.textSecondary),
          onPressed: widget.onCancel ?? () => Navigator.maybePop(context),
        ),
        title: Text(
          'أستوديو التسميع والإلقاء',
          style: DiwanTypography.uiTitle(color: diwan.accentGold, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // نص البيت المركز عالي التباين
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Wrap(
                textDirection: TextDirection.rtl,
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 12,
                children: allWords.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final word = entry.value;
                  final isSpoken = idx < _activeWordIndex;
                  final isCurrent = idx == _activeWordIndex && _isRecording;

                  Color textColor = diwan.textMuted;
                  if (isSpoken) textColor = diwan.primary;
                  if (isCurrent) textColor = diwan.accentGold;

                  return AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: DiwanTypography.verseStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                    child: Text(
                      word,
                      textDirection: TextDirection.rtl,
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 32),

            // محاكاة الموجات الصوتية الحية (Live Simulated Waveform)
            SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(24, (index) {
                  final height = _isRecording
                      ? (12.0 + (index % 5) * 6.0)
                      : 4.0;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: 3.5,
                    height: height,
                    decoration: BoxDecoration(
                      color: _isRecording ? diwan.primary : diwan.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ),

            const Spacer(),

            // نص التوجيه
            Text(
              _isRecording
                  ? 'ديوان ينصت إلى إلقائك بخشوع..'
                  : 'اضغط على زر اللاقط وابدأ التسميع',
              style: DiwanTypography.uiBody(
                color: _isRecording ? diwan.accentGold : diwan.textSecondary,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 20),

            // زر التسجيل التفاعلي
            RecordButton(
              isRecording: _isRecording,
              onToggle: _toggleRecording,
              size: 80,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
