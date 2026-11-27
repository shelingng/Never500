// Durable per-booking claim: never repeat an uncertain Billplz POST.
async function acquireBillClaim(supabase, bookingId) {
  const { error } = await supabase.from('payment_bill_claims')
    .insert({ booking_id: bookingId });
  if (!error) return { acquired: true };
  if (error.code !== '23505') throw new Error('Could not secure payment creation');
  const { data, error: readError } = await supabase.from('payment_bill_claims')
    .select('state,billplz_id,payment_url').eq('booking_id', bookingId).single();
  if (readError) throw new Error('Could not read payment creation state');
  return { acquired: false, ...data };
}
async function finishBillClaim(supabase, bookingId, bill) {
  const { error } = await supabase.from('payment_bill_claims').update({
    state: 'ready', billplz_id: bill.id, payment_url: bill.url,
    updated_at: new Date().toISOString(),
  }).eq('booking_id', bookingId);
  if (error) throw new Error('Could not save payment creation state');
}
async function markBillUncertain(supabase, bookingId) {
  const { error } = await supabase.from('payment_bill_claims').update({
    state: 'uncertain', updated_at: new Date().toISOString(),
  }).eq('booking_id', bookingId).eq('state', 'creating');
  if (error) console.error('Payment claim needs reconciliation:', bookingId);
}
module.exports = { acquireBillClaim, finishBillClaim, markBillUncertain };
