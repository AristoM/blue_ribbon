import 'package:blue_ribbon/data/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:blue_ribbon/data/models/upsell_product.dart';
import 'order.dart';
import 'advanced_voice_chat_page.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  Order? _order;
  bool _isLoading = true;
  String? _error;
  List<UpsellProduct> _upsellProducts = [];
  bool _isLoadingOffers = true;
  String? _offersError;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService().getOrderDetails(widget.orderId);
      print('OrderDetails API Response: ${response.data}');
      if (response.statusCode == 200 && response.data['success']) {
        final orderData = response.data['data'];
        print('Parsing order details from data: $orderData');
        setState(() {
          _order = Order.fromJson(orderData);
          print(
              'Successfully parsed order: ${_order?.id}, jobId: ${_order?.jobId}');
          _isLoading = false;
        });
        _loadUpsellProducts();
      } else {
        print('OrderDetails API failed or success is false');
        setState(() {
          _error = "Failed to load order details";
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _loadOrder: $e');
      setState(() {
        _error = "An error occurred: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUpsellProducts() async {
    print(
        'Checking if _order is null: _order is ${_order == null ? 'NULL' : 'NOT NULL'}, id: ${_order?.id}');
    if (_order == null) {
      print('Skipping upsell products call because _order is null');
      setState(() {
        _isLoadingOffers = false;
        _offersError = null;
      });
      return;
    }

    print('Starting getUpsellProducts call for id: ${_order!.id}');
    setState(() {
      _isLoadingOffers = true;
      _offersError = null;
    });

    try {
      final response = await ApiService().getUpsellProducts(_order!.id);
      print(
          'UpsellProducts API Response: ${response.statusCode}, Data: ${response.data}');
      if (response.statusCode == 200 && response.data['success']) {
        final List<dynamic> productsJson =
            response.data['data']['products'] ?? [];
        setState(() {
          _upsellProducts =
              productsJson.map((json) => UpsellProduct.fromJson(json)).toList();
          _isLoadingOffers = false;
        });
      } else {
        print('UpsellProducts API failed or success is false');
        setState(() {
          _offersError = "Failed to load offers";
          _isLoadingOffers = false;
        });
      }
    } catch (e) {
      setState(() {
        _offersError = "Error loading offers: $e";
        _isLoadingOffers = false;
      });
    }
  }

  void _handleJobStatus() {
    if (_order == null) return;

    if (_order!.status == "PENDING") {
      _showStartConfirmation();
    } else if (_order!.status == "IN_PROGRESS") {
      _completeJob();
    }
  }

  void _showStartConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm"),
          content: const Text("Are you sure you want to start the job?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Implementation for start job API call would go here
                _loadOrder();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _completeJob() {
    // Implementation for complete job API call would go here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Job completed and moved to history.")),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Order Details")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Order Details")),
        body: Center(child: Text(_error ?? "Order not found")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Details"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection("Customer Details", [
              "Name: ${_order!.customer.name}",
              "Email: ${_order!.customer.email}",
              "Phone: ${_order!.customer.phone}",
              "Address: ${_order!.deliveryAddress}",
            ]),
            const SizedBox(height: 24),
            _buildSection("Product Details", [
              "Product: ${_order!.lineItem.displayName}",
              "SKU: ${_order!.lineItem.sku}",
              "Type: ${_order!.lineItem.type}",
              "Scheduled: ${_order!.scheduledTime.toString().split(' ')[0]}",
            ]),
            const SizedBox(height: 24),
            Text("Technician", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(_order!.technician.photoUrl),
                  radius: 30,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_order!.technician.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    Text("Rating: ${_order!.technician.rating} ⭐",
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection("Customer Notes", [
              "Entrance Code: ${_order!.customerNotes['entrance_code'] ?? 'None'}",
              "Pets: ${_order!.customerNotes['pets'] == true ? 'Yes' : 'No'}",
            ]),
            const SizedBox(height: 24),
            Text("Tracking", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            LinearProgressIndicator(
                value: _order!.tracking.progress.percentage / 100),
            const SizedBox(height: 8),
            Text("Step: ${_order!.tracking.progress.currentStep}"),
            const SizedBox(height: 24),
            _buildSection("Payment", [
              "Installation Fee: \$${_order!.payment.installationFee}",
              "Additional Charges: \$${_order!.payment.additionalCharges}",
              "Total: \$${_order!.payment.total}",
              "Status: ${_order!.payment.status}",
            ]),
            const SizedBox(height: 24),
            Text(
              "Offers for Customer",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildUpsellProductsList(),
            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _order!.status == "COMPLETED" ? null : _handleJobStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _order!.status == "IN_PROGRESS"
                          ? Colors.green
                          : Colors.black,
                    ),
                    child: Text(
                        _order!.status == "IN_PROGRESS" ? "Complete" : "Start"),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.mic, size: 32, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        opaque: false,
                        barrierDismissible: true,
                        pageBuilder: (context, _, __) =>
                            AdvancedVoiceChatPage(jobId: _order!.id),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...details.map((detail) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(detail, style: Theme.of(context).textTheme.bodyLarge),
            )),
      ],
    );
  }

  Widget _buildUpsellProductsList() {
    if (_isLoadingOffers) {
      return const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_offersError != null) {
      return SizedBox(
        height: 150,
        child: Center(child: Text(_offersError!)),
      );
    }

    if (_upsellProducts.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text("No offers available for this order.")),
      );
    }

    return SizedBox(
      height: 220, // Increased height to accommodate details
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _upsellProducts.length,
        itemBuilder: (context, index) {
          final product = _upsellProducts[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    product.imageUrl,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 100,
                      color: Colors.grey.shade200,
                      child:
                          const Center(child: Icon(Icons.image_not_supported)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "\$${product.price.toStringAsFixed(2)}",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
