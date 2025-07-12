import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/session.dart';
import 'session_items_screen.dart';

class SessionDetailsScreen extends StatelessWidget {
  final Session session;

  const SessionDetailsScreen({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final isUpcoming = session.sessionDate.isAfter(DateTime.now().subtract(const Duration(days: 1)));
    final canEdit = isUpcoming;

    return Scaffold(
      appBar: AppBar(
        title: Text(session.displayName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                                session.displayName,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                session.location,
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
                      value: DateFormat('EEEE, MMM d, yyyy').format(session.sessionDate),
                    ),
                    if (session.sessionTime != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        icon: Icons.access_time,
                        label: 'Time',
                        value: _formatTime(session.sessionTime!),
                      ),
                    ],
                    if (session.description != null && session.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        icon: Icons.description,
                        label: 'Description',
                        value: session.description!,
                      ),
                    ],
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: session.isHost ? Icons.star : Icons.person,
                      label: 'Role',
                      value: session.isHost ? 'Host' : 'Guest',
                      valueColor: session.isHost ? Colors.green : Colors.blue,
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
                              session.joinCode,
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

            // Quick Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          context,
                          icon: Icons.receipt_long,
                          label: 'Items',
                          value: '0', // TODO: Get actual count
                        ),
                        _buildSummaryItem(
                          context,
                          icon: Icons.attach_money,
                          label: 'Total',
                          value: '£${session.totalAmount.toStringAsFixed(2)}',
                        ),
                        _buildSummaryItem(
                          context,
                          icon: Icons.people,
                          label: 'People',
                          value: '1+', // TODO: Get actual participant count
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Manage Items Button
            ElevatedButton.icon(
              onPressed: canEdit ? () => _navigateToItems(context) : null,
              icon: const Icon(Icons.list_alt),
              label: Text(canEdit ? 'Manage Items' : 'View Items (Read Only)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: canEdit ? Theme.of(context).colorScheme.primary : Colors.grey,
                foregroundColor: Colors.white,
              ),
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
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
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
    Clipboard.setData(ClipboardData(text: session.joinCode));
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
        builder: (context) => SessionItemsScreen(session: session),
      ),
    );
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
}
