import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu_screen.dart';
import 'pesanan_screen.dart';
import 'wallet_screen.dart';
import 'profile.dart';
import 'package:async/async.dart'; // untuk StreamZip

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String searchQuery = ""; // 🔎 untuk menyimpan text pencarian

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6FA),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =========================================================
          // SIDEBAR
          // =========================================================
          Container(
            width: 230,
            height: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LOGO
                Row(
                  children: [
                    Image.asset(
                      'images/bubur.png',
                      height: 40,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.rice_bowl, size: 36, color: Colors.black),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "BuburKu.",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // MENU ITEMS
                _buildMenuItem(Icons.dashboard, "Dashboard", true, () {}),
                _buildMenuItem(Icons.receipt_long, "Pesanan", false, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PesananScreen()),
                  );
                }),
                _buildMenuItem(Icons.menu_book, "Menu", false, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MenuScreen()),
                  );
                }),
                _buildMenuItem(Icons.account_balance_wallet, "Wallet", false, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WalletScreen()),
                  );
                }),
                _buildMenuItem(Icons.person, "Profile", false, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                }),
              ],
            ),
          ),

          // =========================================================
          // MAIN CONTENT
          // =========================================================
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFFF6F6FA),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 🔎 SEARCH BOX AKTIF
                        Container(
                          width: 250,
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search, color: Colors.grey, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  onChanged: (value) {
                                    setState(() {
                                      searchQuery = value.toLowerCase().trim();
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    hintText: "Cari pesanan...",
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ADMIN INFO
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Hai Admin,",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text("BuburKu", style: TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // TITLE
                    const Text(
                      "Pesanan Realtime.",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // =========================================================
                    // TABLE VIEW — REALTIME FIRESTORE (orders + history)
                    // =========================================================
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: StreamBuilder(
                        stream: StreamZip([
                          FirebaseFirestore.instance.collection("orders").snapshots(),
                          FirebaseFirestore.instance.collection("History").snapshots(),
                        ]),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final orders = (snapshot.data![0] as QuerySnapshot).docs;
                          final history = (snapshot.data![1] as QuerySnapshot).docs;

                          final allOrders = [...orders, ...history];

                          // 🔎 FILTER SEARCH
                          final filteredOrders = allOrders.where((order) {
                            final data = order.data() as Map<String, dynamic>;
                            final orderId = (data["orderId"] ?? "").toString().toLowerCase();
                            final customerName = (data["customerName"] ?? "").toString().toLowerCase();
                            final orderType = (data["orderType"] ?? "").toString().toLowerCase();

                            return orderId.contains(searchQuery) ||
                                customerName.contains(searchQuery) ||
                                orderType.contains(searchQuery);
                          }).toList();

                          if (filteredOrders.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(child: Text("Tidak ditemukan hasil")),
                            );
                          }

                          return Table(
                            columnWidths: const {
                              0: FlexColumnWidth(1.5),
                              1: FlexColumnWidth(1),
                              2: FlexColumnWidth(1.5),
                              3: FlexColumnWidth(1.3),
                            },
                            border: TableBorder.symmetric(
                              inside: BorderSide(color: Colors.grey.shade200),
                            ),
                            children: [
                              _buildTableRow(
                                ["Nomor Pesanan", "Option", "Nama Pelanggan", "Status"],
                                isHeader: true,
                              ),

                              ...filteredOrders.map((order) {
                                final data = order.data() as Map<String, dynamic>;

                                String orderId = data["orderId"] ?? "-";
                                String orderType = data["orderType"] ?? "-";
                                String customerName = data["customerName"] ?? "-";
                                String status = data["status"] ?? "-";

                                Color statusColor = Colors.grey;
                                if (status == "pending") statusColor = Colors.orange;
                                if (status == "process") statusColor = Colors.blue;
                                if (status == "done") statusColor = Colors.green;

                                return _buildTableRow(
                                  [
                                    "Order - $orderId",
                                    orderType,
                                    customerName,
                                    status,
                                  ],
                                  statusColor: statusColor,
                                );
                              }).toList(),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // Sidebar Menu Helper
  // =========================================================
  static Widget _buildMenuItem(
      IconData icon, String title, bool selected, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: selected ? Colors.grey.shade200 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.black87),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.black87,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  // =========================================================
  // Table Row Helper
  // =========================================================
  static TableRow _buildTableRow(List<String> cells,
      {bool isHeader = false, Color? statusColor}) {
    return TableRow(
      decoration: BoxDecoration(
        color: isHeader ? Colors.grey.shade100 : Colors.white,
      ),
      children: cells.asMap().entries.map((entry) {
        final index = entry.key;
        final text = entry.value;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              color: (index == 3 && !isHeader)
                  ? (statusColor ?? Colors.black87)
                  : Colors.black87,
            ),
          ),
        );
      }).toList(),
    );
  }
}
