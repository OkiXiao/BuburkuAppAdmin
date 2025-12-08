// lib/screens/menu_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/admin_layout.dart';

const String menuRoute = '/menu';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      activeRoute: menuRoute,
      title: 'Menu',
      content: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // 🔍 BAR PENCARIAN
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari menu...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            searchQuery = "";
                          });
                        })
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),

            const SizedBox(height: 15),

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _showAddMenuDialog(context),
                icon: const Icon(Icons.add, color: Colors.white),
                label:
                    const Text("Tambah Menu", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 REALTIME MENAMPILKAN MENU FIRESTORE + FILTER SEARCH
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("menu")
                    .orderBy("id")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final menuData = snapshot.data!.docs;

                  // FILTER SEARCH
                  final filteredMenu = menuData.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data["name"].toString().toLowerCase();
                    return name.contains(searchQuery);
                  }).toList();

                  if (filteredMenu.isEmpty) {
                    return const Center(child: Text("Tidak ada menu ditemukan."));
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 250,
                      childAspectRatio: 0.78,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: filteredMenu.length,
                    itemBuilder: (context, index) {
                      final item = filteredMenu[index];
                      return _buildMenuItemCard(item);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UI CARD MENU
  Widget _buildMenuItemCard(DocumentSnapshot item) {
    final data = item.data() as Map<String, dynamic>;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: InkWell(
        onTap: () => _showEditMenuDialog(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              data["image"] != null
                  ? Image.asset(data["image"],
                      height: 100, errorBuilder: (_, __, ___) {
                      return _fallbackImage();
                    })
                  : _fallbackImage(),

              const SizedBox(height: 10),

              Text(data["name"],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),

              const SizedBox(height: 4),

              Text("Rp ${data["price"]}",
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold)),

              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteMenu(item.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      height: 100,
      width: 100,
      decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8)),
      child:
          const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
    );
  }

  // ADD MENU → Firestore
  void _showAddMenuDialog(BuildContext context) {
    final name = TextEditingController();
    final price = TextEditingController();
    final image = TextEditingController();
    final id = TextEditingController();

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text("Tambah Menu Baru"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: id, decoration: const InputDecoration(labelText: "ID (angka)")),
                TextField(controller: name, decoration: const InputDecoration(labelText: "Nama Menu")),
                TextField(controller: price, decoration: const InputDecoration(labelText: "Harga")),
                TextField(controller: image, decoration: const InputDecoration(labelText: "Path Gambar")),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
              ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection("menu")
                        .doc(name.text)
                        .set({
                      "id": int.parse(id.text),
                      "name": name.text,
                      "price": int.parse(price.text),
                      "image": image.text
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(
                            content: Text("Menu berhasil ditambahkan")));
                  },
                  child: const Text("Simpan"))
            ],
          );
        });
  }

  // EDIT MENU
  void _showEditMenuDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final name = TextEditingController(text: data["name"]);
    final price = TextEditingController(text: data["price"].toString());
    final image = TextEditingController(text: data["image"]);
    final id = TextEditingController(text: data["id"].toString());

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Edit Menu"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: id, decoration: const InputDecoration(labelText: "ID")),
                TextField(controller: name, decoration: const InputDecoration(labelText: "Nama Menu")),
                TextField(controller: price, decoration: const InputDecoration(labelText: "Harga")),
                TextField(controller: image, decoration: const InputDecoration(labelText: "Path Gambar")),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
              ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection("menu")
                        .doc(doc.id)
                        .update({
                      "id": int.parse(id.text),
                      "name": name.text,
                      "price": int.parse(price.text),
                      "image": image.text
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Menu berhasil diperbarui")));
                  },
                  child: const Text("Simpan"))
            ],
          );
        });
  }

  // DELETE MENU
  Future<void> _deleteMenu(String docId) async {
    await FirebaseFirestore.instance.collection("menu").doc(docId).delete();

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Menu dihapus")));
  }
}
