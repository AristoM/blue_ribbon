enum JobStatus { pending, inProgress, completed }

class LineItem {
  final String sku;
  final String displayName;
  final String imageUrl;
  final String type;

  LineItem({
    required this.sku,
    required this.displayName,
    required this.imageUrl,
    required this.type,
  });

  factory LineItem.fromJson(Map<String, dynamic> json) {
    return LineItem(
      sku: json['sku'] ?? '',
      displayName: json['display_name'] ?? '',
      imageUrl: json['image_url'] ?? '',
      type: json['type'] ?? '',
    );
  }
}

class Customer {
  final String name;
  final String email;
  final String phone;

  Customer({
    required this.name,
    required this.email,
    required this.phone,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class Technician {
  final String id;
  final String name;
  final String phone;
  final double rating;
  final String photoUrl;

  Technician({
    required this.id,
    required this.name,
    required this.phone,
    required this.rating,
    required this.photoUrl,
  });

  factory Technician.fromJson(Map<String, dynamic> json) {
    return Technician(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      photoUrl: json['photo_url'] ?? '',
    );
  }
}

class TrackingProgress {
  final int percentage;
  final String currentStep;
  final List<String> stepsCompleted;
  final List<String> stepsRemaining;

  TrackingProgress({
    required this.percentage,
    required this.currentStep,
    required this.stepsCompleted,
    required this.stepsRemaining,
  });

  factory TrackingProgress.fromJson(Map<String, dynamic> json) {
    return TrackingProgress(
      percentage: (json['percentage'] as num?)?.toInt() ?? 0,
      currentStep: (json['current_step'] ?? '').toString(),
      stepsCompleted: json['steps_completed'] != null
          ? List<String>.from(json['steps_completed'].map((e) => e.toString()))
          : [],
      stepsRemaining: json['steps_remaining'] != null
          ? List<String>.from(json['steps_remaining'].map((e) => e.toString()))
          : [],
    );
  }
}

class Tracking {
  final String currentStatus;
  final TrackingProgress progress;

  Tracking({
    required this.currentStatus,
    required this.progress,
  });

  factory Tracking.fromJson(Map<String, dynamic> json) {
    return Tracking(
      currentStatus: (json['current_status'] ?? 'PENDING').toString(),
      progress: json['progress'] != null
          ? TrackingProgress.fromJson(json['progress'])
          : TrackingProgress(
              percentage: 0,
              currentStep: 'Scheduled',
              stepsCompleted: [],
              stepsRemaining: []),
    );
  }
}

class TimelineEvent {
  final String status;
  final DateTime timestamp;

  TimelineEvent({
    required this.status,
    required this.timestamp,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      status: (json['status'] ?? 'UNKNOWN').toString(),
      timestamp: json['timestamp'] != null
          ? (DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

class Payment {
  final double installationFee;
  final double additionalCharges;
  final double total;
  final String status;

  Payment({
    required this.installationFee,
    required this.additionalCharges,
    required this.total,
    required this.status,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      installationFee:
          (json['installation_fee'] ?? json['payment_amount'] as num?)
                  ?.toDouble() ??
              0.0,
      additionalCharges:
          (json['additional_charges'] as num?)?.toDouble() ?? 0.0,
      total:
          (json['total'] ?? json['payment_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'PENDING',
    );
  }
}

class Order {
  final String id;
  final String? jobId;
  final String status;
  final LineItem lineItem;
  final Customer customer;
  final String deliveryAddress;
  final DateTime scheduledTime;
  final Technician technician;
  final Map<String, dynamic> customerNotes;
  final Tracking tracking;
  final List<TimelineEvent> timeline;
  final Payment payment;
  bool isPast;

  Order({
    required this.id,
    this.jobId,
    required this.status,
    required this.lineItem,
    required this.customer,
    required this.deliveryAddress,
    required this.scheduledTime,
    required this.technician,
    required this.customerNotes,
    required this.tracking,
    required this.timeline,
    required this.payment,
    this.isPast = false,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    String address = '';
    if (json['delivery_address'] != null) {
      address = json['delivery_address'].toString();
    } else if (json['location']?['address'] != null) {
      final addr = json['location']['address'];
      if (addr is Map) {
        address =
            "${addr['street'] ?? ''}, ${addr['city'] ?? ''}, ${addr['state'] ?? ''} ${addr['zip'] ?? ''}"
                .trim();
        if (address == ", ,") address = "";
      } else if (addr is String) {
        address = addr;
      }
    }

    return Order(
      id: (json['order_id'] ?? json['job_id'] ?? '').toString(),
      jobId: json['job_id']?.toString(),
      status: (json['job_status'] ?? json['status'] ?? 'PENDING').toString(),
      lineItem: LineItem.fromJson(json['line_item'] ?? {}),
      customer: Customer.fromJson(json['customer'] ?? {}),
      deliveryAddress: address.isEmpty ? 'No address provided' : address,
      scheduledTime: (json['scheduled_time'] != null &&
              json['scheduled_time'].toString().isNotEmpty)
          ? (DateTime.tryParse(json['scheduled_time'].toString()) ??
              DateTime.now())
          : DateTime.now(),
      technician: json['technician'] != null
          ? Technician.fromJson(json['technician'])
          : json['assigned_technician'] != null
              ? Technician.fromJson(json['assigned_technician'])
              : Technician(
                  id: '',
                  name: 'Not Assigned',
                  phone: '',
                  rating: 0,
                  photoUrl: ''),
      customerNotes: json['customer_notes'] is Map
          ? {
              'entrance_code': json['customer_notes']['entrance_code'] ?? '',
              'pets': json['customer_notes']['pets'] ?? false,
            }
          : {'entrance_code': '', 'pets': false},
      tracking: json['tracking'] != null
          ? Tracking.fromJson(json['tracking'])
          : Tracking(
              currentStatus: 'PENDING',
              progress: TrackingProgress(
                  percentage: 0,
                  currentStep: 'Scheduled',
                  stepsCompleted: [],
                  stepsRemaining: [])),
      timeline: json['timeline'] != null
          ? (json['timeline'] as List)
              .map((e) => TimelineEvent.fromJson(e))
              .toList()
          : [],
      payment: Payment.fromJson(json),
      isPast: (json['job_status'] ?? json['status']) == 'COMPLETED',
    );
  }
}

class OrderRepository {
  static final List<Order> _orders = [
    Order(
      id: "ORD-2026-001234",
      status: "IN_PROGRESS",
      lineItem: LineItem(
        sku: "FRIDGE-LG-500L",
        displayName: "LG 500L Refrigerator",
        imageUrl: "https://cdn.example.com/products/fridge-lg-500l.jpg",
        type: "appliance",
      ),
      customer: Customer(
        name: "John Doe",
        email: "john@example.com",
        phone: "+1234567890",
      ),
      deliveryAddress: "123 Main St, San Francisco, CA 94102",
      scheduledTime: DateTime.parse("2026-02-05T10:00:00Z"),
      technician: Technician(
        id: "TECH-001",
        name: "Mike Johnson",
        phone: "+1234567891",
        rating: 4.8,
        photoUrl: "https://cdn.example.com/techs/tech-001.jpg",
      ),
      customerNotes: {
        "entrance_code": "1234",
        "pets": true,
        "questionnaire_answers": {}
      },
      tracking: Tracking(
        currentStatus: "IN_PROGRESS",
        progress: TrackingProgress(
          percentage: 60,
          currentStep: "Installation in progress",
          stepsCompleted: ["Arrived", "Unpacking", "Positioning"],
          stepsRemaining: ["Testing", "Walkthrough", "Completion"],
        ),
      ),
      timeline: [
        TimelineEvent(
          status: "ORDER_CONFIRMED",
          timestamp: DateTime.parse("2026-01-30T10:30:00Z"),
        ),
        TimelineEvent(
          status: "TECHNICIAN_ASSIGNED",
          timestamp: DateTime.parse("2026-01-30T10:35:00Z"),
        ),
        TimelineEvent(
          status: "IN_PROGRESS",
          timestamp: DateTime.parse("2026-02-05T10:00:00Z"),
        ),
      ],
      payment: Payment(
        installationFee: 150.0,
        additionalCharges: 50.0,
        total: 200.0,
        status: "PENDING",
      ),
    ),
  ];

  static List<Order> getUpcomingOrders() {
    return _orders.where((order) => !order.isPast).toList();
  }

  static List<Order> getPastOrders() {
    return _orders.where((order) => order.isPast).toList();
  }

  static void deleteOrder(String id) {
    _orders.removeWhere((order) => order.id == id);
  }

  static void addOrder(Order order) {
    _orders.add(order);
  }

  static void startJob(String id) {
    final index = _orders.indexWhere((o) => o.id == id);
    if (index != -1) {
      // Logic for starting job
    }
  }

  static void completeJob(String id) {
    final index = _orders.indexWhere((o) => o.id == id);
    if (index != -1) {
      _orders[index].isPast = true;
    }
  }

  static Order? getOrderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (e) {
      return null;
    }
  }
}
