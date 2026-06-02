import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config/app_config.dart';
import 'config/app_version.dart';
import 'services/auth_service.dart';
import 'services/contacts_service.dart';
import 'services/inbox_service.dart';
import 'services/leads_service.dart';
import 'services/quick_replies_service.dart';
import 'theme/rezeki_theme.dart';
import 'widgets/count_up_text.dart';
import 'widgets/gradient_button.dart';
import 'widgets/page_transitions.dart';

// =============================================================================
// Rezeki Dashboard - Kempen Digital Untuk PMKS
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
          backgroundColor: AppColors.backgroundEnd,
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
        gradient: RezekiTheme.loginBackgroundGradient,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 56),
                    // Logo
                    Container(
                          width: 240,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              RezekiRadii.card,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            boxShadow: RezekiTheme.glowShadow,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              RezekiRadii.card,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Image.asset(
                                'assets/logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: Colors.white70,
                                      size: 48,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: -0.2, end: 0, duration: 600.ms),
                    const SizedBox(height: 36),
                    // Title
                    Text(
                          'Rezeki Dashboard',
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 600.ms)
                        .slideY(begin: 0.2, end: 0, duration: 600.ms),
                    const SizedBox(height: 8),
                    // Tagline
                    Text(
                      'Kempen Digital Untuk PMKS',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
                    const SizedBox(height: 44),
                    // Email field
                    _GlassInput(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          enabled: !_isLoading,
                          label: 'Email',
                          hint: 'you@company.com',
                          prefixIcon: Icons.email_outlined,
                        )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 500.ms)
                        .slideY(begin: 0.15, end: 0, duration: 500.ms),
                    const SizedBox(height: 16),
                    // Password field
                    _GlassInput(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          enabled: !_isLoading,
                          onSubmitted: (_) => _signInWithEmail(),
                          label: 'Password',
                          hint: '********',
                          prefixIcon: Icons.lock_outline,
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white70,
                            ),
                            onPressed: _isLoading
                                ? null
                                : () {
                                    setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    );
                                  },
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 500.ms, duration: 500.ms)
                        .slideY(begin: 0.15, end: 0, duration: 500.ms),
                    const SizedBox(height: 10),
                    // Error message
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.errorLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 20),
                    // Login button
                    GradientButton(
                          width: double.infinity,
                          onPressed: _isLoading ? null : _signInWithEmail,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        )
                        .animate()
                        .fadeIn(delay: 600.ms, duration: 500.ms)
                        .slideY(begin: 0.15, end: 0, duration: 500.ms),
                    const SizedBox(height: 20),
                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'or',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Google Sign-In button
                    SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _signInWithGoogle,
                            icon: _GoogleIcon(),
                            label: const Text(
                              'Sign in with Google',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  RezekiRadii.button,
                                ),
                              ),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 700.ms, duration: 500.ms)
                        .slideY(begin: 0.15, end: 0, duration: 500.ms),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
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

class _GlassInput extends StatelessWidget {
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool enabled;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final Widget? suffix;

