enum JobStatus { pending, inProgress, completed }

class LineItem {
  final String sku;
  final String displayName;
  final String imageUrl;
  final String type;
  final String category;
  final double weightKg;
  final Dimensions dimensions;
  final String manualUrl;

  LineItem({
    required this.sku,
    required this.displayName,
    required this.imageUrl,
    required this.type,
    required this.category,
    required this.weightKg,
    required this.dimensions,
    required this.manualUrl,
  });

  factory LineItem.fromJson(Map<String, dynamic> json) {
    try {
      return LineItem(
        sku: (json['sku'] ?? '').toString(),
        displayName: (json['display_name'] ?? '').toString(),
        imageUrl: (json['image_url'] ?? '').toString(),
        type: (json['type'] ?? '').toString(),
        category: (json['category'] ?? '').toString(),
        weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0.0,
        dimensions: Dimensions.fromJson(json['dimensions'] ?? {}),
        manualUrl: (json['manual_url'] ?? '').toString(),
      );
    } catch (e) {
      print('Error parsing LineItem: $e, json: $json');
      rethrow;
    }
  }
}

class Dimensions {
  final int lengthCm;
  final int widthCm;
  final int depthCm;

  Dimensions({
    required this.lengthCm,
    required this.widthCm,
    required this.depthCm,
  });

