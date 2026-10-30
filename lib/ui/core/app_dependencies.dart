import 'package:go_router/go_router.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/cart_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/orders_repository.dart';
import '../../data/repositories/pets_repository.dart';
import '../../data/repositories/recommendation_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/token_store.dart';
import '../features/auth/view_models/auth_view_model.dart';
import '../features/chat_ai/view_models/chat_ai_view_model.dart';
import 'app_router.dart';

class AppDependencies {
  AppDependencies._({
    required this.tokenStore,
    required this.apiClient,
    required this.authRepository,
    required this.authViewModel,
    required this.petsRepository,
    required this.ordersRepository,
    required this.cartRepository,
    required this.recommendationRepository,
    required this.chatAiViewModel,
    required this.router,
  });

  factory AppDependencies.create({required String baseUrl}) {
    final tokenStore = TokenStore();
    final apiClient = ApiClient(baseUrl: baseUrl, tokenStore: tokenStore);
    final authRepository = AuthRepository(apiClient, tokenStore);
    final authViewModel = AuthViewModel(authRepository, tokenStore);
    apiClient
      ..onUnauthorized = authViewModel.handleSessionExpired
      ..onForbidden = authViewModel.handleSessionExpired;
    final petsRepository = PetsRepository(apiClient);
    final ordersRepository = OrdersRepository(apiClient);
    return AppDependencies._(
      tokenStore: tokenStore,
      apiClient: apiClient,
      authRepository: authRepository,
      authViewModel: authViewModel,
      petsRepository: petsRepository,
      ordersRepository: ordersRepository,
      cartRepository: CartRepository(apiClient),
      recommendationRepository: RecommendationRepository(apiClient),
      chatAiViewModel: ChatAiViewModel(
        ChatRepository(apiClient),
        authViewModel,
      ),
      router: createAppRouter(authViewModel),
    );
  }

  final TokenStore tokenStore;
  final ApiClient apiClient;
  final AuthRepository authRepository;
  final AuthViewModel authViewModel;
  final PetsRepository petsRepository;
  final OrdersRepository ordersRepository;
  final CartRepository cartRepository;
  final RecommendationRepository recommendationRepository;
  final ChatAiViewModel chatAiViewModel;
  final GoRouter router;

  void dispose() {
    router.dispose();
    chatAiViewModel.dispose();
    authViewModel.dispose();
    apiClient.close();
  }
}
