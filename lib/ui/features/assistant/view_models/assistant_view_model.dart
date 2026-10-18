import 'package:flutter/foundation.dart';

import '../../../../data/repositories/pets_repository.dart';
import '../../../../data/repositories/recommendation_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../../domain/models/order.dart';
import '../../../../domain/models/pet_profile.dart';

class AssistantViewModel extends ChangeNotifier {
  AssistantViewModel(
    this._petsRepository,
    this._recommendationRepository, {
    int? initialPetId,
  }) : _selectedPetId = initialPetId;

  final PetsRepository _petsRepository;
  final RecommendationRepository _recommendationRepository;
  int? _selectedPetId;

  List<PetProfile> pets = const [];
  RecommendationResult? result;
  bool isLoadingPets = false;
  bool isThinking = false;
  String? errorMessage;
  String? unavailableMessage;

  int? get selectedPetId => _selectedPetId;

  Future<void> loadPets() async {
    isLoadingPets = true;
    errorMessage = null;
    notifyListeners();
    try {
      pets = await _petsRepository.list();
      if (_selectedPetId == null ||
          !pets.any((pet) => pet.petId == _selectedPetId)) {
        _selectedPetId = pets.isEmpty ? null : pets.first.petId;
      }
    } on ApiException catch (error) {
      errorMessage = error.userMessage;
    } catch (_) {
      errorMessage = 'Không tải được hồ sơ thú cưng.';
    } finally {
      isLoadingPets = false;
      notifyListeners();
    }
  }

  void selectPet(int? petId) {
    _selectedPetId = petId;
    result = null;
    unavailableMessage = null;
    notifyListeners();
  }

  Future<void> ask() async {
    final petId = _selectedPetId;
    if (petId == null) return;
    isThinking = true;
    result = null;
    errorMessage = null;
    unavailableMessage = null;
    notifyListeners();
    try {
      result = await _recommendationRepository.recommend(petId);
    } on ApiException catch (error) {
      if (error.statusCode == 503) {
        unavailableMessage = 'Trợ lý AI chưa được kết nối với nhà cung cấp. Hồ sơ thú cưng đã sẵn sàng; cửa hàng cần cấu hình dịch vụ AI để bật tư vấn.';
      } else {
        errorMessage = error.userMessage;
      }
    } catch (_) {
      errorMessage = 'Chưa nhận được phản hồi. Hãy thử lại.';
    } finally {
      isThinking = false;
      notifyListeners();
    }
  }
}
