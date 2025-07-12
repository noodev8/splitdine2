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
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isHost;

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
    required this.createdAt,
    required this.updatedAt,
    required this.isHost,
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

  // Get formatted date string
  String get formattedDate {
    return '${sessionDate.day}/${sessionDate.month}/${sessionDate.year}';
  }

  // Get formatted time string
  String get formattedTime {
    if (sessionTime == null) return '';
    return sessionTime!;
  }

  // Get display name (session name or location)
  String get displayName {
    return sessionName?.isNotEmpty == true ? sessionName! : location;
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
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isHost: json['is_host'] as bool? ?? false,
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
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_host': isHost,
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
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isHost,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isHost: isHost ?? this.isHost,
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
