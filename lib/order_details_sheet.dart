import 'package:flutter/material.dart';
import 'package:blue_ribbon/data/services/api_service.dart';
import 'package:blue_ribbon/order.dart';
import 'package:blue_ribbon/data/models/upsell_product.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:blue_ribbon/job_chat_page.dart';

class OrderDetailsSheet extends StatefulWidget {
  final String orderId;

  const OrderDetailsSheet({super.key, required this.orderId});

  @override
  State<OrderDetailsSheet> createState() => _OrderDetailsSheetState();
}

class _OrderDetailsSheetState extends State<OrderDetailsSheet> {
  Order? _order;
  bool _isLoading = true;
  String? _error;
  List<UpsellProduct> _upsellProducts = [];

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
      if (response.statusCode == 200 && response.data['success']) {
        final orderData = response.data['data'];
        setState(() {
          _order = Order.fromJson(orderData);
          _isLoading = false;
        });
        _loadUpsellProducts(_order!.id);
      } else {
        setState(() {
          _error = "Failed to load order details";
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

  Future<void> _loadUpsellProducts(String jobId) async {
    // Assuming upsell products might use jobId, but we have orderId mostly.
    // However, Order object has jobId.
    if (_order?.jobId == null) {
      return;
    }

    try {
      final response = await ApiService().getUpsellProducts(_order!.jobId!);
      if (response.statusCode == 200 && response.data['success']) {
        final List<dynamic> productsJson =
            response.data['data']['products'] ?? [];
        if (mounted) {
          setState(() {
            _upsellProducts = productsJson
                .map((json) => UpsellProduct.fromJson(json))
                .toList();
          });
        }
      }
    } catch (e) {
      // Ignore errors for upsell products
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 400,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _order == null) {
      return SizedBox(
        height: 400,
        child: Center(child: Text(_error ?? "Order not found")),
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Stack(
            children: [
              ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildSitePhotosSection(),
                  const SizedBox(height: 24),
                  _buildCustomerNotesSection(),
                  const SizedBox(height: 24),
                  _buildQuestionnaireSection(),
                  const SizedBox(height: 24),
                  _buildToolsSection(),
                  const SizedBox(height: 24),
                  _buildPhotoVerifyButton(),
                  const SizedBox(height: 24),
                  _buildUpsellSection(),
                ],
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomBar(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _order!.lineItem.displayName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _order!.status,
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 40), // Spacer for close button
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _order!.orderId,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 13,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSitePhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.image_outlined, size: 20, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text(
              "SITE PHOTOS (2)",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildPhotoPlaceholder(),
              const SizedBox(width: 12),
              _buildPhotoPlaceholder(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        image: const DecorationImage(
          image: NetworkImage('https://placehold.co/600x400/png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(Icons.image, size: 40, color: Colors.grey.shade400),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.black)),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios,
                    size: 16, color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerNotesSection() {
    final notes = _order!.customerNotes['special_instructions']?.toString();
    if (notes == null || notes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.note_alt_outlined,
                size: 20, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text(
              "CUSTOMER NOTES",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBE6), // Light yellow background
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "\"$notes\"",
            style: TextStyle(
              color: Colors.brown.shade900.withOpacity(0.8),
              fontSize: 14,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionnaireSection() {
    // Parsing questionnaire answers from customerNotes if possible
    // The JSON structure says customer_notes: { questionnaire_answers: ... }
    // Order model puts this into customerNotes map.

    // In the screenshot: Water Supply, Drain Routing, Electrical Setup etc.
    // Let's assume these are keys in the questionnaire_answers map

    final answers = _order!.customerNotes['questionnaire_answers'];
    if (answers == null || answers is! Map) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.assignment_outlined,
                size: 20, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text(
              "QUESTIONNAIRE ANSWERS",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: (answers as Map<String, dynamic>).entries.map((entry) {
              return _buildQuestionnaireRow(entry.key, entry.value.toString());
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionnaireRow(String label, String value) {
    // Format label: space_measurements -> Space Measurements
    final formattedLabel = label
        .split('_')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            formattedLabel,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.book_outlined, size: 20, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text(
              "TOOLS & RESOURCES",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child:
                    _buildToolButton("AI Chat", Icons.chat_bubble_outline, () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  opaque: false,
                  barrierDismissible: true,
                  pageBuilder: (context, _, __) =>
                      JobChatPage(jobId: _order!.id),
                ),
              );
            })),
            const SizedBox(width: 12),
            Expanded(
                child: _buildToolButton(
                    "Install Guide", Icons.menu_book_outlined, () {})),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildToolButton(
                    "Product Manual", Icons.description_outlined, () {
              // Open manual URL if exists
              if (_order!.lineItem.manualUrl.isNotEmpty) {
                launchUrl(Uri.parse(_order!.lineItem.manualUrl));
              }
            }, iconColor: Colors.purple)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildToolButton(
                    "Video Support", Icons.videocam_outlined, () {},
                    iconColor: Colors.orange)),
          ],
        ),
      ],
    );
  }

  Widget _buildToolButton(String label, IconData icon, VoidCallback onTap,
      {Color? iconColor}) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: iconColor ?? Colors.blue),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: iconColor ?? Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoVerifyButton() {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
      label: const Text(
        "Photo Verify",
        style: TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  Widget _buildUpsellSection() {
    if (_upsellProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 20, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text(
              "UPSELL OPPORTUNITIES",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._upsellProducts.map((product) => _buildUpsellCard(product)),
      ],
    );
  }

  Widget _buildUpsellCard(UpsellProduct product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (product.strikeThroughPrice != null)
                      Text(
                        "\$${product.strikeThroughPrice!.toInt()}",
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(width: 4),
                    Text(
                      "\$${product.price.toInt()}",
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (product.strikeThroughPrice != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        "-${((1 - product.price / product.strikeThroughPrice!) * 100).toInt()}%",
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.inventory,
                      size: 12, color: Colors.orange.shade800),
                  const SizedBox(width: 4),
                  Text("In Your Truck",
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.bold)),
                ])
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Share.share("Check out this product: ${product.displayName}");
            },
            icon: const Icon(Icons.share, size: 14, color: Colors.white),
            label: const Text("Share",
                style: TextStyle(color: Colors.white, fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text("Chat with Customer"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: () {
              if (_order != null && _order!.customer.phone.isNotEmpty) {
                launchUrl(Uri.parse("tel:${_order!.customer.phone}"));
              }
            },
            backgroundColor: Colors.green,
            child: const Icon(Icons.phone, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
