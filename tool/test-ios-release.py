#!/usr/bin/env python3
import copy
from datetime import datetime, timedelta, timezone
import importlib.util
from pathlib import Path
import unittest
import tempfile
import plistlib
import zipfile

spec = importlib.util.spec_from_file_location('profile_validation', Path(__file__).with_name('validate-ios-profile.py'))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

class ProfileValidationTests(unittest.TestCase):
    def setUp(self):
        self.now = datetime(2026, 10, 15, tzinfo=timezone.utc)
        self.team = 'A1B2C3D4E5'
        self.bundle = 'com.justsmartchoice.mobile'
        self.cert = b'synthetic public certificate fixture; not a real certificate'
        self.profile = {
            'TeamIdentifier': [self.team], 'ApplicationIdentifierPrefix': [self.team],
            'UUID': '12345678-1234-1234-1234-123456789ABC',
            'CreationDate': (self.now-timedelta(days=1)).replace(tzinfo=None),
            'ExpirationDate': (self.now+timedelta(days=90)).replace(tzinfo=None),
            'DeveloperCertificates': [self.cert],
            'Entitlements': {'application-identifier': self.team+'.'+self.bundle,
                             'com.apple.developer.team-identifier': self.team,
                             'get-task-allow': False}}
    def run_validation(self, profile=None, **kwargs):
        return module.validate(profile or self.profile, kwargs.get('team', self.team),
                               kwargs.get('bundle', self.bundle), kwargs.get('certificate', self.cert), self.now)
    def test_valid_exact_profile(self):
        self.assertEqual(self.run_validation(), self.profile['UUID'])
    def test_legacy_prefix_still_requires_team(self):
        self.profile['ApplicationIdentifierPrefix'] = ['LEGACY1234']
        self.profile['Entitlements']['application-identifier'] = 'LEGACY1234.'+self.bundle
        self.run_validation()
    def test_reject_unsafe_profiles(self):
        mutations = [
            lambda p: p.update(TeamIdentifier=['Z9Y8X7W6V5']),
            lambda p: p['Entitlements'].update({'application-identifier': self.team+'.*'}),
            lambda p: p['Entitlements'].update({'com.apple.developer.team-identifier': 'Z9Y8X7W6V5'}),
            lambda p: p['Entitlements'].update({'get-task-allow': True}),
            lambda p: p['Entitlements'].pop('get-task-allow'),
            lambda p: p.update(ProvisionedDevices=[]),
            lambda p: p.update(ProvisionsAllDevices=True),
            lambda p: p.update(ExpirationDate=(self.now-timedelta(seconds=1)).replace(tzinfo=None)),
            lambda p: p.update(CreationDate=(self.now+timedelta(days=1)).replace(tzinfo=None)),
            lambda p: p.pop('CreationDate'),
            lambda p: p.update(DeveloperCertificates=[b'other certificate']),
            lambda p: p.update(UUID='../unsafe'),
        ]
        for mutation in mutations:
            with self.subTest(mutation=mutations.index(mutation)):
                profile = copy.deepcopy(self.profile)
                mutation(profile)
                with self.assertRaises(ValueError): self.run_validation(profile)
    def test_invalid_team_input(self):
        with self.assertRaises(ValueError): self.run_validation(team='invalid')

export_spec = importlib.util.spec_from_file_location('export_validation', Path(__file__).with_name('verify-ios-export.py'))
exports = importlib.util.module_from_spec(export_spec)
export_spec.loader.exec_module(exports)

class ExportValidationTests(unittest.TestCase):
    def test_expected_package_and_invalid_exports(self):
        with tempfile.TemporaryDirectory() as folder:
            target = Path(folder)/'app.ipa'
            def write(bundle='com.justsmartchoice.mobile', build='10'):
                with zipfile.ZipFile(target, 'w') as archive:
                    archive.writestr('Payload/Runner.app/Info.plist', plistlib.dumps({'CFBundleIdentifier':bundle,'CFBundleVersion':build}))
            with self.assertRaises(ValueError): exports.verify_export(folder, '10')
            target.write_bytes(b'')
            with self.assertRaises(ValueError): exports.verify_export(folder, '10')
            write(); self.assertEqual(exports.verify_export(folder, '10'), target)
            write(bundle='com.example.other')
            with self.assertRaises(ValueError): exports.verify_export(folder, '10')
            write(build='9')
            with self.assertRaises(ValueError): exports.verify_export(folder, '10')
            write(); (Path(folder)/'old.ipa').write_bytes(target.read_bytes())
            with self.assertRaises(ValueError): exports.verify_export(folder, '10')

if __name__ == '__main__': unittest.main()
