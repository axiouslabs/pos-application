module.exports = async (client) => {
  try {
    const check = await client.query(`
      SELECT to_regclass('public.stock_movements') AS table_name;
    `);

    const exists = check.rows[0].table_name !== null;

    if (exists) {
      console.log('ℹ️ "stock_movements" table already exists.');
      return;
    }

    await client.query(`
      CREATE TABLE stock_movements (
        id SERIAL PRIMARY KEY,
        product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
       change NUMERIC(10,2) NOT NULL,
        reason VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    console.log('✅ "stock_movements" table created successfully.');
  } catch (err) {
    console.error('❌ Failed to create "stock_movements" table:', err.message);
    throw err;
  }
};
