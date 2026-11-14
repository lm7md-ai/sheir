import 'package:diwan_core/diwan_core.dart';

class SrsCardEntity {
  final String cardId;
  final String verseUid; // مرجع ثابت غير معتمد على معرف قاعدة بيانات متغيرة
  final SrsCardState state;

  const SrsCardEntity({
    required this.cardId,
    required this.verseUid,
    required this.state,
  });
}
