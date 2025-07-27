class Session {
  final int id;
  final int organizerId;
  final String? sessionName;
  final String location;
  final DateTime sessionDate;
  final String? sessionTime;
  final String? description;
  final String joinCode;
  final String? receiptImageUrl;
  final String? receiptOcrText;
  final bool receiptProcessed;
  final double totalAmount;
  final double taxAmount;
  final double tipAmount;
  final double serviceCharge;
  final double itemAmount;
  final double extraCharge;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isHost;
  final bool allowInvites;
  final bool allowGuestsAddItems;
  final bool allowGuestsEditPrices;
  final bool allowGuestsEditItems;
  final bool allowGuestsAllocate;

  Session({
    required this.id,
    required this.organizerId,
    this.sessionName,
    required this.location,
    required this.sessionDate,
    this.sessionTime,
    this.description,
    required this.joinCode,
    this.receiptImageUrl,
    this.receiptOcrText,
    required this.receiptProcessed,
    required this.totalAmount,
    required this.taxAmount,
    required this.tipAmount,
    required this.serviceCharge,
    required this.itemAmount,
    required this.extraCharge,
    required this.createdAt,
    required this.updatedAt,
    required this.isHost,
    this.allowInvites = true,
    this.allowGuestsAddItems = true,
    this.allowGuestsEditPrices = true,
    this.allowGuestsEditItems = true,
    this.allowGuestsAllocate = true,
  });

  // Check if session is upcoming (date >= today)
  bool get isUpcoming {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final sessionDateOnly = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
    return sessionDateOnly.isAtSameMomentAs(todayDate) || sessionDateOnly.isAfter(todayDate);
  }

  // Check if session is editable (date >= today)
  bool get isEditable => isUpcoming;

  // Get formatted date string with day name
  String get formattedDate {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = weekdays[sessionDate.weekday - 1];
    return '$dayName, ${sessionDate.day}/${sessionDate.month}/${sessionDate.year}';
  }

  // Get formatted time string (without seconds)
  String get formattedTime {
    if (sessionTime == null) return '';
    // Remove seconds if present (e.g., "14:30:00" -> "14:30")
    final timeParts = sessionTime!.split(':');
    if (timeParts.length >= 2) {
      return '${timeParts[0]}:${timeParts[1]}';
    }
    return sessionTime!;
  }

  // Get display name (session name or location)
  String get displayName {
    return sessionName?.isNotEmpty == true ? sessionName! : location;
  }

  // Check if session is in the past (date has passed)
  bool get isPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDay = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
    return sessionDay.isBefore(today);
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as int,
      organizerId: json['organizer_id'] as int,
      sessionName: json['session_name'] as String?,
      location: json['location'] as String,
      sessionDate: DateTime.parse(json['session_date'] as String),
      sessionTime: json['session_time'] as String?,
      description: json['description'] as String?,
      joinCode: json['join_code'] as String,
      receiptImageUrl: json['receipt_image_url'] as String?,
      receiptOcrText: json['receipt_ocr_text'] as String?,
      receiptProcessed: json['receipt_processed'] as bool? ?? false,
      totalAmount: double.parse((json['total_amount'] ?? 0.0).toString()),
      taxAmount: double.parse((json['tax_amount'] ?? 0.0).toString()),
      tipAmount: double.parse((json['tip_amount'] ?? 0.0).toString()),
      serviceCharge: double.parse((json['service_charge'] ?? 0.0).toString()),
      itemAmount: double.parse((json['item_amount'] ?? 0.0).toString()),
      extraCharge: double.parse((json['extra_charge'] ?? 0.0).toString()),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isHost: json['is_host'] as bool? ?? false,
      allowInvites: json['allow_invites'] as bool? ?? true,
      allowGuestsAddItems: json['allow_guests_add_items'] as bool? ?? true,
      allowGuestsEditPrices: json['allow_guests_edit_prices'] as bool? ?? true,
      allowGuestsEditItems: json['allow_guests_edit_items'] as bool? ?? true,
      allowGuestsAllocate: json['allow_guests_allocate'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizer_id': organizerId,
      'session_name': sessionName,
      'location': location,
      'session_date': sessionDate.toIso8601String().split('T')[0], // Date only
      'session_time': sessionTime,
      'description': description,
      'join_code': joinCode,
      'receipt_image_url': receiptImageUrl,
      'receipt_ocr_text': receiptOcrText,
      'receipt_processed': receiptProcessed,
      'total_amount': totalAmount,
      'tax_amount': taxAmount,
      'tip_amount': tipAmount,
      'service_charge': serviceCharge,
      'item_amount': itemAmount,
      'extra_charge': extraCharge,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_host': isHost,
      'allow_invites': allowInvites,
      'allow_guests_add_items': allowGuestsAddItems,
      'allow_guests_edit_prices': allowGuestsEditPrices,
      'allow_guests_edit_items': allowGuestsEditItems,
      'allow_guests_allocate': allowGuestsAllocate,
    };
  }

  Session copyWith({
    int? id,
    int? organizerId,
    String? sessionName,
    String? location,
    DateTime? sessionDate,
    String? sessionTime,
    String? description,
    String? joinCode,
    String? receiptImageUrl,
    String? receiptOcrText,
    bool? receiptProcessed,
    double? totalAmount,
    double? taxAmount,
    double? tipAmount,
    double? serviceCharge,
    double? itemAmount,
    double? extraCharge,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isHost,
    bool? allowInvites,
    bool? allowGuestsAddItems,
    bool? allowGuestsEditPrices,
    bool? allowGuestsEditItems,
    bool? allowGuestsAllocate,
  }) {
    return Session(
      id: id ?? this.id,
      organizerId: organizerId ?? this.organizerId,
      sessionName: sessionName ?? this.sessionName,
      location: location ?? this.location,
      sessionDate: sessionDate ?? this.sessionDate,
      sessionTime: sessionTime ?? this.sessionTime,
      description: description ?? this.description,
      joinCode: joinCode ?? this.joinCode,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      receiptOcrText: receiptOcrText ?? this.receiptOcrText,
      receiptProcessed: receiptProcessed ?? this.receiptProcessed,
      totalAmount: totalAmount ?? this.totalAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      tipAmount: tipAmount ?? this.tipAmount,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      itemAmount: itemAmount ?? this.itemAmount,
      extraCharge: extraCharge ?? this.extraCharge,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isHost: isHost ?? this.isHost,
      allowInvites: allowInvites ?? this.allowInvites,
      allowGuestsAddItems: allowGuestsAddItems ?? this.allowGuestsAddItems,
      allowGuestsEditPrices: allowGuestsEditPrices ?? this.allowGuestsEditPrices,
      allowGuestsEditItems: allowGuestsEditItems ?? this.allowGuestsEditItems,
      allowGuestsAllocate: allowGuestsAllocate ?? this.allowGuestsAllocate,
    );
  }

  @override
  String toString() {
    return 'Session(id: $id, sessionName: $sessionName, location: $location, sessionDate: $sessionDate, isHost: $isHost)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Session && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
