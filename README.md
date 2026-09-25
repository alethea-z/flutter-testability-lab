# Flutter Testability Lab

[![CI](https://github.com/alethea-z/flutter-testability-lab/actions/workflows/ci.yml/badge.svg)](https://github.com/alethea-z/flutter-testability-lab/actions/workflows/ci.yml) · [Latest test runs](https://github.com/alethea-z/flutter-testability-lab/actions/workflows/ci.yml)

A functional reading-list app for learning test layers. It supports add/edit/delete/search, validation, local persistence and deterministic simulated imports. UI, domain, persistence/repository and importer layers are separate. Tests never call a real service.

## Requirements & traceability
See [the Gherkin requirements](docs/requirements/reading-list.feature). Automated BDD cases are parsed from `test/features/reading_list.feature` and map to cases in `test/bdd_test.dart`. Unit/service tests: `test/reading_list_test.dart`; widget tests: `test/widget_test.dart`; emulator GUI: `integration_test/reading_list_test.dart`. `MANUAL-01` accessibility check is explicitly manual. Planned but not yet executed scenarios are not reported as passed.

| Test type | Example | Command |
|---|---|---|
| Unit | VAL-01, BOOK-01 | `flutter test test/reading_list_test.dart` |
| BDD | BOOK-ADD-01, BOOK-VALID-01, BOOK-SEARCH-01, IMPORT-01 | `flutter test test/bdd_test.dart` |
| Widget | WID-ADD-01, WID-ERR-01 | `flutter test test/widget_test.dart` |
| GUI/E2E | GUI-01 | `flutter test integration_test -d <emulator-id>` |
| Persistence | PER-01 | CI integration flow adds through UI, force-stops/relaunches app, verifies restored entry in rendered Android UI hierarchy |
| Service | SVC-01 | controlled importer tests; no network |
| Build/smoke | Android APK + GUI scenario | `flutter build apk --debug` |

## Prerequisites and commands
Flutter stable and Android SDK; an Android emulator/device is needed for integration tests.

```sh
flutter pub get
flutter run
flutter analyze
flutter test
flutter build apk --debug
flutter test integration_test -d emulator-5554
```

Import modes are controlled (`success`, `error`, `timeout`, `offline`).

## CI and reports
Pull requests and pushes to `main` run analysis, fast tests, emulator GUI tests and a debug APK build. Reports and GUI screenshots are uploaded on every run, including failures; a final CI gate keeps failed test jobs failed. `FAILED` and `NOT RUN` remain distinct from `PASSED`. Each run's artifacts are linked from its workflow summary.

[Workflow status and run artifacts](https://github.com/alethea-z/flutter-testability-lab/actions/workflows/ci.yml). Visual golden comparisons are omitted; functional tests have priority.
