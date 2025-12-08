const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");
const midtransClient = require("midtrans-client");
const path = require("path");
const bodyParser = require("body-parser");

const app = express();
app.use(cors());
app.use(express.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static("public")); // folder public untuk HTML

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
   🛡 MIDDLEWARE ADMIN
======================= */
function authAdmin(req, res, next) {
  const { username, password } = req.body;
  if (username === process.env.ADMIN_USERNAME && password === process.env.ADMIN_PASSWORD) {
    next();
  } else {
    res.status(401).send("Unauthorized");
  }
}

/* =======================
   🔑 ROUTES
======================= */

// Redirect root ke login
app.get("/", (req, res) => {
  res.redirect("/login");
});

// Tampilkan halaman login
app.get("/login", (req, res) => {
  res.sendFile(path.join(__dirname, "public/login.html"));
});

// Proses login
app.post("/login", authAdmin, (req, res) => {
  // redirect ke dashboard
  res.redirect("/admin/dashboard");
});

// Dashboard admin (bisa tampilkan halaman HTML)
app.get("/admin/dashboard", (req, res) => {
  res.sendFile(path.join(__dirname, "public/dashboard.html"));
});

// Ambil data order dari Firestore
app.get("/admin/orders", async (req, res) => {
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
    res.json({ token: transaction.token });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/* =======================
   🚀 START SERVER
======================= */
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Admin API running on port ${PORT}`));

module.exports = app;
