const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");
const midtransClient = require("midtrans-client");

const app = express();
app.use(cors());
app.use(express.json());

/* =======================
   🔥 FIREBASE INIT
======================= */
admin.initializeApp({
  credential: admin.credential.cert({
    projectId: process.env.PROJECT_ID,
    clientEmail: process.env.CLIENT_EMAIL,
    privateKey: process.env.PRIVATE_KEY.replace(/\\n/g, "\n"),
  }),
});

const db = admin.firestore();

/* =======================
   💳 MIDTRANS INIT
======================= */
let snap = new midtransClient.Snap({
  isProduction: false,
  serverKey: process.env.MIDTRANS_SERVER_KEY,
  clientKey: process.env.MIDTRANS_CLIENT_KEY,
});

/* =======================
   🛡 ROUTES ADMIN
======================= */

// Login admin
app.post("/login", async (req, res) => {
  const { username, password } = req.body;

  if (username === process.env.ADMIN_USERNAME && password === process.env.ADMIN_PASSWORD) {
    // Bisa tambah token JWT kalau mau
    return res.json({ success: true, message: "Login berhasil" });
  } else {
    return res.status(401).json({ success: false, message: "Username atau password salah" });
  }
});

// Ambil data order
app.get("/admin/orders", async (req, res) => {
  try {
    const snapshot = await db.collection("orders").get();
    const orders = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.json({ success: true, orders });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Contoh route menu (user)
app.get("/menu", async (req, res) => {
  try {
    const snapshot = await db.collection("menus").get();
    const menus = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.json({ success: true, menus });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Contoh route payment
app.post("/create-transaction", async (req, res) => {
  const { orderId, amount } = req.body;
  try {
    const parameter = {
      transaction_details: {
        order_id: orderId,
        gross_amount: amount,
      },
    };
    const transaction = await snap.createTransaction(parameter);
    res.json({ success: true, token: transaction.token });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

/* =======================
   🚀 START SERVER
======================= */
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Admin API running on port ${PORT}`));

module.exports = app;
