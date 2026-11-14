import '../models/recitation_session.dart';

abstract class IRecitationRepository {
  Future<void> saveRecitationSession(RecitationSessionEntity session);
  Future<List<RecitationSessionEntity>> getRecentSessions({int limit = 20});
}
