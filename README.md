# PawMart Flutter

Flutter Android app for the PawMart pet food store. The app uses the ASP.NET API as its source of truth and keeps access tokens in Android secure storage.

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
- COD is available. VNPAY, MoMo, ZaloPay, map tiles, address geocoding, distance-based shipping, and push notifications stay visibly unavailable until their provider credentials and platform configuration are supplied. Chat AI and pet advice use the backend's Omniroute configuration; see the backend README. Chat history is held only during the app session.
- Pet profiles now include size, activity, a 1–9 body condition score, feeding habits, and food preferences. The Tư vấn result shows curated nutrition reference URLs and avoids calculating a daily portion when product energy density is unavailable. Apply the backend `Database/2026-10-28_PetsNutritionProfile.sql` migration before using this UI with an existing database.
- In Tư vấn and Chat AI, verified products mentioned in an AI reply appear as tappable cards showing their current name and price; tapping a card opens product detail. The Tư vấn screen also accepts free-form questions about the selected pet.
- GPS checkout asks for Android location permission and keeps manual address entry available if permission is denied. GPS provides coordinates, not a geocoded street address.
- Order tracking shows API status history and the delivery address; it does not claim a live courier location or ETA.

## Build

On Windows, enable **Developer Mode** before `flutter pub get` so Flutter can create plugin symlinks and its Android plugin registrant. Without it, an APK built with `--no-pub` may install but fail to register `flutter_secure_storage` at startup. The local runtime check generated the ignored registrant file manually; a fresh clone should use normal `flutter pub get` with Developer Mode enabled.

```powershell
flutter analyze
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:5165
```
