const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");
const midtransClient = require("midtrans-client");

const app = express();
app.use(cors());
app.use(express.json());

/* =======================
   🔥 FIREBASE INIT (NO JSON)
========================== */
admin.initializeApp({
  credential: admin.credential.cert({
    type: process.env.TYPE,
    project_id: process.env.PROJECT_ID,
    private_key_id: process.env.PRIVATE_KEY_ID,
    private_key: process.env.PRIVATE_KEY.replace(/\\n/g, "\n"),
    client_email: process.env.CLIENT_EMAIL,
    client_id: process.env.CLIENT_ID,
    auth_uri: process.env.AUTH_URI,
    token_uri: process.env.TOKEN_URI,
    auth_provider_x509_cert_url: process.env.AUTH_PROVIDER,
    client_x509_cert_url: process.env.CLIENT_CERT_URL,
  }),
});

const db = admin.firestore();

/* =======================
   💳 MIDTRANS INIT
========================== */
let snap = new midtransClient.Snap({
  isProduction: false, // set true jika sudah live
  serverKey: process.env.MIDTRANS_SERVER_KEY,
  clientKey: process.env.MIDTRANS_CLIENT_KEY,
});

/* =======================
   🌟 ROUTE CONTOH GET DATA
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
   💰 ROUTE CONTOH PAYMENT
========================== */
app.post("/create-transaction", async (req, res) => {
  const { orderId, amount } = req.body;
  try {
    let parameter = {
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
