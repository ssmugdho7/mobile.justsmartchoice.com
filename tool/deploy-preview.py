#!/usr/bin/env python3
"""Publish only the client preview wrapper; keep APK/CRM deployments separate."""
import datetime
import pathlib
import subprocess

root = pathlib.Path(__file__).resolve().parent.parent
host = 'scusawco@162.144.17.232'
key = str(pathlib.Path.home() / '.ssh/id_ed25519')
ssh = ['ssh', '-i', key, '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=15', host]
stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
backup = f'/home2/scusawco/codex-backups/mobile-preview-{stamp}'
target = '/home2/scusawco/public_html/mobile/preview'
def remote(script):
    subprocess.run(ssh + ['bash -se'], input=script, text=True, check=True)
remote(f'''test -d /home2/scusawco/public_html/mobile
mkdir -p {backup}
chmod 700 {backup}
test ! -L {target}
mkdir -p {target}
test ! -L {target}/index.html
if [ -f {target}/index.html ]; then cp -p {target}/index.html {backup}/index.html; fi
''')
subprocess.run(['scp', '-i', key, '-o', 'BatchMode=yes', str(root/'website/preview.html'), f'{host}:{backup}/new.html'], check=True)
remote(f'''cat > {backup}/rollback.sh <<'ROLLBACK'
#!/bin/bash
set -eu
if [ -f {backup}/index.html ]; then cp -p {backup}/index.html {target}/index.html; else rm -f {target}/index.html; fi
ROLLBACK
chmod 700 {backup}/rollback.sh
test ! -e {target}/index.html.new
cp {backup}/new.html {target}/index.html.new
chmod 644 {target}/index.html.new
mv {target}/index.html.new {target}/index.html
''')
print('Published https://mobile.justsmartchoice.com/preview/')
print(f'Rollback: bash {backup}/rollback.sh')
