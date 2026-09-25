import datetime, json, os, pathlib, subprocess

root = pathlib.Path('.')
out = root / 'artifacts'
(out / 'screenshots').mkdir(parents=True, exist_ok=True)
def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True).stdout.strip()
flutter = run(['flutter', '--version']).splitlines()[0] or 'unknown'
commit = os.getenv('GITHUB_SHA') or run(['git', 'rev-parse', 'HEAD'])
results = {name: os.getenv(env, 'not_run') for name, env in [('analysis','ANALYZE'),('unit_bdd_widget','FAST_TESTS'),('android_gui_persistence','GUI_TESTS'),('apk_build','APK_BUILD')]}
statuses = {k: ('PASSED' if v == 'success' else 'FAILED' if v == 'failure' else 'NOT RUN') for k,v in results.items()}
overall = 'PASSED' if all(v == 'success' for v in results.values()) else 'FAILED' if any(v == 'failure' for v in results.values()) else 'INCOMPLETE'
now = datetime.datetime.now(datetime.timezone.utc).astimezone().isoformat()
run_url = os.getenv('REPORT_ARTIFACT_URL','')
info = {'workflow_run':os.getenv('GITHUB_RUN_ID','local'), 'commit_sha':commit, 'timestamp':now, 'flutter_version':flutter, 'platform':'Android emulator (API 35) and Ubuntu Linux', 'cases': [{'name':k,'status':statuses[k],'duration_seconds':None} for k in results], 'overall':overall, 'artifacts_url':run_url, 'screenshots':['screenshots/gui-smoke.png'] if (out/'screenshots/gui-smoke.png').exists() else [], 'note':'Durations are unavailable when test reporter output did not provide per-case timing; see workflow step logs for durations and failure details.'}
(out/'report.json').write_text(json.dumps(info,indent=2)+'\n')
md = ['# Flutter Testability Lab — CI report','',f"- Workflow run: [{info['workflow_run']}]({run_url})",f"- Commit: `{commit}`",f"- Timestamp: {now}",f"- Flutter: {flutter}",f"- Platform: {info['platform']}",'',f"## Overall: {overall}",'','| Test group | Status | Duration |','|---|---|---|']
for k in results: md.append(f"| {k} | {statuses[k]} | Not reported |")
md += ['', '## Failure details','See the named workflow steps for compiler/test output; no failed or unrun check is classified as passed.','', '## GUI screenshot', ('- `screenshots/gui-smoke.png` (in this run artifact)' if info['screenshots'] else '- NOT GENERATED (GUI test may not have run or failed before capture)'), '', f"## Downloadable artifacts\n[Run artifacts and logs]({run_url})"]
(out/'report.md').write_text('\n'.join(md)+'\n')
if os.getenv('GITHUB_STEP_SUMMARY'): pathlib.Path(os.environ['GITHUB_STEP_SUMMARY']).write_text('\n'.join(md)+'\n')
