import 'package:flutter/material.dart';

// =======================
// RUTE YANG DIGUNAKAN
// =======================
const String loginRoute = '/login';
const String dashboardRoute = '/dashboard';
const String orderRoute = '/pesanan';
const String menuRoute = '/menu';
const String walletRoute = '/wallet';
const String profileRoute = '/profile';

// =======================
// MODEL MENU ITEM
// =======================
class MenuItem {
  final String title;
  final IconData icon;
  final String route;

  const MenuItem({
    required this.title,
    required this.icon,
    required this.route,
  });
}

// =======================
// DAFTAR MENU ADMIN
// =======================
const List<MenuItem> adminMenuItems = [
  MenuItem(title: 'Dashboard', icon: Icons.dashboard, route: dashboardRoute),
  MenuItem(title: 'Pesanan', icon: Icons.assignment, route: orderRoute),
  MenuItem(title: 'Menu', icon: Icons.menu_book, route: menuRoute),
  MenuItem(title: 'Wallet', icon: Icons.account_balance_wallet, route: walletRoute),
  MenuItem(title: 'Profile', icon: Icons.person, route: profileRoute),
];

// =======================
// TAMPILAN UTAMA ADMIN LAYOUT
// =======================
class AdminLayout extends StatelessWidget {
  final String activeRoute;
  final Widget content;
  final String title;

  const AdminLayout({
    super.key,
    required this.activeRoute,
    required this.content,
    required this.title,
  });

  // =======================
  // BUILD SIDEBAR ITEM
  // =======================
  Widget _buildSidebarItem(BuildContext context, MenuItem item) {
    final bool isSelected = item.route == activeRoute;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        splashColor: Colors.teal.withOpacity(0.2),
        onTap: () {
          if (!isSelected) {
            Navigator.of(context, rootNavigator: true)
                .pushReplacementNamed(item.route);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.teal.shade100 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: isSelected ? Colors.teal.shade800 : Colors.black87,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.teal.shade800 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =======================
  // BUILD SIDEBAR
  // =======================
  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context, rootNavigator: true)
                .pushReplacementNamed(dashboardRoute),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/bubur.png',
                  height: 45,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.restaurant, size: 40, color: Colors.teal),
                ),
                const SizedBox(width: 10),
                const Text(
                  'BuburKu.',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text('Admin Panel',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
          const SizedBox(height: 30),

          Expanded(
            child: ListView.builder(
              itemCount: adminMenuItems.length,
              itemBuilder: (context, index) =>
                  _buildSidebarItem(context, adminMenuItems[index]),
            ),
          ),
        ],
      ),
    );
  }

  // =======================
  // BUILD HEADER (NO SEARCH BAR)
  // =======================
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
        ],
      ),
    );
  }

  // =======================
  // BUILD LAYOUT
  // =======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(context),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                Expanded(
                  child: Container(
                    color: Colors.grey.shade50,
                    child: content,
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
