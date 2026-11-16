# Repository Guidelines

## Project Structure & Module Organization

`lib/v_platform.dart` is the package entry point and exports the public API. Keep implementations in `lib/src/`: `v_platform_file.dart` owns file-source metadata and serialization, `platforms.dart` contains platform and multipart helpers, and `enums.dart` defines shared types. Package tests live in `test/`. The runnable demonstration and its widget tests live in `example/lib/` and `example/test/`; sibling platform directories are Flutter runners. The package declares no bundled assets.

## Flutter 3.50 verification workflow

Use the installed project-compatible Flutter 3.50/Dart 3.14 SDK. Keep direct `material_ui`/`cupertino_ui` dependencies consistent with their imports; design widgets no longer come from `flutter/material.dart` or `flutter/cupertino.dart`. Prefer neutral Flutter libraries when design widgets are unnecessary. Preserve this project's architecture and public contracts.

Resolve dependencies from each affected package root with `flutter pub get --no-example`. For a design migration, run `dart fix --apply --code=migrate_design_widgets` and review its output. After every code edit, run these commands sequentially from the affected package root:

```sh
dart fix --apply
dart format .
flutter analyze
```

Fix and format must finish before analysis or tests. Analyzer-only verification is the default. Run a focused test or build when requested or needed to prove a specific behavior change; choose the smallest useful check. Passing analysis does not prove runtime, provider, native linking, or integration behavior. Never suppress maintained-source diagnostics to obtain a pass. Preserve tool-owned generated files.

Existing web runners: `example`. When a run is requested, use the existing web development workflow with one explicitly selected target and port, then inspect it with Playwright MCP. An explicitly requested `flutter build web` is a compile check, separate from the development run. Do not add web targets merely to validate a migration.

Use a reachable physical Android device only when web is unsupported and device execution is requested. No emulator or simulator is authorized. This Linux VPS cannot execute native iOS/macOS builds or assume access to a phone attached to the Mac. Observe the global 500 MB download rule and preserve existing edits, credentials, caches, and running sessions. Do not push, publish, deploy, or run native builds without task authorization.

Use one handwritten class/widget per file; a StatefulWidget and its paired State may share a file. Apply SOLID without speculative abstractions. Keep UI, coordination, domain behavior, transport, persistence, and provider mechanics in their existing layers; use explicit types and correct async ownership/disposal. Do not impose another project’s state management or architecture.


## Coding Style & Naming Conventions

Use idiomatic null-safe Dart with two-space indentation. Follow `UpperCamelCase` for types, `lowerCamelCase` for members, and `snake_case.dart` for files. Prefer `final` or `const` where values do not change. Name source-specific constructors consistently with the existing API (`VPlatformFile.fromPath`, `.fromUrl`, `.fromBytes`, and `.fromAssets`). Document public members and export intentional public APIs through `lib/v_platform.dart`; do not import another package's `src/` files.

## Testing Guidelines

Name tests `*_test.dart` and group them by behavior. Cover constructor validation, MIME/media classification, hashes, map round trips, and relative-versus-absolute URL handling. Exercise web byte sources separately from native path sources. Avoid live network dependencies; use deterministic bytes, temporary files, or mocked clients. There is no numeric coverage gate, but every bug fix should include a regression test. Update the example's widget test when UI behavior changes.

## Commit & Pull Request Guidelines

History favors short, imperative subjects such as `Fix set file from url issue` and `Support Flutter V3.22`; release commits use `## 2.1.5 - ...`. Keep each commit focused. Pull requests should explain behavior and compatibility impact, link relevant issues, list commands actually run, and include screenshots for visible example changes. Update `CHANGELOG.md` for user-facing changes. Exclude secrets, local SDK paths, `.dart_tool/`, `build/`, and generated plugin registrants.

## Local package migration dependencies

The development overrides in `example/pubspec_overrides.yaml` point to migrated sibling packages in the organized workspace. Keep the relative layout when developing this migration. Hosted releases may still expose legacy Material theme types. Before distributing a checkout independently, release compatible dependency versions and update its hosted constraints; do not publish local paths or force incompatible overrides.
