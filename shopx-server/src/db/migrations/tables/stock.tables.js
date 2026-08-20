module.exports = async (client) => {
  try {
    // 1️⃣ Check if table already exists
    const check = await client.query(`
      SELECT to_regclass('public.stock') AS table_name;
    `);

    const exists = check.rows[0].table_name !== null;

    if (exists) {
      console.log('ℹ️ "stock" table already exists.');
      return;
    }

    // 2️⃣ Create the table
    await client.query(`
      CREATE TABLE stock (
        id SERIAL PRIMARY KEY,
       product_id INTEGER NOT NULL UNIQUE REFERENCES products(id) ON DELETE CASCADE,
       quantity NUMERIC(10,2) NOT NULL DEFAULT 0,
        last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    console.log('✅ "stock" table created successfully.');

  } catch (err) {
    console.error('❌ Failed to create "stock" table:', err.message);
    throw err;
  }
};
