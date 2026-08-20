module.exports = async (client) => {
  try {
    // 1️⃣ Check if refresh_tokens table already exists
    const result = await client.query(`
      SELECT to_regclass('public.refresh_tokens') AS table_name;
    `);

    const tableExists = result.rows[0].table_name !== null;

    if (tableExists) {
      console.log('ℹ️ "refresh_tokens" table already exists.');
      return;
    }

    // 2️⃣ Create refresh_tokens table
    await client.query(`
      CREATE TABLE refresh_tokens (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        token TEXT NOT NULL,
        expires_at TIMESTAMP NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    console.log('✅ "refresh_tokens" table created successfully.');
  } catch (err) {
    console.error('❌ Failed to create "refresh_tokens" table:', err.message);
    throw err;
  }
};
