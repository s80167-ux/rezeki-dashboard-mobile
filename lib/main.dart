import 'package:flutter/material.dart';

import 'services/auth_service.dart';
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
      setState(
        () => _errorMessage = 'Google sign-in failed: $e',
      );
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

  final _pages = const [InboxPage(), ContactsPage()];

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
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Inbox Page
// ---------------------------------------------------------------------------

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  final List<Map<String, dynamic>> messages = const [
    {
      'name': 'Ali Kedai Makan',
      'message': 'Boss, pakej ni berapa sebulan? Boleh kurang sikit?',
      'time': '10:25 AM',
      'unread': 2,
      'isUnread': true,
    },
    {
      'name': 'Siti Boutique',
      'message': 'Saya nak tanya pasal campaign WhatsApp untuk Raya ni.',
      'time': '9:10 AM',
      'unread': 0,
      'isUnread': true,
    },
    {
      'name': 'Kamal Workshop',
      'message': 'Boleh demo sistem ni? Saya free petang ni.',
      'time': 'Yesterday',
      'unread': 0,
      'isUnread': false,
    },
    {
      'name': 'Mira Beauty Spa',
      'message': 'Terima kasih! Saya akan cuba dulu untuk sebulan.',
      'time': 'Yesterday',
      'unread': 0,
      'isUnread': false,
    },
    {
      'name': 'Pak Abu Groceries',
      'message': 'Boleh hantar quotation untuk 3 cawangan?',
      'time': 'Mon',
      'unread': 1,
      'isUnread': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RezekiTheme.appBackgroundGradient,
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 72, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inbox',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${messages.where((m) => m['isUnread'] == true).length} unread messages',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: _SearchBar(hint: 'Search conversations...'),
                ),
              ),
              // Message list
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                sliver: SliverList.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final item = messages[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MessageCard(
                        name: item['name'] as String,
                        message: item['message'] as String,
                        time: item['time'] as String,
                        unreadCount: item['unread'] as int,
                        isUnread: item['isUnread'] as bool,
                      ),
                    );
                  },
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
            ],
          ),
        ),
      ),
    );
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

  final List<Map<String, String>> contacts = const [
    {
      'name': 'Ali Kedai Makan',
      'phone': '012-345 6789',
      'status': 'Interested',
      'tag': 'F&B',
    },
    {
      'name': 'Siti Boutique',
      'phone': '013-888 9999',
      'status': 'New Lead',
      'tag': 'Retail',
    },
    {
      'name': 'Kamal Workshop',
      'phone': '011-222 3333',
      'status': 'Processing',
      'tag': 'Services',
    },
    {
      'name': 'Mira Beauty Spa',
      'phone': '017-444 5555',
      'status': 'Closed Won',
      'tag': 'Beauty',
    },
    {
      'name': 'Pak Abu Groceries',
      'phone': '019-666 7777',
      'status': 'Closed Lost',
      'tag': 'Retail',
    },
  ];

  List<Map<String, String>> get _filteredContacts {
    if (_filter == 'All') return contacts;
    return contacts.where((c) => c['status'] == _filter).toList();
  }

  final List<String> _filters = [
    'All',
    'New Lead',
    'Interested',
    'Processing',
    'Closed Won',
    'Closed Lost',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RezekiTheme.appBackgroundGradient,
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header with logout
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 72, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CRM Contacts',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${contacts.length} contacts',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: _SearchBar(hint: 'Search contacts...'),
                ),
              ),
              // Filter chips
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
              // Contact list
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                sliver: SliverList.builder(
                  itemCount: _filteredContacts.length,
                  itemBuilder: (context, index) {
                    final item = _filteredContacts[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ContactCard(
                        name: item['name']!,
                        phone: item['phone']!,
                        status: item['status']!,
                        tag: item['tag']!,
                      ),
                    );
                  },
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
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

class _SearchBar extends StatelessWidget {
  final String hint;
  const _SearchBar({required this.hint});

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

  const _MessageCard({
    required this.name,
    required this.message,
    required this.time,
    required this.unreadCount,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.zero,
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _Avatar(initial: name[0]),
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

  const _ContactCard({
    required this.name,
    required this.phone,
    required this.status,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    final statusColors = _statusColor(status);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.zero,
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _Avatar(initial: name[0]),
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
                        Text(
                          phone,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
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
  const _Avatar({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        gradient: RezekiTheme.primaryGradient,
        borderRadius: BorderRadius.all(Radius.circular(RezekiRadii.avatar)),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
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
