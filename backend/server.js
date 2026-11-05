// server.js - Quick Payment Gateway Prototype for Sprint 1
const express = require('express');
const app = express();
app.use(express.json());

// 1. Temporary in-memory database for today
const paymentsDb = [];

// 2. Route: Create a Payment Link (Simulates Payment Gateway call)
app.post('/api/payments/create', (req, res) => {
  const { booking_id, amount, user_email, payment_method } = req.body;

  // Generate a mock gateway bill ID & checkout link
  const mockBillId = 'BILL_' + Date.now();
  const mockCheckoutUrl = `https://sandbox-gateway.com/pay/${mockBillId}`;

  // Save transaction to local store
  const newPaymentRecord = {
    id: paymentsDb.length + 1,
    booking_id: booking_id,
    gateway_reference_id: mockBillId,
    payment_method: payment_method, // 'fpx' or 'tng'
    amount: amount,
    status: 'pending',
    created_at: new Date()
  };

  paymentsDb.push(newPaymentRecord);

  console.log('✅ Payment initiated and saved to local DB:', newPaymentRecord);

  // Return response
  return res.status(200).json({
    success: true,
    message: 'Payment bill created successfully',
    payment_url: mockCheckoutUrl,
    transaction: newPaymentRecord
  });
});

// 3. Route: Check Saved Payments
app.get('/api/payments/list', (req, res) => {
  res.json({ total: paymentsDb.length, payments: paymentsDb });
});

app.listen(5000, () => console.log('🚀 Payment test server running on port 5000!'));
