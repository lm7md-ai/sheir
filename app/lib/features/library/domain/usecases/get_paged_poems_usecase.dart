import '../entities/poem_entity.dart';
import '../repositories/i_library_repository.dart';

/// حالة استخدام جلب القصائد بالتقطيع المفتاحي (Keyset Pagination UseCase)
class GetPagedPoemsUseCase {
  final ILibraryRepository _repository;

  const GetPagedPoemsUseCase(this._repository);

  Future<KeysetPage<PoemEntity>> execute({
    String? afterCursor,
    int limit = 50,
    String? era,
    String? meter,
  }) {
    return _repository.getPoemsKeyset(
      afterCursor: afterCursor,
      limit: limit,
      era: era,
      meter: meter,
    );
  }
}
