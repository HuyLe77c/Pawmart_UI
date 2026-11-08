# PawMart Flutter

Flutter Android app for the PawMart pet food store. The app uses the ASP.NET API as its source of truth and keeps access tokens in Android secure storage.

Google Sign-In dùng Android OAuth client (package `com.example.pawmart` và SHA-1 của khóa ký) cùng Web OAuth client trong cùng Google Cloud project. Web Client ID công khai của PawMart đã được đặt làm mặc định trong app; khi đổi Google Cloud project có thể ghi đè bằng `--dart-define=GOOGLE_WEB_CLIENT_ID=<WEB_CLIENT_ID>`. BE phải dùng cùng giá trị ở `GoogleAuth:WebClientId`. Xem hướng dẫn `docs/google-sign-in.md` trong repo BE; không cần đưa client secret vào app.

## Run locally

1. Start SQL Server and the API from `C:\Users\cubin\OneDrive\Desktop\Project_PRM393\Pawmart\Pawmart`:

   ```powershell
   dotnet run --launch-profile http
   ```

   The API's HTTP launch profile listens on `0.0.0.0:5165`; Swagger is at `http://localhost:5165/swagger`.
2. Start the `Pixel_8` AVD from Android Studio Device Manager.
3. Open this folder in VS Code and run:

   ```powershell
   flutter pub get
   flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:5165
   ```

   `10.0.2.2` is the Android Emulator address for the host computer. For a physical phone, use the computer's LAN IP and allow inbound access to port 5165.

## Roles and features

- Public users can browse/search/filter the catalog. Sign in or register to manage pet profiles, cart, COD checkout, orders, pet-specific Tư vấn, and a separate Chat AI screen linked from the customer home page.
- Public registration always creates a CUSTOMER account. Create/promote an admin account using the SQL process in the API README. Admin users can open the dashboard, manage products, transition orders, manage categories/promotions/stores/warehouses, and save notification broadcasts to customer inboxes. Customers can read and mark those in-app notifications as read.
- Product data, prices, stock, order totals, and status are read from or written to the API. The local database includes 10 sample dog/cat food, treats, and accessory items.
- Admins can provide an external product image URL or pick a JPEG, PNG, or WebP image from the device gallery (maximum 20 MB). Uploaded files are stored by the API and their relative URLs are saved in `Product_Images`; back up the API's `wwwroot/uploads/products` folder together with the database.
- COD is available. Store and delivery maps use OpenStreetMap tiles; delivery address suggestions and reverse lookup use Photon with Android geocoding as a fallback. VNPAY, MoMo, ZaloPay, live route-based shipping prices, and push notifications require separate provider integration. Chat AI and pet advice use the backend's Omniroute configuration; see the backend README. Chat history is held only during the app session.
- Bank QR orders show a unique transfer code. When the backend is connected to SePay, the order detail refreshes payment status while open and shows confirmed payment after a verified incoming transfer. SePay setup, database migration, and public HTTPS webhook configuration are documented in the backend's `docs/checkout-cod-bank-qr.md`.
- Pet profiles now include size, activity, a 1–9 body condition score, feeding habits, and food preferences. The Tư vấn result shows curated nutrition reference URLs and avoids calculating a daily portion when product energy density is unavailable. Apply the backend `Database/migrations/2026-10-28_PetsNutritionProfile.sql` migration before using this UI with an existing database.
- In Tư vấn and Chat AI, verified products mentioned in an AI reply appear as tappable cards showing their current name and price; tapping a card opens product detail. The Tư vấn screen also accepts free-form questions about the selected pet.
- GPS checkout asks for Android location permission and keeps manual address entry available if permission is denied. The map shows the device's current GPS position and accuracy separately from the delivery pin; customers must confirm the full delivery address before ordering.

## Maps

The store map uses the coordinates returned by the API. Its pin is an approximate street location, not a verified storefront entrance. The directions button opens Google Maps using the full store address. Distance shown in the app is straight-line distance, not driving distance.

The delivery map debounces address searches, prioritizes nearby Vietnamese places, and caches recent suggestions. Up to 15 search results appear as numbered map pins and a matching list. On opening the map, nearby mapped roads and alleys appear as choices; after panning, use **Tìm khu vực này** to refresh them for the visible area. Search results are real geocoded places, but address coverage and house-number precision depend on OpenStreetMap/Photon data. Android's GPS position also depends on location permission and device accuracy; an emulator reports a simulated position. The app never silently turns a suggested road into a confirmed house address.

The default map tiles come from the public OpenStreetMap server and suggestions from the public Photon endpoint. These services have usage limits and no availability guarantee; configure a suitable hosted provider before production-scale traffic. `MAP_TILE_URL` can override the XYZ tile URL and `MAP_SEARCH_HOST` can point to a Photon-compatible host via `--dart-define`. Keep the required tile-provider attribution visible if changing providers.
- Order tracking shows API status history and the delivery address; it does not claim a live courier location or ETA.

## Build

On Windows, enable **Developer Mode** before `flutter pub get` so Flutter can create plugin symlinks and its Android plugin registrant. Without it, an APK built with `--no-pub` may install but fail to register `flutter_secure_storage` at startup. The local runtime check generated the ignored registrant file manually; a fresh clone should use normal `flutter pub get` with Developer Mode enabled.

```powershell
flutter analyze
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:5165
```
