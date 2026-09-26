#!/usr/bin/env bash
# Drive the production installation directly; no instrumentation uninstall may erase data.
set +e
mkdir -p artifacts/screenshots
if [[ ! -f artifacts/production.apk ]]; then
  printf '%s\n' 'Android build did not produce artifacts/production.apk; device tests NOT RUN.' > artifacts/persistence.stderr
  printf '%s\n' '1' > artifacts/persistence.exit
  exit 1
fi
timeout 420s python3 tool/android_restart_test.py > artifacts/persistence.stdout 2> artifacts/persistence.stderr
rc=$?
adb logcat -d -t 1200 > artifacts/post-gui-logcat.txt 2>&1
if [[ ! -f artifacts/persistence.exit ]]; then printf '%s\n' '1' > artifacts/persistence.exit; fi
exit "$rc"
