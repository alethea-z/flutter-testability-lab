"""Black-box Android add/force-stop/relaunch test on a single installed APK.

Install the production APK once, drive its UI, then force-stop and relaunch.
No test instrumentation replaces the app or clears its data.
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
    if any(x in output.lower() for x in ('error:', 'does not exist', 'unable to resolve')):
        raise AssertionError(f'Activity launch failed: {output}')
    # am start -W can time out on a slow emulator even when the app opens.
    # The visible app hierarchy, not the launcher timing estimate, decides.
    await_node('Reading list lab', seconds=90)


start = time.monotonic()
restart_start = start
gui: dict[str, str | float | None] = {'name': 'GUI-01 add a book through the running app', 'status': 'FAILED'}
restart: dict[str, str | float | None] = {'name': 'PER-01 real app restart restores entry', 'status': 'NOT RUN'}
try:
    # One installation only: no reinstall or data reset between add and relaunch.
    adb('install', '-r', 'artifacts/production.apk', timeout=180)
    launch()
    tap(await_node('Book title'))
    adb('shell', 'input', 'text', TITLE.replace(' ', '%s'))
    tap(await_node('Add book'))
    await_node(TITLE)
    gui['status'] = 'PASSED'
    gui['duration_seconds'] = round(time.monotonic() - start, 3)
    restart_start = time.monotonic()
    restart['status'] = 'FAILED'
    adb('shell', 'am', 'force-stop', PKG)
    launch()
    await_node(TITLE)
    # Only a verified relaunched app state is eligible for screenshot evidence.
    screenshot = subprocess.run(['adb', 'exec-out', 'screencap', '-p'], capture_output=True, timeout=60)
    if screenshot.returncode or not screenshot.stdout.startswith(b'\x89PNG\r\n\x1a\n'):
        raise AssertionError('No valid PNG screenshot of the relaunched app')
    (ART / 'screenshots').mkdir(exist_ok=True)
    (ART / 'screenshots' / 'gui-smoke.png').write_bytes(screenshot.stdout)
    restart['status'] = 'PASSED'
except Exception as exc:
    case = gui if gui['status'] != 'PASSED' else restart
    case['error'] = str(exc)
    print(f"Android GUI/restart test failed: {exc}", file=sys.stderr)
finally:
    if 'duration_seconds' not in gui:
        gui['duration_seconds'] = round(time.monotonic() - start, 3)
    if restart['status'] != 'NOT RUN':
        restart['duration_seconds'] = round(time.monotonic() - restart_start, 3)
    else:
        restart['duration_seconds'] = None
    (ART / 'device-results.json').write_text(json.dumps([gui, restart], indent=2) + '\n')
    (ART / 'persistence.exit').write_text('0\n' if restart['status'] == 'PASSED' else '1\n')
sys.exit(0 if restart['status'] == 'PASSED' else 1)
