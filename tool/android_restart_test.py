"""Black-box Android add/force-stop/relaunch test on a single installed APK.

Run after Flutter's integration-test runner exits: that runner uninstalls its app.
This test creates its own entry AFTER installing the production APK and never
reinstalls or clears data between writing and checking it.
"""
import json
import pathlib
import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET

ART = pathlib.Path('artifacts')
ART.mkdir(exist_ok=True)
PKG = 'de.alethea.flutter_testability_lab'
ACTIVITY = f'{PKG}/{PKG}.MainActivity'
TITLE = 'Restart proof book'


def adb(*args, timeout=60):
    result = subprocess.run(['adb', *args], capture_output=True, text=True, timeout=timeout)
    with (ART / 'android-restart.log').open('a') as log:
        log.write(f"adb {args!r}: exit={result.returncode}\n{result.stdout}{result.stderr}\n")
    if result.returncode:
        raise RuntimeError(f'adb {args!r} failed ({result.returncode}): {result.stderr}')
    return result.stdout


def hierarchy():
    adb('shell', 'uiautomator', 'dump', '/sdcard/window.xml')
    adb('pull', '/sdcard/window.xml', str(ART / 'restarted-ui.xml'))
    root = ET.parse(ART / 'restarted-ui.xml').getroot()
    return list(root.iter('node'))


def matching(nodes, needle):
    return [node for node in nodes if needle in ((node.get('text') or '') + ' ' + (node.get('content-desc') or ''))]


def await_node(needle, seconds=40):
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        nodes = hierarchy()
        found = matching(nodes, needle)
        if found:
            return found[0]
        time.sleep(2)
    raise AssertionError(f'{needle!r} not visible in app hierarchy')


def tap(node):
    bounds = node.get('bounds', '')
    coords = [int(x) for x in re.findall(r'\d+', bounds)]
    if len(coords) != 4:
        raise AssertionError(f'No tappable bounds: {bounds}')
    adb('shell', 'input', 'tap', str((coords[0] + coords[2]) // 2), str((coords[1] + coords[3]) // 2))


def launch():
    output = adb('shell', 'am', 'start', '-W', '-n', ACTIVITY)
    if any(x in output.lower() for x in ('status: timeout', 'launchstate: unknown', 'error:', 'does not exist')):
        raise AssertionError(f'Activity launch failed: {output}')
    await_node('Reading list lab')


start = time.monotonic()
result: dict[str, str | float] = {'name': 'PER-01 real app restart restores entry', 'status': 'FAILED'}
try:
    # This is the only APK install. No installation or data reset follows add.
    adb('install', '-r', 'artifacts/production.apk', timeout=180)
    launch()
    tap(await_node('Book title'))
    adb('shell', 'input', 'text', TITLE.replace(' ', '%s'))
    tap(await_node('Add book'))
    await_node(TITLE)
    adb('shell', 'am', 'force-stop', PKG)
    launch()
    await_node(TITLE)
    # Only a verified relaunched app state is eligible for screenshot evidence.
    screenshot = subprocess.run(['adb', 'exec-out', 'screencap', '-p'], capture_output=True, timeout=60)
    if screenshot.returncode or not screenshot.stdout.startswith(b'\x89PNG\r\n\x1a\n'):
        raise AssertionError('No valid PNG screenshot of the relaunched app')
    (ART / 'screenshots').mkdir(exist_ok=True)
    (ART / 'screenshots' / 'gui-smoke.png').write_bytes(screenshot.stdout)
    result['status'] = 'PASSED'
except Exception as exc:
    result['error'] = str(exc)
    print(f"Restart test failed: {exc}", file=sys.stderr)
finally:
    result['duration_seconds'] = round(time.monotonic() - start, 3)
    (ART / 'restart-result.json').write_text(json.dumps(result, indent=2) + '\n')
    (ART / 'persistence.exit').write_text('0\n' if result['status'] == 'PASSED' else '1\n')
sys.exit(0 if result['status'] == 'PASSED' else 1)
