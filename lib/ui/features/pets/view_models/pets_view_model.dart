import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../data/repositories/pets_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../../domain/models/pet_profile.dart';

class PetsViewModel extends ChangeNotifier {
  PetsViewModel(this._repository);
  final PetsRepository _repository;

  List<PetProfile> pets = const [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      pets = await _repository.list();
    } on ApiException catch (error) {
      errorMessage = error.userMessage;
    } catch (_) {
      errorMessage = 'Không tải được hồ sơ thú cưng.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> save({
    int? petId,
    required Map<String, Object?> request,
    XFile? photo,
  }) async {
    errorMessage = null;
    try {
      var saved = petId == null
          ? await _repository.create(request)
          : await _repository.update(petId, request);
      if (photo != null) {
        try {
          saved = await _repository.uploadImage(saved.petId, photo.path);
        } on ApiException catch (error) {
          errorMessage =
              'Hồ sơ đã lưu nhưng ảnh chưa tải lên: ${error.userMessage}';
        } catch (_) {
          errorMessage = 'Hồ sơ đã lưu nhưng ảnh chưa tải lên được. Bạn có thể thử lại trong phần sửa hồ sơ.';
        }
      }
      pets = [
        for (final pet in pets)
          if (pet.petId != saved.petId) pet,
        saved,
      ]..sort((a, b) => a.petId.compareTo(b.petId));
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.userMessage;
    } catch (_) {
      errorMessage = 'Không lưu được hồ sơ thú cưng.';
    }
    notifyListeners();
    return false;
  }

  Future<bool> delete(int petId) async {
    errorMessage = null;
    try {
      await _repository.delete(petId);
      pets = pets.where((pet) => pet.petId != petId).toList(growable: false);
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.userMessage;
    } catch (_) {
      errorMessage = 'Không xóa được hồ sơ thú cưng.';
    }
    notifyListeners();
    return false;
  }
}