  const _GlassInput({
    required this.controller,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    this.obscureText = false,
    this.onSubmitted,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(RezekiRadii.input),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        enabled: enabled,
        obscureText: obscureText,
        onSubmitted: onSubmitted,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          prefixIcon: Icon(prefixIcon, color: Colors.white70),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
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
  final GlobalKey<_InboxPageState> _inboxKey = GlobalKey<_InboxPageState>();
  late final List<Widget> _pages = [
    DashboardPage(onSelectTab: _selectTab),
    InboxPage(key: _inboxKey),
    const ContactsPage(),
    SalesPage(onSelectTab: _selectTab),
    const MorePage(),
  ];

  void _selectTab(int index) {
    setState(() => _currentIndex = index);
    if (index == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _inboxKey.currentState?.refreshNow();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _pages[_currentIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  AppColors.primary.withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: RezekiTheme.softShadow,
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                _selectTab(index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'Dashboard',
                ),
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
                  icon: Icon(Icons.trending_up_outlined),
                  selectedIcon: Icon(Icons.trending_up_rounded),
                  label: 'Sales',
                ),
                NavigationDestination(
                  icon: Icon(Icons.more_horiz_outlined),
                  selectedIcon: Icon(Icons.more_horiz_rounded),
                  label: 'More',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard Page
// ---------------------------------------------------------------------------

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.onSelectTab});

  final ValueChanged<int> onSelectTab;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final InboxService _inboxService = InboxService(
    authService: AuthService.instance,
  );
  final ContactsService _contactsService = ContactsService(
    authService: AuthService.instance,
  );
  final LeadsService _leadsService = LeadsService(
    authService: AuthService.instance,
  );
  late Future<_DashboardSnapshot> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  Future<_DashboardSnapshot> _loadDashboard() async {
    final conversationsFuture = _inboxService
        .fetchConversations(days: 30)
        .catchError((_) => const <InboxConversation>[]);
    final contactsFuture = _contactsService
        .fetchContacts(days: 30)
        .catchError((_) => const <CrmContact>[]);
    final leadsFuture = _leadsService.fetchLeads().catchError(
      (_) => const <SalesLead>[],
    );

    final conversations = await conversationsFuture;
    final contacts = await contactsFuture;
    final leads = await leadsFuture;

    return _DashboardSnapshot(
      conversations: conversations,
      contacts: contacts,
      leads: leads,
    );
  }

  Future<void> _refresh() async {
    final future = _loadDashboard();
    setState(() => _dashboardFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final session = AuthService.instance.session.value;
    final user = session?.user;
    final displayName = user?.fullName ?? user?.email ?? 'there';
    final organization = user?.organizationName ?? user?.organizationId;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RezekiTheme.appBackgroundGradient,
        ),
        child: SafeArea(
          child: FutureBuilder<_DashboardSnapshot>(
            future: _dashboardFuture,
            builder: (context, snapshot) {
              final data = snapshot.data ?? _DashboardSnapshot.empty;
              final unread = data.conversations
                  .where((conversation) => conversation.isUnread)
                  .length;
              final activeLeads = data.leads
                  .where((lead) => _isActiveLeadStatus(lead.displayStatus))
                  .length;

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.asset(
                                'assets/logo.png',
                                height: 48,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const SizedBox.shrink();
                                },
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Dashboard',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Hi, $displayName',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              if (organization != null &&
                                  organization.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  organization,
                                  style: const TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _Avatar(
                          initial: displayName,
                          imageUrl: user?.avatarUrl,
                          size: 48,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData)
                      const LinearProgressIndicator(minHeight: 3),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.05,
                      children: [
                        _SummaryCard(
                              icon: Icons.mark_chat_unread_outlined,
                              label: 'Unread Inbox',
                              value: unread.toString(),
                              onTap: () => widget.onSelectTab(1),
                            )
                            .animate()
                            .fadeIn(delay: 0.ms, duration: 500.ms)
                            .slideY(begin: 0.2, end: 0, duration: 500.ms),
                        _SummaryCard(
                              icon: Icons.people_outline,
                              label: 'Total Contacts',
                              value: data.contacts.length.toString(),
                              onTap: () => widget.onSelectTab(2),
                            )
                            .animate()
                            .fadeIn(delay: 100.ms, duration: 500.ms)
                            .slideY(begin: 0.2, end: 0, duration: 500.ms),
                        _SummaryCard(
                              icon: Icons.trending_up_outlined,
                              label: 'Active Leads',
                              value: activeLeads.toString(),
                              onTap: () => widget.onSelectTab(3),
                            )
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 500.ms)
                            .slideY(begin: 0.2, end: 0, duration: 500.ms),
                        _SummaryCard(
                              icon: Icons.today_outlined,
                              label: 'Today Follow-up',
                              value: '0',
                              helper: 'Coming soon',
                              onTap: () => widget.onSelectTab(3),
                            )
                            .animate()
                            .fadeIn(delay: 300.ms, duration: 500.ms)
                            .slideY(begin: 0.2, end: 0, duration: 500.ms),
                      ],
                    ),
                    if (data.isEmpty &&
                        snapshot.connectionState != ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: _InlineNotice(
                          message:
                              'Dashboard data is unavailable right now. Counts will update when inbox and contacts are available.',
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
}

class _DashboardSnapshot {
  const _DashboardSnapshot({
    required this.conversations,
    required this.contacts,
    required this.leads,
  });

  static const empty = _DashboardSnapshot(
    conversations: [],
    contacts: [],
    leads: [],
  );

  final List<InboxConversation> conversations;
  final List<CrmContact> contacts;
  final List<SalesLead> leads;

  bool get isEmpty =>
      conversations.isEmpty && contacts.isEmpty && leads.isEmpty;
}

// ---------------------------------------------------------------------------
// Sales Page
// ---------------------------------------------------------------------------

class SalesPage extends StatefulWidget {
  const SalesPage({super.key, required this.onSelectTab});

  final ValueChanged<int> onSelectTab;

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  static const _filters = [
    'All',
    'New Lead',
    'Contacted',
    'Interested',
    'Processing',
    'Closed Won',
    'Closed Lost',
  ];

  final LeadsService _leadsService = LeadsService(
    authService: AuthService.instance,
  );
  final ContactsService _contactsService = ContactsService(
    authService: AuthService.instance,
  );
  late Future<_SalesSnapshot> _salesFuture;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _salesFuture = _loadSales();
  }

  Future<_SalesSnapshot> _loadSales() async {
    final leadsFuture = _leadsService.fetchLeads();
    final contactsFuture = _contactsService
        .fetchContacts(days: 30)
        .catchError((_) => const <CrmContact>[]);

    final leads = await leadsFuture;
    final contacts = await contactsFuture;
    final contactsById = {
      for (final contact in contacts)
        if (contact.id.isNotEmpty) contact.id: contact,
    };

    return _SalesSnapshot(leads: leads, contactsById: contactsById);
  }

  Future<void> _refresh() async {
    final future = _loadSales();
    setState(() => _salesFuture = future);
    await future;
  }

  List<SalesLead> _visibleLeads(List<SalesLead> leads) {
    if (_selectedFilter == 'All') return leads;
    return leads
        .where(
          (lead) => _normalizeStatus(lead.displayStatus) == _selectedFilter,
        )
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
          child: FutureBuilder<_SalesSnapshot>(
            future: _salesFuture,
            builder: (context, snapshot) {
              final data = snapshot.data ?? _SalesSnapshot.empty;
              final leads = data.leads;
              final visibleLeads = _visibleLeads(leads);
              final statusCounts = _leadStatusCounts(leads);

              return RefreshIndicator(
                onRefresh: _refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sales',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Daily CRM execution',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                        child: _PipelineSummary(
                          total: leads.length,
                          newLead: statusCounts['New Lead'] ?? 0,
                          interested: statusCounts['Interested'] ?? 0,
                          processing: statusCounts['Processing'] ?? 0,
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
                            return _FilterChip(
                              label: filter,
                              isSelected: _selectedFilter == filter,
                              onTap: () =>
                                  setState(() => _selectedFilter = filter),
                            );
                          },
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                        child: _SalesSectionHeader(
                          title: 'My Leads',
                          subtitle: '${visibleLeads.length} leads',
                        ),
                      ),
                    ),
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        leads.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _PageStateMessage(
                          icon: Icons.sync_outlined,
                          title: 'Loading sales',
                          message: 'Fetching leads from Rezeki.',
                        ),
                      )
                    else if (snapshot.hasError)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _PageStateMessage(
                          icon: Icons.error_outline,
                          title: 'Sales unavailable',
                          message: _errorText(snapshot.error),
                          actionLabel: 'Retry',
                          onAction: _refresh,
                        ),
                      )
                    else if (visibleLeads.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _PageStateMessage(
                          icon: Icons.trending_up_outlined,
                          title: 'No leads found',
                          message:
                              'Leads created in the sales pipeline will appear here.',
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        sliver: SliverList.builder(
                          itemCount: visibleLeads.length,
                          itemBuilder: (context, index) {
                            final lead = visibleLeads[index];
                            final contact = data.contactsById[lead.contactId];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _LeadCard(
                                lead: lead,
                                contact: contact,
                                onTap: () => _openLead(lead),
                              ),
                            );
                          },
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        child: Column(
                          children: const [
                            _SalesPlaceholderSection(
                              title: 'Follow-up Today',
                              message: 'Follow-up scheduling is coming soon.',
                            ),
                            SizedBox(height: 12),
                            _SalesPlaceholderSection(
                              title: 'Recently Updated',
                              message:
                                  'Recent sales activity will appear here when available.',
                            ),
                          ],
                        ),
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
    if (error is LeadsServiceException) return error.message;
    if (error is AuthServiceException) return error.message;
    return 'Unable to load leads.';
  }

  Future<void> _openLead(SalesLead lead) async {
    await Navigator.of(
      context,
    ).push(FadeThroughPageRoute(page: LeadDetailPage(lead: lead)));
    if (!mounted) return;
    final future = _loadSales();
    setState(() => _salesFuture = future);
  }
}

class _SalesSnapshot {
  const _SalesSnapshot({required this.leads, required this.contactsById});

  static const empty = _SalesSnapshot(leads: [], contactsById: {});

  final List<SalesLead> leads;
  final Map<String, CrmContact> contactsById;
}

// ---------------------------------------------------------------------------
// Lead Detail Page
// ---------------------------------------------------------------------------

class LeadDetailPage extends StatefulWidget {
  const LeadDetailPage({super.key, required this.lead});

  final SalesLead lead;

  @override
  State<LeadDetailPage> createState() => _LeadDetailPageState();
}

class _LeadDetailPageState extends State<LeadDetailPage> {
  static const _statusOptions = [
    ('new_lead', 'New Lead'),
    ('contacted', 'Contacted'),
    ('interested', 'Interested'),
    ('processing', 'Processing'),
    ('closed_won', 'Closed Won'),
    ('closed_lost', 'Closed Lost'),
  ];

  final LeadsService _leadsService = LeadsService(
    authService: AuthService.instance,
  );
  late Future<SalesLead> _leadFuture;
  bool _isSavingStatus = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _leadFuture = _leadsService.fetchLead(widget.lead.id);
  }

  Future<void> _refresh() async {
    final future = _leadsService.fetchLead(widget.lead.id);
    setState(() => _leadFuture = future);
    await future;
  }

  Future<void> _updateStatus(SalesLead lead, String status) async {
    if (_isSavingStatus || status == lead.status) return;
    setState(() {
      _isSavingStatus = true;
      _errorMessage = null;
    });

    try {
      final updated = await _leadsService.updateLead(
        leadId: lead.id,
        status: status,
      );
      if (!mounted) return;
      setState(() => _leadFuture = Future.value(updated));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lead status updated.')));
    } on LeadsServiceException catch (error) {
      setState(() => _errorMessage = error.message);
    } on AuthServiceException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = 'Unable to update lead status.');
    } finally {
      if (mounted) setState(() => _isSavingStatus = false);
    }
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
          child: FutureBuilder<SalesLead>(
            future: _leadFuture,
            initialData: widget.lead,
            builder: (context, snapshot) {
              final lead = snapshot.data ?? widget.lead;
              final status = _normalizeStatus(lead.displayStatus);

              return RefreshIndicator(
                onRefresh: _refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _SimpleDetailHeader(
                        title: lead.name,
                        subtitle: lead.phone,
                        icon: Icons.trending_up_outlined,
                      ),
                    ),
                    if (snapshot.hasError || _errorMessage != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: _InlineNotice(
                            message:
                                _errorMessage ?? _leadError(snapshot.error),
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      sliver: SliverList.list(
                        children: [
                          _DetailSection(
                            title: 'Lead',
                            children: [
                              _DetailRow(
                                icon: Icons.flag_outlined,
                                label: 'Status',
                                value: status,
                              ),
                              _DetailRow(
                                icon: Icons.source_outlined,
                                label: 'Source',
                                value: lead.source ?? 'Not set',
                              ),
                              _DetailRow(
                                icon: Icons.local_fire_department_outlined,
                                label: 'Temperature',
                                value: lead.temperatureLabel ?? 'Not set',
                              ),
                              _DetailRow(
                                icon: Icons.schedule_outlined,
                                label: 'Updated',
                                value: _formatNullableDate(lead.updatedAt),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: DropdownButtonFormField<String>(
                                initialValue: lead.status,
                                decoration: const InputDecoration(
                                  labelText: 'Update status',
                                  prefixIcon: Icon(Icons.swap_horiz_outlined),
                                ),
                                items: _statusOptions
                                    .map(
                                      (option) => DropdownMenuItem(
                                        value: option.$1,
                                        child: Text(option.$2),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _isSavingStatus
                                    ? null
                                    : (value) {
                                        if (value != null) {
                                          _updateStatus(lead, value);
                                        }
                                      },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _DetailSection(
                            title: 'Customer',
                            children: [
                              _DetailRow(
                                icon: Icons.person_outline,
                                label: 'Name',
                                value: lead.name,
                              ),
                              _DetailRow(
                                icon: Icons.phone_outlined,
                                label: 'Phone',
                                value: lead.phone,
                              ),
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

  String _leadError(Object? error) {
    if (error is LeadsServiceException) return error.message;
    if (error is AuthServiceException) return error.message;
    return 'Unable to load lead detail.';
  }

  String _formatNullableDate(DateTime? value) {
    if (value == null) return 'Not available';
    return '${value.day}/${value.month}/${value.year}';
  }
}

// ---------------------------------------------------------------------------
// More Page
// ---------------------------------------------------------------------------

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AuthService.instance.session.value;
    final user = session?.user;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RezekiTheme.appBackgroundGradient,
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              Text('More', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  gradient: RezekiTheme.tealPurpleGradient,
                  borderRadius: BorderRadius.all(Radius.circular(RezekiRadii.card)),
                  boxShadow: RezekiTheme.elevatedShadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      _Avatar(
                        initial: user?.fullName ?? user?.email ?? 'U',
                        imageUrl: user?.avatarUrl,
                        size: 64,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? user?.email ?? 'Signed in',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            if (user?.email != null &&
                                user?.fullName != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                user!.email!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            if ((user?.organizationName ??
                                    user?.organizationId) !=
                                null) ...[
                              const SizedBox(height: 6),
                              Text(
                                user?.organizationName ?? user!.organizationId!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    _MoreMenuTile(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () => Navigator.of(
                        context,
                      ).push(FadeThroughPageRoute(page: const SettingsPage())),
                    )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 400.ms)
                        .slideY(begin: 0.1, end: 0, duration: 400.ms),
                    _MoreMenuTile(
                      icon: Icons.support_agent_outlined,
                      label: 'Help / Support',
                      onTap: () => _showComingSoon(context),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 400.ms)
                        .slideY(begin: 0.1, end: 0, duration: 400.ms),
                    _MoreMenuTile(
                      icon: Icons.info_outline,
                      label: 'About App',
                      onTap: () => _showAboutDialog(context),
                    )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 400.ms)
                        .slideY(begin: 0.1, end: 0, duration: 400.ms),
                    _MoreMenuTile(
                      icon: Icons.logout_outlined,
                      label: 'Logout',
                      destructive: true,
                      onTap: () => _logout(context),
                    )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 400.ms)
                        .slideY(begin: 0.1, end: 0, duration: 400.ms),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Coming soon.')));
  }

  Future<void> _showAboutDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rezeki Dashboard'),
        content: FutureBuilder<String>(
          future: AppVersion.releaseLabel(),
          builder: (context, snapshot) {
            final releaseLabel = snapshot.data ?? 'Release ...';
            return Text('Kempen Digital Untuk PMKS\n$releaseLabel');
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
}

// ---------------------------------------------------------------------------
// Inbox Page
// ---------------------------------------------------------------------------

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> with WidgetsBindingObserver {
  final InboxService _inboxService = InboxService(
    authService: AuthService.instance,
  );
  late Future<List<InboxConversation>> _conversationsFuture;
  StreamSubscription<InboxUpdateEvent>? _inboxEventsSubscription;
  Timer? _conversationRefreshDebounce;
  bool _isPollingConversations = false;
  String _inboxSearch = '';
  String _inboxFilter = 'All';
  int? _activityDays;
  final List<String> _inboxFilters = ['All', 'Unread', 'WhatsApp', 'Social'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _conversationsFuture = _inboxService.fetchConversations(
      days: _activityDays,
      forceRefresh: true,
    );
    _inboxEventsSubscription = _inboxService.watchInboxEvents().listen(
      _handleInboxEvent,
      onError: (_) {
        // Realtime reconnects internally; keep the visible inbox stable.
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _conversationRefreshDebounce?.cancel();
    _inboxEventsSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshNow();
    }
  }

  void refreshNow() {
    _inboxService.clearInboxCaches();
    unawaited(_pollConversations(force: true));
  }

  void _handleInboxEvent(InboxUpdateEvent event) {
    final organizationId =
        AuthService.instance.session.value?.user.organizationId;
    if (organizationId != null &&
        organizationId.isNotEmpty &&
        event.organizationId != organizationId) {
      return;
    }

    _scheduleConversationRefresh();
  }

  void _scheduleConversationRefresh() {
    _conversationRefreshDebounce?.cancel();
    _conversationRefreshDebounce = Timer(
      const Duration(milliseconds: 750),
      refreshNow,
    );
  }

  Future<void> _pollConversations({bool force = false}) async {
    if (_isPollingConversations && !force) return;
    _isPollingConversations = true;
    try {
      _inboxService.clearInboxCaches();
      final conversations = await _inboxService.fetchConversations(
        days: _activityDays,
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() => _conversationsFuture = Future.value(conversations));
    } catch (_) {
      // Keep the current inbox visible if a background refresh fails.
    } finally {
      _isPollingConversations = false;
    }
  }

  Future<void> _refresh() async {
    _inboxService.clearInboxCaches();
    final future = _inboxService.fetchConversations(
      days: _activityDays,
      forceRefresh: true,
    );
    setState(() => _conversationsFuture = future);
    await future;
  }

  void _setActivityDays(int? days) {
    if (_activityDays == days) return;
    _inboxService.clearInboxCaches();
    final future = _inboxService.fetchConversations(
      days: days,
      forceRefresh: true,
    );
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
        .toList()
      ..sort(InboxConversation.compareByLatestMessageDesc);
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
                                hasSales: item.hasSales,
                                salesLabel: item.salesLabel,
                                salesStatus: item.salesStatus,
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
      FadeThroughPageRoute(page: InboxThreadPage(conversation: conversation)),
    );
    if (!mounted) return;
    _inboxService.clearInboxCaches();
    final future = _inboxService.fetchConversations(
      days: _activityDays,
      forceRefresh: true,
    );
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

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[value.month - 1];
    return '${value.day} $month ${value.year}';
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
  static const _salesStatusOptions = [
    ('new_lead', 'New Lead'),
    ('contacted', 'Contacted'),
    ('interested', 'Interested'),
    ('processing', 'Processing'),
  ];
  static const _salesOrderStatusOptions = [
    ('open', 'Open'),
    ('closed_won', 'Closed Won'),
    ('closed_lost', 'Closed Lost'),
  ];
  final InboxService _inboxService = InboxService(
    authService: AuthService.instance,
  );
  final QuickRepliesService _quickRepliesService = QuickRepliesService(
    authService: AuthService.instance,
  );
  static const int? _activityDays = null;
  static const int _initialMessagePageSize = 15;
  static const int _olderMessagePageSize = 5;
  final TextEditingController _composerController = TextEditingController();
  late InboxConversation _conversation;
  late Future<List<InboxMessage>> _messagesFuture;
  StreamSubscription<InboxUpdateEvent>? _inboxEventsSubscription;
  Timer? _messageRefreshDebounce;
  List<InboxMessage> _messages = const [];
  MessagePagination? _messagesPagination;
  bool _isPollingMessages = false;
  bool _isLoadingOlderMessages = false;
  bool _isRefreshingConversation = false;
  bool _isSending = false;
  bool _isAiThinking = false;
  bool _isCheckingAiAvailability = true;
  bool _isAiAssistEnabled = false;
  List<QuickReply> _quickReplies = const [];
  String _composerText = '';
  String? _sendError;
  String? _aiError;
  AiInboxAssistResult? _aiResult;
  InboxMessage? _replyDraft;
  bool _isForwarding = false;
  bool _isCreatingSales = false;

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    _inboxService.clearInboxCaches();
    _messagesFuture = _loadLatestMessages();
    unawaited(_refreshConversationSnapshot());
    _composerController.addListener(_handleComposerChanged);
    _loadAiAssistAvailability();
    _loadQuickReplies();
    _inboxEventsSubscription = _inboxService.watchInboxEvents().listen(
      _handleInboxEvent,
      onError: (_) {
        // Realtime reconnects internally; keep the visible thread stable.
      },
    );
  }

  @override
  void dispose() {
    _messageRefreshDebounce?.cancel();
    _inboxEventsSubscription?.cancel();
    _composerController.removeListener(_handleComposerChanged);
    _composerController.dispose();
    super.dispose();
  }

  void _handleComposerChanged() {
    final text = _composerController.text;
    if (text == _composerText) return;
    setState(() => _composerText = text);
  }

  Future<void> _refresh() async {
    _inboxService.clearInboxCaches();
    setState(() {
      _messages = const [];
      _messagesPagination = null;
    });
    final future = _loadLatestMessages();
    setState(() => _messagesFuture = future);
    await future;
    await _refreshConversationSnapshot();
  }

  void _handleInboxEvent(InboxUpdateEvent event) {
    if (event.conversationId != _conversation.id) {
      return;
    }

    _scheduleMessageRefresh();
  }

  void _scheduleMessageRefresh() {
    _messageRefreshDebounce?.cancel();
    _messageRefreshDebounce = Timer(
      const Duration(milliseconds: 750),
      () => unawaited(_pollMessages()),
    );
  }

  Future<void> _pollMessages() async {
    if (_isPollingMessages) return;
    _isPollingMessages = true;
    try {
      final messages = await _loadLatestMessages();
      await _refreshConversationSnapshot();
      if (!mounted) return;
      setState(() => _messagesFuture = Future.value(messages));
    } catch (_) {
      // Keep the current thread visible if a background refresh fails.
    } finally {
      _isPollingMessages = false;
    }
  }

  Future<List<InboxMessage>> _loadLatestMessages({
    bool mergeExisting = false,
  }) async {
    final page = await _inboxService.fetchMessagesPage(
      _conversation.id,
      days: _activityDays,
      limit: _initialMessagePageSize,
    );
    final messages = mergeExisting
        ? _mergeMessages(_messages, page.messages)
        : _sortMessages(page.messages);

    if (mounted) {
      _messages = messages;
      _messagesPagination = _preserveOldestPaginationCursor(
        mergeExisting ? _messagesPagination : null,
        page.pagination,
      );
    }

    return messages;
  }

  Future<void> _refreshConversationSnapshot() async {
    if (_isRefreshingConversation) return;
    _isRefreshingConversation = true;
    try {
      final conversations = await _inboxService.fetchConversations(
        days: _activityDays,
        forceRefresh: true,
      );
      InboxConversation? updated;
      for (final conversation in conversations) {
        if (conversation.id == _conversation.id) {
          updated = conversation;
          break;
        }
      }
      if (!mounted || updated == null) return;
      final refreshedConversation = updated;
      setState(() => _conversation = refreshedConversation);
    } catch (_) {
      // Keep the current conversation header if a background refresh fails.
    } finally {
      _isRefreshingConversation = false;
    }
  }

  Future<void> _loadOlderMessages() async {
    final nextBefore = _messagesPagination?.nextBefore;
    if (_isLoadingOlderMessages ||
        _messagesPagination?.hasMore != true ||
        nextBefore == null) {
      return;
    }

    setState(() => _isLoadingOlderMessages = true);
    try {
      final page = await _inboxService.fetchMessagesPage(
        _conversation.id,
        days: _activityDays,
        limit: _olderMessagePageSize,
        before: nextBefore,
      );
      if (!mounted) return;

      final messages = _mergeMessages(_messages, page.messages);
      setState(() {
        _messages = messages;
        _messagesPagination = page.pagination;
        _messagesFuture = Future.value(messages);
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorText(error))));
    } finally {
      if (mounted) {
        setState(() => _isLoadingOlderMessages = false);
      }
    }
  }

  List<InboxMessage> _mergeMessages(
    List<InboxMessage> existing,
    List<InboxMessage> incoming,
  ) {
    final messagesById = <String, InboxMessage>{
      for (final message in existing) message.id: message,
    };
    for (final message in incoming) {
      messagesById[message.id] = message;
    }
    return _sortMessages(messagesById.values.toList());
  }

  List<InboxMessage> _sortMessages(List<InboxMessage> messages) {
    return [...messages]..sort(InboxMessage.compareByTimelineDesc);
  }

  MessagePagination? _preserveOldestPaginationCursor(
    MessagePagination? current,
    MessagePagination incoming,
  ) {
    if (current == null) return incoming;
    if (!current.hasMore ||
        _isOlderOrSameCursor(current.nextBefore, incoming.nextBefore)) {
      return current;
    }
    return incoming;
  }

  bool _isOlderOrSameCursor(
    MessagePaginationCursor? left,
    MessagePaginationCursor? right,
  ) {
    if (left == null) return false;
    if (right == null) return true;

    final leftTime =
        DateTime.tryParse(left.sentAt)?.millisecondsSinceEpoch ?? 0;
    final rightTime =
        DateTime.tryParse(right.sentAt)?.millisecondsSinceEpoch ?? 0;
    return leftTime < rightTime ||
        (leftTime == rightTime && left.id.compareTo(right.id) <= 0);
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
              _ThreadHeader(conversation: _conversation),
              _ThreadCrmContext(conversation: _conversation),
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
                        itemCount:
                            messages.length +
                            (_messagesPagination?.hasMore == true ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == messages.length) {
                            return _ShowMoreMessagesButton(
                              isLoading: _isLoadingOlderMessages,
                              onPressed: _loadOlderMessages,
                            );
                          }

                          final message = messages[index];
                          return _MessageBubble(
                            message: message,
                            onLongPress: message.isSystem
                                ? null
                                : () => _showMessageActions(message),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              _MessageComposer(
                controller: _composerController,
                enabled: _conversation.whatsappAccountId != null,
                isSending: _isSending,
                isAiThinking: _isAiThinking,
                isCheckingAiAvailability: _isCheckingAiAvailability,
                isAiAssistEnabled: _isAiAssistEnabled,
                aiResult: _aiResult,
                errorMessage: _sendError,
                aiErrorMessage: _aiError,
                replyLabel: _replyDraft == null
                    ? null
                    : _replyLabelForMessage(_replyDraft!),
                replyPreviewText: _replyDraft?.contentText,
                onClearReply: _replyDraft == null ? null : _clearReplyDraft,
                onSend: _sendMessage,
                onAiAction: _runAiAssist,
                onUseAiReply: _useAiReply,
                onQuickReply: _pickQuickReply,
                hasQuickReplies: _quickReplies.isNotEmpty,
                hasDraft: _composerText.trim().isNotEmpty,
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
    final replyToMessageId = _replyDraft?.id;

    setState(() {
      _isSending = true;
      _sendError = null;
    });

    try {
      await _inboxService.sendMessage(
        conversation: _conversation,
        text: text,
        replyToMessageId: replyToMessageId,
      );
      _composerController.clear();
      _aiResult = null;
      _replyDraft = null;
      final future = _loadLatestMessages(mergeExisting: true);
      setState(() => _messagesFuture = future);
      _scheduleStatusRefreshes();
    } on InboxServiceException catch (error) {
      final recovered = await _recoverSentMessageAfterError(text);
      if (!recovered && mounted) {
        setState(() => _sendError = error.message);
      }
    } on AuthServiceException catch (error) {
      final recovered = await _recoverSentMessageAfterError(text);
      if (!recovered && mounted) {
        setState(() => _sendError = error.message);
      }
    } catch (_) {
      final recovered = await _recoverSentMessageAfterError(text);
      if (!recovered && mounted) {
        setState(() => _sendError = 'Unable to send message.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<bool> _recoverSentMessageAfterError(String text) async {
    try {
      final messages = await _loadLatestMessages(mergeExisting: true);
      final normalizedText = text.trim();
      final now = DateTime.now();
      final hasSentMessage = messages.any((message) {
        if (!message.isOutgoing) return false;
        if (message.contentText.trim() != normalizedText) return false;
        final sentAt = message.sentAt;
        if (sentAt == null) return true;
        return now.difference(sentAt).abs() <= const Duration(minutes: 5);
      });

      if (!hasSentMessage || !mounted) return false;

      _composerController.clear();
      _aiResult = null;
      setState(() {
        _messagesFuture = Future.value(messages);
        _sendError = null;
        _replyDraft = null;
      });
      _scheduleStatusRefreshes();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadAiAssistAvailability() async {
    try {
      final status = await _inboxService.fetchAiAssistAvailability();
      if (!mounted) return;
      setState(() {
        _isAiAssistEnabled = status.isEnabled;
        _isCheckingAiAvailability = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAiAssistEnabled = false;
        _isCheckingAiAvailability = false;
        _aiError = 'AI Assist status could not be checked.';
      });
    }
  }

  Future<void> _loadQuickReplies() async {
    try {
      final replies = await _quickRepliesService.fetchQuickReplies();
      if (!mounted) return;
      setState(() => _quickReplies = replies);
    } catch (_) {
      // Quick replies are optional; keep normal reply composition available.
    }
  }

  Future<void> _pickQuickReply() async {
    var replies = _quickReplies;
    if (replies.isEmpty) {
      try {
        replies = await _quickRepliesService.fetchQuickReplies(
          forceRefresh: true,
        );
        if (!mounted) return;
        setState(() => _quickReplies = replies);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quick replies are unavailable.')),
        );
        return;
      }
    }

    if (!mounted) return;
    final selected = await showModalBottomSheet<QuickReply>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: replies.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final reply = replies[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.quickreply_outlined),
                title: Text(reply.title),
                subtitle: Text(
                  reply.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.of(context).pop(reply),
              );
            },
          ),
        );
      },
    );

    if (selected == null) return;
    _composerController.text = selected.body;
    _composerController.selection = TextSelection.fromPosition(
      TextPosition(offset: _composerController.text.length),
    );
    unawaited(
      _quickRepliesService
          .recordUsage(
            templateId: selected.id,
            conversationId: _conversation.id,
          )
          .catchError((_) {}),
    );
  }

  Future<void> _runAiAssist(String action) async {
    final draft = _composerController.text.trim();
    if (_isAiThinking || !_isAiAssistEnabled) return;

    if ((action == 'rewrite_draft' || action == 'check_reply') &&
        draft.isEmpty) {
      setState(() => _aiError = 'Write a draft first for this AI action.');
      return;
    }

    setState(() {
      _isAiThinking = true;
      _aiError = null;
    });

    try {
      final result = await _inboxService.requestAiAssist(
        conversationId: _conversation.id,
        action: action,
        draft: draft.isEmpty ? null : draft,
        tone: action == 'rewrite_draft' ? 'friendly' : 'concise',
      );
      setState(() => _aiResult = result);
    } on InboxServiceException catch (error) {
      if (error.code == 'ai_message_assist_disabled') {
        setState(() {
          _isAiAssistEnabled = false;
          _aiResult = null;
          _aiError = null;
        });
      } else {
        setState(() => _aiError = _friendlyAiError(error.message));
      }
    } on AuthServiceException catch (error) {
      setState(() => _aiError = error.message);
    } catch (_) {
      setState(() => _aiError = 'AI Assist is unavailable right now.');
    } finally {
      if (mounted) {
        setState(() => _isAiThinking = false);
      }
    }
  }

  void _useAiReply(String body) {
    _composerController.text = body;
    _composerController.selection = TextSelection.collapsed(
      offset: _composerController.text.length,
    );
  }

  String _replyLabelForMessage(InboxMessage message) {
    if (message.isOutgoing) return 'You';
    return _conversation.contactName;
  }

  void _clearReplyDraft() {
    if (_replyDraft == null) return;
    setState(() => _replyDraft = null);
  }

  Future<void> _showMessageActions(InboxMessage message) async {
    final canCopy = _canCopyMessageText(message);
    final action = await showModalBottomSheet<_ThreadMessageAction>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply_outlined),
                title: const Text('Reply'),
                onTap: () =>
                    Navigator.of(context).pop(_ThreadMessageAction.reply),
              ),
              ListTile(
                leading: const Icon(Icons.forward_outlined),
                title: const Text('Forward'),
                onTap: () =>
                    Navigator.of(context).pop(_ThreadMessageAction.forward),
              ),
              ListTile(
                leading: Icon(
                  message.hasSales
                      ? Icons.business_center_outlined
                      : Icons.work_outline,
                ),
                title: Text(message.hasSales ? 'View Sales' : 'Create Sales'),
                subtitle: message.hasSales && message.salesLabel != null
                    ? Text(message.salesLabel!)
                    : null,
                onTap: () => Navigator.of(context).pop(
                  message.hasSales
                      ? _ThreadMessageAction.viewSales
                      : _ThreadMessageAction.createSales,
                ),
              ),
              if (canCopy)
                ListTile(
                  leading: const Icon(Icons.copy_all_outlined),
                  title: const Text('Copy text'),
                  onTap: () =>
                      Navigator.of(context).pop(_ThreadMessageAction.copy),
                ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _ThreadMessageAction.reply:
        setState(() => _replyDraft = message);
        return;
      case _ThreadMessageAction.forward:
        await _showForwardPicker(message);
        return;
      case _ThreadMessageAction.createSales:
        await _showCreateSalesSheet(message);
        return;
      case _ThreadMessageAction.viewSales:
        await _viewSales(message);
        return;
      case _ThreadMessageAction.copy:
        await Clipboard.setData(ClipboardData(text: message.contentText));
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Message copied.')));
        return;
    }
  }

  bool _canCopyMessageText(InboxMessage message) {
    final text = message.contentText.trim();
    return text.isNotEmpty && !(text.startsWith('[') && text.endsWith(']'));
  }

  Future<void> _showForwardPicker(InboxMessage message) async {
    if (_isForwarding) return;

    setState(() => _isForwarding = true);
    try {
      final conversations = await _inboxService.fetchConversations(
        forceRefresh: true,
      );
      final targets = conversations
          .where((item) => item.id != _conversation.id)
          .toList();

      if (!mounted) return;
      if (targets.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No other conversations available.')),
        );
        return;
      }

      final target = await showModalBottomSheet<InboxConversation>(
        context: context,
        showDragHandle: true,
        builder: (context) {
          return SafeArea(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: targets.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = targets[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_conversationSourceIcon(item.channel)),
                  title: Text(item.contactName),
                  subtitle: Text(
                    item.lastMessagePreview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.of(context).pop(item),
                );
              },
            ),
          );
        },
      );

      if (!mounted || target == null) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Forward message'),
          content: Text('Forward this message to ${target.contactName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Forward'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      await _inboxService.forwardMessage(
        messageId: message.id,
        targetConversationId: target.id,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message forwarded to ${target.contactName}.')),
      );
    } on InboxServiceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } on AuthServiceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _isForwarding = false);
      }
    }
  }

  Future<void> _showCreateSalesSheet(InboxMessage message) async {
    if (_isCreatingSales || message.hasSales) {
      if (message.hasSales) {
        await _viewSales(message);
      }
      return;
    }

    final salesInput = await showModalBottomSheet<CreateMessageSalesInput>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _CreateMessageSalesSheet(
        customerName: _conversation.contactName,
        messagePreview: message.contentText,
        statusOptions: _salesOrderStatusOptions,
      ),
    );

    if (salesInput == null || !mounted) return;

    setState(() => _isCreatingSales = true);
    try {
      final salesLink = await _inboxService.createSalesFromMessage(
        messageId: message.id,
        conversationId: _conversation.id,
        contactId: _conversation.contactId,
        input: salesInput,
      );
      if (!mounted) return;

      _inboxService.cacheSalesMetadata(
        messageId: message.id,
        conversationId: _conversation.id,
        salesLink: salesLink,
      );

      final updatedMessages = _messages
          .map(
            (item) => item.id == message.id
                ? item.copyWith(
                    hasSales: true,
                    salesId: salesLink.id,
                    salesStatus: salesLink.status,
                    salesLabel: salesLink.label,
                  )
                : item,
          )
          .toList();

      setState(() {
        _conversation = _conversation.copyWith(
          hasSales: true,
          salesId: salesLink.id,
          salesStatus: salesLink.status,
          salesLabel: salesLink.label,
        );
        _messages = updatedMessages;
        _messagesFuture = Future.value(updatedMessages);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${salesLink.label} linked to this message.')),
      );
    } on InboxServiceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } on AuthServiceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _isCreatingSales = false);
      }
    }
  }

  Future<void> _viewSales(InboxMessage message) async {
    final salesId = message.salesId;
    if (salesId == null || salesId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sales are already linked to this message.'),
        ),
      );
      return;
    }

    final displayStatus =
        message.salesLabel ??
        message.salesStatus ??
        _salesStatusOptions.first.$2;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LeadDetailPage(
          lead: SalesLead(
            id: salesId,
            contactId: _conversation.contactId ?? '',
            status: message.salesStatus ?? 'new_lead',
            displayStatus: _normalizeStatus(displayStatus),
            name: _conversation.contactName,
            phone: 'No phone',
          ),
        ),
      ),
    );
  }

  void _scheduleStatusRefreshes() {
    for (final delay in const [
      Duration(seconds: 2),
      Duration(seconds: 6),
      Duration(seconds: 12),
    ]) {
      Future<void>.delayed(delay, () {
        if (!mounted) return;
        setState(() {
          _messagesFuture = _loadLatestMessages(mergeExisting: true);
        });
      });
    }
  }

  String _friendlyAiError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('usage') || lower.contains('credit')) {
      return 'AI Assist limit has been reached for this workspace.';
    }
    if (lower.contains('not enabled')) {
      return 'AI Assist is not enabled for this workspace.';
    }
    return 'AI Assist could not complete that action. You can still reply normally.';
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
    final future = _contactsService.fetchContacts(
      days: _activityDays,
      forceRefresh: true,
    );
    setState(() => _contactsFuture = future);
    await future;
  }

  void _setActivityDays(int? days) {
    if (_activityDays == days) return;
    final future = _contactsService.fetchContacts(
      days: days,
      forceRefresh: true,
    );
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
    await Navigator.of(
      context,
    ).push(FadeThroughPageRoute(page: ContactDetailPage(contact: contact)));
    if (!mounted) return;
    final future = _contactsService.fetchContacts(
      days: _activityDays,
      forceRefresh: true,
    );
    setState(() => _contactsFuture = future);
  }

  Future<void> _openCreateContact() async {
    final created = await Navigator.of(
      context,
    ).push<CrmContact>(FadeThroughPageRoute(page: const ContactCreatePage()));

    if (created == null || !mounted) return;
    final future = _contactsService.fetchContacts(
      days: _activityDays,
      forceRefresh: true,
    );
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
                            title: 'Sales / Lead',
                            children: [
                              _DetailRow(
                                icon: Icons.verified_user_outlined,
                                label: 'Status',
                                value: contact.status.isEmpty
                                    ? 'Not set'
                                    : contact.status,
                              ),
                              _DetailRow(
                                icon: Icons.label_outline,
                                label: 'Tag',
                                value: contact.tag.isEmpty
                                    ? 'Not set'
                                    : contact.tag,
                              ),
                              const _DetailRow(
                                icon: Icons.today_outlined,
                                label: 'Follow-up',
                                value: 'Coming soon',
                              ),
                              const _DetailRow(
                                icon: Icons.history_outlined,
                                label: 'Last Activity',
                                value: 'Coming soon',
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
      FadeThroughPageRoute(page: ContactEditPage(contact: contact)),
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

bool _isActiveLeadStatus(String status) {
  return !{'Closed Won', 'Closed Lost'}.contains(_normalizeStatus(status));
}

String _normalizeStatus(String status) {
  final normalized = status.trim().toLowerCase().replaceAll('_', ' ');
  switch (normalized) {
    case 'new':
    case 'new lead':
      return 'New Lead';
    case 'contacted':
      return 'Contacted';
    case 'interested':
      return 'Interested';
    case 'processing':
      return 'Processing';
    case 'closed won':
    case 'won':
      return 'Closed Won';
    case 'closed lost':
    case 'lost':
      return 'Closed Lost';
    case 'active':
      return 'New Lead';
    default:
      if (status.trim().isEmpty) return 'New Lead';
      return status.trim();
  }
}

Map<String, int> _leadStatusCounts(List<SalesLead> leads) {
  final counts = <String, int>{};
  for (final lead in leads) {
    final status = _normalizeStatus(lead.displayStatus);
    counts[status] = (counts[status] ?? 0) + 1;
  }
  return counts;
}

({Color bg, Color fg}) _statusColors(String status) {
  switch (_normalizeStatus(status)) {
    case 'Closed Won':
      return (bg: AppColors.successLight, fg: AppColors.success);
    case 'Closed Lost':
      return (bg: AppColors.errorLight, fg: AppColors.error);
    case 'Interested':
    case 'Contacted':
      return (bg: AppColors.interestedLight, fg: AppColors.primary);
    case 'Processing':
      return (bg: AppColors.warningLight, fg: AppColors.warning);
    case 'New Lead':
    default:
      return (bg: AppColors.newLeadLight, fg: AppColors.newLead);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.helper,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? helper;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gradient = switch (label) {
      'Unread Inbox' => RezekiTheme.primaryGradient,
      'Total Contacts' => RezekiTheme.tealPurpleGradient,
      'Active Leads' => RezekiTheme.amberRoseGradient,
      _ => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      ),
    };
    final iconFg = Colors.white;
    final textPrimary = Colors.white;
    final textSecondary = Colors.white70;

    return Card(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RezekiRadii.card),
        side: BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(RezekiRadii.card),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(RezekiRadii.card),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(RezekiRadii.sm),
                  ),
                  child: Icon(icon, color: iconFg, size: 20),
                ),
                const Spacer(),
                CountUpText(
                  end: int.tryParse(value) ?? 0,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (helper != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    helper!,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PipelineSummary extends StatelessWidget {
  const _PipelineSummary({
    required this.total,
    required this.newLead,
    required this.interested,
    required this.processing,
  });

  final int total;
  final int newLead;
  final int interested;
  final int processing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RezekiTheme.surfaceGlassGradient,
        borderRadius: BorderRadius.circular(RezekiRadii.card),
        boxShadow: RezekiTheme.elevatedShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SalesSectionHeader(
            title: 'Pipeline Summary',
            subtitle: 'Lead status overview',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(label: 'Total', value: total),
              ),
              Expanded(
                child: _MiniMetric(label: 'New', value: newLead),
              ),
              Expanded(
                child: _MiniMetric(label: 'Interested', value: interested),
              ),
              Expanded(
                child: _MiniMetric(label: 'Processing', value: processing),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CountUpText(
          end: value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SalesSectionHeader extends StatelessWidget {
  const _SalesSectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _LeadCard extends StatelessWidget {
  const _LeadCard({required this.lead, required this.onTap, this.contact});

  final SalesLead lead;
  final CrmContact? contact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _normalizeStatus(lead.displayStatus);
    final tag =
        lead.source ?? contact?.companyName ?? lead.temperatureLabel ?? 'Lead';
    final displayName = contact?.name ?? lead.name;
    final phone =
        _usablePhone(contact?.phone) ?? _usablePhone(lead.phone) ?? 'No phone';
    final accentColor = _statusColors(status).fg;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(RezekiRadii.card),
        boxShadow: RezekiTheme.elevatedShadow,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(RezekiRadii.card),
          onTap: onTap,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  color: accentColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                child: Row(
                  children: [
                    _Avatar(
                      initial: displayName.isEmpty ? '?' : displayName[0],
                      imageUrl: contact?.avatarUrl,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            phone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _StatusChip(
                                label: status,
                                colors: _statusColors(status),
                              ),
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
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05, end: 0, duration: 400.ms);
  }

  String? _usablePhone(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.toLowerCase() == 'no phone' ? null : trimmed;
  }
}

class _SalesPlaceholderSection extends StatelessWidget {
  const _SalesPlaceholderSection({required this.title, required this.message});

  final String title;
  final String message;

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
            const SizedBox(height: 6),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _MoreMenuTile extends StatelessWidget {
  const _MoreMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : AppColors.textPrimary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RezekiRadii.card),
      ),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: destructive ? AppColors.errorLight : AppColors.secondary,
          borderRadius: BorderRadius.circular(RezekiRadii.sm),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      trailing: destructive
          ? null
          : const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: onTap,
    );
  }
}

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
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(RezekiRadii.card),
              ),
              child: Icon(icon, color: AppColors.textTertiary, size: 32),
            ),
            const SizedBox(height: 16),
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

class _CreateMessageSalesSheet extends StatefulWidget {
  const _CreateMessageSalesSheet({
    required this.customerName,
    required this.messagePreview,
    required this.statusOptions,
  });

  final String customerName;
  final String messagePreview;
  final List<(String, String)> statusOptions;

  @override
  State<_CreateMessageSalesSheet> createState() =>
      _CreateMessageSalesSheetState();
}

class _CreateMessageSalesSheetState extends State<_CreateMessageSalesSheet> {
  late String _status;
  bool _showAdvanced = false;
  String? _error;
  final TextEditingController _currencyController = TextEditingController(
    text: 'MYR',
  );
  final TextEditingController _productTypeController = TextEditingController();
  final TextEditingController _packageNameController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController _premiseAddressController =
      TextEditingController();
  final TextEditingController _businessTypeController = TextEditingController();
  final TextEditingController _contactPersonController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _expectedCloseDateController =
      TextEditingController();
  final TextEditingController _coverageStatusController =
      TextEditingController();
  final TextEditingController _documentStatusController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _status = widget.statusOptions.first.$1;
  }

  @override
  void dispose() {
    _currencyController.dispose();
    _productTypeController.dispose();
    _packageNameController.dispose();
    _unitPriceController.dispose();
    _quantityController.dispose();
    _premiseAddressController.dispose();
    _businessTypeController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _expectedCloseDateController.dispose();
    _coverageStatusController.dispose();
    _documentStatusController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Sales', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text(
              'Create the sales order and first item line.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              'Customer: ${widget.customerName}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(RezekiRadii.input),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                widget.messagePreview,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                prefixIcon: Icon(Icons.work_outline),
              ),
              items: widget.statusOptions
                  .map(
                    (option) => DropdownMenuItem(
                      value: option.$1,
                      child: Text(option.$2),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _status = value);
              },
            ),
            const SizedBox(height: 12),
            _textField(
              label: 'Currency',
              controller: _currencyController,
              icon: Icons.payments_outlined,
              refreshOnChange: true,
            ),
            const SizedBox(height: 12),
            _textField(
              label: 'Product Type',
              controller: _productTypeController,
              hint: 'Fixed, Mobile, Solution',
              icon: Icons.category_outlined,
            ),
            const SizedBox(height: 12),
            _textField(
              label: 'Package Name',
              controller: _packageNameController,
              hint: 'Unifi Biz 100Mbps',
              icon: Icons.inventory_2_outlined,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _unitPriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Unit Price',
                      hintText: '111',
                      prefixIcon: Icon(Icons.attach_money_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      prefixIcon: Icon(Icons.numbers_outlined),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.muted,
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Estimated total: ${_currencyLabel()} ${_estimatedTotal().toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
              icon: Icon(
                _showAdvanced
                    ? Icons.expand_less_outlined
                    : Icons.expand_more_outlined,
              ),
              label: Text(
                _showAdvanced
                    ? 'Hide advanced details'
                    : 'Show advanced details',
              ),
            ),
            if (_showAdvanced) ...[
              _textField(
                label: 'Premise Address',
                controller: _premiseAddressController,
                minLines: 3,
                maxLines: 4,
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 12),
              _textField(
                label: 'Business Type',
                controller: _businessTypeController,
                icon: Icons.storefront_outlined,
              ),
              const SizedBox(height: 12),
              _textField(
                label: 'Contact Person',
                controller: _contactPersonController,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _textField(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 12),
              _textField(
                label: 'Expected Close Date',
                controller: _expectedCloseDateController,
                hint: 'yyyy-mm-dd',
                keyboardType: TextInputType.datetime,
                icon: Icons.event_outlined,
              ),
              const SizedBox(height: 12),
              _textField(
                label: 'Coverage Status',
                controller: _coverageStatusController,
                hint: 'pending, checked, available',
                icon: Icons.fact_check_outlined,
              ),
              const SizedBox(height: 12),
              _textField(
                label: 'Document Status',
                controller: _documentStatusController,
                hint: 'not_started, pending, completed',
                icon: Icons.description_outlined,
              ),
              const SizedBox(height: 12),
              _textField(
                label: 'Notes',
                controller: _notesController,
                minLines: 3,
                maxLines: 4,
                icon: Icons.notes_outlined,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.business_center_outlined),
                label: const Text('Create Sales'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    int minLines = 1,
    int maxLines = 1,
    IconData? icon,
    bool refreshOnChange = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      onChanged: refreshOnChange ? (_) => setState(() {}) : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon),
      ),
    );
  }

  void _submit() {
    final unitPrice = double.tryParse(_unitPriceController.text.trim());
    final quantity = int.tryParse(_quantityController.text.trim());

    if (unitPrice == null || !unitPrice.isFinite || unitPrice < 0) {
      setState(() {
        _error = 'Unit price must be a valid non-negative number.';
      });
      return;
    }

    if (quantity == null || quantity <= 0) {
      setState(() {
        _error = 'Quantity must be a whole number greater than 0.';
      });
      return;
    }

    Navigator.of(context).pop(
      CreateMessageSalesInput(
        status: _status,
        currency: _currencyLabel(),
        productType: _blankToNull(_productTypeController.text),
        packageName: _blankToNull(_packageNameController.text),
        unitPrice: unitPrice,
        quantity: quantity,
        premiseAddress: _blankToNull(_premiseAddressController.text),
        businessType: _blankToNull(_businessTypeController.text),
        contactPerson: _blankToNull(_contactPersonController.text),
        emailAddress: _blankToNull(_emailController.text),
        expectedCloseDate: _blankToNull(_expectedCloseDateController.text),
        coverageStatus: _blankToNull(_coverageStatusController.text),
        documentStatus: _blankToNull(_documentStatusController.text),
        notes: _blankToNull(_notesController.text),
      ),
    );
  }

  double _estimatedTotal() {
    final unitPrice = double.tryParse(_unitPriceController.text.trim()) ?? 0;
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    if (!unitPrice.isFinite || quantity <= 0) return 0;
    return unitPrice * quantity;
  }

  String _currencyLabel() {
    final value = _currencyController.text.trim();
    return value.isEmpty ? 'MYR' : value;
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _ThreadHeader extends StatelessWidget {
  const _ThreadHeader({required this.conversation});

  final InboxConversation conversation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 10),
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
                        conversation.sourceDescription,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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

class _ThreadCrmContext extends StatelessWidget {
  const _ThreadCrmContext({required this.conversation});

  final InboxConversation conversation;

  @override
  Widget build(BuildContext context) {
    final status = conversation.leadStatus;
    final tag = conversation.tag ?? conversation.whatsappAccountLabel;
    final hasContext =
        (status != null && status.isNotEmpty) ||
        (tag != null && tag.isNotEmpty);

    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (status != null && status.isNotEmpty)
                _StatusChip(label: status, colors: _statusColors(status)),
              if (tag != null && tag.isNotEmpty) _TagChip(label: tag),
              if (!hasContext) const _TagChip(label: 'CRM status not set'),
            ],
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

class _ShowMoreMessagesButton extends StatelessWidget {
  const _ShowMoreMessagesButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.expand_less_outlined, size: 18),
          label: Text(isLoading ? 'Loading...' : 'Show more'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, this.onLongPress});

  final InboxMessage message;
  final VoidCallback? onLongPress;

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
    final presentation = message.presentation;

    final borderRadius = isSystem
        ? BorderRadius.circular(RezekiRadii.input)
        : isOutgoing
        ? const BorderRadius.only(
            topLeft: Radius.circular(RezekiRadii.input),
            topRight: Radius.circular(RezekiRadii.input),
            bottomLeft: Radius.circular(RezekiRadii.input),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(RezekiRadii.input),
            topRight: Radius.circular(RezekiRadii.input),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(RezekiRadii.input),
          );

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.78,
      ),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: borderRadius,
        border: isOutgoing
            ? null
            : Border.all(color: AppColors.border.withValues(alpha: 0.75)),
        boxShadow: isSystem ? null : RezekiTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: isOutgoing
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.replyPreviewText != null &&
              message.replyPreviewText!.isNotEmpty) ...[
            _ReplySnippet(
              text: message.replyPreviewText!,
              isOutgoing: isOutgoing,
            ),
            const SizedBox(height: 8),
          ],
          if (presentation.isMedia)
            _MessageAttachmentView(
              presentation: presentation,
              isOutgoing: isOutgoing,
            )
          else
            Text(
              presentation.title,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: isSystem ? FontWeight.w500 : FontWeight.w400,
                height: 1.35,
              ),
            ),
          if (message.hasSales) ...[
            const SizedBox(height: 8),
            _SalesIndicatorChip(
              label:
                  message.salesLabel ??
                  _normalizeStatus(message.salesStatus ?? 'Sales'),
              status: message.salesStatus ?? message.salesLabel,
              compact: true,
            ),
          ],
          const SizedBox(height: 6),
          if (_messageTimestamp != null ||
              (isOutgoing && _MessageStatusLabel.hasVisibleStatus(message)))
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_messageTimestamp != null)
                  Flexible(
                    child: Text(
                      _formatMessageTime(_messageTimestamp!),
                      style: TextStyle(
                        color: isOutgoing
                            ? Colors.white.withValues(alpha: 0.85)
                            : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (isOutgoing &&
                    _MessageStatusLabel.hasVisibleStatus(message)) ...[
                  if (_messageTimestamp != null) const SizedBox(width: 8),
                  _MessageStatusLabel(message: message),
                ],
              ],
            ),
        ],
      ),
    );

    return Align(
      alignment: isSystem ? Alignment.center : alignment,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: bubble
            .animate()
            .fadeIn(duration: 300.ms)
            .slideX(
              begin: isSystem ? 0 : (isOutgoing ? 0.05 : -0.05),
              end: 0,
              duration: 300.ms,
            ),
      ),
    );
  }

  DateTime? get _messageTimestamp {
    return message.timelineAt;
  }

  String _formatMessageTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class _MessageAttachmentView extends StatelessWidget {
  const _MessageAttachmentView({
    required this.presentation,
    required this.isOutgoing,
  });

  final MessageAttachmentPresentation presentation;
  final bool isOutgoing;

  @override
  Widget build(BuildContext context) {
    final fgColor = isOutgoing ? Colors.white : AppColors.textPrimary;
    final mutedColor = isOutgoing
        ? Colors.white.withValues(alpha: 0.74)
        : AppColors.textSecondary;
    final panelColor = isOutgoing
        ? Colors.white.withValues(alpha: 0.12)
        : AppColors.muted;

    return Container(
      constraints: const BoxConstraints(minWidth: 190),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(RezekiRadii.input),
        border: Border.all(
          color: isOutgoing
              ? Colors.white.withValues(alpha: 0.18)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (presentation.hasImagePreview) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(RezekiRadii.input),
              child: Image.memory(
                base64Decode(presentation.dataBase64!),
                width: 220,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _AttachmentIconPanel(
                    kind: presentation.kind,
                    color: mutedColor,
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ] else
            _AttachmentIconPanel(kind: presentation.kind, color: mutedColor),
          if (presentation.label != null) ...[
            const SizedBox(height: 8),
            Text(
              presentation.label!.toUpperCase(),
              style: TextStyle(
                color: mutedColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            presentation.title,
            style: TextStyle(
              color: fgColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          if (presentation.caption != null) ...[
            const SizedBox(height: 6),
            Text(
              presentation.caption!,
              style: TextStyle(color: mutedColor, fontSize: 13, height: 1.35),
            ),
          ],
          if (presentation.details.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: presentation.details
                  .map(
                    (detail) => Text(
                      detail,
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (presentation.downloadUrl != null &&
              presentation.downloadUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(presentation.downloadUrl!),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new_outlined, size: 16),
              label: const Text('Open attachment'),
              style: OutlinedButton.styleFrom(
                foregroundColor: fgColor,
                side: BorderSide(color: mutedColor.withValues(alpha: 0.55)),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AttachmentIconPanel extends StatelessWidget {
  const _AttachmentIconPanel({required this.kind, required this.color});

  final String kind;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(RezekiRadii.input),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Icon(_iconForKind(kind), color: color, size: 24),
    );
  }

  IconData _iconForKind(String kind) {
    switch (kind) {
      case 'image':
        return Icons.image_outlined;
      case 'video':
        return Icons.videocam_outlined;
      case 'audio':
        return Icons.graphic_eq_outlined;
      case 'document':
        return Icons.description_outlined;
      case 'location':
        return Icons.location_on_outlined;
      case 'contact':
        return Icons.contact_page_outlined;
      case 'sticker':
        return Icons.emoji_emotions_outlined;
      case 'reaction':
        return Icons.favorite_border;
      default:
        return Icons.attach_file_outlined;
    }
  }
}

class _MessageStatusLabel extends StatelessWidget {
  const _MessageStatusLabel({required this.message});

  final InboxMessage message;

  static bool hasVisibleStatus(InboxMessage message) {
    return _statusText(message) != null;
  }

  @override
  Widget build(BuildContext context) {
    final label = _statusText(message);
    if (label == null) {
      return const SizedBox.shrink();
    }
    final color = _ackStatusColor(message.ackStatus);

    return Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    );
  }

  static String? _statusText(InboxMessage message) {
    switch (message.ackStatus) {
      case 'queued':
      case 'pending':
        return _hasConnectorMessageId(message) ? null : 'Sending';
      case 'server_ack':
        return null;
      case 'device_delivered':
        return 'Delivered';
      case 'read':
        return 'Read';
      case 'played':
        return 'Played';
      case 'failed':
        return 'Failed';
      default:
        return null;
    }
  }

  static bool _hasConnectorMessageId(InboxMessage message) {
    final externalId = message.externalMessageId;
    if (externalId == null || externalId.isEmpty) return false;
    return !externalId.startsWith('queued:');
  }

  Color _ackStatusColor(String? status) {
    switch (status) {
      case 'device_delivered':
      case 'played':
      case 'read':
      case 'server_ack':
        return Colors.white.withValues(alpha: 0.78);
      case 'failed':
        return AppColors.errorLight;
      case 'pending':
      case 'queued':
      default:
        return Colors.white.withValues(alpha: 0.68);
    }
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.enabled,
    required this.isSending,
    required this.isAiThinking,
    required this.isCheckingAiAvailability,
    required this.isAiAssistEnabled,
    required this.onSend,
    required this.onAiAction,
    required this.onUseAiReply,
    required this.onQuickReply,
    required this.hasQuickReplies,
    required this.hasDraft,
    this.replyLabel,
    this.replyPreviewText,
    this.onClearReply,
    this.aiResult,
    this.errorMessage,
    this.aiErrorMessage,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool isSending;
  final bool isAiThinking;
  final bool isCheckingAiAvailability;
  final bool isAiAssistEnabled;
  final VoidCallback onSend;
  final ValueChanged<String> onAiAction;
  final ValueChanged<String> onUseAiReply;
  final VoidCallback onQuickReply;
  final bool hasQuickReplies;
  final bool hasDraft;
  final String? replyLabel;
  final String? replyPreviewText;
  final VoidCallback? onClearReply;
  final AiInboxAssistResult? aiResult;
  final String? errorMessage;
  final String? aiErrorMessage;

  @override
  Widget build(BuildContext context) {
    final canType = enabled && !isSending;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
        ),
        boxShadow: RezekiTheme.softShadow,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyPreviewText != null && replyPreviewText!.isNotEmpty) ...[
              _ComposerReplyPreview(
                label: replyLabel ?? 'Replying',
                text: replyPreviewText!,
                onClear: onClearReply,
              ),
              const SizedBox(height: 10),
            ],
            if (enabled) ...[
              _InboxAiAssistPanel(
                isThinking: isAiThinking,
                isCheckingAvailability: isCheckingAiAvailability,
                isEnabled: isAiAssistEnabled,
                result: aiResult,
                errorMessage: aiErrorMessage,
                hasDraft: hasDraft,
                onAction: onAiAction,
                onUseReply: onUseAiReply,
              ),
              const SizedBox(height: 10),
            ],
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
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 44,
                  height: 48,
                  child: IconButton(
                    tooltip: 'Quick replies',
                    onPressed: canType ? onQuickReply : null,
                    icon: Icon(
                      hasQuickReplies
                          ? Icons.quickreply
                          : Icons.quickreply_outlined,
                      color: canType
                          ? AppColors.primary
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
      ),
    );
  }
}

class _InboxAiAssistPanel extends StatelessWidget {
  const _InboxAiAssistPanel({
    required this.isThinking,
    required this.isCheckingAvailability,
    required this.isEnabled,
    required this.hasDraft,
    required this.onAction,
    required this.onUseReply,
    this.result,
    this.errorMessage,
  });

  final bool isThinking;
  final bool isCheckingAvailability;
  final bool isEnabled;
  final bool hasDraft;
  final AiInboxAssistResult? result;
  final String? errorMessage;
  final ValueChanged<String> onAction;
  final ValueChanged<String> onUseReply;

  @override
  Widget build(BuildContext context) {
    final actionButtons = [
      _AiAction('suggest_reply', 'Suggest reply', Icons.lightbulb_outline),
      _AiAction('detect_intent', 'Intent', Icons.manage_search_outlined),
      _AiAction('summarize', 'Summary', Icons.notes_outlined),
      _AiAction('rewrite_draft', 'Improve', Icons.edit_outlined, true),
      _AiAction('check_reply', 'Check', Icons.fact_check_outlined, true),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.muted,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(RezekiRadii.input),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'AI Assist',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isThinking || isCheckingAvailability)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          if (!isCheckingAvailability && !isEnabled) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Assist is not enabled for this workspace. You can still reply normally.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          if (isEnabled)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: actionButtons.map((item) {
                  final disabled =
                      isThinking ||
                      isCheckingAvailability ||
                      (item.needsDraft && !hasDraft);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OutlinedButton.icon(
                      onPressed: disabled ? null : () => onAction(item.action),
                      icon: Icon(item.icon, size: 16),
                      label: Text(item.label),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (result != null) ...[
            const SizedBox(height: 10),
            _AiAssistResultCard(result: result!, onUseReply: onUseReply),
          ],
        ],
      ),
    );
  }
}

class _AiAssistResultCard extends StatelessWidget {
  const _AiAssistResultCard({required this.result, required this.onUseReply});

  final AiInboxAssistResult result;
  final ValueChanged<String> onUseReply;

  @override
  Widget build(BuildContext context) {
    final firstSuggestion = result.suggestedReplies.isEmpty
        ? null
        : result.suggestedReplies.first;
    final reviewNotes = [...result.review.warnings, ...result.review.tips];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(RezekiRadii.input),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.action == 'detect_intent') ...[
            Text(
              '${result.intent.displayLabel} (${(result.intent.confidence * 100).round()}%)',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sentiment: ${result.intent.sentiment}. Urgency: ${result.intent.urgency}.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          if (result.summary != null) ...[
            const Text(
              'Summary',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              result.summary!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
          if (firstSuggestion != null) ...[
            Text(
              firstSuggestion.label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              firstSuggestion.body,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => onUseReply(firstSuggestion.body),
                icon: const Icon(Icons.add_comment_outlined, size: 16),
                label: const Text('Use reply'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ],
          if (result.action == 'check_reply') ...[
            Text(
              'Spam: ${result.review.spamRisk}. Readability: ${result.review.readability}. CTA: ${result.review.ctaClarity}.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            ...reviewNotes
                .take(3)
                .map(
                  (note) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '- $note',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
          ],
          if (result.recommendedAction != null) ...[
            const SizedBox(height: 6),
            Text(
              'Next: ${result.recommendedAction!.replaceAll('_', ' ')}',
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AiAction {
  const _AiAction(
    this.action,
    this.label,
    this.icon, [
    this.needsDraft = false,
  ]);

  final String action;
  final String label;
  final IconData icon;
  final bool needsDraft;
}

class _ContactDetailHeader extends StatelessWidget {
  const _ContactDetailHeader(this.contact, {required this.onEdit});

  final CrmContact contact;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 12),
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

class _SimpleDetailHeader extends StatelessWidget {
  const _SimpleDetailHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 12),
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: RezekiTheme.primaryGradient,
              borderRadius: BorderRadius.circular(RezekiRadii.sm),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 10),
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
        border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(RezekiRadii.input),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactActionBar extends StatefulWidget {
  const _ContactActionBar({required this.contact, required this.onNotice});

  final CrmContact contact;
  final ValueChanged<String> onNotice;

  @override
  State<_ContactActionBar> createState() => _ContactActionBarState();
}

class _ContactActionBarState extends State<_ContactActionBar> {
  final InboxService _inboxService = InboxService(
    authService: AuthService.instance,
  );
  bool _isMessageLoading = false;

  CrmContact get contact => widget.contact;
  bool get _hasPhone => contact.hasPhone && contact.phone != 'No phone';
  bool get _hasEmail => contact.email != null && contact.email!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ContactActionButton(
            icon: Icons.chat_outlined,
            label: 'Message',
            enabled: !_isMessageLoading && contact.id.isNotEmpty,
            isLoading: _isMessageLoading,
            onPressed: _openMessage,
          ),
        ),
        const SizedBox(width: 8),
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
    widget.onNotice('Phone number copied.');
  }

  Future<void> _openMessage() async {
    if (_isMessageLoading) return;

    setState(() => _isMessageLoading = true);
    try {
      final existing = await _inboxService.fetchConversationForContact(
        contact.id,
      );
      if (existing != null) {
        await _openConversation(existing);
        return;
      }

      final sources = await _inboxService.fetchWhatsappSources();
      if (!mounted) return;

      if (sources.isEmpty) {
        widget.onNotice(
          'No WhatsApp source connected. Please connect a WhatsApp source first.',
        );
        return;
      }

      final source = sources.length == 1
          ? sources.first
          : await _pickWhatsappSource(sources);
      if (source == null || !mounted) return;

      final conversation = await _inboxService.createConversationForContact(
        contactId: contact.id,
        whatsappAccountId: source.id,
      );
      if (!mounted) return;

      await _openConversation(conversation);
    } on InboxServiceException catch (error) {
      widget.onNotice(error.message);
    } on AuthServiceException catch (error) {
      widget.onNotice(error.message);
    } catch (_) {
      widget.onNotice('Unable to open this conversation.');
    } finally {
      if (mounted) setState(() => _isMessageLoading = false);
    }
  }

  Future<void> _openConversation(InboxConversation conversation) async {
    await Navigator.of(context).push(
      FadeThroughPageRoute(page: InboxThreadPage(conversation: conversation)),
    );
  }

  Future<WhatsAppSource?> _pickWhatsappSource(
    List<WhatsAppSource> sources,
  ) async {
    return showModalBottomSheet<WhatsAppSource>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose WhatsApp source',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ...sources.map(
                  (source) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.chat_outlined),
                    title: Text(source.label),
                    subtitle: source.subtitle.isEmpty
                        ? null
                        : Text(source.subtitle),
                    onTap: () => Navigator.of(context).pop(source),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launch(Uri uri) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        widget.onNotice('Unable to open this action.');
      }
    } catch (_) {
      widget.onNotice('Unable to open this action.');
    }
  }
}

class _ContactActionButton extends StatelessWidget {
  const _ContactActionButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RezekiRadii.sm),
        ),
        side: BorderSide(
          color: enabled
              ? AppColors.border
              : AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              icon,
              size: 18,
              color: enabled ? AppColors.primary : AppColors.textTertiary,
            ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
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
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
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
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(RezekiRadii.sm),
            ),
            child: Icon(icon, color: AppColors.textTertiary, size: 16),
          ),
          const SizedBox(width: 12),
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
                    height: 1.4,
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
      title: 'Source',
      children: [
        if (sources.isEmpty)
          const _DetailText(value: 'No source linked.')
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(RezekiRadii.input),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: RezekiTheme.softShadow,
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Icon(Icons.search, color: AppColors.textTertiary, size: 20),
          ),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
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
  final bool hasSales;
  final String? salesLabel;
  final String? salesStatus;
  final VoidCallback? onTap;

  const _MessageCard({
    required this.name,
    required this.message,
    required this.time,
    required this.unreadCount,
    required this.isUnread,
    this.avatarUrl,
    this.sourceLabel,
    this.hasSales = false,
    this.salesLabel,
    this.salesStatus,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isUnread
        ? AppColors.primary
        : hasSales
            ? _statusColors(salesStatus ?? salesLabel ?? 'Sales').fg
            : AppColors.border.withValues(alpha: 0.5);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(RezekiRadii.card),
        boxShadow: RezekiTheme.elevatedShadow,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(RezekiRadii.card),
          onTap: onTap,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  color: accentColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                child: Row(
                  children: [
                    _Avatar(initial: name[0], imageUrl: avatarUrl, size: 56),
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
                                      ? AppColors.primary
                                      : AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (sourceLabel != null && sourceLabel!.isNotEmpty) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.account_tree_outlined,
                                      size: 13,
                                      color: AppColors.textTertiary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      sourceLabel!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textTertiary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                if (hasSales)
                                  _SalesIndicatorChip(
                                    label:
                                        salesLabel ??
                                        _normalizeStatus(salesStatus ?? 'Sales'),
                                    status: salesStatus ?? salesLabel,
                                    compact: true,
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
                                    color: AppColors.warning,
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
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05, end: 0, duration: 400.ms);
  }
}

enum _ThreadMessageAction { reply, forward, createSales, viewSales, copy }

class _ReplySnippet extends StatelessWidget {
  const _ReplySnippet({required this.text, required this.isOutgoing});

  final String text;
  final bool isOutgoing;

  @override
  Widget build(BuildContext context) {
    final fgColor = isOutgoing
        ? Colors.white.withValues(alpha: 0.92)
        : AppColors.textPrimary;
    final mutedColor = isOutgoing
        ? Colors.white.withValues(alpha: 0.72)
        : AppColors.textSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isOutgoing
            ? Colors.white.withValues(alpha: 0.14)
            : AppColors.muted,
        borderRadius: BorderRadius.circular(RezekiRadii.input),
        border: Border.all(
          color: isOutgoing
              ? Colors.white.withValues(alpha: 0.18)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Replying to',
            style: TextStyle(
              color: mutedColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fgColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposerReplyPreview extends StatelessWidget {
  const _ComposerReplyPreview({
    required this.label,
    required this.text,
    this.onClear,
  });

  final String label;
  final String text;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(RezekiRadii.input),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(RezekiRadii.badge),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            tooltip: 'Cancel reply',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }
}

class _SalesIndicatorChip extends StatelessWidget {
  const _SalesIndicatorChip({
    required this.label,
    this.status,
    this.compact = false,
  });

  final String label;
  final String? status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors(status ?? label);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(RezekiRadii.badge),
        border: Border.all(color: colors.fg.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            compact ? Icons.work_outline : Icons.business_center_outlined,
            size: compact ? 13 : 14,
            color: colors.fg,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: colors.fg,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
    final accentColor = statusColors.fg;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(RezekiRadii.card),
        boxShadow: RezekiTheme.elevatedShadow,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(RezekiRadii.card),
          onTap: onTap,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  color: accentColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
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
                                    fontWeight: FontWeight.w500,
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
                            runSpacing: 6,
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
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05, end: 0, duration: 400.ms);
  }
}

class _Avatar extends StatelessWidget {
  final String initial;
  final String? imageUrl;
  final double size;

  const _Avatar({required this.initial, this.imageUrl, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final normalizedInitial = initial.trim().isEmpty
        ? '?'
        : initial.trim().substring(0, 1).toUpperCase();
    final normalizedImageUrl = imageUrl?.trim();
    final hasImage =
        normalizedImageUrl != null && normalizedImageUrl.isNotEmpty;
    final token = AuthService.instance.session.value?.accessToken;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: RezekiTheme.primaryGradient,
        borderRadius: const BorderRadius.all(
          Radius.circular(RezekiRadii.avatar),
        ),
        border: hasImage
            ? Border.all(
                color: Colors.white,
                width: 2.5,
              )
            : null,
        boxShadow: hasImage ? RezekiTheme.softShadow : null,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(
          Radius.circular(RezekiRadii.avatar),
        ),
        child: !hasImage
            ? _AvatarInitial(initial: normalizedInitial)
            : Image.network(
                normalizedImageUrl,
                fit: BoxFit.cover,
                headers: token != null && token.isNotEmpty
                    ? {'Authorization': 'Bearer $token'}
                    : null,
                frameBuilder: (
                  context,
                  child,
                  frame,
                  wasSynchronouslyLoaded,
                ) {
                  if (wasSynchronouslyLoaded || frame != null) {
                    return child;
                  }
                  return Center(
                    child: SizedBox(
                      width: size * 0.4,
                      height: size * 0.4,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  );
                },
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
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? RezekiTheme.primaryGradient : null,
          color: isSelected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(RezekiRadii.button),
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
        border: Border.all(color: colors.fg.withValues(alpha: 0.15)),
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
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
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
