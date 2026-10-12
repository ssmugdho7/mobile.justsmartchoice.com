"""Reject incomplete or integration-test Flutter debug APKs before publication."""
import pathlib
import sys
import zipfile


def validate_testing_apk(path):
    with zipfile.ZipFile(path) as archive:
        required = {'AndroidManifest.xml', 'classes.dex', 'assets/flutter_assets/kernel_blob.bin'}
        if not required.issubset(archive.namelist()):
            raise ValueError('Incomplete testing APK: Android files or Dart program missing')
        kernel = archive.read('assets/flutter_assets/kernel_blob.bin')
        if b'/lib/main.dart' not in kernel or b'/integration_test/' in kernel:
            raise ValueError('Rebuild the normal lib/main.dart APK; this program is not the app entry point')
        if archive.testzip() is not None:
            raise ValueError('APK contains a corrupt entry')


if __name__ == '__main__':
    try:
        validate_testing_apk(pathlib.Path(sys.argv[1]))
    except (ValueError, zipfile.BadZipFile) as error:
        raise SystemExit(str(error))
    print('Normal testing APK program verified')
