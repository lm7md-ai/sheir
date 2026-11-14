import '../models/srs_card_entity.dart';

abstract class ISrsRepository {
  Future<void> saveCard(SrsCardEntity card);
  Future<SrsCardEntity?> getCardByVerseUid(String verseUid);
  Future<List<SrsCardEntity>> getDueCards({int limit = 50});
}
