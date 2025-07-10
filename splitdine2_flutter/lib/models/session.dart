import 'package:cloud_firestore/cloud_firestore.dart';

enum SessionStatus { active, completed, cancelled }

class ReceiptData {
  final String? imageUrl;
  final String? ocrText;
  final List<Map<String, dynamic>> parsedItems;
  final double totalAmount;
  final double tax;
  final double tip;
  final double serviceCharge;

  ReceiptData({
    this.imageUrl,
    this.ocrText,
    this.parsedItems = const [],
    this.totalAmount = 0.0,
    this.tax = 0.0,
    this.tip = 0.0,
    this.serviceCharge = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'ocrText': ocrText,
      'parsedItems': parsedItems,
      'totalAmount': totalAmount,
      'tax': tax,
      'tip': tip,
      'serviceCharge': serviceCharge,
    };
  }

  factory ReceiptData.fromMap(Map<String, dynamic> map) {
    return ReceiptData(
      imageUrl: map['imageUrl'],
      ocrText: map['ocrText'],
      parsedItems: List<Map<String, dynamic>>.from(map['parsedItems'] ?? []),
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      tax: (map['tax'] ?? 0.0).toDouble(),
      tip: (map['tip'] ?? 0.0).toDouble(),
      serviceCharge: (map['serviceCharge'] ?? 0.0).toDouble(),
    );
  }
}

class Participant {
  final String name;
  final DateTime joinedAt;
  final String role; // 'organizer' or 'participant'
  final bool confirmed;

  Participant({
    required this.name,
    required this.joinedAt,
    required this.role,
    this.confirmed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'role': role,
      'confirmed': confirmed,
    };
  }

  factory Participant.fromMap(Map<String, dynamic> map) {
    return Participant(
      name: map['name'] ?? '',
      joinedAt: (map['joinedAt'] as Timestamp).toDate(),
      role: map['role'] ?? 'participant',
      confirmed: map['confirmed'] ?? false,
    );
  }
}

class ItemAssignment {
  final List<String> assignedTo;
  final String splitType; // 'equal' or 'custom'
  final Map<String, dynamic>? customSplits;

  ItemAssignment({
    this.assignedTo = const [],
    this.splitType = 'equal',
    this.customSplits,
  });

  Map<String, dynamic> toMap() {
    return {
      'assignedTo': assignedTo,
      'splitType': splitType,
      'customSplits': customSplits,
    };
  }

  factory ItemAssignment.fromMap(Map<String, dynamic> map) {
    return ItemAssignment(
      assignedTo: List<String>.from(map['assignedTo'] ?? []),
      splitType: map['splitType'] ?? 'equal',
      customSplits: map['customSplits'],
    );
  }
}

class FinalSplit {
  final double amount;
  final List<String> items;
  final bool confirmed;
  final bool paid;

  FinalSplit({
    this.amount = 0.0,
    this.items = const [],
    this.confirmed = false,
    this.paid = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'items': items,
      'confirmed': confirmed,
      'paid': paid,
    };
  }

  factory FinalSplit.fromMap(Map<String, dynamic> map) {
    return FinalSplit(
      amount: (map['amount'] ?? 0.0).toDouble(),
      items: List<String>.from(map['items'] ?? []),
      confirmed: map['confirmed'] ?? false,
      paid: map['paid'] ?? false,
    );
  }
}

class Session {
  final String id;
  final String organizerId;
  final String joinCode;
  final SessionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? restaurantName;
  final ReceiptData receiptData;
  final Map<String, Participant> participants;
  final Map<String, ItemAssignment> assignments;
  final Map<String, FinalSplit> finalSplit;

  Session({
    required this.id,
    required this.organizerId,
    required this.joinCode,
    this.status = SessionStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.restaurantName,
    ReceiptData? receiptData,
    this.participants = const {},
    this.assignments = const {},
    this.finalSplit = const {},
  }) : receiptData = receiptData ?? ReceiptData();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organizerId': organizerId,
      'joinCode': joinCode,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'restaurantName': restaurantName,
      'receiptData': receiptData.toMap(),
      'participants': participants.map((key, value) => MapEntry(key, value.toMap())),
      'assignments': assignments.map((key, value) => MapEntry(key, value.toMap())),
      'finalSplit': finalSplit.map((key, value) => MapEntry(key, value.toMap())),
    };
  }

  factory Session.fromMap(Map<String, dynamic> map, String documentId) {
    return Session(
      id: documentId,
      organizerId: map['organizerId'] ?? '',
      joinCode: map['joinCode'] ?? '',
      status: SessionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SessionStatus.active,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      restaurantName: map['restaurantName'],
      receiptData: ReceiptData.fromMap(map['receiptData'] ?? {}),
      participants: (map['participants'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, Participant.fromMap(value))),
      assignments: (map['assignments'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, ItemAssignment.fromMap(value))),
      finalSplit: (map['finalSplit'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, FinalSplit.fromMap(value))),
    );
  }

  Session copyWith({
    String? organizerId,
    String? joinCode,
    SessionStatus? status,
    DateTime? updatedAt,
    String? restaurantName,
    ReceiptData? receiptData,
    Map<String, Participant>? participants,
    Map<String, ItemAssignment>? assignments,
    Map<String, FinalSplit>? finalSplit,
  }) {
    return Session(
      id: id,
      organizerId: organizerId ?? this.organizerId,
      joinCode: joinCode ?? this.joinCode,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      restaurantName: restaurantName ?? this.restaurantName,
      receiptData: receiptData ?? this.receiptData,
      participants: participants ?? this.participants,
      assignments: assignments ?? this.assignments,
      finalSplit: finalSplit ?? this.finalSplit,
    );
  }
}
