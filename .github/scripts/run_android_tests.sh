#!/usr/bin/env bash
# Flutter's integration runner can uninstall the test package at exit. Run the
# production APK persistence scenario separately on one unchanged installation.
set +e
mkdir -p artifacts/screenshots
timeout 900s flutter test integration_test -d emulator-5554 --reporter=json > artifacts/gui-tests.json 2> artifacts/gui-tests.stderr
test_rc=$?
adb logcat -d -t 1200 > artifacts/post-gui-logcat.txt 2>&1
timeout 300s python3 tool/android_restart_test.py > artifacts/persistence.stdout 2> artifacts/persistence.stderr
restart_rc=$?
if [[ ! -f artifacts/persistence.exit ]]; then printf '%s\n' '1' > artifacts/persistence.exit; fi
if [[ $test_rc -ne 0 || $restart_rc -ne 0 ]]; then
  printf 'GUI test exit=%s; black-box restart exit=%s\n' "$test_rc" "$restart_rc" >&2
  exit 1
fi
