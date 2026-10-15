#!/usr/bin/env python3
"""Validate decoded App Store profile metadata; never read a private key."""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import plistlib
import re


def validate(profile, team, bundle, certificate, now=None):
    now = now or datetime.now(timezone.utc)
    if not re.fullmatch(r'[A-Z0-9]{10}', team):
        raise ValueError('Invalid Apple team identifier')
    if profile.get('TeamIdentifier') != [team]:
        raise ValueError('Profile belongs to a different Apple team')
    entitlements = profile.get('Entitlements', {})
    prefixes = profile.get('ApplicationIdentifierPrefix', [])
    if entitlements.get('application-identifier') not in [p + '.' + bundle for p in prefixes]:
        raise ValueError('Profile must match the exact app bundle identifier')
    if entitlements.get('com.apple.developer.team-identifier') != team:
        raise ValueError('Profile entitlement belongs to a different team')
    if entitlements.get('get-task-allow') is not False:
        raise ValueError('Development profiles are not distribution profiles')
    if 'ProvisionedDevices' in profile or profile.get('ProvisionsAllDevices', False):
        raise ValueError('Use an App Store profile, not ad hoc or enterprise')
    for key in ('CreationDate', 'ExpirationDate'):
        if not isinstance(profile.get(key), datetime):
            raise ValueError('Profile dates are missing')
    created = profile['CreationDate'].replace(tzinfo=timezone.utc)
    expires = profile['ExpirationDate'].replace(tzinfo=timezone.utc)
    if created > now or expires <= now:
        raise ValueError('Profile is expired or not yet valid')
    if certificate not in profile.get('DeveloperCertificates', []):
        raise ValueError('Distribution certificate does not match the profile')
    uuid = profile.get('UUID', '')
    if not re.fullmatch(r'[A-Fa-f0-9-]{36}', uuid):
        raise ValueError('Profile UUID is invalid')
    return uuid


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('profile')
    parser.add_argument('certificate')
    parser.add_argument('export_options')
    args = parser.parse_args()
    import os
    team = os.environ['IOS_TEAM_ID']
    bundle = 'com.justsmartchoice.mobile'
    try:
        profile = plistlib.loads(Path(args.profile).read_bytes())
        uuid = validate(profile, team, bundle, Path(args.certificate).read_bytes())
        options = {'method': 'app-store-connect', 'destination': 'export',
                   'signingStyle': 'manual', 'teamID': team,
                   'provisioningProfiles': {bundle: uuid},
                   'manageAppVersionAndBuildNumber': False, 'uploadSymbols': True}
        Path(args.export_options).write_bytes(plistlib.dumps(options))
        print(uuid)
    except (ValueError, KeyError, TypeError, plistlib.InvalidFileException) as error:
        raise SystemExit('Signing profile rejected: ' + str(error))
