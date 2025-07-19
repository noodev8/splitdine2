import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../services/guest_choice_service.dart';
import '../services/session_provider.dart';
import '../services/session_service.dart';

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
  final GuestChoiceService _guestChoiceService = GuestChoiceService();
  final SessionService _sessionService = SessionService();
  Map<String, dynamic>? _paymentSummary;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPaymentSummary();
      _refreshSessionData();
    });
  }


  Future<void> _loadPaymentSummary() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _guestChoiceService.getPaymentSummary(widget.session.id);
      
      if (!mounted) return;

      if (result['success']) {
        setState(() {
          _paymentSummary = result;
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
          _errorMessage = 'Failed to load payment summary: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshSessionData() async {
    try {
      // Refresh session data by reloading sessions
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
      await sessionProvider.loadSessions();
    } catch (e) {
      // Handle error silently for now
      debugPrint('Error refreshing session data: $e');
    }
  }

  Future<void> _removeParticipant(int userId, String userName) async {
    // Show confirmation dialog
    final shouldRemove = await _showRemoveConfirmationDialog(userName);
    if (!shouldRemove) return;

    // Show loading
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _sessionService.removeParticipant(widget.session.id, userId);
      
      if (result['success']) {
        // Refresh the payment summary to remove the participant
        await _loadPaymentSummary();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$userName removed from session'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove $userName: ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing $userName: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showRemoveConfirmationDialog(String userName) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: Icon(
            Icons.person_remove,
            color: Colors.red.shade600,
            size: 48,
          ),
          title: const Text(
            'Remove Participant',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Remove $userName from this session?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'This will:',
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.clear, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Remove them from the session'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.clear, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Delete all their allocated items'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'This action cannot be undone.',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    ) ?? false;
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
                        onPressed: _loadPaymentSummary,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _paymentSummary != null ? Builder(
                  builder: (context) {
                    final billTotal = (_paymentSummary!['bill_total'] as num).toDouble();
                    final allocatedAmount = (_paymentSummary!['allocated_total'] as num).toDouble();
                    final remainingAmount = (_paymentSummary!['remaining_total'] as num).toDouble();
                    final participantTotals = _paymentSummary!['participant_totals'] as List<dynamic>;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Session info card removed as requested

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
                                        '£${billTotal.toStringAsFixed(2)}',
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
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Remaining',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                      Text(
                                        '£${remainingAmount.toStringAsFixed(2)}',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: remainingAmount > 0 ? Colors.red : Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
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
                          if (widget.session.isHost) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Long-press to remove guests',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),

                          ...participantTotals.map<Widget>((participantData) {
                            final userName = participantData['user_name'] as String;
                            final userEmail = participantData['email'] as String?;
                            final amount = (participantData['total_amount'] as num).toDouble();
                            final userId = participantData['user_id'] as int;
                            final isOrganizer = userId == widget.session.organizerId;
                            final canRemove = widget.session.isHost && !isOrganizer;

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
                              child: canRemove
                                  ? InkWell(
                                      onLongPress: () => _removeParticipant(userId, userName),
                                      borderRadius: BorderRadius.circular(8),
                                      child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: amount > 0 
                                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.1),
                                  child: Text(
                                    userName.isNotEmpty 
                                        ? userName[0].toUpperCase()
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
                                        userName,
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
                                  userEmail ?? 'Guest user',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                trailing: Text(
                                  '£${amount.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: amount > 0
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                                    )
                                  : ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: amount > 0 
                                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                                            : Colors.grey.withValues(alpha: 0.1),
                                        child: Text(
                                          userName.isNotEmpty 
                                              ? userName[0].toUpperCase()
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
                                              userName,
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
                                        userEmail ?? 'Guest user',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      trailing: Text(
                                        '£${amount.toStringAsFixed(2)}',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: amount > 0
                                              ? Theme.of(context).colorScheme.primary
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                            );
                          }),


                        ],
                      ),
                    );
                  },
                ) : const Center(child: Text('No payment data available')),
    );
  }

}
