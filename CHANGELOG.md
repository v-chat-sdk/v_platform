## Unreleased — Flutter 3.50 migration

- Require Flutter 3.50 and Dart 3.14 or newer compatible versions.
- Migrate maintained Material/Cupertino imports to `material_ui`/`cupertino_ui` where used and apply the official Dart fixes.
- UI-facing theme and widget types now belong to the new design packages. Consumers must migrate together; legacy SDK `ThemeData`/`TextTheme` are distinct types. Treat this as a breaking release before publishing; no release is performed by this migration.
- Development examples may use `pubspec_overrides.yaml` for migrated sibling packages. Release compatible dependency versions and update hosted constraints before independent distribution.

## 3.0.0 - 2026-11-04

- Require Flutter >=3.47.0 and Dart >=3.13.0 <4.0.0 for this SDK update.
- Refresh package and example dependency constraints to current stable releases as of 2026-11-04, subject to documented upstream compatibility constraints.
- Validate with Flutter 3.47.8 / Dart 3.13.7 using fix, format, static analysis, and package/example tests.

## 2.2.0

- Add production-focused regression coverage for file sources, malformed maps,
  URL resolution, MIME detection, multipart uploads, and native/web targets.
- Restore signed-URL map precedence, validate byte and map inputs, normalize
  MIME classification, and redact credentials from diagnostic output.
- Fix asset serialization round trips and legacy map decoding.
- Normalize URL file names, base URL resolution, and deterministic cache keys.
- Make local-file access web/WASM safe through conditional platform helpers.
- Improve multipart validation, platform detection, documentation, and example UX.
- Remove redundant MIME and browser-DOM dependencies; update package metadata.
- Align declared minimums with Dart 3.4 and Flutter 3.22; update the example to
  the current stable `file_picker` API.
- Refresh the example Android toolchain to AGP 8.11.1, Gradle 8.14.3,
  Kotlin 2.2.20, and Java 17.
- Migrate the example's Apple runners to the current Flutter project format and
  raise its deployment targets to iOS 14.0 and macOS 10.15 for `file_picker` 12.

## 2.1.5

- Fix fullNetworkUrl to return url directly if already starts with http
- Fix getHashKey to return hashCode string instead of full URL

## 2.1.4

- Fix crypto issues with from bytes

## 2.1.3

- Fix set file from url issue

## 2.1.2

Fix set file from url issue
Remove meta package

## 2.1.1

Update .Readme file

## 2.1.0

Update the packages
Support isWasm flag
Fix get hash long time issue

## 2.0.0

Support Flutter V3.22

## 1.2.2

Support fileHash

## 1.2.1

upgrade the http package

## 1.2.0

- fix bug

## 1.0.7

- fix bug

## 1.0.5

- support for base url share

## 1.0.4

fix bug

## 1.0.3

fix bug

## 1.0.2

support dart 3

## 1.0.1

support dart 3

## 1.0.0
