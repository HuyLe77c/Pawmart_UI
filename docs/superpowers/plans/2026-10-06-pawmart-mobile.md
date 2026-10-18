# PawMart Android App Implementation Plan

> **For agentic workers:** Follow this plan task by task using the Native execution method selected by the user. Do not use GitHub or delegate implementation.

**Goal:** Turn the PawMart Flutter starter into a customer and admin Android app matching the ten supplied design pages and backed by the existing ASP.NET API.

**Architecture:** Build a Flutter presentation layer with role-specific shells and ChangeNotifier view models. Keep HTTP, secure token storage, DTO mapping, and repositories in the data layer; use immutable domain models between repositories and screens. Add three Admin-authorized read APIs for inactive catalog/store records; no database schema changes.

**Tech Stack:** Flutter 3.47.2, Dart 3.13.2, Material 3, `http`, `provider`, `go_router`, `flutter_secure_storage`, `geolocator`, ASP.NET Core 10, SQL Server.

**Spec:** `docs/superpowers/specs/2026-10-06-pawmart-mobile-design.md`

## Global Constraints

- Target Android phones with Flutter; customer navigation has Home, Categories, AI Chat, Orders, Profile; admin navigation has Overview, Products, Orders, More.
- The app is online-first and every failed request has a clear message and retry action.
- Persist JWTs only in Android secure storage; never hardcode API secrets or provider keys.
- The PDF is a visual reference only. Implement customer pages 1-6 and adapt admin pages 7-10 for phones.
- Render admin actions only for an authenticated `ADMIN`; public mobile registration creates customers only.
- Use at least 48dp touch targets, lazy lists with stable IDs, and loading/empty/error/success states.
- Do not fabricate product ratings, reviews, variants, discounts, or inventory; current API/DB has none of those product attributes.
- No DB schema changes. No GitHub. Automated tests are not included in this plan; verify with analyzer/build and manual Android/API smoke flows.
- Android Emulator calls the host API through `http://10.0.2.2:5165`; the API HTTP launch profile binds to `0.0.0.0:5165`.

## Review Focus

- Stale, expired, or malformed JWT: clear protected state, route to sign-in, and do not display customer/admin data.
- `CUSTOMER` directly opening an admin route or receiving HTTP 403: reject the route and retain customer navigation.
- Empty catalog, admin list, pet list, cart, or orders: show an intentional empty state instead of fake sample records.
- API offline, timeout, validation problem, 401, 403, or 409: show the correct recoverable message and retry/re-auth action.
- GPS permission denied or location service disabled: preserve manual address/coordinate entry and COD checkout.

---

### Task 1: Add protected admin list APIs

**Files:**
- Modify: `Pawmart/Services/CatalogServices.cs`
- Modify: `Pawmart/Services/CommerceServices.cs`
- Create: `Pawmart/Controllers/AdminProductsController.cs`
- Create: `Pawmart/Controllers/AdminCategoriesController.cs`
- Create: `Pawmart/Controllers/AdminStoresController.cs`

**Interfaces:**
- Produce `ProductService.ListForAdminAsync(ProductQuery query, CancellationToken ct) -> Task<PagedResponse<ProductResponse>>`; preserve the existing query filters/sort/page limits but do not filter `IsActive`; `ProductResponse` exposes `IsActive`.
- Produce `CategoryService.ListForAdminAsync(CancellationToken ct) -> Task<IReadOnlyList<CategoryResponse>>`; include active and inactive, ordered by `SortOrder`, then ID; `CategoryResponse` exposes `IsActive`.
- Produce `StoreService.ListForAdminAsync(CancellationToken ct) -> Task<IReadOnlyList<StoreResponse>>`; include active and inactive, ordered by ID; `StoreResponse` exposes `IsActive`.
- `PromotionResponse` exposes `IsActive` so admin can reliably display/toggle promotion state.
- Expose those methods only through `GET /api/admin/products`, `GET /api/admin/categories`, and `GET /api/admin/stores`, each protected by `AuthorizationPolicies.Admin`.

- [ ] Add Admin controllers and service queries with the exact routes and response contracts above.
- [ ] Build the API with `dotnet build Pawmart/Pawmart.csproj --no-restore`; expected: 0 errors.
- [ ] Start the API and verify each route returns 401 without a token and a valid admin response with an admin token; verify the product page remains paged and includes inactive records.

