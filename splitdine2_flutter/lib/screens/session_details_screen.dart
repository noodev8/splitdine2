import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../services/session_provider.dart';
import '../services/session_service.dart';

import 'payment_summary_screen.dart';
import 'guest_choices_screen.dart';
import 'add_guest_screen.dart';
import 'host_permissions_screen.dart';

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
  final SessionService _sessionService = SessionService();

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Clean light background
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
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'share_code') {
                _copyJoinCode(context);
              } else if (value == 'add_guest') {
                _navigateToAddGuest(context);
              } else if (value == 'permissions') {
                _navigateToPermissions(context);
              } else if (value == 'leave') {
                _leaveSession(context);
              } else if (value == 'leave_host') {
                _leaveAsHost(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'share_code',
                child: Row(
                  children: [
                    Icon(Icons.qr_code),
                    SizedBox(width: 8),
                    Text('Session Code'),
                  ],
                ),
              ),
              if (widget.session.isHost && !widget.session.isPast)
                const PopupMenuItem<String>(
                  value: 'add_guest',
                  child: Row(
                    children: [
                      Icon(Icons.person_add),
                      SizedBox(width: 8),
                      Text('Add Guest'),
                    ],
                  ),
                ),
              if (widget.session.isHost && !widget.session.isPast)
                const PopupMenuItem<String>(
                  value: 'permissions',
                  child: Row(
                    children: [
                      Icon(Icons.security),
                      SizedBox(width: 8),
                      Text('Permissions'),
                    ],
                  ),
                ),
              if (!widget.session.isHost)
                const PopupMenuItem<String>(
                  value: 'leave',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Leave Session', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              if (widget.session.isHost)
                const PopupMenuItem<String>(
                  value: 'leave_host',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Leave Session (Transfer Host)', style: TextStyle(color: Colors.red)),
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
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Show host icon only for hosts
                        if (widget.session.isHost)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.star,
                              size: 28,
                              color: Colors.amber,
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

                    // Description moved to after buttons

                    // Role removed - no longer displayed
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),


            // Action Cards Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
              children: [
                // Receipt Card
                _buildActionCard(
                  icon: Icons.receipt,
                  title: 'The Bill',
                  subtitle: widget.session.isPast ? 'View items' : 'Manage items',
                  onTap: () => _navigateToGuestChoices(context),
                ),
                // Payment Summary Card
                _buildActionCard(
                  icon: Icons.payment,
                  title: 'Payment',
                  subtitle: 'View summary',
                  onTap: () => _navigateToPaymentSummary(context),
                ),
                // Session Code Card
                _buildSessionCodeCard(),
                // Add Guest Card (only for non-past sessions)
                if (!widget.session.isPast)
                  _buildActionCard(
                    icon: Icons.person_add,
                    title: 'Add Guest',
                    subtitle: 'Invite someone',
                    onTap: () => _navigateToAddGuest(context),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Description section (moved from header)
            if (widget.session.description != null && widget.session.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.session.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Share Session Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (widget.session.allowInvites || widget.session.isHost)
                    ? 'Share this code with others to join:'
                    : 'The host has disabled invitations for this session.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.session.allowInvites || widget.session.isHost 
                          ? widget.session.joinCode 
                          : 'XXXXXX',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 2,
                      ),
                    ),
                    IconButton(
                      onPressed: (widget.session.allowInvites || widget.session.isHost)
                          ? () {
                              Clipboard.setData(ClipboardData(text: widget.session.joinCode));
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Session code copied to clipboard'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.copy),
                      tooltip: 'Copy to clipboard',
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }



  void _navigateToPaymentSummary(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentSummaryScreen(session: widget.session),
      ),
    );
  }


  void _navigateToGuestChoices(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GuestChoicesScreen(session: widget.session),
      ),
    );
  }

  void _navigateToAddGuest(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddGuestScreen(session: widget.session),
      ),
    );
  }

  void _navigateToPermissions(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HostPermissionsScreen(session: widget.session),
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
        // Refresh the session list to ensure UI is updated
        sessionProvider.refreshSessions();
        
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
    // First get the session participants
    try {
      final result = await _sessionService.getSessionParticipants(widget.session.id);
      
      if (!result['success'] || !mounted) return;
      
      final participants = result['participants'] as List;
      // Filter out the current host
      final otherParticipants = participants.where((p) => p.userId != widget.session.organizerId).toList();
      
      if (otherParticipants.isEmpty) {
        // No other participants to transfer to
        await showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Cannot Leave Session'),
              content: const Text(
                'You are the only participant in this session. You cannot leave without first inviting other participants.',
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
        return;
      }
      
      // Show transfer host dialog
      await _showTransferHostDialog(context, otherParticipants);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading participants: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showTransferHostDialog(BuildContext context, List participants) async {
    final selectedParticipant = await showDialog<dynamic>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Transfer Host Privileges'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose who should become the new session host:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: Column(
                    children: participants.map<Widget>((participant) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            participant.displayName.isNotEmpty 
                                ? participant.displayName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(participant.displayName),
                        subtitle: Text(participant.email ?? 'Guest user'),
                        onTap: () => Navigator.of(context).pop(participant),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selectedParticipant != null && mounted) {
      await _performHostTransfer(context, selectedParticipant);
    }
  }

  Future<void> _performHostTransfer(BuildContext context, dynamic newHost) async {
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Host Transfer'),
          content: Text(
            'Transfer host privileges to ${newHost.displayName}?\n\n'
            'You will become a regular participant and will no longer be able to manage the session.',
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
              child: const Text('Transfer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    // Perform the transfer
    final success = await sessionProvider.transferHost(widget.session.id, newHost.userId);

    if (mounted) {
      if (success) {
        // Now leave the session after transferring host privileges
        final leaveSuccess = await sessionProvider.leaveSession(widget.session.id);
        
        if (leaveSuccess) {
          // Refresh the session list to ensure UI is updated
          sessionProvider.refreshSessions();
          
          navigator.pop(); // Go back to session lobby
          messenger.showSnackBar(
            SnackBar(
              content: Text('Host privileges transferred to ${newHost.displayName}. You have left the session.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          navigator.pop(); // Go back to session lobby  
          messenger.showSnackBar(
            SnackBar(
              content: Text('Host transferred but failed to leave session: ${sessionProvider.errorMessage}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to transfer host privileges: ${sessionProvider.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Colors.blue.shade600,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCodeCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: (widget.session.allowInvites || widget.session.isHost)
            ? () {
                Clipboard.setData(ClipboardData(text: widget.session.joinCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Code copied'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('The host has disabled invitations'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.qr_code,
                size: 32,
                color: Colors.green.shade600,
              ),
              const SizedBox(height: 12),
              Text(
                (widget.session.allowInvites || widget.session.isHost)
                    ? widget.session.joinCode
                    : 'XXXXXX',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 1,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                (widget.session.allowInvites || widget.session.isHost)
                    ? 'Tap to copy'
                    : 'Invites disabled',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
