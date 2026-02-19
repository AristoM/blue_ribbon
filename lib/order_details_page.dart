import 'package:blue_ribbon/data/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:blue_ribbon/data/models/upsell_product.dart';
import 'package:share_plus/share_plus.dart';
import 'order.dart';
import 'package:blue_ribbon/advanced_voice_chat_page.dart';
import 'package:blue_ribbon/job_chat_page.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailsPage extends StatefulWidget {
  final String? jobId;

  const OrderDetailsPage({super.key, required this.jobId});

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
      final response = await ApiService().getJobDetails(widget.jobId!);
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

  Future<void> _openMap(double lat, double lng, String address) async {
    String query;
    if (lat != 0.0 && lng != 0.0) {
      query = "$lat,$lng";
    } else if (address.isNotEmpty) {
      query = Uri.encodeComponent(address);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No location information available")),
        );
      }
      return;
    }

    final String googleMapsUrl =
        "https://www.google.com/maps/search/?api=1&query=$query";
    final String appleMapsUrl = "https://maps.apple.com/?q=$query";
    final String geoUrl = "geo:0,0?q=$query";

    try {
      // Try to launch geo URL first (often opens native map app)
      if (await launchUrl(Uri.parse(geoUrl))) {
        return;
      }
      // If geo URL fails, try Google Maps
      if (await launchUrl(Uri.parse(googleMapsUrl))) {
        return;
      }
      // If Google Maps fails, try Apple Maps
      if (await launchUrl(Uri.parse(appleMapsUrl))) {
        return;
      }
      // If all attempts fail
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open any map application.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not open maps: $e")),
        );
      }
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
        appBar: AppBar(title: const Text("Job Details")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Job Details")),
        body: Center(child: Text(_error ?? "Order not found")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              "Job Details",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              _order?.jobId ?? _order?.orderId ?? 'JOB-N/A',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                _order!.status.replaceAll('_', ' '),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductCard(),
            const SizedBox(height: 16),
            _buildCustomerCard(),
            const SizedBox(height: 16),
            _buildSummaryRow(),
            const SizedBox(height: 24),
            Text(
              "Offers for Customer",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildUpsellProductsList(),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _order!.status == "COMPLETED"
                          ? null
                          : _handleJobStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        _order!.status == "IN_PROGRESS"
                            ? "Complete Job"
                            : "Start Job",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline,
                      size: 28, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JobChatPage(jobId: _order!.id),
                      ),
                    );
                  },
                ),
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

  Widget _buildProductCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _order!.lineItem.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _order!.lineItem.displayName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "SKU: ${_order!.lineItem.sku}",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${_order!.lineItem.dimensions.lengthCm}x${_order!.lineItem.dimensions.widthCm}x${_order!.lineItem.dimensions.depthCm} cm | ${_order!.lineItem.weightKg} kg",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.shade700,
                  child: Text(
                    _order!.customer.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _order!.customer.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(_order!.customer.phone,
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                      Text(
                        _order!.customer.email,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Colors.orange, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _order!.location.address,
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (_order!.customerNotes['entrance_code'] != null &&
                          _order!.customerNotes['entrance_code']
                              .toString()
                              .isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "Note: Gate code: ${_order!.customerNotes['entrance_code']}",
                            style: TextStyle(
                                color: Colors.grey.shade700, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _openMap(_order!.location.lat,
                    _order!.location.lng, _order!.location.address),
                icon: const Icon(Icons.directions, size: 18),
                label: const Text("Get Directions",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue.shade700,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
              icon: Icons.calendar_today,
              label: "DATE",
              value: _order!.scheduledTime.toString().split(' ')[0],
              iconColor: Colors.blue,
            ),
            _buildSummaryItem(
              icon: Icons.access_time,
              label: "EST. TIME",
              value: "${_order!.estimatedDurationHours} hrs",
              iconColor: Colors.blue,
            ),
            _buildSummaryItem(
              icon: Icons.monetization_on_outlined,
              label: "PAYMENT",
              value: "\$${_order!.payment.total.toInt()}",
              iconColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
      {required IconData icon,
      required String label,
      required String value,
      required Color iconColor}) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
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
      height: 240, // Increased height to safely accommodate padding
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      product.imageUrl,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 100,
                        color: Colors.grey.shade200,
                        child: const Center(
                            child: Icon(Icons.image_not_supported)),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
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
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "\$${product.price.toStringAsFixed(2)}",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                if (product.strikeThroughPrice != null) ...[
                                  Text(
                                    "\$${product.strikeThroughPrice!.toStringAsFixed(2)}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.grey,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.share,
                                size: 18, color: Colors.blue),
                            onPressed: () {
                              if (product.shareLink.isNotEmpty) {
                                Share.share(
                                  "Check out this Samsung Product: ${product.displayName}\n${product.shareLink}",
                                  subject: "Samsung Upsell Product",
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text("Share link not available")),
                                );
                              }
                            },
                          ),
                        ],
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
