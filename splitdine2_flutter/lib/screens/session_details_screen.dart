import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../services/receipt_provider.dart';
import '../services/assignment_provider.dart';
import '../services/session_provider.dart';
import 'session_items_screen.dart';
import 'payment_summary_screen.dart';
import 'guest_management_screen.dart';
import 'my_items_screen.dart';

class SessionDetailsScreen extends StatefulWidget {
  final Session session;

  const SessionDetailsScreen({
    super.key,
    required this.session,
  });

  @override
  State<SessionDetailsScreen> createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Schedule data loading after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);
    final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);

    // Load items and assignments for this session
    await receiptProvider.loadItems(widget.session.id);
    await assignmentProvider.loadSessionAssignments(widget.session.id);
  }

  @override
  Widget build(BuildContext context) {
    final isUpcoming = widget.session.sessionDate.isAfter(DateTime.now().subtract(const Duration(days: 1)));
    final canEdit = isUpcoming;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session.displayName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (widget.session.isHost)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteSession(context);
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Session', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Session Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.session.displayName,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.session.location,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Date',
                      value: DateFormat('EEEE, MMM d, yyyy').format(widget.session.sessionDate),
                    ),
                    if (widget.session.sessionTime != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        icon: Icons.access_time,
                        label: 'Time',
                        value: _formatTime(widget.session.sessionTime!),
                      ),
                    ],
                    if (widget.session.description != null && widget.session.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        icon: Icons.description,
                        label: 'Description',
                        value: widget.session.description!,
                      ),
                    ],
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: widget.session.isHost ? Icons.star : Icons.person,
                      label: 'Role',
                      value: widget.session.isHost ? 'Host' : 'Guest',
                      valueColor: widget.session.isHost ? Colors.green : Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // Join Code Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session Code',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              widget.session.joinCode,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () => _copyJoinCode(context),
                          icon: const Icon(Icons.copy),
                          tooltip: 'Copy join code',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Share this code with others to join the session',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Meal Status Card
            Consumer2<ReceiptProvider, AssignmentProvider>(
              builder: (context, receiptProvider, assignmentProvider, child) {
                final items = receiptProvider.items;
                final allocatedAmount = assignmentProvider.getTotalAllocatedAmount(items);
                final unallocatedItems = assignmentProvider.getUnallocatedItems(items);
                final subtotal = receiptProvider.subtotal;
                final isFullyAllocated = unallocatedItems.isEmpty && items.isNotEmpty;
                final completionPercentage = subtotal > 0 ? (allocatedAmount / subtotal * 100) : 0.0;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isFullyAllocated ? Icons.check_circle : Icons.pending,
                              color: isFullyAllocated ? Colors.green : Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Meal Status',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${completionPercentage.toStringAsFixed(0)}% allocated',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isFullyAllocated ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryItem(
                              context,
                              icon: Icons.receipt_long,
                              label: 'Items',
                              value: '${items.length}',
                              valueColor: items.isEmpty ? Colors.grey : null,
                            ),
                            _buildSummaryItem(
                              context,
                              icon: Icons.check_circle,
                              label: 'Allocated',
                              value: '£${allocatedAmount.toStringAsFixed(2)}',
                              valueColor: allocatedAmount > 0 ? Colors.green : Colors.grey,
                            ),
                            _buildSummaryItem(
                              context,
                              icon: Icons.pending,
                              label: 'Remaining',
                              value: '£${(subtotal - allocatedAmount).toStringAsFixed(2)}',
                              valueColor: (subtotal - allocatedAmount) == 0 ? Colors.green : Colors.red,
                            ),
                          ],
                        ),
                        if (items.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: completionPercentage / 100,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isFullyAllocated ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: canEdit ? () => _navigateToItems(context) : null,
                        icon: const Icon(Icons.list_alt),
                        label: Text(canEdit ? 'Manage Items' : 'View Items'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: canEdit ? Theme.of(context).colorScheme.primary : Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToMyItems(context),
                        icon: const Icon(Icons.person),
                        label: const Text('My Items'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToPaymentSummary(context),
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('Payment Summary'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToGuestManagement(context),
                        icon: const Icon(Icons.people),
                        label: const Text('Guests'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                if (!widget.session.isHost) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _leaveSession(context),
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text('Leave Session'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _leaveAsHost(context),
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text('Leave Session (Transfer Host)'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            if (!canEdit) ...[
              const SizedBox(height: 8),
              Text(
                'This session is from the past and cannot be edited',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  void _copyJoinCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.session.joinCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Join code copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _navigateToItems(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SessionItemsScreen(session: widget.session),
      ),
    );
  }

  void _navigateToPaymentSummary(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentSummaryScreen(session: widget.session),
      ),
    );
  }

  void _navigateToMyItems(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MyItemsScreen(session: widget.session),
      ),
    );
  }

  void _navigateToGuestManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GuestManagementScreen(session: widget.session),
      ),
    );
  }

  Future<void> _leaveSession(BuildContext context) async {
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final shouldLeave = await _showLeaveConfirmationDialog(context);
    if (!shouldLeave || !mounted) return;

    final success = await sessionProvider.leaveSession(widget.session.id);

    if (mounted) {
      if (success) {
        navigator.pop(); // Go back to session lobby
        messenger.showSnackBar(
          SnackBar(
            content: Text('You have left "${widget.session.displayName}"'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to leave session: ${sessionProvider.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showLeaveConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Leave Session'),
          content: Text(
            'Are you sure you want to leave "${widget.session.displayName}"?\n\n'
            'You will lose access to this session and any items you\'ve added or been assigned to.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  String _formatTime(String timeString) {
    try {
      // Parse time string (assuming format like "14:30:00" or "14:30")
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        // Format as 24-hour time without seconds
        return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      }
      return timeString; // Return original if parsing fails
    } catch (e) {
      return timeString; // Return original if parsing fails
    }
  }

  Future<void> _deleteSession(BuildContext context) async {
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final shouldDelete = await _showDeleteConfirmationDialog(context);
    if (!shouldDelete || !mounted) return;

    final success = await sessionProvider.deleteSession(widget.session.id);

    if (mounted) {
      if (success) {
        navigator.pop(); // Go back to session lobby
        messenger.showSnackBar(
          SnackBar(
            content: Text('Session "${widget.session.displayName}" has been deleted'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to delete session: ${sessionProvider.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Session'),
          content: Text(
            'Are you sure you want to delete "${widget.session.displayName}"?\n\n'
            'This action cannot be undone and will:\n'
            '• Remove the session for all participants\n'
            '• Delete all items and assignments\n'
            '• Clear all payment information',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<void> _leaveAsHost(BuildContext context) async {
    final navigator = Navigator.of(context);

    // Show dialog explaining the host needs to transfer privileges first
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Leave Session as Host'),
          content: const Text(
            'As the session host, you need to transfer host privileges to another participant before leaving.\n\n'
            'Would you like to go to the Guests screen to select a new host?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Select New Host'),
            ),
          ],
        );
      },
    ) ?? false;

    if (shouldProceed && mounted) {
      // Navigate to guest management screen
      navigator.push(
        MaterialPageRoute(
          builder: (context) => GuestManagementScreen(session: widget.session),
        ),
      );
    }
  }
}
