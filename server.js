const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");
const midtransClient = require("midtrans-client");

const app = express();
app.use(cors());
app.use(express.json());

// =======================
// 🔥 FIREBASE INIT
// =======================
admin.initializeApp({
  credential: admin.credential.cert({
    projectId: process.env.PROJECT_ID,
    clientEmail: process.env.CLIENT_EMAIL,
    privateKey: process.env.PRIVATE_KEY.replace(/\\n/g, "\n"),
  }),
});

const db = admin.firestore();

// =======================
// 💳 MIDTRANS INIT
// =======================
const snap = new midtransClient.Snap({
  isProduction: false,
  serverKey: process.env.MIDTRANS_SERVER_KEY,
  clientKey: process.env.MIDTRANS_CLIENT_KEY,
});

// =======================
// 🛡 AUTH MIDDLEWARE
// =======================
function authAdmin(req, res, next) {
  const { username, password } = req.body;

  // Simple auth, bisa ganti ke Firebase Auth atau JWT nanti
  if (username === process.env.ADMIN_USERNAME && password === process.env.ADMIN_PASSWORD) {
    next();
  } else {
    res.status(401).json({ error: "Unauthorized" });
  }
}

// =======================
// 🔑 ROUTES
// =======================

// Default root
app.get("/", (req, res) => {
  res.json({ message: "🔥 Admin API is running. Use POST /login to authenticate." });
});

// Login admin
app.post("/login", authAdmin, (req, res) => {
  // Bisa return token atau success status
  res.json({ message: "Login successful" });
});

// Ambil data order (admin)
app.get("/admin/orders", authAdmin, async (req, res) => {
  try {
    const snapshot = await db.collection("orders").get();
    const orders = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    res.json(orders);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Contoh route menu (user)
app.get("/menu", async (req, res) => {
  try {
    const snapshot = await db.collection("menus").get();
    const menus = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    res.json(menus);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Buat transaksi Midtrans
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
    res.json({ token: transaction.token, redirect_url: transaction.redirect_url });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// =======================
// 🚀 START SERVER
// =======================
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Admin API running on port ${PORT}`));

module.exports = app;
