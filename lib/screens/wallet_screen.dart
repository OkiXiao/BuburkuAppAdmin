import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/admin_layout.dart';

const String walletRoute = '/wallet';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double totalPendapatan = 0;
  List<Map<String, dynamic>> riwayatOrderanDone = [];

  @override
  void initState() {
    super.initState();
    _ambilData();
  }

  // ==== AMBIL DATA DARI HISTORY ====
  Future<void> _ambilData() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('History').get();

      double pendapatan = 0;
      List<Map<String, dynamic>> list = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        pendapatan += (data['totalPrice'] ?? 0);

        list.add({
          "title": data['items'] != null && data['items'].isNotEmpty
              ? data['items'][0]['name'] ?? 'Orderan'
              : 'Orderan',
          "date": (data['createdAt'] is Timestamp)
              ? (data['createdAt'] as Timestamp).toDate().toString()
              : data['createdAt']?.toString() ?? '-',
          "amount": data['totalPrice'] ?? 0,
        });
      }

      setState(() {
        totalPendapatan = pendapatan;
        riwayatOrderanDone = list.reversed.toList(); // terbaru di atas
      });
    } catch (e) {
      print("Error ambil data History: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      activeRoute: walletRoute,
      title: 'Wallet',
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hai Admin,',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // ==== CARD TOTAL PENDAPATAN ====
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Total Pendapatan',
                    value: 'Rp ${totalPendapatan.toStringAsFixed(0)}',
                    subtitle: 'Dari orderan selesai',
                    color: Colors.green.shade100,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // ==== RIWAYAT ORDERAN DONE ====
            const Text(
              'Riwayat Order Selesai',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // ==== LIST RIWAYAT BISA DI SCROLL ====
            Expanded(
              child: riwayatOrderanDone.isEmpty
                  ? const Center(child: Text("Belum ada orderan selesai."))
                  : ListView.builder(
                      itemCount: riwayatOrderanDone.length,
                      itemBuilder: (context, index) {
                        final item = riwayatOrderanDone[index];
                        return _buildTransactionTile(
                          title: item['title'],
                          date: item['date'],
                          amount: "Rp ${item['amount'].toStringAsFixed(0)}",
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ==== CARD COMPONENT ====
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.black54, size: 30),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  // ==== TILE RIWAYAT ORDER ====
  Widget _buildTransactionTile({
    required String title,
    required String date,
    required String amount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: const Icon(Icons.check, color: Colors.green),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(date),
        trailing: Text(
          amount,
          style: TextStyle(
            color: Colors.green.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
