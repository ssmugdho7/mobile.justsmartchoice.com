import 'package:flutter/material.dart';

/// Public destinations already used by the Smart Choice website.
enum QuickLink {
  staff(
    'Staff portal',
    Icons.badge_outlined,
    'https://crm.justsmartchoice.com/admin',
  ),
  customer(
    'Customer portal',
    Icons.person_outline,
    'https://crm.justsmartchoice.com/clients',
  ),
  callOffice('Call office', Icons.phone_outlined, 'tel:+17277553786'),
  appointment(
    'Make appointment',
    Icons.calendar_month_outlined,
    'https://crm.justsmartchoice.com/appointly/appointments',
  ),
  toolbox(
    'Toolbox',
    Icons.handyman_outlined,
    'https://justsmartchoice.com/toolbox.php',
  );

  const QuickLink(this.label, this.icon, this.destination);
  final String label;
  final IconData icon;
  final String destination;
  Uri get uri => Uri.parse(destination);

  static String labelFor(Uri? uri) {
    for (final link in values) {
      if (link.uri == uri) return link.label;
    }
    if (uri?.host == 'crm.justsmartchoice.com' &&
        uri?.path == '/appointly/appointments_public/book') {
      return 'Book an Appointment';
    }
    if (uri?.host == 'justsmartchoice.com' && uri?.path == '/contacts.php') {
      return 'Contact Us';
    }
    return 'CRM';
  }
}

class QuickLinksMenu extends StatelessWidget {
  const QuickLinksMenu({super.key, required this.onSelected, this.onAbout});
  final ValueChanged<QuickLink> onSelected;
  final VoidCallback? onAbout;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Quick links',
    onSelected: (value) {
      if (value == 'about') {
        onAbout?.call();
      } else {
        onSelected(QuickLink.values.byName(value));
      }
    },
    itemBuilder: (_) => [
      for (final link in QuickLink.values)
        PopupMenuItem(
          value: link.name,
          child: Row(
            children: [
              Icon(link.icon, color: const Color(0xff107566), size: 21),
              const SizedBox(width: 12),
              Flexible(child: Text(link.label)),
            ],
          ),
        ),
      if (onAbout != null)
        const PopupMenuItem(value: 'about', child: Text('App information')),
    ],
  );
}
