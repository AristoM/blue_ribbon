import 'package:flutter/material.dart';

import 'order.dart';

class History extends StatelessWidget {
  const History({super.key});

  @override
  Widget build(BuildContext context) {
    final pastOrders = OrderRepository.getPastOrders();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Text(
            "Past Jobs",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        if (pastOrders.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text("No past jobs."),
          )
        else
          ...pastOrders.map((order) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(
                    order.lineItem.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    "Completed on: ${order.scheduledTime.toString().split(' ')[0]}",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              )),
      ],
    );
  }
}
