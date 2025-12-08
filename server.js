const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");
const fs = require("fs");
const midtransClient = require("midtrans-client");
const bodyParser = require("body-parser");

const app = express();

// ==============================
//  FIREBASE CONNECT
// ==============================
const serviceAccount = JSON.parse(fs.readFileSync("./serviceAccountKey.json", "utf8"));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ==============================
//  MIDDLEWARE
// ==============================
app.use(cors());
app.use(
  express.json({
    verify: (req, res, buf) => {
      req.rawBody = buf; // untuk webhook midtrans
    },
  })
);
app.use(bodyParser.urlencoded({ extended: true }));

// ==============================
//  MIDTRANS CONFIG
// ==============================
const MIDTRANS_SERVER_KEY = "Mid-server-P4ZTwWY3hkkXJrcfi_KF3sMY";

const snap = new midtransClient.Snap({
  isProduction: false,
  serverKey: MIDTRANS_SERVER_KEY,
});

// ==============================
//  CREATE TRANSACTION
// ==============================
app.post("/create-transaction", async (req, res) => {
  try {
    const { items, totalPrice, orderType, customerName, tableNumber, queueNumber } = req.body;

    if (!items || items.length === 0)
      return res.status(400).json({ error: "Items kosong" });

    if (!totalPrice)
      return res.status(400).json({ error: "totalPrice tidak valid" });

    const orderId = "order-" + Date.now();

    // SIMPAN SEMENTARA dengan status WAITING PAYMENT
    await db.collection("orders").doc(orderId).set({
      orderId,
      items,
      totalPrice,
      orderType,
      customerName: customerName || "Guest",
      tableNumber: tableNumber || null,
      queueNumber: queueNumber || null,
      status: "waiting_payment",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // URL NGROK ATAU DOMAIN KAMU
    const NGROK_URL = "https://margaric-nonfeelingly-herman.ngrok-free.dev";

    const parameter = {
      transaction_details: {
        order_id: orderId,
        gross_amount: totalPrice,
      },
      customer_details: {
        first_name: customerName || "Guest",
      },
      // JANGAN SIMPAN JSON, HANYA SIMPAN ID!
      custom_field1: orderId,

      callbacks: {
        finish: `${NGROK_URL}/payment-success`,
      },
    };

    const transaction = await snap.createTransaction(parameter);

    res.json({
      token: transaction.token,
      redirect_url: transaction.redirect_url,
    });
  } catch (error) {
    console.error("Transaction Error:", error);
    res.status(500).json({ error: error.message });
  }
});

// ==============================
//  MIDTRANS WEBHOOK
// ==============================
app.post("/midtrans-webhook", async (req, res) => {
  try {
    const notification = req.body;
    console.log("🔔 Webhook received:", notification);

    const transactionStatus = notification.transaction_status;
    const orderId = notification.custom_field1; // AMBIL orderId

    if (!orderId) return res.status(400).send("orderId missing");

    // STATUS SUKSES
    if (transactionStatus === "settlement" || transactionStatus === "capture") {
      await db.collection("orders").doc(orderId).update({
        status: "pending",
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`✔ Order ${orderId} saved as PAID`);
    }

    // STATUS GAGAL
    else if (["expire", "cancel", "deny"].includes(transactionStatus)) {
      await db.collection("orders").doc(orderId).update({
        status: "cancel",
      });

      console.log(`✘ Order ${orderId} saved as CANCEL`);
    }

    res.status(200).send("OK");
  } catch (error) {
    console.error("Webhook Error:", error);
    res.status(500).send("Error");
  }
});

// ==============================
//  REDIRECT FINISH PAGE
// ==============================
app.get("/payment-success", (req, res) => {
  res.send(`
    <html>
      <body style="font-family: Arial; text-align:center; padding:50px">
        <h2>✅ Pembayaran Berhasil!</h2>
        <p>Silakan kembali ke aplikasi.</p>
      </body>
    </html>
  `);
});

// ==============================
//  MENU (untuk aplikasi user)
// ==============================
app.get("/menu", async (req, res) => {
  const snapshot = await db.collection("menu").get();
  const items = snapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }));
  res.json(items);
});

// ==============================
//  START SERVER
// ==============================
app.listen(3000, () => console.log("🚀 API running on port 3000"));
