#!/usr/bin/env bash
# Run each Android check in one shell so failures are recorded without skipping
# the persistence assertion, screenshot capture, or the final nonzero exit.
set +e
mkdir -p artifacts/screenshots

flutter test integration_test -d emulator-5554 --reporter=json > artifacts/gui-tests.json 2> artifacts/gui-tests.stderr
test_rc=$?

# Stop the integration-test instrumentation process before the cold app launch.
# This does not clear the app's data, which is the subject of the persistence check.
if adb shell pm path de.alethea.flutter_testability_lab.test > /dev/null 2>&1; then
  adb shell am force-stop de.alethea.flutter_testability_lab.test > artifacts/test-runner-stop.stdout 2> artifacts/test-runner-stop.stderr
fi
adb logcat -d -t 1200 > artifacts/post-gui-logcat.txt 2>&1

# Reinstall the same APK without clearing app data, then relaunch its verified activity.
adb install -r build/app/outputs/flutter-apk/app-debug.apk > artifacts/install.stdout 2> artifacts/install.stderr
install_rc=$?
adb shell am force-stop de.alethea.flutter_testability_lab
adb shell am start -W -n de.alethea.flutter_testability_lab/de.alethea.flutter_testability_lab.MainActivity > artifacts/relaunch.stdout 2> artifacts/relaunch.stderr
start_rc=$?
python3 -c "import pathlib,sys; t=' '.join(pathlib.Path(p).read_text(errors='replace') for p in ('artifacts/relaunch.stdout','artifacts/relaunch.stderr')).lower(); sys.exit(1 if any(x in t for x in ('unable to resolve','error:','error type 3','does not exist','status: timeout','launchstate: unknown')) else 0)" || start_rc=1
sleep 8
adb shell uiautomator dump /sdcard/window.xml > artifacts/uiautomator.stdout 2> artifacts/uiautomator.stderr
dump_rc=$?
adb pull /sdcard/window.xml artifacts/restarted-ui.xml > artifacts/persistence.stdout 2> artifacts/persistence.stderr
pull_rc=$?
python3 -c "import pathlib,sys; p=pathlib.Path('artifacts/restarted-ui.xml'); text=p.read_text() if p.exists() else ''; sys.exit(0 if 'GUI smoke book' in text else 1)"
persist_rc=$?
if [[ $persist_rc -ne 0 ]]; then
  printf 'Expected persisted entry "GUI smoke book" was absent from restarted-ui.xml. Relaunch output follows:\n' >> artifacts/persistence.stderr
  python3 -c "from pathlib import Path; p=Path('artifacts/persistence.stderr'); p.write_text(p.read_text(errors='replace') + ''.join(Path(n).read_text(errors='replace') for n in ('artifacts/relaunch.stdout','artifacts/relaunch.stderr')))"
fi
# A screenshot is evidence only after the relaunched app shows the saved entry.
screenshot_rc=1
if [[ $persist_rc -eq 0 ]]; then
  adb exec-out screencap -p > artifacts/screenshots/gui-smoke.png
  screenshot_rc=$?
  if [[ ! -s artifacts/screenshots/gui-smoke.png ]]; then screenshot_rc=1; fi
fi
printf '%s\n' "$persist_rc" > artifacts/persistence.exit

if [[ $test_rc -ne 0 || $install_rc -ne 0 || $screenshot_rc -ne 0 || $start_rc -ne 0 || $dump_rc -ne 0 || $pull_rc -ne 0 || $persist_rc -ne 0 ]]; then
  printf 'GUI test=%s install=%s screenshot=%s relaunch=%s dump=%s pull=%s persistence=%s\n' \
    "$test_rc" "$install_rc" "$screenshot_rc" "$start_rc" "$dump_rc" "$pull_rc" "$persist_rc" >&2
  exit 1
fi
