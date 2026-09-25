#!/usr/bin/env bash
# Run each Android check in one shell so failures are recorded without skipping
# the persistence assertion, screenshot capture, or the final nonzero exit.
set +e
mkdir -p artifacts/screenshots

flutter test integration_test -d emulator-5554 --reporter=json > artifacts/gui-tests.json 2> artifacts/gui-tests.stderr
test_rc=$?

# Reinstall the same APK without clearing app data, then relaunch via its launcher intent.
adb install -r build/app/outputs/flutter-apk/app-debug.apk > artifacts/install.stdout 2> artifacts/install.stderr
install_rc=$?
adb shell am force-stop de.alethea.flutter_testability_lab
adb shell am start -W -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -p de.alethea.flutter_testability_lab > artifacts/relaunch.stdout 2> artifacts/relaunch.stderr
start_rc=$?
python3 -c "import pathlib,sys; t=' '.join(pathlib.Path(p).read_text(errors='replace') for p in ('artifacts/relaunch.stdout','artifacts/relaunch.stderr')); sys.exit(1 if ('unable to resolve' in t.lower() or 'error:' in t.lower()) else 0)" || start_rc=1
sleep 8
adb shell uiautomator dump /sdcard/window.xml > artifacts/uiautomator.stdout 2> artifacts/uiautomator.stderr
dump_rc=$?
adb exec-out screencap -p > artifacts/screenshots/gui-smoke.png
screenshot_rc=$?
if [[ ! -s artifacts/screenshots/gui-smoke.png ]]; then screenshot_rc=1; fi
adb pull /sdcard/window.xml artifacts/restarted-ui.xml > artifacts/persistence.stdout 2> artifacts/persistence.stderr
pull_rc=$?
python3 -c "import pathlib,sys; p=pathlib.Path('artifacts/restarted-ui.xml'); text=p.read_text() if p.exists() else ''; sys.exit(0 if 'GUI smoke book' in text else 1)"
persist_rc=$?
printf '%s\n' "$persist_rc" > artifacts/persistence.exit

if [[ $test_rc -ne 0 || $install_rc -ne 0 || $screenshot_rc -ne 0 || $start_rc -ne 0 || $dump_rc -ne 0 || $pull_rc -ne 0 || $persist_rc -ne 0 ]]; then
  printf 'GUI test=%s install=%s screenshot=%s relaunch=%s dump=%s pull=%s persistence=%s\n' \
    "$test_rc" "$install_rc" "$screenshot_rc" "$start_rc" "$dump_rc" "$pull_rc" "$persist_rc" >&2
  exit 1
fi
