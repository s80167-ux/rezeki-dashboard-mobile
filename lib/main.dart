import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config/app_config.dart';
import 'services/auth_service.dart';
import 'services/contacts_service.dart';
import 'services/inbox_service.dart';
import 'theme/rezeki_theme.dart';

// =============================================================================
// Rezeki Dashboard - WhatsApp CRM for PMKS/SMEs
// Backend Auth Integration (existing WhatsApp CRM v2 API)
// =============================================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.initialize();
  runApp(const RezekiDashboardApp());
}

// ---------------------------------------------------------------------------
// App Root
// ---------------------------------------------------------------------------

class RezekiDashboardApp extends StatelessWidget {
  const RezekiDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rezeki Dashboard',
      debugShowCheckedModeBanner: false,
      theme: RezekiTheme.buildTheme(),
      home: const AuthGate(),
    );
  }
}

// ---------------------------------------------------------------------------
// Auth Gate - watches the saved CRM API session and routes accordingly
// ---------------------------------------------------------------------------

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When user returns from browser OAuth flow, force a rebuild
    // so we pick up the new session immediately.
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthSession?>(
      valueListenable: AuthService.instance.session,
      builder: (context, session, _) {
        if (session != null) {
          return const MainShell();
        }
        return const Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(child: LoginPage()),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Login Page
// ---------------------------------------------------------------------------

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with WidgetsBindingObserver {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AuthService.instance.authError.addListener(_handleAuthError);
    _errorMessage = AuthService.instance.authError.value;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AuthService.instance.authError.removeListener(_handleAuthError);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleAuthError() {
    final message = AuthService.instance.authError.value;
    if (message != null && mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = message;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reset loading when user returns from browser OAuth flow.
    if (state == AppLifecycleState.resumed && _isLoading) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter email and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.signInWithEmail(
        email: email,
        password: password,
      );
    } on AuthServiceException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Login failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.startGoogleSignIn();
      // Native sign-in completes synchronously and saves the session.
      // AuthGate will automatically navigate to MainShell.
    } on AuthServiceException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Google sign-in failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF4F8FF),
        gradient: RezekiTheme.appBackgroundGradient,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 48),
            // Logo
            Container(
              width: 280,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
                boxShadow: RezekiTheme.panelShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.zero,
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.textTertiary,
                        size: 48,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Title
            Text(
              'Rezeki Dashboard',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(color: AppColors.primaryDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Tagline
            Text(
              'Kempen Digital untuk PMKS',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Email field
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'you@company.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),
            // Password field
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              enabled: !_isLoading,
              onSubmitted: (_) => _signInWithEmail(),
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: '********',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textTertiary,
                  ),
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Error message
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),
            // Login button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signInWithEmail,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Login'),
              ),
            ),
            const SizedBox(height: 16),
            // Divider
            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: AppColors.border)),
              ],
            ),
            const SizedBox(height: 16),
            // Google Sign-In button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: _GoogleIcon(),
                label: const Text('Sign in with Google'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Google "G" Icon (Flutter widgets only)
// ---------------------------------------------------------------------------

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main Shell (Bottom Navigation)
// ---------------------------------------------------------------------------

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _pages = const [InboxPage(), ContactsPage(), SettingsPage()];

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _pages[_currentIndex],
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            right: 12,
            child: Material(
              color: AppColors.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: AppColors.border),
              ),
              elevation: 0,
              child: IconButton(
                icon: const Icon(
                  Icons.logout_outlined,
                  color: AppColors.textSecondary,
                ),
                tooltip: 'Log Out',
                onPressed: _logout,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
          ),
          boxShadow: RezekiTheme.softShadow,
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.inbox_outlined),
              selectedIcon: Icon(Icons.inbox_rounded),
              label: 'Inbox',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people_rounded),
              label: 'Contacts',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Inbox Page
