// Requires an EMPTY disposable database and npm package `pg`.
// DATABASE_URL=postgresql://... node database/tests/checkout.test.mjs
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import pg from 'pg';
import { randomUUID } from 'node:crypto';
const db = process.env.DATABASE_URL;
if (!db || process.env.CHECKOUT_TEST_DISPOSABLE !== 'yes') {
  throw new Error('Set DATABASE_URL and CHECKOUT_TEST_DISPOSABLE=yes for an EMPTY disposable database.');
}
const admin = new pg.Client({connectionString:db});
await admin.connect();
const occupied = await admin.query("select count(*)::int n from information_schema.tables where table_schema='public'");
assert.equal(occupied.rows[0].n,0,'Refusing to alter a nonempty database');
await admin.query(await readFile(new URL('./fixture.sql',import.meta.url),'utf8'));
const sql=await readFile(new URL('../atomic_checkout.sql',import.meta.url),'utf8');

// A legacy active orphan must abort the complete deployment without deleting it.
const legacy=await admin.query("insert into bookings(user_id,booking_reference,total_amount,status) values('00000000-0000-0000-0000-000000000001','legacy',6,'Confirmed') returning id");
await assert.rejects(admin.query(sql),/LEGACY_RECONCILIATION_REQUIRED/);
await admin.query('rollback');
assert.equal((await admin.query('select count(*)::int n from bookings')).rows[0].n,1);
await admin.query('delete from bookings where id=$1',[legacy.rows[0].id]);
await admin.query(sql);
console.log('PASS legacy deployment fails without deleting records');

const day=(await admin.query("select ((now() at time zone 'Asia/Kuala_Lumpur')::date+1)::text d")).rows[0].d;
const cart=(name='Badminton Court 01',times=['17:00:00'])=>[
 {facility_name:name,date:day,start_times:times},
];
async function user(n) {
 const c=new pg.Client({connectionString:db}); await c.connect();
 await c.query('set role authenticated');
 await c.query("select set_config('request.jwt.claim.sub',$1,false)",[`00000000-0000-0000-0000-00000000000${n}`]);
 return c;
}
const a=await user(1),b=await user(2);
const reserve=(c,items=cart(),key=randomUUID(),total=6)=>c.query(
 'select public.reserve_cart($1,$2,$3) result',[key,JSON.stringify(items),total]);
try {
 // Two connections compete while the winner is still uncommitted.
 const key=randomUUID();
 await a.query('begin');
 const first=(await reserve(a,cart(),key)).rows[0].result;
 const second=reserve(b,cart(),randomUUID(),8);
 const conflict=assert.rejects(second,e=>e.code==='23505');
 await a.query('commit');
 await conflict;
 assert.equal((await admin.query('select count(*)::int n from bookings')).rows[0].n,1);
 assert.equal((await admin.query('select count(*)::int n from booking_items')).rows[0].n,1);
 console.log('PASS two connections: first reservation wins; losing transaction leaves no order');

 const retry=(await reserve(a,cart(),key)).rows[0].result;
 assert.equal(retry.id,first.id);
 await assert.rejects(reserve(a,cart('Ping Pong Table 01'),key,4),/IDEMPOTENCY_MISMATCH/);
 console.log('PASS stable retry returns same order; changed cart cannot reuse key');

 // A free first item must roll back when a later cart item is taken.
 await assert.rejects(reserve(b,[...cart('Ping Pong Table 01'),...cart()],randomUUID(),14),e=>e.code==='23505');
 assert.equal((await admin.query('select count(*)::int n from booking_items')).rows[0].n,1);
 console.log('PASS multi-item conflict rolls back free item and parent order');

 await admin.query("update bookings set payment_deadline=now()-interval '1 second' where id=$1",[first.id]);
 const expiredAvailability=await b.query('select * from public.slot_availability($1)',[day]);
 assert.equal(expiredAvailability.rows.find(r=>r.facility_name==='Badminton Court 1'&&r.start_time==='17:00:00').status,'available');
 await assert.rejects(reserve(a,cart(),key),/HOLD_EXPIRED/);
 const next=(await reserve(b,cart(),randomUUID(),8)).rows[0].result;
 assert.notEqual(next.id,first.id);
 assert.equal(next.total_amount,8);
 assert.equal((await admin.query('select status from bookings where id=$1',[first.id])).rows[0].status,'expired');
 console.log('PASS expiry releases slot; old retry cannot renew it; server uses non-KRP rate');

 await assert.rejects(reserve(a,cart('Ping Pong Table 01'),randomUUID(),0),/PRICE_CHANGED/);
 await assert.rejects(reserve(a,cart('Ping Pong Table 01',['17:30:00']),randomUUID(),4),/OUTSIDE_OPERATING_HOURS/);
 await assert.rejects(reserve(a,cart('Ping Pong Table 01',['17:00:00','17:00:00']),randomUUID(),8),/DUPLICATE_CART_SLOT/);
 await assert.rejects(reserve(a,[{...cart()[0],date:'2020-01-01'}]),/INVALID_DATE/);
 console.log('PASS price tampering, half-hour sessions, duplicates and past dates rejected');

 await admin.query("update bookings set status='confirmed',payment_deadline=now()-interval '1 day' where id=$1",[next.id]);
 await admin.query("update booking_items set status='confirmed' where booking_id=$1",[next.id]);
 await assert.rejects(reserve(a),e=>e.code==='23505');
 assert.equal((await a.query('select * from public.slot_availability($1)',[day])).rows.find(r=>r.facility_name==='Badminton Court 1'&&r.start_time==='17:00:00').status,'booked');
 console.log('PASS confirmed booking remains blocked beyond old deadline');

 assert.equal((await a.query('select count(*)::int n from bookings where id=$1',[next.id])).rows[0].n,0);
 await assert.rejects(a.query("insert into payments(booking_id,amount,status) values($1,6,'successful')",[next.id]),e=>e.code==='42501');
 await assert.rejects(a.query("update bookings set status='confirmed'"),e=>e.code==='42501');
 await assert.rejects(a.query("update profiles set role='admin'"),e=>e.code==='42501');
 await assert.rejects(a.query("update facilities set krp_price=0"),e=>e.code==='42501');
 assert.ok(!Object.keys(expiredAvailability.rows[0]).some(k=>/user|email|booking_id/.test(k)));
 console.log('PASS ownership, client payment/status/role/rate tampering denied; availability excludes identities');

 await admin.query("insert into facility_blocks values('10000000-0000-0000-0000-000000000002',($1::date+time '17:00') at time zone 'Asia/Kuala_Lumpur',($1::date+time '18:00') at time zone 'Asia/Kuala_Lumpur')",[day]);
 await assert.rejects(reserve(a,cart('Ping Pong Table 01'),randomUUID(),4),/SLOT_UNAVAILABLE/);
 const c=new pg.Client({connectionString:db});await c.connect();await c.query('set role anon');
 await assert.rejects(reserve(c),e=>e.code==='42501');await c.end();
 console.log('PASS management block respected; anonymous checkout denied');
} finally {await a.end();await b.end();await admin.end();}
