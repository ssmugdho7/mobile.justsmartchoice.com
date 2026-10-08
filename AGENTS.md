# Smart Choice Android app

- This is a separate Flutter repository for the app, not the PHP CRM checkout.
- `crm.justsmartchoice.com` is the authoritative live CRM. `mobile.justsmartchoice.com` distributes APKs; `dev.justsmartchoice.com` is not this app's backend.
- Use `origin/dev` for development. Do not change CRM authentication, permissions, databases or production source as part of an app UI task.
- Keep credentials, cookies, private document URLs/PDFs, SDK paths and signing keys out of commits and public artifacts.
- Do not run production payment, signature, approval or notification workflows as automated smoke tests.
- Run `tool/check.sh` and build a normal `lib/main.dart` APK after integration tests, which replace the test build entry point.
- Publish only the explicit files through `tool/deploy-web.py`, with private backups/rollback. Preserve Bluehost SSL/configuration and unrelated files.
- Testing APKs are debug-signed. A store/production release requires separate private release-signing configuration; never pretend debug signing is a production release.
