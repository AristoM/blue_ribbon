import 'package:blue_ribbon/bloc/auth/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'in_app_notification_page.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Text(
            "Account & Settings",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading:
                const Icon(Icons.notifications_active, color: Colors.orange),
            title: Text(
              'Simulate Notification',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const InAppNotificationPage()),
              );
            },
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              'Logout',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.red),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
        ),
      ],
    );
  }
}
