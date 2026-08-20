module.exports = async (client) => {
  try {
    const check = await client.query(`
      SELECT to_regclass('public.payments') AS table_name;
    `);

    if (check.rows[0].table_name) {
      console.log('ℹ️ "payments" table already exists.');
      return;
    }

    await client.query(`
     CREATE TABLE payments (
  id SERIAL PRIMARY KEY,
  sale_id INTEGER REFERENCES sales(id) ON DELETE CASCADE,
  customer_id INTEGER REFERENCES customers(id) ON DELETE SET NULL,

  amount NUMERIC(10,2) NOT NULL,
  method VARCHAR(20) DEFAULT 'cash',

  status VARCHAR(20) DEFAULT 'paid', -- ✅ IMPORTANT

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

    `);

    console.log('✅ "payments" table created.');
  } catch (err) {
    console.error('❌ Failed to create "payments" table:', err.message);
    throw err;
  }
};



/*✔ Supports partial payments

If a customer pays ₹500 today and ₹1000 tomorrow.

✔ Supports multiple methods

Cash

UPI

Bank transfer

Credit

✔ Admin Reports

Total collected today

Pending amount

Payment method summary

✔ Salesperson Performance

We know who collected how much. */