// ---------------------------------------------------------------------------

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final InboxService _inboxService = InboxService(
    authService: AuthService.instance,
  );
  late Future<List<InboxConversation>> _conversationsFuture;
  String _inboxSearch = '';
  String _inboxFilter = 'All';
  int? _activityDays = 30;
  final List<String> _inboxFilters = ['All', 'Unread', 'WhatsApp', 'Social'];

  @override
  void initState() {
    super.initState();
    _conversationsFuture = _inboxService.fetchConversations(
      days: _activityDays,
    );
  }

  Future<void> _refresh() async {
    final future = _inboxService.fetchConversations(days: _activityDays);
    setState(() => _conversationsFuture = future);
    await future;
  }

  void _setActivityDays(int? days) {
    if (_activityDays == days) return;
    final future = _inboxService.fetchConversations(days: days);
    setState(() {
      _activityDays = days;
      _conversationsFuture = future;
    });
  }

  List<InboxConversation> _visibleConversations(
    List<InboxConversation> conversations,
  ) {
    return conversations
        .where((conversation) => conversation.matchesFilter(_inboxFilter))
        .where((conversation) => conversation.matchesSearch(_inboxSearch))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RezekiTheme.appBackgroundGradient,
        ),
        child: SafeArea(
          child: FutureBuilder<List<InboxConversation>>(
            future: _conversationsFuture,
            builder: (context, snapshot) {
              final conversations = snapshot.data ?? const [];
              final visibleConversations = _visibleConversations(conversations);
              final unreadCount = conversations
                  .where((conversation) => conversation.isUnread)
                  .length;

              return RefreshIndicator(
                onRefresh: _refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 72, 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Inbox',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$unreadCount unread messages',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            _ActivityRangeMenu(
                              selectedDays: _activityDays,
                              onChanged: _setActivityDays,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                        child: _SearchBar(
                          hint: 'Search conversations...',
                          onChanged: (value) =>
                              setState(() => _inboxSearch = value),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _inboxFilters.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final filter = _inboxFilters[index];
                            final isSelected = _inboxFilter == filter;
                            return _FilterChip(
                              label: filter,
                              isSelected: isSelected,
                              onTap: () =>
                                  setState(() => _inboxFilter = filter),
                            );
                          },
                        ),
                      ),
                    ),
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        conversations.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _PageStateMessage(
                          icon: Icons.sync_outlined,
                          title: 'Loading inbox',
                          message: 'Fetching conversations from Rezeki.',
                        ),
                      )
                    else if (snapshot.hasError)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _PageStateMessage(
                          icon: Icons.error_outline,
                          title: 'Inbox unavailable',
                          message: _errorText(snapshot.error),
                          actionLabel: 'Retry',
                          onAction: _refresh,
                        ),
                      )
                    else if (visibleConversations.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _PageStateMessage(
                          icon: Icons.inbox_outlined,
                          title: 'No conversations found',
                          message:
                              'Matching customer messages will appear here.',
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        sliver: SliverList.builder(
                          itemCount: visibleConversations.length,
                          itemBuilder: (context, index) {
                            final item = visibleConversations[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _MessageCard(
                                name: item.contactName,
                                message: item.lastMessagePreview,
                                time: _formatConversationTime(
                                  item.lastMessageAt,
                                ),
                                unreadCount: item.unreadCount,
                                isUnread: item.isUnread,
                                avatarUrl: item.avatarUrl,
                                sourceLabel: item.sourceDescription,
                                onTap: () => _openConversation(item),
                              ),
                            );
                          },
                        ),
                      ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _errorText(Object? error) {
    if (error is InboxServiceException) return error.message;
    if (error is AuthServiceException) return error.message;
    return 'Unable to load inbox conversations.';
  }

  Future<void> _openConversation(InboxConversation conversation) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InboxThreadPage(conversation: conversation),
      ),
    );
    if (!mounted) return;
    final future = _inboxService.fetchConversations(days: _activityDays);
    setState(() => _conversationsFuture = future);
  }

  String _formatConversationTime(DateTime? value) {
    if (value == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(value.year, value.month, value.day);
    final time =
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

    if (date == today) return time;
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';

    return '${value.day}/${value.month}';
  }
}

// ---------------------------------------------------------------------------
// Inbox Thread Page
// ---------------------------------------------------------------------------

class InboxThreadPage extends StatefulWidget {
  const InboxThreadPage({super.key, required this.conversation});

  final InboxConversation conversation;

  @override
  State<InboxThreadPage> createState() => _InboxThreadPageState();
}

class _InboxThreadPageState extends State<InboxThreadPage> {
  final InboxService _inboxService = InboxService(
    authService: AuthService.instance,
  );
  final TextEditingController _composerController = TextEditingController();
  late Future<List<InboxMessage>> _messagesFuture;
  bool _isSending = false;
  String? _sendError;

  @override
  void initState() {
    super.initState();
    _messagesFuture = _inboxService.fetchMessages(widget.conversation.id);
  }

