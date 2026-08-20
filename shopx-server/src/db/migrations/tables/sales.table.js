module.exports = async (client) => {
  try {
    // 1️⃣ Check if table exists
    const check = await client.query(`
      SELECT to_regclass('public.sales') AS table_name;
    `);

    if (check.rows[0].table_name !== null) {
      console.log('ℹ️ "sales" table already exists.');
      return;
    }

    // 2️⃣ Create table
    await client.query(`
    CREATE TABLE sales (
  id SERIAL PRIMARY KEY,
  customer_id INTEGER REFERENCES customers(id),
  salesperson_id INTEGER REFERENCES users(id),

  subtotal_amount NUMERIC(12,2) NOT NULL,
  discount_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  vat_percentage NUMERIC(5,2) NOT NULL DEFAULT 15,
  vat_amount NUMERIC(12,2) NOT NULL,

  total_amount NUMERIC(12,2) NOT NULL,

  sale_status VARCHAR(20) DEFAULT 'completed',
   payment_method VARCHAR(20) NOT NULL,
        payment_status VARCHAR(20) NOT NULL,
  sale_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
    `);

    console.log('✅ "sales" table created successfully.');
  } catch (err) {
    console.error('❌ Failed to create "sales" table:', err.message);
    throw err;
  }
};
