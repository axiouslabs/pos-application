module.exports = async (client) => {
  try {
    // 1️⃣ Check if table already exists
    const check = await client.query(`
      SELECT to_regclass('public.price_history') AS table_name;
    `);

    if (check.rows[0].table_name !== null) {
      console.log('ℹ️ "price_history" table already exists.');
      return;
    }

    // 2️⃣ Create table
    await client.query(`
      CREATE TABLE price_history (
        id SERIAL PRIMARY KEY,
        product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
        old_price NUMERIC(10, 2) NOT NULL,
        new_price NUMERIC(10, 2) NOT NULL,
        changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    console.log('✅ "price_history" table created successfully.');
  } catch (err) {
    console.error('❌ Failed to create "price_history" table:', err.message);
    throw err;
  }
};

/*Why do we need a price history table?
✔ Products price may change anytime

When “Biscuits 1kg” increases from ₹50 → ₹55, admin should know:

when it changed

who changed it (optional future field)

past price to calculate old invoices

✔ Useful for analytics

Show price trends to admin.

✔ Required for correct billing

If customer bought on 3rd October when price was ₹48, invoice must use ₹48 even if today’s price is ₹55. */