  @override
  void dispose() {
    _composerController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final future = _inboxService.fetchMessages(widget.conversation.id);
    setState(() => _messagesFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RezekiTheme.appBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _ThreadHeader(conversation: widget.conversation),
              Expanded(
                child: FutureBuilder<List<InboxMessage>>(
                  future: _messagesFuture,
                  builder: (context, snapshot) {
                    final messages = snapshot.data ?? const [];

                    if (snapshot.connectionState == ConnectionState.waiting &&
                        messages.isEmpty) {
                      return const _PageStateMessage(
                        icon: Icons.sync_outlined,
                        title: 'Loading messages',
                        message: 'Fetching this conversation from Rezeki.',
                      );
                    }

                    if (snapshot.hasError) {
                      return _PageStateMessage(
                        icon: Icons.error_outline,
                        title: 'Messages unavailable',
                        message: _errorText(snapshot.error),
                        actionLabel: 'Retry',
                        onAction: _refresh,
                      );
                    }

                    if (messages.isEmpty) {
                      return const _PageStateMessage(
                        icon: Icons.chat_bubble_outline,
                        title: 'No messages yet',
                        message: 'This conversation has no message history.',
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[messages.length - 1 - index];
                          return _MessageBubble(message: message);
                        },
                      ),
                    );
                  },
                ),
              ),
              _MessageComposer(
                controller: _composerController,
                enabled: widget.conversation.whatsappAccountId != null,
                isSending: _isSending,
                errorMessage: _sendError,
                onSend: _sendMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _errorText(Object? error) {
    if (error is InboxServiceException) return error.message;
    if (error is AuthServiceException) return error.message;
    return 'Unable to load messages.';
  }

  Future<void> _sendMessage() async {
    final text = _composerController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _sendError = null;
    });

    try {
      await _inboxService.sendMessage(
        conversation: widget.conversation,
        text: text,
      );
      _composerController.clear();
      final future = _inboxService.fetchMessages(widget.conversation.id);
      setState(() => _messagesFuture = future);
      await future;
    } on InboxServiceException catch (error) {
      setState(() => _sendError = error.message);
    } on AuthServiceException catch (error) {
      setState(() => _sendError = error.message);
    } catch (_) {
      setState(() => _sendError = 'Unable to send message.');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Contacts Page
// ---------------------------------------------------------------------------

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  String _filter = 'All';
  String _search = '';
  int? _activityDays = 30;

  final ContactsService _contactsService = ContactsService(
    authService: AuthService.instance,
  );
  late Future<List<CrmContact>> _contactsFuture;

  @override
  void initState() {
    super.initState();
    _contactsFuture = _contactsService.fetchContacts(days: _activityDays);
  }

  Future<void> _refresh() async {
    final future = _contactsService.fetchContacts(days: _activityDays);
    setState(() => _contactsFuture = future);
    await future;
  }

  void _setActivityDays(int? days) {
    if (_activityDays == days) return;
    final future = _contactsService.fetchContacts(days: days);
    setState(() {
      _activityDays = days;
      _contactsFuture = future;
    });
  }

  List<CrmContact> _filteredContacts(List<CrmContact> contacts) {
    return contacts
        .where((contact) => contact.matchesFilter(_filter))
        .where((contact) => contact.matchesSearch(_search))
        .toList();
  }

  final List<String> _filters = ['All', 'WhatsApp', 'Company', 'No Phone'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RezekiTheme.appBackgroundGradient,
        ),
        child: SafeArea(
          child: FutureBuilder<List<CrmContact>>(
            future: _contactsFuture,
            builder: (context, snapshot) {
              final contacts = snapshot.data ?? const [];
              final visibleContacts = _filteredContacts(contacts);

              return RefreshIndicator(
                onRefresh: _refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 72, 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CRM Contacts',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${contacts.length} contacts',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            _ActivityRangeMenu(
                              selectedDays: _activityDays,
                              onChanged: _setActivityDays,
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: AppColors.primary,
                              ),
                              tooltip: 'Create Contact',
                              onPressed: _openCreateContact,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                        child: _SearchBar(
                          hint: 'Search contacts...',
                          onChanged: (value) => setState(() => _search = value),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _filters.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final filter = _filters[index];
                            final isSelected = _filter == filter;
                            return _FilterChip(
                              label: filter,
                              isSelected: isSelected,
                              onTap: () => setState(() => _filter = filter),
                            );
                          },
                        ),
                      ),
                    ),
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        contacts.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _PageStateMessage(
                          icon: Icons.sync_outlined,
                          title: 'Loading contacts',
                          message: 'Fetching CRM contacts from Rezeki.',
                        ),
                      )
                    else if (snapshot.hasError)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _PageStateMessage(
                          icon: Icons.error_outline,
                          title: 'Contacts unavailable',
                          message: _errorText(snapshot.error),
                          actionLabel: 'Retry',
                          onAction: _refresh,
                        ),
                      )
                    else if (visibleContacts.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _PageStateMessage(
                          icon: Icons.people_outline,
                          title: 'No contacts found',
                          message: 'Matching CRM contacts will appear here.',
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        sliver: SliverList.builder(
                          itemCount: visibleContacts.length,
                          itemBuilder: (context, index) {
                            final item = visibleContacts[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ContactCard(
                                name: item.name,
                                phone: item.phone,
                                status: item.status,
                                tag: item.tag,
                                avatarUrl: item.avatarUrl,
                                onTap: () => _openContact(item),
                              ),
                            );
                          },
                        ),
                      ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _errorText(Object? error) {
    if (error is ContactsServiceException) return error.message;
    if (error is AuthServiceException) return error.message;
    return 'Unable to load CRM contacts.';
  }

  Future<void> _openContact(CrmContact contact) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContactDetailPage(contact: contact),
      ),
    );
    if (!mounted) return;
    final future = _contactsService.fetchContacts(days: _activityDays);
    setState(() => _contactsFuture = future);
  }

