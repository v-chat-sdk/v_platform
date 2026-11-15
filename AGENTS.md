# Repository Guidelines

## Project Structure & Module Organization

`lib/v_platform.dart` is the package entry point and exports the public API. Keep implementations in `lib/src/`: `v_platform_file.dart` owns file-source metadata and serialization, `platforms.dart` contains platform and multipart helpers, and `enums.dart` defines shared types. Package tests live in `test/`. The runnable demonstration and its widget tests live in `example/lib/` and `example/test/`; sibling platform directories are Flutter runners. The package declares no bundled assets.

## Build, Test, and Development Commands

- `flutter pub get` — resolve package dependencies from the repository root.
- `flutter analyze` — apply the rules inherited from `flutter_lints`.
- `dart format --output=none --set-exit-if-changed lib test example/lib example/test` — verify Dart formatting without rewriting files.
- `flutter test` — run package-level unit tests.
- `cd example && flutter run -d chrome` — exercise the example app in a web browser; select another device when validating native file paths.
- `cd example && flutter test` — run the current `flutter_test` widget suite.
- `cd example && flutter build web` — perform a distributable web build smoke test.

Run `dart format lib test example/lib example/test` before submitting Dart changes.

## Coding Style & Naming Conventions

Use idiomatic null-safe Dart with two-space indentation. Follow `UpperCamelCase` for types, `lowerCamelCase` for members, and `snake_case.dart` for files. Prefer `final` or `const` where values do not change. Name source-specific constructors consistently with the existing API (`VPlatformFile.fromPath`, `.fromUrl`, `.fromBytes`, and `.fromAssets`). Document public members and export intentional public APIs through `lib/v_platform.dart`; do not import another package's `src/` files.

## Testing Guidelines

Name tests `*_test.dart` and group them by behavior. Cover constructor validation, MIME/media classification, hashes, map round trips, and relative-versus-absolute URL handling. Exercise web byte sources separately from native path sources. Avoid live network dependencies; use deterministic bytes, temporary files, or mocked clients. There is no numeric coverage gate, but every bug fix should include a regression test. Update the example's widget test when UI behavior changes.

## Commit & Pull Request Guidelines

History favors short, imperative subjects such as `Fix set file from url issue` and `Support Flutter V3.22`; release commits use `## 2.1.5 - ...`. Keep each commit focused. Pull requests should explain behavior and compatibility impact, link relevant issues, list commands actually run, and include screenshots for visible example changes. Update `CHANGELOG.md` for user-facing changes. Exclude secrets, local SDK paths, `.dart_tool/`, `build/`, and generated plugin registrants.