### Task 2: Create Flutter foundation and role-aware authentication

**Files:**
- Modify: `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml`, `lib/main.dart`
- Create: `lib/data/services/api_client.dart`, `lib/data/services/token_store.dart`
- Create: `lib/data/models/auth_api_model.dart`, `lib/domain/models/app_user.dart`
- Create: `lib/data/repositories/auth_repository.dart`
- Create: `lib/ui/core/app_router.dart`, `lib/ui/core/app_theme.dart`, `lib/ui/core/app_dependencies.dart`
- Create: `lib/ui/features/auth/view_models/auth_view_model.dart`
- Create: `lib/ui/features/auth/views/sign_in_screen.dart`, `lib/ui/features/auth/views/register_screen.dart`

**Interfaces:**
- `ApiClient({required String baseUrl, required TokenStore tokenStore, required http.Client httpClient})`; methods `getJson`, `postJson`, `putJson`, `patchJson`, `delete` attach JWT when present and throw `ApiException(statusCode, title, detail, errors)` for ProblemDetails/errors.
- `TokenStore.read() -> Future<String?>`, `write(String token) -> Future<void>`, `clear() -> Future<void>` uses `FlutterSecureStorage`.
- `AuthRepository.login(email, password) -> Future<AppUserSession>`, `register(...) -> Future<AppUserSession>`, `me() -> Future<AppUser>`.
- Router sends unauthenticated protected routes to sign-in, `CUSTOMER` to customer shell, and `ADMIN` to admin shell. No admin self-registration.

- [ ] Add only `http`, `provider`, `go_router`, `flutter_secure_storage`, and `geolocator` dependencies needed by this plan; grant Android Internet and runtime location permission declarations.
- [x] Implement API error/JWT handling and secure token persistence, including session clearing on 401/403. Set the API URL through `--dart-define=API_BASE_URL=...`; use `http://10.0.2.2:5165` for the emulator.
- [ ] Replace the Flutter counter app with PawMart theme, dependency composition, role-aware router, sign-in, and customer registration.
- [ ] Run `flutter pub get` and `flutter analyze`; expected: dependency resolution succeeds and analyzer reports no errors.

### Task 3: Implement customer storefront, catalog, pets, and cart

**Files:**
- Create domain/API models under `lib/domain/models/` and `lib/data/models/` for products, categories, pets, and cart.
- Create repositories under `lib/data/repositories/` for catalog, pets, and cart.
- Create view models and screens under `lib/ui/features/home/`, `catalog/`, `product_detail/`, `pets/`, and `cart/`.
- Create customer shell under `lib/ui/features/customer/views/customer_shell.dart`.

**Interfaces:**
- Catalog repository exposes paged product search, product detail, categories, and active promotions.
- Pet repository exposes `list/create/update/delete` against `/api/pets`.
- Cart repository exposes `get/upsert/remove` against `/api/cart`.
- Customer shell has exactly five destinations: Home, Categories, AI Chat, Orders, Profile. Home shows available active promotions/featured products; Categories follows page 2; Profile hosts pet management from page 1.

- [ ] Implement domain/API models with explicit mappings for API camel-case JSON and enum values (`DOG`, `CAT`, `ALL`, `OTHER`).
- [ ] Implement repositories and ChangeNotifier view models with loading, empty, error/retry, and success states.
- [ ] Build Home, catalog search/filter/sort/pagination, product detail and add-to-cart, pet CRUD, and cart update/remove flows using lazy lists and stable IDs.
- [ ] Run `flutter analyze`; expected: no analyzer errors. Manually verify catalog empty state and signed-out prompts against the local API after Task 6.

### Task 4: Implement customer AI, checkout, address, and order tracking

**Files:**
- Create: `lib/data/models/order_api_model.dart`, `lib/data/models/commerce_api_model.dart`
- Create: `lib/data/repositories/orders_repository.dart`, `lib/data/repositories/recommendation_repository.dart`
- Create view models/screens under `lib/ui/features/assistant/`, `checkout/`, and `orders/`
- Modify: `lib/ui/features/customer/views/customer_shell.dart`

