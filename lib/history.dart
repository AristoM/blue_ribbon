import 'package:flutter/material.dart';
import 'package:blue_ribbon/data/services/api_service.dart';
import 'order.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  List<Order> _pastOrders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPastOrders();
  }

  Future<void> _loadPastOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService().getUpcomingOrders();
      if (response.statusCode == 200 && response.data['success']) {
        final List jobsJson = response.data['data']['jobs'];
        final allJobs = jobsJson.map((json) => Order.fromJson(json)).toList();
        setState(() {
          _pastOrders =
              allJobs.where((job) => job.jobStatus == 'COMPLETED').toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Failed to load past jobs";
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
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Text(_error!))
            : ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 8.0),
                    child: Text(
                      "Past Jobs",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  if (_pastOrders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text("No past jobs."),
                    )
                  else
                    ..._pastOrders.map((order) => Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 8),
                            leading: const Icon(Icons.check_circle,
                                color: Colors.green),
                            title: Text(
                              order.lineItem.displayName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            subtitle: Text(
                              "Completed: ${order.scheduledTime}",
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                          ),
                        )),
                ],
              );
  }
}
