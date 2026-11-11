require('dotenv').config();
const express = require('express');
const cors = require('cors'); 
const axios = require('axios');

const { createClient } = require('@supabase/supabase-js');

const app = express(); 

app.use(cors()); 
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_KEY);

// SCRUM-17: Generate Payment Link and Insert into DB
app.post('/api/create-payment', async (req, res) => {
    try {
        // Note: Frontend should send totalAmount instead of amount
        const { bookingId, totalAmount } = req.body;

        if (!bookingId || !totalAmount) {
            return res.status(400).json({ error: 'Missing bookingId or totalAmount' });
        }

        const params = new URLSearchParams();
        params.append('collection_id', process.env.BILLPLZ_COLLECTION_ID);
        params.append('email', 'test@student.utm.my');
        params.append('name', 'Test Student');
        params.append('amount', totalAmount * 100); // Convert to cents
        params.append('description', `KRP Booking Ref: ${bookingId}`);
        params.append('callback_url', 'https://lvdw23j8-3000.asse.devtunnels.ms/api/webhook'); 
        params.append('redirect_url', 'https://google.com'); 

        const response = await axios.post('https://www.billplz-sandbox.com/api/v3/bills', params, {
            auth: {
                username: process.env.BILLPLZ_SECRET_KEY,
                password: '' 
            }
        });

        const paymentUrl = response.data.url;
        const billplzId = response.data.id; 

        // Insert into 'payments' table
        const { error: dbError } = await supabase
            .from('payments')
            .insert([
                { 
                    booking_id: bookingId, 
                    billplz_id: billplzId, 
                    amount: totalAmount, 
                    status: 'pending' 
                }
            ]);

        if (dbError) {
            console.error("❌ [SUPABASE ERROR]:", dbError.message);
            return res.status(500).json({ error: 'Database insert failed', details: dbError.message });
        }

        console.log("✅ Payment record saved to Supabase!");
        res.status(200).json({ paymentUrl: paymentUrl });

    } catch (error) {
        console.error("❌ [GLOBAL ERROR]:", error.message);
        res.status(500).json({ error: 'Payment creation failed' });
    }
});

// SCRUM-18: Webhook for Automated Confirmation
app.post('/api/webhook', async (req, res) => {
    const { id, state } = req.body; 

    if (state === 'paid') {
        console.log(`🔔 Webhook Received! Bill ID: ${id} is PAID.`);
        
        try {
            // Update payments table
            await supabase
                .from('payments')
                .update({ status: 'paid' })
                .eq('billplz_id', id);

            // Get booking_id
            const { data: paymentData } = await supabase
                .from('payments')
                .select('booking_id')
                .eq('billplz_id', id)
                .single();

            // Update 'booking' table (SINGULAR!)
            if (paymentData) {
                await supabase
                    .from('booking') // Table name is singular
                    .update({ status: 'confirmed' })
                    .eq('id', paymentData.booking_id);
                
                console.log(`✅ Database Updated: Booking ${paymentData.booking_id} is CONFIRMED.`);
            }

        } catch (error) {
            console.error("❌ Database Update Failed:", error.message);
        }
    }
    
    res.status(200).send('OK'); 
});