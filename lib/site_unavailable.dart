import 'package:flutter/material.dart';

import 'navigation_policy.dart';

class SiteUnavailable extends StatelessWidget {
  const SiteUnavailable({
    super.key,
    required this.onRetry,
    this.httpError = false,
  });
  final VoidCallback onRetry;
  final bool httpError;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    httpError
                        ? 'This page is unavailable'
                        : 'Unable to connect',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    httpError
                        ? 'The mobile CRM could not load this page. Please try again.'
                        : 'The mobile CRM is not available right now. Check your connection and try again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    NavigationPolicy.crmHost,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xff64748b)),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
