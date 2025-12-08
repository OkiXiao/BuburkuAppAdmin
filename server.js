const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");
const midtransClient = require("midtrans-client");

const app = express();
app.use(cors());
app.use(express.json());

/* =======================
   🔥 FIREBASE INIT (SAFE)
========================== */
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.PROJECT_ID,
      clientEmail: process.env.CLIENT_EMAIL,
      privateKey: process.env.PRIVATE_KEY.replace(/\\n/g, "\n"),
    }),
  });
}

const db = admin.firestore();

/* =======================
   💳 MIDTRANS INIT
========================== */
const snap = new midtransClient.Snap({
  isProduction: false,
  serverKey: process.env.MIDTRANS_SERVER_KEY,
  clientKey: process.env.MIDTRANS_CLIENT_KEY,
});

/* =======================
   🌟 GET MENU
========================== */
app.get("/menu", async (req, res) => {
  try {
    const snapshot = await db.collection("menus").get();
    const data = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/* =======================
   💰 CREATE TRANSACTION
========================== */
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
   🚀 DEFAULT ROUTE
========================== */
app.get("/", (req, res) => {
  res.send("🔥 API is running on Vercel");
});

/* =======================
   📌 EXPORT UNTUK VERCEL
========================== */
module.exports = app;
