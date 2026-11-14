import 'package:diwan_core/diwan_core.dart';

class RecitationSessionEntity {
  final String sessionId;
  final String verseUid;
  final DateTime timestamp;
  final RecitationEvaluationResult evaluation;
  final int durationSeconds;

  const RecitationSessionEntity({
    required this.sessionId,
    required this.verseUid,
    required this.timestamp,
    required this.evaluation,
    required this.durationSeconds,
  });
}