  Future<void> _openCreateContact() async {
    final created = await Navigator.of(context).push<CrmContact>(
      MaterialPageRoute(builder: (context) => const ContactCreatePage()),
    );

    if (created == null || !mounted) return;
    final future = _contactsService.fetchContacts(days: _activityDays);
    setState(() => _contactsFuture = future);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Contact created.')));
  }
}

// ---------------------------------------------------------------------------
// Contact Detail Page
// ---------------------------------------------------------------------------

class ContactDetailPage extends StatefulWidget {
  const ContactDetailPage({super.key, required this.contact});

  final CrmContact contact;

  @override
  State<ContactDetailPage> createState() => _ContactDetailPageState();
}

class _ContactDetailPageState extends State<ContactDetailPage> {
  final ContactsService _contactsService = ContactsService(
    authService: AuthService.instance,
  );
  late Future<CrmContact> _contactFuture;

  @override
  void initState() {
    super.initState();
    _contactFuture = _contactsService.fetchContact(widget.contact.id);
  }

  Future<void> _refresh() async {
    final future = _contactsService.fetchContact(widget.contact.id);
    setState(() => _contactFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RezekiTheme.appBackgroundGradient,
        ),
        child: SafeArea(
          child: FutureBuilder<CrmContact>(
            future: _contactFuture,
            initialData: widget.contact,
            builder: (context, snapshot) {
              final contact = snapshot.data ?? widget.contact;

              return RefreshIndicator(
                onRefresh: _refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _ContactDetailHeader(
                        contact,
                        onEdit: () => _openEdit(contact),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: _ContactActionBar(
                          contact: contact,
                          onNotice: _showNotice,
                        ),
                      ),
                    ),
                    if (snapshot.hasError)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: _InlineNotice(
                            message: _errorText(snapshot.error),
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      sliver: SliverList.list(
                        children: [
                          _DetailSection(
                            title: 'Contact',
                            children: [
                              _DetailRow(
                                icon: Icons.phone_outlined,
                                label: 'Phone',
                                value: contact.phone,
                              ),
                              _DetailRow(
                                icon: Icons.email_outlined,
                                label: 'Email',
                                value: contact.email ?? 'Not set',
                              ),
                              _DetailRow(
                                icon: Icons.business_outlined,
                                label: 'Company',
                                value: contact.companyName ?? 'Not set',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _DetailSection(
                            title: 'CRM',
                            children: [
                              _DetailRow(
                                icon: Icons.verified_user_outlined,
                                label: 'Status',
                                value: contact.status,
                              ),
                              _DetailRow(
                                icon: Icons.label_outline,
                                label: 'Tag',
                                value: contact.tag,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _SourceSection(contact: contact),
                          const SizedBox(height: 12),
                          _DetailSection(
                            title: 'Notes',
                            children: [
                              _DetailText(value: contact.notes ?? 'No notes.'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _errorText(Object? error) {
    if (error is ContactsServiceException) return error.message;
    if (error is AuthServiceException) return error.message;
    return 'Unable to load contact detail.';
  }

  void _showNotice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openEdit(CrmContact contact) async {
    final updated = await Navigator.of(context).push<CrmContact>(
      MaterialPageRoute(
        builder: (context) => ContactEditPage(contact: contact),
      ),
    );

    if (updated == null || !mounted) return;
    setState(() => _contactFuture = Future.value(updated));
    _showNotice('Contact updated.');
  }
}

// ---------------------------------------------------------------------------
// Contact Create Page
// ---------------------------------------------------------------------------

class ContactCreatePage extends StatefulWidget {
  const ContactCreatePage({super.key});

  @override
  State<ContactCreatePage> createState() => _ContactCreatePageState();
}

class _ContactCreatePageState extends State<ContactCreatePage> {
  final ContactsService _contactsService = ContactsService(
    authService: AuthService.instance,
  );
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ContactFormScaffold(
      title: 'Create Contact',
      isSaving: _isSaving,
      errorMessage: _errorMessage,
      formKey: _formKey,
      nameController: _nameController,
      phoneController: _phoneController,
      emailController: _emailController,
      companyController: _companyController,
      notesController: _notesController,
      onSave: _save,
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final hasAnyValue = [
      _nameController,
      _phoneController,
      _emailController,
      _companyController,
      _notesController,
    ].any((controller) => controller.text.trim().isNotEmpty);
    if (!hasAnyValue) {
      setState(() => _errorMessage = 'Enter at least one contact field.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final created = await _contactsService.createContact(
        displayName: _blankToNull(_nameController.text),
        phoneNumber: _blankToNull(_phoneController.text),
        email: _blankToNull(_emailController.text),
        companyName: _blankToNull(_companyController.text),
        notes: _blankToNull(_notesController.text),
      );
      if (mounted) Navigator.of(context).pop(created);
    } on ContactsServiceException catch (error) {
      setState(() => _errorMessage = error.message);
    } on AuthServiceException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = 'Unable to create contact.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

// ---------------------------------------------------------------------------
// Contact Edit Page
// ---------------------------------------------------------------------------

class ContactEditPage extends StatefulWidget {
  const ContactEditPage({super.key, required this.contact});

  final CrmContact contact;

  @override
  State<ContactEditPage> createState() => _ContactEditPageState();
}

class _ContactEditPageState extends State<ContactEditPage> {
  final ContactsService _contactsService = ContactsService(
    authService: AuthService.instance,
  );
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _companyController;
  late final TextEditingController _notesController;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.contact.displayName ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.contact.hasPhone ? widget.contact.phone : '',
    );
    _emailController = TextEditingController(text: widget.contact.email ?? '');
    _companyController = TextEditingController(
      text: widget.contact.companyName ?? '',
    );
    _notesController = TextEditingController(text: widget.contact.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RezekiTheme.appBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _EditHeader(
                title: 'Edit Contact',
                isSaving: _isSaving,
                onSave: _save,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (_errorMessage != null) ...[
                          _InlineNotice(message: _errorMessage!),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: _nameController,
                          enabled: !_isSaving,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().length > 160) {
                              return 'Name is too long.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          enabled: !_isSaving,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (value) {
                            final trimmed = (value ?? '').trim();
                            if (trimmed.isNotEmpty && trimmed.length < 6) {
                              return 'Phone must be at least 6 characters.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          enabled: !_isSaving,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            final trimmed = (value ?? '').trim();
                            if (trimmed.isEmpty) return null;
                            final looksValid = RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(trimmed);
                            return looksValid ? null : 'Enter a valid email.';
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _companyController,
                          enabled: !_isSaving,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Company',
                            prefixIcon: Icon(Icons.business_outlined),
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().length > 160) {
                              return 'Company is too long.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _notesController,
                          enabled: !_isSaving,
                          minLines: 4,
                          maxLines: 8,
                          decoration: const InputDecoration(
                            labelText: 'Notes',
                            prefixIcon: Icon(Icons.notes_outlined),
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().length > 2000) {
                              return 'Notes are too long.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updated = await _contactsService.updateContact(
        contactId: widget.contact.id,
        displayName: _blankToNull(_nameController.text),
        phoneNumber: _blankToNull(_phoneController.text),
        email: _blankToNull(_emailController.text),
        companyName: _blankToNull(_companyController.text),
        notes: _blankToNull(_notesController.text),
      );
      if (mounted) Navigator.of(context).pop(updated);
    } on ContactsServiceException catch (error) {
      setState(() => _errorMessage = error.message);
    } on AuthServiceException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = 'Unable to update contact.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

// ---------------------------------------------------------------------------
// Settings / Diagnostics Page
// ---------------------------------------------------------------------------

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AuthService.instance.session.value;
    final user = session?.user;
    final hasGoogleConfig = AppConfig.googleServerClientId.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RezekiTheme.appBackgroundGradient,
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 72, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'App diagnostics',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                sliver: SliverList.list(
                  children: [
                    _SettingsSection(
                      title: 'Account',
                      children: [
                        _SettingsRow(
                          icon: Icons.person_outline,
                          label: 'User',
                          value: user?.fullName ?? user?.email ?? 'Signed in',
                        ),
                        _SettingsRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: user?.email ?? 'Not available',
                        ),
                        _SettingsRow(
                          icon: Icons.business_outlined,
                          label: 'Organization',
                          value:
                              user?.organizationName ??
                              user?.organizationId ??
                              'Not available',
                        ),
                        _SettingsRow(
                          icon: Icons.shield_outlined,
                          label: 'Role',
                          value: user?.role ?? 'Not available',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SettingsSection(
                      title: 'Connection',
                      children: [
                        _SettingsRow(
                          icon: Icons.cloud_outlined,
                          label: 'API',
                          value: AppConfig.apiBaseUrl,
                          copyValue: AppConfig.apiBaseUrl,
                        ),
                        _SettingsRow(
                          icon: Icons.login_outlined,
                          label: 'Google Sign-In',
                          value: hasGoogleConfig ? 'Configured' : 'Missing',
                          valueColor: hasGoogleConfig
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        _SettingsRow(
                          icon: Icons.key_outlined,
                          label: 'Access token',
                          value: session?.accessToken?.isNotEmpty == true
                              ? 'Present'
                              : 'Missing',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SettingsSection(
                      title: 'App',
                      children: const [
                        _SettingsRow(
                          icon: Icons.phone_android_outlined,
                          label: 'Package',
                          value: 'com.example.rezeki_dashboard_app',
                        ),
                        _SettingsRow(
                          icon: Icons.info_outline,
                          label: 'Mode',
                          value: 'Native Flutter',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable Widgets
// ---------------------------------------------------------------------------

class _ContactFormScaffold extends StatelessWidget {
  const _ContactFormScaffold({
    required this.title,
    required this.isSaving,
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    required this.companyController,
    required this.notesController,
    required this.onSave,
    this.errorMessage,
  });

  final String title;
  final bool isSaving;
  final String? errorMessage;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController companyController;
  final TextEditingController notesController;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RezekiTheme.appBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _EditHeader(title: title, isSaving: isSaving, onSave: onSave),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        if (errorMessage != null) ...[
                          _InlineNotice(message: errorMessage!),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: nameController,
                          enabled: !isSaving,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().length > 160) {
                              return 'Name is too long.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: phoneController,
                          enabled: !isSaving,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (value) {
                            final trimmed = (value ?? '').trim();
                            if (trimmed.isNotEmpty && trimmed.length < 6) {
                              return 'Phone must be at least 6 characters.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: emailController,
                          enabled: !isSaving,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            final trimmed = (value ?? '').trim();
                            if (trimmed.isEmpty) return null;
                            final looksValid = RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(trimmed);
                            return looksValid ? null : 'Enter a valid email.';
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: companyController,
                          enabled: !isSaving,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Company',
                            prefixIcon: Icon(Icons.business_outlined),
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().length > 160) {
                              return 'Company is too long.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: notesController,
                          enabled: !isSaving,
                          minLines: 4,
                          maxLines: 8,
                          decoration: const InputDecoration(
                            labelText: 'Notes',
                            prefixIcon: Icon(Icons.notes_outlined),
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().length > 2000) {
                              return 'Notes are too long.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.copyValue,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final String? copyValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textTertiary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (copyValue != null)
            IconButton(
              icon: const Icon(
                Icons.copy_outlined,
                color: AppColors.textTertiary,
                size: 18,
              ),
              tooltip: 'Copy',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: copyValue!));
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Copied.')));
              },
            ),
        ],
      ),
    );
  }
}

class _ActivityRangeMenu extends StatelessWidget {
  const _ActivityRangeMenu({
    required this.selectedDays,
    required this.onChanged,
  });

  final int? selectedDays;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int?>(
      tooltip: 'Activity range',
      initialValue: selectedDays,
      onSelected: onChanged,
      itemBuilder: (context) => const [
        PopupMenuItem<int?>(value: 7, child: Text('Last 7 days')),
        PopupMenuItem<int?>(value: 30, child: Text('Last 30 days')),
        PopupMenuItem<int?>(value: 90, child: Text('Last 90 days')),
        PopupMenuItem<int?>(value: null, child: Text('All time')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(RezekiRadii.input),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.date_range_outlined,
              color: AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              _label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _label {
    switch (selectedDays) {
      case 7:
        return '7d';
      case 30:
        return '30d';
      case 90:
        return '90d';
      default:
        return 'All';
    }
  }
}

class _PageStateMessage extends StatelessWidget {
  const _PageStateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textTertiary, size: 42),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ThreadHeader extends StatelessWidget {
  const _ThreadHeader({required this.conversation});

  final InboxConversation conversation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
        ),
        boxShadow: RezekiTheme.softShadow,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
          _Avatar(
            initial: conversation.contactName[0],
            imageUrl: conversation.avatarUrl,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation.contactName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      _conversationSourceIcon(conversation.channel),
                      color: AppColors.textTertiary,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Source: ${conversation.sourceDescription}',
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _conversationSourceIcon(String? channel) {
  switch (channel) {
    case 'facebook':
      return Icons.facebook_outlined;
    case 'instagram':
    case 'social':
      return Icons.alternate_email_outlined;
    case 'whatsapp':
    default:
      return Icons.chat_outlined;
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final InboxMessage message;

  @override
  Widget build(BuildContext context) {
    final isOutgoing = message.isOutgoing;
    final isSystem = message.isSystem;
    final alignment = isOutgoing ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isSystem
        ? AppColors.muted
        : isOutgoing
        ? AppColors.primary
        : AppColors.surface;
    final textColor = isOutgoing ? Colors.white : AppColors.textPrimary;

    return Align(
      alignment: isSystem ? Alignment.center : alignment,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(RezekiRadii.input),
          border: isOutgoing
              ? null
              : Border.all(color: AppColors.border.withValues(alpha: 0.75)),
          boxShadow: isOutgoing ? RezekiTheme.softShadow : null,
        ),
        child: Column(
          crossAxisAlignment: isOutgoing
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.contentText,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: isSystem ? FontWeight.w500 : FontWeight.w400,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatMessageTime(message.sentAt),
              style: TextStyle(
                color: isOutgoing
                    ? Colors.white.withValues(alpha: 0.72)
                    : AppColors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime? value) {
    if (value == null) return '';
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.enabled,
    required this.isSending,
    required this.onSend,
    this.errorMessage,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool isSending;
  final VoidCallback onSend;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final canType = enabled && !isSending;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
        ),
        boxShadow: RezekiTheme.softShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!enabled || errorMessage != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                errorMessage ??
                    'This conversation is not available for mobile replies.',
                style: TextStyle(
                  color: errorMessage == null
                      ? AppColors.textTertiary
                      : AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: canType,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Write a message...',
                    prefixIcon: Icon(Icons.message_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 48,
                height: 48,
                child: ElevatedButton(
                  onPressed: canType ? onSend : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RezekiRadii.button),
                    ),
                  ),
                  child: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_outlined, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactDetailHeader extends StatelessWidget {
  const _ContactDetailHeader(this.contact, {required this.onEdit});

  final CrmContact contact;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
        ),
        boxShadow: RezekiTheme.softShadow,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
          _Avatar(initial: contact.name[0], imageUrl: contact.avatarUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  contact.phone,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            tooltip: 'Edit Contact',
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

class _EditHeader extends StatelessWidget {
  const _EditHeader({
    required this.title,
    required this.isSaving,
    required this.onSave,
  });

  final String title;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
        ),
        boxShadow: RezekiTheme.softShadow,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
            tooltip: 'Cancel',
            onPressed: isSaving ? null : () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: isSaving ? null : onSave,
            icon: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_outlined),
            label: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(RezekiRadii.input),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.error,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ContactActionBar extends StatelessWidget {
  const _ContactActionBar({required this.contact, required this.onNotice});

  final CrmContact contact;
  final ValueChanged<String> onNotice;

  bool get _hasPhone => contact.hasPhone && contact.phone != 'No phone';
  bool get _hasEmail => contact.email != null && contact.email!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ContactActionButton(
            icon: Icons.call_outlined,
            label: 'Call',
            enabled: _hasPhone,
            onPressed: () => _launch(Uri(scheme: 'tel', path: contact.phone)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ContactActionButton(
            icon: Icons.chat_outlined,
            label: 'WhatsApp',
            enabled: _hasPhone,
            onPressed: () {
              _openWhatsApp();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ContactActionButton(
            icon: Icons.copy_outlined,
            label: 'Copy',
            enabled: _hasPhone,
            onPressed: () {
              _copyPhone();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ContactActionButton(
            icon: Icons.email_outlined,
            label: 'Email',
            enabled: _hasEmail,
            onPressed: () =>
                _launch(Uri(scheme: 'mailto', path: contact.email)),
          ),
        ),
      ],
    );
  }

  Future<void> _copyPhone() async {
    await Clipboard.setData(ClipboardData(text: contact.phone));
    onNotice('Phone number copied.');
  }

  Future<void> _openWhatsApp() async {
    final phone = contact.phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.isEmpty) {
      onNotice('No WhatsApp-ready phone number.');
      return;
    }

    await _launch(Uri.parse('https://wa.me/$phone'));
  }

  Future<void> _launch(Uri uri) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        onNotice('Unable to open this action.');
      }
    } catch (_) {
      onNotice('Unable to open this action.');
    }
  }
}

class _ContactActionButton extends StatelessWidget {
  const _ContactActionButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textTertiary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailText extends StatelessWidget {
  const _DetailText({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        height: 1.4,
      ),
    );
  }
}

class _SourceSection extends StatelessWidget {
  const _SourceSection({required this.contact});

  final CrmContact contact;

  @override
  Widget build(BuildContext context) {
    final sources = contact.sourceLabels;

    return _DetailSection(
      title: 'WhatsApp Sources',
      children: [
        if (sources.isEmpty)
          const _DetailText(value: 'No WhatsApp source linked.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sources.map((label) => _TagChip(label: label)).toList(),
          ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;

  const _SearchBar({required this.hint, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(RezekiRadii.input),
        border: Border.all(color: AppColors.border),
        boxShadow: RezekiTheme.softShadow,
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Icon(Icons.search, color: AppColors.textTertiary),
          ),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String name;
  final String message;
  final String time;
  final int unreadCount;
  final bool isUnread;
  final String? avatarUrl;
  final String? sourceLabel;
  final VoidCallback? onTap;

  const _MessageCard({
    required this.name,
    required this.message,
    required this.time,
    required this.unreadCount,
    required this.isUnread,
    this.avatarUrl,
    this.sourceLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.zero,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _Avatar(initial: name[0], imageUrl: avatarUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isUnread
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isUnread
                                ? AppColors.navy
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (sourceLabel != null && sourceLabel!.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.account_tree_outlined,
                            size: 13,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              sourceLabel!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isUnread
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              color: isUnread
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.orange,
                              borderRadius: BorderRadius.circular(
                                RezekiRadii.badge,
                              ),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String name;
  final String phone;
  final String status;
  final String tag;
  final String? avatarUrl;
  final VoidCallback? onTap;

  const _ContactCard({
    required this.name,
    required this.phone,
    required this.status,
    required this.tag,
    this.avatarUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColors = _statusColor(status);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.zero,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _Avatar(initial: name[0], imageUrl: avatarUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            phone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        _StatusChip(label: status, colors: statusColors),
                        _TagChip(label: tag),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initial;
  final String? imageUrl;

  const _Avatar({required this.initial, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final normalizedInitial = initial.trim().isEmpty
        ? '?'
        : initial.trim().substring(0, 1).toUpperCase();
    final normalizedImageUrl = imageUrl?.trim();

    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        gradient: RezekiTheme.primaryGradient,
        borderRadius: BorderRadius.all(Radius.circular(RezekiRadii.avatar)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(
          Radius.circular(RezekiRadii.avatar),
        ),
        child: normalizedImageUrl == null || normalizedImageUrl.isEmpty
            ? _AvatarInitial(initial: normalizedInitial)
            : Image.network(
                normalizedImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _AvatarInitial(initial: normalizedInitial);
                },
              ),
      ),
    );
  }
}

class _AvatarInitial extends StatelessWidget {
  const _AvatarInitial({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(RezekiRadii.input),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: isSelected ? RezekiTheme.softShadow : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final ({Color bg, Color fg}) colors;

  const _StatusChip({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(RezekiRadii.badge),
        border: Border.all(color: colors.fg.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colors.fg,
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(RezekiRadii.badge),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

({Color bg, Color fg}) _statusColor(String status) {
  switch (status) {
    case 'Active':
      return (bg: AppColors.successLight, fg: AppColors.success);
    case 'New Lead':
      return (bg: AppColors.newLeadLight, fg: AppColors.newLead);
    case 'Interested':
      return (bg: AppColors.interestedLight, fg: AppColors.primary);
    case 'Processing':
      return (bg: AppColors.processingLight, fg: AppColors.primary);
    case 'Closed Won':
      return (bg: AppColors.successLight, fg: AppColors.success);
    case 'Closed Lost':
      return (bg: AppColors.errorLight, fg: AppColors.error);
    default:
      return (bg: AppColors.muted, fg: AppColors.textSecondary);
  }
}
