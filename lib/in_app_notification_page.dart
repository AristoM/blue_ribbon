import 'package:flutter/material.dart';

class InAppNotificationPage extends StatelessWidget {
  const InAppNotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Installation Request"),
        forceMaterialTransparency: true,
      ),
      body: Column(
        children: [
          // Map Placeholder
          Container(
            height: 300,
            width: double.infinity,
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 50, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text("Map View Placeholder",
                    style: TextStyle(color: Colors.grey[600], fontSize: 18)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Installation Request",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow(
                      context, Icons.person, "Customer", "John Doe"),
                  _buildDetailRow(context, Icons.location_on, "Address",
                      "123 Main St, Springfield"),
                  _buildDetailRow(
                      context, Icons.calendar_today, "Date", "Jan 30, 2026"),
                  const Divider(height: 48),
                  Text(
                    "Cost Information",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(context, Icons.attach_money, "Estimated Cost",
                      "\$150.00"),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Accept Request"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey)),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
