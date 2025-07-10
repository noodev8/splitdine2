import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../models/session.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final SessionService _sessionService = SessionService();
  final _joinCodeController = TextEditingController();
  String? _userDisplayName;

  @override
  void initState() {
    super.initState();
    // Load user data to ensure display name is correct
    _loadUserData();
  }

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.isAnonymous) {
        _userDisplayName = 'Guest';
      } else {
        // Try to get display name from Firestore user document
        final appUser = await _authService.getUserDocument(user.uid);
        if (appUser != null) {
          _userDisplayName = appUser.displayName;
        } else {
          // Fallback to Firebase Auth display name
          _userDisplayName = user.displayName ?? user.email?.split('@').first ?? 'User';
        }
      }
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
  }

  Future<void> _createNewSession() async {
    final restaurantNameController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Session'),
        content: TextField(
          controller: restaurantNameController,
          decoration: const InputDecoration(
            labelText: 'Restaurant Name (Optional)',
            hintText: 'Enter restaurant name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, restaurantNameController.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final session = await _sessionService.createSession(
          restaurantName: result.isNotEmpty ? result : null,
        );
        
        if (session != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Session created! Join code: ${session.joinCode}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating session: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _getDisplayName(User? user) {
    // Use the loaded display name if available
    if (_userDisplayName != null) {
      return _userDisplayName!;
    }

    // Fallback logic
    if (user == null) return 'Guest';
    if (user.isAnonymous) return 'Guest';
    // Prioritize displayName over email
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    return user.email?.split('@').first ?? 'User';
  }

  String _getStatusText(User? user) {
    if (user == null) return 'Not signed in';
    if (user.isAnonymous) return 'You are signed in as a guest';
    return 'You are signed in with ${user.email}';
  }

  Future<void> _joinSession() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Session'),
        content: TextField(
          controller: _joinCodeController,
          decoration: const InputDecoration(
            labelText: 'Join Code',
            hintText: 'Enter 6-digit code',
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _joinCodeController.text),
            child: const Text('Join'),
          ),
        ],
      ),
    );

    if (result != null && result.length == 6) {
      try {
        final session = await _sessionService.joinSession(result);
        
        if (session != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Joined session: ${session.restaurantName ?? "Unnamed"}'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session not found or already completed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error joining session: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        // Reload user data when auth state changes
        if (snapshot.hasData && _userDisplayName == null) {
          _loadUserData();
        }

        return _buildHomeContent(user);
      },
    );
  }

  Widget _buildHomeContent(User? user) {
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Dine'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${_getDisplayName(user)}!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getStatusText(user),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Your Sessions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: StreamBuilder<List<Session>>(
                stream: _sessionService.getUserSessions(user?.uid ?? ''),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }
                  
                  final sessions = snapshot.data ?? [];
                  
                  if (sessions.isEmpty) {
                    return const Center(
                      child: Text('No sessions found. Create or join a session!'),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(session.restaurantName ?? 'Unnamed Session'),
                          subtitle: Text(
                            'Status: ${session.status.name} • '
                            'Participants: ${session.participants.length}',
                          ),
                          trailing: Text('Code: ${session.joinCode}'),
                          onTap: () {
                            // Navigate to session details screen
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Session details coming in Phase 4!'),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'join',
            onPressed: _joinSession,
            tooltip: 'Join Session',
            child: const Icon(Icons.group_add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'create',
            onPressed: _createNewSession,
            tooltip: 'Create Session',
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
