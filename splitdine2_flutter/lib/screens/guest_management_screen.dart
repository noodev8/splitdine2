import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../models/participant.dart';
import '../services/session_service.dart';
import '../services/session_provider.dart';
import '../services/auth_provider.dart';

class GuestManagementScreen extends StatefulWidget {
  final Session session;

  const GuestManagementScreen({
    super.key,
    required this.session,
  });

  @override
  State<GuestManagementScreen> createState() => _GuestManagementScreenState();
}

class _GuestManagementScreenState extends State<GuestManagementScreen> {
  final SessionService _sessionService = SessionService();
  List<Participant> _participants = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _sessionService.getSessionParticipants(widget.session.id);
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
      setState(() {
        _errorMessage = 'Failed to load participants: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeParticipant(Participant participant) async {
    final shouldRemove = await _showRemoveConfirmationDialog(participant);
    if (!shouldRemove || !mounted) return;

    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final success = await sessionProvider.removeParticipant(widget.session.id, participant.userId);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${participant.displayName} has been removed from the session'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload participants
        _loadParticipants();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove ${participant.displayName}: ${sessionProvider.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _transferHost(Participant participant) async {
    final shouldTransfer = await _showTransferHostConfirmationDialog(participant);
    if (!shouldTransfer || !mounted) return;

    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final success = await sessionProvider.transferHost(widget.session.id, participant.userId);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(); // Go back to session details
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${participant.displayName} is now the session host'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to transfer host privileges: ${sessionProvider.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showRemoveConfirmationDialog(Participant participant) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Participant'),
          content: Text(
            'Are you sure you want to remove ${participant.displayName} from this session?\n\n'
            'This action cannot be undone and they will lose access to the session.',
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
              child: const Text('Remove'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<bool> _showTransferHostConfirmationDialog(Participant participant) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Transfer Host Privileges'),
          content: Text(
            'Are you sure you want to make ${participant.displayName} the new session host?\n\n'
            'You will lose host privileges and they will become the new organizer of this session.',
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
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.id ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guests'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadParticipants,
            tooltip: 'Refresh',
          ),
        ],
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
                        onPressed: _loadParticipants,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Session Info Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.session.displayName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_participants.length} participant${_participants.length == 1 ? '' : 's'}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Participants List
                    Expanded(
                      child: _participants.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No participants found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _participants.length,
                              itemBuilder: (context, index) {
                                final participant = _participants[index];
                                final isOrganizer = participant.userId == widget.session.organizerId;
                                final isCurrentUser = participant.userId == currentUserId;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isOrganizer 
                                          ? Colors.amber.withValues(alpha: 0.2)
                                          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                      child: Text(
                                        participant.displayName.isNotEmpty 
                                            ? participant.displayName[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          color: isOrganizer 
                                              ? Colors.amber.shade700
                                              : Theme.of(context).colorScheme.primary,
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
                                        if (isCurrentUser && !isOrganizer)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'YOU',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          participant.email ?? 'Guest user',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        Text(
                                          'Joined ${_formatJoinedDate(participant.joinedAt)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: widget.session.isHost && !isOrganizer && !isCurrentUser
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.admin_panel_settings),
                                                color: Colors.orange,
                                                onPressed: () => _transferHost(participant),
                                                tooltip: 'Make host',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.remove_circle_outline),
                                                color: Colors.red,
                                                onPressed: () => _removeParticipant(participant),
                                                tooltip: 'Remove participant',
                                              ),
                                            ],
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  String _formatJoinedDate(DateTime joinedAt) {
    final now = DateTime.now();
    final difference = now.difference(joinedAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
