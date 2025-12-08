import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/admin_layout.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const String orderRoute = '/pesanan';

class PesananScreen extends StatefulWidget {
  const PesananScreen({super.key});

  @override
  State<PesananScreen> createState() => _PesananScreenState();
}

class _PesananScreenState extends State<PesananScreen> {
  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotification();
    _listenForNewOrders();
  }

  // ================================================================
  //  NOTIFICATION INITIALIZATION
  // ================================================================
  Future<void> _initNotification() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await notifications.initialize(settings);
  }

  // ================================================================
  // DETECT NEW ORDERS (Pending)
  // ================================================================
  void _listenForNewOrders() {
    FirebaseFirestore.instance
        .collection("orders")
        .where("status", isEqualTo: "pending")
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docChanges.isNotEmpty) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            _showNewOrderNotification(change.doc.data()!);
          }
        }
      }
    });
  }

  Future<void> _showNewOrderNotification(Map<String, dynamic> data) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'order_channel',
      'Pesanan Masuk',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await notifications.show(
      0,
      "Pesanan Baru!",
      "Order - ${data["orderId"]} dari ${data["customerName"]}",
      details,
    );
  }

  // ================================================================
  //  BUILD UI
  // ================================================================
  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      activeRoute: orderRoute,
      title: 'Pesanan',
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildOrderStream(
                "orders",
                "pending",
                "Pesanan Baru",
                Colors.tealAccent.shade700,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: _buildOrderStream(
                "orders",
                "process",
                "Dalam Proses",
                Colors.cyan.shade700,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: _buildOrderStream(
                "History",
                "done",
                "Selesai",
                Colors.grey,
                showResetButton: true, // <──── RESET hanya untuk History
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STREAM BUILDER
  Widget _buildOrderStream(String collection, String status, String title,
      Color color, {bool showResetButton = false}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .where("status", isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!.docs;

        return _buildOrderColumn(
          collection,
          title,
          color,
          orders,
          showResetButton: showResetButton,
        );
      },
    );
  }

  // ================================================================
  // COLUMN UI
  // ================================================================
  Widget _buildOrderColumn(String collection, String title,
      Color indicatorColor, List orders,
      {bool showResetButton = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(radius: 6, backgroundColor: indicatorColor),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),

          // ======= RESET BUTTON (KHUSUS HISTORY) =======
          if (showResetButton)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent),
                onPressed: _confirmResetHistory,
                child: const Text("Reset Riwayat", style: TextStyle(color: Colors.white)),
              ),
            ),

          const SizedBox(height: 16),

          Expanded(
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: ListTile(
                    title: Text("Order - ${order["orderId"]}",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: ElevatedButton(
                      onPressed: () => _showOrderDetail(order),
                      child: const Text("Detail"),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // POPUP DETAIL ORDER
  // ================================================================
  void _showOrderDetail(DocumentSnapshot order) {
    final data = order.data() as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: const EdgeInsets.all(16),
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Order - ${data["orderId"]}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const Divider(),

                ...data["items"].map<Widget>((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item["name"],
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text("Rp ${item["price"]}"),
                      ],
                    ),
                  );
                }).toList(),

                const SizedBox(height: 10),
                Text("Nama: ${data["customerName"]}"),
                Text("Meja: ${data["tableNumber"]}"),
                Text("Antrian: ${data["queueNumber"]}"),

                const SizedBox(height: 20),

                Center(
                  child: _buildActionButton(order, data["status"]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================================================================
  // ACTION BUTTONS
  // ================================================================
  Widget _buildActionButton(DocumentSnapshot doc, String status) {
    if (status == "pending") {
      return ElevatedButton(
        onPressed: () => _updateOrderStatus(doc.id, "process"),
        child: const Text("Mulai Proses"),
      );
    }

    if (status == "process") {
      return ElevatedButton(
        onPressed: () => _finishOrder(doc),
        child: const Text("Pesanan Selesai"),
      );
    }

    return const Text("Pesanan Selesai ✔️",
        style: TextStyle(color: Colors.green, fontSize: 16));
  }

  Future<void> _updateOrderStatus(String id, String newStatus) async {
    await FirebaseFirestore.instance.collection("orders").doc(id).update({
      "status": newStatus,
    });

    Navigator.pop(context);
  }

  Future<void> _finishOrder(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;

    data["status"] = "done";

    await FirebaseFirestore.instance.collection("History").doc(doc.id).set(data);

    await FirebaseFirestore.instance.collection("orders").doc(doc.id).delete();

    Navigator.pop(context);

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Pesanan selesai")));
  }

  // ================================================================
  // RESET HISTORY
  // ================================================================
  void _confirmResetHistory() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reset Riwayat?"),
          content: const Text(
              "Semua data pesanan selesai akan dihapus permanen. Lanjutkan?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                _resetHistory();
              },
              child: const Text("Reset", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetHistory() async {
    final history = await FirebaseFirestore.instance.collection("History").get();

    for (var doc in history.docs) {
      await FirebaseFirestore.instance
          .collection("History")
          .doc(doc.id)
          .delete();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Riwayat berhasil direset")),
    );

    setState(() {}); // Refresh UI
  }
}
