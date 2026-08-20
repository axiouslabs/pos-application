module.exports = async (client) => {
  try {
    // 1️⃣ Check if table exists
    const check = await client.query(`
      SELECT to_regclass('public.receipts') AS table_name;
    `);

    if (check.rows[0].table_name !== null) {
      console.log('ℹ️ "receipts" table already exists.');
      return;
    }

    // 2️⃣ Create receipts table
    await client.query(`
      CREATE TABLE receipts (
        id SERIAL PRIMARY KEY,
        sale_id INTEGER NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
        receipt_data JSONB NOT NULL,   -- full receipt JSON (items, totals, customer, etc.)
        printed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    console.log('✅ "receipts" table created successfully.');
  } catch (err) {
    console.error('❌ Failed to create "receipts" table:', err.message);
    throw err;
  }
};


/*🧠 Why this table is important?
✔ Saves printed bills

Salesperson prints invoice using thermal printer — we save it.

✔ Allows reprinting

Admin can open and reprint older invoices.

✔ Saves scene history

If sale items later change, we still keep original bill.

✔ JSONB column

We store the whole bill in JSON: */