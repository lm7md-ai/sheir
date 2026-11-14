import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../srs/spaced_repetition_engine.dart';
import '../../logs/diwan_logger.dart';

/// بطاقة تقدم المستخدم وسجل الحفظ
class UserProfileData {
  final int xp;
  final int streakDays;
  final String currentRank;
  final int memorizedVersesCount;

  const UserProfileData({
    required this.xp,
    required this.streakDays,
    required this.currentRank,
    required this.memorizedVersesCount,
  });
}

abstract class IUserDataRepository {
  Future<UserProfileData> getUserProfile();
  Future<void> saveSrsCard(SrsCardState card);
  Future<List<SrsCardState>> getDueCards();
  Future<void> recordRecitationSession({
    required int poemId,
    required double accuracy,
    required int xpEarned,
  });
}

class UserDataRepository implements IUserDataRepository {
  final Map<String, SrsCardState> _cardsCache = {};
  UserProfileData _profile = const UserProfileData(
    xp: 350,
    streakDays: 7,
    currentRank: 'ناظمٌ مُتْقِن',
    memorizedVersesCount: 38,
  );

  @override
  Future<UserProfileData> getUserProfile() async {
    return _profile;
  }

  @override
  Future<void> saveSrsCard(SrsCardState card) async {
    _cardsCache[card.cardId] = card;
    DiwanLogger.instance.info(
      'UserDataRepo',
      'Saved SRS card ${card.cardId}: next interval ${card.intervalDays} days',
    );
  }

  @override
  Future<List<SrsCardState>> getDueCards() async {
    final now = DateTime.now();
    return _cardsCache.values
        .where((c) => c.nextDue.isBefore(now) || c.nextDue.isAtSameMomentAs(now))
        .toList();
  }

  @override
  Future<void> recordRecitationSession({
    required int poemId,
    required double accuracy,
    required int xpEarned,
  }) async {
    _profile = UserProfileData(
      xp: _profile.xp + xpEarned,
      streakDays: _profile.streakDays,
      currentRank: _profile.currentRank,
      memorizedVersesCount: _profile.memorizedVersesCount + 1,
    );
    DiwanLogger.instance.info(
      'UserDataRepo',
      'Recitation session saved for poem $poemId: +$xpEarned XP (Total: ${_profile.xp})',
    );
  }
}

final userDataRepositoryProvider = Provider<IUserDataRepository>((ref) {
  return UserDataRepository();
});

final userProfileProvider = FutureProvider<UserProfileData>((ref) async {
  final repo = ref.watch(userDataRepositoryProvider);
  return repo.getUserProfile();
});
