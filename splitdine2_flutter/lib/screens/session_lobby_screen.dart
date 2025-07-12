import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/session_provider.dart';
import '../models/session.dart';
import 'create_session_screen.dart';
import 'login_screen.dart';

class SessionLobbyScreen extends StatefulWidget {
  const SessionLobbyScreen({super.key});

  @override
  State<SessionLobbyScreen> createState() => _SessionLobbyScreenState();
}

class _SessionLobbyScreenState extends State<SessionLobbyScreen> {
  @override
  void initState() {
    super.initState();
    // Load sessions when screen initializes, but only if user is authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        Provider.of<SessionProvider>(context, listen: false).loadSessions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Dine'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              if (authProvider.user != null) {
                Provider.of<SessionProvider>(context, listen: false).refreshSessions();
              }
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer2<AuthProvider, SessionProvider>(
        builder: (context, authProvider, sessionProvider, child) {
          final user = authProvider.user;
          
          if (user == null) {
            return const Center(child: Text('Not logged in'));
          }

          if (sessionProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (sessionProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading sessions',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sessionProvider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => sessionProvider.refreshSessions(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // User info header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        user.displayName[0].toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${user.displayName}!',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (user.email != null)
                            Text(
                              user.email!,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          if (user.isAnonymous)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Guest User',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Sessions content
              Expanded(
                child: _buildSessionsContent(sessionProvider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "join",
            onPressed: _handleJoinSession,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.qr_code_scanner, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "create",
            onPressed: _handleCreateSession,
            backgroundColor: Colors.green,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsContent(SessionProvider sessionProvider) {
    final upcomingSessions = sessionProvider.upcomingSessions;
    final pastSessions = sessionProvider.pastSessions;

    if (upcomingSessions.isEmpty && pastSessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No sessions yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new session or join an existing one to get started!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(
                text: 'Upcoming (${upcomingSessions.length})',
                icon: const Icon(Icons.schedule),
              ),
              Tab(
                text: 'Past (${pastSessions.length})',
                icon: const Icon(Icons.history),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildSessionList(upcomingSessions, isUpcoming: true),
                _buildSessionList(pastSessions, isUpcoming: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionList(List<Session> sessions, {required bool isUpcoming}) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.schedule : Icons.history,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? 'No upcoming sessions' : 'No past sessions',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _buildSessionCard(session, isUpcoming: isUpcoming);
      },
    );
  }

  Widget _buildSessionCard(Session session, {required bool isUpcoming}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: session.isHost ? Colors.green : Colors.blue,
          child: Icon(
            session.isHost ? Icons.star : Icons.group,
            color: Colors.white,
          ),
        ),
        title: Text(
          session.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(session.location),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  session.formattedDate,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                if (session.formattedTime.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    session.formattedTime,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              session.isHost ? 'HOST' : 'GUEST',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: session.isHost ? Colors.green : Colors.blue,
              ),
            ),
            if (!isUpcoming)
              Icon(
                Icons.lock,
                size: 16,
                color: Colors.grey.shade400,
              ),
          ],
        ),
        onTap: () {
          // TODO: Navigate to session details
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Session details for ${session.displayName} - Coming Soon!')),
          );
        },
      ),
    );
  }

  void _handleCreateSession() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CreateSessionScreen()),
    );
  }

  void _handleJoinSession() {
    // TODO: Implement join session dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Join Session - Coming Soon!')),
    );
  }

  void _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);

    // Clear session data
    sessionProvider.clearSessions();

    // Logout
    await authProvider.logout();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }
}
