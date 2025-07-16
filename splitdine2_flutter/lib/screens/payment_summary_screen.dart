import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../models/participant.dart';
import '../services/receipt_provider.dart';
import '../services/assignment_provider.dart';
import '../services/session_service.dart';
import 'session_items_screen.dart';

class PaymentSummaryScreen extends StatefulWidget {
  final Session session;

  const PaymentSummaryScreen({
    super.key,
    required this.session,
  });

  @override
  State<PaymentSummaryScreen> createState() => _PaymentSummaryScreenState();
}

class _PaymentSummaryScreenState extends State<PaymentSummaryScreen> {
  final SessionService _sessionService = SessionService();
  List<Participant> _participants = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    try {
      final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);
      final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);

      // Load items and assignments for this session
      await receiptProvider.loadItems(widget.session.id);
      await assignmentProvider.loadSessionAssignments(widget.session.id);

      // Load participants
      await _loadParticipants();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load data: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadParticipants() async {
    if (!mounted) return;

    try {
      final result = await _sessionService.getSessionParticipants(widget.session.id);
      if (!mounted) return;

      if (result['success']) {
        setState(() {
          _participants = result['participants'] as List<Participant>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load participants: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Payment Summary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        shadowColor: Colors.black12,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Consumer2<ReceiptProvider, AssignmentProvider>(
                  builder: (context, receiptProvider, assignmentProvider, child) {
                    final items = receiptProvider.items;
                    final subtotal = receiptProvider.subtotal;
                    final allocatedAmount = assignmentProvider.getTotalAllocatedAmount(items);
                    final unallocatedAmount = subtotal - allocatedAmount;

                    // Calculate each participant's total
                    final participantTotals = <int, double>{};
                    for (final participant in _participants) {
                      participantTotals[participant.userId] = 
                          assignmentProvider.getUserAssignedTotal(participant.userId, items);
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Session Info Card
                          Card(
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.session.displayName,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.session.location,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Summary Card
                          Card(
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Bill Total',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      Text(
                                        '£${subtotal.toStringAsFixed(2)}',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Allocated',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                      Text(
                                        '£${allocatedAmount.toStringAsFixed(2)}',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (unallocatedAmount > 0) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Unallocated',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                        Text(
                                          '£${unallocatedAmount.toStringAsFixed(2)}',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Participants Payment List
                          const Text(
                            'Who Owes What',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),

                          ..._participants.map((participant) {
                            final amount = participantTotals[participant.userId] ?? 0.0;
                            final isOrganizer = participant.userId == widget.session.organizerId;

                            return Card(
                              elevation: 0,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                onTap: amount > 0 ? () => _navigateToItemsWithFilter(context, participant.displayName) : null,
                                leading: CircleAvatar(
                                  backgroundColor: amount > 0 
                                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.1),
                                  child: Text(
                                    participant.displayName.isNotEmpty 
                                        ? participant.displayName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: amount > 0 
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        participant.displayName,
                                        style: TextStyle(
                                          fontWeight: isOrganizer ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (isOrganizer)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'HOST',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Text(
                                  participant.email ?? 'Guest user',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '£${amount.toStringAsFixed(2)}',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: amount > 0
                                                ? Theme.of(context).colorScheme.primary
                                                : Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          amount > 0 ? 'owes' : 'no items',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (amount > 0) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: Colors.grey.shade400,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }),

                          if (unallocatedAmount > 0) ...[
                            const SizedBox(height: 16),
                            Card(
                              color: Colors.orange.withValues(alpha: 0.1),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'There are still unallocated items worth £${unallocatedAmount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: Colors.orange.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  void _navigateToItemsWithFilter(BuildContext context, String userName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SessionItemsScreen(
          session: widget.session,
          initialFilter: userName,
        ),
      ),
    );
  }
}
