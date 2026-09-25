import datetime
import json
import os
import pathlib
import subprocess

root = pathlib.Path('.')
out = root / 'artifacts'
(out / 'screenshots').mkdir(parents=True, exist_ok=True)

def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True).stdout.strip()

def read_test_events(filename):
    path = out / filename
    if not path.exists():
        return []
    started = {}
    cases = []
    for line in path.read_text(errors='replace').splitlines():
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if event.get('type') == 'testStart':
            test = event.get('test', {})
            started[event.get('testID')] = (test.get('name', 'unknown'), event.get('time', 0))
        elif event.get('type') == 'testDone':
            name, begin = started.get(event.get('testID'), (f"test-{event.get('testID')}", event.get('time', 0)))
            result = 'NOT RUN' if event.get('skipped') else ('PASSED' if event.get('result') == 'success' else 'FAILED')
            cases.append({'name': name, 'status': result, 'duration_seconds': round(max(0, event.get('time', begin) - begin) / 1000, 3), 'error': str(event.get('error', ''))[:2000] if result == 'FAILED' else None})
    return cases

flutter = run(['flutter', '--version']).splitlines()[0] or 'unknown'
commit = os.getenv('GITHUB_SHA') or run(['git', 'rev-parse', 'HEAD'])
results = {name: os.getenv(env, 'not_run') for name, env in [('analysis', 'ANALYZE'), ('unit_bdd_widget_group', 'FAST_TESTS'), ('android_device_tests', 'GUI_TESTS'), ('apk_build', 'APK_BUILD')]}
statuses = {k: ('PASSED' if v == 'success' else 'FAILED' if v == 'failure' else 'NOT RUN') for k, v in results.items()}
cases = read_test_events('fast-tests.json') + read_test_events('bdd-tests.json') + read_test_events('gui-tests.json')
# The process restart check is a separate assertion performed after force-stop/relaunch.
persist_result = out / 'persistence.exit'
if os.getenv('GUI_TESTS') not in ('', 'not_run', 'skipped'):
    value = persist_result.read_text().strip() if persist_result.exists() else None
    cases.append({'name': 'PER-01 process restart restores persisted entry', 'status': 'PASSED' if value == '0' else 'FAILED' if value is not None else 'NOT RUN', 'duration_seconds': None})
all_required = list(statuses.values()) + [case['status'] for case in cases]
overall = 'PASSED' if all(s == 'PASSED' for s in all_required) and cases else 'FAILED' if any(s == 'FAILED' for s in all_required) else 'INCOMPLETE'
now = datetime.datetime.now(datetime.timezone.utc).astimezone().isoformat()
run_url = os.getenv('REPORT_ARTIFACT_URL', '')
failure_details = []
for case in cases:
    if case['status'] == 'FAILED':
        failure_details.append(f"Test case failed: {case['name']}\\n{case.get('error') or ''}")
for group, status in statuses.items():
    if status == 'FAILED':
        failure_details.append(f"Check failed: {group}; inspect the matching workflow step output.")
for filename in ['fast-tests.stderr', 'bdd-tests.stderr', 'gui-tests.stderr']:
    path = out / filename
    if path.exists() and path.stat().st_size:
        failure_details.append(f"{filename}: {path.read_text(errors='replace')[-4000:]}")
info = {
    'workflow_run': os.getenv('GITHUB_RUN_ID', 'local'), 'commit_sha': commit,
    'timestamp': now, 'flutter_version': flutter,
    'platform': 'Android emulator (API 35) and Ubuntu Linux',
    'cases': cases, 'groups': [{'name': k, 'status': statuses[k]} for k in results],
    'overall': overall, 'artifacts_url': run_url,
    'screenshots': ['screenshots/gui-smoke.png'] if (out / 'screenshots/gui-smoke.png').exists() else [],
    'failure_logs': ['fast-tests.stderr', 'bdd-tests.stderr', 'gui-tests.stderr'],
    'failure_details': failure_details,
}
(out / 'report.json').write_text(json.dumps(info, indent=2) + '\n')
md = ['# Flutter Testability Lab — CI report', '', f"- Workflow run: [{info['workflow_run']}]({run_url})", f"- Commit: `{commit}`", f"- Timestamp: {now}", f"- Flutter: {flutter}", f"- Platform: {info['platform']}", '', f"## Overall: {overall}", '', '### Checks', '', '| Check | Status |', '|---|---|']
for key in results:
    md.append(f'| {key} | {statuses[key]} |')
md += ['', '### Executed test cases', '', '| Case | Status | Duration (s) |', '|---|---|---:|']
if cases:
    for case in cases:
        duration = 'Not available' if case['duration_seconds'] is None else f"{case['duration_seconds']:.3f}"
        md.append(f"| {case['name']} | {case['status']} | {duration} |")
else:
    md.append('| No test events recorded | NOT RUN | — |')
md += ['', '### Failure details']
if info['failure_details']:
    md.extend(['```text', *info['failure_details'], '```'])
else:
    md.append('No failure details recorded; failed and unrun checks are never represented as passing.')
md += ['', '### GUI screenshot']
md.append('- `screenshots/gui-smoke.png` (in this run artifact)' if info['screenshots'] else '- NOT GENERATED (GUI test may not have run or failed before capture)')
md += ['', '### Downloadable artifacts', f"[Run artifacts and logs]({run_url})"]
report = '\n'.join(md) + '\n'
(out / 'report.md').write_text(report)
if os.getenv('GITHUB_STEP_SUMMARY'):
    pathlib.Path(os.environ['GITHUB_STEP_SUMMARY']).write_text(report)
