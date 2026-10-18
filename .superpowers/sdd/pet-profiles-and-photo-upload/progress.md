# SDD ledger — plan: docs/superpowers/plans/2026-10-07-pet-profiles-and-photo-upload.md

Ruling: Both API and Flutter directories are user-provided working folders without Git metadata; implement in-place as explicitly directed, with no commits or GitHub operations.

Pre-flight: Task 1 produces POST /api/pets/{id}/image and PetResponse; Task 2 repository consumes that route and response. API contract inspected and Flutter PetProfile.fromJson maps the matching properties.

Approved seams: POST /api/pets/{id}/image multipart field `file`; Flutter add/edit pet form and persisted `Pets.ImageUrl`. Verification scope is approved plan: API build and manual owner/format checks; Flutter analysis/build and Android emulator flow.

Task 1: in_progress
Task 2: pending
Task 3: pending
