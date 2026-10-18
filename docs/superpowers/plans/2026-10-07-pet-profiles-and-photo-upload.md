# Pet Profiles and Photo Upload Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make customer pet profile creation work with optional age and let customers take or select a pet photo that is uploaded and saved with the profile.

**Architecture:** Keep pet metadata in the existing `Pets` table and store uploaded image files under the API's `wwwroot/uploads/pets`, persisting their relative URLs in `Pets.ImageUrl`. Add an authenticated, owner-scoped image endpoint with the existing 20 MiB JPEG/PNG/WebP policy; Flutter saves profile fields first, then uploads a selected image and reports a partial image failure without losing the saved profile.

**Tech Stack:** ASP.NET Core, EF Core, SQL Server, Flutter, `image_picker`, existing `ApiClient` multipart upload.

**Spec:** Approved in chat on 2026-10-07.

## Global Constraints

- Do not change the SQL schema; `Pets.ImageUrl` already exists and is nullable.
- Only a customer's own pet may receive an uploaded image.
- Limit uploads to 20 MiB and valid JPEG, PNG, or WebP signatures.
- Do not break existing API JSON pet create/update or external profile image URLs.

## Review Focus

- API unavailable: surface connection errors and ensure the API is running during emulator verification.
- Empty age and comma decimal input: accept empty age and convert decimal years consistently to months.
- Unauthorized or wrong-owner upload: reject and do not create/replace a file.
- Invalid, empty, or oversized image: reject without changing the saved image.
- Photo upload fails after profile save: preserve the profile and clearly report that only the photo failed.

---

### Task 1: Pet image upload API

**Files:**
- Create: API `Services/PetImageStorageService.cs`
- Modify: API `Program.cs`, `Controllers/PetsController.cs`

**Interfaces:**
- `PetImageStorageService.UploadAsync(string userId, int petId, IFormFile file, CancellationToken ct) -> Task<PetResponse>`
- `POST /api/pets/{id}/image`, multipart field `file`; authenticated customer only.

- [ ] Check owner and image existence, enforce the 20 MiB limit and JPEG/PNG/WebP signatures, write a generated filename under `wwwroot/uploads/pets`, and set `Pets.ImageUrl` to `/uploads/pets/{generated-name}`.
- [ ] On database failure, remove the newly written file; after a successful replacement, remove only an old PawMart-managed pet upload.
- [ ] Build the API and manually verify success, wrong-owner rejection, and invalid-image rejection without leaving test records/files.

### Task 2: Flutter pet form and photo flow

**Files:**
- Modify: `lib/data/repositories/pets_repository.dart`, `lib/ui/features/pets/view_models/pets_view_model.dart`, `lib/ui/features/pets/views/pet_profiles_screen.dart`

**Interfaces:**
- Add repository `uploadImage(int petId, String filePath) -> Future<PetProfile>` using `ApiClient.postMultipart`.
- Extend pet save to accept an optional picked `XFile` and preserve profile success when only the photo upload fails.

- [ ] Allow age to be empty and accept comma or period decimal separators before converting years to months.
- [ ] Add camera and gallery actions, a local preview, a 20 MiB client-side check, and JPEG/PNG/WebP extension checks.
- [ ] Upload the image after profile create/update; refresh the view model with the returned pet and show a clear partial-failure message if the upload fails.
- [ ] Resolve relative pet photo paths against the API base URL and show a placeholder if image loading fails.
- [ ] Run Flutter analysis/build and verify add, edit, and photo display on the Android emulator.

### Task 3: End-to-end recovery and verification

**Files:**
- No additional files unless verification finds a defect.

- [ ] Start the API on port 5165 and confirm `/health/ready` reports an available database.
- [ ] On Pixel 8, create a pet without age, edit it with age/weight, capture or select an image, and confirm the saved photo appears after reopening the profile.
- [ ] Confirm uploaded photo URL is stored in SQL and served as `image/jpeg`, `image/png`, or `image/webp`.
