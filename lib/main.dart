import 'package:flutter/material.dart';

void main() {
  runApp(const RezekiDashboardApp());
}

class RezekiDashboardApp extends StatelessWidget {
  const RezekiDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rezeki Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1E40AF),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  void _login(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Rezeki Dashboard',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('WhatsApp CRM untuk PMKS'),
              const SizedBox(height: 32),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _login(context),
                  child: const Text('Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int currentIndex = 0;

  final pages = const [
    InboxPage(),
    ContactsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() => currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox),
            label: 'Inbox',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Contacts',
          ),
        ],
      ),
    );
  }
}

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  final List<Map<String, String>> messages = const [
    {
      'name': 'Ali Kedai Makan',
      'message': 'Boss, pakej ni berapa sebulan?',
      'time': '10:25 AM',
    },
    {
      'name': 'Siti Boutique',
      'message': 'Saya nak tanya pasal campaign WhatsApp.',
      'time': '9:10 AM',
    },
    {
      'name': 'Kamal Workshop',
      'message': 'Boleh demo sistem ni?',
      'time': 'Yesterday',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final item = messages[index];

          return ListTile(
            leading: CircleAvatar(
              child: Text(item['name']![0]),
            ),
            title: Text(
              item['name']!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(item['message']!),
            trailing: Text(item['time']!),
          );
        },
      ),
    );
  }
}

class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  final List<Map<String, String>> contacts = const [
    {
      'name': 'Ali Kedai Makan',
      'phone': '012-345 6789',
      'status': 'Interested',
    },
    {
      'name': 'Siti Boutique',
      'phone': '013-888 9999',
      'status': 'New Lead',
    },
    {
      'name': 'Kamal Workshop',
      'phone': '011-222 3333',
      'status': 'Processing',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CRM Contacts')),
      body: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final item = contacts[index];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: Text(
                item['name']!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(item['phone']!),
              trailing: Chip(label: Text(item['status']!)),
            ),
          );
        },
      ),
    );
  }
}