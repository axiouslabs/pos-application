module.exports = async (client) => {
  try {
    const check = await client.query(`
      SELECT to_regclass('public.sale_balance') AS table_name;
    `);

    if (check.rows[0].table_name) {
      console.log('ℹ️ "sale_balance" table already exists.');
      return;
    }

    await client.query(`
      CREATE TABLE sale_balance (
        sale_id INTEGER PRIMARY KEY REFERENCES sales(id) ON DELETE CASCADE,
        total_amount NUMERIC(10,2) NOT NULL,
        paid_amount NUMERIC(10,2) NOT NULL DEFAULT 0,
        balance NUMERIC(10,2) NOT NULL DEFAULT 0
      );
    `);

    console.log('✅ "sale_balance" table created.');
  } catch (err) {
    console.error('❌ Failed to create "sale_balance" table:', err.message);
    throw err;
  }
};
