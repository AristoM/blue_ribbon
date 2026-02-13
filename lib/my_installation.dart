import 'package:flutter/material.dart';
import 'package:blue_ribbon/data/services/api_service.dart';
import 'order.dart';
import 'order_details_page.dart';

class MyInstallation extends StatefulWidget {
  const MyInstallation({super.key});

  @override
  State<MyInstallation> createState() => _MyInstallationState();
}

class _MyInstallationState extends State<MyInstallation> {
  List<Order> _upcomingOrders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService().getUpcomingOrders();
      if (response.statusCode == 200 && response.data['success']) {
        final List jobsJson = response.data['data']['jobs'];
        setState(() {
          _upcomingOrders =
              jobsJson.map((json) => Order.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Failed to load upcoming jobs";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "An error occurred: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Text(
            "Upcoming Jobs",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        if (_isLoading)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(48.0),
            child: CircularProgressIndicator(),
          ))
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(child: Text(_error!)),
          )
        else if (_upcomingOrders.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text("No upcoming jobs."),
          )
        else
          ..._upcomingOrders.map((order) => InkWell(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailsPage(jobId: order.jobId),
                    ),
                  );
                  if (result == true) {
                    _loadOrders();
                  }
                },
                child: Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.lineItem.displayName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Customer: ${order.customer.name}",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          "Status: ${order.tracking.currentStatus}",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Scheduled: ${order.scheduledTime.toString().split(' ')[0]}",
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
      ],
    );
  }
}
