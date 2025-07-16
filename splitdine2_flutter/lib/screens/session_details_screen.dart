import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../services/receipt_provider.dart';
import '../services/assignment_provider.dart';
import '../services/session_provider.dart';

import 'payment_summary_screen.dart';
import 'my_items_screen.dart';
import 'receipt_total_screen.dart';

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
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background
      appBar: AppBar(
        title: Text(
          widget.session.displayName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
            // Restaurant Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Restaurant header with icon
                    Row(
                      children: [
                        Expanded(
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
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6200EE).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.restaurant_menu,
                            size: 28,
                            color: Color(0xFF6200EE),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Date and Time
                    _buildModernInfoRow(
                      icon: Icons.calendar_today,
                      text: DateFormat('EEEE, MMM d, yyyy').format(widget.session.sessionDate),
                    ),
                    const SizedBox(height: 12),
                    if (widget.session.sessionTime != null)
                      _buildModernInfoRow(
                        icon: Icons.access_time,
                        text: _formatTime(widget.session.sessionTime!),
                      ),
                    if (widget.session.sessionTime != null) const SizedBox(height: 12),

                    // Description
                    if (widget.session.description != null && widget.session.description!.isNotEmpty) ...[
                      _buildModernInfoRow(
                        icon: Icons.description,
                        text: widget.session.description!,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Role
                    _buildModernInfoRow(
                      icon: widget.session.isHost ? Icons.star : Icons.person,
                      text: 'Role: ${widget.session.isHost ? 'Host' : 'Guest'}',
                      iconColor: widget.session.isHost ? Colors.amber : const Color(0xFF6200EE),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Session Code Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Session Code',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 1,
                  color: const Color(0xFFE3F2FD), // Light blue background
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.session.joinCode,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: Colors.black87,
                            letterSpacing: 2,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _copyJoinCode(context),
                          icon: const Icon(Icons.copy, size: 24),
                          tooltip: 'Copy session code',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF6200EE),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Share this code with others to join',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),





            const SizedBox(height: 32),

            // Action Buttons
            Column(
              children: [
                // Primary action buttons in a grid
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToMyItems(context),
                        icon: const Icon(Icons.person, size: 20),
                        label: const Text(
                          'My Items',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF6200EE),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToPaymentSummary(context),
                        icon: const Icon(Icons.payment, size: 20),
                        label: const Text(
                          'Payment Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF03DAC6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Bill Total button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToReceiptTotal(context),
                    icon: const Icon(Icons.receipt_long, size: 20),
                    label: const Text(
                      'Bill Total',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF6200EE),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Leave Session button (danger style)
                if (!widget.session.isHost) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _leaveSession(context),
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text(
                        'Leave Session',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: const Color(0xFFB00020),
                        side: const BorderSide(
                          color: Color(0xFFB00020),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _leaveAsHost(context),
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text(
                        'Leave Session (Transfer Host)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: const Color(0xFFB00020),
                        side: const BorderSide(
                          color: Color(0xFFB00020),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

  Widget _buildModernInfoRow({
    required IconData icon,
    required String text,
    Color? iconColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: iconColor ?? const Color(0xFF6200EE),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
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



  void _navigateToReceiptTotal(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReceiptTotalScreen(session: widget.session),
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
    // Show dialog explaining the host cannot leave without transferring privileges
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cannot Leave Session'),
          content: const Text(
            'As the session host, you cannot leave the session without first transferring host privileges to another participant.\n\n'
            'Please use the web interface or contact support to transfer host privileges.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
