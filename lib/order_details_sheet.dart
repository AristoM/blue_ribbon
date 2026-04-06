import 'package:flutter/material.dart';
import 'package:blue_ribbon/data/services/api_service.dart';
import 'package:blue_ribbon/order.dart';
import 'package:blue_ribbon/photo_verification_page.dart';
import 'package:blue_ribbon/data/models/upsell_product.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:blue_ribbon/job_chat_page.dart';
import 'package:blue_ribbon/data/services/settings_service.dart';

class OrderDetailsSheet extends StatefulWidget {
  final Order order;

  const OrderDetailsSheet({super.key, required this.order});

  @override
  State<OrderDetailsSheet> createState() => _OrderDetailsSheetState();
}

class _OrderDetailsSheetState extends State<OrderDetailsSheet> {
  late Order _order;
  bool _isLoading = false;
  String? _error;
  List<UpsellProduct> _upsellProducts = [];
  String _baseUrl = '';

  @override
  void initState() {
    super.initState();
    _loadBaseUrl();
    _order = widget.order;
    _loadUpsellProducts(_order.id);
  }

  Future<void> _loadBaseUrl() async {
    final baseUrl = await SettingsService.getBaseUrl();
    if (mounted) {
      setState(() {
        _baseUrl = baseUrl.replaceAll('/api/v1', '');
      });
    }
  }

  Future<void> _loadUpsellProducts(String jobId) async {
    // Assuming upsell products might use jobId, but we have orderId mostly.
    // However, Order object has jobId.
    if (_order.jobId == null) {
      return;
    }

    try {
      final response = await ApiService().getUpsellProducts(_order.jobId!);
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

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('OK'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _startJob() async {
    final confirmed = await _showConfirmDialog(
      'Start Job',
      'Are you sure you want to start this job?',
    );
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService().startJob(_order.id);
      if (response.statusCode == 200 && response.data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job started successfully')),
          );
          if (mounted) {
            Navigator.pop(context, true);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(response.data['message'] ?? 'Failed to start job')),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _completeJob() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if photo verification is completed
      final verificationResponse =
          await ApiService().getVerificationPrerequisites(_order.id);
      bool isVerified = false;
      if (verificationResponse.statusCode == 200 &&
          verificationResponse.data['success']) {
        final List stepsJson = verificationResponse.data['data']['steps'] ?? [];
        if (stepsJson.isEmpty) {
          isVerified = true; // No steps means nothing to verify
        } else {
          isVerified = stepsJson.every((j) => j['status'] == 'success');
        }
      }

      if (!isVerified) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          final confirm = await _showConfirmDialog(
            'Photo Verification Pending',
            'Some photo verification steps are still pending. Would you like to complete verification now?',
          );
          if (confirm && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PhotoVerificationPage(
                  jobId: _order.id,
                  orderName: _order.lineItem.displayName,
                  modelNumber: _order.lineItem.sku,
                ),
              ),
            ).then((_) {
              if (mounted) _completeJob();
            }); // Retry after returning from verification
          }
        }
        return;
      }

      final confirmed = await _showConfirmDialog(
        'Complete Job',
        'Are you sure you want to complete this job?',
      );
      if (!confirmed) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await ApiService().completeJob(_order.id);
      if (response.statusCode == 200 && response.data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job completed successfully')),
          );
          if (mounted) {
            Navigator.pop(context, true);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(response.data['message'] ?? 'Failed to complete job')),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
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

    if (_error != null) {
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 180),
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
                _order.lineItem.displayName,
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
                _order.status,
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
          _order.orderId,
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
    final images = _order.notes.siteImages;
    if (images.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.image_outlined, size: 20, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            Text(
              "SITE PHOTOS (${images.length})",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildPhotoPlaceholder(images[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPlaceholder(String imageUrl) {
    final String fullImageUrl = imageUrl.startsWith('http')
        ? imageUrl
        : '$_baseUrl$imageUrl';

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage(fullImageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          if (!imageUrl.startsWith('http'))
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
    final notes = _order.notes.specialInstructions;
    if (notes.isEmpty) return const SizedBox.shrink();

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
    final answers = _order.notes.questionnaireAnswers;
    if (answers.isEmpty) {
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
            children: answers.map((entry) {
              return _buildQuestionnaireRow(entry.question, entry.answer.toString());
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              formattedLabel,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
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
                      JobChatPage(jobId: _order.id),
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
              if (_order.lineItem.manualUrl.isNotEmpty) {
                launchUrl(Uri.parse(_order.lineItem.manualUrl));
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
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoVerificationPage(
              jobId: _order.id,
              orderName: _order.lineItem.displayName,
              modelNumber: _order.lineItem.sku,
            ),
          ),
        );
      },
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
    final bool canStart =
        _order.jobStatus == 'PENDING' || _order.jobStatus == 'ASSIGNED';
    final bool canComplete = _order.jobStatus == 'IN_PROGRESS';
    final bool showActionButton = canStart || canComplete;

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
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
                  if (_order.customer.phone.isNotEmpty) {
                    launchUrl(Uri.parse("tel:${_order.customer.phone}"));
                  }
                },
                backgroundColor: Colors.green,
                child: const Icon(Icons.phone, color: Colors.white),
              ),
            ],
          ),
          if (showActionButton) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canStart ? _startJob : _completeJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      canStart ? Colors.blue.shade700 : Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  canStart ? "Start Job" : "Complete",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
