#!/usr/bin/env python3
"""Fail a release if Flutter archived successfully but did not export its IPA."""
from pathlib import Path
import plistlib
import re
import sys
import zipfile


def verify_export(folder, build_number):
    packages = list(Path(folder).glob('*.ipa'))
    if len(packages) != 1 or packages[0].stat().st_size == 0:
        raise ValueError('Expected exactly one fresh, nonempty exported IPA')
    with zipfile.ZipFile(packages[0]) as archive:
        records = [item for item in archive.infolist() if re.fullmatch(r'Payload/[^/]+\.app/Info\.plist', item.filename)]
        if len(records) != 1 or records[0].file_size > 2 * 1024 * 1024:
            raise ValueError('IPA app metadata is absent, ambiguous or oversized')
        info = plistlib.loads(archive.read(records[0]))
    if info.get('CFBundleIdentifier') != 'com.justsmartchoice.mobile':
        raise ValueError('Exported IPA has the wrong bundle identifier')
    if str(info.get('CFBundleVersion', '')) != str(build_number):
        raise ValueError('Exported IPA has the wrong build number')
    return packages[0]


if __name__ == '__main__':
    try:
        verify_export(sys.argv[1], sys.argv[2])
        print('Exported IPA metadata verified')
    except (ValueError, OSError, zipfile.BadZipFile, plistlib.InvalidFileException) as error:
        raise SystemExit('Release export rejected: ' + str(error))