  factory Dimensions.fromJson(Map<String, dynamic> json) {
    try {
      return Dimensions(
        lengthCm: (json['length_cm'] as num?)?.toInt() ?? 0,
        widthCm: (json['width_cm'] as num?)?.toInt() ?? 0,
        depthCm: (json['depth_cm'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      print('Error parsing Dimensions: $e, json: $json');
      rethrow;
    }
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
    try {
      return Customer(
        name: (json['name'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        phone: (json['phone'] ?? '').toString(),
      );
    } catch (e) {
      print('Error parsing Customer: $e, json: $json');
      rethrow;
    }
  }
}

class Location {
  final String address;
  final double lat;
  final double lng;
  final String accessInstructions;

  Location({
    required this.address,
    required this.lat,
    required this.lng,
    required this.accessInstructions,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    try {
      String address = '';
      final addr = json['address'];
      if (addr is Map) {
        address =
            "${addr['street'] ?? ''}, ${addr['city'] ?? ''}, ${addr['state'] ?? ''} ${addr['zip'] ?? ''}"
                .trim();
        if (address == ", ,") address = "";
      } else {
        address = (addr ?? '').toString();
      }

      return Location(
        address: address,
        lat: (json['coordinates']?['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (json['coordinates']?['lng'] as num?)?.toDouble() ?? 0.0,
        accessInstructions: (json['access_instructions'] ?? '').toString(),
      );
    } catch (e) {
      print('Error parsing Location: $e, json: $json');
      rethrow;
    }
  }
}

class Questionnaire {
  final String installationLocation;
  final int floorLevel;
  final bool elevatorAvailable;
  final bool powerOutletAvailable;
  final bool waterConnectionAvailable;
  final String specialRequirements;

  Questionnaire({
    required this.installationLocation,
    required this.floorLevel,
    required this.elevatorAvailable,
    required this.powerOutletAvailable,
    required this.waterConnectionAvailable,
    required this.specialRequirements,
  });

  factory Questionnaire.fromJson(Map<String, dynamic> json) {
    try {
      return Questionnaire(
        installationLocation: (json['installation_location'] ?? '').toString(),
        floorLevel: (json['floor_level'] as num?)?.toInt() ?? 0,
        elevatorAvailable: json['elevator_available'] ?? false,
        powerOutletAvailable: json['power_outlet_available'] ?? false,
        waterConnectionAvailable: json['water_connection_available'] ?? false,
        specialRequirements: (json['special_requirements'] ?? '').toString(),
      );
    } catch (e) {
      print('Error parsing Questionnaire: $e, json: $json');
      rethrow;
    }
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
    try {
      return Technician(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        phone: (json['phone'] ?? '').toString(),
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        photoUrl: (json['photo_url'] ?? '').toString(),
      );
    } catch (e) {
      print('Error parsing Technician: $e, json: $json');
      rethrow;
    }
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
    try {
      return TrackingProgress(
        percentage: (json['percentage'] as num?)?.toInt() ?? 0,
        currentStep: (json['current_step'] ?? '').toString(),
        stepsCompleted: json['steps_completed'] != null
            ? List<String>.from(
                json['steps_completed'].map((e) => e.toString()))
            : [],
        stepsRemaining: json['steps_remaining'] != null
            ? List<String>.from(
                json['steps_remaining'].map((e) => e.toString()))
            : [],
      );
    } catch (e) {
      print('Error parsing TrackingProgress: $e, json: $json');
      rethrow;
    }
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
    try {
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
    } catch (e) {
      print('Error parsing Tracking: $e, json: $json');
      rethrow;
    }
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
    try {
      return TimelineEvent(
        status: (json['status'] ?? 'UNKNOWN').toString(),
        timestamp: json['timestamp'] != null
            ? (DateTime.tryParse(json['timestamp'].toString()) ??
                DateTime.now())
            : DateTime.now(),
      );
    } catch (e) {
      print('Error parsing TimelineEvent: $e, json: $json');
      rethrow;
    }
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
    try {
      return Payment(
        installationFee:
            (json['installation_fee'] ?? json['payment_amount'] as num?)
                    ?.toDouble() ??
                0.0,
        additionalCharges:
            (json['additional_charges'] as num?)?.toDouble() ?? 0.0,
        total: (json['total'] ?? json['payment_amount'] as num?)?.toDouble() ??
            0.0,
        status: (json['status'] ?? 'PENDING').toString(),
      );
    } catch (e) {
      print('Error parsing Payment: $e, json: $json');
      rethrow;
    }
  }
}

class Order {
  final String id;
  final String orderId;
  final String? jobId;
  final String? historyId;
  final String status;
  final String? action;
  final String jobStatus;
  final LineItem lineItem;
  final Customer customer;
  final Location location;
  final Questionnaire questionnaire;
  final String scheduledTime;
  final Technician technician;
  final Map<String, dynamic> customerNotes;
  final Tracking tracking;
  final List<TimelineEvent> timeline;
  final Payment payment;
  final int estimatedDurationHours;
  final DateTime? assignedAt;
  final double? paymentAmount;
  bool isPast;

  Order({
    required this.id,
    required this.orderId,
    this.jobId,
    this.historyId,
    required this.status,
    this.action,
    required this.jobStatus,
    required this.lineItem,
    required this.customer,
    required this.location,
    required this.questionnaire,
    required this.scheduledTime,
    required this.technician,
    required this.customerNotes,
    required this.tracking,
    required this.timeline,
    required this.payment,
    required this.estimatedDurationHours,
    this.assignedAt,
    this.paymentAmount,
    this.isPast = false,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      print(
          'Order.fromJson start parsing: ${json['job_id'] ?? json['order_id']}');
      return Order(
        id: (json['job_id'] ?? json['order_id'] ?? '').toString(),
        orderId: (json['order_id'] ?? '').toString(),
        jobId: json['job_id']?.toString(),
        historyId: json['history_id']?.toString(),
        status: (json['status'] ?? 'PENDING').toString(),
        action: json['action']?.toString(),
        jobStatus: (json['job_status'] ?? 'PENDING').toString(),
        lineItem: LineItem.fromJson(json['line_item'] ?? {}),
        customer: Customer.fromJson(json['customer'] ?? {}),
        location: Location.fromJson(
            json['location'] ?? json['delivery_address'] ?? {}),
        questionnaire: Questionnaire.fromJson(json['questionnaire'] ?? {}),
        scheduledTime: (json['scheduled_time'] ?? '').toString(),
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
            ? json['customer_notes']
            : {
                'special_instructions':
                    (json['customer_notes'] ?? '').toString()
              },
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
        estimatedDurationHours:
            (json['estimated_duration_hours'] as num?)?.toInt() ?? 0,
        assignedAt: json['assigned_at'] != null
            ? (DateTime.tryParse(json['assigned_at'].toString()))
            : null,
        paymentAmount: (json['payment_amount'] as num?)?.toDouble(),
        isPast: (json['job_status'] == 'COMPLETED'),
      );
    } catch (e, stack) {
      print('Error parsing Order: $e');
      print('Stacktrace: $stack');
      print('Failed JSON: $json');
      rethrow;
    }
  }
}
