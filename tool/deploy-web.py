#!/usr/bin/env python3
"""Publish only the app download site; never deploy or modify the CRM backend."""
import hashlib
import json
import pathlib
import shlex
import subprocess
import tempfile
import datetime
import zipfile
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
HOST = 'scusawco@162.144.17.232'
DOCROOT = '/home2/scusawco/public_html/mobile'
KEY = pathlib.Path.home() / '.ssh/id_ed25519'
SSH = ['ssh', '-i', str(KEY), '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=15', HOST]
APK = ROOT / 'dist/smart-choice-mobile-debug.apk'
VERSION = re.search(r'^version: (\d+\.\d+\.\d+)\+', (ROOT/'pubspec.yaml').read_text(), re.M).group(1)

def run(args, **kwargs):
    return subprocess.run(args, check=True, **kwargs)

def remote(script):
    return run(SSH + ['bash -se'], input=script, text=True)

def sha(path):
    with path.open('rb') as f:
        digest = hashlib.sha256()
        for chunk in iter(lambda: f.read(1024 * 1024), b''):
            digest.update(chunk)
        return digest.hexdigest()

if not APK.is_file():
    raise SystemExit('Build the normal testing APK first with tool/build-apk.sh')
with zipfile.ZipFile(APK) as z:
    if not {'AndroidManifest.xml', 'classes.dex'}.issubset(z.namelist()):
        raise SystemExit('Invalid Android APK')
if subprocess.check_output(['git', 'status', '--porcelain'], cwd=ROOT, text=True).strip():
    raise SystemExit('Commit/review source before deployment; worktree must be clean')
commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
# Reject integration-test APKs and stale source builds before publishing.
marker = ROOT / 'dist/build-source.json'
if not marker.exists() or json.loads(marker.read_text()).get('commit') != commit:
    raise SystemExit('Rebuild the normal APK after committing source')
if json.loads(marker.read_text()).get('sha256') != sha(APK):
    raise SystemExit('APK changed after the normal build')
stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
backup = f'/home2/scusawco/codex-backups/mobile-app-{stamp}'
stage = f'/home2/scusawco/codex-backups/mobile-stage-{stamp}'
remote(f'''test -d {DOCROOT}
test ! -L {DOCROOT}
mkdir -p {backup} {stage}
chmod 700 {backup} {stage}
''')
files = {'index.html': ROOT/'website/index.html', 'index.php': ROOT/'website/index.php',
         'downloads/.htaccess': ROOT/'website/downloads.htaccess',
         'downloads/smart-choice-mobile.apk': APK,
         f'downloads/smart-choice-mobile-{VERSION}.apk': APK}
with tempfile.TemporaryDirectory() as td:
    release = pathlib.Path(td)/'release.json'
    release.write_text(json.dumps({'version':VERSION, 'package':'com.justsmartchoice.mobile',
        'build':'debug-testing', 'commit':commit, 'sha256':sha(APK),
        'download':f'https://mobile.justsmartchoice.com/downloads/smart-choice-mobile-{VERSION}.apk'}, indent=2)+'\n')
    files['release.json'] = release
    remote(f'mkdir -p {stage}/downloads\n')
    uploaded = {}
    for rel, path in files.items():
        if path in uploaded:
            remote(f'cp {stage}/{uploaded[path]} {stage}/{rel}\n')
            continue
        uploaded[path] = rel
        run(['scp', '-i', str(KEY), '-o', 'BatchMode=yes', str(path), f'{HOST}:{stage}/{rel}'])
    # Explicit-file backup and atomic replacement. Rollback restores old contents
    # or removes only newly published files. Preserve SSL and unrelated user files.
    rollback = ['#!/bin/bash', 'set -eu']
    backups = []
    replacements = []
    script = ['set -eu', f'cd {DOCROOT}', 'test ! -L downloads', 'mkdir -p downloads']
    for rel, path in files.items():
        qrel = shlex.quote(rel)
        old = f'{backup}/{rel}'
        rollback.append(f'if [ -f {shlex.quote(old)} ]; then cp -p {shlex.quote(old)} {shlex.quote(DOCROOT+"/"+rel)}; else rm -f {shlex.quote(DOCROOT+"/"+rel)}; fi')
        backups += [f'test ! -L {qrel}', f'mkdir -p {shlex.quote(str(pathlib.PurePosixPath(old).parent))}',
                    f'if [ -f {qrel} ]; then cp -p {qrel} {shlex.quote(old)}; fi']
        replacements += [f"echo '{sha(path)}  {stage}/{rel}' | sha256sum --check --status",
                   f'test ! -e {qrel}.new', f'test ! -L {qrel}.new', f'cp {stage}/{rel} {qrel}.new', f'chmod 644 {qrel}.new',
                   f'mv {qrel}.new {qrel}']
    rollback_file = pathlib.Path(td)/'rollback.sh'
    rollback_file.write_text('\n'.join(rollback)+'\n')
    run(['scp', '-i', str(KEY), '-o', 'BatchMode=yes', str(rollback_file), f'{HOST}:{backup}/rollback.sh'])
    script += backups + [f"trap 'bash {backup}/rollback.sh' ERR"] + replacements
    script += [f'chmod 700 {backup}/rollback.sh', f'sha256sum downloads/smart-choice-mobile.apk', f'rm -rf {stage}']
    remote('\n'.join(script)+'\n')
print('Published https://mobile.justsmartchoice.com')
print(f'Rollback on Bluehost: bash {backup}/rollback.sh')