**Interfaces:**
- Orders repository exposes customer list/detail/cancel and checkout to `/api/orders`, `/api/cart/checkout`, and `/api/orders/{orderId}/cancel`.
- Recommendation repository exposes `recommend(int petId) -> Future<RecommendationResult>` to `/api/chat/recommendations`.
- Checkout accepts recipient, address, optional coordinates, note, promo code, and payment enum `COD|VNPAY|MOMO|ZALOPAY`.

- [x] Implement the conversation-style AI screen using pet profiles and the single-response recommendation API; surface provider-unavailable response as a recoverable unavailable state.
- [x] Implement address/checkout with GPS permission handling, manual address/coordinate entry, COD, and honest disabled states for unconfigured online payment/map providers.
- [x] Implement customer orders, status history, detail, and cancellation. Do not synthesize courier location or ETA.
- [x] Run `flutter analyze --no-fatal-infos`; no errors or warnings. Informational lint notices remain. Denied-location and unavailable-provider states were not manually exercised on the emulator.

### Task 5: Implement four admin screens and management flows

**Files:**
- Create models/repositories under `lib/data/models/` and `lib/data/repositories/` for admin reports, products, categories, promotions, stores.
- Create: `lib/ui/features/admin/views/admin_shell.dart`
- Create screens/view models under `lib/ui/features/admin/overview/`, `products/`, `orders/`, and `catalog_management/`
- Modify: `lib/ui/core/app_router.dart`

**Interfaces:**
- Admin repositories use `/api/admin/reports/*`, `/api/admin/orders*`, `/api/admin/products`, `/api/admin/categories`, `/api/promotions/admin`, `/api/products` write operations, `/api/categories` write operations, and `/api/stores` write operations.
- Admin shell has Overview, Products, Orders, More. More contains categories, promotions, and store/warehouse sections.

- [x] Implement overview KPI cards/recent orders from existing report/order endpoints; do not add the unsupported new-customer count.
- [x] Implement admin product paging including inactive products, create/edit, and activate/deactivate.
- [x] Implement admin order filters/status transitions and display API conflicts without applying optimistic status changes.
- [x] Implement category/promotion/store list/create/edit/activate flows; use address and lat/lon fields until map SDK keys are configured. Admin can also persist in-app notification broadcasts; push remains provider-dependent.
- [ ] Manually verify role routing and admin mutations on the emulator; no admin test account/catalog seed was available. API authorization and the admin list endpoints had already been checked directly.

### Task 6: Run and verify on Android Studio Emulator

**Files:**
- Modify only as required: `android/app/src/main/AndroidManifest.xml`, `android/app/build.gradle.kts`, and implementation files discovered during build/run.
- Modify: `README.md` with API/device startup instructions, provider limitations, and demo login/bootstrap steps.

- [ ] Run `flutter analyze` from the Flutter project root; expected: no errors.
- [x] Run `flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:5165`; expected: debug APK builds successfully.
- [x] Start the Android Studio Pixel_8 AVD, confirm `flutter devices` lists `emulator-5554`, install and launch the APK.
- [ ] Complete signed-in customer and admin end-to-end flows on the emulator; the guest catalog, live API connection, sign-in screen, and customer registration screen were manually inspected. Full checkout/admin mutations require a provisioned test admin account and real catalog records.
- [ ] Verify network failure/retry, expired-token sign-in, denied GPS permission/manual entry, empty-state behavior, and unavailable AI/map/payment provider messaging. Record any environment-only blocker without claiming the relevant flow passed.

## Plan self-review

- **Coverage:** Customer auth, home/catalog/detail, pet profiles, cart, AI, address/checkout, order tracking, admin dashboard/products/orders/catalog/promotion/store pages, role routing, API extensions, and Android emulator workflow each have an owning task.
- **Step granularity:** Tasks are ordered by contracts and dependency boundaries: admin endpoints, shared Flutter base, customer commerce, extended customer flows, admin UI, Android integration.
- **Type consistency:** `AppUserSession`, `AppUser`, `ApiException`, `ProductQuery`, `PagedResponse`, and provider routes use the existing backend contracts referenced in the spec; concrete Flutter model field mappings are defined against controller response records during implementation.
- **Review focus:** All five highest-risk cases map to explicit manual smoke scenarios in Tasks 3-6.
- **Proportion:** Six tasks split backend/API foundation, customer app, admin app, and device integration without duplicating endpoint contracts.
